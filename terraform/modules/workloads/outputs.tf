# ──────────────────────────────────────────────────────────────
# Workloads module — outputs
# Exports resource IDs for use by future phases:
#   Phase 5 (ML/AI) may deploy models behind APIM
#   Phase 6 (compliance) adds private endpoints + CMK
# ──────────────────────────────────────────────────────────────

# ── Resource Group ───────────────────────────────────────────
output "resource_group_name" {
  description = "Workloads resource group name"
  value       = azurerm_resource_group.workloads.name
}

output "resource_group_id" {
  description = "Workloads resource group ID"
  value       = azurerm_resource_group.workloads.id
}

# ── ACR ──────────────────────────────────────────────────────
output "acr_id" {
  description = "Container Registry resource ID"
  value       = azurerm_container_registry.acr.id
}

output "acr_login_server" {
  description = "ACR login server URL (e.g. acrjdplatformdevuae.azurecr.io)"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  description = "Container Registry name"
  value       = azurerm_container_registry.acr.name
}

# ── AKS ──────────────────────────────────────────────────────
output "aks_id" {
  description = "AKS cluster resource ID"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_fqdn" {
  description = "AKS cluster FQDN (API server endpoint)"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_kubelet_identity_object_id" {
  description = "Kubelet managed identity object ID (used for ACR pull)"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "kube_config_raw" {
  description = "Raw kubeconfig for kubectl access (sensitive)"
  value       = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive   = true
}

# ── SQL (conditional) ────────────────────────────────────────
output "sql_server_fqdn" {
  description = "SQL Server fully qualified domain name"
  value       = var.deploy_sql ? azurerm_mssql_server.sql[0].fully_qualified_domain_name : null
}

output "sql_server_id" {
  description = "SQL Server resource ID"
  value       = var.deploy_sql ? azurerm_mssql_server.sql[0].id : null
}

output "sql_database_name" {
  description = "SQL Database name"
  value       = var.deploy_sql ? azurerm_mssql_database.db[0].name : null
}

# ── App Service (conditional) ────────────────────────────────
output "app_service_url" {
  description = "Web app default hostname"
  value       = var.deploy_app_service ? "https://${azurerm_linux_web_app.app[0].default_hostname}" : null
}

output "app_service_id" {
  description = "Web app resource ID"
  value       = var.deploy_app_service ? azurerm_linux_web_app.app[0].id : null
}

# ── APIM (conditional) ───────────────────────────────────────
output "apim_gateway_url" {
  description = "APIM gateway URL"
  value       = var.deploy_apim ? azurerm_api_management.apim[0].gateway_url : null
}

output "apim_id" {
  description = "APIM resource ID"
  value       = var.deploy_apim ? azurerm_api_management.apim[0].id : null
}
