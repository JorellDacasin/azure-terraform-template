module "landing_zone" {
  source = "../../modules/landing-zone"

  org_prefix  = "jd"
  workload    = "platform"
  env         = "dev"
  region      = "uae"
  owner       = "jorell-dacasin"
  cost_center = "platform-dev"
  extra_tags  = {}
}

# ──────────────────────────────────────────────────────────
# Networking — hub/spoke VNets, NSGs, firewall, Log Analytics
# ──────────────────────────────────────────────────────────
# Uses the tags from the landing zone module so every resource
# gets consistent tagging. Firewall is disabled in dev to save
# ~$900/month — enable it in staging/prod by setting to true.

module "networking" {
  source = "../../modules/networking"

  env             = "dev"
  region          = "uae"
  location        = "UAE North"
  tags            = module.landing_zone.tags
  deploy_firewall = false # save ~$900/month in dev; enable in prod
}

# ──────────────────────────────────────────────────────────
# Identity — service principals, RBAC, policy, Key Vault, Defender
# ──────────────────────────────────────────────────────────
# Depends on landing-zone for tags. Independent of networking —
# the two can be applied in parallel. Defender is disabled in dev
# to save cost; enable in staging/prod.

module "identity" {
  source = "../../modules/identity"

  env             = "dev"
  org_prefix      = "jd"
  workload        = "platform"
  region          = "uae"
  location        = "UAE North"
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  tags            = module.landing_zone.tags

  enable_defender = false # cost toggle — off in dev
}

# ──────────────────────────────────────────────────────────
# Workloads — ACR, AKS, SQL, App Service, APIM
# ──────────────────────────────────────────────────────────
# Deploys into the spoke subnets from Phase 1. AKS and ACR are
# always on (core platform). SQL, App Service, APIM have cost
# toggles. APIM defaults to off — enable when learning API
# gateway patterns.

module "workloads" {
  source = "../../modules/workloads"

  org_prefix = "jd"
  workload   = "platform"
  env        = "dev"
  region     = "uae"
  location   = "UAE North"
  tags       = module.landing_zone.tags

  # Network references from Phase 1
  app_subnet_id              = module.networking.spoke_app_subnet_id
  data_subnet_id             = module.networking.spoke_data_subnet_id
  spoke_vnet_id              = module.networking.spoke_vnet_id
  log_analytics_workspace_id = module.networking.log_analytics_workspace_id

  # AKS — single node, cheapest VM for dev
  kubernetes_version = "1.30"
  aks_node_count     = 1
  aks_node_vm_size   = "Standard_B2s"

  # SQL — provide password via tfvars or CI variable (never hardcode)
  sql_admin_password = var.sql_admin_password

  # Cost toggles
  deploy_sql         = true
  deploy_app_service = true
  deploy_apim        = false   # enable when learning API gateway
}
