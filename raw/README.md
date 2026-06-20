# raw/ — immutable source material

This folder holds **sources**, not knowledge. The LLM *reads* these and never edits the
captured content. Compiled understanding lives in [`../wiki/`](../wiki/).

## What goes here

- Research papers (convert PDF → markdown with the `docling-convert` skill)
- Web articles & docs (clip to markdown)
- Meeting notes, transcripts (e.g. via the `yt-transcribe` skill)
- Datasets, screenshots, diagrams

## Naming convention

**Pattern:** `YYYY-MM-DD-[<series>-[NN-]]<slug>.md`

| Pattern | When | Example |
|---|---|---|
| `YYYY-MM-DD-<slug>.md` | Standalone article or source | `2026-06-20-recursive-language-models.md` |
| `YYYY-MM-DD-<series>-NN-<slug>.md` | Ordered series on one topic | `2026-06-20-graphrag-01-production-engineer-agent.md` |

Rules:
- **Date = ingestion date** (not the source's publication date — publication date goes in frontmatter `pub_date:`).
- **Series prefix** (e.g. `graphrag`) groups related articles; decide it *before* scraping.
- **No publisher suffix** in the slug — publisher lives in frontmatter `source_url`.
- The lint script (`scripts/lint.ps1`) enforces this pattern and flags violations.

## File structure

Each captured source gets a header from [`../templates/source-note.md`](../templates/source-note.md):
frontmatter, key takeaways, and a `feeds:` list of which `wiki/concepts/` pages it informs.
The raw content stays verbatim below a separator line. Analysis lives above it.
