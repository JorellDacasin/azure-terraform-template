# ──────────────────────────────────────────────────────────────
# Azure OpenAI Service
# Managed OpenAI models (GPT-4o, embeddings) behind Azure's
# enterprise security — VNet integration, RBAC, managed keys,
# content filtering built-in.
#
# Two model deployments:
#   1. GPT-4o — chat/reasoning for AI assistants
#   2. text-embedding-3-small — vector embeddings for RAG
#      (retrieval-augmented generation with AI Search)
#
# Pay-per-token, no idle cost. S0 SKU is the only option.
#
# IMPORTANT: Azure OpenAI is region-limited. UAE North may not
# support it — var.openai_location defaults to Sweden Central.
# For strict data residency, evaluate Azure-approved regions.
#
# Interview note: "I deploy Azure OpenAI instead of calling the
# public OpenAI API because it gives me VNet integration, RBAC,
# audit logging, and content filtering — all required for
# healthcare data. The model runs inside Azure's boundary."
# ──────────────────────────────────────────────────────────────

# ── Resource Group (OpenAI may be in a different region) ─────
resource "azurerm_resource_group" "ai" {
  name     = "rg-ai-${var.env}-${var.region}"
  location = var.location
  tags     = var.tags
}

# ── Azure OpenAI Account ─────────────────────────────────────
resource "azurerm_cognitive_account" "openai" {
  count = var.deploy_openai ? 1 : 0

  name                = "oai-${var.org_prefix}-${var.workload}-${var.env}"
  resource_group_name = azurerm_resource_group.ai.name
  location            = var.openai_location     # May differ from primary region
  kind                = "OpenAI"
  sku_name            = "S0"                    # Only option for OpenAI

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# ── GPT-4o deployment ────────────────────────────────────────
# Chat/reasoning model. Capacity = tokens-per-minute (TPM).
# 10K TPM is the minimum useful allocation for dev.
resource "azurerm_cognitive_deployment" "gpt" {
  count = var.deploy_openai ? 1 : 0

  name                 = var.gpt_model_name
  cognitive_account_id = azurerm_cognitive_account.openai[0].id

  model {
    format  = "OpenAI"
    name    = var.gpt_model_name
    version = var.gpt_model_version
  }

  sku {
    name     = "Standard"
    capacity = var.gpt_capacity
  }
}

# ── Embedding deployment ─────────────────────────────────────
# Converts text → 1536-dim vectors for semantic search (RAG).
# Used with AI Search: embed documents at index time, embed
# queries at search time, match by vector similarity.
resource "azurerm_cognitive_deployment" "embedding" {
  count = var.deploy_openai ? 1 : 0

  name                 = var.embedding_model_name
  cognitive_account_id = azurerm_cognitive_account.openai[0].id

  model {
    format  = "OpenAI"
    name    = var.embedding_model_name
    version = var.embedding_model_version
  }

  sku {
    name     = "Standard"
    capacity = var.embedding_capacity
  }
}
