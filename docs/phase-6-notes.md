# Phase 6 — Healthcare Compliance Hardening

## Overview

Phase 6 takes every resource from Phases 1–5 and hardens it for regulated healthcare data. This is the difference between a dev environment and a production LifeCare deployment.

Four pillars:

```
┌─ Private Endpoints ────────────────────────────┐
│ Every service locked to private IPs in the VNet │
│ Zero public surface area                        │
└─────────────────────────────────────────────────┘
┌─ Customer-Managed Keys (CMK) ──────────────────┐
│ YOU control the encryption key in Key Vault     │
│ Revoke key → data unreadable                    │
└─────────────────────────────────────────────────┘
┌─ Purview ──────────────────────────────────────┐
│ Data governance — discover, classify, track     │
│ Where does patient data flow?                   │
└─────────────────────────────────────────────────┘
┌─ Immutable Storage (WORM) ─────────────────────┐
│ Tamper-proof audit logs — 365-day retention     │
│ Even admins can't delete or modify              │
└─────────────────────────────────────────────────┘
```

## Private Endpoints

Locks every service to a private IP inside the data subnet. Public access is blocked.

Services with private endpoints:
- **Key Vault** — `privatelink.vaultcore.azure.net`
- **ACR** — `privatelink.azurecr.io` (requires Premium SKU)
- **Azure OpenAI** — `privatelink.openai.azure.com`
- **AML Workspace** — `privatelink.api.azureml.ms`

Each private endpoint needs:
1. **Private endpoint resource** — NIC with a private IP in the subnet
2. **Private DNS zone** — resolves `*.service.net` → private IP
3. **VNet link** — connects the DNS zone to the spoke VNet

Cost: ~$7.30/month per endpoint.

> Interview note: "Every AI service — OpenAI, AML, ACR, Key Vault — is locked behind a private endpoint. There's zero public surface area. Even if credentials leak, there's no network path from the internet. For LifeCare's patient data, this is the first thing I implement."

### Dev vs Prod

| Setting | Dev | Prod |
|---|---|---|
| Private endpoints | OFF (ACR Basic doesn't support PE) | ON (upgrade ACR to Premium) |
| Public access | Allowed (for local dev) | Blocked on all services |

## Customer-Managed Keys (CMK)

By default, Azure encrypts at rest with Microsoft-managed keys. CMK gives you control:

- **You own the key** — RSA-2048, stored in your Key Vault
- **You control access** — Key Vault RBAC + audit logs
- **You can revoke** — delete the key → all encrypted data becomes unreadable
- **Auditors can verify** — Key Vault logs prove who accessed the key and when

Applied to: AML Storage Account. Extend the pattern to other storage accounts as needed.

> Interview note: "I use customer-managed keys so we can prove to auditors that we control the encryption. If a storage account is compromised, revoking the key makes all data immediately unreadable — even Azure can't decrypt it."

### Compliance Standards

| Standard | CMK Required? |
|---|---|
| HIPAA | Recommended (safe harbor) |
| HITRUST | Required for Level 2+ |
| UAE NESA | Required for critical infrastructure |
| SOC 2 Type II | Required for encryption controls |

## Microsoft Purview

Data governance platform. Scans your estate and answers: "Where is patient data, who has access, and how does it flow?"

Capabilities:
- **Data discovery** — scans storage, SQL, AI services
- **Classification** — auto-detects PII, PHI, financial data
- **Data lineage** — visual map of data flow across services
- **Data catalog** — searchable inventory of all datasets

Default OFF for dev (complex pricing). Enable in prod/staging.

> Interview note: "Purview gives me a data lineage map. I can show auditors exactly where patient data originates, which services process it, and where it ends up. For LifeCare, this replaces manual data flow documentation with live, automated tracking."

## Immutable Storage (WORM)

Write Once, Read Many. Audit logs stored here CANNOT be modified or deleted during the retention period.

- **365-day retention** — matches most healthcare audit requirements
- **Tamper-proof** — even Azure admins, subscription owners, or compromised accounts can't delete logs
- **Standard LRS** — cheapest tier (~$0.02/GB/month)
- **Separate storage account** — `st<prefix>audit<env><region>`, isolated from operational data

> Interview note: "Audit logs are in WORM storage — 365-day retention, zero modification allowed. If an admin account is compromised, the attacker can't cover their tracks by deleting logs. This is how you maintain audit trail integrity."

## Diagnostic Settings

Every AI/ML resource streams audit logs to two destinations:

| Resource | Log Categories | Destinations |
|---|---|---|
| Azure OpenAI | RequestResponse, Audit | Log Analytics + Immutable Storage |
| AML Workspace | ComputeClusterEvent, RunStatusChanged | Log Analytics + Immutable Storage |
| Content Safety | RequestResponse, Audit | Log Analytics + Immutable Storage |
| Key Vault | AuditEvent | Log Analytics + Immutable Storage |

**Dual destination strategy:**
- **Log Analytics** — real-time KQL queries, dashboards, alerts
- **Immutable Storage** — long-term tamper-proof retention

> Interview note: "Every AI API call is dual-logged. Log Analytics for real-time monitoring — 'who called GPT-4o in the last hour?' — and immutable storage for audit compliance — 'prove this log hasn't been tampered with.'"

## Cost Summary (dev)

| Resource | SKU | Monthly Cost |
|---|---|---|
| Private endpoints | OFF in dev | $0 |
| CMK key | Free (in existing KV) | $0 |
| Purview | OFF in dev | $0 |
| Immutable storage | Standard LRS | ~$1 |
| Diagnostic settings | Free (Log Analytics ingestion) | $0 |
| **Total** | | **~$1/month** |

**Prod estimate** (all toggles ON):
| Resource | Monthly Cost |
|---|---|
| 4× private endpoints | ~$30 |
| ACR Premium (required for PE) | ~$50 |
| Purview | ~$100+ |
| CMK | $0 |
| Immutable storage | ~$1-5 |
| **Total** | **~$180-200/month** |

## Files Written

```
terraform/modules/compliance/
├── variables.tf             — inputs (refs to all earlier phases, cost toggles)
├── private-endpoints.tf     — PE + DNS zones for KV, ACR, OpenAI, AML
├── cmk.tf                   — RSA-2048 key + storage account CMK encryption
├── purview.tf               — Microsoft Purview (data governance, OFF by default)
├── immutable-storage.tf     — WORM storage account + audit-logs container + lifecycle
├── diagnostic-settings.tf   — audit logs for OpenAI, AML, Content Safety, Key Vault
└── outputs.tf               — PE IPs, CMK key ID, audit storage ID, Purview ID

terraform/environments/dev/
└── main.tf                  — updated: calls compliance module

docs/
└── phase-6-notes.md         — this file
```
