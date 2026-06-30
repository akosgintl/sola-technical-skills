---
title: "Baseline Enterprise RAG: From PDF to Highlighted Answer"
aliases: [edi-baseline-rag, vol-1-1]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, enterprise, baseline, keyword-retrieval, structured-output]
updated: 2026-06-30
source_url: https://towardsdatascience.com/baseline-enterprise-rag-from-pdf-to-highlighted-answer-enterprise-document-intelligence-vol-1-1/
source_type: article
ingested: 2026-06-22
feeds: [retrieval-augmented-generation, llm-application-architecture]
---

# Baseline Enterprise RAG: From PDF to Highlighted Answer

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** May 29, 2026 · **URL:** https://towardsdatascience.com/baseline-enterprise-rag-from-pdf-to-highlighted-answer-enterprise-document-intelligence-vol-1-1/

## Key takeaways

- ~100-line minimal pipeline: PyMuPDF → keyword extraction (LLM) → page ranking (keyword count) → structured generation (Pydantic) → PDF annotation.
- Keyword matching chosen over embeddings initially: "Cosine similarity returns 0.7798 and asks the user to trust it." Keywords allow auditing why pages were selected.
- `AnswerWithEvidence` Pydantic schema enforces: start/end page+line, confidence, justification, direct quote, caveats, null-path (`complete_answer_found: false`).
- "I don't know" is a feature: null path more valuable than padding with unreliable answers.
- Exposed limitation driving future articles: symbol/vocabulary mismatch — query for "epsilon" fails when document uses Greek letter `ε`.
- Enterprise docs are often 300+ pages; retrieval (not "throw it all in") enables corpus-scale operation.

## Notable claims (with location)

- Academic papers align with pages; contracts align with clauses — no single chunking strategy works universally.
- Question parsing deserves its own brick: extracting keywords separately from retrieval keeps concerns separated.
- Minimal stack: PyMuPDF, OpenAI SDK (swappable), Pandas, Pydantic — no vector databases or RAG libraries.
- Schema-enforced citations prevent hallucination: Pydantic validation forces real `(page, line)` references.

## Key visuals

Localized to `raw/assets/2026-06-22-edi-01-baseline-rag/` (3 diagrams, visual backfill 2026-06-30; dataframe/PDF-page screenshots dropped).

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | Baseline RAG pipeline end-to-end | [[retrieval-augmented-generation]] |
| `…-02.png` | PDF annotation in three steps | |
| `…-03.png` | The minimal pipeline as rung one of five | |

## Feeds these wiki pages

- [[retrieval-augmented-generation]]
- [[llm-application-architecture]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
