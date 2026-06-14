# ──────────────────────────────────────────────────────────────
# Resource Group — workloads
# Separate from hub/spoke/identity so workload lifecycle is
# independent. You can tear down all workloads without touching
# networking or security.
# ──────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "workloads" {
  name     = "rg-workloads-${var.env}-${var.region}"
  location = var.location
  tags     = var.tags
}
