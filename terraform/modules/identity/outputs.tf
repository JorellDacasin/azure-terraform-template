output "terraform_sp_client_id" {
  description = "Client ID of the Terraform service principal (use as ARM_CLIENT_ID)"
  value       = azuread_application.terraform.client_id
}

output "terraform_sp_object_id" {
  description = "Object ID of the Terraform service principal"
  value       = azuread_service_principal.terraform.object_id
}

output "pipeline_sp_client_id" {
  description = "Client ID of the pipeline service principal"
  value       = azuread_application.pipeline.client_id
}

output "pipeline_sp_object_id" {
  description = "Object ID of the pipeline service principal"
  value       = azuread_service_principal.pipeline.object_id
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault (used by apps to fetch secrets)"
  value       = azurerm_key_vault.main.vault_uri
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "identity_rg_name" {
  description = "Name of the identity resource group"
  value       = azurerm_resource_group.identity.name
}
