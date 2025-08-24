terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5.1"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

# provider "azurerm" {
#   features {}
#   resource_provider_registrations = "none"
# }

# provider "azapi" {}
