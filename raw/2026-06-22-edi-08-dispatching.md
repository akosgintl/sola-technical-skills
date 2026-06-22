---
title: "Dispatching the Parsed RAG Question: Chunk Strategy, Model Tier, Activations, Audit"
aliases: [edi-dispatching, rag-dispatcher]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, dispatching, routing, model-selection, audit]
updated: 2026-06-22
source_url: https://towardsdatascience.com/dispatching-the-parsed-rag-question-chunk-strategy-model-tier-activations-audit/
source_type: article
ingested: 2026-06-22
feeds: [rag-query-understanding, retrieval-augmented-generation]
---

# Dispatching the Parsed RAG Question: Chunk Strategy, Model Tier, Activations, Audit

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** June 18, 2026 · **URL:** https://towardsdatascience.com/dispatching-the-parsed-rag-question-chunk-strategy-model-tier-activations-audit/

## Key takeaways

- Dispatcher uses parsed question + document profile to make three routing decisions:
  1. **Context/chunk strategy**: `detection_context` (line/paragraph for regex confirmation), `answer_context` (line/paragraph/page/section/chapter/document), `chunk_strategy` (sequential for single facts vs. combined for synthesized answers).
  2. **Model tier**: cascading defaults — concept-level > type-level > project fallback. Four conceptual tiers: nano/mini/standard/reasoning.
  3. **Activation flags**: document-aware downgrades prevent high-confidence wrong answers (e.g., Word docs disable `extract_page_numbers` since page breaks are renderer-dependent).
- Three approaches to deciding activations: A = user explicit (debugging), B = deterministic dispatcher (code reads parsed question + doc profile, **recommended**), C = LLM autonomous (rejected for enterprise — reproducibility concerns).
- `_meta` audit block captures: decomposition pattern, activation states, skip reasons, iterations, retrieval methods, model, prompt versions — full traceability.
- Full ParsedQuestion schema includes: original + corrected question, keywords (direct/anchor/LLM-expanded/expert-dictionary), answer shape+type, decomposition pattern, scope filters, structural hints, dispatch decisions, activations, parsing notes, plus RetrievalQuery and GenerationBrief consumer briefs.
- Satellite tables: `llm_model_tiers_df` (conceptual groupings), `llm_models_df` (specific registry with pricing, latency, context windows).
- "A pipeline that tunes embedding models and chunk sizes but routes the raw user string to every brick is leaving most of its quality on the table."
- Rejects agentic RAG for enterprise: "reproducibility, auditability, and cost boundaries" require deterministic routing from structured parsing, not runtime LLM routing decisions.

## Notable claims (with location)

- Production results (broker corpus): parsing latency 280ms average; 91% vs. 76% accuracy with/without parsing (+15 points).

## Feeds these wiki pages

- [[rag-query-understanding]]
- [[retrieval-augmented-generation]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
