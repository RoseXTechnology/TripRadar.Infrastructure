#  Custom domain and managed certificate for API Container App

locals {
  api_custom_domain_enabled = var.enable_container_app_environment && var.api_ingress_external && var.api_custom_domain != null && !var.fd_enable
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

# Complete custom domain setup with Azure CLI (more reliable than azapi)
resource "null_resource" "api_custom_domain_setup" {
  count = local.api_custom_domain_enabled ? 1 : 0

  # Step 1: Add the custom domain without certificate first
  provisioner "local-exec" {
    command = "az containerapp hostname add --hostname ${var.api_custom_domain} --name ${module.ca_api[0].name} --resource-group ${azurerm_resource_group.rg.name} || true"
  }

  # Step 2: Create managed certificate after hostname is added
  provisioner "local-exec" {
    command = "az containerapp env certificate create --name ${replace(var.api_custom_domain, ".", "-")} --environment ${azurerm_container_app_environment.cae[0].name} --resource-group ${azurerm_resource_group.rg.name} --hostname ${var.api_custom_domain} --validation-method CNAME || true"
  }

  # Step 3: Bind the certificate to the hostname
  provisioner "local-exec" {
    command = "az containerapp hostname bind --hostname ${var.api_custom_domain} --name ${module.ca_api[0].name} --resource-group ${azurerm_resource_group.rg.name} --environment ${azurerm_container_app_environment.cae[0].name} --certificate ${replace(var.api_custom_domain, ".", "-")} || true"
  }

  depends_on = [
    module.ca_api,
  ]

  triggers = {
    domain        = var.api_custom_domain
    container_app = module.ca_api[0].name
    environment   = azurerm_container_app_environment.cae[0].name
  }
}
