# ──────────────────────────────────────────────────────────────
# Azure Kubernetes Service (AKS)
# Main compute platform — containers run here.
#
# Free tier: no SLA (fine for dev). Standard ($75/mo) for prod.
# Azure CNI: pods get real VNet IPs in the spoke app subnet —
#   NSGs and firewalls apply at pod level, pods reach SQL in
#   the data subnet directly. Kubenet (NAT) would break this.
# Managed identity: no service principal to rotate.
# ──────────────────────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-${var.workload}-${var.env}-${var.region}"
  location            = azurerm_resource_group.workloads.location
  resource_group_name = azurerm_resource_group.workloads.name
  dns_prefix          = "${var.org_prefix}-${var.workload}-${var.env}"
  kubernetes_version  = var.kubernetes_version
  sku_tier            = "Free"

  # ── Default node pool ─────────────────────────────────────
  # Single node, cheapest burstable VM. Scale up for prod.
  # vnet_subnet_id places pods directly in the spoke app subnet
  # so they inherit NSG rules and can reach the data subnet.
  default_node_pool {
    name                 = "system"
    node_count           = var.aks_node_count
    vm_size              = var.aks_node_vm_size
    vnet_subnet_id       = var.app_subnet_id
    auto_scaling_enabled = false         # manual scaling in dev
    os_disk_size_gb      = 30            # minimum, saves cost
  }

  # ── Identity ───────────────────────────────────────────────
  # SystemAssigned = Azure creates and manages the identity.
  # No SP credentials to rotate. The kubelet identity (below)
  # is what pulls images from ACR.
  identity {
    type = "SystemAssigned"
  }

  # ── Networking ─────────────────────────────────────────────
  # Azure CNI: pods get real VNet IPs from the app subnet.
  # service_cidr: Kubernetes-internal ClusterIP range — must NOT
  # overlap with hub (10.0.x.x) or spoke (10.1.x.x).
  # dns_service_ip: must be inside service_cidr.
  network_profile {
    network_plugin = "azure"
    service_cidr   = "10.2.0.0/16"
    dns_service_ip = "10.2.0.10"
  }

  # ── Monitoring ─────────────────────────────────────────────
  # Streams container logs and metrics to Log Analytics (Phase 1).
  # Enables Container Insights in the Azure portal — live pod
  # logs, node metrics, deployment status dashboards.
  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # ── RBAC ───────────────────────────────────────────────────
  # Azure AD-integrated RBAC: Kubernetes RBAC roles can be
  # backed by Azure AD groups. Combined with Azure RBAC for
  # the cluster resource itself.
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
  }

  tags = var.tags
}

# ── ACR Pull permission ───────────────────────────────────────
# Grant AKS's kubelet managed identity the AcrPull role on the
# container registry. This lets AKS pull images from ACR without
# needing docker login or imagePullSecrets in pod specs.
#
# Interview note: "I use managed identity + AcrPull instead of
# admin credentials or imagePullSecrets. No secrets to manage,
# rotate, or leak."
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}
