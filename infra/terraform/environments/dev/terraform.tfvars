# Dev environment variables for TripRadar Terraform stack
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

api_image  = "tripradardevacr.azurecr.io/tripradar/api:4a098b6f6ef40c909ad152634657cbcb715f0245"
jobs_image = "tripradardevacr.azurecr.io/tripradar/jobs:4a098b6f6ef40c909ad152634657cbcb715f0245"

# Custom domain for API (public)
api_custom_domain = "api.dev.tripradar.io"

subnet_cae_cidr = "10.100.0.0/23" # CAE requires at least /23


# --- Optional: ACR for private images ---
# enable_acr = true
# acr_name   = "<your-acr-name>" # without .azurecr.io
