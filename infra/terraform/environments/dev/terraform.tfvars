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

# Optional resources (toggle on as needed)
enable_acr = true
acr_name   = "tripradardevacr"

enable_key_vault = true
key_vault_name   = "tripradar-dev-kv-8715" # Globally unique name for Key Vault

# --- Optional: Libby Container App (disabled by default) ---
# enable_libby           = true
# libby_port             = 8080
# libby_ingress_external = false
# libby_min_replicas     = 1
# libby_max_replicas     = 1

# --- Optional: ACR for private images ---
# enable_acr = true
# acr_name   = "<your-acr-name>" # without .azurecr.io
