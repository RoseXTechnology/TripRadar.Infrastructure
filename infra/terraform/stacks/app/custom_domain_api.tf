# Custom domain configuration (temporarily disabled due to azapi_update_resource issues with secrets)
# TODO: Re-enable after resolving azapi compatibility with Container App secrets

locals {
  api_custom_domain_enabled = false # Temporarily disabled
  # api_custom_domain_enabled = var.enable_container_app_environment && var.api_ingress_external && var.api_custom_domain != null
}

# Read Container App to get verification code and FQDN for manual domain setup
data "azapi_resource" "api_app" {
  count       = var.enable_container_app_environment ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_api[0].id

  response_export_values = [
    "properties.customDomainVerificationId",
    "properties.configuration.ingress.fqdn",
  ]
}

# Note: Custom domain resources commented out due to azapi_update_resource incompatibility
# Use Azure CLI after deployment: az containerapp hostname add --hostname api.dev.tripradar.io --name tripradar-dev-api --resource-group tripradar-dev-rg
