resource "azurerm_resource_group" "spoke" {
  name     = "rg-spoke-${var.env}-${var.region}"
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-${var.env}-${var.region}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  address_space       = ["10.1.0.0/16"] # must not overlap with hub (10.0.0.0/16)
  tags                = var.tags
}

# App tier — for workloads like AKS (Phase 4)
resource "azurerm_subnet" "app" {
  name                 = "snet-app-${var.env}-${var.region}"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.0.0/24"] # 256 addresses
}

# Data tier — for databases and storage (Phase 4)
resource "azurerm_subnet" "data" {
  name                 = "snet-data-${var.env}-${var.region}"
  resource_group_name  = azurerm_resource_group.spoke.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = ["10.1.1.0/24"] # 256 addresses
}
