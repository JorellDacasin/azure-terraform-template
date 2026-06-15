# ──────────────────────────────────────────────────────────────
# AML Compute Cluster
# On-demand VMs for training ML models. Scales to ZERO when idle
# — no running jobs = no cost. Spins up automatically when a
# training job is submitted.
#
# Deployed into the spoke app subnet so training jobs can access
# data in the data subnet (SQL, storage) via the VNet.
#
# Cost toggle: var.deploy_compute (default true — but min_nodes=0
# means zero cost when idle anyway).
#
# Interview note: "The compute cluster scales to zero between
# training jobs. You only pay when a model is actually training.
# For LifeCare, this means you can have the ML infrastructure
# ready without burning money on idle VMs."
# ──────────────────────────────────────────────────────────────

resource "azurerm_machine_learning_compute_cluster" "training" {
  count = var.deploy_compute ? 1 : 0

  name                          = "cpu-cluster"
  machine_learning_workspace_id = azurerm_machine_learning_workspace.ml.id
  location                      = azurerm_resource_group.ml.location
  vm_size                       = var.compute_vm_size
  vm_priority                   = "Dedicated"     # LowPriority saves ~80% but can be evicted

  scale_settings {
    min_node_count                       = var.compute_min_nodes    # 0 = scale to zero
    max_node_count                       = var.compute_max_nodes
    scale_down_nodes_after_idle_duration = "PT120S"   # 2 min idle → scale down
  }

  # Deploy into the spoke app subnet — training jobs can reach
  # SQL/storage in the data subnet via VNet without needing
  # public endpoints.
  subnet_resource_id = var.app_subnet_id

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}
