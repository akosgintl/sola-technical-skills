---
title: "spec-compare — Research Comparing 6 Spec-Driven Development Tools"
aliases: [spec-compare, SDD tool comparison]
type: source
domain: emerging
status: seed
tags: [source, emerging, spec-driven-development, tooling, comparison, git-worktrees]
updated: 2026-06-25
source_url: https://github.com/cameronsjo/spec-compare
source_type: docs
ingested: 2026-06-25
feeds: [spec-driven-development-tools, git-worktrees-parallel-agents, spec-driven-development]
---

# spec-compare (Cameron S. Jo)

> [!info] Source metadata
> **Author:** Cameron S. Jo (cameronsjo) · **URL:** https://github.com/cameronsjo/spec-compare · Compares Spec-Kit, Spec Kitty, BMad, OpenSpec, Kiro, Tessl.

## Key takeaways

- **Tool roster (with versions at time of writing):**
  | Tool | License | Maturity | Differentiator |
  |---|---|---|---|
  | Spec-Kit | OSS | Production (v0.8.18) | Greenfield, constitution-driven; **no worktree support** |
  | Spec Kitty | OSS | Active (v3.1.9) | **Built-in git worktree orchestration**; pioneered worktree automation |
  | BMad Method | OSS | Stable (v6.8.0) | Enterprise framework, **21 specialized AI agents** |
  | OpenSpec | MIT | Production (v1.3.1) | **Brownfield delta format** (ADDED/MODIFIED/REMOVED); lightweight |
  | Kiro | Proprietary | GA (v0.12.x, since Nov 2025) | AWS-backed agentic IDE; native IDE; no worktree support |
  | Tessl | Proprietary | Active | **Spec-as-Source** platform; edit-and-regenerate |

- **The modification problem:** most tools excel at upfront requirements but struggle with iterative change. OpenSpec (delta management) and Tessl (spec regeneration) directly address this gap.
- **Maturity hierarchy (matches Piskala taxonomy):**
  1. **Spec-First** — specs precede code but are discarded (Spec-Kit, Kiro, BMad)
  2. **Spec-Anchored** — specs persist and evolve (OpenSpec, Spec Kitty)
  3. **Spec-as-Source** — only specs edited, code auto-generates (Tessl)

## Notable claims (with location)

- Git worktree leaders: Spec Kitty (per-feature worktree, parallel isolation, auto cleanup), plus Superpowers (skills-framework worktrees) and Conductor (macOS parallel agent runner). Gap: Spec-Kit, BMad, Kiro, Tessl lack native worktree support.
- Decision framework: parallel features → Spec Kitty; brownfield small changes → OpenSpec; enterprise → BMad; greenfield → Spec-Kit; IDE experience → Kiro; spec-as-source regeneration → Tessl.

## Feeds these wiki pages

- [[spec-driven-development-tools]]
- [[git-worktrees-parallel-agents]]
- [[spec-driven-development]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
