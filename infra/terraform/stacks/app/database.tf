# PostgreSQL Flexible Server (optional)
resource "random_password" "pg_admin" {
  count   = var.enable_postgres && var.postgres_administrator_password == null ? 1 : 0
  length  = 24
  special = true
}

resource "azurerm_postgresql_flexible_server" "pg" {
  count               = var.enable_postgres ? 1 : 0
  name                = coalesce(var.postgres_server_name, lower(replace("${var.project}-${var.environment}-pg", "_", "-")))
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  version  = var.postgres_version
  sku_name = var.postgres_sku_name
  zone     = "1"

  storage_mb = var.postgres_storage_mb

  administrator_login           = var.postgres_administrator_login
  administrator_password        = var.postgres_administrator_password != null ? var.postgres_administrator_password : random_password.pg_admin[0].result
  public_network_access_enabled = var.postgres_public_network_access_enabled

  # Note: For private access, configure delegated subnet and private DNS zones.
  # delegated_subnet_id = azurerm_subnet.subnet_data[0].id

  tags = merge(var.tags, { Environment = var.environment, Project = var.project })
  lifecycle {
    prevent_destroy = true
  }
}

# Management lock to prevent accidental deletion of the PostgreSQL server
resource "azurerm_management_lock" "pg_cannot_delete" {
  count      = var.enable_postgres ? 1 : 0
  name       = "${var.project}-${var.environment}-pg-lock"
  scope      = azurerm_postgresql_flexible_server.pg[0].id
  lock_level = "CanNotDelete"
  notes      = "Prevent accidental deletion of PostgreSQL server"
}

# Create the application database
resource "azurerm_postgresql_flexible_server_database" "tripradar" {
  count     = var.enable_postgres ? 1 : 0
  name      = var.postgres_database_name
  server_id = azurerm_postgresql_flexible_server.pg[0].id
  collation = "en_US.utf8"
  charset   = "utf8"
  lifecycle {
    prevent_destroy = true
  }
}
