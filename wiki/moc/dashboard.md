---
title: Dashboard — What to Read / Ingest Next
aliases: [dashboard, read next, ingest next, backlog]
type: moc
domain: mixed
priority: ""
roadmap_ref: ""
status: seed
tags: [moc, dashboard]
updated: 2026-06-19
sources: []
---

# Dashboard — What to Read / Ingest Next

> [!summary]
> A live, priority-ranked view of the wiki by maturity. Use it to pick the
> **highest-leverage** next move: the `🔴 P0` pages still at `stub` are where ingesting a
> source buys the most. Run `pwsh scripts/lint.ps1` for health; this page is for *priority*.

← Back to [[index]] · [[00-roadmap]] · Tiers: [[tier-1-edge]] · [[tier-2-solid]] · [[tier-3-watch]] · [[meta-skills]]

## Live view (Obsidian Bases)

The embed below renders dynamic, always-current tables from page frontmatter (P0 stubs to
ingest, P1 stubs, mature pages, everything by status). Requires the **Bases** core plugin
(already enabled). If a column looks off, adjust it in the Bases UI — the data is live.

![[dashboard.base]]

> [!note] Outside Obsidian
> Bases (and the embed above) only render in Obsidian. On GitHub or a plain viewer, use the
> static backlog below — keep it roughly in sync, but treat `index.md` as the source of truth.

---

## Static backlog (P0 stubs — the deep-work queue)

These are the 🔴 **P0** pages still at `stub`, grouped by domain. Promoting any of them
(`stub → draft` via an [ingest](../../CLAUDE.md)) is high-value.

**AI & Agentic** — [[multi-agent-orchestration]] · [[agent-to-agent-protocols]] · [[human-in-the-loop-design]] · [[agents-as-system-citizens]] · [[agent-identity-and-access]] · [[agent-governance-and-policy]] · [[llm-application-architecture]] · [[context-engineering]] · [[agent-memory-architectures]] · [[model-selection-and-routing]]

**Cloud** — [[multi-cloud-architecture]] · [[cloud-native-patterns]] · [[event-driven-architecture]] · [[serverless-architecture]] · [[kubernetes-at-design-level]]

**Security** — [[prompt-injection]] · [[model-supply-chain-security]]

**Platform / Data / FinOps** — [[policy-as-code]] · [[ai-data-fabric]] · [[vector-and-embedding-stores]] · [[feature-stores]] · [[ai-gpu-economics]]

**Meta-skills** — [[systems-thinking-over-syntax]] · [[trade-off-judgment]] · [[delegate-review-own]] · [[accountable-human-layer]]

## Recommended Q1 starting set

Per the roadmap's sequencing ([[00-roadmap]] → "Close the agentic gap"), and because the
agentic anchor pages are already `mature`, ingest into the agentic cluster first:

1. [[multi-agent-orchestration]] — extends the mature [[agentic-system-design]].
2. [[agent-to-agent-protocols]] — pairs with [[model-context-protocol]] (mature).
3. [[context-engineering]] + [[agent-memory-architectures]] — feed [[retrieval-augmented-generation]] (mature).

## Mature pages (already trusted)

[[agentic-system-design]] · [[retrieval-augmented-generation]] · [[model-context-protocol]] · [[ai-specific-security]] · [[ai-generated-iac-reviewer]] · [[ai-agent-observability]]
