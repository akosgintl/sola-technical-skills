---
title: "Spec-Driven Development (spec-driven.md) — the Spec Kit methodology essay"
aliases: [spec-driven.md, spec-kit constitution, nine articles, SDD power inversion]
type: source
domain: emerging
status: seed
tags: [source, emerging, spec-driven-development, methodology, constitution, github]
updated: 2026-06-25
source_url: https://github.com/github/spec-kit/blob/main/spec-driven.md
source_type: docs
ingested: 2026-06-25
feeds: [spec-driven-development]
---

# Spec-Driven Development — the Spec Kit methodology essay

> [!info] Source metadata
> **Org:** GitHub (open source) · **Doc:** `spec-driven.md` in github/spec-kit · **URL:** https://github.com/github/spec-kit/blob/main/spec-driven.md

The canonical long-form essay that states the *methodology* behind [[spec-driven-development-tools|Spec Kit]] (the [[2026-06-25-sdd-03-github-spec-kit|repo/tool itself]] is captured separately). Its distinctive contribution over the general SDD literature is the **constitutional framework** — nine numbered architectural articles that constrain how generated systems may be structured — and the "power inversion" framing.

## Key takeaways

- **The Power Inversion.** Traditional development treats code as sovereign and specs as subordinate guidance. SDD inverts this: *"Specifications don't serve code — code serves specifications."* The spec is the primary artifact; code is its expression in a particular language/framework, generated and regenerable from the spec.
- **Executable specifications.** Specs must be "precise, complete, and unambiguous enough to generate working systems," closing the historic intent→implementation gap.
- **Continuous refinement, not one-time gates.** Consistency validation happens continuously as the spec evolves, rather than as a single sign-off.
- **Three core commands:** `/specify` (feature description → structured spec, with repo + feature-numbering automation), `/plan` (business requirements → technical architecture/stack/contracts), `/tasks` (plan → ordered, parallelism-marked, actionable task list).

## The nine constitutional articles (the signature content)

A set of immutable principles governing every generated system. Articles IV–VI are deliberately left for each project to fill in (integration testing, observability, versioning, breaking changes), keeping the nine-article skeleton stable:

- **Article I — Library-First.** *"Every feature in Specify MUST begin its existence as a standalone library."* No feature is built directly into the application; it starts as a self-contained, independently testable library.
- **Article II — CLI Interface Mandate.** All library functionality is exposed through a command-line interface: text in, text out, with JSON for structured data. Forces observable, composable, scriptable units.
- **Article III — Test-First Imperative.** *"No implementation code shall be written before: (1) unit tests are written, (2) tests are validated and approved by the user, (3) tests are confirmed to FAIL."* Strict red-green TDD as a non-negotiable.
- **Articles IV, V & VI — Project-Defined Governance.** Intentionally blank slots for each project to define (e.g. integration-test policy, observability, versioning, breaking-change rules) while preserving the nine-article structure.
- **Article VII — Simplicity.** Maximum **3 projects** for initial implementation; more requires documented justification. Avoid speculative future-proofing.
- **Article VIII — Anti-Abstraction.** Use framework features **directly** rather than wrapping them behind your own abstraction layers; maintain a single model representation rather than parallel DTO/domain mirrors.
- **Article IX — Integration-First Testing.** Prefer realistic environments — real databases over mocks, actual service instances over stubs — so tests exercise real contracts.

> The articles encode an opinionated architectural style (library-first, CLI-observable, TDD-mandatory, deliberately simple, anti-over-engineering). This is *separate* from the security-oriented "Constitutional SDD" paper (Marri, arXiv:2602.02584); both put a versioned constitution upstream of generation, but Spec Kit's articles target architecture/quality, not CWE/regulatory constraints.

## Why SDD matters now

Three convergent trends:

1. **AI capability threshold** — natural-language specs now reliably generate working code.
2. **Exponential complexity** — systems integrating dozens of services need systematic, specification-driven alignment.
3. **Accelerated change** — rapid pivots make spec-driven *regeneration* more practical than manual rewrites, turning requirement changes from obstacles into normal workflow.

## Feeds these wiki pages

- [[spec-driven-development]] — the constitutional-articles subsection and the "power inversion" framing

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
