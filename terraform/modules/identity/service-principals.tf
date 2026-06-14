# Two service principals:
#   sp-terraform  — used by Terraform to deploy infrastructure
#   sp-pipeline   — used by Azure DevOps CI/CD pipelines

resource "azuread_application" "terraform" {
  display_name = "sp-${var.org_prefix}-terraform-${var.env}"
}

resource "azuread_service_principal" "terraform" {
  client_id = azuread_application.terraform.client_id
}

resource "azuread_application" "pipeline" {
  display_name = "sp-${var.org_prefix}-pipeline-${var.env}"
}

resource "azuread_service_principal" "pipeline" {
  client_id = azuread_application.pipeline.client_id
}
