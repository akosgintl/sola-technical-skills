---
title: Model Selection and Routing
aliases: [model routing, LLM routing]
type: concept
domain: ai-agentic
status: stub
tags: [ai-agentic, llm, routing, cost]
updated: 2026-06-19
sources: []
---

# Model Selection and Routing

> [!summary]
> Choosing and dynamically routing between models to balance cost, latency, and quality — including fallback chains and the strategic call between prompting, RAG, and fine-tuning.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Model selection and routing is the practice of matching each request to the cheapest model that meets quality needs, and falling back when a model fails or refuses. A router may classify difficulty, send easy queries to small/cheap models and hard ones to frontier models, and chain fallbacks for reliability. At the design level it also frames the prompt-vs-RAG-vs-fine-tune trade-off for achieving a given capability.

## Key concepts

- Cost / latency / quality trade-offs
- Difficulty-based routing and cascades
- Fallback and retry chains
- Prompt vs. RAG vs. fine-tune decision
- Model evaluation for selection

## See also

- [[llm-application-architecture]]
- [[ai-evaluation-and-quality]]
- [[ai-gpu-economics]]
- [[context-engineering]]
- [[retrieval-augmented-generation]]

## Sources

- _Stub — no sources ingested yet._
