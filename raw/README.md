# raw/ — immutable source material

This folder holds **sources**, not knowledge. The LLM *reads* these and never edits the
captured content. Compiled understanding lives in [`../wiki/`](../wiki/).

## What goes here

- Research papers (convert PDF → markdown with the `docling-convert` skill)
- Web articles & docs (clip to markdown)
- Meeting notes, transcripts (e.g. via the `yt-transcribe` skill)
- Datasets, screenshots, diagrams

## Convention

Each captured source gets a header from [`../templates/source-note.md`](../templates/source-note.md):
metadata, key takeaways, and which `wiki/concepts/` pages it feeds. Keep one source per
file, named `kebab-case` by title or `YYYY-MM-DD-slug` for dated material.

Analysis and takeaways go *above* the captured raw content; the raw content stays verbatim.
