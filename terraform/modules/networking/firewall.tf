# ──────────────────────────────────────────────────────────
# Azure Firewall (Standard SKU)
# ──────────────────────────────────────────────────────────
# Sits in the hub VNet's AzureFirewallSubnet (10.0.0.0/26).
# All spoke traffic routes through here for centralized
# inspection, filtering, and logging.
#
# Cost note: Standard SKU ~$1.25/hr (~$900/month).
# Use var.deploy_firewall to toggle off in dev if needed.
# ──────────────────────────────────────────────────────────

# ── Toggle: set to false in dev to skip firewall and save cost
variable "deploy_firewall" {
  description = "Set to false to skip Azure Firewall deployment (saves ~$900/month in dev)"
  type        = bool
  default     = true
}

# ── Public IP for Azure Firewall (required for outbound traffic)
resource "azurerm_public_ip" "firewall" {
  count               = var.deploy_firewall ? 1 : 0
  name                = "pip-afw-${var.env}-${var.region}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  allocation_method   = "Static"
  sku                 = "Standard"   # Standard SKU required for Azure Firewall
  tags                = var.tags
}

# ── Firewall Policy (ruleset container)
# Rules are organized: Policy → Rule Collection Group → Rule Collection → Rules
resource "azurerm_firewall_policy" "main" {
  count               = var.deploy_firewall ? 1 : 0
  name                = "afwp-${var.env}-${var.region}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "Standard"
  tags                = var.tags

  # Enable DNS proxy so spokes can use the firewall as their DNS server
  dns {
    proxy_enabled = true
  }
}

# ── Azure Firewall resource
resource "azurerm_firewall" "main" {
  count               = var.deploy_firewall ? 1 : 0
  name                = "afw-${var.env}-${var.region}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku_name            = "AZFW_VNet"
  sku_tier            = "Standard"
  firewall_policy_id  = azurerm_firewall_policy.main[0].id
  tags                = var.tags

  ip_configuration {
    name                 = "fw-ipconfig"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

# ── Rule Collection Group: Network Rules
# Controls port/protocol-level traffic (Layer 4)
resource "azurerm_firewall_policy_rule_collection_group" "network" {
  count              = var.deploy_firewall ? 1 : 0
  name               = "rcg-network-${var.env}"
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 200

  # Allow spoke-to-spoke traffic (app ↔ data)
  network_rule_collection {
    name     = "rc-spoke-internal"
    priority = 210
    action   = "Allow"

    rule {
      name                  = "AllowSpokeToSpoke"
      protocols             = ["TCP", "UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["10.1.0.0/16"]
      destination_ports     = ["*"]
    }
  }

  # Allow spoke-to-internet DNS (UDP 53)
  network_rule_collection {
    name     = "rc-dns-outbound"
    priority = 220
    action   = "Allow"

    rule {
      name                  = "AllowDNS"
      protocols             = ["UDP"]
      source_addresses      = ["10.1.0.0/16"]
      destination_addresses = ["*"]
      destination_ports     = ["53"]
    }
  }
}

# ── Rule Collection Group: Application Rules
# Controls FQDN-based traffic (Layer 7 — HTTP/HTTPS)
resource "azurerm_firewall_policy_rule_collection_group" "application" {
  count              = var.deploy_firewall ? 1 : 0
  name               = "rcg-application-${var.env}"
  firewall_policy_id = azurerm_firewall_policy.main[0].id
  priority           = 300

  # Allow outbound HTTPS to essential Azure services
  application_rule_collection {
    name     = "rc-azure-services"
    priority = 310
    action   = "Allow"

    rule {
      name = "AllowAzureServices"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.1.0.0/16"]
      destination_fqdns = [
        "*.microsoft.com",
        "*.azure.com",
        "*.windows.net",
        "*.azurecr.io",           # Azure Container Registry
        "*.blob.core.windows.net", # Storage
        "*.database.windows.net",  # Azure SQL
      ]
    }
  }

  # Allow outbound to package managers (for VM/container updates)
  application_rule_collection {
    name     = "rc-package-updates"
    priority = 320
    action   = "Allow"

    rule {
      name = "AllowPackageManagers"
      protocols {
        type = "Https"
        port = 443
      }
      source_addresses  = ["10.1.0.0/16"]
      destination_fqdns = [
        "*.ubuntu.com",
        "*.docker.io",
        "*.docker.com",
        "registry.npmjs.org",
        "pypi.org",
        "*.pypi.org",
      ]
    }
  }
}
