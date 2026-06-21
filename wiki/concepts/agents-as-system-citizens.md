---
title: Agents as System Citizens
aliases: [agents as first-class actors, agent principal model, NHI agent identity]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, agents, architecture, identity, NHI, governance]
updated: 2026-06-21
sources:
  - https://labs.cloudsecurityalliance.org/agentic/agentic-identity-governance-framework-v1/
  - https://labs.cloudsecurityalliance.org/research/csa-whitepaper-nonhuman-identity-agentic-ai-governance-v1-cs/
  - https://builtin.com/articles/enterprise-identity-access-management
  - https://blog.gitguardian.com/what-ai-agents-can-teach-us-about-nhi-governance/
  - https://www.sailpoint.com/blog/agentic-ai-and-the-future-of-iam
  - https://christian-schneider.net/blog/non-human-identity-governance-gap-ai-agents/
---

# Agents as System Citizens

> [!summary]
> The architectural stance that AI agents are first-class actors in a system — provisioned with intent, authenticated cryptographically, authorized just-in-time, monitored continuously, and deprovisioned cleanly — rather than ephemeral scripts that borrow credentials and leave no trace. This reframes agent design from prompt engineering toward identity and systems engineering.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

When an AI agent reads a database, calls an API, writes a file, or triggers a workflow, it is making authenticated, authorized requests to real systems. Treating the agent as a script (borrowing a shared service account or a hard-coded API key) means those actions are indistinguishable from each other, unattributable to a specific agent or task, and impossible to revoke per-agent without affecting all callers.

Treating agents as system citizens means applying to them the same identity and access disciplines applied to human users and service workloads:

- **Identity:** Each agent has a unique, cryptographically verifiable identifier — not a shared credential.
- **Authorization:** The agent's permissions are scoped to the task it was provisioned to perform, not an inherited set of broad capabilities.
- **Accountability:** Every action the agent takes is logged with the agent's identity, task context, and human sponsor.
- **Lifecycle:** Agents are provisioned when a task begins and deprovisioned (with credential revocation) when it ends.

The shift matters because agents are autonomous: a service account doesn't decide to request new permissions mid-task or act in emergent sequences across systems. Agents do. The governance model must account for autonomy, not just authentication.

## Why it matters

**The NHI scale problem.** Non-human identities — a category that includes AI agents, service accounts, OAuth tokens, API keys, and workload identities — already outnumber human identities by more than 90 to 1 in many enterprises, with some reporting ratios up to 144:1. The NHI population grew 44% between 2024 and 2025 (GitGuardian 2025 NHI survey). AI agents are adding a new, fast-growing category of NHIs — with the critical distinction that agents are autonomous rather than passive.

**Governance gap is severe.** Only 28% of organisations can trace agent actions back to a human sponsor across all environments — meaning 72% have AI agents operating without a clear accountability chain. 51% of organisations report no clear ownership of their AI identity population (WEF 2025). 92% fail to rotate machine credentials even on a 90-day cycle (SANS 2026 NHI Survey).

**Scale of coming adoption.** Gartner projects that 40% of enterprise applications will integrate task-specific AI agents by end of 2026, up from under 5% at projection time. Without a principal model for agents, those integrations will default to shared credentials and over-provisioned access — repeating the mistakes of the 2010s service-account era at an order of magnitude larger scale.

## Key concepts

### The agent principal model

An agent is a **principal** in the same sense as a user or a service: an entity that can be authenticated, authorized, and held accountable for its actions. The CSA Agent Identity Governance Framework (AIGF, 2026) formalises this as three requirements:

1. **Provisioned with intention** — identity is created explicitly for a named task, with a defined scope of access, not inherited from a generic account.
2. **Authenticated cryptographically** — short-lived tokens, not static API keys. Ed25519 keys, OIDC-issued JWTs, or DID-based credentials (as used in the Microsoft Agent Governance Toolkit's Inter-Agent Trust Protocol).
3. **Authorized just-in-time** — permissions are issued for the duration of a task and revoked automatically when the task ends.

### Agent identity vs. traditional NHI

Legacy NHI (service accounts, static API keys) is static and passive: it authenticates once, holds broad access, and never changes until manually rotated. Agent identity is dynamic, ephemeral, and autonomous:

| Property | Service account (legacy NHI) | Agent identity |
|---|---|---|
| Lifetime | Persistent (months–years) | Ephemeral (task duration) |
| Access scope | Broad (role-based) | Narrow (task-scoped) |
| Credential type | Static API key or long-lived token | Short-lived JWTs / dynamic credentials |
| Autonomy | Passive (called by code) | Active (decides what to call next) |
| Action sequencing | Deterministic (scripted) | Emergent (LLM-guided) |
| Revocation trigger | Manual | Automatic on task end / anomaly |

The difference in autonomy and emergent behavior is why the legacy NHI governance model breaks: an agent can discover, request, and use capabilities its operators did not anticipate.

### Accountability chain

Every agent action should be traceable through a chain: `action → agent identity → task → human sponsor`. The human sponsor is the person or team that commissioned the task and is accountable for the agent's actions. Without this chain, auditors, incident responders, and regulators cannot establish who is responsible for a given agent action.

### Agent lifecycle

```
Provision    →  identity created, task-scoped permissions issued, JIT credentials granted
Authenticate →  cryptographic handshake at each API boundary
Execute      →  all tool calls logged with agent ID, task ID, timestamp, parameters
Monitor      →  behavioural anomaly detection (deviation from expected permission pattern)
Deprovision  →  credentials revoked automatically on task end or anomaly trigger
```

### Quotas and cost governance

Agents consume compute, API calls, and tokens at rates that can exceed human usage by orders of magnitude. System-citizen treatment includes **resource quotas**: per-agent token budgets, rate limits on external API calls, cost attribution to the sponsoring team or project, and alerting on quota breaches. Without quotas, a runaway agent loop can exhaust an organisation's monthly API budget in minutes.

## Design decisions & trade-offs

**Short-lived tokens vs. credential complexity.** JIT short-lived tokens are the right security posture but require an identity provider (e.g., HashiCorp Vault, AWS IAM Roles Anywhere, Entra Managed Identity) that can issue and rotate credentials on sub-minute timescales. This is operationally more complex than a static API key. The cost is justified by the risk: a stolen short-lived token expires before it can be exploited; a stolen static API key is valid until manually revoked (which may be never).

**Task-scoped vs. role-scoped permissions.** Task-scoped permissions (this agent may read table X and write to queue Y for this task) are more secure but require a permission model granular enough to express task boundaries. Role-scoped permissions (this agent may use the "data-reader" role) are simpler but over-provision. Most production deployments start with coarse-grained roles and refine to task-scope as governance matures.

**Behavioural monitoring overhead.** Continuous behavioural verification (checking whether the agent's actions match expected patterns) adds latency and requires a baseline model of normal behaviour. For high-throughput agents, this monitoring runs asynchronously and triggers alerts or revocation rather than blocking in the hot path.

**Multi-agent trust.** In multi-agent architectures, one agent may delegate to another. The delegating agent should not be able to grant more permissions than it holds (no privilege escalation through delegation). The CSA AIGF and the Microsoft Agent Governance Toolkit's Inter-Agent Trust Protocol (IATP) both specify delegation constraints at the protocol level.

## State of the art

The Cloud Security Alliance published the **Agent Identity Governance Framework (AIGF) v1** in early 2026, the first formal specification for treating agents as identity principals. It aligns with NIST SP 800-207 (Zero Trust) and NIST IR 8596 (non-human identity) and defines credential lifecycle, delegation constraints, and audit requirements.

The **Microsoft Agent Governance Toolkit** (April 2026) implements DID-based agent identity with Ed25519 cryptography, IATP for secure agent-to-agent communication, and dynamic trust scoring (0–1000 scale, five behavioral tiers) that can trigger automatic permission reduction or agent termination.

**NSA guidance on NHI** (2026 update) includes an explicit agent-identity discovery mandate: security teams must inventory all AI agents alongside service accounts and API keys as first-class NHI subjects.

The dominant implementation path in AWS, Azure, and GCP environments is **workload identity federation**: agents running in compute workloads assume cloud IAM roles via OIDC tokens rather than static keys. AWS IRSA, GCP Workload Identity, and Azure Managed Identity all support this pattern and are the recommended starting point for agent identity in cloud-native deployments.

## Pitfalls & anti-patterns

- **Shared service account for all agents.** Indistinguishable actions, no per-agent revocation, no accountability chain. The single most common agent security mistake.
- **Static API keys in environment variables.** Keys that don't expire, that may be logged, and that grant the same access whether the agent is behaving normally or has been compromised.
- **Inheriting human user permissions.** An agent running with a developer's credentials inherits all their access — including access the agent does not need and that the developer may not want an autonomous system to use.
- **No deprovisioning path.** Provisioning an agent identity with no defined end-of-life means credentials accumulate indefinitely. Define the deprovisioning trigger at provisioning time.
- **Ignoring multi-agent privilege escalation.** Allowing an orchestrator to grant sub-agents more permissions than the orchestrator holds. Always enforce that delegation cannot exceed the delegator's scope.

## See also

- [[agent-identity-and-access]]
- [[agent-governance-and-policy]]
- [[iam-and-secrets-management]]
- [[zero-trust-architecture]]
- [[multi-agent-orchestration]]
- [[human-in-the-loop-design]]
- [[policy-as-code]]

## Sources

- CSA Agent Identity Governance Framework v1: https://labs.cloudsecurityalliance.org/agentic/agentic-identity-governance-framework-v1/
- CSA Whitepaper — The Non-Human Identity Governance Vacuum: https://labs.cloudsecurityalliance.org/research/csa-whitepaper-nonhuman-identity-agentic-ai-governance-v1-cs/
- Built In — Securing the Future of IAM: Why AI Agents Need First-Class Identity Governance: https://builtin.com/articles/enterprise-identity-access-management
- GitGuardian — What AI Agents Can Teach Us About NHI Governance: https://blog.gitguardian.com/what-ai-agents-can-teach-us-about-nhi-governance/
- SailPoint — Agentic AI and the Next Era of IAM: https://www.sailpoint.com/blog/agentic-ai-and-the-future-of-iam
- Christian Schneider — Closing the AI Agent Identity Governance Gap: https://christian-schneider.net/blog/non-human-identity-governance-gap-ai-agents/
