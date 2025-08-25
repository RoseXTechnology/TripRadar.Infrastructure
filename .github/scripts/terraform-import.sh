#!/bin/bash
set -euo pipefail

# Terraform import utilities for Azure resources
# Usage: ./terraform-import.sh <environment> <working_directory>

ENVIRONMENT="${1:-dev}"
WORKING_DIR="${2:-.}"
RG_NAME="tripradar-${ENVIRONMENT}-rg"
SUB="/subscriptions/${ARM_SUBSCRIPTION_ID}"
VAR_FILE="../terraform.tfvars"

cd "$WORKING_DIR"

# Import function with ID validation
import_if_needed() {
  local addr="$1"; local rid="$2"
  if terraform state list | grep -q "^${addr}$"; then
    local current_id
    current_id=$(terraform state show -no-color "${addr}" 2>/dev/null | awk -F' = ' '/^id = /{print $2; exit}')
    if [ -n "$rid" ] && [ "$current_id" != "$rid" ]; then
      echo "Re-importing ${addr} with correct id (was: $current_id)"
      terraform import -var-file="$VAR_FILE" "${addr}" "${rid}" || true
    else
      echo "${addr} already in state — skipping"
    fi
  else
    echo "Importing ${addr} ..."
    terraform import -var-file="$VAR_FILE" "${addr}" "${rid}" || true
  fi
}

# Remove legacy root-level state addresses
cleanup_legacy_root_state() {
  local legacy_addrs=(
    "azurerm_resource_group.rg"
    "azurerm_log_analytics_workspace.law[0]"
    "azurerm_container_app_environment.cae[0]"
    "azurerm_postgresql_flexible_server.pg[0]"
    "azurerm_postgresql_flexible_server_database.tripradar[0]"
    "random_password.pg_admin[0]"
  )
  for addr in "${legacy_addrs[@]}"; do
    if terraform state list | grep -q "^${addr}$"; then
      echo "Removing legacy root-level state address: ${addr}"
      terraform state rm "${addr}" || true
    fi
  done
}

# Import role assignment if it exists
import_role_if_needed() {
  local addr="$1"; local scope_id="$2"; local role_name="$3"; local principal_id="$4"
  if [ -z "$scope_id" ] || [ -z "$principal_id" ]; then return; fi
  if terraform state list | grep -q "^${addr}$"; then
    echo "${addr} already in state — skipping"
    return
  fi
  local assignment_id
  assignment_id=$(az role assignment list --scope "$scope_id" --role "$role_name" --assignee-object-id "$principal_id" --query "[0].id" -o tsv 2>/dev/null || true)
  if [ -n "$assignment_id" ]; then
    echo "Importing role assignment ${addr} ..."
    terraform import -var-file="$VAR_FILE" "$addr" "$assignment_id" || true
  fi
}

echo "Starting import process for environment: ${ENVIRONMENT}"

# Clean up legacy state
cleanup_legacy_root_state

# PostgreSQL Flexible Server
PG_NAME=$(az postgres flexible-server list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -n "$PG_NAME" ]; then
  import_if_needed "module.app.azurerm_postgresql_flexible_server.pg[0]" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${PG_NAME}"
  
  # Ensure we never manage system DB 'azure_maintenance'
  if terraform state list | grep -q "^module.app.azurerm_postgresql_flexible_server_database.tripradar\\[0\\]$"; then
    CURRENT_DB_ID=$(terraform state show -no-color "module.app.azurerm_postgresql_flexible_server_database.tripradar[0]" 2>/dev/null | awk -F' = ' '/^id = /{print $2; exit}')
    if echo "$CURRENT_DB_ID" | grep -q "/databases/azure_maintenance$"; then
      echo "Removing system DB 'azure_maintenance' from state"
      terraform state rm "module.app.azurerm_postgresql_flexible_server_database.tripradar[0]" || true
    fi
  fi
  
  # Import application database (exclude system DBs)
  DB_NAME=$(az postgres flexible-server db list -g "$RG_NAME" -s "$PG_NAME" --query "[?name!='postgres' && name!='azure_maintenance']|[0].name" -o tsv 2>/dev/null || true)
  if [ -n "$DB_NAME" ]; then
    import_if_needed "module.app.azurerm_postgresql_flexible_server_database.tripradar[0]" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.DBforPostgreSQL/flexibleServers/${PG_NAME}/databases/${DB_NAME}"
  fi
fi

# Managed Identities
for suffix in api-mi jobs-mi db-mi; do
  MI_NAME="tripradar-${ENVIRONMENT}-${suffix}"
  if az identity show -g "$RG_NAME" -n "$MI_NAME" >/dev/null 2>&1; then
    NAME_TRIMMED=${suffix%-mi}
    import_if_needed "module.app.azurerm_user_assigned_identity.${NAME_TRIMMED}" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${MI_NAME}"
  fi
done

# Log Analytics Workspace
LAW_NAME=$(az monitor log-analytics workspace list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -n "$LAW_NAME" ]; then
  import_if_needed "module.app.azurerm_log_analytics_workspace.law[0]" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.OperationalInsights/workspaces/${LAW_NAME}"
fi

# Azure Container Registry
ACR_NAME=$(az acr list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -n "$ACR_NAME" ]; then
  import_if_needed "module.app.azurerm_container_registry.acr[0]" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.ContainerRegistry/registries/${ACR_NAME}"
fi

# Key Vault
KV_NAME=$(az keyvault list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -n "$KV_NAME" ]; then
  import_if_needed "module.app.azurerm_key_vault.kv[0]" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.KeyVault/vaults/${KV_NAME}"
fi

# Application Insights (prefer expected name)
EXPECTED_APPI="${RG_NAME%-rg}-appi"
if az monitor app-insights component show -g "$RG_NAME" -a "$EXPECTED_APPI" >/dev/null 2>&1; then
  APPI_NAME="$EXPECTED_APPI"
else
  APPI_NAME=$(az monitor app-insights component list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
fi
if [ -n "$APPI_NAME" ]; then
  import_if_needed "module.app.azurerm_application_insights.appi[0]" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.Insights/components/${APPI_NAME}"
fi

# Container Apps Environment
CAE_NAME=$(az containerapp env list -g "$RG_NAME" --query "[0].name" -o tsv 2>/dev/null || true)
if [ -n "$CAE_NAME" ]; then
  import_if_needed "module.app.azurerm_container_app_environment.cae[0]" "${SUB}/resourceGroups/${RG_NAME}/providers/Microsoft.App/managedEnvironments/${CAE_NAME}"
  
  # Import diagnostic setting
  CAE_ID=$(az containerapp env show -g "$RG_NAME" -n "$CAE_NAME" --query id -o tsv 2>/dev/null || true)
  if [ -n "$CAE_ID" ]; then
    import_if_needed "module.app.module.diag_cae[0].azurerm_monitor_diagnostic_setting.this" "${CAE_ID}|${CAE_NAME}-diag"
  fi
  
  # Import Container Apps to avoid delete conflicts
  for CA_NAME in $(az containerapp list -g "$RG_NAME" --query "[].name" -o tsv 2>/dev/null || true); do
    CA_ID=$(az containerapp show -g "$RG_NAME" -n "$CA_NAME" --query id -o tsv 2>/dev/null || true)
    if [ -n "$CA_ID" ]; then
      case "$CA_NAME" in
        *-api)
          import_if_needed "module.app.module.ca_api[0].azurerm_container_app.this" "$CA_ID"
          ;;
        *-jobs)
          import_if_needed "module.app.module.ca_jobs[0].azurerm_container_app.this" "$CA_ID"
          ;;
      esac
    fi
  done
fi

# Import role assignments
ACR_ID=""; KV_ID=""; MI_API_PRINCIPAL=""; MI_JOBS_PRINCIPAL=""; MI_DB_PRINCIPAL=""
if [ -n "$ACR_NAME" ]; then ACR_ID=$(az acr show -g "$RG_NAME" -n "$ACR_NAME" --query id -o tsv 2>/dev/null || true); fi
if [ -n "$KV_NAME" ]; then KV_ID=$(az keyvault show -g "$RG_NAME" -n "$KV_NAME" --query id -o tsv 2>/dev/null || true); fi

for suffix in api jobs db; do
  MI_NAME="tripradar-${ENVIRONMENT}-${suffix}-mi"
  if az identity show -g "$RG_NAME" -n "$MI_NAME" >/dev/null 2>&1; then
    PRINCIPAL_ID=$(az identity show -g "$RG_NAME" -n "$MI_NAME" --query principalId -o tsv 2>/dev/null || true)
    case "$suffix" in
      api) MI_API_PRINCIPAL="$PRINCIPAL_ID" ;;
      jobs) MI_JOBS_PRINCIPAL="$PRINCIPAL_ID" ;;
      db) MI_DB_PRINCIPAL="$PRINCIPAL_ID" ;;
    esac
  fi
done

# ACR Pull role assignments
if [ -n "$ACR_ID" ]; then
  import_role_if_needed "module.app.azurerm_role_assignment.api_acr_pull[0]" "$ACR_ID" "AcrPull" "$MI_API_PRINCIPAL"
  import_role_if_needed "module.app.azurerm_role_assignment.jobs_acr_pull[0]" "$ACR_ID" "AcrPull" "$MI_JOBS_PRINCIPAL"
  import_role_if_needed "module.app.azurerm_role_assignment.db_acr_pull[0]" "$ACR_ID" "AcrPull" "$MI_DB_PRINCIPAL"
fi

# Key Vault Secrets User role assignments
if [ -n "$KV_ID" ]; then
  import_role_if_needed "module.app.azurerm_role_assignment.api_kv_secrets_user[0]" "$KV_ID" "Key Vault Secrets User" "$MI_API_PRINCIPAL"
  import_role_if_needed "module.app.azurerm_role_assignment.jobs_kv_secrets_user[0]" "$KV_ID" "Key Vault Secrets User" "$MI_JOBS_PRINCIPAL"
fi

echo "Import process completed for environment: ${ENVIRONMENT}"
