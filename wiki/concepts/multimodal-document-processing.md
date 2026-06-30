---
title: Multimodal Document Processing
aliases: [multimodal agents, vision document processing, multimodal RAG, document intelligence, stop converting to text]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, multimodal, vision, pdf, audio, colpali, rag, embeddings]
updated: 2026-06-23
sources:
  - raw/2026-06-23-decodingai-09-multimodal-agents.md
  - "https://www.decodingai.com/p/stop-converting-documents-to-text"
  - "https://arxiv.org/abs/2407.01449"
  - "https://openai.com/index/gpt-4-technical-report/"
  - "https://arxiv.org/abs/2103.00020"
---

# Multimodal Document Processing

> [!summary]
> Multimodal document processing is the practice of sending images, PDFs, audio, and other non-text content directly to a vision-capable LLM rather than converting them to text first. Modern LLMs can read documents as images, preserving the spatial relationships, layout, color, and visual context that OCR pipelines discard. The key insight: most traditional "document AI" pipelines are brittle text-extraction layers in front of a model that was always capable of understanding the raw visual input.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Traditional document processing pipelines assume text is the universal intermediate format: a PDF arrives → layout detection → OCR → table recognition → figure description → text assembly → LLM. Each conversion step loses information and introduces failure modes. A financial report with embedded charts becomes a table of numbers with no spatial context. A technical diagram becomes an approximate description. Audio becomes a transcript without tone or emphasis.

The alternative: treat documents as the multimodal objects they are. A modern vision-capable LLM (Gemini, GPT-4V, Claude) can receive a PDF page as an image — byte-for-byte — and reason about its content with no preprocessing pipeline. The ColPali paper (Faysse et al., arXiv:2407.01449) demonstrated empirically that Vision Language Models retrieve document pages more accurately when treating them as images than when extracting text.

**The three failure modes of text-only conversion that multimodal processing eliminates:**

1. **Layout collapse** — OCR does not know that the number in column 3 row 7 is the revenue figure for Q2; it produces a stream of characters. The LLM must reconstruct table structure from text — with errors.
2. **Visual context loss** — a diagram's spatial relationships, a chart's trend, a form's checkbox layout — all lost in text conversion.
3. **Pipeline fragility** — unexpected document layouts (scanned, rotated, hand-annotated, custom fonts) break OCR heuristics silently, producing malformed text that downstream code cannot detect as wrong.

## Why it matters

**Breadth of document types.** Enterprise AI needs to handle financial reports with charts, technical diagrams in specifications, audio logs from customer calls, video transcripts with visual context, and form images scanned at 300dpi. A text-only pipeline requires specialized handling for each; a multimodal pipeline has a unified input path.

**Reliability.** Text extraction pipelines fail on unexpected layouts and produce no signal when they fail — the LLM receives malformed text and hallucinates a plausible answer. A multimodal pipeline's failure mode is explicit: the image is unclear, the model says so.

**Agent capability expansion.** A multimodal agent can use a screenshot tool, receive the image, and reason about the UI — no screen parsing pipeline required. It can retrieve visually similar images via embedding similarity, not keyword search. The modality boundary is the tool boundary, not a preprocessing requirement.

## Key concepts / building blocks

### Multimodal LLM architectures

Two primary architectures achieve multimodal understanding:

![[2026-06-23-decodingai-09-multimodal-agents-01.jpg|The two main approaches to building multimodal LLMs]]
*Figure: The two main approaches to developing multimodal LLM architectures — source [[2026-06-23-decodingai-09-multimodal-agents]].*

**Unified Embedding Decoder:** Text and image are encoded separately (text tokenizer + vision encoder), the embeddings are concatenated, and the full sequence is passed to the LLM transformer. Simpler to implement; higher accuracy for OCR-heavy tasks because image features are explicitly aligned with token positions.

![[2026-06-23-decodingai-09-multimodal-agents-02.jpg|Unified embedding decoder: concatenate image and text embeddings]]
*Figure: Unified embedding decoder architecture — source [[2026-06-23-decodingai-09-multimodal-agents]].*

**Cross-modality Attention:** Image embeddings are injected directly into the attention mechanism at each transformer layer rather than concatenated to the input. More computationally efficient for high-resolution images; better at reasoning about fine-grained visual relationships. This is the architecture used by models like Claude 3 and Gemini 2.5.

![[2026-06-23-decodingai-09-multimodal-agents-03.jpg|Cross-modality attention: inject image embeddings into each attention layer]]
*Figure: Cross-modality attention architecture — source [[2026-06-23-decodingai-09-multimodal-agents]].*

Both architectures rely on **vision encoders** (CLIP, OpenCLIP, SigLIP) that embed images into the same vector space as text — enabling semantic comparison between image content and text queries without explicit OCR.

### Encoding strategies for agent pipelines

Three approaches for passing images and documents to a model or storing them in agent memory:

| Approach | Mechanism | Trade-off |
|---|---|---|
| Raw bytes | `Part.from_bytes(data=img_bytes)` | Simplest; risk of database corruption if stored naively |
| Base64 encoding | Convert to base64 string | Safe for any storage system; ~33% size overhead |
| URL/GCS reference | `Part.from_uri(uri="gs://bucket/file")` | No size overhead; requires cloud storage (S3, GCS, Azure Blob) |

For production scale: base64 for small images and thumbnails stored alongside text metadata; URL references for full-resolution documents in cloud storage. Never store raw binary directly in a relational database column.

### Multimodal tool design for agents

Tools in multimodal agents return non-text data that becomes part of [[agent-memory-architectures|agent short-term memory]]. Each message in the agent's state can contain text, images, audio, or document references:

```python
# Tool returning image content (computer screenshot)
{
  "role": "tool",
  "name": "computer_screen_shoot_tool",
  "parts": [{"inline_data": {"mime_type": "image/jpeg", "data": "<base64>"}}]
}

# Tool returning a document from cloud storage
{
  "role": "tool",
  "name": "google_drive_document_search_tool",
  "parts": [{"file_data": {"mime_type": "application/pdf", "file_uri": "gs://bucket/doc.pdf"}}]
}
```

An agent that captures a screenshot at step 1 can reference that image in any subsequent step — the image persists in the message history, enabling reasoning like "what is the color of the kitten in the screenshot I took earlier?" without another tool call.

### Multimodal retrieval

Keyword search fails for images and audio — there is no text to match. Multimodal [[retrieval-augmented-generation|retrieval]] requires:

1. **Multimodal embeddings** — encode images, audio clips, and document pages with the same embedding model used for text queries (CLIP-compatible models). This creates a shared semantic space where a text query "Q3 revenue chart" can surface the matching bar chart image.

2. **Vector similarity search** — query the vector database with the multimodal embedding; retrieve the most semantically similar content regardless of modality (see [[vector-and-embedding-stores]]).

3. **Late interaction models** — ColBERT-style scoring where the query interacts with every patch of the document image independently. The ColPali architecture applies this to PDF retrieval, achieving higher accuracy than text extraction approaches on visually complex documents.

### ColPali: the empirical case for image-based document retrieval

The ColPali paper (Faysse et al., arXiv:2407.01449) is the primary research grounding for treating PDFs as images in retrieval pipelines. Key findings:

- Existing PDF retrieval pipelines fail on complex visual layouts, figures, and tables
- A Vision Language Model fine-tuned with late interaction scoring retrieves the correct document page more reliably than text-extraction pipelines
- The performance gap is largest on documents with charts, diagrams, and non-standard layouts — precisely the enterprise documents that matter most

This makes the "stop converting documents to text" recommendation an empirically grounded design choice, not a preference.

## Design decisions & trade-offs

**When to use native multimodal vs. text extraction:**
- If the document contains charts, diagrams, forms, or non-standard layouts → native multimodal.
- If the document is clean text (articles, code files, markdown) → text extraction is simpler and cheaper.
- If you need exact character-level fidelity (legal contract parsing, data extraction) → text extraction or hybrid (multimodal for layout understanding, OCR for character accuracy).

**Image resolution and token cost:**
High-resolution images consume more tokens. Gemini 2.5 and GPT-4V both have per-image token costs that scale with resolution. Tile the image at lower resolution for layout understanding; pass at full resolution only when character-level detail is required. Profile token costs before scaling.

**Storage for multimodal agent memory:**
Images in agent state are transient for session use. For cross-session persistence, store image references (GCS URIs) in the memory layer, not the images themselves. The agent loads images on demand from cloud storage when they are relevant to the current task.

**Modality parity in retrieval:**
A retrieval system that only supports text queries cannot surface audio or image content by semantic similarity. Invest in multimodal embeddings early if the domain includes non-text content — retrofitting is more expensive than building it in.

## State of the art

Gemini 2.5 Flash and Pro (Google, 2025–2026) are the leading production models for multimodal document processing — they accept PDFs, images, audio, and video directly, have native function calling with multimodal tool results, and support million-token context windows suitable for long document analysis.

GPT-4V and GPT-4o (OpenAI) provide strong vision capabilities with extensive production deployment. Claude 3 and Claude 3.5 Sonnet (Anthropic) excel at document understanding with their cross-modality attention architecture.

ColPali and its successors (ColQwen2, ColBERT-v3) are actively developing as the standard for multimodal document retrieval in RAG pipelines. By mid-2026, multimodal embedding support has been added to Qdrant, Weaviate, and Pinecone — enabling unified text+image vector search in a single index.

## Pitfalls & anti-patterns

**Defaulting to OCR when multimodal is available.** If the LLM in use supports direct image input, adding an OCR preprocessing step introduces latency, cost, and information loss without benefit. Test the direct path first.

**Storing raw images in relational databases.** Binary blobs in SQL databases degrade query performance and complicate backup/replication. Store object references (S3 keys, GCS URIs) and let cloud object storage handle the bytes.

**Keyword search for image retrieval.** A retrieval system that can only match on text metadata (filename, caption, extracted OCR text) misses semantic image content. Multimodal embeddings are required for semantic image retrieval.

**Ignoring token cost at image scale.** A 100-page PDF processed page-by-page as full-resolution images can cost 10–50× the tokens of a text extraction approach. Profile costs and apply resolution tuning or selective page processing before deploying at scale.

**Treating multimodal as text with pictures.** Multimodal agents need tool schemas that explicitly handle non-text modalities (base64 image parameters, MIME types, streaming audio), multimodal memory structures, and retrieval pipelines tuned for cross-modal similarity. Grafting multimodal inputs onto a text-only architecture produces subtle failures.

## See also

- [[retrieval-augmented-generation]]
- [[vector-and-embedding-stores]]
- [[agent-memory-architectures]]
- [[agentic-system-design]]
- [[rag-query-understanding]]
- [[graphrag]]

## Sources

- Iusztin, P. (Decoding AI). Multimodal AI Agents: Images, PDFs & Audio. https://www.decodingai.com/p/stop-converting-documents-to-text
- Faysse, M., et al. (2024). ColPali: Efficient Document Retrieval with Vision Language Models. arXiv:2407.01449. https://arxiv.org/abs/2407.01449
- Radford, A., et al. (2021). Learning Transferable Visual Models From Natural Language Supervision (CLIP). arXiv:2103.00020. https://arxiv.org/abs/2103.00020
- OpenAI. (2023). GPT-4 Technical Report. https://openai.com/index/gpt-4-technical-report/
- raw/2026-06-23-decodingai-09-multimodal-agents.md
