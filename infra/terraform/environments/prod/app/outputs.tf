# Production Environment Outputs

# --- Cost Management outputs ---
output "budget_id" {
  value       = try(module.cost_management.budget_id, null)
  description = "Budget resource ID"
}

output "cost_export_note" {
  value       = try(module.cost_management.cost_export_note, null)
  description = "Note about cost export setup"
}

output "reserved_instance_note" {
  value       = try(module.cost_management.reserved_instance_note, null)
  description = "Note about reserved instance management"
}

output "monthly_budget_amount" {
  value       = try(module.cost_management.monthly_budget_amount, null)
  description = "Configured monthly budget amount"
}

output "cost_management_summary" {
  value       = try(module.cost_management.cost_management_summary, null)
  description = "Cost management configuration summary"
}

# --- Production-specific outputs ---
output "environment_type" {
  value       = "production"
  description = "Environment type identifier"
}

output "high_availability_enabled" {
  value       = true
  description = "High availability configuration status"
}

output "cost_optimization_enabled" {
  value       = true
  description = "Cost optimization features status"
}
