variable "project" {
  description = "Project name used for naming resources"
  type        = string
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
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
}
