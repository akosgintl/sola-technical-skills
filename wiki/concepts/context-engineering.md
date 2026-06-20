---
title: Context Engineering
aliases: [context window management, prompt context design]
type: concept
domain: ai-agentic
status: seed
tags: [ai-agentic, llm, context]
updated: 2026-06-20
sources: [raw/recursive-language-models-decodingai.md]
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

## Three patterns for large inputs

When input exceeds what fits cleanly in a context window, there are three approaches — each with distinct infrastructure cost and quality profile:

| Pattern | Mechanism | Infrastructure cost | Latency | Quality risk |
|---|---|---|---|---|
| Context stuffing (CAG) | Load everything into one call | None | Low | Context rot at long lengths |
| RAG | Retrieve relevant chunks via embeddings | High (vector DB, chunking pipeline, retrieval eval) | Medium | Retrieval misses; zigzag query patterns |
| [[recursive-language-models\|RLMs]] | Model navigates data as external REPL variable | Low (just a sandboxed runtime) | High/variable | Code fragility; error propagation |

RLMs represent a shift from *manual* context curation to *programmatic* curation: the model itself decides what to read, filter, and summarize on each turn. See [[recursive-language-models]] for the full treatment.

## See also

- [[llm-application-architecture]]
- [[retrieval-augmented-generation]]
- [[recursive-language-models]]
- [[agent-memory-architectures]]
- [[model-selection-and-routing]]

## Sources

- Iusztin, P. (2026-04-07). Your RAG Pipeline Is Overkill. Decoding AI. https://www.decodingai.com/p/recursive-language-models
- Anthropic. (n.d.). Effective Context Engineering for AI Agents. https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
