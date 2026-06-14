# Custom role: Terraform Deployer
# Scoped Contributor — can manage resources but cannot modify role assignments.
# Principle: least privilege. Terraform gets exactly what it needs, nothing more.

resource "azurerm_role_definition" "terraform_deployer" {
  name        = "Terraform Deployer - ${upper(var.org_prefix)}"
  scope       = "/subscriptions/${var.subscription_id}"
  description = "Least-privilege role for Terraform deployments — resource management without IAM escalation"

  permissions {
    actions = [
      "Microsoft.Resources/*",
      "Microsoft.Network/*",
      "Microsoft.Compute/*",
      "Microsoft.Storage/*",
      "Microsoft.KeyVault/*",
      "Microsoft.Authorization/*/read",
      "Microsoft.Insights/*",
      "Microsoft.OperationalInsights/*",
      "Microsoft.ContainerService/*",
      "Microsoft.ContainerRegistry/*",
      "Microsoft.MachineLearningServices/*",
      "Microsoft.CognitiveServices/*",
      "Microsoft.Search/*",
      "Microsoft.Security/*/read",
    ]
    not_actions = [
      # Block IAM escalation — Terraform cannot grant itself or others elevated access
      "Microsoft.Authorization/roleAssignments/write",
      "Microsoft.Authorization/roleAssignments/delete",
      "Microsoft.Authorization/roleDefinitions/write",
      "Microsoft.Authorization/roleDefinitions/delete",
    ]
  }

  assignable_scopes = ["/subscriptions/${var.subscription_id}"]
}

# Assign Terraform Deployer to the Terraform service principal
resource "azurerm_role_assignment" "terraform_deployer" {
  scope              = "/subscriptions/${var.subscription_id}"
  role_definition_id = azurerm_role_definition.terraform_deployer.role_definition_resource_id
  principal_id       = azuread_service_principal.terraform.object_id
}

# Pipeline SP gets Reader at subscription scope.
# Promoted to Contributor per-workload resource group as needed in later phases.
resource "azurerm_role_assignment" "pipeline_reader" {
  scope                = "/subscriptions/${var.subscription_id}"
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.pipeline.object_id
}
