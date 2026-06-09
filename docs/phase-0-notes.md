# Azure Terraform Training — Running Notes

> Living document. Updated as each phase progresses.

---

## Phase 0 — CAF Foundations

### Concepts

**CAF (Cloud Adoption Framework)** — Microsoft's best-practice framework for organising Azure infrastructure. It defines naming conventions, tagging strategy, management group hierarchy, and landing zone design. Following it means your infrastructure is audit-ready and consistent across projects.

**Management Groups** — Azure's way of organising subscriptions into a tree. Policies and RBAC applied at a Management Group level cascade down to all subscriptions under it — so instead of configuring each subscription individually, you govern at scale.

**Landing Zone** — a pre-configured, policy-compliant Azure environment (subscription + networking + identity + logging) that workloads are deployed into. Think of it as a "ready-to-use slot" that already has guardrails in place.

**Remote State** — Terraform tracks what it has deployed in a state file (`terraform.tfstate`). Locally this lives on disk, but in a team/CI setup it lives in Azure Blob Storage so everyone shares the same source of truth. We'll wire this up in Phase 1.

---

### Files created

#### `terraform/modules/landing-zone/variables.tf`
Declares all inputs the module accepts: `org_prefix`, `workload`, `env`, `region`, `owner`, `cost_center`, `extra_tags`.
Everything else in the module references these — changing them in one place propagates everywhere.

#### `terraform/modules/landing-zone/naming.tf`
A `locals` block that builds consistent resource names following CAF conventions:
`<type>-<workload>-<env>-<region>`
Example: a VNet in dev UAE → `vnet-platform-dev-uae`.
Important because Azure has strict naming rules per resource type — e.g. storage accounts can't have hyphens, max 24 chars.

#### `terraform/modules/landing-zone/tags.tf`
A `locals` block that assembles a standard tag set (`environment`, `workload`, `owner`, `cost_center`, `managed_by`) merged with any extra tags passed in.
CAF requires consistent tagging for cost visibility and governance.

#### `terraform/modules/landing-zone/management-groups.tf`
Defines the Management Group hierarchy in Terraform.

```
Tenant Root Group (auto-exists)
└── jd-root
    ├── platform
    │   ├── connectivity   (hub VNet, Firewall)
    │   ├── identity       (AAD, PIM)
    │   └── management     (Log Analytics, Defender)
    ├── landing-zones
    │   ├── corp           (internal workloads, e.g. LifeCare)
    │   └── online         (internet-facing)
    ├── sandbox            (dev/experimentation — relaxed policy)
    └── decommissioned     (subscriptions pending removal — deny-all policy)
```

#### `terraform/modules/landing-zone/outputs.tf`
Exposes management group IDs and the computed names/tags maps so other modules can reference them without re-declaring the same logic.

#### `terraform/environments/dev/main.tf`
Entry point that calls the landing-zone module with real values for dev.
Each environment (dev, prod) has its own folder so they can have different variable values and separate state files.

#### `terraform/environments/dev/providers.tf`
Two blocks:
- **`terraform` block** — locks minimum Terraform version (`>= 1.5`) and pins azurerm to `~> 4.0` (4.x only). Prevents version drift between local and CI.
- **`provider "azurerm"` block** — locally picks up `az login` session automatically. In CI reads credentials from env vars (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, etc.) — no secrets in code. Remote backend config is commented out; uncomment in Phase 1 once the storage account exists.

#### `.gitignore`
Excludes:
- `.terraform/` — provider binaries, too large and machine-specific for git
- `*.tfstate` — state files contain sensitive resource details, belongs in remote storage
- `*.tfvars` — variable value files often contain secrets like subscription IDs
- `.env`, `*.pem`, `*.key` — credentials, never in source control

---

### Commands run

| Command | What it does |
|---|---|
| `terraform init` | Downloads provider plugins (azurerm v4.76.0) and locks the version in `.terraform.lock.hcl`. Commit the lock file — it ensures everyone uses the exact same provider version. |
| `terraform validate` | Checks HCL syntax and module references are correct. Does not connect to Azure. |
| `terraform plan` | (next) Compares desired state (code) vs actual Azure state and shows what would be created/changed/destroyed. Read-only — nothing is deployed. |

---

## Phase 1 — Landing Zone with Terraform

### Concepts

**Remote State** — Terraform tracks every resource it creates in a state file (`terraform.tfstate`). By default this is local, which breaks CI/CD pipelines and multi-machine setups. Storing it in Azure Blob Storage means every machine and pipeline reads from the same source of truth.

**Why a bootstrap exists** — You can't use Terraform to create the storage account if that same storage account is where Terraform needs to store its state. Chicken-and-egg problem. The bootstrap is a separate, one-time Terraform config that uses a local state file just long enough to create the remote storage. You run it once per project, then every other config points its backend at that storage account.

**Hub-spoke VNet topology** — The standard CAF network design. One *hub* VNet holds shared services (Firewall, DNS, VPN Gateway). *Spoke* VNets hold workloads and peer to the hub. All traffic between spokes routes through the hub — this centralises security inspection and keeps workloads isolated from each other.

**NSG (Network Security Group)** — A set of inbound/outbound rules attached to a subnet or NIC. Controls which traffic is allowed in and out. Free resource.

**Log Analytics Workspace** — Central logging sink for Azure Monitor, Defender for Cloud, AKS, and other services. Free tier: 5GB/month — more than enough for training.

**Azure Firewall** — Sits in the hub VNet and inspects all traffic between spokes and to the internet. Costs ~$900/month so we gate it behind `var.deploy_firewall = false` for training — the code is written correctly but it won't be provisioned.

---

### Files created (`terraform/bootstrap/`)

The bootstrap runs once with a local backend to create the remote state storage. After `terraform apply`, copy the outputs into the commented-out backend block in `environments/dev/providers.tf`.

#### `providers.tf`
Same as the dev environment provider config but with no backend block — state stays local intentionally. This is the only config that should ever use local state.

#### `main.tf`
Three resources, in dependency order:
- **`azurerm_resource_group`** — logical container required before any Azure resource can be created. Named `rg-tfstate-prod-uae`.
- **`azurerm_storage_account`** — Standard LRS (cheapest tier). Hardened: HTTPS only, TLS 1.2, no public blob access. Named `stjdtfstateprod` (globally unique across Azure — no hyphens, max 24 chars).
- **`azurerm_storage_container`** — the "folder" inside the storage account where `.tfstate` files live. `container_access_type = "private"` — never expose state files publicly.

#### `outputs.tf`
Prints `resource_group_name`, `storage_account_name`, and `container_name` after apply — these are the three values you paste into the backend block in `environments/dev/providers.tf`.

---

### Bootstrap workflow (run once when Azure account is ready)
```bash
cd terraform/bootstrap
terraform init
terraform apply        # creates RG + storage account + container
# copy outputs into environments/dev/providers.tf backend block
```

---

### Files created (`terraform/modules/networking/`)

#### `variables.tf`
Defines inputs for the networking module: `env`, `region`, `location`, `tags`.
- `region` — short code for resource *names* (e.g. `uae`)
- `location` — full Azure region string for resource *deployment* (e.g. `UAE North`)
These are kept separate because Azure naming conventions use short codes but the API requires the full region name.

#### `hub-vnet.tf`
Creates the hub VNet and its three reserved subnets.
- **Resource Group** `rg-hub-dev-uae` — hub gets its own RG, separate from spoke, so lifecycles are independent.
- **VNet** `vnet-hub-dev-uae` — address space `10.0.0.0/16`.
- **`AzureFirewallSubnet`** (`10.0.0.0/26`) — name is reserved and exact; Azure Firewall won't attach to anything else. `/26` is the minimum.
- **`GatewaySubnet`** (`10.0.1.0/27`) — reserved name for VPN/ExpressRoute Gateway. `/27` minimum.
- **`AzureBastionSubnet`** (`10.0.2.0/26`) — reserved name for Azure Bastion (secure RDP/SSH without public IPs). `/26` minimum.

> The three reserved subnet names are a common interview gotcha — Azure rejects any other name for those services.

#### `spoke-vnet.tf`
Creates the spoke VNet where workloads will actually run (AKS, databases, etc.).
- **Resource Group** `rg-spoke-dev-uae` — separate from hub so a workload spoke can be torn down without touching hub infrastructure.
- **VNet** `vnet-spoke-dev-uae` — address space `10.1.0.0/16` (must not overlap with hub's `10.0.0.0/16`).
- **`snet-app-dev-uae`** (`10.1.0.0/24`) — app tier subnet for workloads like AKS (Phase 4).
- **`snet-data-dev-uae`** (`10.1.1.0/24`) — data tier subnet for databases and storage (Phase 4).

> Spoke address pattern: hub = `10.0.x.x`, spoke 1 = `10.1.x.x`, spoke 2 = `10.2.x.x` — never overlapping.

---

### ⏸ Paused here — resume from VNet Peering

**Next resource: VNet Peering** — the connection between hub and spoke VNets that allows traffic to flow between them. After that: NSGs, Log Analytics, then wiring everything into `environments/dev/main.tf`.

**Pending: `az login` + `terraform plan`** — deferred until Azure account is set up.

---

## Phase 2 — Identity, RBAC & Policy
*Not started. Covers: Service Principals, custom roles, Azure Policy, Defender for Cloud, Key Vault.*

## Phase 3 — Azure DevOps Pipelines
*Not started. Covers: PR validation, apply pipeline, Key Vault-linked secrets, drift detection.*

## Phase 4 — Workload Deployments
*Not started. Covers: AKS, ACR, App Service, Azure SQL, API Management.*

## Phase 5 — ML & AI Instances
*Not started. Covers: AML Workspace, Compute Cluster, Azure OpenAI, AI Search, Content Safety.*

## Phase 6 — Healthcare Compliance Hardening
*Not started. Covers: private endpoints, CMK, Purview, immutable storage (LifeCare-specific).*
