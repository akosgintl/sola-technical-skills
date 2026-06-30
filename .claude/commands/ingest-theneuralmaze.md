---
description: Pull the latest The Neural Maze posts and ingest the ones you pick
argument-hint: "[limit]"
---
Source key: `theneuralmaze` (in `scripts/substack-sources.json`).

1. Run `pwsh scripts/fetch-substack-archive.ps1 -Source theneuralmaze` — append `-Limit $ARGUMENTS`
   only if `$ARGUMENTS` is a number.
2. Then follow the **Substack archive ingest** procedure in `CLAUDE.md §9.4`: show me the NEW
   posts, let me pick which to ingest, and ingest only those (free → firecrawl; `only_paid` →
   authenticated Chrome — I have a paid subscription). Respect the per-wave limit and never
   auto-commit.
