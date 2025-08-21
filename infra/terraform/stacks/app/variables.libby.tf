# Variables for Libby container app (optional)

variable "enable_libby" {
  description = "Create Libby Container App"
  type        = bool
  default     = false
}

variable "libby_image" {
  description = "Full image reference for Libby (e.g., myregistry.azurecr.io/tripradar/libby:sha)"
  type        = string
  default     = null
}

variable "libby_port" {
  description = "Libby container listening port"
  type        = number
  default     = 8080
  validation {
    condition     = var.libby_port > 0 && var.libby_port <= 65535
    error_message = "libby_port must be between 1 and 65535."
  }
}

variable "libby_ingress_external" {
  description = "Expose Libby via external ingress"
  type        = bool
  default     = false
}

variable "libby_min_replicas" {
  description = "Min replicas for Libby"
  type        = number
  default     = 1
  validation {
    condition     = var.libby_min_replicas >= 0
    error_message = "libby_min_replicas must be >= 0."
  }
}

variable "libby_max_replicas" {
  description = "Max replicas for Libby"
  type        = number
  default     = 1
  validation {
    condition     = var.libby_max_replicas >= var.libby_min_replicas
    error_message = "libby_max_replicas must be >= libby_min_replicas."
  }
}
