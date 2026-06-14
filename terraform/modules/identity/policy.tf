locals {
  # Only UAE regions allowed — data residency requirement
  allowed_locations = ["uaenorth", "uaecentral", "global"]
}

# Policy 1: Allowed locations — deny resources outside UAE
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-locations-${var.org_prefix}"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed Locations - ${upper(var.org_prefix)}"

  metadata = jsonencode({ category = "General" })

  policy_rule = jsonencode({
    if = {
      not = {
        field = "location"
        in    = local.allowed_locations
      }
    }
    then = { effect = "Deny" }
  })

  parameters = jsonencode({})
}

# Policy 2: Required tags — deny resources missing mandatory tags
resource "azurerm_policy_definition" "required_tags" {
  name         = "required-tags-${var.org_prefix}"
  policy_type  = "Custom"
  mode         = "Indexed"
  display_name = "Required Tags - ${upper(var.org_prefix)}"

  metadata = jsonencode({ category = "Tags" })

  policy_rule = jsonencode({
    if = {
      anyOf = [
        { field = "tags['environment']", exists = "false" },
        { field = "tags['workload']", exists = "false" },
        { field = "tags['owner']", exists = "false" },
        { field = "tags['managed_by']", exists = "false" },
      ]
    }
    then = { effect = "Deny" }
  })

  parameters = jsonencode({})
}

# Policy 3: Allowed VM SKUs — prevent expensive VM sizes in non-prod
resource "azurerm_policy_definition" "allowed_vm_skus" {
  name         = "allowed-vm-skus-${var.org_prefix}"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Allowed VM SKUs - ${upper(var.org_prefix)}"

  metadata = jsonencode({ category = "Compute" })

  policy_rule = jsonencode({
    if = {
      allOf = [
        { field = "type", equals = "Microsoft.Compute/virtualMachines" },
        {
          not = {
            field = "Microsoft.Compute/virtualMachines/sku.name"
            in    = ["Standard_B2s", "Standard_B2ms", "Standard_D2s_v3", "Standard_D4s_v3"]
          }
        }
      ]
    }
    then = { effect = "Deny" }
  })

  parameters = jsonencode({})
}

# Assign all policies at subscription scope
resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.allowed_locations.id
  display_name         = "Allowed Locations"
}

resource "azurerm_subscription_policy_assignment" "required_tags" {
  name                 = "required-tags"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.required_tags.id
  display_name         = "Required Tags"
}

resource "azurerm_subscription_policy_assignment" "allowed_vm_skus" {
  name                 = "allowed-vm-skus"
  subscription_id      = "/subscriptions/${var.subscription_id}"
  policy_definition_id = azurerm_policy_definition.allowed_vm_skus.id
  display_name         = "Allowed VM SKUs"
}
