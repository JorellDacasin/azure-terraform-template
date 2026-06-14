# Defender for Cloud — Standard tier per-service pricing
# Disabled by default (enable_defender = false) to avoid cost in dev.
# Enable for staging/prod by passing enable_defender = true from the environment.

locals {
  defender_services = var.enable_defender ? [
    "VirtualMachines",
    "SqlServers",
    "AppServices",
    "StorageAccounts",
    "Containers",
    "KeyVaults",
    "Arm",
    "Dns",
  ] : []
}

resource "azurerm_security_center_subscription_pricing" "defender" {
  for_each      = toset(local.defender_services)
  tier          = "Standard"
  resource_type = each.value
}

resource "azurerm_security_center_contact" "main" {
  count               = var.enable_defender ? 1 : 0
  email               = "security@${var.org_prefix}.local"
  alert_notifications = true
  alerts_to_admins    = true
}
