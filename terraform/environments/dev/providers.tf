terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }

  # Remote state — uncomment once storage account is provisioned (Phase 1)
  # backend "azurerm" {
  #   resource_group_name  = "rg-tfstate-prod-uae"
  #   storage_account_name = "stjdtfstateprod"
  #   container_name       = "tfstate"
  #   key                  = "dev/landing-zone.tfstate"
  # }
}

provider "azurerm" {
  features {}
  # Locally: picks up `az login` session automatically
  # CI/CD: reads ARM_SUBSCRIPTION_ID, ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID from env vars
}

provider "azuread" {
  # Uses the same az login session / CI env vars as azurerm
}
