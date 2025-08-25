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

  delegation {
    name = "delegation"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_subnet" "subnet_data" {
  count                = var.enable_vnet ? 1 : 0
  name                 = "data"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [var.subnet_data_cidr]
}


# Subnet for Private Endpoints
resource "azurerm_subnet" "subnet_private_endpoints" {
  count                = var.enable_vnet ? 1 : 0
  name                 = "privatelink"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [var.subnet_private_endpoints_cidr]

  private_endpoint_network_policies = "Disabled"
}

# GatewaySubnet required for Virtual Network Gateway
resource "azurerm_subnet" "subnet_gateway" {
  count                = var.enable_vnet ? 1 : 0
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[0].name
  address_prefixes     = [var.subnet_gateway_cidr]
}

