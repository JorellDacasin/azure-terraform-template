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
