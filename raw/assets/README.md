# raw/assets/ — durable copies of source visuals

Local, version-controlled copies of the **valuable visuals** from ingested sources —
original diagrams, architecture/sequence figures, charts, annotated screenshots, and key
video frames. They live here so the wiki never depends on a third-party CDN that can rot,
rename, or paywall an image. Compiled knowledge lives in [`../../wiki/`](../../wiki/); the
text capture lives in the source note next door in [`../`](../).

## Layout

One sub-folder per source, named with the source's slug:

```
raw/assets/<source-slug>/
  <source-slug>-01.png          # curated blog images (fetch-assets.ps1)
  <source-slug>-02.svg
  <source-slug>-frame-01.png    # video diagram frames (grab-frames.ps1)
```

## Naming — unique basenames

Files are named `<source-slug>-NN-[<short-desc>].<ext>` (video frames:
`<source-slug>-frame-NN.<ext>`). The slug prefix makes every **basename unique across the
whole vault**, which matters because Obsidian and `scripts/lint.ps1` both resolve
`[[wikilink]]` embeds by basename — so a plain embed of `<source-slug>-02.png` always
resolves with no collisions and no full-path embed needed.

## Curation rubric — what to keep

**Keep** (download these): original diagrams, architecture/sequence figures, charts &
graphs, annotated screenshots, data tables shown as images, on-screen diagram frames.

**Drop** (leave as remote links or omit): avatars and author/profile pics, logos, sponsor /
ad banners, social-share buttons, purely decorative hero images, comment-thread images.

## Helpers

- **[`../../scripts/fetch-assets.ps1`](../../scripts/fetch-assets.ps1)** — download a curated
  list of image URLs into `raw/assets/<slug>/` and print paste-ready `![[…]]` embeds.
- **[`../../scripts/grab-frames.ps1`](../../scripts/grab-frames.ps1)** — extract video
  diagram frames at given timestamps (yt-dlp + ffmpeg) into the same folder.

See [`../../CLAUDE.md`](../../CLAUDE.md) §3 (asset naming) and §9.1 (ingest workflow).
