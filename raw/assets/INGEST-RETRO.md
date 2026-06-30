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
| 2026-06-23-decodingai-01-ai-workflows-vs-agents | article (re-fetch) | **done** | 9 | → agentic-system-design, agentic-loop |
| 2026-06-23-decodingai-02-context-engineering | article (re-fetch) | **done** | 2 | → context-engineering; promo graphics dropped |
| 2026-06-23-decodingai-03-llm-structured-outputs | article (re-fetch) | **done** | 2 | → llm-structured-outputs |
| 2026-06-23-decodingai-04-workflow-patterns | article (re-fetch) | **done** | 6 | localized; patterns already on multi-agent-orchestration |
| 2026-06-23-decodingai-05-tool-calling | article (re-fetch) | **done** | 3 | → llm-tool-use |
| 2026-06-23-decodingai-06-agent-planning | article (re-fetch) | **done** | 5 | → agent-planning |
| 2026-06-23-decodingai-07-react-agents | article (re-fetch) | **done** | 1 | 2 figures were dups of -06 (cross-article reuse) |
| 2026-06-23-decodingai-08-agent-memory | article (re-fetch) | **done** | 5 | → agent-memory-architectures |
| 2026-06-23-decodingai-09-multimodal-agents | article (re-fetch) | **done** | 3 | truncated URLs recovered via 2nd targeted prompt |
| 2026-06-26-decodingai-10-agentic-harness-system-design | article (re-fetch) | **done** | 9 | → agentic-harness |
| 2026-06-22-edi-00-series-intro | article (re-fetch) | **done** | 7 | → retrieval-augmented-generation |
| 2026-06-22-edi-01-baseline-rag | article (re-fetch) | **done** | 3 | → retrieval-augmented-generation |
| 2026-06-22-edi-02-embeddings-failure-modes | article (re-fetch) | **none** | 0 | only scorer-comparison tables, no diagrams |
| 2026-06-22-edi-03-rerankers | article (re-fetch) | **done** | 1 | → RAG; ~10 result tables not localized |
| 2026-06-22-edi-04-rag-not-ml | article (re-fetch) | **done** | 1 | timeline diagram; sklearn example dropped |
| 2026-06-22-edi-05-technique-selection | article (re-fetch) | **done** | 4 | complexity/control tiers + decision matrix |
| 2026-06-22-edi-06-question-parsing-intro | article (re-fetch) | **none** | 0 | only series-position image + screenshots |
| 2026-06-22-edi-07-question-parser-fields | article (re-fetch) | **done** | 2 | → rag-query-understanding |
| 2026-06-22-edi-08-dispatching | article (re-fetch) | **done** | 2 | → rag-query-understanding |
| 2026-06-22-edi-09-vague-questions | article (re-fetch) | **none** | 0 | only series-position image; code-heavy |
| 2026-06-25-sdd-02-microsoft-spec-first | blog (re-fetch) | **done** | 1 | Spec Kit lifecycle → spec-driven-development |
| 2026-06-25-sdd-08-worktrees-openspec-opencode | blog (re-fetch) | **none** | 0 | prose + cover photo only |
| 2026-06-26-loop-engineering-osmani-anatomy | blog (re-fetch) | **none** | 0 | comparison table (not an image) + headshot |
| 2026-06-26-loop-engineering-langchain-stack | blog (re-fetch) | **done** | 8 | four-loop diagrams → agentic-loop |
| 2026-06-25-sdd-01-piskala-code-to-contract | arXiv paper | **blocked** | 0 | HTML has no raster figures (TikZ/SVG-inline); needs PDF→docling — deferred |
| 2026-06-25-sdd-07-ssde-repo-level-arxiv | arXiv paper | **done** | 1 | overview.png from arXiv HTML → spec-driven-development |
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
- **WebFetch truncates some image URLs** (decodingai-09): the first enumeration returned only the
  CDN transform prefix with no encoded source path — unusable. A **second, more specific prompt**
  (demand the full `…/https%3A%2F%2F…` path, write SKIP otherwise) recovered all three. Worth doing
  by default for image-heavy pages.
- **Cross-article image reuse** (decodingai-07 reused two figures verbatim from -06). Per-source
  folders mean the same bytes get stored twice under different names. Minor; a content-hash dedupe
  in `fetch-assets.ps1` could collapse these, but cross-source duplication is rare enough to ignore.
- **Confirmed at scale: Decoding AI / Substack is fully fetchable** (16/16 posts, ~80 diagrams) —
  the paywall hypothesis did NOT hold for this publisher. The real cost was curation, not access.
- **Extension mismatch in hand-written embeds** (`.jpeg` sources save as `.jpg`, not `.png`):
  caught by lint as broken `.png` embed links. Fix: paste the embed lines `fetch-assets.ps1`
  already emits (correct extension) instead of hand-typing `.png`.
- **arXiv HTML works for raster-figure papers, not TikZ/SVG ones.** SSDE (2605.02455) exposed a
  direct `/assets/overview.png` — grabbed cleanly, no PDF/docling needed. The Piskala paper
  (2602.00180) renders its figures inline (LaTeXML, no `<img …png>`), so the HTML path yielded
  nothing and WebFetch *hallucinated* plausible image URLs (`x1.png`…) that 404'd. Lesson: verify
  arXiv image URLs exist before trusting an LLM's enumeration; fall back to PDF→`docling-convert`
  for vector-figure papers (deferred here).
- **TDS/Medium also fully fetchable** (paywall hypothesis again did not hold); images on a
  WordPress CDN. BUT the EDI series is **screenshot-heavy code walkthroughs** — 3/10 articles had
  **zero genuine diagrams** (only dataframe/result-table screenshots), and curation had to discard
  far more than it kept. The real friction for this publisher is *signal-to-noise in the images*,
  not access — a per-source judgement the enumerate→curate step handled but which cost the most time.

## Synthesis (Phase G) — outcome & adopted improvements

**The pass.** Visual backfill across all 44 `raw/` sources. Localized **~110 curated diagrams**
into `raw/assets/<slug>/` and embedded **~45** into concept pages, committed in six phases
(B–F). Coverage: **27 done**, **8 none** (text/screenshot-only), **1 blocked** (TikZ-figure
arXiv paper), **4 deferred** (video frames), **4 prior** (the Anthropic pilot + this scaffold).

**Headline finding.** The pre-pass hypothesis was *paywalls will block re-fetching*. It was
**wrong** — every publisher hit (Anthropic, Decoding AI/Substack ×16, Towards Data Science/Medium
×10, LangChain, Microsoft, arXiv HTML) was fully fetchable. The real costs were **(1)** that
visuals weren't captured at first ingest, forcing a whole backfill pass, and **(2)** *curation* —
separating genuine diagrams from dataframe/code/result-table screenshots, which dominated the time.

**Adopted this phase (committed):**
- CLAUDE.md §9.1 step 2 rewritten: capture visuals **at first ingest**; **WebFetch-enumerate**
  (`URL | caption`) as the canonical method; **verify** URLs (shape / full Substack path);
  expanded **drop** rubric (dataframe/code/registry screenshots, benchmark tables); arXiv
  HTML-then-docling guidance; **paste the script's emitted embed lines** (correct extension).
- `raw/assets/README.md` curation rubric expanded with the same drop categories + a "curation is
  the real cost" note.
- `fetch-assets.ps1` now prints a `DONE: N saved, M failed` summary (batch loops can detect
  failures without parsing `WARNING:`-prefixed lines).

**Deferred (next pass, not blocking):**
- Video frame extraction for the 4 transcripts (needs `yt-dlp` via `update-tooling` + manual
  timestamps) — `grab-frames.ps1` is ready.
- arXiv `sdd-01` (Piskala) figures via PDF → `docling-convert` (HTML had no raster figures).
- Optional lint check flagging remote-CDN `![](http…)` hotlinks left in `wiki/` pages.
- Optional content-hash dedupe in `fetch-assets.ps1` for cross-article image reuse (rare).
