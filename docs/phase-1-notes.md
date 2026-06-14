# Phase 1 — Landing Zone with Terraform

## Remote State

Terraform tracks every resource it creates in a state file (`terraform.tfstate`). By default this is local, which breaks CI/CD pipelines and multi-machine setups. Storing it in Azure Blob Storage means every machine and pipeline reads from the same source of truth.

**Why a bootstrap exists** — You can't use Terraform to create the storage account if that same storage account is where Terraform needs to store its state. Chicken-and-egg problem. The bootstrap is a separate, one-time Terraform config that uses a local state file just long enough to create the remote storage. You run it once per project, then every other config points its backend at that storage account.

## Hub-Spoke VNet Topology

The standard CAF network design. One *hub* VNet holds shared services (Firewall, DNS, VPN Gateway). *Spoke* VNets hold workloads and peer to the hub. All traffic between spokes routes through the hub — this centralises security inspection and keeps workloads isolated from each other.

> Interview note: "VNet peering is non-transitive — if Spoke A peers with Hub and Spoke B peers with Hub, Spoke A and Spoke B can only talk via the hub's firewall, not directly. This is a security feature, not a bug."

## NSGs (Network Security Groups)

A set of inbound/outbound rules attached to a subnet or NIC. Controls which traffic is allowed in and out. Free resource.

Three NSGs in this template:
- **Bastion NSG** — Azure Bastion has strict required rules (HTTPS inbound, Gateway Manager, SSH/RDP outbound to spokes). Missing any of these and Bastion won't function.
- **App NSG** — app tier only reachable from Bastion and the hub (firewall-forwarded traffic). No direct internet inbound.
- **Data NSG** — fully isolated. Only the app tier talks to it. Internet outbound denied entirely — smallest attack surface.

> Interview note: `AzureFirewallSubnet` and `GatewaySubnet` do NOT allow custom NSGs — Azure manages those internally. A common exam gotcha.

## Azure Firewall

Sits in the hub VNet's `AzureFirewallSubnet` (10.0.0.0/26). Standard SKU.

Rules are split into two types:
- **Network rules** (Layer 4) — IP/port based. Used for spoke-to-spoke traffic and DNS (UDP 53).
- **Application rules** (Layer 7) — FQDN based. Used for Azure services (*.microsoft.com, *.azure.com) and package managers (docker.io, pypi.org, npmjs.org).

Cost toggle (`var.deploy_firewall = false`) skips deployment in dev to save ~$900/month. All firewall resources use `count = var.deploy_firewall ? 1 : 0`.

> Interview note: "Application rules can filter by domain name, which is more secure than opening IP ranges — you're allowing exactly *.azurecr.io, not the entire IP block Azure Container Registry might use."

## Log Analytics Workspace

Central logging sink for Azure Monitor, Defender for Cloud, AKS, and other services. PerGB2018 SKU — 5 GB/day free ingestion, 30-day retention.

Diagnostic settings are wired up for:
- **Firewall** — AZFWApplicationRule, AZFWNetworkRule, AZFWThreatIntel, AZFWDnsProxy logs + AllMetrics.
- **NSGs** — NetworkSecurityGroupEvent and NetworkSecurityGroupRuleCounter per NSG.

> Interview note: "Diagnostic settings are a separate resource from the resource they monitor. A common mistake is creating the resource but forgetting the diagnostic setting — then you have no visibility into what it's doing."

## Subnet Address Plan

```
Hub VNet       10.0.0.0/16
  AzureFirewallSubnet   10.0.0.0/26   (min /26, exact name required)
  GatewaySubnet         10.0.1.0/27   (min /27, exact name required)
  AzureBastionSubnet    10.0.2.0/26   (min /26, exact name required)

Spoke VNet     10.1.0.0/16
  snet-app-dev-uae      10.1.0.0/24   (AKS, workloads)
  snet-data-dev-uae     10.1.1.0/24   (databases, storage)
```

> Interview note: The three reserved subnet names are a common interview gotcha — Azure rejects any other name for Firewall, Gateway, and Bastion subnets.

## Bootstrap Workflow (run once per project)

```bash
cd terraform/bootstrap
terraform init
terraform apply        # creates RG + storage account + container
# copy outputs into environments/dev/providers.tf backend block
cd ../environments/dev
terraform init -migrate-state   # moves local state to remote
```

**Pending: `az login` + `terraform plan`** — deferred until Azure account is set up.

## Files Written

```
terraform/
├── bootstrap/
│   ├── providers.tf         — local backend only (intentional, one-time use)
│   ├── main.tf              — RG + storage account (Standard LRS, HTTPS-only, TLS 1.2) + container
│   └── outputs.tf           — prints rg name, storage account name, container name
└── modules/
    └── networking/
        ├── variables.tf     — env, region, location, tags, deploy_firewall
        ├── hub-vnet.tf      — hub VNet + 3 reserved subnets
        ├── spoke-vnet.tf    — spoke VNet + app + data subnets
        ├── nsgs.tf          — bastion/app/data NSGs + subnet associations
        ├── firewall.tf      — Azure Firewall + public IP + policy + network/app rule collections
        ├── peering.tf       — hub↔spoke peering (both directions)
        ├── log-analytics.tf — Log Analytics Workspace + diagnostic settings
        └── outputs.tf       — VNet IDs, subnet IDs, firewall private IP, LAW ID, RG names
terraform/
└── environments/
    └── dev/
        ├── main.tf          — updated: calls networking module (deploy_firewall=false)
        └── providers.tf     — backend block present, commented out pending bootstrap
docs/
└── phase-1-notes.md         — this file
```
