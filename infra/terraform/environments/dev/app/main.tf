terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.110.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
}

provider "azapi" {}

module "app" {
  source = "../../../stacks/app"

  project     = var.project
  environment = var.environment
  location    = var.location
  tags        = var.tags

  enable_log_analytics             = var.enable_log_analytics
  enable_app_insights              = var.enable_app_insights
  enable_container_app_environment = var.enable_container_app_environment

  enable_vnet          = var.enable_vnet
  subnet_cae_cidr      = var.subnet_cae_cidr
  # You can pass additional networking vars as needed:
  # vnet_address_space    = var.vnet_address_space
  # subnet_data_cidr      = var.subnet_data_cidr
  enable_private_endpoints       = var.enable_private_endpoints
  subnet_private_endpoints_cidr  = var.subnet_private_endpoints_cidr
  subnet_gateway_cidr            = var.subnet_gateway_cidr

  enable_acr = var.enable_acr
  acr_name   = var.acr_name

  enable_key_vault                             = var.enable_key_vault
  key_vault_name                               = var.key_vault_name
  key_vault_public_network_access_enabled      = var.key_vault_public_network_access_enabled
  write_secrets_to_key_vault                   = var.write_secrets_to_key_vault
  deployer_object_id                           = var.deployer_object_id

  enable_postgres = var.enable_postgres
  # You can pass detailed Postgres settings if needed:
  # postgres_server_name                     = var.postgres_server_name
  # postgres_administrator_login             = var.postgres_administrator_login
  # postgres_administrator_password          = var.postgres_administrator_password
  # postgres_database_name                   = var.postgres_database_name
  # postgres_version                         = var.postgres_version
  # postgres_sku_name                        = var.postgres_sku_name
  # postgres_storage_mb                      = var.postgres_storage_mb
  # postgres_public_network_access_enabled   = var.postgres_public_network_access_enabled

  api_image  = var.api_image
  jobs_image = var.jobs_image
  db_image   = var.db_image

  api_min_replicas        = var.api_min_replicas
  api_max_replicas        = var.api_max_replicas
  api_concurrent_requests = var.api_concurrent_requests
  jobs_min_replicas       = var.jobs_min_replicas
  jobs_max_replicas       = var.jobs_max_replicas

  api_custom_domain = var.api_custom_domain

  # Front Door / WAF (optional)
  fd_enable              = var.fd_enable
  fd_custom_domain       = var.fd_custom_domain
  fd_waf_enable          = var.fd_waf_enable
  fd_profile_sku         = var.fd_profile_sku
  fd_forwarding_protocol = var.fd_forwarding_protocol
  fd_route_patterns      = var.fd_route_patterns

  # VPN (optional)
  enable_vpn                    = var.enable_vpn
  vpn_sku                       = var.vpn_sku
  vpn_type                      = var.vpn_type
  vpn_gateway_generation        = var.vpn_gateway_generation
  enable_vpn_connection         = var.enable_vpn_connection
  local_network_gateway_address = var.local_network_gateway_address
  local_network_address_space   = var.local_network_address_space
  vpn_shared_key                = var.vpn_shared_key
}
