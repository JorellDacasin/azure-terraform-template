variable "org_prefix" {
  description = "Short org/company prefix used in management group names (e.g. jd, contoso)"
  type        = string
  default     = "jd"
}

variable "workload" {
  description = "Logical workload name used in resource naming (e.g. platform, shared, lifecare)"
  type        = string
}

variable "env" {
  description = "Deployment environment"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be dev, staging, or prod"
  }
}

variable "region" {
  description = "Short region code used in resource names (e.g. uae, eus, weu)"
  type        = string
  default     = "uae"
}

variable "owner" {
  description = "Team or person responsible for this workload"
  type        = string
}

variable "cost_center" {
  description = "Cost center for billing allocation"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags to merge with the default tag set"
  type        = map(string)
  default     = {}
}
