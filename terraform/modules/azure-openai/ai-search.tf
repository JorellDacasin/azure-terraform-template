# ──────────────────────────────────────────────────────────────
# Azure AI Search (formerly Cognitive Search)
# Vector + full-text search for RAG (Retrieval-Augmented
# Generation). Stores document embeddings and returns
# semantically similar results when queried.
#
# RAG pattern:
#   1. Index time: embed documents with text-embedding-3-small
#      → store vectors in AI Search
#   2. Query time: embed the user's question → vector search
#      → top-K results fed to GPT-4o as context
#   3. GPT-4o answers using the retrieved context (not hallucination)
#
# Free tier: 50 MB storage, 3 indexes, 10K documents.
# Enough for dev/training. Basic ($75/mo) for prod.
#
# Interview note: "I use AI Search + OpenAI for RAG instead of
# fine-tuning. RAG is cheaper, faster to update (re-index vs
# re-train), and the source documents are always traceable —
# critical for healthcare where you need to cite your sources."
# ──────────────────────────────────────────────────────────────

resource "azurerm_search_service" "search" {
  count = var.deploy_ai_search ? 1 : 0

  name                = "srch-${var.org_prefix}-${var.workload}-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.ai.name
  location            = azurerm_resource_group.ai.location
  sku                 = "free"

  # Semantic search (AI-powered re-ranking) — available on
  # Basic+ SKUs. Disabled on free tier.
  # semantic_search_sku = "free"   # uncomment on Basic+

  tags = var.tags
}
