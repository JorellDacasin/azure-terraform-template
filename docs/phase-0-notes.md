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

### Files created (`terraform/modules/networking/` — continued)

#### `nsgs.tf`
Defines Network Security Groups for subnets that support them. **AzureFirewallSubnet and GatewaySubnet do NOT allow custom NSGs** — Azure manages those internally.

- **Bastion NSG** (`nsg-bastion-dev-uae`) — attached to `AzureBastionSubnet`.
  - Inbound: allows HTTPS (portal access) + Gateway Manager (Azure control plane).
  - Outbound: allows SSH/RDP to spoke VMs + HTTPS to Azure Cloud (telemetry).
  - Why: Azure Bastion has strict required rules — missing any of these and Bastion won't function.

- **App NSG** (`nsg-app-dev-uae`) — attached to `snet-app`.
  - Inbound: allows SSH/RDP from Bastion subnet (10.0.2.0/26) only + HTTPS from hub (10.0.0.0/16). Denies all other inbound at priority 4096.
  - Outbound: allows database ports (1433/SQL, 5432/Postgres, 3306/MySQL) to data subnet + HTTPS to internet.
  - Why: app tier should only be reachable from Bastion (maintenance) and the hub (firewall-forwarded traffic). No direct internet inbound.

- **Data NSG** (`nsg-data-dev-uae`) — attached to `snet-data`.
  - Inbound: allows database ports from app subnet (10.1.0.0/24) only + Bastion SSH for maintenance. Denies all other inbound.
  - Outbound: denies internet access entirely.
  - Why: data tier is fully isolated. Only the app tier talks to it. No internet access = smallest attack surface.

- Each NSG is associated to its subnet via `azurerm_subnet_network_security_group_association` — this is the resource that actually attaches the NSG. Creating the NSG alone does nothing without this association.

#### `firewall.tf`
Azure Firewall sitting in the hub VNet's `AzureFirewallSubnet` (10.0.0.0/26). Standard SKU.

- **Cost toggle** — `var.deploy_firewall` (default `true`). Set to `false` in dev to skip deployment and save ~$900/month. All firewall resources use `count = var.deploy_firewall ? 1 : 0`.

- **Public IP** (`pip-afw-dev-uae`) — Static, Standard SKU. Required for Azure Firewall outbound traffic. Every Azure Firewall must have at least one public IP.

- **Firewall Policy** (`afwp-dev-uae`) — the ruleset container. Rules are organized hierarchically: Policy → Rule Collection Group → Rule Collection → Rules. DNS proxy enabled so spokes can use the firewall as their DNS server.

- **Firewall resource** (`afw-dev-uae`) — the firewall itself, linked to the policy and the subnet.

- **Network Rule Collection Group** (Layer 4 — port/protocol level):
  - Allow spoke-to-spoke traffic (10.1.0.0/16 ↔ 10.1.0.0/16)
  - Allow DNS outbound (UDP 53) from spokes

- **Application Rule Collection Group** (Layer 7 — FQDN/HTTP level):
  - Allow Azure services: *.microsoft.com, *.azure.com, *.windows.net, *.azurecr.io, *.blob.core.windows.net, *.database.windows.net
  - Allow package managers: *.ubuntu.com, *.docker.io, registry.npmjs.org, pypi.org

> Interview note: Azure Firewall rules have two types — **network rules** (IP/port based, Layer 4) and **application rules** (FQDN based, Layer 7). Application rules can filter by domain name, which is more secure than opening IP ranges.

#### `peering.tf`
VNet Peering connecting hub ↔ spoke. Azure peering is **not bidirectional by default** — you must create a peering resource in both directions.

- **Hub → Spoke** (`peer-hub-to-spoke-dev`) — allows the hub to reach spoke resources. `allow_forwarded_traffic = true` so the firewall can forward traffic to spokes.

- **Spoke → Hub** (`peer-spoke-to-hub-dev`) — allows spokes to reach hub services (firewall, bastion, gateway). Also allows forwarded traffic.

- **Gateway transit** — set to `false` for now (no VPN/ExpressRoute gateway deployed yet). Flip `allow_gateway_transit = true` on hub and `use_remote_gateways = true` on spoke when a gateway is added in a later phase.

> Interview note: "VNet peering is non-transitive" — if Spoke A peers with Hub and Spoke B peers with Hub, Spoke A and Spoke B can only talk via the hub's firewall, not directly. This is a security feature, not a bug.

#### `log-analytics.tf`
Central Log Analytics Workspace — every resource in the landing zone sends diagnostic data here.

- **Log Analytics Workspace** (`log-hub-dev-uae`) — PerGB2018 SKU (5 GB/day free ingestion, 30-day retention). This is the single pane of glass for all infrastructure logs and metrics. KQL queries run against this workspace.

- **Diagnostic Settings — Firewall** (`diag-afw-to-logs`) — streams four log categories:
  - `AZFWApplicationRule` — Layer 7 (FQDN) rule hits
  - `AZFWNetworkRule` — Layer 4 (port/protocol) rule hits
  - `AZFWThreatIntel` — threat intelligence matches
  - `AZFWDnsProxy` — DNS proxy resolution logs
  - Plus `AllMetrics` for throughput, latency, etc.
  - Uses `count = var.deploy_firewall ? 1 : 0` — only created when firewall is deployed.

- **Diagnostic Settings — NSGs** (`diag-nsg-*-to-logs`) — one per NSG (bastion, app, data). Two log categories each:
  - `NetworkSecurityGroupEvent` — individual packet allow/deny events
  - `NetworkSecurityGroupRuleCounter` — aggregated hit counts per rule

> Interview note: Diagnostic settings are a separate resource from the resource they monitor. A common mistake is creating the resource but forgetting the diagnostic setting — then you have no visibility into what it's doing.

#### `outputs.tf`
Exports key resource IDs so `environments/dev/main.tf` can pass them to future modules:
- `log_analytics_workspace_id` / `_name` — needed by Defender for Cloud (Phase 2), AKS (Phase 4)
- `hub_vnet_id` / `spoke_vnet_id` — for additional peerings or VPN gateways
- `spoke_app_subnet_id` / `spoke_data_subnet_id` — AKS and database modules will deploy into these
- `firewall_private_ip` — used as next-hop in spoke route tables (returns null when firewall is disabled)
- `hub_resource_group_name` / `spoke_resource_group_name` — for resources that co-locate in the same RGs

---

### Wiring: `environments/dev/main.tf`

Added `module "networking"` block that calls the networking module with dev-appropriate values:
- `deploy_firewall = false` — saves ~$900/month in dev
- `tags = module.landing_zone.tags` — inherits consistent tagging from Phase 0

This is the pattern: each environment folder is a *composition root* that calls modules with environment-specific values. The modules themselves are environment-agnostic.

---

### Backend block: `environments/dev/providers.tf`

Already present and commented out. Three-step activation:
1. Run `terraform apply` in `terraform/bootstrap/` to create the storage account
2. Uncomment the `backend "azurerm"` block
3. Run `terraform init -migrate-state` to move the local state to remote

**Pending: `az login` + `terraform plan`** — deferred until Azure account is set up.

---

### ✅ Phase 1 Complete (code-side)

All networking resources written and wired. The only remaining step is `az login` + `terraform apply` against a real Azure subscription to provision these resources. That can happen anytime.

---

## Phase 2 — Identity, RBAC & Policy ✅
*Complete (code-side). See [phase-2-notes.md](phase-2-notes.md).*

## Phase 3 — Azure DevOps Pipelines + GitHub Actions ✅
*Complete (code-side). See [phase-3-notes.md](phase-3-notes.md).*

## Phase 4 — Workload Deployments ✅
*Complete (code-side). See [phase-4-notes.md](phase-4-notes.md).*

## Phase 5 — ML & AI Instances ✅
*Complete (code-side). See [phase-5-notes.md](phase-5-notes.md).*

## Phase 6 — Healthcare Compliance Hardening ✅
*Complete (code-side). See [phase-6-notes.md](phase-6-notes.md).*
