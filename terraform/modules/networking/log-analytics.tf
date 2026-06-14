# ──────────────────────────────────────────────────────────
# Log Analytics Workspace (Central Logging)
# ──────────────────────────────────────────────────────────
# Every landing zone needs a central place to collect logs.
# All hub resources (firewall, NSGs) send diagnostic data
# here. Spoke workloads will also point here in later phases.
#
# Cost note: Free tier = 500 MB/day ingestion, 7-day retention.
# PerGB2018 tier = 5 GB/day free, 31-day retention (better).
# We use PerGB2018 with 30 days — still essentially free for
# dev workloads and gives us real query capability.
# ──────────────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-hub-${var.env}-${var.region}"
  location            = azurerm_resource_group.hub.location
  resource_group_name = azurerm_resource_group.hub.name
  sku                 = "PerGB2018" # standard tier, 5 GB/day free
  retention_in_days   = 30          # keep logs 30 days (free range)
  tags                = var.tags
}

# ──────────────────────────────────────────────────────────
# Diagnostic Settings — Firewall → Log Analytics
# ──────────────────────────────────────────────────────────
# Captures all firewall rule hits, threat intelligence matches,
# and DNS proxy logs. This is how you see what traffic the
# firewall allowed or denied.

resource "azurerm_monitor_diagnostic_setting" "firewall" {
  count                      = var.deploy_firewall ? 1 : 0
  name                       = "diag-afw-to-logs"
  target_resource_id         = azurerm_firewall.main[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  # Azure Firewall structured logs (resource-specific tables)
  enabled_log {
    category = "AZFWApplicationRule"
  }
  enabled_log {
    category = "AZFWNetworkRule"
  }
  enabled_log {
    category = "AZFWThreatIntel"
  }
  enabled_log {
    category = "AZFWDnsProxy"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

# ──────────────────────────────────────────────────────────
# Diagnostic Settings — NSGs → Log Analytics
# ──────────────────────────────────────────────────────────
# NSG flow logs show which packets each security rule allowed
# or denied — essential for troubleshooting connectivity and
# security auditing.

resource "azurerm_monitor_diagnostic_setting" "nsg_bastion" {
  name                       = "diag-nsg-bastion-to-logs"
  target_resource_id         = azurerm_network_security_group.bastion.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_app" {
  name                       = "diag-nsg-app-to-logs"
  target_resource_id         = azurerm_network_security_group.app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_data" {
  name                       = "diag-nsg-data-to-logs"
  target_resource_id         = azurerm_network_security_group.data.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }
  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
