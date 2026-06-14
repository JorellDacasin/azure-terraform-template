# Phase 3 — Azure DevOps Pipelines + GitHub Actions

## Why Two Platforms

**Azure DevOps Pipelines** — the enterprise standard. Banks, hospitals (LifeCare), and government use it. Native Azure integration, environment approval gates, audit trails. More relevant for interviews.

**GitHub Actions** — native to GitHub where the repo lives. Simpler setup, no external service connection needed. Better for actually running and testing the pipelines.

Both are written against the same Terraform code. They don't conflict — you can run both simultaneously on the same repo.

## Pipeline Architecture

```
  Developer pushes code
         │
         ▼
  ┌─── PR opened ───────────────────────────────┐
  │  terraform init → validate → plan            │
  │  Plan output posted as PR comment (GH) or    │
  │  published as artifact (Azure DevOps)        │
  │  Reviewer sees exactly what will change       │
  └──────────────┬──────────────────────────────┘
                 │ PR approved + merged
                 ▼
  ┌─── Push to main ────────────────────────────┐
  │  terraform plan (re-plan — state may have    │
  │  changed since PR approval)                  │
  │  terraform apply (with approval gate)        │
  │  Environment: dev (auto) / prod (manual)     │
  └─────────────────────────────────────────────┘

  ┌─── Scheduled (weekly) ──────────────────────┐
  │  terraform plan -detailed-exitcode           │
  │  Exit 0 = no drift, Exit 2 = DRIFT          │
  │  Creates GitHub Issue or logs warning        │
  └─────────────────────────────────────────────┘
```

## Shared Init Template (Azure DevOps only)

Azure DevOps supports YAML templates — reusable step blocks. The `templates/terraform-init.yml` file installs Terraform and runs `terraform init` with backend config. All three pipelines call it instead of duplicating those steps.

GitHub Actions doesn't have an exact equivalent (composite actions are close but heavier), so each workflow has its own init steps.

> Interview note: "I use YAML templates in Azure DevOps to keep init logic DRY. One change to the backend config or Terraform version propagates to all pipelines automatically."

## PR Validation

Triggers on every pull request that changes `.tf` files. Runs `validate` (syntax check) then `plan` (what would change).

- **Azure DevOps:** publishes plan as a pipeline artifact
- **GitHub Actions:** posts the plan as a PR comment (updates the same comment on re-push to avoid spam)

> Interview note: "Infrastructure changes go through the same code review process as application code. The reviewer sees the exact plan output — how many resources will be created, modified, or destroyed — before approving the merge."

## Apply Pipeline

Triggers on push to main (after merge). Two stages:

1. **Plan** — re-runs `terraform plan` because state may have changed between PR approval and merge. Saves the plan binary.
2. **Apply** — uses the saved plan binary. Applies exactly what was reviewed, nothing more.

**Environment approval gates:**
- Azure DevOps: configure in Pipelines → Environments → dev → Approvals & checks
- GitHub Actions: configure in Settings → Environments → dev → Protection rules

Dev auto-applies. Prod would require manual approval from a designated reviewer.

> Interview note: "I never run `terraform apply` from a laptop in production. Everything goes through the pipeline with approval gates. Dev auto-deploys for speed, prod requires explicit sign-off. The saved plan binary ensures you apply exactly what was reviewed — no surprises."

## Drift Detection

Scheduled weekly (Monday 06:00 UTC / 10:00 Dubai). Runs `terraform plan -detailed-exitcode`:

| Exit Code | Meaning | Action |
|---|---|---|
| 0 | No drift — Azure matches code | Log clean ✅ |
| 1 | Error — plan failed | Pipeline fails ❌ |
| 2 | **Drift detected** — someone changed Azure manually | Warning ⚠️ |

- **Azure DevOps:** logs a pipeline warning (`##vso[task.logissue type=warning]`)
- **GitHub Actions:** creates a GitHub Issue with the full plan output and remediation steps

> Interview note: "Drift detection catches manual portal changes. If someone logs into Azure and tweaks a firewall rule, the Monday scan catches it and creates an issue. For healthcare environments like LifeCare, this is critical — every change must be traceable."

## Credentials

### Azure DevOps
1. **Service Connection** — links Azure DevOps to Azure via `sp-pipeline` (Phase 2)
2. **Variable Group** (`terraform-credentials`) — linked to Key Vault, pulls:
   - `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`
   - `BACKEND_RESOURCE_GROUP`, `BACKEND_STORAGE_ACCOUNT`, `BACKEND_CONTAINER`, `BACKEND_STATE_KEY`

### GitHub Actions
**Repository Secrets** (Settings → Secrets and variables → Actions):
   - `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`
   - `BACKEND_RESOURCE_GROUP`, `BACKEND_STORAGE_ACCOUNT`, `BACKEND_CONTAINER`, `BACKEND_STATE_KEY`

> Interview note: "Credentials never live in YAML or code. Azure DevOps pulls them from Key Vault at runtime via a linked variable group. GitHub Actions uses repository secrets. Both are encrypted at rest and masked in logs."

## Setup Guide — Azure DevOps

1. Create a free org at `dev.azure.com` → create a project
2. Project Settings → Service Connections → New → Azure Resource Manager → Service Principal (manual) → enter `sp-pipeline` credentials from Phase 2
3. Pipelines → Library → New Variable Group → name it `terraform-credentials` → add the 8 variables above (or link to Key Vault)
4. Pipelines → New Pipeline → GitHub (YAML) → select the repo → choose `azure-pipelines/pr-validation.yml`
5. Repeat for `apply.yml` and `drift-detection.yml`
6. Pipelines → Environments → create `dev` → optionally add approval checks

## Setup Guide — GitHub Actions

1. Go to repo Settings → Secrets and variables → Actions
2. Add the 8 secrets listed above
3. Push the `.github/workflows/` files to main
4. Open a test PR that modifies a `.tf` file → PR Validation runs automatically
5. Optionally: Settings → Environments → create `dev` → add protection rules

## Files Written

```
azure-pipelines/
├── templates/
│   └── terraform-init.yml       — shared init steps (DRY)
├── pr-validation.yml            — validate + plan on PR
├── apply.yml                    — plan + apply on merge (with approval gate)
└── drift-detection.yml          — weekly drift check

.github/
└── workflows/
    ├── pr-validation.yml        — validate + plan on PR (posts PR comment)
    ├── apply.yml                — plan + apply on merge (with environment gate)
    └── drift-detection.yml      — weekly drift check (creates GitHub Issue)

docs/
└── phase-3-notes.md             — this file
```
