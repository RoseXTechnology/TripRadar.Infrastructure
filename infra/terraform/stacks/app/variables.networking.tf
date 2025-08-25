# Networking and VPN variables

variable "enable_private_endpoints" {
  description = "Enable creation of Private Endpoints and Private DNS Zones for services"
  type        = bool
  default     = false
}

variable "subnet_private_endpoints_cidr" {
  description = "CIDR for Private Endpoints subnet"
  type        = string
  default     = "10.100.3.0/24"
}

# Gateway subnet for VPN
variable "subnet_gateway_cidr" {
  description = "CIDR for GatewaySubnet (required if VPN enabled)"
  type        = string
  default     = "10.100.254.0/27"
}

variable "enable_vpn" {
  description = "Enable Virtual Network Gateway for S2S VPN"
  type        = bool
  default     = false
}

variable "vpn_sku" {
  description = "SKU for the Virtual Network Gateway (e.g., VpnGw1)"
  type        = string
  default     = "VpnGw1"
}

variable "vpn_type" {
  description = "VPN type: RouteBased or PolicyBased"
  type        = string
  default     = "RouteBased"
}

variable "vpn_gateway_generation" {
  description = "Gateway generation: Generation1 or Generation2"
  type        = string
  default     = "Generation1"
}

variable "enable_vpn_connection" {
  description = "Create S2S connection to a Local Network Gateway"
  type        = bool
  default     = false
}

variable "local_network_gateway_address" {
  description = "Public IP address of the on-premises VPN device"
  type        = string
  default     = null
}

variable "local_network_address_space" {
  description = "Address spaces for the on-premises network"
  type        = list(string)
  default     = []
}

variable "vpn_shared_key" {
  description = "Pre-shared key for the S2S VPN connection"
  type        = string
  default     = null
  sensitive   = true
}
