# Cost Management Module Outputs

output "budget_id" {
  value       = try(azurerm_consumption_budget_resource_group.budget[0].id, null)
  description = "Budget resource ID"
}

output "budget_name" {
  value       = try(azurerm_consumption_budget_resource_group.budget[0].name, null)
  description = "Budget resource name"
}

output "cost_export_note" {
  value       = "Cost exports must be configured via Azure Portal → Cost Management → Exports"
  description = "Note about cost export setup"
}

output "reserved_instance_note" {
  value       = "Reserved instances are managed via Azure Portal → Reservations"
  description = "Note about reserved instance management"
}

output "action_group_id" {
  value       = try(azurerm_monitor_action_group.budget_alerts[0].id, null)
  description = "Action group ID for budget alerts"
}

output "monthly_budget_amount" {
  value       = var.monthly_budget_amount
  description = "Configured monthly budget amount"
}

output "budget_alert_thresholds" {
  value       = var.budget_alert_thresholds
  description = "Budget alert thresholds configured"
}

output "cost_management_summary" {
  description = "Summary of cost management resources created"
  value = {
    budget_enabled         = var.enable_budget_alerts
    cost_exports_enabled   = var.enable_cost_exports
    reserved_instances     = var.enable_reserved_instances
    monthly_budget         = var.monthly_budget_amount
    alert_thresholds       = var.budget_alert_thresholds
    environment           = var.environment
    resource_group        = var.resource_group_name
  }
}
