# ──────────────────────────────────────────────────────────────
# Azure Container Registry (ACR)
# Private Docker registry — AKS pulls images from here.
#
# Basic SKU: 10 GB storage, 2 webhooks, cheapest tier.
# Admin DISABLED — AKS authenticates via managed identity with
# AcrPull role (set up in aks.tf). Never use admin credentials.
#
# ACR names are globally unique DNS hostnames — no hyphens,
# lowercase, max 50 chars. e.g. acrjdplatformdevuae.azurecr.io
# ──────────────────────────────────────────────────────────────

resource "azurerm_container_registry" "acr" {
  name                = "acr${var.org_prefix}${var.workload}${var.env}${var.region}"
  resource_group_name = azurerm_resource_group.workloads.name
  location            = azurerm_resource_group.workloads.location
  sku                 = "Basic"
  admin_enabled       = false

  tags = var.tags
}
