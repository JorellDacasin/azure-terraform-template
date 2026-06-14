# Phase 2 — Identity, RBAC & Policy

## Service Principals

A **service principal** is a non-human identity for an application or service to authenticate to Azure.

In this template we create two:
- **sp-terraform** — the identity Terraform uses to deploy infrastructure. Assigned the custom *Terraform Deployer* role.
- **sp-pipeline** — the identity Azure DevOps pipelines use. Starts as Reader; promoted per-workload as needed.

> Interview note: "I separate Terraform and pipeline identities so a compromised pipeline credential can't modify infrastructure. Each has the minimum permissions needed — least privilege by design."

## Custom RBAC Role — Terraform Deployer

Azure has built-in roles (Owner, Contributor, Reader), but built-in Contributor includes the ability to assign roles — which would let Terraform escalate its own permissions. The *Terraform Deployer* custom role is a scoped Contributor that explicitly **blocks IAM write actions** (`Microsoft.Authorization/roleAssignments/write`).

> Interview note: "I never give Terraform service principals Owner or raw Contributor. A custom role gives full resource management with IAM escalation blocked — Terraform can deploy, but it can't grant itself elevated access."

## Azure Policy

Azure Policy enforces guardrails across the subscription. Three policies here:

1. **Allowed Locations** — deny resources outside UAE North / UAE Central. Enforces data residency.
2. **Required Tags** — deny resources missing `environment`, `workload`, `owner`, `managed_by`. Ensures every resource is traceable for cost and compliance.
3. **Allowed VM SKUs** — deny expensive VM sizes in dev. Prevents accidental cost overruns.

All three are assigned at the **subscription scope** so they apply to every resource group.

> Interview note: "Policies are assigned at subscription scope so they act as guardrails before anything is deployed — you can't accidentally deploy to the wrong region or forget a tag. This is especially important in a healthcare context like LifeCare where data residency and auditability are regulatory requirements."

## Key Vault

Key Vault is Azure's centralized secret store — TLS certificates, connection strings, API keys, encryption keys.

Key design choices:
- **RBAC authorization** (not legacy access policies) — simpler, auditable, CAF-recommended.
- **Purge protection** enabled in prod — prevents a deleted vault from being permanently destroyed within the retention window. Required for compliance.
- **Soft delete** — 7-day recovery window in dev, longer in prod.
- Network ACLs set to Allow now, locked to private endpoint in Phase 6 (healthcare hardening).

> Interview note: "I use Key Vault RBAC mode over access policies. RBAC is more granular — you can scope a role to a specific secret, not just the whole vault. And it integrates with Azure AD audit logs, which matters for compliance."

## Defender for Cloud

Microsoft Defender for Cloud is Azure's Cloud Security Posture Management (CSPM) and workload protection platform.

- **Free tier** — always on, gives you Secure Score and basic recommendations.
- **Standard tier** — adds threat detection, vulnerability scanning, just-in-time VM access.
- Disabled in dev (cost toggle) — enabled in staging/prod.

> Interview note: "Defender for Cloud gives me a Secure Score dashboard showing security posture across the whole subscription. For LifeCare, enabling the Containers and Key Vaults plans would be a day-one requirement given the sensitivity of health data."

## Build Order

```
landing-zone → networking → identity → (Phase 3: pipelines) → (Phase 4+: workloads)
```

Identity depends on landing-zone (for tags) but not on networking — they can be applied in parallel or sequentially. The networking outputs (subnet IDs, VNet IDs) feed into Phase 4 workloads.

## Files Written

```
terraform/
└── modules/
    └── identity/
        ├── variables.tf         — all inputs
        ├── service-principals.tf — sp-terraform, sp-pipeline
        ├── rbac.tf              — custom role + assignments
        ├── policy.tf            — 3 policy definitions + assignments
        ├── key-vault.tf         — Key Vault + RBAC assignments
        ├── defender.tf          — Defender for Cloud pricing tiers
        └── outputs.tf           — SP IDs, KV ID/URI/name, RG name
terraform/
└── environments/
    └── dev/
        ├── main.tf              — updated: calls identity module
        ├── providers.tf         — updated: added azuread provider ~>3.0
        └── variables.tf         — new: subscription_id, tenant_id inputs
docs/
└── phase-2-notes.md             — this file
```
