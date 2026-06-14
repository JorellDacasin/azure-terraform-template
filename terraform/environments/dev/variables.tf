variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "sql_admin_password" {
  description = "SQL Server admin password (pass via -var, TF_VAR_, or tfvars — never hardcode)"
  type        = string
  sensitive   = true
  default     = ""
}
