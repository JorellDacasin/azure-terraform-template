resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate-prod-uae"
  location = "UAE North"

  tags = {
    environment = "prod"
    managed_by  = "terraform"
    purpose     = "remote-state"
  }
}

resource "azurerm_storage_account" "tfstate" {
  name                     = "stjdtfstateprod"   # must be globally unique across Azure
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"           # cheapest tier
  account_replication_type = "LRS"               # locally redundant — 3 copies, one datacenter

  # Harden the storage account — state files may contain sensitive resource details
  allow_nested_items_to_be_public  = false
  https_traffic_only_enabled       = true
  min_tls_version                  = "TLS1_2"

  tags = azurerm_resource_group.tfstate.tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_id    = azurerm_storage_account.tfstate.id
  container_access_type = "private"
}
