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
  - https://www.ibm.com/think/topics/spec-driven-development
  - https://www.itential.com/resource/guide/spec-driven-development/
  - https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development/three-levels-of-sdd
  - https://arxiv.org/abs/2605.02455
  - https://www.augmentcode.com/guides/what-is-spec-driven-development
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

- **Constitution** — the project's non-negotiable principles (quality bars, testing standards, architectural rules) that govern every later decision.
- **Specify** — functional requirements and user stories: the *what*, deliberately excluding the *how*.
- **Clarify** — structured questioning that surfaces and resolves ambiguity before any planning.
- **Plan** — the technical *how*: architecture, stack, API contracts, data models.
- **Tasks** — an ordered, dependency-aware breakdown with explicit file paths and parallelism markers.
- **Implement / Validate** — the assistant executes tasks; output is checked against the spec.

The human spends their attention on the constitution, spec, and plan; the assistant does the mechanical translation to code. This is the [[delegate-review-own|delegate / review / own]] discipline applied at the level of the whole feature rather than the individual completion.

## Why it matters

**It fixes the failure mode of [[vibe-coding-governance|vibe coding]].** Vibe coding — accepting AI output without reading every line, using tests and observed behavior as the feedback signal — is fast but transfers all quality risk downstream to review and runtime. SDD keeps the velocity but relocates the human checkpoint to the spec, where a misunderstanding costs a sentence to fix rather than a refactor. The two are not opposites so much as the same velocity with the control point in a different place.

**Specs are the right context for agents.** An AI agent given a precise spec, a plan, and a task list has dramatically less room to drift than one given a paragraph of prose. The spec is simultaneously the prompt, the acceptance criteria, the test oracle, and the documentation. This is [[context-engineering]] formalized into a repeatable artifact rather than re-improvised per session.

**"Spec quality = output quality."** This is SDD's central trade-off, stated by both Microsoft and the practitioner literature. SDD does not remove the hard thinking; it *front-loads* it. The reward is that downstream rework drops; the cost is that a vague or wrong spec now produces wrong code with full confidence and at full speed. SDD makes specification skill — long a neglected discipline — load-bearing again.

**Repository-scale generation becomes tractable.** The SSDE research (arXiv:2605.02455) observes that LLMs excel at function-level generation but "degrade significantly at repository scale," and argues that structured specifications as inputs "make high-quality, repository-level code generation a tangible goal." Structure buys verifiability that free-form prompting cannot.

## Key concepts / building blocks

### The three levels of SDD

The most useful mental model — appearing independently in Piskala's paper, Panaversity's "three levels," and the [[spec-driven-development-tools|spec-compare]] research — is a **maturity ladder** defined by how much authority the spec holds over the code:

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

SDD did not appear from nowhere. It is the AI-era descendant of **behavior-driven development** (Given/When/Then scenarios as executable specs), **contract-first** API design (OpenAPI/Protobuf as the authoritative interface), and formal **requirements engineering**. What is new is the executor: an LLM agent capable of turning a rich spec into a working implementation, which makes the spec-as-source ambition newly plausible.

## Design decisions & trade-offs

**When SDD earns its overhead.** Piskala's paper is explicit that SDD's "utility varies by domain and project characteristics" — it is not a universal default. The ceremony pays off when: the feature is non-trivial and long-lived; multiple people (or multiple [[multi-agent-orchestration|agents]]) must stay aligned; correctness and auditability matter (regulated, enterprise, embedded). It is overkill for a throwaway script or a one-line fix — applying full Spec Kit there is, as the tooling literature puts it, "a sledgehammer to crack a nut."

**Upfront cost vs. downstream rework.** SDD trades more time before the first line of code for less time fixing drift afterward. On short horizons, vibe coding wins on raw speed; on long horizons with real maintenance, the spec amortizes. The break-even depends on how long the code lives and how many hands touch it.

**Over-specification is a real failure mode.** Microsoft's guidance — "treat specs as living documents, avoid over-specification" — warns against the opposite extreme: a spec so detailed it becomes a second implementation to maintain, with all the cost of code and none of the executability. The spec should pin down *intent and contracts*, not pre-write the code in prose.

**Spec-first vs. spec-anchored as an organizational choice.** Spec-first is cheaper to adopt (no sync discipline) but the specs rot the moment code diverges, destroying their value as documentation. Spec-anchored demands the discipline to update the spec on every change — the same discipline that keeps ADRs and API docs honest, and the same place most teams fail. Choosing the level is really choosing how much sync discipline the team will sustain.

## State of the art

As of mid-2026 the SDD tooling landscape has consolidated around a handful of approaches — covered in depth in [[spec-driven-development-tools]]:

- **[[spec-driven-development-tools|GitHub Spec Kit]]** — the open-source reference implementation; seven-phase slash-command workflow; supports 30+ agents (Claude Code, Copilot, Cursor, Gemini, Codex).
- **Kiro** (AWS) — GA since November 2025; spec-first agentic IDE built around the EARS `requirements.md` / `design.md` / `tasks.md` triple.
- **Spec Kitty** — open source; pioneered **[[git-worktrees-parallel-agents|git-worktree]]** orchestration so multiple agents implement different specs in parallel, isolated working trees.
- **OpenSpec** — brownfield-focused, delta-based, lightweight.
- **Tessl** — the commercial bet on full **spec-as-source** (edit the spec, regenerate the code).
- **BMad Method** — enterprise framework with ~21 specialized agents for heavyweight workflows.

The academic side is nascent but active: Piskala's framing paper (arXiv:2602.00180) supplies the taxonomy and decision framework; SSDE (arXiv:2605.02455) tackles repository-level generation from structured specs. Both are positioning/pilot work rather than large empirical evaluations — the field is still defining its terms.

> [!tip]
> A pragmatic adoption path (Microsoft's recommendation): pilot SDD on **one** misaligned, painful feature rather than mandating it everywhere. Keep the spec living (spec-anchored), write requirements in [[ears-notation|EARS]] so they double as test cases, and expand only where the value is obvious. Don't apply the full ceremony to throwaway work.

## Pitfalls & anti-patterns

- **Treating the spec as a one-time gate.** A spec written, approved, then never updated as the code evolves becomes actively misleading — worse than no spec, because it is trusted. Spec-first degrades into this by default; spec-anchored requires real discipline to avoid it.
- **Over-specification.** Writing the implementation in prose inside the spec doubles the maintenance burden and gains nothing. Specify intent and contracts; let the plan and code hold the *how*.
- **Vague specs at full speed.** SDD amplifies whatever you feed it. An ambiguous spec now yields confidently wrong code, fast. "Spec quality = output quality" is not a slogan; it is the load-bearing risk.
- **Applying SDD universally.** Full SDD ceremony on trivial or exploratory work is pure overhead. Match the rigor level (spec-first / anchored / as-source) to the stakes.
- **Skipping the clarify step.** The phase that resolves ambiguity *before* planning is the one most often dropped under time pressure — and it is precisely where SDD's value is created. Skipping it reduces SDD back to dressed-up vibe coding.
- **No human accountability for the spec.** The spec is now the contract; an unreviewed or auto-generated spec that no human owns reintroduces, at the contract level, exactly the risk SDD was meant to remove. See [[accountable-human-layer]].

## See also

- [[spec-driven-development-tools]] — the tool landscape: Spec Kit, Kiro, Spec Kitty, OpenSpec, Tessl, BMad
- [[ears-notation]] — the requirements syntax that makes specs testable
- [[git-worktrees-parallel-agents]] — running multiple spec-driven agents in parallel
- [[vibe-coding-governance]] — the failure mode SDD is the disciplined answer to
- [[context-engineering]] — the spec as durable, structured agent context
- [[delegate-review-own]] — the human discipline SDD scales to the feature level
- [[accountable-human-layer]] — who owns the contract
- [[developer-experience]] — SDD as a platform-level developer workflow

## Sources

- Piskala, D. B. (2026). *Spec-Driven Development: From Code to Contract in the Age of AI Coding Assistants.* arXiv:2602.00180. https://arxiv.org/abs/2602.00180
- Microsoft (2026). *Spec-Driven Development: A Spec-First Approach to AI-Native Engineering.* https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering
- GitHub (2026). *Spec Kit — Toolkit for Spec-Driven Development.* https://github.com/github/spec-kit
- IBM (2026). *What is Spec-Driven Development?* https://www.ibm.com/think/topics/spec-driven-development
- Itential (2026). *Spec-Driven Development (SDD) — Fundamentals & Definitions.* https://www.itential.com/resource/guide/spec-driven-development/
- Panaversity (2026). *The Three Levels of SDD.* https://agentfactory.panaversity.org/docs/General-Agents-Foundations/spec-driven-development/three-levels-of-sdd
- *LLM-Assisted Repository-Level Generation with Structured Spec-Driven Engineering (SSDE).* arXiv:2605.02455. https://arxiv.org/abs/2605.02455
- Augment Code (2026). *What Is Spec-Driven Development? A Complete Guide.* https://www.augmentcode.com/guides/what-is-spec-driven-development
