# ──────────────────────────────────────────────────────────────
# Azure Machine Learning Workspace
# Central hub for ML experiments, model training, and deployment.
# The workspace itself is FREE — you pay for compute (training)
# and endpoints (serving). Everything else is metadata.
#
# Dependencies:
#   - Storage Account (NEW) — datasets, model artifacts, logs
#   - Application Insights (NEW) — model endpoint monitoring
#   - Key Vault (Phase 2) — secrets for training/serving
#   - ACR (Phase 4) — custom Docker images for training
#
# Interview note: "AML Workspace is the control plane for the
# entire ML lifecycle — from data prep to model registration to
# endpoint deployment. It doesn't run anything itself; compute
# clusters and endpoints handle execution."
# ──────────────────────────────────────────────────────────────

# ── Resource Group ───────────────────────────────────────────
resource "azurerm_resource_group" "ml" {
  name     = "rg-ml-${var.env}-${var.region}"
  location = var.location
  tags     = var.tags
}

# ── Storage Account (for AML) ────────────────────────────────
# Stores experiment data, model artifacts, and pipeline outputs.
# Separate from the tfstate storage in bootstrap — different
# lifecycle and access pattern.
# Standard LRS (cheapest), hardened same as bootstrap.
resource "azurerm_storage_account" "ml" {
  name                     = "st${var.org_prefix}ml${var.env}${var.region}"
  resource_group_name      = azurerm_resource_group.ml.name
  location                 = azurerm_resource_group.ml.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"

  tags = var.tags
}

# ── Application Insights ─────────────────────────────────────
# Monitors deployed model endpoints — tracks latency, error rate,
# request volume, and custom metrics. Required by AML Workspace.
resource "azurerm_application_insights" "ml" {
  name                = "appi-ml-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.ml.name
  location            = azurerm_resource_group.ml.location
  application_type    = "web"

  tags = var.tags
}

# ── AML Workspace ────────────────────────────────────────────
# The workspace ties everything together. Compute clusters,
# datasets, experiments, models, and endpoints all live here.
# identity = SystemAssigned so the workspace authenticates to
# storage/ACR/KV via managed identity (no SP to rotate).
resource "azurerm_machine_learning_workspace" "ml" {
  name                    = "mlw-${var.workload}-${var.env}-${var.region}"
  resource_group_name     = azurerm_resource_group.ml.name
  location                = azurerm_resource_group.ml.location
  friendly_name           = "${var.workload}-${var.env} ML Workspace"
  storage_account_id      = azurerm_storage_account.ml.id
  key_vault_id            = var.key_vault_id
  application_insights_id = azurerm_application_insights.ml.id
  container_registry_id   = var.acr_id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
