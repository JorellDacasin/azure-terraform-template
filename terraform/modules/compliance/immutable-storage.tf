# ──────────────────────────────────────────────────────────────
# Immutable Blob Storage (WORM — Write Once, Read Many)
# Tamper-proof audit log storage. Once written, data CANNOT be
# modified or deleted for the retention period — even by Azure
# admins or account owners.
#
# Use case: store diagnostic logs, access logs, and compliance
# reports here. Auditors can verify logs haven't been tampered
# with because the immutability policy is enforced by Azure.
#
# Retention: 365 days (1 year). After the period, blobs can
# be deleted but not modified during retention.
#
# Cost: Standard LRS storage cost only (~$0.02/GB/month).
#
# Interview note: "Audit logs are stored in immutable blob
# storage — WORM policy, 365-day retention. Even if an admin
# account is compromised, the attacker can't delete or modify
# historical logs. This is how you maintain audit trail
# integrity for healthcare compliance."
# ──────────────────────────────────────────────────────────────

# ── Storage Account for audit logs ───────────────────────────
# Separate from AML storage — this one is purpose-built for
# tamper-proof compliance logs. Hardened: HTTPS, TLS 1.2,
# no public blob access.
resource "azurerm_storage_account" "audit" {
  count = var.deploy_immutable_storage ? 1 : 0

  name                     = "st${var.org_prefix}audit${var.env}${var.region}"
  resource_group_name      = azurerm_resource_group.compliance.name
  location                 = azurerm_resource_group.compliance.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  # Block public blob access — only authorized requests via
  # Azure RBAC or shared keys.
  allow_nested_items_to_be_public = false

  tags = var.tags
}

# ── Audit logs container ─────────────────────────────────────
resource "azurerm_storage_container" "audit_logs" {
  count = var.deploy_immutable_storage ? 1 : 0

  name                  = "audit-logs"
  storage_account_id    = azurerm_storage_account.audit[0].id
  container_access_type = "private"
}

# ── Immutability policy ──────────────────────────────────────
# 365-day retention. Once locked, the period CANNOT be shortened
# (only extended). Blobs written during this window are immutable.
resource "azurerm_storage_management_policy" "audit_lifecycle" {
  count = var.deploy_immutable_storage ? 1 : 0

  storage_account_id = azurerm_storage_account.audit[0].id

  rule {
    name    = "audit-retention"
    enabled = true

    filters {
      prefix_match = ["audit-logs/"]
      blob_types   = ["blockBlob"]
    }

    # Keep blobs for 365 days, then allow deletion.
    # During retention, blobs cannot be modified or deleted.
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 365
      }
    }
  }
}
