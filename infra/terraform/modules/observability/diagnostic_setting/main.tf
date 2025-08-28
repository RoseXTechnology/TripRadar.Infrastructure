variable "name" { type = string }
variable "target_resource_id" { type = string }
variable "log_analytics_workspace_id" { type = string }
variable "enable_metrics" {
  type    = bool
  default = false
  # Some provider versions mark the 'metric' block as deprecated; keep it opt-in
}

# Discover categories dynamically for the target
# (Removed to avoid plan-time unknowns when target_resource_id is not yet known)
# data "azurerm_monitor_diagnostic_categories" "this" {
#   resource_id = var.target_resource_id
# }

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = var.name
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  # Enable all available log categories using category group
  enabled_log {
    category_group = "allLogs"
  }

  # Enable all available metrics
  dynamic "metric" {
    for_each = var.enable_metrics ? [1] : []
    content {
      category = "AllMetrics"
    }
  }
  
  lifecycle {
    ignore_changes = [name]
  }
}
