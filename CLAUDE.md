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
durable, encyclopedia-style pages. It is built on a **spine**: the 2026 Solution
Architect skills roadmap (`skill-set/2026/technology-skills.md`). Every roadmap topic
is (or becomes) a wiki page; the roadmap itself is the master Map of Content.

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
│   ├── moc/                      # Maps of Content (navigation hubs)
│   │   ├── 00-roadmap.md         # master MOC — mirrors the skills roadmap
│   │   ├── tier-1-edge.md        # AI/agentic, cloud, security
│   │   ├── tier-2-solid.md       # platform, data, integration, finops, observability
│   │   ├── tier-3-watch.md       # emerging/adjacent
│   │   └── meta-skills.md        # the 15+ year differentiators
│   └── concepts/                 # the pages — ONE concept per file, flat, kebab-case
│       └── *.md
├── raw/                          # immutable sources (see raw/README.md)
└── skill-set/2026/technology-skills.md   # the seed roadmap (source of the spine)
```

**Flat `concepts/` on purpose.** Obsidian favors *links over folders*. Don't nest by
topic — let `[[wikilinks]]`, tags, and MOCs do the organizing. The graph view is the
real "folder structure."

---

## 3. File & naming conventions

- **One concept per file.** If a page tries to cover two ideas, split it.
- **Filenames:** `kebab-case.md`, descriptive, stable. Match the dominant alias
  (e.g. `retrieval-augmented-generation.md`, not `rag.md` — but add `RAG` as an alias).
- **Page title** (`# H1`) is the human-readable name; the filename is the slug.
- **Never rename a file** without updating every inbound `[[wikilink]]` (run a lint).

---

## 4. Frontmatter spec

Every `wiki/` page starts with YAML frontmatter:

```yaml
---
title: Retrieval-Augmented Generation        # human-readable H1 name
aliases: [RAG, retrieval augmented generation]  # for [[alias]] resolution & search
type: concept            # concept | moc | meta | source
domain: ai-agentic       # see §5 domain slugs
priority: P0             # P0 | P1 | P2 | P3 (from the roadmap)
roadmap_ref: "1.3.1"     # node id in technology-skills.md ("" if not on the roadmap)
status: stub             # stub | seed | draft | mature  (see §6)
tags: [llm, retrieval, vector-search]
updated: 2026-06-19      # ISO date of last meaningful edit
sources: []              # list of raw/ files or URLs this page is grounded in
---
```

`source` pages (in `raw/`) use the lighter template in `templates/source-note.md`.

---

## 5. Domains (the spine) & priorities

`domain:` is one of these slugs (mirrors the roadmap sections):

| Slug | Roadmap | MOC |
|---|---|---|
| `ai-agentic` | §1 AI & Agentic Architecture | [[tier-1-edge]] |
| `cloud` | §2 Cloud Architecture | [[tier-1-edge]] |
| `security` | §3 Security & Compliance | [[tier-1-edge]] |
| `platform` | §4 Platform Engineering & IaC | [[tier-2-solid]] |
| `data` | §5 Data Architecture | [[tier-2-solid]] |
| `integration` | §6 Integration & API Architecture | [[tier-2-solid]] |
| `finops` | §7 FinOps & Cost Architecture | [[tier-2-solid]] |
| `observability` | §8 Observability & Reliability | [[tier-2-solid]] |
| `emerging` | §9 Emerging & adjacent | [[tier-3-watch]] |
| `meta` | Cross-cutting meta-skills | [[meta-skills]] |

**Priority** (from the roadmap, surfaced on every page so depth is obvious):

- 🔴 **P0** — go deep / own it
- 🟠 **P1** — strong competence
- 🟡 **P2** — working knowledge
- 🟢 **P3** — keep an eye on

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
3. **Context line:** priority · domain MOC link · roadmap ref
4. **`## What it is`** — the concept, precisely
5. **`## Why it matters (2026, senior architect lens)`** — why a veteran invests here
6. **`## Key concepts / building blocks`**
7. **`## Design decisions & trade-offs`** — the architect's real job
8. **`## State of the art (2026)`** — current tools, patterns, what changed
9. **`## Pitfalls & anti-patterns`**
10. **`## See also`** — `[[links]]`
11. **`## Sources`** — `raw/` files and external citations

---

## 9. Workflows

### 9.1 Ingest (add a source → grow the wiki)

When given a new source (paper, article, doc, transcript, note):

1. **Capture** the raw source into `raw/` (convert PDFs/HTML to markdown; use the
   `docling-convert` skill for local files). Add a `templates/source-note.md` header.
2. **Read & discuss** — surface the key takeaways with the user.
3. **Write/extend pages** — for each concept the source informs, create or update the
   relevant `wiki/concepts/` page. Ground claims in the source; add it to `sources:`.
4. **Cross-link** new and changed pages (`[[links]]`, See-also).
5. **Update `index.md`** — add new pages, bump statuses.
6. **Append to `log.md`** — `## [YYYY-MM-DD] ingest | <source title>` + 2–4 bullets.

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
- **Roadmap coverage** — nodes in `skill-set/2026/technology-skills.md` with no page yet.

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
