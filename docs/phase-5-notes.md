# Phase 5 — ML & AI Instances

## Overview

Phase 5 deploys Azure's ML and AI services. Split into two modules:
- **`aml-workspace`** — ML platform (experiments, training, model management)
- **`azure-openai`** — AI services (GPT-4o, embeddings, search, content safety)

```
┌─ aml-workspace ────────────────────────────────┐
│ AML Workspace (free — control plane only)      │
│ ├── Storage Account (experiment data, models)  │
│ ├── App Insights (endpoint monitoring)         │
│ ├── Key Vault (Phase 2 — secrets)              │
│ ├── ACR (Phase 4 — custom training images)     │
│ └── Compute Cluster (scale to 0 when idle)     │
└────────────────────────────────────────────────┘

┌─ azure-openai ─────────────────────────────────┐
│ Azure OpenAI (GPT-4o + text-embedding-3-small) │
│ AI Search (Free — vector search for RAG)       │
│ AI Services (vision, speech, language — OFF)   │
│ Content Safety (harmful content filtering)     │
└────────────────────────────────────────────────┘
```

## AML Workspace

The central hub for ML experiments, model training, and deployment. The workspace itself is **free** — you pay for compute when training and endpoints when serving.

Required supporting resources (created by the module):
- **Storage Account** — datasets, model artifacts, experiment logs
- **Application Insights** — model endpoint monitoring (latency, errors)
- **Key Vault** — referenced from Phase 2 (not duplicated)
- **ACR** — referenced from Phase 4 (custom training Docker images)

> Interview note: "AML Workspace is the control plane for the entire ML lifecycle. It doesn't run anything itself — compute clusters handle training, managed endpoints handle serving. I wire it into existing Key Vault and ACR so there's one set of secrets and one image registry."

## Compute Cluster

On-demand VMs for training ML models. The key feature is **scale-to-zero**:

| State | Nodes | Cost |
|---|---|---|
| No training jobs | 0 | $0 |
| Job submitted | auto-scales to max_nodes | VM cost while running |
| Job complete + 2 min idle | scales back to 0 | $0 |

- `Standard_DS2_v2` — 2 vCPU, 7 GB RAM. Cheapest for dev training.
- Deployed into the spoke app subnet — training can reach data in the data subnet.
- `vm_priority = "Dedicated"` — for prod. Switch to `"LowPriority"` for ~80% savings on non-critical jobs (but VMs can be evicted).

> Interview note: "The compute cluster scales to zero between training jobs. You only pay when a model is actually training. For LifeCare, this means the ML infrastructure is always ready without burning money on idle VMs."

## Azure OpenAI

Microsoft's managed OpenAI service — GPT-4o, embeddings, DALL-E, etc. behind Azure's enterprise boundary.

### Why Azure OpenAI over public OpenAI API
- **VNet integration** — models accessible only from your VNet (Phase 6)
- **RBAC** — Azure AD controls who can call the API
- **Content filtering** — built-in, can't be disabled
- **Audit logging** — every API call logged in Azure Monitor
- **Data privacy** — your prompts are NOT used for model training
- **SLA** — 99.9% uptime guarantee

### Model Deployments

| Model | Purpose | Capacity |
|---|---|---|
| `gpt-4o` | Chat, reasoning, generation | 10K TPM |
| `text-embedding-3-small` | Text → vectors for RAG | 10K TPM |

> Interview note: "I deploy Azure OpenAI instead of calling the public API because it gives me VNet integration, RBAC, and audit logging — all required for healthcare data. The model runs inside Azure's boundary, and prompts containing patient data never leave our subscription."

### Region Limitation
Azure OpenAI is NOT available in all regions. UAE North may not support it. The module uses `openai_location` (default: Sweden Central) for the OpenAI resource. Other AI services stay in the primary region.

For strict data residency: check Azure's region availability docs before deploying.

## RAG Pattern (OpenAI + AI Search)

RAG = Retrieval-Augmented Generation. The standard enterprise pattern for AI that answers questions from your own data:

```
  User question
       │
       ▼
  ┌─ Embed query ──────────┐
  │ text-embedding-3-small │
  └────────┬───────────────┘
           │ vector
           ▼
  ┌─ AI Search ────────────┐
  │ Vector similarity      │
  │ → top-K documents      │
  └────────┬───────────────┘
           │ context
           ▼
  ┌─ GPT-4o ───────────────┐
  │ "Answer using this     │
  │  context: [docs]"      │
  │ → grounded answer      │
  └────────────────────────┘
```

### Why RAG over fine-tuning
- **Cheaper** — no training cost, just inference
- **Faster to update** — re-index documents vs re-train a model
- **Traceable** — every answer cites its source documents
- **No hallucination risk** — model answers from provided context only

### AI Search — Free tier
50 MB storage, 3 indexes, 10K documents. Enough for dev/training.

> Interview note: "I use RAG instead of fine-tuning for LifeCare's medical knowledge base. RAG is cheaper, sources are traceable (critical for healthcare — every answer must be auditable), and updating the knowledge base is just re-indexing documents, not re-training a model."

## AI Services

Multi-service account — one resource, one API key, access to:
- **Vision** — image analysis, OCR (medical document scanning)
- **Speech** — transcription, text-to-speech (doctor-patient recordings)
- **Language** — sentiment analysis, NER, summarization (medical reports)
- **Translator** — multilingual support

Default OFF (cost toggle). Enable when learning specific APIs.

> Interview note: "For LifeCare, the Language service handles medical document summarization and entity extraction — pulling patient names, diagnoses, and medications from unstructured text. The Speech service transcribes doctor-patient recordings for documentation."

## Content Safety

Filters harmful content from AI inputs and outputs. Categories:
- **Hate** — discriminatory language
- **Violence** — graphic or threatening content
- **Sexual** — explicit content
- **Self-harm** — dangerous instructions

Returns severity scores (0-6) per category. Your app sets the threshold.

Built into Azure OpenAI by default, but a **standalone** resource lets you:
- Filter non-OpenAI content (user uploads, chat messages)
- Use custom blocklists (drug names, medical terms)
- Call the API independently

> Interview note: "Content Safety is non-negotiable for healthcare AI. A patient-facing chatbot must filter harmful responses before they reach the user. I deploy it standalone so it also filters user-uploaded content, not just model outputs."

## Cost Summary (dev)

| Resource | SKU | Monthly Cost |
|---|---|---|
| AML Workspace | Free | $0 |
| AML Storage Account | Standard LRS | ~$1 |
| App Insights | Free tier | $0 |
| Compute Cluster | DS2_v2, min=0 | $0 (idle) |
| Azure OpenAI | S0, pay-per-token | ~$0-5 (dev usage) |
| AI Search | Free | $0 |
| AI Services | OFF | $0 |
| Content Safety | S0, pay-per-call | ~$0-1 (dev usage) |
| **Total** | | **~$1-7/month** |

## Files Written

```
terraform/modules/aml-workspace/
├── variables.tf         — inputs (Key Vault + ACR refs, compute settings)
├── main.tf              — AML Workspace + Storage Account + App Insights
├── compute.tf           — Compute Cluster (scale to 0, in spoke subnet)
└── outputs.tf           — workspace ID, storage ID, App Insights ID

terraform/modules/azure-openai/
├── variables.tf         — inputs (region, models, capacity, cost toggles)
├── openai.tf            — Azure OpenAI account + GPT-4o + embedding deployments
├── ai-search.tf         — AI Search (Free tier, for RAG)
├── ai-services.tf       — AI Services multi-service (OFF by default)
├── content-safety.tf    — Content Safety (healthcare requirement)
└── outputs.tf           — endpoints, keys, deployment names

terraform/environments/dev/
└── main.tf              — updated: calls aml_workspace + azure_openai modules

docs/
└── phase-5-notes.md     — this file
```
