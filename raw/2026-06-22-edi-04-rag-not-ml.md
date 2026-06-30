---
title: "RAG Is Not Machine Learning, and the ML Toolkit Solves the Wrong Problem"
aliases: [edi-rag-not-ml, rag-engineering-not-ml]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, ml, engineering, evaluation, per-failure-mode]
updated: 2026-06-30
source_url: https://towardsdatascience.com/rag-is-not-machine-learning-and-the-ml-toolkit-solves-the-wrong-problem/
source_type: article
ingested: 2026-06-22
feeds: [retrieval-augmented-generation, ai-evaluation-and-quality]
---

# RAG Is Not Machine Learning, and the ML Toolkit Solves the Wrong Problem

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** June 1, 2026 · **URL:** https://towardsdatascience.com/rag-is-not-machine-learning-and-the-ml-toolkit-solves-the-wrong-problem/

## Key takeaways

- RAG answers factual questions where "the answer exists, written on page one of the document, or it doesn't." Unlike ML, every wrong answer is "a bug" with a traceable root cause — not statistical noise.
- Three ML approaches that misfire in RAG:
  1. **Hyperparameter sweeping** (chunk size, overlap, threshold) — these are routing/domain decisions, not tunable parameters. Fix: route question types to different retrieval strategies.
  2. **Train/test splits** — "there is nothing to generalize." Evaluate instead: corpus coverage (does answer exist?) + retrieval quality (did we find it?) + generation fidelity (did model stay faithful?).
  3. **ML explainability** (SHAP, attention) — RAG is inherently explainable through citations. "Citation is part of the answer, not an analysis layer."
- Two-part failure diagnosis: retrieve then check if correct passage was in context. Yes → LLM failure. No → search engine failure. Fix accordingly.
- "The single most expensive misconception in enterprise RAG today" — applying ML frameworks to what is fundamentally an engineering problem.
- Per-failure-mode metrics replace aggregate accuracy: retrieval recall, answer faithfulness, extraction accuracy.
- Teams shift: from ML researchers → software engineers + domain experts + IR specialists.
- Tools shift: from PyTorch/clusters → parsers, retrievers, logging systems.

## Notable claims (with location)

- Failure case study: team spent six months tuning embeddings and chunk sizes; actual problem was OCR degradation in 30% of documents. A two-day parser review would have caught it.
- Example fix: wrong Transformer architecture answer — retrieval returned pages 4,7,8 instead of 5. Fix: require co-occurrence of `base`, `model`, `heads` on same lines — five-line code change, not a reranker.

## Key visuals

Localized to `raw/assets/2026-06-22-edi-04-rag-not-ml/` (1 diagram, visual backfill 2026-06-30; the sklearn decision-tree example was dropped).

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | Six-month timeline: ML optimization vs. corpus-level bug fixes | |

## Feeds these wiki pages

- [[retrieval-augmented-generation]]
- [[ai-evaluation-and-quality]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
