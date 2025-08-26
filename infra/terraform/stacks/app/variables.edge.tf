# Edge/Front Door variables

variable "fd_profile_sku" {
  description = "Azure Front Door SKU"
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "fd_forwarding_protocol" {
  description = "Forwarding protocol for Front Door route"
  type        = string
  default     = "HttpsOnly"
}

variable "fd_route_patterns" {
  description = "Patterns to match for Front Door route"
  type        = list(string)
  default     = ["/*"]
}

variable "fd_custom_domain" {
  description = "Optional custom domain hostname for Front Door (e.g., api.dev.tripradar.io). When set, creates FD custom domain and associates to route."
  type        = string
  default     = null
}

variable "fd_waf_enable" {
  description = "Enable Front Door WAF policy and associate with custom domain"
  type        = bool
  default     = false
}

# Blue/Green slot selector for Front Door
variable "fd_active_slot" {
  description = "Active Front Door slot ('blue' or 'green')"
  type        = string
  default     = "blue"
  validation {
    condition     = contains(["blue", "green"], var.fd_active_slot)
    error_message = "fd_active_slot must be either 'blue' or 'green'."
  }
}
