---
title: Master Roadmap MOC
aliases: [roadmap, spine, master moc]
type: moc
domain: mixed
priority: ""
roadmap_ref: ""
status: seed
tags: [moc, roadmap]
updated: 2026-06-19
sources: ["skill-set/2026/technology-skills.md"]
---

# Master Roadmap MOC

> [!summary]
> The spine of this knowledge base. Mirrors the **[2026 Solution Architect Technology
> Skills Roadmap](../../skill-set/2026/technology-skills.md)**. Every roadmap node maps to
> a `[[wiki page]]`. Priorities: 🔴 P0 own it · 🟠 P1 solid · 🟡 P2 working · 🟢 P3 watch.

Navigate by tier: [[tier-1-edge]] · [[tier-2-solid]] · [[tier-3-watch]] · [[meta-skills]].

---

## TIER 1 — Where your edge is made

### §1 AI & Agentic Architecture 🔴
- [[agentic-system-design]] 🔴 — single vs. multi-agent, topologies, hand-offs *(§1.1)*
  - [[multi-agent-orchestration]] — sequential vs. parallel, planner-executor, hierarchical *(§1.1.1)*
  - [[agent-to-agent-protocols]] — decomposition, shared state, failure handling *(§1.1.2)*
  - [[human-in-the-loop-design]] — approval gates, "delegate, review, own" *(§1.1.3)*
- [[agents-as-system-citizens]] 🔴 — agents as first-class actors *(§1.2)*
  - [[agent-identity-and-access]] — RBAC/ABAC, quotas, least-privilege *(§1.2.1)*
  - [[agent-governance-and-policy]] — allow-lists, audit trails *(§1.2.2)*
- [[llm-application-architecture]] 🔴 — the LLM app stack *(§1.3)*
  - [[retrieval-augmented-generation]] 🔴 — chunking, vectors, hybrid search, re-ranking *(§1.3.1)*
  - [[context-engineering]] — window budgeting, compression *(§1.3.2)*
  - [[agent-memory-architectures]] — short/long/episodic memory *(§1.3.2.2)*
  - [[model-selection-and-routing]] — cost/latency/quality, fallback, tune-vs-prompt-vs-RAG *(§1.3.3)*
- [[model-context-protocol]] 🟠 — MCP & integration protocols *(§1.4)*
- [[ai-evaluation-and-quality]] 🟠 — eval pipelines, drift, hallucination *(§1.5)*
  - [[guardrails-and-output-validation]] — safety filters, validation *(§1.5.3)*

### §2 Cloud Architecture 🔴
- [[multi-cloud-architecture]] 🔴 — provider equivalency, lock-in judgment *(§2.1)*
- [[hybrid-and-onprem-topologies]] 🟠 — data gravity, edge *(§2.2)*
- [[cloud-native-patterns]] 🔴 *(§2.3)*
  - [[event-driven-architecture]] *(§2.3.1)*
  - [[serverless-architecture]] *(§2.3.2)*
  - [[kubernetes-at-design-level]] *(§2.3.3)*
- [[cloud-governance-at-scale]] 🟠 — landing zones, Well-Architected, guardrails *(§2.4)*

### §3 Security & Compliance 🔴
- [[zero-trust-architecture]] 🟠 *(§3.1.1)*
- [[iam-and-secrets-management]] 🟠 *(§3.1.2)*
- [[ai-specific-security]] 🔴 — prompt injection, exfiltration, agent permissions *(§3.2)*
  - [[prompt-injection]] 🔴 *(§3.2.1)*
  - [[model-supply-chain-security]] 🔴 *(§3.2.3)*
- [[compliance-and-regulation]] 🟠 — GDPR-as-design-input, regulated sectors *(§3.3)*
  - [[ai-governance-frameworks]] 🟢 *(§3.3.3)*

---

## TIER 2 — Must be genuinely solid

### §4 Platform Engineering & IaC 🟠
- [[infrastructure-as-code]] 🟠 — Terraform/OpenTofu, CDK, Pulumi *(§4.1)*
- [[ai-generated-iac-reviewer]] 🔴 — the "AI reviewer" problem *(§4.2)*
  - [[policy-as-code]] — OPA / Sentinel / Kyverno *(§4.2.3)*
- [[developer-experience]] 🟡 — golden paths, IDPs *(§4.3)*
- [[cicd-pipeline-architecture]] 🟠 — progressive delivery *(§4.4)*
  - [[software-supply-chain-security]] — SBOM, signing, attestation *(§4.4.2)*

### §5 Data Architecture 🟠
- [[data-storage-paradigms]] 🟠 — lakehouse vs. mesh vs. warehouse, OLTP/OLAP *(§5.1)*
- [[streaming-and-event-data]] 🟠 — Kafka/Kinesis/Pub-Sub *(§5.2)*
  - [[event-sourcing-and-cqrs]] *(§5.2.2)*
- [[data-governance-and-lineage]] 🟠 — catalogs, contracts, quality *(§5.3)*
- [[ai-data-fabric]] 🔴 *(§5.4)*
  - [[vector-and-embedding-stores]] *(§5.4.1)*
  - [[feature-stores]] *(§5.4.2)*

### §6 Integration & API Architecture 🟠
- [[api-styles-and-protocols]] 🟠 — REST/GraphQL/gRPC selection *(§6.1)*
- [[api-gateways-and-service-mesh]] 🟡 *(§6.2)*
- [[coupling-and-versioning-discipline]] 🟠 — loose coupling, contract testing *(§6.3)*

### §7 FinOps & Cost Architecture 🟠
- [[cloud-cost-modeling]] 🟠 — cost models alongside designs *(§7.1)*
- [[ai-gpu-economics]] 🔴 — inference cost, token economics, tiering *(§7.2)*
- [[cost-optimization-practice]] 🟡 — right-sizing, showback/chargeback *(§7.3)*

### §8 Observability & Reliability 🟠
- [[observability-fundamentals]] 🟠 — metrics/logs/traces, SLO/SLI *(§8.1)*
- [[distributed-systems-reliability]] 🟠 — failure modes, chaos, degradation *(§8.2)*
- [[ai-agent-observability]] 🔴 — tracing agents, non-deterministic failure *(§8.3)*

---

## TIER 3 — Keep an eye on 🟢

- [[vibe-coding-governance]] — non-deterministic generation as platform responsibility *(§9.1)*
- [[confidential-computing]] — privacy-enhancing tech *(§9.4)*
- [[wasm-at-the-edge]] *(§9.5)*
- [[post-quantum-cryptography]] *(§9.6)*
- [[green-software-architecture]] — sustainability *(§9.7)*
- *Also tracking (no page yet): dynamic/surge staffing models (§9.2), AI-architecture certifications (§9.3).*

---

## CROSS-CUTTING META-SKILLS (the real differentiator)

- [[systems-thinking-over-syntax]] 🔴 *(M.1)*
- [[trade-off-judgment]] 🔴 *(M.2)*
- [[delegate-review-own]] 🔴 *(M.3)*
- [[accountable-human-layer]] 🔴 *(M.4)*
- [[t-shaped-depth]] 🟠 *(M.5)*

---

## Suggested sequencing (next ~12 months)

1. **Q1 — Close the agentic gap:** [[agentic-system-design]] + [[model-context-protocol]].
2. **Q2 — Harden the AI surface:** [[ai-specific-security]] + [[ai-agent-observability]] + [[ai-generated-iac-reviewer]].
3. **Q3 — Refit the data fabric:** [[ai-data-fabric]] + [[ai-gpu-economics]].
4. **Q4 — Consolidate breadth:** [[multi-cloud-architecture]] + integration discipline; pick one Tier-3 item to track.
