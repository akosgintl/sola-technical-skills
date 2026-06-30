---
title: "Multimodal AI Agents: Images, PDFs & Audio"
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, multimodal, vision, pdf, audio, colpali, rag]
updated: 2026-06-30
source_url: https://www.decodingai.com/p/stop-converting-documents-to-text
source_type: article
ingested: 2026-06-23
feeds: [multimodal-document-processing, retrieval-augmented-generation]
---

# Multimodal AI Agents: Images, PDFs & Audio

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Series:** AI Agents Foundations #9 · **URL:** https://www.decodingai.com/p/stop-converting-documents-to-text

## Key takeaways

- Key insight: treat PDF pages as images rather than extracting text — modern LLMs process visual data natively, preserving spatial relationships, colors, and layout that OCR loses.
- Two multimodal LLM architectures: **Unified Embedding Decoder** (text + image embeddings concatenated; simpler, higher OCR accuracy) and **Cross-modality Attention** (image embeddings injected into attention mechanism; more efficient for high-resolution images).
- Vision encoders (CLIP, OpenCLIP, SigLIP) convert images to embeddings in a shared vector space with text.
- Three encoding approaches: Raw Bytes (simple, risk of DB corruption), Base64 (safe, ~33% size increase), URLs (most efficient at scale, data in S3/GCS).
- Multimodal tools for agents: `text_image_search_tool`, `image_to_image_search_tool`, `image_audio_search_tool`, `image_document_search_tool`, `computer_screen_shoot_tool`.
- Multimodal retrieval requires vector similarity with multimodal embedding models — keyword search fails for images and audio.
- ColPali research: Vision Language Models retrieve documents more effectively by treating them as images rather than extracting text (the core justification for the "stop converting" argument).
- Agent short-term memory naturally extends to mixed modalities — each message can contain text, images, audio, or documents.

## Notable claims (with location)

- Traditional OCR pipelines are brittle, slow, and expensive — fail on unexpected layouts or specialized diagrams.
- Base64 encoding: ~33% file size increase vs. raw bytes; URL-based: no size overhead, requires cloud storage.
- Gemini API accepts PDFs identically to images via `Part.from_bytes(data=pdf_bytes, mime_type="application/pdf")`.

## Key visuals

Localized to `raw/assets/2026-06-23-decodingai-09-multimodal-agents/` (3 architecture diagrams, visual backfill 2026-06-30). The first WebFetch returned truncated image URLs (transform prefix only, no source path); a second, more specific prompt recovered the full URLs. Example photos/screenshots were excluded.

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.jpg` | The two main approaches to multimodal LLMs | [[multimodal-document-processing]] |
| `…-02.jpg` | Unified embedding decoder architecture | [[multimodal-document-processing]] |
| `…-03.jpg` | Cross-modality attention architecture | [[multimodal-document-processing]] |

## Feeds these wiki pages

- [[multimodal-document-processing]]
- [[retrieval-augmented-generation]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
