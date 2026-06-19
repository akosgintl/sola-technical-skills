---
title: Dashboard — What to Read / Ingest Next
aliases: [dashboard, read next, ingest next, backlog]
type: moc
domain: mixed
status: seed
tags: [moc, dashboard]
updated: 2026-06-19
sources: []
---

# Dashboard — What to Read / Ingest Next

> [!summary]
> A live view of the wiki by maturity. Use it to pick the next move: the `stub` pages are the
> ingest backlog; `mature` pages are trusted. Run `pwsh scripts/lint.ps1` for health; this
> page is for *navigation*.

← Back to [[index]] · [[00-roadmap]] · Tiers: [[tier-1-edge]] · [[tier-2-solid]] · [[tier-3-watch]] · [[meta-skills]]

## Live view (Obsidian Bases)

The embed below renders dynamic, always-current tables from page frontmatter (stub backlog by
domain, in-progress, mature, and everything by status). Requires the **Bases** core plugin
(already enabled). If a column looks off, adjust it in the Bases UI — the data is live.

![[dashboard.base]]

> [!note] Outside Obsidian
> Bases (and the embed above) only render in Obsidian. On GitHub or a plain viewer, use
> [[index]] for the full page-by-status catalog.

---

## Recommended next ingests

The agentic anchor pages ([[agentic-system-design]], [[model-context-protocol]],
[[retrieval-augmented-generation]]) are already `mature`. The highest-leverage next ingests
extend that cluster:

1. [[multi-agent-orchestration]] — already `draft`; round it out toward `mature`.
2. [[agent-to-agent-protocols]] — pairs with [[model-context-protocol]].
3. [[context-engineering]] + [[agent-memory-architectures]] — feed [[retrieval-augmented-generation]].
4. [[agents-as-system-citizens]] + [[agent-identity-and-access]] — pair with [[ai-specific-security]].

## Mature pages (already trusted)

[[agentic-system-design]] · [[retrieval-augmented-generation]] · [[model-context-protocol]] · [[ai-specific-security]] · [[ai-generated-iac-reviewer]] · [[ai-agent-observability]]
