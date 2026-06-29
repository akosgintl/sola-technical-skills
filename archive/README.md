# Archive

Retired material kept for reference. Nothing here is part of the live wiki workflow,
but it is preserved so its content is not lost.

## `moc/` — former Maps of Content

These were the navigation hubs (`00-roadmap`, the `tier-*` MOCs, `meta-skills`, and the
`dashboard` + `dashboard.base` Obsidian Bases view). They have been **superseded by
[`index.md`](../index.md)** as the primary catalog and navigation entry point.

They are retained because:

- Concept pages still carry a `**Domain:** [[tier-1-edge|…]]` context line. Obsidian (and
  `scripts/lint.ps1`) resolve `[[wikilinks]]` by **basename across the whole repo**, so these
  links keep resolving from `archive/moc/` — moving the folder did **not** break anything.
- `dashboard.base` still renders in Obsidian: its filter targets the absolute path
  `file.folder == "wiki/concepts"` and the embed resolves by name.

Their unique content is also preserved elsewhere: the roadmap mapping mirrors the retired
`skill-set/2026/technology-skills.md` (see below); the meta-skills "honest caveat" lives in that
roadmap source and in `wiki/concepts/t-shaped-depth.md`; tier groupings are derivable from each
page's `domain:` frontmatter plus `index.md`.

## `skill-set/` — seed roadmap

`skill-set/2026/technology-skills.md` is the **2026 Solution Architect Technology Skills Roadmap**
that originally seeded this wiki — the *spine* every concept page was created against. It has been
retired here now that **coverage is complete**: every §1–§9 + meta roadmap node has a `mature`
page (plus 29 ingest-sourced expansions beyond the roadmap), tracked in [`index.md`](../index.md).

Nothing in the live workflow consumes it any longer — the former `CLAUDE.md` §9.3 "Roadmap
coverage" lint check was dropped when this was archived. The wiki now self-governs via `index.md`
+ each page's `domain:` frontmatter. The file is kept purely as the historical source-of-record
for the spine and the original priority/tier framing.
