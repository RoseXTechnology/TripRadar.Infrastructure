# Custom domain and managed certificate for API Container App

locals {
  api_custom_domain_enabled = var.enable_container_app_environment && var.api_ingress_external && var.api_custom_domain != null
}

# Read Container App to get verification code and FQDN
# Using AzAPI data source to fetch properties not exposed by azurerm
# - properties.customDomainVerificationId
# - properties.configuration.ingress.fqdn
# Docs: https://learn.microsoft.com/azure/templates/microsoft.app/containerapps

data "azapi_resource" "api_app" {
  count       = local.api_custom_domain_enabled ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_api[0].id

  response_export_values = [
    "properties.customDomainVerificationId",
    "properties.configuration.ingress.fqdn",
  ]
}

resource "azapi_update_resource" "api_custom_domain_unmanaged" {
  count       = local.api_custom_domain_enabled ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_api[0].id

  body = {
    properties = {
      configuration = {
        ingress = {
          customDomains = [
            {
              name        = var.api_custom_domain
              bindingType = "Unmanaged"
            }
          ]
        }
      }
    }
  }
}

# Managed certificate in the Container Apps Environment
# Docs: https://learn.microsoft.com/azure/templates/microsoft.app/managedenvironments/managedcertificates
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
    azapi_update_resource.api_custom_domain_unmanaged,
  ]
}

# Bind custom domain to API app using the managed certificate
resource "azapi_update_resource" "api_custom_domain_bind" {
  count       = local.api_custom_domain_enabled ? 1 : 0
  type        = "Microsoft.App/containerApps@2024-03-01"
  resource_id = module.ca_api[0].id

  body = {
    properties = {
      configuration = {
        ingress = {
          customDomains = [
            {
              name          = var.api_custom_domain
              bindingType   = "Managed"
              certificateId = azapi_resource.api_managed_cert[0].id
            }
          ]
        }
      }
    }
  }

  depends_on = [
    azapi_resource.api_managed_cert,
  ]
}
