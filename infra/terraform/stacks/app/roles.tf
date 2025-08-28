# Role assignments for Managed Identities

# ACR pull permissions for API MI
resource "azurerm_role_assignment" "api_acr_pull" {
  count                = var.enable_acr && var.enable_role_assignments ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
  
  # Ignore changes if role assignment fails due to insufficient permissions
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}

# ACR pull permissions for Jobs MI
resource "azurerm_role_assignment" "jobs_acr_pull" {
  count                = var.enable_acr && var.enable_role_assignments ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.jobs.principal_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}

# ACR pull permissions for DB MI
resource "azurerm_role_assignment" "db_acr_pull" {
  count                = var.enable_acr && var.enable_role_assignments ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.db.principal_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}


# Key Vault secrets read for API MI (only if KV enabled)
resource "azurerm_role_assignment" "api_kv_secrets_user" {
  count                = var.enable_key_vault && var.enable_role_assignments ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}

# Key Vault secrets read for Jobs MI
resource "azurerm_role_assignment" "jobs_kv_secrets_user" {
  count                = var.enable_key_vault && var.enable_role_assignments ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.jobs.principal_id
  
  lifecycle {
    ignore_changes = [role_definition_id]
  }
}


## Optional: Grant deployer ability to write secrets to Key Vault
resource "azurerm_role_assignment" "deployer_kv_secrets_officer" {
  count                = var.enable_key_vault && var.deployer_object_id != null ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.deployer_object_id
}
