# Root variables for prod environment entrypoint

variable "project" { type = string }
variable "environment" { type = string }
variable "location" {
  type    = string
  default = "northeurope"
}
variable "tags" {
  type    = map(string)
  default = {}
}

variable "enable_log_analytics" {
  type    = bool
  default = true
}
variable "enable_app_insights" {
  type    = bool
  default = true
}
variable "enable_container_app_environment" {
  type    = bool
  default = true
}

variable "enable_vnet" {
  type    = bool
  default = true
}
variable "subnet_cae_cidr" {
  type    = string
  default = "10.100.1.0/24"
}

variable "enable_acr" {
  type    = bool
  default = false
}
variable "acr_name" {
  type    = string
  default = null
}

variable "enable_key_vault" {
  type    = bool
  default = false
}
variable "key_vault_name" {
  type    = string
  default = null
}
variable "key_vault_public_network_access_enabled" {
  type    = bool
  default = true
}
variable "write_secrets_to_key_vault" {
  type    = bool
  default = true
}
variable "deployer_object_id" {
  type    = string
  default = null
}

variable "enable_postgres" {
  type    = bool
  default = false
}

variable "api_image" {
  type    = string
  default = null
}
variable "jobs_image" {
  type    = string
  default = null
}
variable "db_image" {
  type    = string
  default = null
}

variable "api_min_replicas" {
  type    = number
  default = 1
}
variable "api_max_replicas" {
  type    = number
  default = 3
}
variable "api_concurrent_requests" {
  type    = number
  default = 50
}
variable "jobs_min_replicas" {
  type    = number
  default = 1
}
variable "jobs_max_replicas" {
  type    = number
  default = 1
}

variable "api_custom_domain" {
  type    = string
  default = null
}

# Optional: Front Door / WAF
variable "fd_enable" {
  type    = bool
  default = false
}
variable "fd_custom_domain" {
  type    = string
  default = null
}
variable "fd_waf_enable" {
  type    = bool
  default = false
}
variable "fd_profile_sku" {
  type    = string
  default = "Premium_AzureFrontDoor"
}
variable "fd_forwarding_protocol" {
  type    = string
  default = "HttpsOnly"
}
variable "fd_route_patterns" {
  type    = list(string)
  default = ["/*"]
}

# Optional: Private Endpoints
variable "enable_private_endpoints" {
  type    = bool
  default = false
}
variable "subnet_private_endpoints_cidr" {
  type    = string
  default = "10.100.3.0/24"
}
variable "subnet_gateway_cidr" {
  type    = string
  default = "10.100.254.0/27"
}

# Optional: VPN
variable "enable_vpn" {
  type    = bool
  default = false
}
variable "vpn_sku" {
  type    = string
  default = "VpnGw1"
}
variable "vpn_type" {
  type    = string
  default = "RouteBased"
}
variable "vpn_gateway_generation" {
  type    = string
  default = "Generation1"
}
variable "enable_vpn_connection" {
  type    = bool
  default = false
}
variable "local_network_gateway_address" {
  type    = string
  default = null
}
variable "local_network_address_space" {
  type    = list(string)
  default = []
}
variable "vpn_shared_key" {
  type      = string
  default   = null
  sensitive = true
}

# Cost Management Variables
variable "monthly_budget_amount" {
  description = "Monthly budget amount for cost alerts (USD)"
  type        = number
  default     = 1000  # Higher budget for production
}

variable "budget_alert_thresholds" {
  description = "Budget alert thresholds as percentages"
  type        = list(number)
  default     = [50, 75, 90, 95, 100]
}

variable "enable_cost_exports" {
  description = "Enable cost analysis exports"
  type        = bool
  default     = true
}

variable "cost_export_storage_account_id" {
  description = "Storage account ID for cost exports"
  type        = string
  default     = null
}

variable "enable_reserved_instances" {
  description = "Enable reserved instances for cost optimization"
  type        = bool
  default     = false
}

variable "reserved_instance_config" {
  description = "Configuration for reserved instances"
  type = object({
    vm_size = string
    term    = string
    count   = number
  })
  default = {
    vm_size = "Standard_B2s"
    term    = "1Year"
    count   = 1
  }
}
