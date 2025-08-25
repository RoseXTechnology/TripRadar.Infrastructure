# Secure Dev environment variables for TripRadar Terraform stack
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

# 🔒 SECURE CONFIGURATION - Private network with VPN access
enable_vnet                      = true 
enable_private_endpoints         = true  
subnet_cae_cidr                  = "10.100.0.0/23"
subnet_private_endpoints_cidr    = "10.100.3.0/24"
subnet_gateway_cidr              = "10.100.254.0/27"

# VPN Configuration (replace with your values)
enable_vpn                       = true
vpn_sku                         = "VpnGw1"
enable_vpn_connection           = true
local_network_gateway_address   = "YOUR_OFFICE_PUBLIC_IP"        # Replace with your office IP
local_network_address_space     = ["192.168.1.0/24"]           # Replace with your office network
vpn_shared_key                  = "YourSecureVPNKey123!"        # Replace with strong key

# ACR and Key Vault
enable_acr = true
acr_name   = "tripradardevacr"

enable_key_vault = true
key_vault_name   = "tripradar-dev-kv-8715"
key_vault_public_network_access_enabled = false
write_secrets_to_key_vault = false

# Database configuration (private)
enable_postgres = true

# Container images
api_image  = "tripradardevacr.azurecr.io/tripradar/api:4a098b6f6ef40c909ad152634657cbcb715f0245"
jobs_image = "tripradardevacr.azurecr.io/tripradar/jobs:4a098b6f6ef40c909ad152634657cbcb715f0245"
db_image   = "tripradardevacr.azurecr.io/tripradar/db:4a098b6f6ef40c909ad152634657cbcb715f0245"

# Autoscaling configuration
api_min_replicas        = 1
api_max_replicas        = 5
api_concurrent_requests = 100
jobs_min_replicas       = 0
jobs_max_replicas       = 2

# NO public domain - VPN access only
# api_custom_domain = null  # ← API only accessible via VPN

# Front Door disabled for private access
fd_enable = false
