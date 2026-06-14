locals {
  # CAF naming convention: <resource-type>-<workload>-<env>-<region>-<instance>
  # https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming

  org      = "jd"         # org/company prefix — change per client
  workload = var.workload # e.g. "platform", "shared", "lifecare"
  env      = var.env      # dev | staging | prod
  region   = var.region   # e.g. "uae" for UAE North

  # Resource name prefixes (CAF abbreviations)
  # https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations
  name = {
    resource_group    = "rg-${local.workload}-${local.env}-${local.region}"
    vnet              = "vnet-${local.workload}-${local.env}-${local.region}"
    subnet            = "snet-${local.workload}-${local.env}-${local.region}"
    nsg               = "nsg-${local.workload}-${local.env}-${local.region}"
    firewall          = "afw-${local.workload}-${local.env}-${local.region}"
    firewall_policy   = "afwp-${local.workload}-${local.env}-${local.region}"
    log_analytics     = "log-${local.workload}-${local.env}-${local.region}"
    key_vault         = "kv-${local.workload}-${local.env}-${local.region}"
    storage_account   = "st${local.org}${local.workload}${local.env}" # no hyphens, max 24 chars
    aks_cluster       = "aks-${local.workload}-${local.env}-${local.region}"
    acr               = "acr${local.org}${local.workload}${local.env}" # no hyphens
    app_service_plan  = "asp-${local.workload}-${local.env}-${local.region}"
    app_service       = "app-${local.workload}-${local.env}-${local.region}"
    api_management    = "apim-${local.workload}-${local.env}-${local.region}"
    sql_server        = "sql-${local.workload}-${local.env}-${local.region}"
    sql_database      = "sqldb-${local.workload}-${local.env}-${local.region}"
    aml_workspace     = "mlw-${local.workload}-${local.env}-${local.region}"
    openai            = "oai-${local.workload}-${local.env}-${local.region}"
    ai_search         = "srch-${local.workload}-${local.env}-${local.region}"
    managed_identity  = "id-${local.workload}-${local.env}-${local.region}"
    policy_assignment = "pa-${local.workload}-${local.env}"
  }
}
