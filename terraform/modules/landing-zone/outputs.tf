output "management_group_ids" {
  description = "Map of all management group IDs for use in policy assignments and RBAC"
  value = {
    org_root              = azurerm_management_group.org_root.id
    platform              = azurerm_management_group.platform.id
    platform_connectivity = azurerm_management_group.platform_connectivity.id
    platform_identity     = azurerm_management_group.platform_identity.id
    platform_management   = azurerm_management_group.platform_management.id
    landing_zones         = azurerm_management_group.landing_zones.id
    corp                  = azurerm_management_group.landing_zones_corp.id
    online                = azurerm_management_group.landing_zones_online.id
    sandbox               = azurerm_management_group.sandbox.id
    decommissioned        = azurerm_management_group.decommissioned.id
  }
}

output "name" {
  description = "Computed resource names map — use these everywhere instead of hardcoding"
  value       = local.name
}

output "tags" {
  description = "Merged tag set to apply to all resources"
  value       = local.tags
}
