---
title: Master Roadmap MOC
aliases: [roadmap, spine, master moc]
type: moc
domain: mixed
status: seed
tags: [moc, roadmap]
updated: 2026-06-19
sources: ["skill-set/2026/technology-skills.md"]
---

# Master Roadmap MOC

> [!summary]
> The spine of this knowledge base. Mirrors the **[skills roadmap](../skill-set/2026/technology-skills.md)**.
> Every roadmap node maps to a `[[wiki page]]`.

Navigate by tier: [[tier-1-edge]] · [[tier-2-solid]] · [[tier-3-watch]] · [[meta-skills]].

---

## TIER 1 — Where your edge is made

### AI & Agentic Architecture
- [[agentic-system-design]] — single vs. multi-agent, topologies, hand-offs
  - [[multi-agent-orchestration]] — sequential vs. parallel, planner-executor, hierarchical
  - [[agent-to-agent-protocols]] — decomposition, shared state, failure handling
  - [[human-in-the-loop-design]] — approval gates, "delegate, review, own"
- [[agents-as-system-citizens]] — agents as first-class actors
  - [[agent-identity-and-access]] — RBAC/ABAC, quotas, least-privilege
  - [[agent-governance-and-policy]] — allow-lists, audit trails
- [[llm-application-architecture]] — the LLM app stack
  - [[retrieval-augmented-generation]] — chunking, vectors, hybrid search, re-ranking
  - [[context-engineering]] — window budgeting, compression
  - [[agent-memory-architectures]] — short/long/episodic memory
  - [[model-selection-and-routing]] — cost/latency/quality, fallback, tune-vs-prompt-vs-RAG
- [[model-context-protocol]] — MCP & integration protocols
- [[ai-evaluation-and-quality]] — eval pipelines, drift, hallucination
  - [[guardrails-and-output-validation]] — safety filters, validation

### Cloud Architecture
- [[multi-cloud-architecture]] — provider equivalency, lock-in judgment
- [[hybrid-and-onprem-topologies]] — data gravity, edge
- [[cloud-native-patterns]]
  - [[event-driven-architecture]]
  - [[serverless-architecture]]
  - [[kubernetes-at-design-level]]
- [[cloud-governance-at-scale]] — landing zones, Well-Architected, guardrails

### Security & Compliance
- [[zero-trust-architecture]]
- [[iam-and-secrets-management]]
- [[ai-specific-security]] — prompt injection, exfiltration, agent permissions
  - [[prompt-injection]]
  - [[model-supply-chain-security]]
- [[compliance-and-regulation]] — GDPR-as-design-input, regulated sectors
  - [[ai-governance-frameworks]]

---

## TIER 2 — Must be genuinely solid

### Platform Engineering & IaC
- [[infrastructure-as-code]] — Terraform/OpenTofu, CDK, Pulumi
- [[ai-generated-iac-reviewer]] — the "AI reviewer" problem
  - [[policy-as-code]] — OPA / Sentinel / Kyverno
- [[developer-experience]] — golden paths, IDPs
- [[cicd-pipeline-architecture]] — progressive delivery
  - [[software-supply-chain-security]] — SBOM, signing, attestation

### Data Architecture
- [[data-storage-paradigms]] — lakehouse vs. mesh vs. warehouse, OLTP/OLAP
- [[streaming-and-event-data]] — Kafka/Kinesis/Pub-Sub
  - [[event-sourcing-and-cqrs]]
- [[data-governance-and-lineage]] — catalogs, contracts, quality
- [[ai-data-fabric]]
  - [[vector-and-embedding-stores]]
  - [[feature-stores]]

### Integration & API Architecture
- [[api-styles-and-protocols]] — REST/GraphQL/gRPC selection
- [[api-gateways-and-service-mesh]]
- [[coupling-and-versioning-discipline]] — loose coupling, contract testing

### FinOps & Cost Architecture
- [[cloud-cost-modeling]] — cost models alongside designs
- [[ai-gpu-economics]] — inference cost, token economics, tiering
- [[cost-optimization-practice]] — right-sizing, showback/chargeback

### Observability & Reliability
- [[observability-fundamentals]] — metrics/logs/traces, SLO/SLI
- [[distributed-systems-reliability]] — failure modes, chaos, degradation
- [[ai-agent-observability]] — tracing agents, non-deterministic failure

---

## TIER 3 — Keep an eye on

- [[vibe-coding-governance]] — non-deterministic generation as platform responsibility
- [[confidential-computing]] — privacy-enhancing tech
- [[wasm-at-the-edge]]
- [[post-quantum-cryptography]]
- [[green-software-architecture]] — sustainability
- *Also tracking (no page yet): dynamic/surge staffing models, AI-architecture certifications.*

---

## CROSS-CUTTING META-SKILLS (the real differentiator)

- [[systems-thinking-over-syntax]]
- [[trade-off-judgment]]
- [[delegate-review-own]]
- [[accountable-human-layer]]
- [[t-shaped-depth]]

---

## Suggested sequencing (next ~12 months)

1. **Close the agentic gap:** [[agentic-system-design]] + [[model-context-protocol]].
2. **Harden the AI surface:** [[ai-specific-security]] + [[ai-agent-observability]] + [[ai-generated-iac-reviewer]].
3. **Refit the data fabric:** [[ai-data-fabric]] + [[ai-gpu-economics]].
4. **Consolidate breadth:** [[multi-cloud-architecture]] + integration discipline; pick one Tier-3 item to track.
