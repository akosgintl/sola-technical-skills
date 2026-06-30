# Schema — Solution Architect Knowledge Base (LLM Wiki)

> This file is the **schema** for an [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
> It tells any LLM (Claude Code, Obsidian Copilot, etc.) how this knowledge base is
> structured, what the conventions are, and which workflows to follow.
> **Read this file first** before ingesting a source, answering a query, or linting.
>
> Mental model (Karpathy): *Obsidian is the IDE, the LLM is the programmer, the wiki is the codebase.*

---

## 1. What this knowledge base is

A self-maintaining, interlinked markdown wiki that compiles raw source material into
durable, encyclopedia-style pages. It was **seeded from a spine**: the 2026 Solution
Architect skills roadmap (now retired to `archive/skill-set/2026/technology-skills.md`).
Every roadmap topic became a wiki page; with coverage complete, that seed is preserved
as history and **`index.md` is the live master Map of Content.**

Unlike RAG (which re-reads raw documents on every query), this wiki **pre-compiles**
knowledge into structured pages so understanding **compounds** over time. Answers get
filed back as pages, so the same question is never researched twice.

**Three layers:**

1. **`raw/`** — immutable source material (papers→markdown, articles, docs, notes, images). The LLM *reads* these; it never edits them.
2. **`wiki/`** — the compiled knowledge: concept pages + Maps of Content. The LLM writes and maintains these.
3. **This schema (`CLAUDE.md`)** — conventions + workflows.

Plus two ledgers at the root: **`index.md`** (catalog of every page) and **`log.md`** (append-only history).

---

## 2. Directory layout

```
/
├── CLAUDE.md                     # this schema (read first)
├── README.md                     # human entry point
├── index.md                      # catalog: every wiki page, by domain, with status
├── log.md                        # append-only ingest/query/lint history
├── templates/
│   ├── concept-page.md           # copy this to start a new concept page
│   ├── moc.md                    # Map of Content template
│   └── source-note.md            # raw-source capture template
├── wiki/
│   └── concepts/                 # the pages — ONE concept per file, flat, kebab-case
│       └── *.md
├── archive/
│   ├── README.md                 # what's retired and why
│   ├── moc/                      # ARCHIVED Maps of Content — superseded by index.md
│   │   ├── 00-roadmap.md         # former master MOC — mirrors the skills roadmap
│   │   ├── tier-{1,2,3}-*.md     # former tier MOCs
│   │   ├── meta-skills.md        # former meta-skills MOC
│   │   └── dashboard.{md,base}   # former Obsidian Bases dashboard
│   └── skill-set/2026/technology-skills.md   # RETIRED seed roadmap — spine coverage complete
└── raw/                          # immutable sources (see raw/README.md)
    └── assets/<source-slug>/     # local copies of a source's curated visuals (diagrams, frames)
```

> [!note] MOCs are archived
> The `wiki/moc/` hubs have been moved to `archive/moc/`; **`index.md` is now the live
> catalog and navigation entry point.** Because Obsidian and `scripts/lint.ps1` resolve
> `[[wikilinks]]` by basename across the whole repo, every page's `**Domain:** [[tier-1-edge|…]]`
> context line (§8) still resolves to the archived MOC — the convention is left intact for now.
> A future "hard decouple" could replace those context lines with plain text or an `index.md`
> link if the dependency is unwanted.

**Flat `concepts/` on purpose.** Obsidian favors *links over folders*. Don't nest by
topic — let `[[wikilinks]]`, tags, and the [[index]] do the organizing. The graph view is the
real "folder structure."

---

## 3. File & naming conventions

- **One concept per file.** If a page tries to cover two ideas, split it.
- **Filenames:** `kebab-case.md`, descriptive, stable. Match the dominant alias
  (e.g. `retrieval-augmented-generation.md`, not `rag.md` — but add `RAG` as an alias).
- **Page title** (`# H1`) is the human-readable name; the filename is the slug.
- **Never rename a file** without updating every inbound `[[wikilink]]` (run a lint).

**`raw/` filenames** follow a stricter pattern: `YYYY-MM-DD-[<series>-[NN-]]<slug>.md`

| Component | Meaning | Required |
|---|---|---|
| `YYYY-MM-DD` | Ingestion date (not the article's publication date) | Always |
| `<series>` | Shared prefix for related articles (e.g. `graphrag`, `anthropic`) | When ≥2 articles share a topic |
| `NN` | Zero-padded sequence number (01, 02, …) | When series is ordered |
| `<slug>` | Descriptive kebab-case title — no publisher suffix | Always |

Examples: `2026-06-20-recursive-language-models.md`, `2026-06-20-graphrag-01-production-engineer-agent.md`

Decide the series prefix and sequence numbers **before scraping** so no post-ingest renames are needed. The lint script enforces this pattern (Check [6]).

**Asset filenames** (curated images/diagrams/video frames) live in
`raw/assets/<source-slug>/` and are named `<source-slug>-NN-[<short-desc>].<ext>`
(video frames: `<source-slug>-frame-NN.<ext>`).

| Component | Meaning |
|---|---|
| `<source-slug>` | The owning source note's slug — used as both the sub-folder name and the filename prefix |
| `NN` | Zero-padded sequence number (01, 02, …) |
| `<short-desc>` | Optional kebab-case hint (e.g. `architecture`, `pipeline`) |
| `<ext>` | `png` / `jpg` / `svg` / `webp` / `gif` |

The slug prefix makes every **basename unique across the vault** — Obsidian and
`scripts/lint.ps1` resolve `![[embeds]]` by basename, so `![[<source-slug>-02.png]]`
always resolves with no collisions. Generate assets with `scripts/fetch-assets.ps1`
(image URLs) and `scripts/grab-frames.ps1` (video frames); both apply this naming and
print paste-ready embed lines. The `raw/` pattern check (Check [6]) is non-recursive, so
`raw/assets/**` is intentionally exempt.

---

## 4. Frontmatter spec

Every `wiki/` page starts with YAML frontmatter:

```yaml
---
title: Retrieval-Augmented Generation        # human-readable H1 name
aliases: [RAG, retrieval augmented generation]  # for [[alias]] resolution & search
type: concept            # concept | moc | meta | source
domain: ai-agentic       # see §5 domain slugs
status: stub             # stub | seed | draft | mature  (see §6)
tags: [llm, retrieval, vector-search]
updated: 2026-06-19      # ISO date of last meaningful edit
sources: []              # list of raw/ files or URLs this page is grounded in
---
```

`source` pages (in `raw/`) use the lighter template in `templates/source-note.md`.

---

## 5. Domains (the spine)

`domain:` is one of these slugs, each mapped to its navigation MOC:

| Slug | Area | MOC |
|---|---|---|
| `ai-agentic` | AI & Agentic Architecture | [[tier-1-edge]] |
| `cloud` | Cloud Architecture | [[tier-1-edge]] |
| `security` | Security & Compliance | [[tier-1-edge]] |
| `platform` | Platform Engineering & IaC | [[tier-2-solid]] |
| `data` | Data Architecture | [[tier-2-solid]] |
| `integration` | Integration & API Architecture | [[tier-2-solid]] |
| `finops` | FinOps & Cost Architecture | [[tier-2-solid]] |
| `observability` | Observability & Reliability | [[tier-2-solid]] |
| `emerging` | Emerging & adjacent | [[tier-3-watch]] |
| `meta` | Cross-cutting meta-skills | [[meta-skills]] |

---

## 6. Status taxonomy (page maturity)

| Status | Meaning |
|---|---|
| `stub` | Frontmatter + links + a one-line summary. A placeholder ready to ingest into. |
| `seed` | Skeleton headings filled with bullet points; no real synthesis yet. |
| `draft` | Real, sourced content. Usable. May have gaps flagged with `> [!todo]`. |
| `mature` | Reviewed, cited, cross-linked, lint-clean. Trustworthy. |

Promote a page's status as it grows. The `index.md` catalog shows status per page so
gaps are visible at a glance.

---

## 7. Linking conventions (Obsidian-flavored)

- **Cross-reference concepts** with `[[wikilinks]]`: `[[model-context-protocol]]`.
- **Pipe for display text:** `[[retrieval-augmented-generation|RAG]]`.
- **Link generously.** A `[[link]]` to a page that doesn't exist yet is *good* — it
  marks a page worth creating (Obsidian shows it greyed out). Linking *is* the to-do list.
- **Every page** ends with a `## See also` section of related `[[links]]` and a
  `## Sources` section.
- **Every page** links *up* to at least one MOC and *across* to sibling concepts.
- **Callouts** for emphasis: `> [!summary]`, `> [!warning]`, `> [!tip]`, `> [!todo]`.
- Backlinks are automatic in Obsidian — don't hand-maintain a backlinks section.

---

## 8. Anatomy of a concept page

Use `templates/concept-page.md`. Standard sections (omit what doesn't apply):

1. **`# Title`** + frontmatter
2. **`> [!summary]`** one-paragraph definition (the "if you read nothing else")
3. **Context line:** domain MOC link only — `**Domain:** [[<moc>|<Area>]]`
4. **`## What it is`** — the concept, precisely
5. **`## Why it matters`** — why it deserves attention; trade-offs over tutorials
6. **`## Key concepts / building blocks`**
7. **`## Design decisions & trade-offs`** — the defensible calls
8. **`## State of the art`** — current tools, patterns, what changed
9. **`## Pitfalls & anti-patterns`**
10. **`## See also`** — `[[links]]`
11. **`## Sources`** — `raw/` files and external citations

**House style (enforced by `scripts/lint.ps1`):**

- Frontmatter carries **no `priority` or `roadmap_ref`** — relevance comes from `domain`, `status`, and the MOCs.
- The context line shows **Domain only** (no priority emoji, no `§` roadmap ref).
- Section headings carry **no year and no role** — `## Why it matters`, `## State of the art` (never "(2026)" or "senior architect lens").
- Page prose is **evergreen and audience-neutral**: no persona framing ("senior architect", "veteran", "15+ year") and no editorial-year framing ("the 2026 consensus", "the mistakes of 2026"). Factual year tokens are fine — standard/spec names, release/GA dates, citation titles, URLs, and the ISO `updated:` date.
- Concepts stay **flat** in `wiki/concepts/`; organize via `domain:`, MOCs, and the [[dashboard]].
- Embedded images are **local and credited**: embed only genuinely explanatory visuals from
  `raw/assets/` with `![[asset|alt]]` followed by a caption line crediting the source note
  (`*Figure: … — source [[raw-note]].*`). Never embed chrome/decorative images, and never
  hotlink a remote CDN URL into a wiki page.

---

## 9. Workflows

### 9.1 Ingest (add a source → grow the wiki)

When given a new source (paper, article, doc, transcript, note):

1. **Capture** the raw source into `raw/` (convert PDFs/HTML to markdown; use the
   `docling-convert` skill for local files). Add a `templates/source-note.md` header.
2. **Capture the visuals** — do this *now, at first ingest*, while the page is reachable;
   backfilling months later is far harder (the lesson of the 2026-06-30 visual-backfill pass,
   see [[INGEST-RETRO]]). Sources with real diagrams/charts need their visuals *localized*,
   not left as remote hotlinks (which rot).
   - **Enumerate** the diagrams: `WebFetch` the source URL asking for `image-URL | caption`,
     content diagrams only — this is more reliable than parsing the raw capture's markdown.
     **Verify** each URL is a real image (sane extension / UUID shape; for Substack demand the
     full `…/https%3A%2F%2F…` path) — WebFetch occasionally truncates or hallucinates URLs.
   - **Curate** with the keep/drop rubric. **Keep:** original diagrams, architecture/sequence/
     pipeline figures, decision matrices, conceptual charts, annotated screenshots. **Drop:**
     avatars, logos, ad/sponsor banners, subscribe widgets, decorative hero images, **and also
     dataframe/output-table screenshots, code screenshots, registry-config screenshots, and
     raw benchmark result tables** (curation is the real cost — screenshot-heavy walkthroughs
     yield few true diagrams).
   - **Blogs/articles:** `pwsh scripts/fetch-assets.ps1 -Slug <source-slug> -UrlFile <list>`
     downloads the keepers into `raw/assets/<source-slug>/` and **prints paste-ready embed
     lines** — use those verbatim in step 4 (don't hand-type the extension; `.jpeg`→`.jpg`).
   - **arXiv papers:** prefer the HTML version's `/assets/*.png`; fall back to PDF →
     `docling-convert` for papers whose figures are inline TikZ/SVG (no raster `src`).
   - **Videos (YouTube/other):** keep the `yt-transcribe` text, and for on-screen diagrams
     run `pwsh scripts/grab-frames.ps1 -Slug <source-slug> -Url <…> -Timestamps "…"` to
     pull key frames.
   - List the kept visuals under `## Key visuals` in the source note (see template).
3. **Read & discuss** — surface the key takeaways with the user.
4. **Write/extend pages** — for each concept the source informs, create or update the
   relevant `wiki/concepts/` page. Ground claims in the source; add it to `sources:`.
   **Embed** any genuinely explanatory diagram into the page with `![[asset|alt]]` + a
   caption line crediting the source note (§8 house style).
5. **Cross-link** new and changed pages (`[[links]]`, See-also).
6. **Update `index.md`** — add new pages, bump statuses.
7. **Append to `log.md`** — `## [YYYY-MM-DD] ingest | <source title>` + 2–4 bullets.

### 9.2 Query (answer a question → file the answer)

1. **Search the wiki first** — read `index.md`, then the relevant pages.
2. **Synthesize** an answer with citations to the pages/sources used.
3. **File it back** — if the answer revealed a gap, create/extend a page so the next
   ask is instant. Append a `## [date] query | <question>` line to `log.md`.

### 9.3 Lint (keep the wiki healthy)

**Run the mechanical checks with the script** — they are reproducible, not a mental
checklist:

```bash
pwsh scripts/lint.ps1                 # broken links, orphans, index gaps, stale mature pages
pwsh scripts/lint.ps1 -StaleMonths 3  # tighter staleness window
```

It exits non-zero if any `[[wikilink]]` is broken (CI-gateable) and reports:

1. **Broken `[[wikilinks]]`** — target has no page (decide: create a stub or fix the link).
2. **Orphan pages** — no inbound links and not in any MOC.
3. **Index coverage gaps** — a concept page on disk but missing from `index.md`.
4. **Stale `mature` pages** — `updated:` older than the threshold; flag for re-review.

(Placeholder example links in `templates/` and this schema are ignored by design.)

**Then apply the judgment checks the script can't** — these need an LLM reading the content:

- **Status drift** — frontmatter `status:` disagrees with the `index.md` catalog.
- **Contradictions** — two pages making incompatible claims.

Report findings, fix the mechanical ones, append a `lint` entry to `log.md`, and ask before
large rewrites.

---

## 10. Operating principles

- **Compound, don't re-derive.** Always check whether a page already exists before
  researching from scratch. Extend it.
- **Ground everything.** Claims trace to a `source:` (a `raw/` file or a cited URL).
  Unsourced synthesis is allowed but should be marked `> [!todo] verify`.
- **Currency matters.** This is a *2026 state-of-the-art* base. When writing the
  "State of the art" section, prefer current sources over training-data recall; use
  `WebSearch` / Context7 / Microsoft Learn MCP for live docs and cite them.
- **Modular & optional.** Per Karpathy: everything here is a starting convention, not
  law. Adapt it with the user rather than following it rigidly.
- **The senior lens.** This base serves a 15+ year architect. Bias content toward
  *trade-offs, judgment, and design decisions* over tutorials and syntax.
