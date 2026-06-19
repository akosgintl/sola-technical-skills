---
title: Context Engineering
aliases: [context window management, prompt context design]
type: concept
domain: ai-agentic
status: stub
tags: [ai-agentic, llm, context]
updated: 2026-06-19
sources: []
---

# Context Engineering

> [!summary]
> The discipline of deciding what information enters a model's context window, in what form and order, and how to budget, compress, and prune it for relevance, cost, and quality.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Context engineering is the practice of curating the limited context window a model sees on each call. It covers selecting and ordering retrieved chunks, compressing or summarizing history, pruning stale or low-value tokens, and balancing how much context to include against latency and cost. As windows grow, the bottleneck shifts from capacity to signal-to-noise: more context is not automatically better.

## Key concepts

- Context window budgeting
- Compression and summarization
- Relevance selection and ordering
- Pruning and eviction strategies
- Cost/latency trade-offs of context size

## See also

- [[llm-application-architecture]]
- [[retrieval-augmented-generation]]
- [[agent-memory-architectures]]
- [[model-selection-and-routing]]

## Sources

- _Stub — no sources ingested yet._
