# Private Endpoints and Private DNS Zones (conditional)

# Key Vault
resource "azurerm_private_dns_zone" "kv" {
  count               = var.enable_private_endpoints && var.enable_key_vault ? 1 : 0
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  count                 = var.enable_private_endpoints && var.enable_key_vault ? 1 : 0
  name                  = "${var.project}-${var.environment}-kv-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.kv[0].name
  virtual_network_id    = azurerm_virtual_network.vnet[0].id
}

resource "azurerm_private_endpoint" "kv" {
  count               = var.enable_private_endpoints && var.enable_key_vault ? 1 : 0
  name                = "${var.project}-${var.environment}-kv-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_private_endpoints[0].id

  private_service_connection {
    name                           = "kv-psc"
    private_connection_resource_id = azurerm_key_vault.kv[0].id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.kv[0].id]
  }
}

# Event Hubs
resource "azurerm_private_dns_zone" "eh" {
  count               = var.enable_private_endpoints && var.enable_event_hubs ? 1 : 0
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "eh" {
  count                 = var.enable_private_endpoints && var.enable_event_hubs ? 1 : 0
  name                  = "${var.project}-${var.environment}-eh-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.eh[0].name
  virtual_network_id    = azurerm_virtual_network.vnet[0].id
}

resource "azurerm_private_endpoint" "eh" {
  count               = var.enable_private_endpoints && var.enable_event_hubs ? 1 : 0
  name                = "${var.project}-${var.environment}-eh-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_private_endpoints[0].id

  private_service_connection {
    name                           = "eh-psc"
    private_connection_resource_id = azurerm_eventhub_namespace.eh[0].id
    is_manual_connection           = false
    subresource_names              = ["namespace"]
  }

  private_dns_zone_group {
    name                 = "eh-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.eh[0].id]
  }
}

# PostgreSQL Flexible Server
resource "azurerm_private_dns_zone" "pg" {
  count               = var.enable_private_endpoints && var.enable_postgres ? 1 : 0
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pg" {
  count                 = var.enable_private_endpoints && var.enable_postgres ? 1 : 0
  name                  = "${var.project}-${var.environment}-pg-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.pg[0].name
  virtual_network_id    = azurerm_virtual_network.vnet[0].id
}

resource "azurerm_private_endpoint" "pg" {
  count               = var.enable_private_endpoints && var.enable_postgres ? 1 : 0
  name                = "${var.project}-${var.environment}-pg-pe"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_private_endpoints[0].id

  private_service_connection {
    name                           = "pg-psc"
    private_connection_resource_id = azurerm_postgresql_flexible_server.pg[0].id
    is_manual_connection           = false
    subresource_names              = ["postgresqlServer"]
  }

  private_dns_zone_group {
    name                 = "pg-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.pg[0].id]
  }
}
