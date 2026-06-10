# ──────────────────────────────────────────────────────────
# Network Security Groups (NSGs)
# ──────────────────────────────────────────────────────────
# NOTE: AzureFirewallSubnet and GatewaySubnet do NOT support
# custom NSGs — Azure manages those internally. We only
# create NSGs for Bastion, App, and Data subnets.
# ──────────────────────────────────────────────────────────

# ── Hub: Bastion NSG ─────────────────────────────────────
# Azure Bastion requires specific inbound/outbound rules.
# See: https://learn.microsoft.com/en-us/azure/bastion/bastion-nsg

resource "azurerm_network_security_group" "bastion" {
  name                = "nsg-bastion-${var.env}-${var.region}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  tags                = var.tags

  # Inbound: Allow HTTPS from internet (Bastion portal access)
  security_rule {
    name                       = "AllowHttpsInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  # Inbound: Allow Gateway Manager (Azure control plane)
  security_rule {
    name                       = "AllowGatewayManagerInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  # Outbound: Allow SSH/RDP to spoke VNets (Bastion → target VMs)
  security_rule {
    name                       = "AllowSshRdpOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "*"
    destination_address_prefix = "VirtualNetwork"
  }

  # Outbound: Allow HTTPS to Azure Cloud (for Bastion telemetry)
  security_rule {
    name                       = "AllowAzureCloudOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "AzureCloud"
  }
}

resource "azurerm_subnet_network_security_group_association" "bastion" {
  subnet_id                 = azurerm_subnet.bastion.id
  network_security_group_id = azurerm_network_security_group.bastion.id
}

# ── Spoke: App Subnet NSG ───────────────────────────────
# App tier: allows traffic from hub (Bastion/Firewall) and
# blocks direct internet inbound.

resource "azurerm_network_security_group" "app" {
  name                = "nsg-app-${var.env}-${var.region}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags

  # Inbound: Allow SSH/RDP from Bastion subnet only
  security_rule {
    name                       = "AllowBastionInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "10.0.2.0/26"
    destination_address_prefix = "*"
  }

  # Inbound: Allow HTTPS from hub (e.g., firewall forwarded traffic)
  security_rule {
    name                       = "AllowHttpsFromHub"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Inbound: Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Outbound: Allow to data subnet (app → database)
  security_rule {
    name                       = "AllowToDataSubnet"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1433", "5432", "3306"]
    source_address_prefix      = "*"
    destination_address_prefix = "10.1.1.0/24"
  }

  # Outbound: Allow HTTPS out (for external APIs, updates)
  security_rule {
    name                       = "AllowHttpsOutbound"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# ── Spoke: Data Subnet NSG ──────────────────────────────
# Data tier: ONLY accepts traffic from the app subnet.
# No direct internet access in or out.

resource "azurerm_network_security_group" "data" {
  name                = "nsg-data-${var.env}-${var.region}"
  location            = azurerm_resource_group.spoke.location
  resource_group_name = azurerm_resource_group.spoke.name
  tags                = var.tags

  # Inbound: Allow database ports from app subnet only
  security_rule {
    name                       = "AllowFromAppSubnet"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1433", "5432", "3306"]
    source_address_prefix      = "10.1.0.0/24"
    destination_address_prefix = "*"
  }

  # Inbound: Allow Bastion SSH for maintenance
  security_rule {
    name                       = "AllowBastionInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["22", "3389"]
    source_address_prefix      = "10.0.2.0/26"
    destination_address_prefix = "*"
  }

  # Inbound: Deny everything else
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Outbound: Deny internet access (data tier stays isolated)
  security_rule {
    name                       = "DenyInternetOutbound"
    priority                   = 4096
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}
