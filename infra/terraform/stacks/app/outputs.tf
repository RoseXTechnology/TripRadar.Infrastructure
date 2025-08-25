
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


# --- Custom domain outputs (API) ---
output "api_custom_domain_hostname" {
  value       = try(var.api_custom_domain, null)
  description = "Desired hostname for API custom domain (e.g., api.dev.tripradar.io)"
}

output "api_custom_domain_cname_target" {
  value       = try(data.azapi_resource.api_app[0].output.properties.configuration.ingress.fqdn, null)
  description = "CNAME target (the generated Container App FQDN)"
}

output "api_custom_domain_verification_id" {
  value       = try(data.azapi_resource.api_app[0].output.properties.customDomainVerificationId, null)
  description = "TXT record value for asuid.<subdomain> to validate domain ownership"
}

output "dns_records_required" {
  description = "DNS records required for custom domain configuration - Copy these to your DNS provider"
  value = local.api_custom_domain_enabled ? {
    txt_record = {
      name        = "asuid.${var.api_custom_domain}"
      value       = try(jsondecode(data.azapi_resource.api_app[0].output).properties.customDomainVerificationId, null)
      description = "Required for domain verification"
    }
    cname_record = {
      name        = var.api_custom_domain
      value       = try(jsondecode(data.azapi_resource.api_app[0].output).properties.configuration.ingress.fqdn, module.ca_api[0].fqdn)
      description = "Points custom domain to Container App"
    }
    instructions = "1. Add the TXT record first, 2. Wait for DNS propagation (5-15 min), 3. Add the CNAME record, 4. Run 'terraform apply' to complete automated SSL setup"
  } : null
}

# --- Front Door outputs ---
output "frontdoor_profile_id" {
  value       = try(azurerm_cdn_frontdoor_profile.fd[0].id, null)
  description = "Front Door profile resource id"
}

output "frontdoor_endpoint_hostname" {
  value       = try(azurerm_cdn_frontdoor_endpoint.fd[0].host_name, null)
  description = "Front Door endpoint hostname"
}

output "frontdoor_endpoint_url" {
  value       = try(format("https://%s", azurerm_cdn_frontdoor_endpoint.fd[0].host_name), null)
  description = "Front Door public URL"
}

# --- Event Hubs outputs ---
output "event_hubs_namespace_name" {
  value       = try(azurerm_eventhub_namespace.eh[0].name, null)
  description = "Event Hubs namespace name"
}

output "event_hub_name" {
  value       = try(azurerm_eventhub.hub[0].name, null)
  description = "Event Hub name"
}

output "event_hubs_send_connection_string" {
  value       = try(azurerm_eventhub_namespace_authorization_rule.send[0].primary_connection_string, null)
  description = "Event Hubs send (producer) connection string"
  sensitive   = true
}

output "event_hubs_listen_connection_string" {
  value       = try(azurerm_eventhub_authorization_rule.hub_listen[0].primary_connection_string, null)
  description = "Event Hubs listen (consumer) connection string"
  sensitive   = true
}

output "event_hubs_kafka_bootstrap" {
  value       = try(local.event_hubs_kafka_bootstrap, null)
  description = "Kafka bootstrap server for Event Hubs"
}


# --- VPN outputs ---
output "vnet_gateway_id" {
  value       = try(azurerm_virtual_network_gateway.vpngw[0].id, null)
  description = "Virtual Network Gateway resource id"
}

output "vnet_gateway_public_ip" {
  value       = try(azurerm_public_ip.vpngw[0].ip_address, null)
  description = "Virtual Network Gateway public IP address"
}

output "vpn_connection_id" {
  value       = try(azurerm_virtual_network_gateway_connection.s2s[0].id, null)
  description = "VPN S2S connection resource id"
}

output "local_network_gateway_id" {
  value       = try(azurerm_local_network_gateway.onprem[0].id, null)
  description = "Local Network Gateway (on-prem) resource id"
}

# --- Private Link / DNS outputs ---
output "private_dns_zone_kv" {
  value       = try(azurerm_private_dns_zone.kv[0].name, null)
  description = "Private DNS Zone name for Key Vault"
}

output "private_dns_zone_eh" {
  value       = try(azurerm_private_dns_zone.eh[0].name, null)
  description = "Private DNS Zone name for Event Hubs"
}

output "private_dns_zone_pg" {
  value       = try(azurerm_private_dns_zone.pg[0].name, null)
  description = "Private DNS Zone name for PostgreSQL Flexible Server"
}

output "pe_key_vault_id" {
  value       = try(azurerm_private_endpoint.kv[0].id, null)
  description = "Private Endpoint id for Key Vault"
}

output "pe_event_hubs_id" {
  value       = try(azurerm_private_endpoint.eh[0].id, null)
  description = "Private Endpoint id for Event Hubs"
}

output "pe_postgres_id" {
  value       = try(azurerm_private_endpoint.pg[0].id, null)
  description = "Private Endpoint id for PostgreSQL Flexible Server"
}

# --- Front Door custom domain / WAF outputs ---
output "frontdoor_custom_domain" {
  value       = try(azurerm_cdn_frontdoor_custom_domain.api[0].host_name, null)
  description = "Front Door custom domain hostname (if configured)"
}

output "frontdoor_waf_policy_id" {
  value       = try(azurerm_cdn_frontdoor_firewall_policy.fd[0].id, null)
  description = "Front Door WAF firewall policy id (if enabled)"
}

output "frontdoor_security_policy_id" {
  value       = try(azurerm_cdn_frontdoor_security_policy.fd[0].id, null)
  description = "Front Door security policy id (association)"
}
