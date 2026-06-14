# ──────────────────────────────────────────────────────────────
# API Management (APIM)
# API gateway — sits in front of AKS and App Service backends.
# Handles rate limiting, API keys, caching, request/response
# transformation, and generates a developer portal.
#
# Consumption tier: pay-per-call, no monthly base cost.
# First 1M calls/month free. Takes ~5 min to provision.
#
# Cost toggle: var.deploy_apim (default FALSE — not needed for
# basic training, enable when learning API gateway patterns).
#
# Interview note: "APIM gives me a single entry point for all
# APIs. I can enforce rate limits, require API keys, and version
# APIs without changing the backend code. For healthcare APIs
# (LifeCare), it also provides audit logging for every call."
# ──────────────────────────────────────────────────────────────

resource "azurerm_api_management" "apim" {
  count = var.deploy_apim ? 1 : 0

  name                = "apim-${var.org_prefix}-${var.workload}-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.workloads.name
  location            = azurerm_resource_group.workloads.location
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email

  # Consumption: serverless, pay-per-call. The "_0" suffix is
  # required by the Azure API — it means 0 dedicated units
  # (all compute is shared/serverless).
  sku_name = "Consumption_0"

  tags = var.tags
}
