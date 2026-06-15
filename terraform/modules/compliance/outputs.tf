# ──────────────────────────────────────────────────────────────
# Compliance module — outputs
# ──────────────────────────────────────────────────────────────

output "resource_group_name" {
  description = "Compliance resource group name"
  value       = azurerm_resource_group.compliance.name
}

# ── Private endpoints ────────────────────────────────────────
output "kv_private_endpoint_ip" {
  description = "Key Vault private endpoint IP"
  value       = var.deploy_private_endpoints ? azurerm_private_endpoint.kv[0].private_service_connection[0].private_ip_address : null
}

output "acr_private_endpoint_ip" {
  description = "ACR private endpoint IP"
  value       = var.deploy_private_endpoints ? azurerm_private_endpoint.acr[0].private_service_connection[0].private_ip_address : null
}

output "openai_private_endpoint_ip" {
  description = "Azure OpenAI private endpoint IP"
  value       = var.deploy_private_endpoints && var.openai_id != "" ? azurerm_private_endpoint.openai[0].private_service_connection[0].private_ip_address : null
}

output "aml_private_endpoint_ip" {
  description = "AML Workspace private endpoint IP"
  value       = var.deploy_private_endpoints ? azurerm_private_endpoint.aml[0].private_service_connection[0].private_ip_address : null
}

# ── CMK ──────────────────────────────────────────────────────
output "cmk_key_id" {
  description = "Customer-Managed Key ID in Key Vault"
  value       = var.deploy_cmk ? azurerm_key_vault_key.cmk[0].id : null
}

output "cmk_key_name" {
  description = "CMK key name"
  value       = var.deploy_cmk ? azurerm_key_vault_key.cmk[0].name : null
}

# ── Audit storage ────────────────────────────────────────────
output "audit_storage_account_id" {
  description = "Immutable audit storage account ID"
  value       = var.deploy_immutable_storage ? azurerm_storage_account.audit[0].id : null
}

output "audit_storage_account_name" {
  description = "Immutable audit storage account name"
  value       = var.deploy_immutable_storage ? azurerm_storage_account.audit[0].name : null
}

# ── Purview ──────────────────────────────────────────────────
output "purview_account_id" {
  description = "Purview account ID"
  value       = var.deploy_purview ? azurerm_purview_account.purview[0].id : null
}
