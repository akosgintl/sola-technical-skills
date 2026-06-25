---
title: "GitHub Spec Kit — Toolkit for Spec-Driven Development"
aliases: [Spec Kit, speckit, github spec-kit]
type: source
domain: emerging
status: seed
tags: [source, emerging, spec-driven-development, tooling, github]
updated: 2026-06-25
source_url: https://github.com/github/spec-kit
source_type: docs
ingested: 2026-06-25
feeds: [spec-driven-development, spec-driven-development-tools]
---

# GitHub Spec Kit

> [!info] Source metadata
> **Org:** GitHub (open source) · **URL:** https://github.com/github/spec-kit

## Key takeaways

- Open-source toolkit for SDD where "specifications become executable" — they drive implementation rather than serve as discardable scaffolding.
- **Seven-phase slash-command workflow:**
  1. `/speckit.constitution` — project principles, governance, non-negotiables (`.specify/memory/constitution.md`)
  2. `/speckit.specify` — functional requirements + user stories (the *what*, not the *how*) → `specs/<feature-id>/spec.md`
  3. `/speckit.clarify` — resolve ambiguities via structured questioning before planning
  4. `/speckit.plan` — technical architecture, tech stack, API contracts, data models → `plan.md`
  5. `/speckit.tasks` — ordered, dependency-sequenced tasks with parallel markers `[P]` and exact file paths → `tasks.md`
  6. `/speckit.analyze` — validate consistency across spec/plan/tasks (optional)
  7. `/speckit.implement` — execute tasks systematically
- Extra commands: `/speckit.taskstoissues` (→ GitHub Issues), `/speckit.converge` (assess codebase vs. artifacts), `/speckit.checklist`.
- Supports **30+ AI agents**: Claude Code, GitHub Copilot, Cursor, Gemini CLI, Codex CLI, Qwen, Tabnine, Kiro, etc.
- Customization: Extensions (new commands), Presets (templates/terminology), Bundles (role-based setups). Resolution order: project-local → presets → extensions → core.

## Notable claims (with location)

- Artifact hierarchy: **constitution → spec → plan → tasks**, each a distinct durable file under version control.
- Supports greenfield (0-to-1), creative exploration across stacks, and brownfield enhancement.

## Feeds these wiki pages

- [[spec-driven-development]]
- [[spec-driven-development-tools]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
