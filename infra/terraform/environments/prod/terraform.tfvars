# Prod environment variables for TripRadar Terraform stack
project     = "tripradar"
environment = "prod"
location    = "northeurope"

tags = {
  Owner = "TripRadar"
  Repo  = "TripRadar.Infrastructure"
}

enable_log_analytics             = true
enable_app_insights              = true
enable_container_app_environment = true

# Networking
enable_vnet                 = true
subnet_cae_cidr             = "10.100.0.0/23"   # CAE requires at least /23
enable_private_endpoints    = false             # toggle to true when ready
subnet_private_endpoints_cidr = "10.100.3.0/24"
subnet_gateway_cidr            = "10.100.254.0/27" # GatewaySubnet (if VPN enabled)

# Optional resources
enable_acr = true
acr_name   = null # Provide a globally unique name before first apply to avoid conflict

enable_key_vault = true
key_vault_name   = null # Provide a globally unique name before first apply to avoid conflict

enable_postgres = true

# Images (typically set by CI via TF_VARs)
api_image  = null
jobs_image = null
db_image   = null

# Autoscaling
api_min_replicas        = 2
api_max_replicas        = 6
api_concurrent_requests = 150
jobs_min_replicas       = 1
jobs_max_replicas       = 3

# Public API custom domain
api_custom_domain = "api.tripradar.io"

# Front Door / WAF (edge)
fd_enable        = true
fd_custom_domain = "api.tripradar.io"
fd_waf_enable    = true

# VPN (Site-to-Site) — disabled by default
enable_vpn                    = false
vpn_sku                       = "VpnGw1"
vpn_type                      = "RouteBased"
vpn_gateway_generation        = "Generation1"
enable_vpn_connection         = false
local_network_gateway_address = null
local_network_address_space   = []
