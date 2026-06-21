---
title: Agent Governance and Policy
aliases: [agent policy, agent allow-lists, agentic AI governance]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, agents, governance, policy, compliance, OWASP]
updated: 2026-06-21
sources:
  - https://github.com/microsoft/agent-governance-toolkit
  - https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/
  - https://techcommunity.microsoft.com/blog/linuxandopensourceblog/agent-governance-toolkit-architecture-deep-dive-policy-engines-trust-and-sre-for/4510105
  - https://www.digitalapplied.com/blog/ai-agent-governance-policy-compliance-2026
  - https://www.bigeye.com/blog/what-is-ai-agent-governance
  - https://www.infoworld.com/article/4155591/microsofts-new-agent-governance-toolkit-targets-top-owasp-risks-for-ai-agents.html
---

# Agent Governance and Policy

> [!summary]
> The rules, allow-lists, policy engines, and audit mechanisms that constrain what autonomous agents may do and create a defensible, immutable record of what they did. It pairs preventive controls (allow-lists, capability sandboxing, policy-as-code gates) with detective controls (append-only audit trails) so that agent behaviour is simultaneously bounded and reviewable — the governance layer that makes autonomous actors auditable principals.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

An AI agent without governance is a capability with no boundary: it can call any tool it discovers, access any data it reaches, and leave no trace a regulator could reconstruct. Agent governance closes that gap by defining, enforcing, and logging the rules that constrain agent behaviour.

Governance has two complementary sides:

- **Preventive controls** — policies that constrain what the agent may do before it acts: tool allow-lists, capability sandboxing, prompt policy gates, execution rings.
- **Detective controls** — mechanisms that record what the agent did so it can be audited, replayed, or investigated: append-only audit logs, action attribution, decision trails.

Governance policy can be expressed as prose (human-readable runbooks), but the operational standard is **policy-as-code**: machine-enforceable, version-controlled rules evaluated at runtime with sub-millisecond latency, not at design time in a document no runtime process reads.

## Why it matters

**Regulatory pressure is converging.** Three governance frameworks took effect or hardened in 2025–2026:

- **EU AI Act** (full effect August 2026): high-risk AI systems must log actions for ≥6 months (Article 12), support human oversight (Article 14), and carry traceability documentation. Fines up to €30 M / 6% global turnover.
- **NIST AI RMF** (GOVERN function): organisational accountability structures, risk tolerance policies, and audit requirements for AI systems.
- **OWASP Agentic AI Top 10** (December 2025): the first formal taxonomy of risks specific to autonomous agents — goal hijacking, tool misuse, identity abuse, memory poisoning, cascading failures, rogue agents — each of which governance policies must address.

**The accountability gap.** As noted in [[agents-as-system-citizens]], 72% of organisations cannot trace agent actions to a human sponsor. Governance is the mechanism that creates that traceability — without it, compliance is structurally impossible to demonstrate.

## Key concepts

### OWASP Agentic AI Top 10 and governance countermeasures

OWASP published the first Top 10 for Agentic Applications in December 2025. Each risk maps to a governance control:

| OWASP Risk | Governance countermeasure |
|---|---|
| Goal hijacking | Semantic intent classifier at input rail; runtime goal monitoring |
| Tool misuse | Tool allow-list; capability sandboxing; execution rings |
| Identity abuse | Cryptographic agent identity; JIT credentials; delegation constraints |
| Memory poisoning | Cross-model verification; read-time provenance checks on agent memory |
| Cascading failures | Circuit breakers; execution quotas; SLO enforcement |
| Rogue agents | Trust scoring; kill switch; ring isolation |
| Supply chain risks | Plugin signing; manifest verification; tool registry |
| Insecure communications | Encrypted inter-agent protocol (IATP); channel authentication |
| Human-agent trust exploitation | HITL approval gates; quorum logic for high-risk decisions |
| Data exfiltration | Output rails; data-loss prevention (DLP) at tool boundaries |

### Policy-as-code enforcement pipeline

Policy-as-code (see [[policy-as-code]]) applied to agents means every action request passes through a policy engine before execution:

```
Agent action request
  → [1] Intent classification   (is this request within the agent's stated goal?)
  → [2] Allow-list check        (is this tool / data source / action permitted for this agent?)
  → [3] Argument validation     (are the action parameters within policy bounds?)
  → [4] Execution              (action runs in a sandboxed execution ring)
  → [5] Output validation       (does the result contain disallowed content / PII?)
  → [6] Audit log              (append-only record with agent ID, task ID, action, result)
```

Policy languages in active use: **OPA/Rego** (general-purpose, CNCF-graduated, used in [[policy-as-code]]); **Cedar** (AWS open-source, purpose-built for authorization, deterministic); **YAML rules** (simpler, lower-expressiveness). The Microsoft Agent Governance Toolkit supports all three in a single policy engine.

### Allow-lists and capability sandboxing

The most immediately actionable governance control is an explicit tool/action allow-list: this agent may call `search_docs`, `write_draft`, and `send_slack_message`. It may not call `delete_record`, `transfer_funds`, or any tool not on the list.

Capability sandboxing goes further: not only must a tool be allow-listed, but the agent runs in an **execution ring** (analogous to CPU privilege rings) where certain operations (file system writes, network calls, subprocess spawning) are structurally prevented — not merely not listed. The Microsoft Agent Governance Toolkit implements four execution rings, from fully sandboxed (no I/O) to privileged (limited external access), with explicit escalation required to move between rings.

### Audit trail requirements

Under EU AI Act Article 12, audit logs for high-risk AI systems must be:
- Retained for ≥6 months
- Append-only and tamper-evident (hash-chained; SHA-256 minimum per the convergent technical standard)
- Attributable (each log entry linked to agent ID, task ID, human sponsor, timestamp)

The log must answer: who commissioned this agent, what task was it given, what actions did it take, what data did it access, what did it produce, and was human approval obtained where required? This is the defensible record that compliance audits and incident investigations reconstruct from.

### Trust scoring and kill switch

Dynamic trust models score an agent's behaviour over time and can reduce permissions or terminate the agent automatically:

- **Trust score** (0–1000, five behavioural tiers in Microsoft AGT): begins at provisioned baseline; decays when the agent takes actions outside expected parameters; recovers as behaviour normalises.
- **Kill switch:** automatic or manual agent termination for tier-breach or anomaly; triggers credential revocation and halts the task cleanly via saga rollback.
- **Trust decay** prevents an agent that has been running correctly for weeks from being granted permanent elevated permissions — trust is contextual and recertified continuously, not established once at provisioning.

### Governance frameworks and standards

Three governance frameworks active in 2026:

| Framework | Owner | Published | Scope |
|---|---|---|---|
| Model AI Governance Framework for Agentic AI | Singapore IMDA | January 2026 | Policy and risk taxonomy for autonomous AI |
| Agentic AI NIST AI RMF Profile v1 | CSA | March 2026 | Maps NIST AI RMF controls to agentic deployments |
| "Careful Adoption of Agentic AI Services" | CISA / Five Eyes | 2026 | Joint guidance for critical infrastructure operators |

## Design decisions & trade-offs

**Allow-list vs. deny-list.** Allow-lists (enumerate what is permitted) are the default-deny starting point: anything not explicitly allowed is blocked. Deny-lists (enumerate what is forbidden) are default-permit: correct only if the full capability surface is known and stable, which it rarely is for LLM-tool integrations where tool discovery is dynamic. Always start with an allow-list.

**Centralised vs. distributed policy enforcement.** Centralised policy engine (single OPA instance evaluated for all agents) is easier to audit and update; single point of failure and potential latency bottleneck. Distributed enforcement (policy sidecar per agent) adds resilience and lower latency at the cost of policy synchronisation complexity. Hybrid: centralised authoring + distributed evaluation cache (Rego bundle served over HTTP) is the standard OPA production pattern.

**Audit log verbosity vs. cost.** Logging every agent action at full fidelity creates significant storage overhead for high-throughput agents. Tier the verbosity: Tier 0–1 actions (reversible, low-impact) at summary level; Tier 3–4 actions (high-impact, irreversible, regulated) at full fidelity including input parameters, agent state snapshot, and human decision record.

**Policy rigidity vs. operational flexibility.** Governance policies that are too strict block legitimate agent work and drive workarounds. Policies calibrated to the actual risk profile enable adoption. Review allow-lists quarterly and adjust based on observed agent behaviour — governance is a continuous process, not a one-time gate.

## State of the art

The **Microsoft Agent Governance Toolkit** (April 2026, MIT license, github.com/microsoft/agent-governance-toolkit) is the first open-source toolkit to address all 10 OWASP Agentic AI risks with deterministic enforcement. It ships seven components (Agent OS policy engine, Agent Mesh inter-agent trust, Agent Runtime execution rings, Agent SRE reliability) in Python, TypeScript, Rust, Go, and .NET, and integrates with LangChain, CrewAI, OpenAI Agents, AutoGen, and Google ADK.

Key capabilities: YAML/OPA/Cedar multi-language policy engine, DID-based cryptographic identity, Inter-Agent Trust Protocol (IATP), dynamic trust scoring, execution rings, saga orchestration for rollback, and an emergency kill switch. Sub-millisecond policy evaluation latency in benchmarks.

**OPA (Open Policy Agent, CNCF-graduated)** is the general-purpose policy engine of choice for teams that already use it for [[policy-as-code|infrastructure policy]] — the same Rego policies can gate agent tool calls, API gateway requests, and Kubernetes admission. Consistency across the stack reduces policy drift.

**OWASP Agentic AI Top 10** (December 2025) established the shared vocabulary for agent risk. It is the primary reference for communicating governance requirements to security teams and regulators unfamiliar with agentic architecture specifics.

EU AI Act enforcement from August 2026 is the primary compliance driver for formal agent governance adoption in regulated industries (finance, healthcare, public sector). Non-regulated industries are adopting governance frameworks proactively as agent-caused incidents (data leakage, runaway cost, erroneous transactions) accumulate.

## Pitfalls & anti-patterns

- **Prose-only governance.** A policy document that no runtime process enforces is not governance — it is aspiration. Policy-as-code is the minimum viable governance implementation.
- **No kill switch.** An agent that cannot be stopped mid-task without manual credential revocation is not safely governable. Build the kill switch before deployment, not after an incident.
- **Mutable audit logs.** Logs that can be modified after the fact are not audit trails — they are notes. Append-only with hash chaining is the technical minimum; managed write-once log services (AWS CloudTrail Lake, Azure Immutable Blob Storage) are the operational shortcut.
- **Allow-listing by role instead of task.** Granting an agent the "data-engineer" role (broad) instead of the specific tools for the current task (narrow). See [[agents-as-system-citizens]] for the full argument.
- **No escalation path in policy.** A policy that only says "no" without specifying the escalation path for legitimate exceptions forces workarounds. Include the exception request process in the policy-as-code (e.g., an OPA rule that logs the request and routes to an approval workflow).
- **Treating governance as a security team problem.** Agent governance touches security, platform, legal, and product. Siloed ownership creates policy gaps at the handoffs.

## See also

- [[agents-as-system-citizens]]
- [[agent-identity-and-access]]
- [[human-in-the-loop-design]]
- [[policy-as-code]]
- [[ai-governance-frameworks]]
- [[guardrails-and-output-validation]]
- [[zero-trust-architecture]]
- [[prompt-injection]]

## Sources

- Microsoft Agent Governance Toolkit GitHub (April 2026): https://github.com/microsoft/agent-governance-toolkit
- Microsoft Open Source Blog — Introducing the Agent Governance Toolkit: https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/
- Microsoft TechCommunity — Agent Governance Toolkit Architecture Deep Dive: https://techcommunity.microsoft.com/blog/linuxandopensourceblog/agent-governance-toolkit-architecture-deep-dive-policy-engines-trust-and-sre-for/4510105
- Digital Applied — AI Agent Governance Policy and Compliance 2026: https://www.digitalapplied.com/blog/ai-agent-governance-policy-compliance-2026
- Bigeye — What is AI Agent Governance: https://www.bigeye.com/blog/what-is-ai-agent-governance
- InfoWorld — Microsoft's Agent Governance Toolkit targets OWASP Agentic risks: https://www.infoworld.com/article/4155591/microsofts-new-agent-governance-toolkit-targets-top-owasp-risks-for-ai-agents.html
