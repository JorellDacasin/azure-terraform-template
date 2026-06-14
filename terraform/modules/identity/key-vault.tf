locals {
  kv_name    = "kv-${var.org_prefix}-${var.workload}-${var.env}"
  identity_rg = "rg-${var.org_prefix}-identity-${var.env}-${var.region}"
}

resource "azurerm_resource_group" "identity" {
  name     = local.identity_rg
  location = var.location
  tags     = var.tags
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = local.kv_name
  location                   = var.location
  resource_group_name        = azurerm_resource_group.identity.name
  tenant_id                  = var.tenant_id
  sku_name                   = var.kv_sku
  soft_delete_retention_days = var.kv_soft_delete_retention_days

  # Purge protection prevents recovery-window bypass — mandatory in prod
  purge_protection_enabled = var.env == "prod" ? true : false

  # RBAC authorization over legacy access policies — simpler, auditable, CAF-recommended
  enable_rbac_authorization = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow" # tightened to Deny + private endpoint in Phase 6
  }

  tags = var.tags
}

# Terraform SP: Secrets Officer — full CRUD on secrets (needed to write pipeline credentials)
resource "azurerm_role_assignment" "kv_terraform_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = azuread_service_principal.terraform.object_id
}

# Pipeline SP: Secrets User — read-only (pipelines read secrets, never write them)
resource "azurerm_role_assignment" "kv_pipeline_reader" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azuread_service_principal.pipeline.object_id
}

# Current deployer (the human running Terraform) gets Secrets Officer so they can seed values
resource "azurerm_role_assignment" "kv_deployer_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}
