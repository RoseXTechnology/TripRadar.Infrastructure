# Container Apps for API and Jobs

locals {
  kv_postgres_secret_id = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_postgres && length(azurerm_key_vault_secret.postgres_connection_string) > 0 ? azurerm_key_vault_secret.postgres_connection_string[0].id : null
  kv_redis_secret_id    = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_redis && length(azurerm_key_vault_secret.redis_connection_string) > 0 ? azurerm_key_vault_secret.redis_connection_string[0].id : null
  kv_appi_secret_id     = var.enable_key_vault && var.write_secrets_to_key_vault && var.enable_app_insights && length(azurerm_key_vault_secret.app_insights_connection_string) > 0 ? azurerm_key_vault_secret.app_insights_connection_string[0].id : null
  appi_conn_string      = try(azurerm_application_insights.appi[0].connection_string, null)
}

module "ca_api" {
  count                    = var.enable_container_app_environment ? 1 : 0
  source                   = "../../modules/container_app"
  name                     = "${var.project}-${var.environment}-api"
  resource_group_name      = azurerm_resource_group.rg.name
  environment_id           = azurerm_container_app_environment.cae[0].id
  identity_id              = azurerm_user_assigned_identity.api.id
  enable_acr               = var.enable_acr
  acr_server               = try(azurerm_container_registry.acr[0].login_server, null)
  image                    = coalesce(var.api_image, "mcr.microsoft.com/dotnet/samples:aspnetapp")
  container_name           = "api"
  port                     = var.api_port
  ingress_external         = var.api_ingress_external
  min_replicas             = var.api_min_replicas
  max_replicas             = var.api_max_replicas
  http_concurrent_requests = var.api_concurrent_requests
  appdb_secret_id          = local.kv_postgres_secret_id
  appdb_conn_fallback      = var.enable_postgres && local.kv_postgres_secret_id == null ? local.postgres_connection_string : null
  redis_secret_id          = local.kv_redis_secret_id
  redis_conn_fallback      = var.enable_redis && local.kv_redis_secret_id == null ? local.redis_connection_string : null
  appi_secret_id           = local.kv_appi_secret_id
  appi_conn_fallback       = local.kv_appi_secret_id == null && local.appi_conn_string != null ? local.appi_conn_string : null
  tags                     = merge(var.tags, { Environment = var.environment, Project = var.project, "azd-service-name" = "api" })
}

module "ca_jobs" {
  count               = var.enable_container_app_environment ? 1 : 0
  source              = "../../modules/container_app"
  name                = "${var.project}-${var.environment}-jobs"
  resource_group_name = azurerm_resource_group.rg.name
  environment_id      = azurerm_container_app_environment.cae[0].id
  identity_id         = azurerm_user_assigned_identity.jobs.id
  enable_acr          = var.enable_acr
  acr_server          = try(azurerm_container_registry.acr[0].login_server, null)
  image               = coalesce(var.jobs_image, "mcr.microsoft.com/dotnet/samples:aspnetapp")
  container_name      = "jobs"
  port                = var.jobs_port
  ingress_external    = var.jobs_ingress_external
  min_replicas        = var.jobs_min_replicas
  max_replicas        = var.jobs_max_replicas
  cpu                 = 0.25
  memory              = "0.5Gi"
  appdb_secret_id     = local.kv_postgres_secret_id
  appdb_conn_fallback = var.enable_postgres && local.kv_postgres_secret_id == null ? local.postgres_connection_string : null
  redis_secret_id     = local.kv_redis_secret_id
  redis_conn_fallback = var.enable_redis && local.kv_redis_secret_id == null ? local.redis_connection_string : null
  appi_secret_id      = local.kv_appi_secret_id
  appi_conn_fallback  = local.kv_appi_secret_id == null && local.appi_conn_string != null ? local.appi_conn_string : null
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project, "azd-service-name" = "jobs" })
}

