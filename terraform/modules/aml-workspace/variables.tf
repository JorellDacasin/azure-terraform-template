# ──────────────────────────────────────────────────────────────
# AML Workspace module — variables
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

# ── References from earlier phases ───────────────────────────
variable "key_vault_id" {
  description = "Key Vault ID from Phase 2 identity module — AML stores secrets here"
  type        = string
}

variable "acr_id" {
  description = "Container Registry ID from Phase 4 — AML uses it for custom training images"
  type        = string
}

variable "app_subnet_id" {
  description = "Spoke app subnet ID — compute cluster deploys here"
  type        = string
}

# ── Compute settings ─────────────────────────────────────────
variable "deploy_compute" {
  description = "Deploy AML Compute Cluster (scales to 0 when idle = no cost)"
  type        = bool
  default     = true
}

variable "compute_vm_size" {
  description = "VM size for compute cluster nodes"
  type        = string
  default     = "Standard_DS2_v2"
}

variable "compute_min_nodes" {
  description = "Minimum node count (0 = scale to zero when idle)"
  type        = number
  default     = 0
}

variable "compute_max_nodes" {
  description = "Maximum node count for training jobs"
  type        = number
  default     = 1
}
