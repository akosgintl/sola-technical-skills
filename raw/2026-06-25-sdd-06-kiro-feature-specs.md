---
title: "Kiro — Feature Specs (requirements.md / design.md / tasks.md)"
aliases: [Kiro feature specs, Kiro specs]
type: source
domain: emerging
status: seed
tags: [source, emerging, spec-driven-development, ears, kiro, tooling]
updated: 2026-06-25
source_url: https://kiro.dev/docs/specs/feature-specs/
source_type: docs
ingested: 2026-06-25
feeds: [ears-notation, spec-driven-development-tools, spec-driven-development]
---

# Kiro — Feature Specs

> [!info] Source metadata
> **Org:** Kiro (AWS) · **URL:** https://kiro.dev/docs/specs/feature-specs/

## Key takeaways

- Kiro organizes each feature into a **three-file spec**:
  1. **requirements.md** — system behavior in **EARS notation** (`WHEN [event] THE SYSTEM SHALL [behavior]`)
  2. **design.md** — technical architecture and implementation considerations
  3. **tasks.md** — discrete implementation tasks for progress tracking
- EARS rationale (Kiro docs): requirements are "unambiguous and easy to understand," can be "directly translated into test cases," and tracked "through implementation."
- Two workflow variants: **Requirements-First** (behavior → design → tasks) and **Design-First** (architecture/pseudocode → requirements → tasks).
- An **analysis phase** checks requirements for inconsistencies, ambiguities, conflicting constraints, and gaps before design.

## Notable claims (with location)

- Benefits: automatic documentation, cross-task progress tracking, shared artifacts for team alignment — aimed at complex, collaborative, iterative features.

## Feeds these wiki pages

- [[ears-notation]]
- [[spec-driven-development-tools]]
- [[spec-driven-development]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
