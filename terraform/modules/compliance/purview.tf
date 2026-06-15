# ──────────────────────────────────────────────────────────────
# Microsoft Purview
# Data governance platform — discovers, classifies, and tracks
# sensitive data across your Azure estate.
#
# What it does:
#   - Scans storage accounts, SQL databases, and AI services
#   - Classifies data (PII, PHI, financial, custom patterns)
#   - Builds data lineage maps (where does patient data flow?)
#   - Provides a unified data catalog for discovery
#
# Cost toggle: var.deploy_purview (default FALSE — Purview has
# complex pricing and is overkill for dev. Enable in prod.)
#
# Interview note: "Purview gives me a data lineage map — I can
# show auditors exactly where patient data originates, which
# services process it, and where it ends up. For LifeCare, this
# is how you prove data handling compliance without manual
# documentation."
# ──────────────────────────────────────────────────────────────

resource "azurerm_purview_account" "purview" {
  count = var.deploy_purview ? 1 : 0

  name                = "pv-${var.org_prefix}-${var.workload}-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.compliance.name
  location            = azurerm_resource_group.compliance.location

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
