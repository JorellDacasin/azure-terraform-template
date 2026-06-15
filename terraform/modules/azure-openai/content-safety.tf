# ──────────────────────────────────────────────────────────────
# Azure Content Safety
# Filters harmful content from AI inputs and outputs.
# Categories: hate, violence, sexual, self-harm.
# Returns severity scores (0-6) per category — your app decides
# the threshold.
#
# Built into Azure OpenAI by default (can't disable), but a
# standalone Content Safety resource lets you:
#   - Filter non-OpenAI content (user uploads, chat messages)
#   - Use custom blocklists (e.g. drug names, medical terms)
#   - Call the API independently of OpenAI
#
# S0 SKU — pay-per-call. Free tier: 5K calls/month.
#
# Interview note: "Content Safety is non-negotiable for
# healthcare AI. A patient-facing chatbot must filter harmful
# responses before they reach the user. I deploy it standalone
# so it also filters user-uploaded content, not just model
# outputs."
# ──────────────────────────────────────────────────────────────

resource "azurerm_cognitive_account" "content_safety" {
  count = var.deploy_content_safety ? 1 : 0

  name                = "cs-${var.org_prefix}-${var.workload}-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
  kind                = "ContentSafety"
  sku_name            = "S0"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
