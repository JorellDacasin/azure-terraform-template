terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  # Intentionally no backend block — state is stored locally.
  # This config only runs once to provision the remote state storage.
}

provider "azurerm" {
  features {}
}
