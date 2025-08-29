# Development Environment Outputs

# --- Cost Management outputs ---
output "budget_id" {
  value       = try(module.cost_management.budget_id, null)
  description = "Budget resource ID"
}

output "monthly_budget_amount" {
  value       = try(module.cost_management.monthly_budget_amount, null)
  description = "Configured monthly budget amount"
}

output "cost_management_summary" {
  value       = try(module.cost_management.cost_management_summary, null)
  description = "Cost management configuration summary"
}

# --- Development-specific outputs ---
output "environment_type" {
  value       = "development"
  description = "Environment type identifier"
}

output "development_features" {
  value       = "cost_management_basic"
  description = "Development environment features"
}
