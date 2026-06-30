# Ingest Retrospective — visual backfill pass

Running record of the **visual backfill reingest** of `raw/` (started 2026-06-30): localizing
curated diagrams into `raw/assets/<slug>/` and embedding the explanatory ones into the concept
pages they feed. Its job is to harden the PKB ingest workflow — capture **what works** and, more
importantly, **what does not**, then feed those findings into CLAUDE.md §9.1 and the helper scripts
(see the **Friction & fixes** section). Scope: visual backfill only; videos deferred; unfetchable
images skipped + logged.

**Status legend:** `done` (visuals localized + embedded) · `none` (no valuable visuals — text-only) ·
`blocked` (visuals exist but unfetchable: paywall/auth) · `deferred` (video frames — later pass) ·
`todo` (not yet processed).

## Per-source status

| Source (raw slug) | Class | Status | Assets | Notes |
|---|---|---|---|---|
| 2026-06-19-anthropic-building-effective-agents | article | **done** | 8 | Pilot run; WebFetch listed URLs cleanly; www-cdn direct PNGs. |
| 2026-06-20-graphrag-01-production-engineer-agent | article | **done** | 4 | → [[graphrag]] |
| 2026-06-20-graphrag-02-agentic-graphrag | article | **done** | 11 | → [[graphrag]] (5 embedded) |
| 2026-06-20-graphrag-03-neo4j-agent-memory | article | **done** | 7 | → [[agent-memory-architectures]] |
| 2026-06-20-graphrag-04-knowledge-graph-ontology | article | **done** | 5 | 1 diagram lost (malformed URL) |
| 2026-06-20-graphrag-05-keep-knowledge-graph-clean | article | **done** | 3 | → [[agent-memory-architectures]] |
| 2026-06-20-recursive-language-models | article | **done** | 5 | → [[recursive-language-models]] |
| 2026-06-23-decodingai-01-ai-workflows-vs-agents | article (re-fetch) | todo | | Substack — paywall risk |
| 2026-06-23-decodingai-02-context-engineering | article (re-fetch) | todo | | Substack |
| 2026-06-23-decodingai-03-llm-structured-outputs | article (re-fetch) | todo | | Substack |
| 2026-06-23-decodingai-04-workflow-patterns | article (re-fetch) | todo | | Substack |
| 2026-06-23-decodingai-05-tool-calling | article (re-fetch) | todo | | Substack |
| 2026-06-23-decodingai-06-agent-planning | article (re-fetch) | todo | | Substack |
| 2026-06-23-decodingai-07-react-agents | article (re-fetch) | todo | | Substack |
| 2026-06-23-decodingai-08-agent-memory | article (re-fetch) | todo | | Substack |
| 2026-06-23-decodingai-09-multimodal-agents | article (re-fetch) | todo | | Substack |
| 2026-06-26-decodingai-10-agentic-harness-system-design | article (re-fetch) | todo | | Substack |
| 2026-06-22-edi-00-series-intro | article (re-fetch) | todo | | TDS/Medium — paywall risk |
| 2026-06-22-edi-01-baseline-rag | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-02-embeddings-failure-modes | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-03-rerankers | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-04-rag-not-ml | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-05-technique-selection | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-06-question-parsing-intro | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-07-question-parser-fields | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-08-dispatching | article (re-fetch) | todo | | TDS |
| 2026-06-22-edi-09-vague-questions | article (re-fetch) | todo | | TDS |
| 2026-06-25-sdd-02-microsoft-spec-first | blog (re-fetch) | todo | | |
| 2026-06-25-sdd-08-worktrees-openspec-opencode | blog (re-fetch) | todo | | |
| 2026-06-26-loop-engineering-osmani-anatomy | blog (re-fetch) | todo | | |
| 2026-06-26-loop-engineering-langchain-stack | blog (re-fetch) | todo | | |
| 2026-06-25-sdd-01-piskala-code-to-contract | arXiv paper | todo | | PDF → docling figures |
| 2026-06-25-sdd-07-ssde-repo-level-arxiv | arXiv paper | todo | | PDF → docling figures |
| 2026-06-25-sdd-03-github-spec-kit | docs (GitHub) | none | | README — quick-check then skip |
| 2026-06-25-sdd-04-spec-compare-tools | docs (GitHub) | none | | |
| 2026-06-25-sdd-05-ears-mavin-canonical | docs | none | | EARS reference text |
| 2026-06-25-sdd-06-kiro-feature-specs | docs | none | | |
| 2026-06-25-sdd-09-spec-kit-constitution | docs (GitHub) | none | | |
| 2026-06-25-ssd01-01-research-report | research report | none | | Internal deep-research, text-only (`citeturn` junk) |
| 2026-06-25-ssd01-02-research-report | research report | none | | |
| 2026-06-25-ssd01-03-research-report | research report | none | | |
| 2026-06-25-ssd01-04-research-report | research report | none | | |
| 2026-06-21-loop-engineering | transcript (video) | deferred | | Frame extraction — later pass (needs yt-dlp) |
| 2026-06-30-pocock-01-software-fundamentals-keynote | transcript (video) | deferred | | |
| 2026-06-30-pocock-02-ai-coding-workflow-walkthrough | transcript (video) | deferred | | |
| 2026-06-30-pocock-03-building-great-agent-skills | transcript (video) | deferred | | |

## Friction & fixes (what works / what doesn't)

> Append findings as phases run. Each entry: **observation → impact → proposed fix.**

### What works
- **WebFetch to enumerate diagram URLs** (pilot Anthropic + all 6 Decoding AI pieces): asking for
  `URL | caption` and to exclude chrome returns clean, captioned content-diagram URLs ready for
  `fetch-assets.ps1 -UrlFile`. **More reliable than parsing the raw capture's interleaved markdown.**
- **Decoding AI (Substack) is publicly fetchable** — WebFetch and the Substack `w_1456` transform
  CDN URLs both work; no paywall hit on these posts. 35 curated diagrams downloaded first try
  (1 further diagram lost to a malformed URL — see below).
- **Batch download** — one PowerShell loop over `{slug → urlfile}` localized all 6 sources in a
  single call; `fetch-assets.ps1` extension-inference picked `.png` correctly from the encoded
  Substack tail; idempotent skip held on re-runs.

### What doesn't (→ Phase G)
- **Visuals were not captured at first ingest.** Every non-pilot source needs a re-fetch; only the
  6 Decoding AI pieces even had image URLs in the raw capture (and those were chrome-polluted).
  Root-cause fix belongs at *capture time*. _(Strong signal already; confirm scale in C–F.)_
- **WebFetch occasionally mangles a URL.** graphrag-04's "data-exploration loop" came back with a
  9-hex UUID segment (`c3cbabfc9…`) — unfetchable, so that diagram was dropped. Need a sanity check
  on enumerated URLs (UUID shape) before trusting them.
- **Caption/URL ordering drift.** In one list the caption and URL were offset, so a code-screenshot
  got a diagram's caption — caught only by manual cross-check. Curation must verify, not trust.
- **Embed-vs-localize gap.** Mature pages can't absorb 11 diagrams each; many are localized but not
  embedded (logged in each raw note's `## Key visuals`). Acceptable, but argues for capturing
  visuals once at ingest and embedding lazily.

### Proposed workflow improvements (accumulating → Phase G)
- **Capture visuals at ingest time** (biggest lever): when first scraping a source, run the
  WebFetch-enumerate → `fetch-assets.ps1` step immediately, so backfill is never needed and content
  is grabbed while the page is reachable.
- **Validate enumerated URLs** (UUID/extension shape) and **cross-check caption↔URL** before download.
- Consider a lint check flagging remote-CDN `![...](http…)` hotlinks left in `wiki/` pages.
