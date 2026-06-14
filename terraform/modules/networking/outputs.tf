# ──────────────────────────────────────────────────────────
# Networking Module Outputs
# ──────────────────────────────────────────────────────────
# These values are consumed by environments/dev/main.tf and
# passed onward to future modules (AKS, identity, monitoring).
# ──────────────────────────────────────────────────────────

# ── Log Analytics ──
output "log_analytics_workspace_id" {
  description = "Resource ID of the central Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace (for KQL queries)"
  value       = azurerm_log_analytics_workspace.main.name
}

# ── Hub Network ──
output "hub_vnet_id" {
  description = "Resource ID of the hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "hub_vnet_name" {
  description = "Name of the hub VNet"
  value       = azurerm_virtual_network.hub.name
}

# ── Spoke Network ──
output "spoke_vnet_id" {
  description = "Resource ID of the spoke VNet"
  value       = azurerm_virtual_network.spoke.id
}

output "spoke_app_subnet_id" {
  description = "Subnet ID for app-tier workloads (AKS, App Service, etc.)"
  value       = azurerm_subnet.app.id
}

output "spoke_data_subnet_id" {
  description = "Subnet ID for data-tier resources (SQL, Storage private endpoints)"
  value       = azurerm_subnet.data.id
}

# ── Firewall ──
output "firewall_private_ip" {
  description = "Firewall private IP — used as next-hop in spoke route tables"
  value       = var.deploy_firewall ? azurerm_firewall.main[0].ip_configuration[0].private_ip_address : null
}

# ── Resource Groups ──
output "hub_resource_group_name" {
  description = "Name of the hub resource group"
  value       = azurerm_resource_group.hub.name
}

output "spoke_resource_group_name" {
  description = "Name of the spoke resource group"
  value       = azurerm_resource_group.spoke.name
}
