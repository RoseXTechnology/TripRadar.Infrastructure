# Variables for application container apps

variable "api_image" {
  description = "Full image reference for API (e.g., myregistry.azurecr.io/tripradar/api:sha)"
  type        = string
  default     = null
}

variable "jobs_image" {
  description = "Full image reference for Jobs API (e.g., myregistry.azurecr.io/tripradar/jobs:sha)"
  type        = string
  default     = null
}

variable "db_image" {
  description = "Full image reference for Database initialization (e.g., myregistry.azurecr.io/tripradar/db:sha)"
  type        = string
  default     = null
}

variable "api_port" {
  description = "API container listening port"
  type        = number
  default     = 5330
  validation {
    condition     = var.api_port > 0 && var.api_port <= 65535
    error_message = "api_port must be between 1 and 65535."
  }
}

variable "jobs_port" {
  description = "Jobs container listening port"
  type        = number
  default     = 5201
  validation {
    condition     = var.jobs_port > 0 && var.jobs_port <= 65535
    error_message = "jobs_port must be between 1 and 65535."
  }
}

variable "api_ingress_external" {
  description = "Expose API via external ingress"
  type        = bool
  default     = true
}

variable "jobs_ingress_external" {
  description = "Expose Jobs via external ingress (usually false; dashboard behind private access)"
  type        = bool
  default     = false
}

# Controls creation of the database initialization Container App Job
variable "enable_db_init_job" {
  description = "Enable the db-init job creation (requires a valid db_image)."
  type        = bool
  default     = false
}

variable "api_min_replicas" {
  description = "Min replicas for API"
  type        = number
  default     = 1
  validation {
    condition     = var.api_min_replicas >= 0
    error_message = "api_min_replicas must be >= 0."
  }
}

variable "api_max_replicas" {
  description = "Max replicas for API"
  type        = number
  default     = 3
  validation {
    condition     = var.api_max_replicas >= var.api_min_replicas
    error_message = "api_max_replicas must be >= api_min_replicas."
  }
}

variable "api_concurrent_requests" {
  description = "KEDA http concurrent requests per replica"
  type        = number
  default     = 50
  validation {
    condition     = var.api_concurrent_requests > 0
    error_message = "api_concurrent_requests must be > 0."
  }
}

variable "jobs_min_replicas" {
  description = "Min replicas for Jobs"
  type        = number
  default     = 1
  validation {
    condition     = var.jobs_min_replicas >= 0
    error_message = "jobs_min_replicas must be >= 0."
  }
}

variable "jobs_max_replicas" {
  description = "Max replicas for Jobs"
  type        = number
  default     = 1
  validation {
    condition     = var.jobs_max_replicas >= var.jobs_min_replicas
    error_message = "jobs_max_replicas must be >= jobs_min_replicas."
  }
}

# Optional: enable CORS configuration via AzAPI PATCH
variable "enable_cors" {
  description = "Enable CORS policy patch for Container Apps via AzAPI"
  type        = bool
  default     = false
}

variable "cors_allowed_origins" {
  description = "List of allowed origins for CORS policy"
  type        = list(string)
  default     = []
}

# Optional: enable HTTP concurrent requests scaling via AzAPI PATCH (API app)
variable "enable_http_scaling_patch" {
  description = "Enable HTTP scaling rule patch for API via AzAPI"
  type        = bool
  default     = false
}

# Custom domain for API (public)
variable "api_custom_domain" {
  description = "Optional custom domain hostname for the API (e.g., api.dev.tripradar.io). Requires external ingress and DNS records."
  type        = string
  default     = null
}

# Front Door feature flag: when true, we disable direct CA custom-domain binding to avoid conflicts
variable "fd_enable" {
  description = "Enable Azure Front Door integration (disables direct Container App custom domain binding)"
  type        = bool
  default     = false
}
