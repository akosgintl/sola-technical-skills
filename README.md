# Solution Architect Knowledge Base

A self-maintaining **[LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)**:
an interlinked markdown wiki that compiles raw sources into durable, encyclopedia-style
pages. Built on the spine of the **[2026 Solution Architect Technology Skills Roadmap](skill-set/2026/technology-skills.md)**.

> *Obsidian is the IDE, the LLM is the programmer, the wiki is the codebase.* — A. Karpathy

## How it works

Raw material goes into [`raw/`](raw/). An LLM reads it and compiles structured,
cross-linked pages into [`wiki/`](wiki/). Unlike RAG, knowledge is **pre-compiled** into
entity pages, so understanding **compounds** — the same thing is never researched twice.

- **[`index.md`](index.md)** — the catalog. Every page, by domain, with maturity status. **Start here.**
- **[`wiki/moc/dashboard.md`](wiki/moc/dashboard.md)** — live "what to read / ingest next", ranked by priority × status (Obsidian Bases).
- **[`wiki/moc/00-roadmap.md`](wiki/moc/00-roadmap.md)** — master Map of Content (mirrors the roadmap).
- **[`CLAUDE.md`](CLAUDE.md)** — the *schema*: conventions + workflows. Read this before editing.
- **[`log.md`](log.md)** — append-only history of every ingest / query / lint.

## Open in Obsidian

Point an Obsidian vault at this repo root. Wikilinks (`[[...]]`), backlinks, callouts,
and graph view all work natively. The graph *is* the table of contents.

## Maps of Content

| MOC | Covers |
|---|---|
| [Tier 1 — Where your edge is made](wiki/moc/tier-1-edge.md) | AI & Agentic · Cloud · Security |
| [Tier 2 — Must be solid](wiki/moc/tier-2-solid.md) | Platform · Data · Integration · FinOps · Observability |
| [Tier 3 — Keep an eye on](wiki/moc/tier-3-watch.md) | Emerging & adjacent |
| [Meta-skills](wiki/moc/meta-skills.md) | The 15+ year differentiators |

## Growing the base

Ask your LLM to **ingest** a source (paper, article, doc), **query** the base, or
**lint** it for health. The workflows are defined in [`CLAUDE.md` §9](CLAUDE.md).
New pages start as `stub` and mature to `seed → draft → mature` as content is added.