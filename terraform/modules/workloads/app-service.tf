# ──────────────────────────────────────────────────────────────
# App Service — Plan + Linux Web App
# Simpler compute for web apps that don't need Kubernetes.
# Deploy a container or code directly — Azure handles scaling,
# TLS, and OS patches.
#
# Free F1: zero cost, 60 min CPU/day, no custom domain/SSL.
# Upgrade to B1 ($13/mo) for always-on + custom domains.
#
# Cost toggle: var.deploy_app_service (default true).
#
# Interview note: "Not everything needs Kubernetes. For a simple
# API or dashboard, App Service is faster to deploy, cheaper to
# run, and less operational overhead. I use AKS for microservices
# that need orchestration, and App Service for simpler workloads."
# ──────────────────────────────────────────────────────────────

# ── Service Plan ─────────────────────────────────────────────
# The plan defines the compute (CPU/RAM/SKU). Multiple web apps
# can share the same plan — cost is per plan, not per app.
resource "azurerm_service_plan" "plan" {
  count = var.deploy_app_service ? 1 : 0

  name                = "asp-${var.workload}-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.workloads.name
  location            = azurerm_resource_group.workloads.location
  os_type             = "Linux"
  sku_name            = "F1"

  tags = var.tags
}

# ── Web App ──────────────────────────────────────────────────
# The actual application. Runs on the plan above.
# Site config sets the runtime stack — Node 22 LTS here.
resource "azurerm_linux_web_app" "app" {
  count = var.deploy_app_service ? 1 : 0

  name                = "app-${var.org_prefix}-${var.workload}-${var.env}-${var.region}"
  resource_group_name = azurerm_resource_group.workloads.name
  location            = azurerm_resource_group.workloads.location
  service_plan_id     = azurerm_service_plan.plan[0].id

  site_config {
    always_on = false   # Free tier doesn't support always_on

    application_stack {
      node_version = "22-lts"
    }
  }

  # App settings = environment variables for the application.
  # Connection strings to SQL, feature flags, etc. go here.
  # In prod, reference Key Vault secrets instead of plain text.
  app_settings = {
    "WEBSITE_NODE_DEFAULT_VERSION" = "~22"
  }

  tags = var.tags
}
