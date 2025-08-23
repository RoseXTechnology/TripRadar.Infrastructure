#  Custom domain and managed certificate for API Container App

locals {
  api_custom_domain_enabled = var.enable_container_app_environment && var.api_ingress_external && var.api_custom_domain != null
}

# Read Container App to get verification code and FQDN
data "azapi_resource" "api_app" {
  count       = local.api_custom_domain_enabled ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_api[0].id

  response_export_values = [
    "properties.customDomainVerificationId",
    "properties.configuration.ingress.fqdn",
  ]
}

# Create managed certificate first
resource "azapi_resource" "api_managed_cert" {
  count     = local.api_custom_domain_enabled ? 1 : 0
  type      = "Microsoft.App/managedEnvironments/managedCertificates@2024-03-01"
  name      = replace(var.api_custom_domain, ".", "-")
  parent_id = azurerm_container_app_environment.cae[0].id
  location  = var.location

  body = {
    properties = {
      subjectName             = var.api_custom_domain
      domainControlValidation = "CNAME"
    }
  }

  depends_on = [
    module.ca_api,
  ]
}

# Use null_resource with Azure CLI for domain configuration (more reliable than azapi_update_resource)
resource "null_resource" "api_custom_domain_setup" {
  count = local.api_custom_domain_enabled ? 1 : 0

  # Add the custom domain without certificate first
  provisioner "local-exec" {
    command = "az containerapp hostname add --hostname ${var.api_custom_domain} --name ${module.ca_api[0].name} --resource-group ${azurerm_resource_group.rg.name} || true"
  }

  # Then bind the managed certificate  
  provisioner "local-exec" {
    command = "az containerapp hostname bind --hostname ${var.api_custom_domain} --name ${module.ca_api[0].name} --resource-group ${azurerm_resource_group.rg.name} --environment ${azurerm_container_app_environment.cae[0].name} --certificate ${azapi_resource.api_managed_cert[0].name} || true"
  }

  depends_on = [
    azapi_resource.api_managed_cert,
    module.ca_api,
  ]

  triggers = {
    domain         = var.api_custom_domain
    container_app  = module.ca_api[0].name
    certificate_id = azapi_resource.api_managed_cert[0].id
  }
}
