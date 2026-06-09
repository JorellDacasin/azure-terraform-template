resource "azurerm_resource_group" "hub" {
  name     = "rg-hub-${var.env}-${var.region}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub-${var.env}-${var.region}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}

# Required by Azure Firewall — name must be exactly "AzureFirewallSubnet"
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/26"]   # /26 minimum required by Azure Firewall
}

# Required by VPN / ExpressRoute Gateway — name must be exactly "GatewaySubnet"
resource "azurerm_subnet" "gateway" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/27"]   # /27 minimum required by Gateway
}

# Required by Azure Bastion — name must be exactly "AzureBastionSubnet"
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.hub.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/26"]   # /26 minimum required by Bastion
}
