# Messaging / Event Hubs variables

variable "enable_event_hubs" {
  description = "Create Azure Event Hubs namespace and hub (Kafka-compatible)"
  type        = bool
  default     = false
}

variable "event_hubs_namespace_name" {
  description = "Event Hubs namespace name (globally unique). If null, derived from project/environment"
  type        = string
  default     = null
}

variable "event_hub_name" {
  description = "Event Hub (topic) name"
  type        = string
  default     = "tripradar"
}

variable "event_hub_partitions" {
  description = "Number of partitions for the Event Hub"
  type        = number
  default     = 2
}

variable "event_hub_message_retention" {
  description = "Event Hub message retention in days"
  type        = number
  default     = 1
}

variable "event_hubs_public_network_access_enabled" {
  description = "Enable public network access for Event Hubs namespace"
  type        = bool
  default     = true
}
