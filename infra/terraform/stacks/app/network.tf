# Virtual Network and subnets (reserved for future integration)
resource "azurerm_virtual_network" "vnet" {
  count               = var.enable_vnet ? 1 : 0
  name                = "${var.project}-${var.environment}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = var.vnet_address_space
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

resource "azurerm_subnet" "subnet_cae" {
  count                = var.enable_vnet ? 1 : 0
  name                 = "cae"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [var.subnet_cae_cidr]
}

resource "azurerm_subnet" "subnet_data" {
  count                = var.enable_vnet ? 1 : 0
  name                 = "data"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [var.subnet_data_cidr]
}
