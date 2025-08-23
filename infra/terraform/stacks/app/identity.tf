# User Assigned Managed Identities for Container Apps

resource "azurerm_user_assigned_identity" "api" {
  name                = "${var.project}-${var.environment}-api-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

resource "azurerm_user_assigned_identity" "jobs" {
  name                = "${var.project}-${var.environment}-jobs-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

resource "azurerm_user_assigned_identity" "db" {
  name                = "${var.project}-${var.environment}-db-mi"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

