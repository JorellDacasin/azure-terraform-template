# ──────────────────────────────────────────────────────────────
# Diagnostic Settings — AI/ML audit logging
# Streams audit logs from Phase 5 resources to:
#   1. Log Analytics (Phase 1) — for KQL queries and dashboards
#   2. Immutable Storage (this phase) — tamper-proof retention
#
# Every API call to OpenAI, every AML experiment, every Content
# Safety check is logged. Auditors can query Log Analytics for
# real-time analysis and verify immutable storage for integrity.
#
# Interview note: "Every AI API call is logged to both Log
# Analytics (for real-time monitoring) and immutable blob
# storage (for tamper-proof audit trail). If an auditor asks
# 'who accessed the GPT-4o endpoint on Tuesday at 3pm?',
# I can answer in seconds with a KQL query."
# ──────────────────────────────────────────────────────────────

# ── Azure OpenAI diagnostics ─────────────────────────────────
# Logs: RequestResponse (every API call), Audit (admin actions)
# Metrics: latency, token usage, error rates
resource "azurerm_monitor_diagnostic_setting" "openai" {
  count = var.openai_id != "" ? 1 : 0

  name                       = "diag-oai-to-logs"
  target_resource_id         = var.openai_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.deploy_immutable_storage ? azurerm_storage_account.audit[0].id : null

  enabled_log {
    category = "RequestResponse"
  }

  enabled_log {
    category = "Audit"
  }

  metric {
    category = "AllMetrics"
  }
}

# ── AML Workspace diagnostics ────────────────────────────────
# Logs: AmlComputeClusterEvent (scale events), AmlRunStatusChangedEvent
# (experiment lifecycle), AmlEnvironmentEvent (environment builds)
resource "azurerm_monitor_diagnostic_setting" "aml" {
  name                       = "diag-mlw-to-logs"
  target_resource_id         = var.aml_workspace_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.deploy_immutable_storage ? azurerm_storage_account.audit[0].id : null

  enabled_log {
    category = "AmlComputeClusterEvent"
  }

  enabled_log {
    category = "AmlRunStatusChangedEvent"
  }

  metric {
    category = "AllMetrics"
  }
}

# ── Content Safety diagnostics ───────────────────────────────
# Logs every content filtering request — what was checked,
# severity scores, whether it was blocked or passed.
resource "azurerm_monitor_diagnostic_setting" "content_safety" {
  count = var.content_safety_id != "" ? 1 : 0

  name                       = "diag-cs-to-logs"
  target_resource_id         = var.content_safety_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.deploy_immutable_storage ? azurerm_storage_account.audit[0].id : null

  enabled_log {
    category = "RequestResponse"
  }

  enabled_log {
    category = "Audit"
  }

  metric {
    category = "AllMetrics"
  }
}

# ── Key Vault diagnostics ────────────────────────────────────
# Logs: AuditEvent (who accessed which secret/key/cert, when)
# Critical for CMK — proves the encryption key was not accessed
# by unauthorized parties.
resource "azurerm_monitor_diagnostic_setting" "kv" {
  name                       = "diag-kv-to-logs"
  target_resource_id         = var.key_vault_id
  log_analytics_workspace_id = var.log_analytics_workspace_id
  storage_account_id         = var.deploy_immutable_storage ? azurerm_storage_account.audit[0].id : null

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }
}
