# Role assignments for Managed Identities

# ACR pull permissions for API MI
resource "azurerm_role_assignment" "api_acr_pull" {
  count                = var.enable_acr ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

# ACR pull permissions for Jobs MI
resource "azurerm_role_assignment" "jobs_acr_pull" {
  count                = var.enable_acr ? 1 : 0
  scope                = azurerm_container_registry.acr[0].id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.jobs.principal_id
}

# Key Vault secrets read for API MI (only if KV enabled)
resource "azurerm_role_assignment" "api_kv_secrets_user" {
  count                = var.enable_key_vault ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

# Key Vault secrets read for Jobs MI
resource "azurerm_role_assignment" "jobs_kv_secrets_user" {
  count                = var.enable_key_vault ? 1 : 0
  scope                = azurerm_key_vault.kv[0].id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.jobs.principal_id
}
