# ──────────────────────────────────────────────────────────────
# Azure OpenAI + AI Services module — variables
# ──────────────────────────────────────────────────────────────

variable "env" {
  description = "Environment short code (e.g. dev, prod)"
  type        = string
}

variable "org_prefix" {
  description = "Organization prefix for resource names"
  type        = string
}

variable "workload" {
  description = "Workload name (e.g. platform)"
  type        = string
}

variable "region" {
  description = "Short region code for naming (e.g. uae)"
  type        = string
}

variable "location" {
  description = "Full Azure region for AI Search, AI Services, Content Safety (e.g. UAE North)"
  type        = string
}

variable "tags" {
  description = "Standard tags from landing-zone module"
  type        = map(string)
}

# ── Azure OpenAI location ────────────────────────────────────
# OpenAI is NOT available in all Azure regions. UAE North may
# not support it. Default to Sweden Central — one of the best-
# supported regions with GPT-4o and embeddings.
#
# For data residency: use this only for the OpenAI resource.
# AI Search and other services stay in the primary location.
variable "openai_location" {
  description = "Azure region for OpenAI resource (limited availability — check docs)"
  type        = string
  default     = "swedencentral"
}

# ── Model deployment settings ────────────────────────────────
variable "gpt_model_name" {
  description = "OpenAI chat model to deploy"
  type        = string
  default     = "gpt-4o"
}

variable "gpt_model_version" {
  description = "Model version (check Azure OpenAI model availability)"
  type        = string
  default     = "2024-11-20"
}

variable "gpt_capacity" {
  description = "Tokens-per-minute capacity in thousands (e.g. 10 = 10K TPM)"
  type        = number
  default     = 10
}

variable "embedding_model_name" {
  description = "OpenAI embedding model for RAG / vector search"
  type        = string
  default     = "text-embedding-3-small"
}

variable "embedding_model_version" {
  description = "Embedding model version"
  type        = string
  default     = "1"
}

variable "embedding_capacity" {
  description = "Tokens-per-minute capacity in thousands for embeddings"
  type        = number
  default     = 10
}

# ── Cost toggles ─────────────────────────────────────────────
variable "deploy_openai" {
  description = "Deploy Azure OpenAI + model deployments (pay-per-token, no idle cost)"
  type        = bool
  default     = true
}

variable "deploy_ai_search" {
  description = "Deploy Azure AI Search (Free tier: 50MB, 3 indexes)"
  type        = bool
  default     = true
}

variable "deploy_ai_services" {
  description = "Deploy Azure AI Services multi-service account"
  type        = bool
  default     = false
}

variable "deploy_content_safety" {
  description = "Deploy Azure Content Safety (filter harmful AI outputs)"
  type        = bool
  default     = true
}
