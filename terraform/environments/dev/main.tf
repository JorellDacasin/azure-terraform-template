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
