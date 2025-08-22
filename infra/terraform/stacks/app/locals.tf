locals {
  postgres_admin_password = var.enable_postgres ? (var.postgres_administrator_password != null ? var.postgres_administrator_password : random_password.pg_admin[0].result) : null
  postgres_fqdn           = var.enable_postgres ? azurerm_postgresql_flexible_server.pg[0].fqdn : null
  postgres_connection_string = var.enable_postgres ? (
    "Host=${azurerm_postgresql_flexible_server.pg[0].fqdn};Database=${var.postgres_database_name};Username=${var.postgres_administrator_login};Password=${local.postgres_admin_password};Ssl Mode=Require;"
  ) : null

  redis_connection_string = var.enable_redis ? (
    "rediss://:${azurerm_redis_cache.redis[0].primary_access_key}@${azurerm_redis_cache.redis[0].hostname}:6380/0"
  ) : null

  appi_conn_string = var.enable_app_insights && length(azurerm_application_insights.appi) > 0 ? azurerm_application_insights.appi[0].connection_string : null
}
