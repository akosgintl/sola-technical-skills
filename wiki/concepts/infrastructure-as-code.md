---
title: Infrastructure as Code
aliases: [IaC, infrastructure-as-code, Terraform, OpenTofu, Pulumi, CDK]
type: concept
domain: platform
status: mature
tags: [platform, iac, terraform, opentofu, pulumi, cdk, automation, drift, state]
updated: 2026-06-20
sources:
  - "https://zop.dev/resources/blogs/infrastructure-as-code-best-practices-terraform-pulumi-and-opentofu-in-2026/"
  - "https://www.frugaltesting.com/blog/terraform-vs-pulumi-vs-opentofu-best-iac-tools-for-cloud-automation-in-2026"
  - "https://sanj.dev/post/terraform-pulumi-aws-cdk-2025-decision-framework"
  - "https://encore.dev/articles/terraform-alternatives"
  - "https://eitt.academy/knowledge-base/terraform-vs-pulumi-vs-opentofu-iac-comparison-2026/"
---

# Infrastructure as Code

> [!summary]
> Infrastructure as Code (IaC) treats cloud resources as software artifacts defined in version-controlled files. The goal is reproducible, reviewable, and auditable infrastructure — the same guarantees that source control provides for application code, applied to networks, compute, databases, and policies. In 2026 the tool landscape has stabilized around three main options: OpenTofu/Terraform (declarative HCL), Pulumi (general-purpose languages), and cloud-native CDKs (AWS CDK, Azure Bicep, Google Config Connector). Tool choice matters less than the practices around it: state management, secrets hygiene, drift detection, and module discipline.

**Domain:** [[tier-2-solid|Platform Engineering & IaC]]

## What it is

Infrastructure as Code encodes the desired state of infrastructure in machine-readable files that tools apply to reach and maintain that state. Two models:

**Declarative (desired-state):** define what you want; the tool figures out how to get there and what to change. The canonical model. Tools: Terraform/OpenTofu, AWS CloudFormation, Azure Bicep.

**Imperative (general-purpose languages):** write code that generates infrastructure definitions or directly calls cloud APIs. More flexible; carries the risk of non-idempotent scripts. Tools: Pulumi, AWS CDK, Google Cloud CDK.

Both models converge on the same operational concern: a **state file** that tracks what the tool believes is deployed, reconciled against cloud reality on each plan/apply cycle.

## Why it matters

Manual infrastructure configuration does not scale and does not audit. ClickOps (configuring resources through the cloud console) produces:
- **Snowflake environments** — no two environments are alike; reproducibility is impossible
- **No audit trail** — who changed what and when is undiscoverable
- **No review process** — infrastructure changes bypass the pull-request review that application code gets
- **Slow recovery** — recreating infrastructure after a failure requires memory and documentation

IaC inverts all four: environments are identical (within variable overrides), every change is a commit with a diff, changes go through PR review, and recovery is `terraform apply`.

## Key concepts / building blocks

### Tool landscape

**Terraform / OpenTofu (HCL, declarative):**
Terraform is the dominant IaC tool — large ecosystem of providers (1000+ for AWS, Azure, GCP, Kubernetes, GitHub, Datadog, etc.), widespread team familiarity, and a simple declarative model. HashiCorp changed Terraform's license to BUSL in 2023; **OpenTofu** is the CNCF-hosted open-source fork with identical HCL syntax, the same providers, and open governance. Migration from Terraform to OpenTofu is a one-line change.

For new projects without a strong language-specific reason: OpenTofu/Terraform with HCL is the default due to ecosystem breadth and team familiarity.

**Pulumi (TypeScript, Python, Go, C#, Java):**
Pulumi replaces HCL with real programming languages. Benefits: full IDE support, type checking, loops, conditionals, native abstractions from the language (classes, functions, packages). Pulumi uses the same provider ecosystem as Terraform (via bridge providers) and has its own first-party providers. Best fit when: the team has strong software engineering backgrounds and values testability; infrastructure logic is complex enough to benefit from language features.

**AWS CDK (TypeScript/Python/Java/Go — generates CloudFormation):**
CDK is AWS-native: write TypeScript or Python that synthesizes to CloudFormation YAML. Level 2 constructs encode sensible AWS defaults. Best fit for: AWS-only organizations with TypeScript/Python teams who want IaC with IDE support and don't need cross-cloud portability.

**Azure Bicep:** Microsoft's declarative DSL for Azure; cleaner syntax than ARM templates. Tight Azure integration; no cross-cloud story.

**Crossplane:** Kubernetes-native IaC; defines cloud resources as Kubernetes Custom Resources. Best fit when the organization is already Kubernetes-centric and wants a single control plane for both workloads and infrastructure.

### State management

IaC tools maintain a **state file** that maps the declared configuration to real cloud resource IDs. The state file is the source of truth for what the tool knows is deployed.

**Remote state is mandatory in team environments.** Local state is single-user and produces conflicts. Use: Terraform Cloud/HCP Terraform, S3 + DynamoDB locking (AWS), Azure Blob + lease locking, Google Cloud Storage.

**State file security:** state files contain sensitive data (database passwords, private keys, connection strings) in plaintext. Restrict access to the remote state backend with IAM; never commit state files to Git; never log state file contents. Treat the state backend as a secrets store.

**State locking:** prevents concurrent applies from corrupting state. DynamoDB (for S3 backend), Terraform Cloud, and most managed backends handle locking automatically.

**State isolation:** use separate state files per environment (dev/staging/prod) and per logical unit. One giant state file for all infrastructure creates long plan times, high blast radius on changes, and merge conflicts on the state lock.

### Drift detection

Drift occurs when someone changes cloud resources outside of IaC — via the console, CLI, or another tool. Drift accumulates silently until the next apply, which may unexpectedly revert manual changes.

**Scheduled drift detection:** run `tofu plan` or `terraform plan` in read-only mode on a schedule (every 4–6 hours). Alert when the plan shows a non-empty diff. Teams that run scheduled drift detection catch manual console changes within hours rather than discovering them weeks later during the next deploy.

**Enforcing IaC discipline:** the cultural complement to tooling — restrict console/CLI permissions to read-only for all but break-glass scenarios; require all infrastructure changes via pull requests.

### Modules and reuse

IaC modules are reusable compositions of resources — equivalent to functions in programming. A module for "a secured S3 bucket" encodes bucket encryption, versioning, access logging, and public access block in one reusable unit.

**Module design principles:**
- Modules should have a clear single responsibility (a VPC, a database cluster, a service's full infrastructure stack)
- Expose only the inputs that vary; hard-code sensible secure defaults
- Pin module versions; unpinned modules break on upstream changes
- Public module registries: Terraform Registry (registry.terraform.io), Pulumi Registry

**Environment promotion:** use the same module across dev/staging/prod with different variable overrides (instance sizes, replica counts, retention periods). Never duplicate module code per environment.

### Secrets hygiene

Secrets in IaC state and code are the most consistently underestimated risk.

**Never:**
- Store secrets as Terraform `output` values — they persist in state and are exposed to anyone with state access
- Hardcode secrets in `.tf` files or commit them to Git
- Use `sensitive = true` as the only protection — it prevents display but secrets still exist in state

**Instead:**
- Generate secrets during `apply` and write them directly to a secrets manager (AWS Secrets Manager, Azure Key Vault, HashiCorp Vault) as a Terraform resource
- Have applications retrieve secrets at runtime from the secrets manager — never from IaC outputs
- Use dynamic secrets (Vault, AWS IAM roles) rather than static credentials where possible

See [[encryption-and-key-management]] for the full key management treatment.

### Policy as code integration

IaC changes should pass policy gates before applying:
- **OPA/Conftest** — open policy agent rules evaluated against Terraform plan JSON; blocks applies that violate security or cost policies
- **Checkov / tfsec / Trivy** — static analysis of IaC files for known security misconfigurations; runs in CI before plan
- **Sentinel (Terraform Cloud)** — policy-as-code in the Terraform Cloud/Enterprise managed workflow

See [[policy-as-code]] for the full treatment.

## Design decisions & trade-offs

**Terraform/OpenTofu vs. Pulumi vs. CDK:**

| If... | Use |
|---|---|
| Team knows HCL and has no strong language preference | OpenTofu/Terraform |
| Terraform license is a concern | OpenTofu (identical syntax, open governance) |
| Team prefers TypeScript/Python, values testability | Pulumi |
| AWS-only, TypeScript team | AWS CDK |
| Kubernetes-centric, want unified control plane | Crossplane |

**Monorepo vs. per-service IaC:**
Two models: one IaC repository for all infrastructure (monorepo), or IaC co-located with each service. Monorepo simplifies cross-service dependency management and has one pipeline. Per-service co-location aligns ownership and enables teams to deploy their own infrastructure. Common middle ground: shared modules in a monorepo, service-specific IaC co-located with the service.

**When to use Terraform vs. Kubernetes operators for cloud resources:**
Terraform manages cloud resources before workloads are deployed; Kubernetes operators manage cloud resources as part of workload lifecycle (Crossplane, AWS Controllers for Kubernetes). Use Terraform for infrastructure that outlives any single workload (VPCs, DNS zones, IAM roles). Use Kubernetes operators when resource lifecycle should follow pod/workload lifecycle.

## State of the art

The OpenTofu fork has reached stability and feature parity with Terraform, and new projects are increasingly choosing it for open governance. Pulumi has matured significantly and is the preferred IaC tool for software-engineering-centric platform teams.

**AI-assisted IaC generation** is emerging (see [[ai-generated-iac-reviewer]]): Copilot and purpose-built tools generate initial Terraform modules from natural language or existing architecture diagrams. Generated IaC still requires expert review — the module may be functionally correct but violate security, cost, or module discipline standards.

**GitOps for IaC:** applying the same GitOps workflow used for application deployments (Argo CD, Flux) to infrastructure — pull-based reconciliation of infrastructure state from Git. Terraform Cloud's agent-based model and Atlantis (open-source) provide similar capabilities. The trend is toward infrastructure and application GitOps on a unified workflow.

## Pitfalls & anti-patterns

**ClickOps for "just a quick change."** Every out-of-band change creates drift. The next IaC apply reverts it or conflicts with it. Enforce IaC for all infrastructure changes, even small ones.

**Single state file for all environments.** One apply error can affect prod. Separate state files per environment; add manual approval gates for production applies.

**Secrets in state without access controls.** IaC state files frequently contain database passwords and private keys. Unrestricted state backend access = credential exposure. Lock down the state backend as tightly as production secrets stores.

**Unpinned provider and module versions.** Provider updates can introduce breaking changes. Pin provider versions in `required_providers`; pin module versions in `source` references; upgrade deliberately.

**No drift detection.** Assuming that because IaC exists, drift cannot occur. It always will. Scheduled plan runs are the safety net.

## See also

- [[ai-generated-iac-reviewer]]
- [[policy-as-code]]
- [[cicd-pipeline-architecture]]
- [[developer-experience]]
- [[cloud-governance-at-scale]]
- [[encryption-and-key-management]]

## Sources

- Zop.dev. (2026). Infrastructure as Code Best Practices: Terraform, Pulumi, and OpenTofu in 2026. https://zop.dev/resources/blogs/infrastructure-as-code-best-practices-terraform-pulumi-and-opentofu-in-2026/
- FrugalTesting. (2026). Terraform vs. Pulumi vs. OpenTofu: Best IaC Tools for Cloud Automation in 2026. https://www.frugaltesting.com/blog/terraform-vs-pulumi-vs-opentofu-best-iac-tools-for-cloud-automation-in-2026
- Sanj.dev. (2025). Terraform vs Pulumi vs AWS CDK: 2026 Decision Framework. https://sanj.dev/post/terraform-pulumi-aws-cdk-2025-decision-framework
- Encore. (2026). Best Terraform Alternatives in 2026: Complete Comparison Guide. https://encore.dev/articles/terraform-alternatives
- EITT Academy. (2026). Terraform vs Pulumi vs OpenTofu — Which IaC Tool in 2026? https://eitt.academy/knowledge-base/terraform-vs-pulumi-vs-opentofu-iac-comparison-2026/
