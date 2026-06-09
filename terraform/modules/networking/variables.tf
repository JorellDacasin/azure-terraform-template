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

variable "location" {
  description = "Azure region for resource deployment"
  type        = string
  default     = "UAE North"
}

variable "tags" {
  description = "Tag set to apply to all networking resources"
  type        = map(string)
  default     = {}
}
