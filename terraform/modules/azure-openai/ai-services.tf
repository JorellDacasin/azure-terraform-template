# ──────────────────────────────────────────────────────────────
# Azure AI Services (formerly Cognitive Services)
# Multi-service account — one resource gives access to:
#   - Vision (image analysis, OCR)
#   - Speech (transcription, text-to-speech)
#   - Language (sentiment, NER, summarization, translation)
#   - Decision (anomaly detection, personalizer)
#
# One API key, one endpoint, multiple capabilities.
# S0 SKU — pay-per-call, no monthly base cost for most APIs.
#
# Cost toggle: var.deploy_ai_services (default FALSE — enable
# when learning vision/speech/language APIs).
#
# Interview note: "For LifeCare, the Language service handles
# medical document summarization and entity extraction (patient
# names, diagnoses, medications). The Speech service transcribes
# doctor-patient recordings for documentation."
# ──────────────────────────────────────────────────────────────

resource "azurerm_cognitive_account" "ai_services" {
  count = var.deploy_ai_services ? 1 : 0

  name                = "ais-${var.org_prefix}-${var.workload}-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
  kind                = "CognitiveServices"    # Multi-service account
  sku_name            = "S0"

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
