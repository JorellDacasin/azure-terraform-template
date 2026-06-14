locals {
  # CAF mandatory tags — applied to every resource via provider default_tags
  # Override or extend per resource with merge(local.tags, { extra = "value" })
  tags = merge(
    {
      environment = var.env         # dev | staging | prod
      workload    = var.workload    # logical app/service name
      owner       = var.owner       # team or person responsible
      cost_center = var.cost_center # billing allocation
      managed_by  = "terraform"
      repo        = "JorellDacasin/azure-terraform-template"
    },
    var.extra_tags
  )
}
