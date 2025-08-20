data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = "${var.project}-${var.environment}-rg"
  location = var.location
  tags     = merge(var.tags, { Environment = var.environment, Project = var.project })
}

# Log Analytics Workspace (optional)
resource "azurerm_log_analytics_workspace" "law" {
  count               = var.enable_log_analytics ? 1 : 0
  name                = "${var.project}-${var.environment}-log"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

# Application Insights (optional)
resource "azurerm_application_insights" "appi" {
  count               = var.enable_app_insights ? 1 : 0
  name                = "${var.project}-${var.environment}-appi"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = var.enable_log_analytics ? azurerm_log_analytics_workspace.law[0].id : null
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

# Container Apps Environment (optional)
resource "azurerm_container_app_environment" "cae" {
  count                      = var.enable_container_app_environment ? 1 : 0
  name                       = "${var.project}-${var.environment}-cae"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = var.enable_log_analytics ? azurerm_log_analytics_workspace.law[0].id : null
  tags                       = merge(var.tags, { Environment = var.environment, Project = var.project })
}

# Azure Container Registry (optional)
resource "azurerm_container_registry" "acr" {
  count               = var.enable_acr ? 1 : 0
  name                = coalesce(var.acr_name, replace(lower("${var.project}${var.environment}acr"), "-", ""))
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  admin_enabled       = false
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

# Key Vault (optional, RBAC-based)
resource "azurerm_key_vault" "kv" {
  count                         = var.enable_key_vault ? 1 : 0
  name                          = coalesce(var.key_vault_name, replace(lower("${var.project}-${var.environment}-kv"), "_", "-"))
  location                      = var.location
  resource_group_name           = azurerm_resource_group.rg.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = "standard"
  purge_protection_enabled      = true
  soft_delete_retention_days    = 7
  enable_rbac_authorization     = true
  public_network_access_enabled = true
  tags                          = merge(var.tags, { Environment = var.environment, Project = var.project })
}
