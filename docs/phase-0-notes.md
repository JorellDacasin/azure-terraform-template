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
*Not started. Covers: hub-spoke VNet, NSGs, Firewall, Log Analytics, remote state.*

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
