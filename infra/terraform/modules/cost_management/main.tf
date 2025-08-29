# Azure Cost Management Module
# Provides budget alerts, cost exports, and reserved instances management

variable "resource_group_name" {
  type        = string
  description = "Resource group name for cost management"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "project" {
  type        = string
  description = "Project name"
}

variable "enable_budget_alerts" {
  type        = bool
  default     = true
  description = "Enable budget alerts"
}

variable "monthly_budget_amount" {
  type        = number
  description = "Monthly budget amount in USD"
  default     = 100
}

variable "budget_alert_thresholds" {
  type        = list(number)
  default     = [50, 75, 90, 100]
  description = "Budget alert thresholds as percentages (e.g., [50, 75, 90, 100])"
}

variable "enable_cost_exports" {
  type        = bool
  default     = false
  description = "Enable cost analysis exports"
}

variable "storage_account_id" {
  type        = string
  default     = null
  description = "Storage account ID for cost exports"
}

variable "enable_reserved_instances" {
  type        = bool
  default     = false
  description = "Enable reserved instances for production workloads"
}

variable "reserved_instance_config" {
  type = object({
    vm_size = string
    term    = string # "1Year" or "3Years"
    count   = number
  })
  default = {
    vm_size = "Standard_B2s"
    term    = "1Year"
    count   = 1
  }
  description = "Reserved instance configuration"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags"
}

# Budget alerts for resource group
resource "azurerm_consumption_budget_resource_group" "budget" {
  count = var.enable_budget_alerts ? 1 : 0

  name                = "${var.project}-${var.environment}-budget"
  resource_group_id   = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
  amount              = var.monthly_budget_amount
  time_grain          = "Monthly"

  time_period {
    start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
    end_date   = formatdate("YYYY-MM-01'T'00:00:00Z", timeadd(timestamp(), "8760h")) # 1 year from now
  }

  dynamic "notification" {
    for_each = var.budget_alert_thresholds
    content {
      enabled        = true
      threshold      = notification.value
      threshold_type = "Actual"
      operator       = "GreaterThanOrEqualTo"

      contact_emails = [] # Add email addresses for alerts
      contact_groups = [] # Add action group IDs
      contact_roles  = ["Owner", "Contributor"]
    }
  }

  filter {
    dimension {
      name = "ResourceGroupName"
      values = [var.resource_group_name]
    }
  }
}

# Cost analysis export (requires storage account)
# Note: Cost management export is not supported in current Azure provider version
# To set up cost exports:
# 1. Go to Azure Portal → Cost Management → Exports
# 2. Create a new export with your storage account
# 3. Configure recurrence and data options

# resource "azurerm_cost_management_export" "export" {
#   count = var.enable_cost_exports && var.storage_account_id != null ? 1 : 0
#
#   name                    = "${var.project}-${var.environment}-cost-export"
#   scope                   = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"
#   recurrence_type         = "Monthly"
#   recurrence_period_start = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
#   recurrence_period_end   = formatdate("YYYY-MM-01'T'00:00:00Z", timeadd(timestamp(), "8760h"))
#
#   export_data_storage_location {
#     container_id     = var.storage_account_id
#     root_folder_path = "cost-analysis/${var.environment}"
#   }
#
#   export_data_options {
#     type       = "ActualCost"
#     time_frame = "MonthToDate"
#   }
#
#   query {
#     type       = "ActualCost"
#     time_frame = "MonthToDate"
#
#     dataset {
#       granularity = "Daily"
#
#       aggregation {
#         name        = "totalCost"
#         function    = "Sum"
#       }
#
#       grouping {
#         type = "Dimension"
#         name = "ServiceName"
#       }
#
#       grouping {
#         type = "Dimension"
#         name = "ResourceGroup"
#       }
#     }
#   }
#
#   tags = merge(var.tags, {
#     Environment = var.environment
#     Project     = var.project
#     Purpose     = "CostAnalysis"
#   })
# }

# Reserved Virtual Machine Instances (for VMs in the resource group)
# Note: Reserved instances are managed via Azure portal or CLI, not Terraform
# This resource type is not currently supported in the Azure provider
# To create reserved instances:
# 1. Go to Azure Portal → Reservations
# 2. Purchase reserved instances for your VM sizes
# 3. Apply them to specific resource groups or subscriptions

# resource "azurerm_reserved_virtual_machine_instance" "vm_reserved" {
#   count = var.enable_reserved_instances ? 1 : 0
#
#   name                               = "${var.project}-${var.environment}-vm-reserved"
#   resource_group_name               = var.resource_group_name
#   location                          = "northeurope"
#   vm_size                           = var.reserved_instance_config.vm_size
#   term                              = var.reserved_instance_config.term
#   instance_count                    = var.reserved_instance_config.count
#   sku_name                          = "${var.reserved_instance_config.vm_size}_${var.reserved_instance_config.term}"
#   reserved_resource_type            = "VirtualMachines"
#
#   tags = merge(var.tags, {
#     Environment = var.environment
#     Project     = var.project
#     Purpose     = "CostOptimization"
#   })
# }

# Action Group for budget alerts (optional - can be created separately)
resource "azurerm_monitor_action_group" "budget_alerts" {
  count = var.enable_budget_alerts ? 1 : 0

  name                = "${var.project}-${var.environment}-budget-alerts"
  resource_group_name = var.resource_group_name
  short_name          = "BudgetAlert"

  # Add email notifications
  email_receiver {
    name                    = "BudgetTeam"
    email_address           = "budget-alerts@tripradar.io" # Update with actual email
    use_common_alert_schema = true
  }

  tags = merge(var.tags, {
    Environment = var.environment
    Project     = var.project
    Purpose     = "CostManagement"
  })
}
