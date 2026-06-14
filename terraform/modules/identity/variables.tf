variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "org_prefix" {
  description = "Short org/owner prefix used in CAF naming (e.g. jd)"
  type        = string
}

variable "workload" {
  description = "Workload name used in CAF naming (e.g. platform)"
  type        = string
}

variable "region" {
  description = "Short region code for CAF naming (e.g. uae)"
  type        = string
}

variable "location" {
  description = "Azure region (e.g. UAE North)"
  type        = string
}

variable "subscription_id" {
  description = "Target Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "tags" {
  description = "Standard tag map passed in from the landing-zone module"
  type        = map(string)
}

variable "kv_sku" {
  description = "Key Vault SKU (standard or premium)"
  type        = string
  default     = "standard"
}

variable "kv_soft_delete_retention_days" {
  description = "Soft-delete retention in days (7-90)"
  type        = number
  default     = 7
}

variable "enable_defender" {
  description = "Toggle Defender for Cloud Standard tier — off by default to avoid dev cost"
  type        = bool
  default     = false
}
