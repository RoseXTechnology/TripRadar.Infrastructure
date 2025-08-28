# Staging environment auto-loaded variables for TripRadar Terraform stack
# This file is automatically loaded by Terraform (no need to specify -var-file)

project     = "tripradar"
environment = "staging"
location    = "northeurope"

tags = {
  Owner       = "TripRadar"
  Environment = "Staging"
  Repo        = "TripRadar.Infrastructure"
  ManagedBy   = "Terraform"
  CostCenter  = "Engineering"
}

# Core Infrastructure
enable_log_analytics             = true
enable_app_insights              = true
enable_container_app_environment = true

# Networking Configuration (Production-like with VNet)
enable_vnet                      = true
enable_private_endpoints         = true
subnet_cae_cidr                  = "10.200.0.0/23"
subnet_private_endpoints_cidr    = "10.200.3.0/24"
subnet_gateway_cidr              = "10.200.254.0/27"

# Container Registry
enable_acr = true
acr_name   = "tripradarstagingacr"

# Key Vault Configuration
enable_key_vault                         = true
key_vault_name                           = "tripradar-staging-kv-8716"
key_vault_public_network_access_enabled  = false  # Private access only
write_secrets_to_key_vault               = false

# Database Configuration (Optimized for staging)
enable_postgres = true

# Container Images (Use stable/tested images for staging)
api_image  = "tripradardevacr.azurecr.io/tripradar/api:latest"
jobs_image = "tripradardevacr.azurecr.io/tripradar/jobs:latest"
db_image   = "tripradardevacr.azurecr.io/tripradar/db:latest"

# Autoscaling Configuration (Production-like)
api_min_replicas        = 2
api_max_replicas        = 10
api_concurrent_requests = 250
jobs_min_replicas       = 1
jobs_max_replicas       = 5

# Custom domain for staging API
api_custom_domain = "api.staging.tripradar.io"

# Front Door + WAF Configuration (Full security)
fd_enable              = true
fd_waf_enable          = true
fd_custom_domain       = "api.staging.tripradar.io"
fd_profile_sku         = "Premium_AzureFrontDoor"
fd_forwarding_protocol = "HttpsOnly"

# VPN Configuration (Optional - for secure access)
enable_vpn                       = false  # Enable if needed for staging access
vpn_sku                         = "VpnGw1"
enable_vpn_connection           = false
