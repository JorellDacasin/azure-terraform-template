# ──────────────────────────────────────────────────────────────
# Workloads module — variables
# Inputs from environment root + outputs of earlier modules.
# ──────────────────────────────────────────────────────────────

# ── Naming / tagging ─────────────────────────────────────────
variable "org_prefix" {
  description = "Organization prefix for resource names (e.g. jd)"
  type        = string
}

variable "workload" {
  description = "Workload name (e.g. platform)"
  type        = string
}

variable "env" {
  description = "Environment short code (e.g. dev, prod)"
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

# ── Network references (from Phase 1 networking module) ──────
variable "app_subnet_id" {
  description = "Spoke app subnet ID — AKS and App Service deploy here"
  type        = string
}

variable "data_subnet_id" {
  description = "Spoke data subnet ID — SQL deploys here (private endpoint)"
  type        = string
}

variable "spoke_vnet_id" {
  description = "Spoke VNet ID — needed for SQL private DNS zone VNet link"
  type        = string
}

# ── Monitoring (from Phase 1 networking module) ──────────────
variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for AKS and diagnostics"
  type        = string
}

# ── AKS settings ─────────────────────────────────────────────
variable "kubernetes_version" {
  description = "Kubernetes version for AKS (e.g. 1.30)"
  type        = string
  default     = "1.30"
}

variable "aks_node_count" {
  description = "Number of nodes in the default pool (1 for dev)"
  type        = number
  default     = 1
}

variable "aks_node_vm_size" {
  description = "VM size for AKS nodes (Standard_B2s = cheapest burstable)"
  type        = string
  default     = "Standard_B2s"
}

# ── SQL settings ─────────────────────────────────────────────
variable "sql_admin_login" {
  description = "SQL Server admin username"
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "SQL Server admin password (from Key Vault in CI)"
  type        = string
  sensitive   = true
  default     = ""
}

# ── APIM settings ────────────────────────────────────────────
variable "publisher_name" {
  description = "APIM publisher organization name"
  type        = string
  default     = "Jorell Dacasin"
}

variable "publisher_email" {
  description = "APIM publisher contact email"
  type        = string
  default     = "jorelldacasin@gmail.com"
}

# ── Cost toggles ─────────────────────────────────────────────
# AKS + ACR are always deployed (core platform).
# SQL, App Service, APIM are optional — toggle off to save cost.
variable "deploy_sql" {
  description = "Deploy Azure SQL Server + Database"
  type        = bool
  default     = true
}

variable "deploy_app_service" {
  description = "Deploy App Service Plan + Web App"
  type        = bool
  default     = true
}

variable "deploy_apim" {
  description = "Deploy API Management (Consumption tier)"
  type        = bool
  default     = false
}
