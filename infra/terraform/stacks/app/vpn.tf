# Virtual Network Gateway for VPN (conditional)

resource "azurerm_public_ip" "vpngw" {
  count               = var.enable_vpn && var.enable_vnet ? 1 : 0
  name                = "${var.project}-${var.environment}-vpngw-pip"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = merge(var.tags, { Environment = var.environment, Project = var.project })
}

resource "azurerm_virtual_network_gateway" "vpngw" {
  count               = var.enable_vpn && var.enable_vnet ? 1 : 0
  name                = "${var.project}-${var.environment}-vpngw"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = var.vpn_type
  sku      = var.vpn_sku
  generation = var.vpn_gateway_generation

  active_active = false
  enable_bgp    = false

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.vpngw[0].id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.subnet_gateway[0].id
  }

  depends_on = [
    azurerm_subnet.subnet_gateway
  ]
}

# Local Network Gateway representing on-premises
resource "azurerm_local_network_gateway" "onprem" {
  count               = var.enable_vpn && var.enable_vnet && var.enable_vpn_connection ? 1 : 0
  name                = "${var.project}-${var.environment}-lng"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  gateway_address = var.local_network_gateway_address
  address_space   = var.local_network_address_space
}

# S2S VPN Connection
resource "azurerm_virtual_network_gateway_connection" "s2s" {
  count               = var.enable_vpn && var.enable_vnet && var.enable_vpn_connection ? 1 : 0
  name                = "${var.project}-${var.environment}-s2s"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngw[0].id
  local_network_gateway_id   = azurerm_local_network_gateway.onprem[0].id
  shared_key                 = var.vpn_shared_key

  depends_on = [
    azurerm_virtual_network_gateway.vpngw,
    azurerm_local_network_gateway.onprem
  ]
}
