---
title: Agent Identity and Access
aliases: [agent IAM, agent RBAC, NHI agent, agent credentials]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, agents, identity, security, iam, nhi]
updated: 2026-06-21
sources:
  - https://media.defense.gov/2025/Apr/09/2003685573/-1/-1/0/CSI_BEST_PRACTICES_FOR_SECURING_NHI.PDF
  - https://nvlpubs.nist.gov/nistpubs/ir/2025/NIST.IR.8596.ipd.pdf
  - https://cloudsecurityalliance.org/blog/2025/03/06/agentic-ai-threats-and-mitigations
  - https://datatracker.ietf.org/doc/html/rfc8693
  - https://techcommunity.microsoft.com/blog/microsoftdefenderatpblog/introducing-the-microsoft-agent-governance-toolkit/4415521
  - https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
---

# Agent Identity and Access

> [!summary]
> Agent identity and access is the practice of giving every AI agent a distinct, verifiable identity with tightly scoped credentials — so each agent can only act within its authorised boundary, its actions are attributable to a human sponsor, and its credentials are revocable in milliseconds if behaviour deviates.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

AI agents are a new category of non-human identity (NHI): they act autonomously, they call APIs and tools, and they can spawn sub-agents — yet they are not humans and cannot use MFA. Traditional IAM built for people does not fit. Agent identity and access adapts the IAM discipline to agents: each agent instance gets its own identity (not a shared service account), obtains short-lived credentials via workload identity federation, operates under the least-privilege scopes its current task requires, and produces an audit trail that links every action back to a human sponsor.

The technical surface spans three layers: **identity** (who is this agent?), **authorisation** (what is it allowed to do?), and **credential lifecycle** (how are secrets obtained and rotated?).

## Why it matters

The numbers make the risk concrete. GitGuardian's 2025 State of Secrets Sprawl report found a 144:1 NHI-to-human credential ratio at peak organisations and 44 % year-on-year NHI growth. SANS 2026 found 92 % of organisations fail 90-day credential rotation for machine identities. NSA's 2026 NHI advisory mandated a discovery and inventory exercise for all federal agencies. When agents share service accounts or use static API keys, a single compromised credential grants blast radius across every task that credential was used for — often with no way to distinguish legitimate from attacker actions after the fact.

The regulatory signal is sharpening: NIST IR 8596 (2025 initial public draft) provides the first NIST guidance specifically on machine-to-machine identity in zero-trust architectures. The EU AI Act Article 12 mandates append-only audit logs for high-risk AI systems (in force August 2026), and attributing log entries to a specific agent identity is a prerequisite for compliance.

## Key concepts

### Workload identity federation

The modern baseline: instead of distributing static secrets, the agent runtime proves its identity to a trusted identity provider (the platform OIDC endpoint) and exchanges that proof for a short-lived cloud credential. No secret is ever stored; the credential expires after minutes or hours.

| Platform | Mechanism | What the agent gets |
|---|---|---|
| AWS | IRSA (IAM Roles for Service Accounts) | STS `AssumeRoleWithWebIdentity` → temporary AWS credentials |
| GCP | Workload Identity Federation | Service account impersonation via OIDC token exchange |
| Azure | Managed Identity / Federated Credentials | Azure AD token via IMDS endpoint |
| GitHub Actions | OIDC provider | Cloud credentials per-job, no stored secrets |

For agents running outside a cloud compute context (e.g., a local process or an LLM-hosted execution environment), OAuth 2.0 RFC 8693 Token Exchange provides the protocol for delegated credential acquisition: the agent presents an assertion (its identity token) and receives a narrower-scoped access token for the downstream resource.

### Per-agent vs. per-task identity

Two scoping models exist:

- **Per-agent identity** — one identity per agent type or deployment. Simple to provision; blast radius is bounded to that agent's capability set. Suitable when the agent runs a single, stable set of tasks.
- **Per-task identity** — a new, ephemerally scoped credential is minted at task start and destroyed at task end. The access token's scope reflects only what the current task needs (`read:s3/bucket-A`, not `s3:*`). Stronger isolation; required for high-consequence or multi-tenant workflows.

The practical pattern: per-agent identity as the base, per-task scope restriction via OAuth token exchange or IAM session policies layered on top.

### Delegated authorisation for sub-agents

Multi-agent workflows introduce a delegation problem: if an orchestrator agent spawns a sub-agent to execute a tool call, the sub-agent should not inherit the orchestrator's full scope — it should receive the minimum scope needed for the delegated step. RFC 8693 `act_as` and `may_act` claims model this: the sub-agent's token includes a reference to the orchestrator's identity, preserving the attribution chain while restricting the scope.

Microsoft's Inter-Agent Trust Protocol (IATP), part of the April 2026 Agent Governance Toolkit, extends this with DID-based agent identity and a dynamic trust score (0–1000, five tiers from "untrusted" to "certified partner") that gates what any given agent-to-agent call is permitted to do.

### RBAC vs. ABAC for agents

Traditional **RBAC** (role-based) assigns a role to the agent identity (`role: document-reader`). Simple to reason about; coarse-grained. Works when agents have stable, well-defined function sets.

**ABAC** (attribute-based) evaluates a policy expression at request time: `allow if agent.task_type == "summarise" AND resource.classification != "RESTRICTED"`. More expressive; enables task-aware and data-classification-aware gates. The OPA/Cedar policy engines from [[agent-governance-and-policy]] evaluate ABAC policies sub-millisecond in the request path.

Practical pattern: start with RBAC roles scoped to agent types, then introduce ABAC attribute checks for any resource that carries a classification label or sensitivity tag.

### Least privilege and JIT elevation

For agents, least privilege means: the credential issued at task start grants exactly the actions needed for that task, nothing more. JIT elevation adds a time-bound: if an agent's task requires a privileged action (e.g., write to a production database), the agent requests that elevated scope for a fixed window (seconds to minutes), executes the action, and the scope is revoked automatically.

This maps directly to PAM (privileged access management) patterns already used for human operators — agents are just another principal type.

## Design decisions and trade-offs

**Shared service account vs. per-agent identity.** Shared accounts are operationally simpler but destroy attribution — the audit log shows the service account acting, not which agent or which task. Per-agent identity is non-negotiable for compliance-regulated workloads.

**Platform-native vs. DID-based identity.** Cloud-native workload identity (IRSA, WIF, Managed Identity) is zero-configuration if agents run on the cloud's own compute. DID-based identity (W3C Decentralised Identifiers) is portable across clouds and execution environments but requires an identity registry and verification infrastructure. Microsoft IATP adopts DIDs for cross-organisational agent trust; cloud-native is the right default for single-cloud deployments.

**RBAC vs. ABAC.** RBAC is easier to audit; ABAC is more powerful but harder to reason about. A hybrid model — RBAC for the coarse boundary, ABAC for fine-grained resource attribute checks — gives both properties. OPA's bundle API lets the ABAC policy live in version control and be distributed centrally.

**Credential rotation cadence.** Workload identity federation tokens naturally expire (minutes to hours). For static credentials that cannot yet be eliminated, automated rotation via HashiCorp Vault or cloud-native secrets managers (AWS Secrets Manager, Azure Key Vault) on a ≤24-hour cycle is the target.

## State of the art

**NIST IR 8596 (2025)** is the reference publication for machine-to-machine identity in zero-trust architectures. It defines NHI inventory as a prerequisite for ZTA and specifies credential lifecycle requirements (no static secrets in compute workloads, time-bounded tokens, automated rotation).

**NSA NHI advisory (April 2026)** mandated NHI discovery and inventory for federal agencies, elevating agent identity from a best practice to a compliance obligation.

**CSA Agentic AI Framework v1 (March 2026)** lists three agent identity principles: *provision with intention* (define scope before provisioning, not after), *authenticate cryptographically* (no password-equivalent credentials), *authorise just-in-time* (narrowest scope for each task, time-bounded).

**Microsoft Agent Governance Toolkit (April 2026, MIT licence)** ships IATP as an open protocol: DID-based agent identity, OAuth 2.0 token exchange for delegation, and a dynamic trust score updated per interaction. It integrates with Entra External ID for cross-organisation agent trust.

**AWS Bedrock AgentCore (GA October 2025)** provides a managed execution environment where agents run with Managed Identity, automatic credential rotation, and per-session isolated execution contexts — reducing the operational burden of per-task scoping to configuration rather than code.

> [!tip]
> Start with workload identity federation (zero stored secrets) and per-agent RBAC roles. Introduce ABAC attribute checks and per-task scope narrowing only where data classification or multi-tenant isolation demands it.

## Pitfalls and anti-patterns

- **Shared service account for multiple agents.** Eliminates attribution; a compromised credential cannot be scoped to a single task.
- **Static API keys embedded in environment variables or code.** Rotated never in practice; appear in logs, stack traces, and container images.
- **Inherited human credentials.** An agent running as a developer's personal OAuth token carries the human's full scope. Use workload identity even in dev/test.
- **No deprovisioning step.** Agents decommissioned without revoking their credentials leave live credentials with no principal attached.
- **Privilege escalation via sub-agent.** An orchestrator that passes its own full-scope token to a sub-agent allows the sub-agent to act beyond its intended boundary. Always narrow scope on delegation.
- **Logging the action but not the identity.** An audit log entry `tool_call: read_file(path=/etc/config)` without the agent ID and task ID is useless for forensics.

## See also

- [[agents-as-system-citizens]] — NHI governance, accountability chain, and lifecycle
- [[agent-governance-and-policy]] — policy-as-code enforcement pipeline and OWASP Agentic AI Top 10
- [[iam-and-secrets-management]] — foundational IAM patterns (RBAC, ABAC, secrets vaults)
- [[zero-trust-architecture]] — ZTA model and NHI in the CISA five-pillar framework
- [[human-in-the-loop-design]] — gates that complement access controls for high-consequence actions
- [[agentic-system-design]] — overall agent architecture

## Sources

- NSA (2026). *Best Practices for Securing Non-Human Identities.* NSA/CISA Cybersecurity Information Sheet. https://media.defense.gov/2025/Apr/09/2003685573/-1/-1/0/CSI_BEST_PRACTICES_FOR_SECURING_NHI.PDF
- NIST (2025). *NIST IR 8596 ipd — Machine-to-Machine Identity in Zero Trust Architectures.* Initial Public Draft. https://nvlpubs.nist.gov/nistpubs/ir/2025/NIST.IR.8596.ipd.pdf
- CSA (2026). *Agentic AI Threats and Mitigations — CSA Agentic AI Framework v1.* March 2026. https://cloudsecurityalliance.org/blog/2025/03/06/agentic-ai-threats-and-mitigations
- IETF (2019). *RFC 8693 — OAuth 2.0 Token Exchange.* https://datatracker.ietf.org/doc/html/rfc8693
- Microsoft (2026). *Introducing the Microsoft Agent Governance Toolkit.* Tech Community Blog, April 2026. https://techcommunity.microsoft.com/blog/microsoftdefenderatpblog/introducing-the-microsoft-agent-governance-toolkit/4415521
- AWS (2024). *IAM Roles for Service Accounts (IRSA).* EKS User Guide. https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html
