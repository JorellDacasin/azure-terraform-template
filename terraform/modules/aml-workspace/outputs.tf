# ──────────────────────────────────────────────────────────────
# AML Workspace module — outputs
# ──────────────────────────────────────────────────────────────

output "workspace_id" {
  description = "AML Workspace resource ID"
  value       = azurerm_machine_learning_workspace.ml.id
}

output "workspace_name" {
  description = "AML Workspace name"
  value       = azurerm_machine_learning_workspace.ml.name
}

output "resource_group_name" {
  description = "ML resource group name"
  value       = azurerm_resource_group.ml.name
}

output "storage_account_id" {
  description = "AML Storage Account resource ID"
  value       = azurerm_storage_account.ml.id
}

output "application_insights_id" {
  description = "Application Insights resource ID (for endpoint monitoring)"
  value       = azurerm_application_insights.ml.id
}
