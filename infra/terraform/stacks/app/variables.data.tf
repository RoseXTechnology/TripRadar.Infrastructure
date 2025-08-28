variable "enable_vnet" {
  description = "Create a Virtual Network and subnets"
  type        = bool
  default     = true
}

variable "vnet_address_space" {
  description = "Address space for the VNet"
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "subnet_cae_cidr" {
  description = "CIDR for Container Apps subnet (reserved for future integration)"
  type        = string
  default     = "10.100.1.0/24"
}

variable "subnet_data_cidr" {
  description = "CIDR for data subnet (e.g., DB/Cache)"
  type        = string
  default     = "10.100.2.0/24"
}

variable "enable_postgres" {
  description = "Create PostgreSQL Flexible Server"
  type        = bool
  default     = false
}

variable "postgres_server_name" {
  description = "PostgreSQL server name (globally unique within region). If null, derived from project/environment"
  type        = string
  default     = null
}

variable "postgres_administrator_login" {
  description = "PostgreSQL admin username"
  type        = string
  default     = "pgadmin"
}

variable "postgres_administrator_password" {
  description = "PostgreSQL admin password (sensitive). Provide via tfvars/secret store"
  type        = string
  default     = null
  sensitive   = true
}

variable "postgres_database_name" {
  description = "Default database to reference in connection string"
  type        = string
  default     = "tripradar"
}

variable "postgres_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "16"
}

variable "postgres_sku_name" {
  description = "PostgreSQL SKU (e.g., B_Standard_B1ms, GP_Standard_D2s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "postgres_public_network_access_enabled" {
  description = "Enable public network access for PostgreSQL"
  type        = bool
  default     = true
}

variable "enable_redis" {
  description = "Create Azure Cache for Redis"
  type        = bool
  default     = false
}

variable "redis_name" {
  description = "Redis cache name. If null, derived from project/environment"
  type        = string
  default     = null
}

variable "redis_sku_name" {
  description = "Redis SKU: Basic, Standard, Premium"
  type        = string
  default     = "Basic"
}

variable "redis_family" {
  description = "Redis family: C (Basic/Standard) or P (Premium)"
  type        = string
  default     = "C"
}

variable "redis_capacity" {
  description = "Redis capacity (0..6 depending on SKU)"
  type        = number
  default     = 0
}

variable "write_secrets_to_key_vault" {
  description = "If true and Key Vault is enabled, write generated secrets (connection strings) to Key Vault"
  type        = bool
  default     = true
}

variable "enable_pg_lock" {
  description = "Enable management lock on PostgreSQL server to prevent accidental deletion"
  type        = bool
  default     = false
}
