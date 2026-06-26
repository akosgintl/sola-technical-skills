---
title: Architecture Decision Records
aliases: [ADR, ADRs, architecture decision record, architectural decision record, MADR, decision log, ADL]
type: concept
domain: meta
status: mature
tags: [meta, adr, decisions, documentation, docs-as-code, architecture]
updated: 2026-06-26
sources:
  - "https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions"
  - "https://adr.github.io/"
  - "https://adr.github.io/madr/"
  - "https://github.com/thomvaill/log4brains"
  - "https://www.techtarget.com/searchapparchitecture/tip/4-best-practices-for-creating-architecture-decision-records"
---

# Architecture Decision Records

> [!summary]
> An Architecture Decision Record (ADR) is a short, version-controlled document that captures
> **one architecturally-significant decision** — the context that forced it, the options
> considered, the choice made, and the consequences accepted — stored as docs-as-code beside
> the code it governs. ADRs are the cheapest high-leverage documentation an architecture team
> keeps: they turn decisions from tribal memory into transferable reasoning, so the next person
> (or the same person in a year) understands *why* a thing is the way it is and knows when to
> revisit it. The real value is the **forcing function** — writing the context and alternatives
> *before* deciding routinely surfaces a better option. They are the artifact that records the
> [[trade-off-judgment|trade-off reasoning]]; this page is the practice, that page is the judgment.

**Domain:** [[meta-skills|Meta-Skills]]

## What it is

An ADR documents a single decision that is *architecturally significant* — one that is costly
to reverse, affects multiple teams or components, or shapes a quality attribute (security,
scalability, cost, compliance). Trivial or easily-reversed choices don't warrant one; the
[[trade-off-judgment#Calibrating analysis to stakes|calibration of effort to stakes]] is itself
a judgment.

The canonical format is **Michael Nygard's** (2011), five sections:

1. **Title** — a short, imperative statement of the decision (e.g. "Use Kafka for the event bus").
2. **Status** — `proposed` → `accepted` → `deprecated` / `superseded by ADR-NNN`.
3. **Context** — the forces at play: the situation, constraints, and requirements that make a
   decision necessary. No solution yet — just the problem.
4. **Decision** — what was chosen, stated plainly.
5. **Consequences** — what becomes easier, what becomes harder, and what is now at risk.

ADRs form an **append-only log**: an accepted record is **immutable**. When a decision changes,
you write a *new* ADR that supersedes the old one (and mark the old one `superseded`) rather than
editing history. The collection — the **Architecture Decision Log (ADL)** — is the project's
decision memory. The convention is to store them in-repo under `docs/adr/` or `docs/decisions/`,
numbered (`0001-…md`), so they version and review alongside the code they describe.

## Why it matters

- **Institutional memory survives turnover.** Teams without a decision log repeatedly re-make
  (or accidentally reverse) settled decisions because the reasoning left with the person. A
  maintained ADL lets the next architect see the constraints that still apply.
- **The forcing function improves the decision itself.** Articulating context and alternatives
  *before* committing is where a better option often appears. An ADR written after the fact is
  rationalization; an ADR written to decide is a design tool.
- **Faster onboarding, fewer re-litigations.** New engineers read *why*, not just *what*; design
  reviews stop re-opening closed questions.
- **The human accountability record over AI output.** As agents and [[vibe-coding-governance|
  generated code]] produce first-pass implementations, the ADR is the **human-authored** record
  of the consequential decision and its rationale — the documentary side of the
  [[accountable-human-layer|accountable-human layer]] and the [[delegate-review-own|delegate,
  review, own]] model. The model can draft the options; the human owns the context and the call.

## Key concepts / building blocks

### The alternatives section is the point

Beyond Nygard's five sections, the single highest-value addition is **the options considered and
why each was rejected**: "We considered X, Y, Z; X failed on A; Y was eliminated by B." This is
what converts a *record of a decision* into a *transferable argument*. Without it, an ADR is
authority-based ("the architect chose Kafka"); with it, it's reasoning-based ("chose Kafka
because replay + multi-consumer fan-out ruled out SQS"). Nygard's minimal format leaves
alternatives implicit — most teams add it explicitly (MADR makes it first-class).

### Templates — pick the lightest that captures alternatives

| Template | Character | Use when |
|---|---|---|
| **Nygard (classic)** | Minimal: Context / Decision / Consequences | Default; lowest friction |
| **MADR** (Markdown ADR) | Structured decision *drivers*, *considered options*, per-option pros/cons | You want the alternatives and drivers explicit and tool-supported |
| **Y-statements** | One-sentence form ("In context C, facing concern F, we chose O to achieve Q, accepting downside D") | Lightweight inline decisions |
| **ISO/IEC/IEEE 42010-inspired** | Formal, traceable to requirements | Regulated / large-org settings |

MADR is the de-facto richer standard (and the default shipped by Log4brains); Y-statements suit
decisions too small for a full record but worth a line.

### Status lifecycle and immutability

`proposed` (under review, often via an RFC/PR) → `accepted` (in force) → `deprecated` (no longer
recommended) or `superseded by ADR-NNN` (replaced). **Never rewrite an accepted ADR** — supersede
it. The log's value is that it shows how thinking *evolved*, including the decisions you later
reversed and why.

### Docs-as-code and tooling

ADRs are plain Markdown in version control — reviewable in pull requests, diffable, and in sync
with the code. Tooling layers on top:

- **adr-tools / dotnet-adr** — CLI scaffolding for new, numbered records (multi-template).
- **Log4brains** — docs-as-code ADR manager that publishes the ADL as a searchable static site.
- **MADR project** — templates + tooling for the richer format.
- **adr.github.io** — the community home, template gallery, and tooling index.

### One decision per record

An ADR covers one decision and its immediate dependencies — not a bundle. Combining several
choices into one document makes each impossible to supersede independently and buries the
reasoning. This mirrors the wiki's own "one concept per file" discipline.

## Design decisions & trade-offs

- **In-repo docs-as-code vs. wiki/Confluence.** In-repo wins for the systems an architect owns:
  the records version with the code, review in the same PR, and don't drift. A separate wiki
  decouples decisions from the code and rots. Use a wiki only for org-level decisions with no
  single repo home.
- **Lightweight vs. heavyweight template.** Heavier templates (MADR, 42010) capture more but
  raise the friction that kills adoption. Adopt the **lightest template that still forces the
  alternatives**, and let teams extend it — a used Nygard ADR beats an unused MADR one.
- **Write-to-decide vs. write-to-record.** The forcing-function value only exists if the ADR is
  written *as part of deciding*. Post-hoc ADRs still provide memory but lose the chance to change
  the outcome. Wire ADR authoring into the design/RFC step, not the cleanup step.
- **Effort calibrated to reversibility.** Not every choice needs one. A two-way-door decision
  goes in the PR description; a one-way door gets a full ADR with alternatives and sign-off. The
  axis is reversibility — see [[trade-off-judgment#Reversibility as the primary axis]].
- **AI-drafted ADRs.** LLMs are good at generating the *options* and a first-draft structure and
  bad at the *weighing* (which needs team, system-history, and regulatory context not in the
  prompt). Let the model draft; the architect supplies context and owns the decision and the
  consequences. Same split as [[delegate-review-own]].

## State of the art

- **Docs-as-code is the default**: numbered Markdown ADRs under `docs/adr/`, reviewed in PRs.
- **MADR + Log4brains** are the prevailing richer-template and publishing stack; `adr.github.io`
  consolidates templates and tooling.
- **AI-assisted ADR authoring** is emerging — LLM-assisted templates that draft context/options
  and reduce the documentation burden, keeping the human as decider. Pairs with the broader move
  to [[spec-driven-development|spec-driven development]], where the ADL sits beside the spec as
  the *why* behind the *what*.
- **ADRs as governance evidence**: in regulated and agentic settings, the decision log is
  increasingly the audit trail for *who decided what and why* — including decisions to accept
  risks surfaced by [[threat-modeling]].

## Pitfalls & anti-patterns

- **Post-hoc rationalization.** ADRs written after implementation record the decision but skip the
  forcing function — and tend to claim only upsides.
- **No alternatives section.** The most common defect: a decision with no rejected options is
  authority, not reasoning, and can't be re-evaluated.
- **Editing accepted ADRs.** Rewriting history destroys the log's value. Supersede, don't edit.
- **Bundling decisions.** Multiple choices per record makes each un-supersedable and the reasoning
  unfindable. One decision per ADR.
- **The ADR graveyard.** A `docs/adr/` folder written once and never referenced or maintained.
  ADRs must be linked from reviews and revisited when assumptions break.
- **Wrong scope.** An ADR for a logging-library choice (over-documentation) or *no* ADR for a data
  model that will hold billions of rows (under-documentation). Calibrate to reversibility.
- **Stored away from the code.** Decisions in a disconnected wiki drift out of sync with reality.

## See also

- [[trade-off-judgment]]
- [[systems-thinking-over-syntax]]
- [[delegate-review-own]]
- [[accountable-human-layer]]
- [[spec-driven-development]]
- [[vibe-coding-governance]]
- [[threat-modeling]]

## Sources

- [Nygard, M. (2011). Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
- [adr.github.io — Architectural Decision Records (templates, tooling, examples)](https://adr.github.io/)
- [MADR — Markdown Architectural Decision Records](https://adr.github.io/madr/)
- [Log4brains — docs-as-code ADR management & publishing](https://github.com/thomvaill/log4brains)
- [TechTarget — Best practices for creating architecture decision records](https://www.techtarget.com/searchapparchitecture/tip/4-best-practices-for-creating-architecture-decision-records)
