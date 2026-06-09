# CAF Management Group hierarchy
#
# Tenant Root Group (auto-exists, not managed here)
# └── org-root  (top-level MG — one per organisation)
#     ├── platform       (shared services: connectivity, identity, management)
#     │   ├── connectivity   (hub VNet, Firewall, ExpressRoute/VPN)
#     │   ├── identity       (AD DS, AAD Connect, PIM)
#     │   └── management     (Log Analytics, Defender, Update Mgmt)
#     ├── landing-zones  (workload subscriptions live here)
#     │   ├── corp           (corp-connected workloads, e.g. LifeCare internal)
#     │   └── online         (internet-facing, e.g. public APIs)
#     ├── sandbox        (dev/experimentation — relaxed policy)
#     └── decommissioned (subscriptions pending removal — deny-all policy)

data "azurerm_client_config" "current" {}

resource "azurerm_management_group" "org_root" {
  name         = "${var.org_prefix}-root"
  display_name = "${upper(var.org_prefix)} Root"
}

resource "azurerm_management_group" "platform" {
  name                       = "${var.org_prefix}-platform"
  display_name               = "Platform"
  parent_management_group_id = azurerm_management_group.org_root.id
}

resource "azurerm_management_group" "platform_connectivity" {
  name                       = "${var.org_prefix}-connectivity"
  display_name               = "Connectivity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "platform_identity" {
  name                       = "${var.org_prefix}-identity"
  display_name               = "Identity"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "platform_management" {
  name                       = "${var.org_prefix}-management"
  display_name               = "Management"
  parent_management_group_id = azurerm_management_group.platform.id
}

resource "azurerm_management_group" "landing_zones" {
  name                       = "${var.org_prefix}-landing-zones"
  display_name               = "Landing Zones"
  parent_management_group_id = azurerm_management_group.org_root.id
}

resource "azurerm_management_group" "landing_zones_corp" {
  name                       = "${var.org_prefix}-corp"
  display_name               = "Corp"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "landing_zones_online" {
  name                       = "${var.org_prefix}-online"
  display_name               = "Online"
  parent_management_group_id = azurerm_management_group.landing_zones.id
}

resource "azurerm_management_group" "sandbox" {
  name                       = "${var.org_prefix}-sandbox"
  display_name               = "Sandbox"
  parent_management_group_id = azurerm_management_group.org_root.id
}

resource "azurerm_management_group" "decommissioned" {
  name                       = "${var.org_prefix}-decommissioned"
  display_name               = "Decommissioned"
  parent_management_group_id = azurerm_management_group.org_root.id
}
