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

variable "api_port" {
  description = "API container listening port"
  type        = number
  default     = 5330
}

variable "jobs_port" {
  description = "Jobs container listening port"
  type        = number
  default     = 5201
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

variable "api_min_replicas" {
  description = "Min replicas for API"
  type        = number
  default     = 1
}

variable "api_max_replicas" {
  description = "Max replicas for API"
  type        = number
  default     = 3
}

variable "api_concurrent_requests" {
  description = "KEDA http concurrent requests per replica"
  type        = number
  default     = 50
}

variable "jobs_min_replicas" {
  description = "Min replicas for Jobs"
  type        = number
  default     = 1
}

variable "jobs_max_replicas" {
  description = "Max replicas for Jobs"
  type        = number
  default     = 1
}
