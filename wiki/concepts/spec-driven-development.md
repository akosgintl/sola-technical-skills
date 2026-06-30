---
title: Spec-Driven Development
aliases: [SDD, spec-driven development, spec-first development, spec-as-source]
type: concept
domain: emerging
status: mature
tags: [emerging, ai, spec-driven-development, requirements, ai-coding, methodology]
updated: 2026-06-25
sources:
  - https://arxiv.org/abs/2602.00180
  - https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering
  - https://github.com/github/spec-kit
  - https://github.com/github/spec-kit/blob/main/spec-driven.md
  - https://www.ibm.com/think/topics/spec-driven-development
  - https://www.itential.com/resource/guide/spec-driven-development/
  - https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development/three-levels-of-sdd
  - https://arxiv.org/abs/2605.02455
  - https://www.augmentcode.com/guides/what-is-spec-driven-development
  - https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
  - https://arxiv.org/abs/2602.02584
  - https://brooker.co.za/blog/2026/04/09/waterfall-vs-spec.html
  - https://www.epam.com/insights/ai/blogs/ai-trends-in-software-development
  - raw/2026-06-25-ssd01-01-research-report.md
  - raw/2026-06-25-ssd01-02-research-report.md
  - raw/2026-06-25-ssd01-03-research-report.md
  - raw/2026-06-25-ssd01-04-research-report.md
---

# Spec-Driven Development

> [!summary]
> Spec-Driven Development (SDD) inverts the conventional AI-coding workflow: instead of prompting an assistant and reconciling the output afterward, a team writes a structured, durable **specification** first and treats it as the source of truth from which code is generated, validated, and regenerated. The spec — not the code — becomes the artifact under version control that humans review and argue about. SDD is the disciplined antidote to "vibe coding": it moves the human judgment upstream, to the contract, where ambiguity is cheap to fix.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

Spec-Driven Development is a methodology, popularized in 2025–2026 as AI coding assistants became capable of generating large amounts of code from natural-language intent. Deepak Babu Piskala's framing paper (arXiv:2602.00180) puts it precisely: SDD "inverts the traditional workflow by treating specifications as the source of truth." Code becomes a *generated or verified secondary product* — the title's "from code to contract" captures the shift in which artifact carries the authority.

The motivating problem is **translation loss**. Software intent degrades at every handoff: stakeholder → requirements → design → implementation. Each step paraphrases the last and loses fidelity. AI assistants accelerate every step but, as Microsoft's engineering blog puts it, "AI can accelerate those steps, but it cannot correct ambiguity that was never resolved." A fast assistant pointed at an ambiguous prompt produces ambiguous code faster. SDD's response is to resolve ambiguity *once*, upstream, in a durable spec, and then let the assistant execute against a clear contract.

A typical SDD pipeline (canonically the [[spec-driven-development-tools|GitHub Spec Kit]] lifecycle) is a chain of durable artifacts, each reviewed before the next:

```
Constitution → Specify → Clarify → Plan → Tasks → Implement → Validate
 (principles)  (what)   (resolve)  (how)  (units)   (code)    (verify)
```

![[2026-06-25-sdd-02-microsoft-spec-first-01.webp|GitHub Spec Kit engineering lifecycle: Constitution, Specify, Clarify, Plan, Tasks, Implement, Validate]]
*Figure: The GitHub Spec Kit engineering lifecycle — seven sequential, reviewed stages — source [[2026-06-25-sdd-02-microsoft-spec-first]].*

- **Constitution** — the project's non-negotiable principles (quality bars, testing standards, architectural rules) that govern every later decision.
- **Specify** — functional requirements and user stories: the *what*, deliberately excluding the *how*.
- **Clarify** — structured questioning that surfaces and resolves ambiguity before any planning.
- **Plan** — the technical *how*: architecture, stack, API contracts, data models.
- **Tasks** — an ordered, dependency-aware breakdown with explicit file paths and parallelism markers.
- **Implement / Validate** — the assistant executes tasks; output is checked against the spec.

The human spends their attention on the constitution, spec, and plan; the assistant does the mechanical translation to code. This is the [[delegate-review-own|delegate / review / own]] discipline applied at the level of the whole feature rather than the individual completion.

### Origins and lineage

SDD crystallized across 2025 without a single inventor; several threads converged. Sean Grove (OpenAI), in his "The New Code" talk at the 2025 AI Engineer World's Fair, supplied the sharpest framing: developers keep generated code and throw the prompt away, which is "like shredding the source and version-controlling the binary" — so the durable, versioned *specification* should be the real artifact. Thoughtworks Distinguished Engineer Birgitta Böckeler then gave the field its working vocabulary in an October 2025 analysis (on martinfowler.com), naming the spec-first / spec-anchored / spec-as-source ladder. Andrej Karpathy — who coined "[[vibe-coding-governance|vibe coding]]" in February 2025 — reframed the professional practice by 2026 as **agentic engineering**: orchestrating fallible, stochastic agents against detailed, human-authored specs, with diff review, eval design, and security oversight as the core skills.

The idea is older than the term. SDD is, as practitioner Bryan Finster put it, "not a revolution… it's just BDD with branding" — the branding's value is the reminder that specs should be *authoritative, not advisory*. Its roots run through [[ears-notation|requirements engineering]], Design by Contract (Meyer, 1992), model-driven engineering, specification by example / behavior-driven development (Given/When/Then), consumer-driven contracts, and contract-first API description (OpenAPI, Protobuf, AsyncAPI). What changed in 2025 is the executor: LLMs collapsed the cost of authoring and maintaining specs and supplied an agent that can actually turn a rich spec into working code — making spec-first viable at modern velocity, and making spec-as-source newly plausible.

## Why it matters

**It fixes the failure mode of [[vibe-coding-governance|vibe coding]].** Vibe coding — accepting AI output without reading every line, using tests and observed behavior as the feedback signal — is fast but transfers all quality risk downstream to review and runtime. SDD keeps the velocity but relocates the human checkpoint to the spec, where a misunderstanding costs a sentence to fix rather than a refactor. The two are not opposites so much as the same velocity with the control point in a different place.

**Specs are the right context for agents.** An AI agent given a precise spec, a plan, and a task list has dramatically less room to drift than one given a paragraph of prose. The spec is simultaneously the prompt, the acceptance criteria, the test oracle, and the documentation. This is [[context-engineering]] formalized into a repeatable artifact rather than re-improvised per session.

**"Spec quality = output quality."** This is SDD's central trade-off, stated by both Microsoft and the practitioner literature. SDD does not remove the hard thinking; it *front-loads* it. The reward is that downstream rework drops; the cost is that a vague or wrong spec now produces wrong code with full confidence and at full speed. SDD makes specification skill — long a neglected discipline — load-bearing again.

**Repository-scale generation becomes tractable.** The SSDE research (arXiv:2605.02455) observes that LLMs excel at function-level generation but "degrade significantly at repository scale," and argues that structured specifications as inputs "make high-quality, repository-level code generation a tangible goal." Structure buys verifiability that free-form prompting cannot.

## Key concepts / building blocks

### The three levels of SDD

The most useful mental model — coined by Böckeler (Thoughtworks, October 2025) and echoed in Piskala's paper, Panaversity's "three levels," and the [[spec-driven-development-tools|spec-compare]] research — is a **maturity ladder** defined by how much authority the spec holds over the code:

| Level | Spec's role | Code's role | What persists | Example tooling |
|---|---|---|---|---|
| **Spec-First** | Written before code, then discarded | The deliverable | Code only | Spec Kit, Kiro, BMad |
| **Spec-Anchored** | Persists and evolves alongside code | The deliverable, kept in sync | Spec + code | OpenSpec, Spec Kitty |
| **Spec-as-Source** | The *only* artifact humans edit | Regenerated output, like a compiler target | Spec only | Tessl |

The ladder is also a statement of ambition. **Spec-first** treats the spec as scaffolding — useful to align before coding, then thrown away (and prone to staleness). **Spec-anchored** keeps the spec living, the way good API docs or ADRs stay current. **Spec-as-source** is the radical end: code is treated like compiled output you never hand-edit, and all change happens in the spec — analogous to how nobody edits assembly emitted by a compiler. Most teams in 2026 operate at spec-first or spec-anchored; spec-as-source remains aspirational and tooling-dependent.

### Requirements notation: EARS

A spec is only as good as its requirements are unambiguous. The dominant convention for writing testable requirements in SDD is [[ears-notation|EARS]] (Easy Approach to Requirements Syntax) — constrained-natural-language templates like `WHEN <trigger> the system SHALL <response>`. Kiro generates its `requirements.md` in EARS specifically because EARS requirements "can be directly translated into test cases." EARS is the bridge between human-readable intent and machine-checkable acceptance criteria.

### The brownfield / modification problem

SDD is easy to demonstrate on greenfield ("0-to-1") work and much harder on existing systems. The hard part is *change*: how do you express "modify this behavior" against a large existing spec without rewriting it? OpenSpec's answer is a **delta format** (`ADDED` / `MODIFIED` / `REMOVED`) that captures only the change; Tessl's answer is to regenerate from an edited spec. The modification problem is the main thing separating toy SDD demos from production adoption.

### Relationship to BDD and contract-first

SDD did not appear from nowhere. It is the AI-era descendant of **behavior-driven development** (Given/When/Then scenarios as executable specs), **contract-first** API design (OpenAPI/Protobuf as the authoritative interface), and formal **requirements engineering**. What is new is the executor: an LLM agent capable of turning a rich spec into a working implementation, which makes the spec-as-source ambition newly plausible. API-first development is SDD's most mature beachhead: Postman's 2025 survey reports 82% of organizations have adopted some level of API-first (up from 74% in 2024 and 66% in 2023), which means spec-first thinking is already standard operating procedure at the interface layer even where the broader methodology is new.

### The constitutional framework: Spec Kit's nine articles

The constitution layer is not just "write down your principles." [[spec-driven-development-tools|Spec Kit]]'s methodology essay (`spec-driven.md`) ships an opinionated, numbered **constitution of nine articles** — immutable architectural rules every generated system must obey. They encode a deliberate style: small, observable, test-first, and aggressively un-clever.

| Article | Rule | What it forces |
|---|---|---|
| **I — Library-First** | "Every feature MUST begin its existence as a standalone library." | No feature welded directly into the app; each starts self-contained and independently testable. |
| **II — CLI Interface** | Expose all library functionality via a CLI: text in, text out, JSON for structured data. | Observable, composable, scriptable units. |
| **III — Test-First** | No implementation before tests are written, user-approved, and confirmed to **FAIL**. | Strict red-green TDD as a non-negotiable. |
| **IV–VI — Project-Defined** | Intentionally blank slots (integration testing, observability, versioning, breaking changes). | Each project fills these in without breaking the nine-article skeleton. |
| **VII — Simplicity** | Max **3 projects** initially; more needs documented justification. Avoid future-proofing. | Kills speculative architecture up front. |
| **VIII — Anti-Abstraction** | Use frameworks **directly**; don't wrap them. Keep a single model representation. | No parallel DTO/domain mirrors, no homemade abstraction layers. |
| **IX — Integration-First** | Real databases over mocks, real service instances over stubs. | Tests exercise real contracts, not fakes. |

This is the embodiment of the essay's **"power inversion"**: *"specifications don't serve code — code serves specifications."* The articles are how the methodology keeps generated code from sprawling — the LLM is powerful enough to over-engineer convincingly, so the constitution pins it to a simple, testable shape *by construction*. Note this is a distinct sense of "constitution" from the security framing below: Spec Kit's articles govern **architecture and quality**; Constitutional SDD (next) governs **security and compliance**. Both share the move of putting a versioned, machine-readable constitution upstream of generation.

### Constitutional SDD: security by construction

A notable 2026 extension (Marri, arXiv:2602.02584) embeds non-negotiable security principles into the **constitution** layer so that AI-generated code satisfies them *by construction rather than by inspection*. The constitution becomes a versioned, machine-readable document encoding constraints derived from CWE / MITRE Top 25 and regulatory frameworks, with enforcement levels stated in RFC 2119 semantics (MUST / SHOULD / MAY). The reported case study found constitutional constraints cut security defects by ~73% versus unconstrained generation with no significant velocity loss — a "shift-left" of security into the spec. For regulated domains (fintech, healthcare, automotive) this closes the gap between "the agent wrote it" and "we can prove it complies." See [[ai-specific-security]] and [[guardrails-and-output-validation]]. *(The 73% figure is a single case study, not a controlled result — see the evidence caveat below.)*

### The living specification

The spec-anchored level depends on the **living specification** — a spec versioned alongside code and kept honest by CI. **Spec drift** (divergence between written spec and actual behavior) is the failure mode it exists to prevent; the standard mitigation is enforcing spec validation in CI/CD (contract tests with Pact/Specmatic, property-based tests) so drift fails the build immediately rather than surfacing at a quarterly review. A spec that gates nothing decays into stale documentation.

## Design decisions & trade-offs

**When SDD earns its overhead.** Piskala's paper is explicit that SDD's "utility varies by domain and project characteristics" — it is not a universal default. The ceremony pays off when: the feature is non-trivial and long-lived; multiple people (or multiple [[multi-agent-orchestration|agents]]) must stay aligned; correctness and auditability matter (regulated, enterprise, embedded). It is overkill for a throwaway script or a one-line fix — applying full Spec Kit there is, as the tooling literature puts it, "a sledgehammer to crack a nut."

**Upfront cost vs. downstream rework.** SDD trades more time before the first line of code for less time fixing drift afterward. On short horizons, vibe coding wins on raw speed; on long horizons with real maintenance, the spec amortizes. The break-even depends on how long the code lives and how many hands touch it.

**Over-specification is a real failure mode.** Microsoft's guidance — "treat specs as living documents, avoid over-specification" — warns against the opposite extreme: a spec so detailed it becomes a second implementation to maintain, with all the cost of code and none of the executability. The spec should pin down *intent and contracts*, not pre-write the code in prose.

**Spec-first vs. spec-anchored as an organizational choice.** Spec-first is cheaper to adopt (no sync discipline) but the specs rot the moment code diverges, destroying their value as documentation. Spec-anchored demands the discipline to update the spec on every change — the same discipline that keeps ADRs and API docs honest, and the same place most teams fail. Choosing the level is really choosing how much sync discipline the team will sustain.

**"Is this just waterfall?"** The most persistent criticism is that writing specs up front is a return to waterfall. AWS principal engineer Marc Brooker's rebuttal is the cleanest: SDD "isn't about pulling designs *up-front*, it's about pulling designs *up*" — making specs explicit, versioned, living artifacts from which implementation flows, while the iteration cycle stays Agile (hours, not quarters) and the artifact being iterated is the spec rather than the code. The criticism lands, though, when SDD is applied rigidly: Thoughtworks' Technology Radar rates SDD **"Assess," not "Adopt,"** explicitly warning against "a bias toward heavy up-front specification and big-bang releases." The defensible position is that SDD is iterative spec-then-generate, not frozen design — but only if the team actually keeps specs lean and the loop tight.

## State of the art

As of mid-2026 the SDD tooling landscape has consolidated around a handful of approaches — covered in depth in [[spec-driven-development-tools]]:

- **[[spec-driven-development-tools|GitHub Spec Kit]]** — the open-source reference implementation; seven-phase slash-command workflow; supports 30+ agents (Claude Code, Copilot, Cursor, Gemini, Codex).
- **Kiro** (AWS) — GA since November 2025; spec-first agentic IDE built around the EARS `requirements.md` / `design.md` / `tasks.md` triple.
- **Spec Kitty** — open source; pioneered **[[git-worktrees-parallel-agents|git-worktree]]** orchestration so multiple agents implement different specs in parallel, isolated working trees.
- **OpenSpec** — brownfield-focused, delta-based, lightweight.
- **Tessl** — the commercial bet on full **spec-as-source** (edit the spec, regenerate the code).
- **BMad Method** — enterprise framework with ~21 specialized agents for heavyweight workflows.

The academic side is nascent but active: Piskala's framing paper (arXiv:2602.00180) supplies the taxonomy and decision framework; SSDE (arXiv:2605.02455) tackles repository-level generation from structured specs. Both are positioning/pilot work rather than large empirical evaluations — the field is still defining its terms.

**Adoption is real; the efficacy evidence is thin and contested.** The demand driver is clear: ~84% of developers use or plan to use AI tools (Stack Overflow 2025), yet trust in AI accuracy *fell* from 40% (2024) to 29% (2025), and the top frustration is "AI solutions that are almost right, but not quite" — precisely SDD's target. EPAM's 2026 trends piece predicts SDD will "dominate brownfield engineering," where legacy systems lack explicit intent. Vendor and case-study numbers are encouraging but not controlled: a financial-services OpenAPI case in the SDD paper reports a 75% cut in API integration cycle time; AWS reports large gains from Kiro at Delta Air Lines and Rackspace. Against this sit credible skeptics: Scott Logic's hands-on review found the reviewer "around ten times faster *without* SDD" on small tasks, and Marmelab ("The Waterfall Strikes Back") documented Spec Kit ballooning a trivial date-display feature into 8 files and ~1,300 lines of markdown. The honest summary: SDD's payoff is well-argued and directionally supported for complex, long-lived, multi-team, or regulated work, but controlled efficacy data specific to SDD barely exists — treat the headline percentages as illustrative, not proof.

> [!tip]
> A pragmatic adoption path (Microsoft's recommendation): pilot SDD on **one** misaligned, painful feature rather than mandating it everywhere. Keep the spec living (spec-anchored), write requirements in [[ears-notation|EARS]] so they double as test cases, and expand only where the value is obvious. Don't apply the full ceremony to throwaway work.

## Pitfalls & anti-patterns

- **Treating the spec as a one-time gate.** A spec written, approved, then never updated as the code evolves becomes actively misleading — worse than no spec, because it is trusted. Spec-first degrades into this by default; spec-anchored requires real discipline to avoid it.
- **Over-specification.** Writing the implementation in prose inside the spec doubles the maintenance burden and gains nothing. Specify intent and contracts; let the plan and code hold the *how*.
- **Vague specs at full speed.** SDD amplifies whatever you feed it. An ambiguous spec now yields confidently wrong code, fast. "Spec quality = output quality" is not a slogan; it is the load-bearing risk.
- **Applying SDD universally.** Full SDD ceremony on trivial or exploratory work is pure overhead. Match the rigor level (spec-first / anchored / as-source) to the stakes.
- **Skipping the clarify step.** The phase that resolves ambiguity *before* planning is the one most often dropped under time pressure — and it is precisely where SDD's value is created. Skipping it reduces SDD back to dressed-up vibe coding.
- **Review overload ("markdown madness").** Tools can emit thousands of lines of spec/plan markdown for a modest feature, and "double code review" (reviewing both the spec *and* the generated code) can cost more than it saves. If review time doubles without fewer defects, you are over-specifying — pull back to the minimum that removes ambiguity.
- **No human accountability for the spec.** The spec is now the contract; an unreviewed or auto-generated spec that no human owns reintroduces, at the contract level, exactly the risk SDD was meant to remove. See [[accountable-human-layer]].
- **Forgetting LLM non-determinism.** The same spec can generate materially different code across runs, which can make diffs noisy and regressions hard to track. This is the unsolved core risk at the spec-as-source level; property-based testing (verifying invariants regardless of implementation) partially mitigates it.

## See also

- [[spec-driven-development-tools]] — the tool landscape: Spec Kit, Kiro, Spec Kitty, OpenSpec, Tessl, BMad
- [[ears-notation]] — the requirements syntax that makes specs testable
- [[git-worktrees-parallel-agents]] — running multiple spec-driven agents in parallel
- [[vibe-coding-governance]] — the failure mode SDD is the disciplined answer to
- [[context-engineering]] — the spec as durable, structured agent context
- [[delegate-review-own]] — the human discipline SDD scales to the feature level
- [[accountable-human-layer]] — who owns the contract
- [[ai-specific-security]] — where Constitutional SDD enforces security-by-construction
- [[guardrails-and-output-validation]] — runtime checks that complement spec validation
- [[developer-experience]] — SDD as a platform-level developer workflow

## Sources

- Piskala, D. B. (2026). *Spec-Driven Development: From Code to Contract in the Age of AI Coding Assistants.* arXiv:2602.00180. https://arxiv.org/abs/2602.00180
- Microsoft (2026). *Spec-Driven Development: A Spec-First Approach to AI-Native Engineering.* https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering
- GitHub (2026). *Spec Kit — Toolkit for Spec-Driven Development.* https://github.com/github/spec-kit
- GitHub (2026). *Spec-Driven Development* (`spec-driven.md` — the methodology essay, incl. the nine constitutional articles & "power inversion"). https://github.com/github/spec-kit/blob/main/spec-driven.md · captured: [[2026-06-25-sdd-09-spec-kit-constitution]]
- IBM (2026). *What is Spec-Driven Development?* https://www.ibm.com/think/topics/spec-driven-development
- Itential (2026). *Spec-Driven Development (SDD) — Fundamentals & Definitions.* https://www.itential.com/resource/guide/spec-driven-development/
- Panaversity (2026). *The Three Levels of SDD.* https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development/three-levels-of-sdd
- *LLM-Assisted Repository-Level Generation with Structured Spec-Driven Engineering (SSDE).* arXiv:2605.02455. https://arxiv.org/abs/2605.02455
- Augment Code (2026). *What Is Spec-Driven Development? A Complete Guide.* https://www.augmentcode.com/guides/what-is-spec-driven-development
- Böckeler, B. (2025). *Understanding Spec-Driven Development: Kiro, spec-kit, and Tessl.* martinfowler.com. https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- Marri, S. R. (2026). *Constitutional Spec-Driven Development: Enforcing Security by Construction in AI-Assisted Code Generation.* arXiv:2602.02584. https://arxiv.org/abs/2602.02584
- Brooker, M. (2026). *Spec Driven Development isn't Waterfall.* https://brooker.co.za/blog/2026/04/09/waterfall-vs-spec.html
- EPAM (2026). *7 AI trends redefining software development workflows in 2026.* https://www.epam.com/insights/ai/blogs/ai-trends-in-software-development
- Research syntheses (ingested 2026-06-25): [[2026-06-25-ssd01-01-research-report]], [[2026-06-25-ssd01-02-research-report]], [[2026-06-25-ssd01-03-research-report]], [[2026-06-25-ssd01-04-research-report]]
