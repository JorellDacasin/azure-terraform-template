# ──────────────────────────────────────────────────────────────
# Private Endpoints
# Locks every service to a private IP inside the data subnet.
# Public access is blocked — even if credentials leak, there's
# no network path from the internet.
#
# Each service needs:
#   1. A private endpoint (NIC with a private IP in the subnet)
#   2. A private DNS zone (resolves *.service.net → private IP)
#   3. A VNet link (connects the DNS zone to the spoke VNet)
#
# Cost: ~$7.30/month per private endpoint.
#
# Interview note: "Every AI service — OpenAI, AML, ACR, Key
# Vault — is locked behind a private endpoint. There's zero
# public surface area. For LifeCare's patient data, this is the
# first requirement I implement before any data flows."
# ──────────────────────────────────────────────────────────────

# ── Resource Group ───────────────────────────────────────────
resource "azurerm_resource_group" "compliance" {
  name     = "rg-compliance-${var.env}-${var.region}"
  location = var.location
  tags     = var.tags
}

# ════════════════════════════════════════════════════════════
# Key Vault — private endpoint
# ════════════════════════════════════════════════════════════
resource "azurerm_private_endpoint" "kv" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                = "pe-kv-${var.env}-${var.region}"
  location            = azurerm_resource_group.compliance.location
  resource_group_name = azurerm_resource_group.compliance.name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "kv-privatelink"
    private_connection_resource_id = var.key_vault_id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "kv" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.compliance.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                  = "kv-dns-link"
  resource_group_name   = azurerm_resource_group.compliance.name
  private_dns_zone_name = azurerm_private_dns_zone.kv[0].name
  virtual_network_id    = var.spoke_vnet_id
}

# ════════════════════════════════════════════════════════════
# ACR — private endpoint
# ════════════════════════════════════════════════════════════
# Note: ACR private endpoint requires Premium SKU ($50/mo).
# For dev with Basic SKU, this will be skipped or the ACR SKU
# must be upgraded. Toggle with deploy_private_endpoints.
resource "azurerm_private_endpoint" "acr" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                = "pe-acr-${var.env}-${var.region}"
  location            = azurerm_resource_group.compliance.location
  resource_group_name = azurerm_resource_group.compliance.name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "acr-privatelink"
    private_connection_resource_id = var.acr_id
    subresource_names              = ["registry"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "acr" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.compliance.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                  = "acr-dns-link"
  resource_group_name   = azurerm_resource_group.compliance.name
  private_dns_zone_name = azurerm_private_dns_zone.acr[0].name
  virtual_network_id    = var.spoke_vnet_id
}

# ════════════════════════════════════════════════════════════
# Azure OpenAI — private endpoint
# ════════════════════════════════════════════════════════════
resource "azurerm_private_endpoint" "openai" {
  count = var.deploy_private_endpoints && var.openai_id != "" ? 1 : 0

  name                = "pe-oai-${var.env}-${var.region}"
  location            = azurerm_resource_group.compliance.location
  resource_group_name = azurerm_resource_group.compliance.name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "openai-privatelink"
    private_connection_resource_id = var.openai_id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "openai" {
  count = var.deploy_private_endpoints && var.openai_id != "" ? 1 : 0

  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.compliance.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "openai" {
  count = var.deploy_private_endpoints && var.openai_id != "" ? 1 : 0

  name                  = "openai-dns-link"
  resource_group_name   = azurerm_resource_group.compliance.name
  private_dns_zone_name = azurerm_private_dns_zone.openai[0].name
  virtual_network_id    = var.spoke_vnet_id
}

# ════════════════════════════════════════════════════════════
# AML Workspace — private endpoint
# ════════════════════════════════════════════════════════════
resource "azurerm_private_endpoint" "aml" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                = "pe-mlw-${var.env}-${var.region}"
  location            = azurerm_resource_group.compliance.location
  resource_group_name = azurerm_resource_group.compliance.name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "aml-privatelink"
    private_connection_resource_id = var.aml_workspace_id
    subresource_names              = ["amlworkspace"]
    is_manual_connection           = false
  }

  tags = var.tags
}

resource "azurerm_private_dns_zone" "aml" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                = "privatelink.api.azureml.ms"
  resource_group_name = azurerm_resource_group.compliance.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "aml" {
  count = var.deploy_private_endpoints ? 1 : 0

  name                  = "aml-dns-link"
  resource_group_name   = azurerm_resource_group.compliance.name
  private_dns_zone_name = azurerm_private_dns_zone.aml[0].name
  virtual_network_id    = var.spoke_vnet_id
}
