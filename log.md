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

## [2026-06-20] ingest | GraphRAG & Knowledge Graph Agent Memory series (Decoding AI, 5 articles)

Sources captured to `raw/graphrag-01` through `raw/graphrag-05` (articles 2026-01-20 through 2026-06-02, Anca Muscalagiu & Paul Iusztin).

**Series arc:** architecture design (articles 1–2) → Neo4j memory system internals (article 3) → ontology design (article 4) → graph hygiene pipeline (article 5).

- Created [[graphrag]] `draft` — covers: what GraphRAG is (data modeling problem, not retrieval algorithm), knowledge graph fundamentals, property graph vs RDF, two-phase generation (extraction → communities → summaries) + two-stage retrieval (RRF entry points → 2–3 hop traversal), bottom-up vs top-down, append-only vs mutable data models, DB selection (Postgres/MongoDB vs Neo4j), agentic GraphRAG via MCP `search_memory`/`write_memory` tools, production layering (graph=historical, MCP=real-time).
- Promoted [[agent-memory-architectures]] `stub → draft` — covers: 3 memory tiers (short-term/long-term/reasoning) joined by 3 typed edges, POLE+O ontology (5 fixed base types + subtypes), `:Fact` and `:Preference` primitives, 3-stage extraction cascade (spaCy → GLiNER → LLM), entity resolution vs deduplication (critical distinction), weighted dedup scores, `:SAME_AS` pending edge pattern for human review, dream pipeline (nightly re-dedup). Grounded in `neo4j-labs/agent-memory` reference implementation.
- Updated `index.md`: added `[[graphrag]] | draft`, bumped `[[agent-memory-architectures]]` to `draft`.

## [2026-06-20] ingest | Recursive Language Models (Decoding AI / Paul Iusztin)

- Source captured to `raw/recursive-language-models-decodingai.md` (article, 2026-04-07, grounded in arXiv:2512.24601).
- Created [[recursive-language-models]] `draft` — new concept page covering: REPL-based data navigation, root controller + worker sub-model architecture, `llm_query()`/`FINAL()` primitives, production guardrails (`maxIterations`, `maxDepth`, `maxStdoutLength`, sandboxing), four use cases (large file parsing, codebase comprehension, legal/financial analysis, deep research), and the RLM vs. RAG vs. CAG decision framework.
- Promoted [[context-engineering]] `stub → seed`: added the three-pattern comparison table (CAG / RAG / RLMs) and linked to the new page.
- Updated `index.md`: added `[[recursive-language-models]] | draft`, bumped `[[context-engineering]]` to `seed`.

## [2026-06-20] build | Wave 0 — 4 draft/seed pages promoted to mature

- [[multi-agent-orchestration]] `draft → mature`: expanded "State of the art" with the MAST failure-taxonomy paper (41–87% multi-agent failure rates, specification/coordination/verification gaps), added 2026 framework landscape table (LangGraph GA v1.0.10, CrewAI v1.10.1, Claude Agent SDK v0.1.48, OpenAI Agents SDK, Strands, AutoGen); added 4 new sources.
- [[context-engineering]] `seed → mature`: full rewrite from seed to a research-backed 8-source mature page. Added: context budget allocation (system/retrieved/history/generation zones), information ordering (U-shaped attention / lost-in-the-middle, Liu et al. arXiv:2307.03172 + calibration study arXiv:2406.16008), compression patterns (sliding window / hierarchical summarization / selective preservation), prompt caching design (cache_control breakpoints, 90% cost reduction), relevance selection (top-k, MMR, reranking, late chunking), ContextBudget runtime control (arXiv:2604.01664), AgentSwing adaptive routing (arXiv:2603.27490), LOCA-bench context-rot benchmark (arXiv:2602.07962). Anchored in Anthropic's Sept 2025 "Effective context engineering" post.
- [[agent-memory-architectures]] `draft → mature`: content already at mature quality (3-tier memory, POLE+O ontology, 3-stage extraction, entity normalization, dream pipeline, 8 sources); status updated.
- [[graphrag]] `draft → mature`: added GraphRAG vs. plain RAG decision table (query type / infrastructure cost / latency / multi-hop / best-fit dimensions); all cross-links to [[retrieval-augmented-generation]] and [[agent-memory-architectures]] verified; status updated.
- Updated `index.md`: 10 mature pages (70+ cited sources), 0 draft, 0 seed.

## [2026-06-20] build | Gap analysis — 4 missing roadmap nodes added as stubs

- Audited all 63 concept pages against `skill-set/2026/technology-skills.md`; found 4 roadmap nodes with no wiki page.
- Created [[encryption-and-key-management]] `stub` (§3.1.3, security) — envelope encryption, KMS, HSM, mTLS, CMK, secrets management.
- Created [[network-segmentation]] `stub` (§3.1.4, security) — VPC segmentation, security groups, Kubernetes Network Policy, eBPF enforcement, mTLS east-west.
- Created [[dynamic-team-staffing]] `stub` (§9.2, emerging) — agentic throughput layer, human judgment gates, Team Topologies framing.
- Created [[ai-architecture-certifications]] `stub` (§9.3, emerging) — vendor AI architect tracks (AWS/Azure/GCP), nascent agentic-AI programs, TOGAF extensions.
- Updated `index.md`: all 67 concept pages now registered; roadmap coverage is complete (every §1–§9 + meta node has a page).
- Priority upgrade queue identified (plan file): Wave 0 = promote 4 in-flight drafts; Wave 1 = ai-data-fabric + ai-gpu-economics cluster; Wave 2 = multi-cloud + cloud-native cluster; Wave 3 = reliability + streaming + data + CI/CD.

## [2026-06-19] build | House-style change — drop priority/roadmap, de-frame prose

- Removed `priority` and `roadmap_ref` frontmatter from all wiki pages, MOCs, templates, index, and the source note; trimmed every concept context line to **Domain only**.
- Renamed sections `## Why it matters (2026, senior architect lens)` → `## Why it matters` and `## State of the art (2026)` → `## State of the art`.
- De-framed prose across the wiki: removed persona/role framing ("senior architect", "veteran", "15+ year") and editorial-year framing ("the 2026 consensus"), keeping factual year tokens (standard names, GA/release dates, citation titles, URLs, ISO dates).
- `index.md` dropped Pri/Roadmap columns; MOCs dropped priority emojis + `§` refs; [[dashboard]] re-based on status/domain (Bases) instead of priority. Concepts stay flat.
- Encoded the rules as **House style** in `CLAUDE.md` §8 and added a house-style check to `scripts/lint.ps1` (priority/roadmap, year-in-heading, role terms). Lint: PASS (0 broken, 0 house-style violations).
