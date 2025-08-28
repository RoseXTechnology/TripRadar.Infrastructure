# Dev environment auto-loaded variables for TripRadar Terraform stack
# This file is automatically loaded by Terraform (no need to specify -var-file)

project     = "tripradar"
environment = "dev"
location    = "northeurope"

tags = {
  Owner = "TripRadar"
  Repo  = "TripRadar.Infrastructure"
}

enable_log_analytics             = true
enable_app_insights              = true
enable_container_app_environment = true
enable_vnet                      = false # Disable VNet to avoid delegation conflicts

# Optional resources (toggle on as needed)
enable_acr = true
acr_name   = "tripradardevacr"

enable_key_vault = true
key_vault_name   = "tripradar-dev-kv-8715" # Globally unique name for Key Vault
write_secrets_to_key_vault = false # Disable to avoid count dependency issues

# Database configuration
enable_postgres = true
enable_pg_lock  = false

# Use public images until ACR images are built and pushed
api_image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
jobs_image = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
db_image   = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"

# Autoscaling configuration
api_min_replicas        = 1
api_max_replicas        = 5
api_concurrent_requests = 100
jobs_min_replicas       = 0
jobs_max_replicas       = 2

# Custom domain for API (with WAF protection)
api_custom_domain = "api.dev.tripradar.io"

# Front Door + WAF (disabled for dev to avoid subscription limits)
fd_enable = false
fd_waf_enable = true
fd_custom_domain = "api.dev.tripradar.io"
fd_profile_sku = "Premium_AzureFrontDoor"  # Required for WAF

subnet_cae_cidr = "10.100.0.0/23" # CAE requires at least /23
