# ──────────────────────────────────────────────────────────────
# Compliance module — variables
# Hardens all resources from Phases 1–5 for healthcare:
#   - Private endpoints (no public internet access)
#   - Customer-managed keys (CMK — you control encryption)
#   - Purview (data governance, lineage, classification)
#   - Immutable storage (WORM — tamper-proof audit logs)
#   - Diagnostic settings (audit trails for AI/ML)
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
  description = "Full Azure region for deployment (e.g. UAE North)"
  type        = string
}

variable "tags" {
  description = "Standard tags from landing-zone module"
  type        = map(string)
}

# ── Network references ───────────────────────────────────────
variable "data_subnet_id" {
  description = "Spoke data subnet ID — private endpoints deploy here"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID — for private DNS zone VNet links"
  type        = string
}

# ── Resource references (from earlier phases) ────────────────
variable "key_vault_id" {
  description = "Key Vault ID (Phase 2) — gets private endpoint + CMK source"
  type        = string
}

variable "key_vault_name" {
  description = "Key Vault name (Phase 2) — for CMK key creation"
  type        = string
}

variable "acr_id" {
  description = "ACR ID (Phase 4) — gets private endpoint"
  type        = string
}

variable "openai_id" {
  description = "Azure OpenAI ID (Phase 5) — gets private endpoint + diagnostics"
  type        = string
  default     = ""
}

variable "aml_workspace_id" {
  description = "AML Workspace ID (Phase 5) — gets private endpoint + diagnostics"
  type        = string
}

variable "aml_storage_account_id" {
  description = "AML Storage Account ID (Phase 5) — gets CMK encryption"
  type        = string
}

variable "content_safety_id" {
  description = "Content Safety ID (Phase 5) — gets diagnostics"
  type        = string
  default     = ""
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID (Phase 1) — audit logs destination"
  type        = string
}

# ── Cost toggles ─────────────────────────────────────────────
variable "deploy_private_endpoints" {
  description = "Deploy private endpoints for all services (locks out public access)"
  type        = bool
  default     = true
}

variable "deploy_cmk" {
  description = "Deploy Customer-Managed Keys for encryption at rest"
  type        = bool
  default     = true
}

variable "deploy_purview" {
  description = "Deploy Microsoft Purview (data governance)"
  type        = bool
  default     = false
}

variable "deploy_immutable_storage" {
  description = "Deploy immutable blob storage for audit logs (WORM)"
  type        = bool
  default     = true
}
