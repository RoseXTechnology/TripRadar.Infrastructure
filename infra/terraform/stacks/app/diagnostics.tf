// Diagnostic settings via reusable module

module "diag_cae" {
  count                      = var.enable_log_analytics && var.enable_container_app_environment ? 1 : 0
  source                     = "../../modules/observability/diagnostic_setting"
  name                       = "${var.project}-${var.environment}-cae-diag"
  target_resource_id         = azurerm_container_app_environment.cae[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law[0].id
}

module "diag_api" {
  count                      = var.enable_log_analytics && var.enable_container_app_environment ? 1 : 0
  source                     = "../../modules/observability/diagnostic_setting"
  name                       = "${var.project}-${var.environment}-api-diag"
  target_resource_id         = module.ca_api[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law[0].id
}

module "diag_jobs" {
  count                      = var.enable_log_analytics && var.enable_container_app_environment ? 1 : 0
  source                     = "../../modules/observability/diagnostic_setting"
  name                       = "${var.project}-${var.environment}-jobs-diag"
  target_resource_id         = module.ca_jobs[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law[0].id
}

