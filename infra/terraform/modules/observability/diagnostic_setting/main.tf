variable "name" { type = string }
variable "target_resource_id" { type = string }
variable "log_analytics_workspace_id" { type = string }

# Discover categories dynamically for the target
# (Removed to avoid plan-time unknowns when target_resource_id is not yet known)
# data "azurerm_monitor_diagnostic_categories" "this" {
#   resource_id = var.target_resource_id
# }

resource "azurerm_monitor_diagnostic_setting" "this" {
  name                       = var.name
  target_resource_id         = var.target_resource_id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  # Enable all available log categories using category group
  log {
    category_group = "allLogs"
    enabled        = true
  }

  # Enable all available metrics
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
