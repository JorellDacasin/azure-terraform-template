# ──────────────────────────────────────────────────────────
# VNet Peering: Hub ↔ Spoke
# ──────────────────────────────────────────────────────────
# Peering is NOT bidirectional by default — you must create
# a peering resource in BOTH directions. Without peering,
# hub and spoke VNets cannot communicate at all.
# ──────────────────────────────────────────────────────────

# ── Hub → Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-spoke-${var.env}"
  resource_group_name       = azurerm_resource_group.hub.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id

  # Allow traffic forwarded by the firewall to reach the spoke
  allow_forwarded_traffic = true

  # Let the hub share its VPN/ExpressRoute gateway with spokes
  # Set to false for now — no gateway resource deployed yet (Phase 2+)
  allow_gateway_transit = false

  # Hub doesn't use anyone else's gateway
  use_remote_gateways = false
}

# ── Spoke → Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-spoke-to-hub-${var.env}"
  resource_group_name       = azurerm_resource_group.spoke.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id

  # Allow traffic forwarded by the firewall back to the spoke
  allow_forwarded_traffic = true

  # Spoke doesn't share gateways
  allow_gateway_transit = false

  # Set to true later when hub has a VPN/ExpressRoute gateway
  # This tells the spoke: "use the hub's gateway for on-prem traffic"
  use_remote_gateways = false
}
