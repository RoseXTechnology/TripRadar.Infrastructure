# Prod environment variables for TripRadar Terraform stack
project     = "tripradar"
environment = "prod"
location    = "eastus"

tags = {
  Owner = "TripRadar"
  Repo  = "TripRadar.Infrastructure"
}

enable_log_analytics             = true
enable_app_insights              = true
enable_container_app_environment = true

# Optional resources (toggle on as needed)
enable_acr = true
acr_name   = null # Provide a globally unique name before first apply to avoid conflict

enable_key_vault = true
key_vault_name   = null # Provide a globally unique name before first apply to avoid conflict
