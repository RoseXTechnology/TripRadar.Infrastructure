output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Resource Group name"
}

output "resource_group_id" {
  value       = azurerm_resource_group.rg.id
  description = "Resource Group id"
}

output "log_analytics_workspace_id" {
  value       = try(azurerm_log_analytics_workspace.law[0].id, null)
  description = "Log Analytics Workspace resource id"
}

output "application_insights_connection_string" {
  value       = try(azurerm_application_insights.appi[0].connection_string, null)
  description = "Application Insights connection string"
  sensitive   = true
}

output "container_app_environment_id" {
  value       = try(azurerm_container_app_environment.cae[0].id, null)
  description = "Container Apps Environment resource id"
}

output "acr_login_server" {
  value       = try(azurerm_container_registry.acr[0].login_server, null)
  description = "ACR login server"
}

output "RESOURCE_GROUP_ID" {
  value       = azurerm_resource_group.rg.id
  description = "Alias: Resource Group id"
}

output "AZURE_CONTAINER_REGISTRY_ENDPOINT" {
  value       = try(azurerm_container_registry.acr[0].login_server, null)
  description = "Alias: ACR login server endpoint"
}

output "key_vault_id" {
  value       = try(azurerm_key_vault.kv[0].id, null)
  description = "Key Vault resource id"
}

output "postgres_fqdn" {
  value       = try(azurerm_postgresql_flexible_server.pg[0].fqdn, null)
  description = "PostgreSQL server FQDN"
}

output "postgres_connection_string" {
  value       = try(local.postgres_connection_string, null)
  description = "PostgreSQL connection string"
  sensitive   = true
}

output "redis_connection_string" {
  value       = try(local.redis_connection_string, null)
  description = "Redis connection string"
  sensitive   = true
}

output "api_fqdn" {
  value       = try(module.ca_api[0].fqdn, null)
  description = "API Container App FQDN"
}

output "api_url" {
  value       = try(format("https://%s", module.ca_api[0].fqdn), null)
  description = "API base URL"
}

output "jobs_fqdn" {
  value       = try(module.ca_jobs[0].fqdn, null)
  description = "Jobs Container App FQDN (only if external ingress enabled)"
}

output "jobs_url" {
  value       = try(format("https://%s", module.ca_jobs[0].fqdn), null)
  description = "Jobs base URL (only if external ingress enabled)"
}

