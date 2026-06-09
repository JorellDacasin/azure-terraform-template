output "resource_group_name" {
  description = "Resource group holding the tfstate storage account"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Storage account name — use this in the backend block"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Blob container name — use this in the backend block"
  value       = azurerm_storage_container.tfstate.name
}
