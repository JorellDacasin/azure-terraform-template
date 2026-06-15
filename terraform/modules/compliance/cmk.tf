# ──────────────────────────────────────────────────────────────
# Customer-Managed Keys (CMK)
# By default, Azure encrypts at rest with Microsoft-managed keys.
# CMK means YOU control the key in YOUR Key Vault.
#
# Why CMK matters for healthcare:
#   - Regulatory proof that YOU control encryption
#   - Revoke the key → data becomes unreadable instantly
#   - Key access is audited in Key Vault logs
#   - Required by HIPAA, HITRUST, UAE NESA
#
# This creates an RSA-2048 key in Key Vault and assigns the
# AML storage account to use it for encryption. Extend the
# pattern to other storage accounts and services as needed.
#
# Interview note: "I use customer-managed keys so we can prove
# to auditors that we control the encryption. If a storage
# account is compromised, revoking the key makes all data
# immediately unreadable — even Azure can't decrypt it."
# ──────────────────────────────────────────────────────────────

# ── Encryption key in Key Vault ──────────────────────────────
# RSA-2048: standard for storage encryption. Rotate annually.
# The key lives in the same Key Vault from Phase 2 — one vault,
# one audit trail.
resource "azurerm_key_vault_key" "cmk" {
  count = var.deploy_cmk ? 1 : 0

  name         = "cmk-${var.workload}-${var.env}"
  key_vault_id = var.key_vault_id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "wrapKey",
    "unwrapKey",
  ]
}

# ── Storage Account CMK encryption ───────────────────────────
# Associates the CMK with the AML storage account. All blobs,
# tables, queues, and files in this account are encrypted with
# YOUR key instead of Microsoft's.
#
# The storage account's managed identity accesses the key.
# If the key is revoked or deleted, all data becomes unreadable.
resource "azurerm_storage_account_customer_managed_key" "ml_storage" {
  count = var.deploy_cmk ? 1 : 0

  storage_account_id = var.aml_storage_account_id
  key_vault_id       = var.key_vault_id
  key_name           = azurerm_key_vault_key.cmk[0].name
}
