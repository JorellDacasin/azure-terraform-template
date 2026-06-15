# ──────────────────────────────────────────────────────────────
# Azure OpenAI + AI Services module — outputs
# Endpoints and IDs for application integration and Phase 6
# (compliance hardening — private endpoints, CMK).
# ──────────────────────────────────────────────────────────────

# ── Resource Group ───────────────────────────────────────────
output "resource_group_name" {
  description = "AI resource group name"
  value       = azurerm_resource_group.ai.name
}

# ── Azure OpenAI ─────────────────────────────────────────────
output "openai_endpoint" {
  description = "Azure OpenAI endpoint URL"
  value       = var.deploy_openai ? azurerm_cognitive_account.openai[0].endpoint : null
}

output "openai_id" {
  description = "Azure OpenAI resource ID"
  value       = var.deploy_openai ? azurerm_cognitive_account.openai[0].id : null
}

output "openai_primary_key" {
  description = "Azure OpenAI primary access key (sensitive)"
  value       = var.deploy_openai ? azurerm_cognitive_account.openai[0].primary_access_key : null
  sensitive   = true
}

output "gpt_deployment_name" {
  description = "GPT model deployment name (use in API calls)"
  value       = var.deploy_openai ? azurerm_cognitive_deployment.gpt[0].name : null
}

output "embedding_deployment_name" {
  description = "Embedding model deployment name (use in API calls)"
  value       = var.deploy_openai ? azurerm_cognitive_deployment.embedding[0].name : null
}

# ── AI Search ────────────────────────────────────────────────
output "search_endpoint" {
  description = "AI Search endpoint URL"
  value       = var.deploy_ai_search ? "https://${azurerm_search_service.search[0].name}.search.windows.net" : null
}

output "search_id" {
  description = "AI Search resource ID"
  value       = var.deploy_ai_search ? azurerm_search_service.search[0].id : null
}

# ── AI Services ──────────────────────────────────────────────
output "ai_services_endpoint" {
  description = "AI Services multi-service endpoint URL"
  value       = var.deploy_ai_services ? azurerm_cognitive_account.ai_services[0].endpoint : null
}

output "ai_services_id" {
  description = "AI Services resource ID"
  value       = var.deploy_ai_services ? azurerm_cognitive_account.ai_services[0].id : null
}

# ── Content Safety ───────────────────────────────────────────
output "content_safety_endpoint" {
  description = "Content Safety endpoint URL"
  value       = var.deploy_content_safety ? azurerm_cognitive_account.content_safety[0].endpoint : null
}

output "content_safety_id" {
  description = "Content Safety resource ID"
  value       = var.deploy_content_safety ? azurerm_cognitive_account.content_safety[0].id : null
}
