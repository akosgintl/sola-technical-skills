---
title: Threat Modeling
aliases: [threat model, threat modelling, STRIDE, attack surface analysis, trust boundaries, secure-by-design]
type: concept
domain: security
status: mature
tags: [security, threat-modeling, stride, secure-by-design, risk, maestro, owasp]
updated: 2026-06-26
sources:
  - "https://shostack.org/resources/threat-modeling"
  - "https://owasp.org/www-community/Threat_Modeling_Process"
  - "https://www.threatmodelingmanifesto.org/"
  - "https://cloudsecurityalliance.org/blog/2025/02/06/agentic-ai-threat-modeling-framework-maestro"
  - "https://csrc.nist.gov/news/2025/nist-ai-100-2-adversarial-machine-learning-taxonom"
  - "https://www.iriusrisk.com/"
---

# Threat Modeling

> [!summary]
> Threat modeling is the design-time discipline of reasoning systematically about *how a
> system could be attacked* before it is built — answering Shostack's four questions: **what
> are we working on, what can go wrong, what are we going to do about it, and did we do a good
> enough job?** It turns "secure-by-design" from a slogan into a concrete, repeatable
> artifact: a model of the system's components, data flows, and **trust boundaries**, enriched
> with the threats that cross those boundaries and the controls that answer them. It is the
> single highest-leverage security activity an architect owns, because the cheapest place to
> remove a vulnerability is the whiteboard, not production.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Threat modeling is structured anticipation. Rather than wait for a pen test or an incident to
reveal weaknesses, you build a deliberate model of the system and interrogate it for failure
under adversarial pressure. The canonical formulation is **Adam Shostack's four questions**,
also adopted by the [Threat Modeling Manifesto](https://www.threatmodelingmanifesto.org/):

1. **What are we working on?** — Decompose the system. The usual artifact is a **data-flow
   diagram (DFD)**: processes, data stores, external entities, the flows between them, and —
   critically — the **trust boundaries** those flows cross (user↔app, app↔database,
   tenant↔tenant, your-code↔third-party, human↔agent).
2. **What can go wrong?** — Enumerate threats against each element and boundary, ideally with
   a mnemonic so coverage doesn't depend on the analyst's imagination.
3. **What are we going to do about it?** — Decide a response per threat: mitigate, eliminate,
   transfer, or accept. Each becomes a requirement, a control, or a logged risk acceptance.
4. **Did we do a good enough job?** — Review the model against the built system; threat
   modeling is iterative, not a one-time gate.

The defining move is **drawing trust boundaries**. A threat is interesting precisely where
data or control crosses from a less-trusted zone to a more-trusted one. This is the same
instinct as [[zero-trust-architecture]] and [[network-segmentation]], applied at design time
to the logical architecture rather than the network.

## Why it matters

Security has shifted "left" into the design phase, and threat modeling is the practice that
operationalizes it. Three reasons it sits with the architect, not only the AppSec team:

- **Economics.** Removing a design flaw on a diagram costs a conversation; removing it after
  it ships costs a re-architecture, an incident, or a breach. Threat modeling is where
  [[trade-off-judgment|security trade-offs]] are made explicit and cheap.
- **It catches *design* flaws, not *code* bugs.** SAST, DAST, and dependency scanners find
  implementation defects. They cannot tell you that an agent holding production credentials
  *should not also* read untrusted email — that is an architecture decision, and only a model
  of the system surfaces it. Roughly half of serious security defects are design flaws no
  scanner will ever find.
- **It produces a shared, auditable artifact.** The threat model is the bridge between
  architecture, security, and compliance: it documents *why* a control exists and which risks
  were knowingly accepted — exactly what regulators and [[compliance-and-regulation|auditors]]
  ask for.

For AI systems the stakes rose sharply: agents that plan and act expand the attack surface in
ways classic models don't anticipate, which is why dedicated AI threat-modeling frameworks
emerged (below). Threat modeling is the methodology; [[ai-specific-security]] is the catalog
of what goes wrong in that surface.

## Key concepts / building blocks

### STRIDE — the default threat taxonomy

Microsoft's **STRIDE** is the most widely used mnemonic. Applied per element (or per
interaction), it forces six questions against each component and flow:

| Letter | Threat | Violates | Typical control |
|---|---|---|---|
| **S** | Spoofing | Authentication | Strong identity, MFA, mutual TLS |
| **T** | Tampering | Integrity | Signing, hashes, input validation |
| **R** | Repudiation | Non-repudiation | Audit logs, immutable trails |
| **I** | Information disclosure | Confidentiality | Encryption, least privilege |
| **D** | Denial of service | Availability | Rate limits, quotas, autoscale |
| **E** | Elevation of privilege | Authorization | Least privilege, sandboxing |

STRIDE's strength is comprehensiveness without relying on intuition; its weakness is that
naïvely applied it generates a long, flat list. **STRIDE-per-element** scopes each threat type
to the elements it actually applies to, keeping the exercise tractable.

### Other methodologies (pick by goal)

- **PASTA** (Process for Attack Simulation and Threat Analysis) — a seven-stage,
  risk-and-business-impact-centric process. Heavier; suited to high-stakes systems where you
  need to tie threats to business risk and attacker motivation.
- **Attack trees** — model a single attacker goal as a tree of sub-goals/methods. Excellent
  for reasoning deeply about *one* critical asset (e.g. "exfiltrate the signing key").
- **LINDDUN** — the **privacy** analogue of STRIDE (Linkability, Identifiability,
  Non-repudiation, Detectability, Disclosure, Unawareness, Non-compliance). Reach for it when
  the dominant risk is personal data, not system compromise. Pairs with
  [[data-governance-and-lineage]] and [[compliance-and-regulation|GDPR]].
- **Attacker-centric / asset-centric / system-centric** are the three lenses; most teams
  start system-centric (the DFD) because it's the most repeatable.
- **DREAD** (a risk-*scoring* scheme) is largely **deprecated** — its ratings proved
  subjective and inconsistent; prefer a simple, documented likelihood×impact rubric or an
  organizational risk matrix.

### AI and agentic extensions

Classic frameworks assume deterministic software logic and fall short on systems that reason
and act. Two AI-native additions now sit *alongside* STRIDE rather than replacing it:

- **MAESTRO** (Multi-Agent Environment, Security, Threat, Risk & Outcome) — the Cloud Security
  Alliance's layered framework (Feb 2025) for agentic AI. Its seven-layer model spans the
  foundation model, data operations, agent frameworks, deployment infrastructure,
  evaluation/observability, the security stack, and the agent **ecosystem** — explicitly
  surfacing threats legacy methods miss: goal misalignment, memory poisoning, malicious
  agent collusion, and cross-layer attacks. Use it to threat-model [[agentic-system-design|
  multi-agent systems]] and [[agent-to-agent-protocols|A2A protocols]].
- **NIST AI 100-2e2025** — the authoritative *catalog* of adversarial ML attacks (evasion,
  poisoning, prompt injection, extraction). It supplies the "what can go wrong" content for an
  AI threat model the way a vulnerability database supplies a classic one. See
  [[model-supply-chain-security]] and [[ai-governance-frameworks]].

For agentic designs, a fast heuristic complements the formal model: count the legs of the
**lethal trifecta** (untrusted input + private data + exfiltration channel) — see
[[ai-specific-security]] and [[prompt-injection]].

### Where it lives in the lifecycle

Threat modeling is most valuable as a **continuous** activity, not a one-time milestone:
embedded in design reviews, re-run when the architecture materially changes, and — at the
mature end — expressed as **threat-model-as-code** that lives beside the system definition and
diffs in pull requests. It is a natural fit with [[spec-driven-development|spec-driven design]]
(the threat model is part of the spec) and feeds requirements into
[[cicd-pipeline-architecture|CI/CD]] and [[guardrails-and-output-validation|runtime controls]].

## Design decisions & trade-offs

- **Depth vs. cadence.** A deep PASTA analysis of every service is unaffordable and goes
  stale. The senior call is to **threat-model the trust boundaries that matter most** —
  authentication, money movement, PII, agent tool access — at design time, and keep a
  lightweight, repeatable STRIDE pass for everything else. Coverage beats ceremony.
- **Who holds the pen.** Security-led threat modeling produces better models but doesn't
  scale and breeds dependence; **developer/architect-led** modeling (security as coach and
  reviewer) scales and builds ownership but needs enablement and guardrails. Most mature orgs
  converge on the latter with security curating the threat library and reviewing high-risk
  models.
- **Workshop vs. tooling vs. as-code.** Whiteboard workshops maximize insight and shared
  understanding but aren't durable; tools (IriusRisk/ThreatModeler, OWASP Threat Dragon)
  give consistency and a question-driven library; **threat-model-as-code** (Threagile,
  STRIDE-GPT pipelines) makes the model versionable and CI-gateable at the cost of
  expressiveness. Match the mechanism to how the team already works.
- **How much to trust AI-generated models.** LLM-assisted threat suggestion is now mainstream
  and a real accelerant — but a generated model is a *first draft*. It will miss
  business-context threats and invent plausible-but-irrelevant ones. This is the
  [[delegate-review-own|delegate-review-own]] pattern applied to security: let the model
  draft, but the architect owns the trust-boundary judgment and the risk decisions.
- **Mitigate / eliminate / transfer / accept — and *document the acceptances*.** The output
  that matters most is often the *risk you chose to accept*, recorded with a rationale and an
  owner. An undocumented acceptance is indistinguishable from a missed threat.

## State of the art

- **AI-assisted threat modeling went mainstream.** Most commercial tools now ship LLM-based
  threat suggestion as a standard feature (e.g. Microsoft's Threat Modeling Tool added
  AI-assisted detection), and open tools like **STRIDE-GPT** wrap GPT models around the STRIDE
  method. The pattern is draft-by-AI, review-by-human — not autonomous threat modeling.
- **Market consolidation.** ThreatModeler's acquisition of **IriusRisk** (Jan 2026, $100M+)
  merged the two leading enterprise platforms, signaling that automated, lifecycle-embedded
  threat modeling has become an expected enterprise capability rather than a specialist
  boutique practice.
- **Open-source stalwarts** remain the stable, no-license-cost picks: **OWASP Threat Dragon**
  (DFD + STRIDE), **Threagile** (YAML threat-model-as-code, well-suited to AI wrapping), and
  **CAIRIS**.
- **AI-native frameworks proliferating.** Beyond MAESTRO, variants such as **STRIFE** extend
  STRIDE for AI-specific threats; expect continued churn here while the discipline settles.
- **Convergence with secure-by-design mandates.** CISA's "Secure by Design" pledge and
  EU/sectoral regulation increasingly *expect* a documented threat model, pulling the practice
  from optional to baseline for regulated systems. See [[compliance-and-regulation]].

## Pitfalls & anti-patterns

- **Boil-the-ocean modeling.** Trying to enumerate every threat against every component
  produces an unread 200-row spreadsheet. Scope to the boundaries that carry real risk.
- **One-and-done.** A threat model produced once at kickoff and never revisited is stale the
  moment the architecture changes. It must be living, ideally versioned with the design.
- **The diagram *is* the deliverable.** A beautiful DFD with no enumerated threats, decisions,
  or owners is documentation theater. The value is in the *answers*, not the picture.
- **Confusing threat modeling with pen testing or scanning.** They are complementary: modeling
  finds *design* flaws early; testing finds *implementation* flaws late. One does not replace
  the other.
- **DREAD-style subjective scoring** dressed up as rigor. Inconsistent ratings erode trust in
  the whole exercise; use a documented, comparable rubric.
- **Applying only classic frameworks to AI systems.** STRIDE alone won't surface goal
  misalignment, memory poisoning, or multi-agent collusion — pair it with MAESTRO / NIST AI
  100-2 for agentic designs.
- **No risk-acceptance trail.** Accepting risk silently means you can't defend the decision
  later and can't distinguish it from negligence.

## See also

- [[ai-specific-security]]
- [[prompt-injection]]
- [[model-supply-chain-security]]
- [[zero-trust-architecture]]
- [[network-segmentation]]
- [[ai-governance-frameworks]]
- [[compliance-and-regulation]]
- [[guardrails-and-output-validation]]
- [[trade-off-judgment]]

## Sources

- [Adam Shostack — Threat Modeling resources & the Four Questions](https://shostack.org/resources/threat-modeling)
- [Threat Modeling Manifesto](https://www.threatmodelingmanifesto.org/)
- [OWASP — Threat Modeling Process](https://owasp.org/www-community/Threat_Modeling_Process)
- [Cloud Security Alliance — Agentic AI Threat Modeling Framework: MAESTRO (Feb 2025)](https://cloudsecurityalliance.org/blog/2025/02/06/agentic-ai-threat-modeling-framework-maestro)
- [NIST AI 100-2e2025 — Adversarial Machine Learning: A Taxonomy and Terminology](https://csrc.nist.gov/news/2025/nist-ai-100-2-adversarial-machine-learning-taxonom)
- [IriusRisk — AI threat modeling platform](https://www.iriusrisk.com/) (and ThreatModeler acquisition, Jan 2026)
- [ThreatModeler acquires IriusRisk (PR, Jan 2026)](https://threatmodeler.com/press-release/threatmodeler-acquires-iriusrisk-to-build-seamless-security-for-enterprises-in-the-ai-coding-era/)
- [OWASP Threat Dragon](https://owasp.org/www-project-threat-dragon/) · [Threagile (threat-model-as-code)](https://threagile.io/) · [STRIDE-GPT](https://github.com/mrwadams/stride-gpt)
