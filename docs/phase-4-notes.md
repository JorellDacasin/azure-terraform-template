# Phase 4 — Workload Deployments

## Overview

Phase 4 deploys the actual services into the landing zone. Everything runs in the spoke VNet's subnets (created in Phase 1), governed by the policies from Phase 2, and deployed through the pipelines from Phase 3.

```
Hub VNet (10.0.0.0/16)           Spoke VNet (10.1.0.0/16)
┌─────────────────────┐          ┌──────────────────────────┐
│ Firewall             │          │ App Subnet (10.1.0.0/24) │
│ Bastion              │◄────────►│   AKS nodes + pods       │
│ Gateway              │ peering  │   App Service             │
└─────────────────────┘          │                          │
                                 │ Data Subnet (10.1.1.0/24)│
                                 │   SQL (private endpoint)  │
                                 └──────────────────────────┘
                                         │
                                 ACR (acrjdplatformdevuae.azurecr.io)
                                 APIM (optional gateway in front)
```

## Azure Container Registry (ACR)

Private Docker image store. AKS pulls from here instead of Docker Hub.

- **Basic SKU** — 10 GB storage, cheapest tier. Upgrade to Standard ($20/mo) when you need geo-replication or webhooks beyond 2.
- **Admin disabled** — images are pulled via managed identity (AcrPull role), not username/password. No credentials to leak or rotate.
- **Naming** — globally unique DNS hostname, no hyphens, lowercase. e.g. `acrjdplatformdevuae.azurecr.io`

> Interview note: "I disable admin credentials on ACR and use AcrPull role assignment to the AKS kubelet identity. Zero credentials in the cluster — no imagePullSecrets, no service account tokens for registry auth."

## Azure Kubernetes Service (AKS)

The main compute platform. Containers run here in pods, managed by Kubernetes.

### Key Decisions

- **Free tier** — no SLA, fine for dev. Standard ($75/mo) for prod.
- **Azure CNI networking** — pods get real VNet IPs from the spoke app subnet. This means:
  - NSGs apply at the pod level (not just node level)
  - Pods can reach SQL in the data subnet directly (no NAT traversal)
  - The firewall in the hub can inspect pod traffic
  - Alternative (kubenet) uses NAT — breaks network visibility and makes NSG rules useless for pods
- **System-assigned managed identity** — AKS authenticates to Azure without a service principal. No credentials to rotate.
- **Single node, Standard_B2s** — cheapest burstable VM. Scale up for prod.
- **OMS Agent** — streams container logs to Log Analytics (Phase 1). Enables Container Insights dashboards.
- **Azure AD RBAC** — Kubernetes RBAC roles backed by Azure AD groups. Combined with Azure RBAC for the cluster resource.

### Service CIDR

```
Hub VNet:      10.0.0.0/16   (firewall, bastion, gateway)
Spoke VNet:    10.1.0.0/16   (app subnet, data subnet)
K8s Services:  10.2.0.0/16   (ClusterIP — internal to K8s, never on VNet)
DNS Service:   10.2.0.10     (must be inside service_cidr)
```

These must never overlap. The service CIDR is Kubernetes-internal only — it never appears on the Azure VNet.

> Interview note: "I use Azure CNI over kubenet because pods need real VNet IPs for proper network policy enforcement. In a healthcare environment like LifeCare, you need NSGs and firewall rules to apply at the pod level, not just the node level — kubenet's NAT breaks that."

## Azure SQL

Managed relational database with private networking.

- **Basic SKU (5 DTU)** — ~$5/month, cheapest. Enough for dev. Prod would use Standard S0+ or serverless (auto-pause).
- **TLS 1.2 minimum** — no downgrade attacks. Healthcare requirement.
- **Public access disabled** — only reachable via private endpoint in the data subnet.
- **Private endpoint** — SQL gets a private IP inside the data subnet. Even if credentials leak, there's no network path from the internet.
- **Private DNS zone** — resolves `*.database.windows.net` to the private IP inside the VNet. Without this, apps would resolve the public IP and get blocked.

> Interview note: "Public access is disabled and the database is only reachable through a private endpoint. Even if someone gets the connection string, there's no network path from outside the VNet. For LifeCare's patient data, this is non-negotiable."

## App Service

Simpler compute for web apps that don't need Kubernetes orchestration.

- **Free F1 SKU** — zero cost, 60 min CPU/day. No custom domain or SSL. Upgrade to B1 ($13/mo) for always-on.
- **Linux** — cheaper than Windows, matches the container ecosystem.
- **When to use vs AKS** — single-container apps, dashboards, internal tools. If it doesn't need multiple containers, service discovery, or rolling deployments, App Service is simpler and cheaper.

> Interview note: "Not everything needs Kubernetes. For a simple API or dashboard, App Service is faster to deploy, cheaper to run, and less operational overhead. I use AKS for microservices that need orchestration, and App Service for simpler workloads."

## API Management (APIM)

API gateway in front of AKS and App Service.

- **Consumption tier** — pay-per-call, no monthly base cost. First 1M calls/month free. Default OFF (cost toggle).
- **What it provides** — rate limiting, API keys, caching, request/response transformation, developer portal, audit logging.

> Interview note: "APIM gives me a single entry point for all APIs. For healthcare APIs, it provides audit logging for every API call — who called what, when, and what data was returned. That's a regulatory requirement."

## Cost Summary (dev)

| Resource | SKU | Monthly Cost |
|---|---|---|
| ACR | Basic | ~$5 |
| AKS | Free + 1× B2s | ~$30 (VM only) |
| SQL Server + DB | Basic (5 DTU) | ~$5 |
| App Service | F1 (Free) | $0 |
| APIM | Consumption (OFF) | $0 |
| **Total** | | **~$40/month** |

## Files Written

```
terraform/modules/workloads/
├── variables.tf         — all inputs + cost toggles
├── resource-group.tf    — rg-workloads-dev-uae (separate lifecycle)
├── acr.tf               — Container Registry (Basic, admin disabled)
├── aks.tf               — AKS (Free, Azure CNI, managed identity, OMS, ACR pull role)
├── sql.tf               — SQL Server + DB + private endpoint + private DNS zone
├── app-service.tf       — Service Plan (F1) + Linux Web App (Node 22)
├── apim.tf              — API Management (Consumption, cost toggle)
└── outputs.tf           — ACR login server, AKS FQDN, SQL FQDN, app URL, APIM gateway URL

terraform/environments/dev/
├── main.tf              — updated: calls workloads module
└── variables.tf         — updated: added sql_admin_password

docs/
└── phase-4-notes.md     — this file
```
