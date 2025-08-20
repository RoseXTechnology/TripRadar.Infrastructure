# Dev environment variables for TripRadar Terraform stack
project     = "tripradar"
environment = "dev"
location    = "eastus"

tags = {
  Owner = "TripRadar"
  Repo  = "TripRadar.Infrastructure"
}

enable_log_analytics             = true
enable_app_insights              = true
enable_container_app_environment = true

# Optional resources (toggle on as needed)
enable_acr       = false
acr_name         = null

enable_key_vault = true
key_vault_name   = null # If null, name defaults to "tripradar-dev-kv"; ensure global uniqueness before apply
