---
title: "OpenSpec, Git Worktrees and OpenCode — Parallel AI Agent Workflow"
aliases: [openspec worktrees, parallel agents worktrees]
type: source
domain: emerging
status: seed
tags: [source, emerging, git-worktrees, parallel-agents, openspec, spec-driven-development]
updated: 2026-06-25
source_url: https://intent-driven.dev/blog/2026/04/01/openspec-git-worktrees-opencode/
source_type: article
ingested: 2026-06-25
feeds: [git-worktrees-parallel-agents, spec-driven-development-tools]
---

# OpenSpec + Git Worktrees + OpenCode

> [!info] Source metadata
> **Org:** intent-driven.dev · **Date:** 2026-04-01 · **URL:** https://intent-driven.dev/blog/2026/04/01/openspec-git-worktrees-opencode/

## Key takeaways

- **Three-phase parallel workflow:**
  1. **Propose on main** (`/opsx:propose`) — analyze changes against authoritative specs on main so the proposal sees *all* in-flight work and detects conflicts/gaps.
  2. **Implement in worktrees** — each sub-agent gets a spec-backed proposal and works in an **isolated worktree branch**, sharing the same git object store.
  3. **Merge → Archive (in that order, every time)** — merge to main, then archive to sync delta specs back into the source-of-truth specs.
- **Why worktrees:** multiple branches checked out simultaneously in separate directories with independent working states; shared object store eliminates duplication while enabling genuine parallel development.
- **Coordination via specs:** proposals created on main are the coordination mechanism; Verify-within-worktree confirms the implementation matches the proposal's spec/design/tasks before merge.

## Notable claims (with location)

- Pitfall: "If you propose from a worktree branch, OpenSpec only sees that branch's delta — it loses visibility into other in-flight changes" and the main specs.
- Pitfall: archiving before merging creates spec-merge conflicts; incorrect sequencing undermines the whole workflow.

## Feeds these wiki pages

- [[git-worktrees-parallel-agents]]
- [[spec-driven-development-tools]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
