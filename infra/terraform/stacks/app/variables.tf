variable "project" {
  description = "Project name used for naming resources"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{3,24}$", var.project))
    error_message = "project must be 3-24 chars of lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9-]{2,16}$", var.environment))
    error_message = "environment must be 2-16 chars of lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Azure location/region"
  type        = string
  default     = "northeurope"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "enable_log_analytics" {
  description = "Create Log Analytics Workspace"
  type        = bool
  default     = true
}

variable "enable_app_insights" {
  description = "Create Application Insights (connected to workspace if enabled)"
  type        = bool
  default     = true
}

variable "enable_container_app_environment" {
  description = "Create Azure Container Apps Environment"
  type        = bool
  default     = true
}

variable "enable_acr" {
  description = "Create Azure Container Registry"
  type        = bool
  default     = false
}

variable "acr_name" {
  description = "ACR name (global unique, lowercase). Required if enable_acr = true"
  type        = string
  default     = null
  validation {
    condition     = var.enable_acr ? (var.acr_name != null && can(regex("^[a-z0-9]{5,50}$", var.acr_name))) : true
    error_message = "acr_name is required when enable_acr=true and must be 5-50 lowercase alphanumeric (no hyphens)."
  }
}

variable "enable_key_vault" {
  description = "Create Azure Key Vault with RBAC (no access policies)"
  type        = bool
  default     = false
}

variable "key_vault_name" {
  description = "Key Vault name (global unique). Required if enable_key_vault = true"
  type        = string
  default     = null
  validation {
    condition     = var.enable_key_vault ? (var.key_vault_name != null && can(regex("^[a-z][a-z0-9-]{1,22}[a-z0-9]$", var.key_vault_name))) : true
    error_message = "key_vault_name is required when enable_key_vault=true and must be 3-24 chars: lowercase letters, numbers, hyphens; start with a letter and end with a letter or digit."
  }
}

# --- Security and RBAC options ---
variable "key_vault_public_network_access_enabled" {
  description = "Allow public network access to Key Vault (set false when using private endpoints)"
  type        = bool
  default     = true
}

variable "deployer_object_id" {
  description = "Azure AD object ID of the deployer principal (used to grant 'Key Vault Secrets Officer' for secret publishing)"
  type        = string
  default     = null
}
