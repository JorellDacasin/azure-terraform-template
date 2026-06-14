# ──────────────────────────────────────────────────────────────
# Azure SQL Server + Database
# Managed relational database — deploys with a private endpoint
# in the spoke data subnet (no public internet access).
#
# Cost toggle: var.deploy_sql (default true). Basic SKU = ~$5/mo.
#
# Interview note: "Public access is disabled. The database is
# only reachable from the data subnet via private endpoint —
# even if credentials leak, there's no network path from the
# internet to the server."
# ──────────────────────────────────────────────────────────────

# ── SQL Server ───────────────────────────────────────────────
resource "azurerm_mssql_server" "sql" {
  count = var.deploy_sql ? 1 : 0

  name                          = "sql-${var.org_prefix}-${var.workload}-${var.env}-${var.region}"
  resource_group_name           = azurerm_resource_group.workloads.name
  location                      = azurerm_resource_group.workloads.location
  version                       = "12.0"
  administrator_login           = var.sql_admin_login
  administrator_login_password  = var.sql_admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = false    # private endpoint only

  tags = var.tags
}

# ── Database ─────────────────────────────────────────────────
# Basic SKU: 5 DTU, 2 GB max. Cheapest tier — fine for dev.
# Prod would use Standard S0+ or serverless (auto-pause).
resource "azurerm_mssql_database" "db" {
  count = var.deploy_sql ? 1 : 0

  name      = "${var.workload}-db-${var.env}"
  server_id = azurerm_mssql_server.sql[0].id
  sku_name  = "Basic"
  max_size_gb = 2

  tags = var.tags
}

# ── Private Endpoint ─────────────────────────────────────────
# Places the SQL Server on a private IP inside the data subnet.
# Only resources in the VNet (or peered VNets) can reach it.
# The private DNS zone resolves sql-*.database.windows.net to
# the private IP instead of the public one.
resource "azurerm_private_endpoint" "sql" {
  count = var.deploy_sql ? 1 : 0

  name                = "pe-sql-${var.env}-${var.region}"
  location            = azurerm_resource_group.workloads.location
  resource_group_name = azurerm_resource_group.workloads.name
  subnet_id           = var.data_subnet_id

  private_service_connection {
    name                           = "sql-privatelink"
    private_connection_resource_id = azurerm_mssql_server.sql[0].id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}

# ── Private DNS Zone ─────────────────────────────────────────
# Maps *.database.windows.net → private IP inside the VNet.
# Without this, apps would resolve the public IP and get blocked
# by public_network_access_enabled = false.
resource "azurerm_private_dns_zone" "sql" {
  count = var.deploy_sql ? 1 : 0

  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.workloads.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  count = var.deploy_sql ? 1 : 0

  name                  = "sql-dns-link"
  resource_group_name   = azurerm_resource_group.workloads.name
  private_dns_zone_name = azurerm_private_dns_zone.sql[0].name
  virtual_network_id    = var.spoke_vnet_id
}

resource "azurerm_private_dns_a_record" "sql" {
  count = var.deploy_sql ? 1 : 0

  name                = azurerm_mssql_server.sql[0].name
  zone_name           = azurerm_private_dns_zone.sql[0].name
  resource_group_name = azurerm_resource_group.workloads.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql[0].private_service_connection[0].private_ip_address]
}
