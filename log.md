# Log

Append-only, chronological history of this wiki. Newest at the bottom.
Consistent prefixes keep it greppable: `## [YYYY-MM-DD] <ingest|query|lint|build> | <title>`.

---

## [2026-06-19] build | Knowledge base bootstrapped

- Established the LLM-Wiki structure per `CLAUDE.md` schema (raw/ → wiki/ → schema).
- Seeded the spine from `skill-set/2026/technology-skills.md` (2026 Solution Architect roadmap).
- Created Maps of Content: [[00-roadmap]], [[tier-1-edge]], [[tier-2-solid]], [[tier-3-watch]], [[meta-skills]].
- Generated 61 concept pages total (55 `stub`, ready to ingest); built `index.md` catalog.
- Wrote 6 research-backed `mature` exemplars for top P0 pages, each with live 2026 web research and citations (50 sources total): [[agentic-system-design]] (7), [[retrieval-augmented-generation]] (9), [[model-context-protocol]] (8), [[ai-specific-security]] (9), [[ai-generated-iac-reviewer]] (9), [[ai-agent-observability]] (8).

## [2026-06-19] lint | Bootstrap link-integrity pass

- Scanned all 75 markdown files for `[[wikilinks]]`: 79 unique targets across the vault.
- 0 broken links among real content. The 12 regex-flagged targets are all illustrative examples in `CLAUDE.md`/templates (`[[link]]`, `[[concept-one]]`, …) or a correctly escaped in-table wikilink (`[[policy-as-code\|…]]`).
- Promoted the 6 exemplars from `draft` → `mature` in `index.md` to match their on-page frontmatter.
- Coverage: every roadmap node (§1–§9 + meta) has a page; no orphans. Next: ingest sources to grow `stub` pages.

## [2026-06-19] build | Review improvements (Tier A + B)

- **Fixed citation defects** in mature pages: corrected a wrong arXiv id → [Tran & Kiela arXiv:2604.02460](https://arxiv.org/abs/2604.02460); added the [MAST / "Why Do Multi-Agent LLM Systems Fail?"](https://openreview.net/forum?id=fAjbYBmonr) citation for the 41–87% figure in [[agentic-system-design]]; softened an unsourced GraphRAG cost number in [[retrieval-augmented-generation]]; added the missing reciprocal RAG link.
- **Shipped executable lint** at `scripts/lint.ps1` (broken links / orphans / index gaps / stale mature) and rewrote `CLAUDE.md` §9.3 to call it. Run: `pwsh scripts/lint.ps1` → currently PASS (0 broken, 0 orphans).
- **Added [[dashboard]]** (Obsidian Bases `dashboard.base` + static backlog) ranking pages by priority × status; linked from README and index.

## [2026-06-19] ingest | Building Effective Agents (Anthropic)

- Source captured to [[2026-06-19-anthropic-building-effective-agents]] (raw/) via firecrawl.
- Promoted [[multi-agent-orchestration]] `stub → draft`, grounded in the five composable
  workflow patterns + orchestrator-workers and the workflows-vs-agents distinction.
- Updated `index.md` status; this is the worked example of the §9.1 ingest workflow.
