---
title: Retrieval-Augmented Generation
aliases: [RAG, retrieval augmented generation, retrieval-augmented generation]
type: concept
domain: ai-agentic
status: mature
tags: [llm, retrieval, vector-search, rag, grounding, reranking, graphrag, embeddings]
updated: 2026-06-19
sources:
  - "https://www.anthropic.com/news/contextual-retrieval"
  - "https://www.microsoft.com/en-us/research/project/graphrag/"
  - "https://dev.to/young_gao/rag-is-not-dead-advanced-retrieval-patterns-that-actually-work-in-2026-2gbo"
  - "https://www.digitalapplied.com/blog/hybrid-search-bm25-vector-reranking-reference-2026"
  - "https://blog.premai.io/rag-evaluation-metrics-frameworks-testing-2026/"
  - "https://medium.com/@officialpreksha2166/rag-vs-fine-tuning-vs-long-context-when-to-use-what-and-why-most-teams-get-it-wrong-388cc446ff3c"
  - "https://docs.anthropic.com/en/docs/build-with-claude/citations"
---

# Retrieval-Augmented Generation

> [!summary]
> **RAG** grounds an LLM's output in an external corpus retrieved at query time, rather than relying solely on parametric (trained-in) knowledge. The classic pipeline is *chunk → embed → retrieve → (rerank) → generate with citations*. The naive version of that pipeline is a commodity; the value has moved up-stack to the hard parts: **retrieval quality** (hybrid search, contextual chunking, late-interaction rerankers), **agentic/iterative retrieval** loops, **GraphRAG** for multi-hop and global questions, faithful **citation/attribution**, and the strategic call of **RAG vs. long-context vs. fine-tuning**. RAG is not a model feature — it is a *system* whose quality is dominated by the retrieval layer, not the generator.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

RAG decouples *knowledge* from the *model*. Instead of baking facts into weights, you keep them in an external store and inject the relevant slice into the prompt at inference time. This buys three properties a base model cannot give you: **freshness** (update the corpus, not the model), **provenance** (you can cite the source span), and **governance** (source data stays separable, access-controlled, and deletable — which matters for GDPR, audit, and tenancy).

The canonical flow:

1. **Ingest & chunk** — split source documents into retrievable units.
2. **Embed** — map each chunk to a dense (and/or sparse) vector via an embedding model.
3. **Index** — store vectors in a [[vector-and-embedding-stores|vector store]] with metadata for filtering.
4. **Retrieve** — embed the query, fetch top-k nearest chunks (often dense + keyword in parallel).
5. **Rerank** — a heavier cross-encoder/late-interaction model reorders candidates for precision.
6. **Generate** — the LLM answers *grounded* in the retrieved context, ideally with inline citations.

Every stage is a design surface. The difference between a demo and a production system lives almost entirely in stages 1, 4, and 5 — the retrieval, not the generation.

## Why it matters

Three reasons to invest here over chasing the latest model:

- **Retrieval is the dominant error source.** Most "hallucinations" in a RAG system are actually *retrieval failures* — the right chunk was never fetched, so the model confabulated. Anthropic's contextual-retrieval work reports that fixing the retrieval layer alone cut failures by ~49%, and ~67% with reranking added. You get more leverage from the retriever than from a bigger LLM.
- **It is the cheapest, most governable way to ground an LLM in proprietary data.** Long-context prompting is ~20–24× more expensive per query at scale and doesn't give you provenance; fine-tuning bakes knowledge in opaquely and goes stale. For dynamic, citable, access-controlled data, RAG is still the default. The "RAG is dead" claims that follow every long-context release have not survived contact with production economics.
- **RAG is the substrate for agents.** Agentic systems don't do one-shot retrieval — they *search, read, reason, re-search* in loops. RAG quality directly caps agent quality. See [[agentic-system-design]] and [[context-engineering]].

The common failure mode is treating RAG as a library call. It is a distributed retrieval system with its own SLOs, eval harness, and failure modes — closer in spirit to building search than to calling an API.

## Key concepts / building blocks

### Chunking
The most under-rated lever. Options, roughly in order of sophistication:

- **Fixed-size / sliding window** — simple, but slices sentences and destroys context across boundaries. A baseline, not a target state.
- **Recursive / structural** — split on document structure (headings, paragraphs, markdown, code blocks). The sane default.
- **Semantic chunking** — group sentences by embedding similarity so a chunk is one coherent idea.
- **Contextual retrieval (Anthropic, 2024)** — prepend a 50–100-token LLM-generated summary to each chunk situating it in its parent document *before* embedding. Cheap with prompt caching; one of the highest-ROI techniques available.
- **Late chunking** — embed the whole document first, then pool token embeddings into chunks, preserving cross-chunk context. Solves the same boundary problem as contextual retrieval from the other direction; which wins depends on the embedding model.

> [!tip] Chunk size is a recall/precision trade-off. Small chunks → precise matches but fragmented context. Large chunks → context but diluted vectors and wasted tokens. Tune against an eval set, never by intuition.

### Embeddings & retrieval
- **Dense (semantic)** — captures meaning; misses exact identifiers, SKUs, error codes, rare terms.
- **Sparse / lexical (BM25)** — exact keyword match; strong precisely where dense fails.
- **Hybrid** — run both, fuse scores (Reciprocal Rank Fusion is the workhorse). Hybrid is the assumed baseline, not an enhancement; dense-only retrieval is an anti-pattern for enterprise corpora full of identifiers.
- **Multi-vector / late interaction (ColBERT)** — encode query and document as *token-level* embeddings and score with a MaxSim operator at search time. Document vectors precompute and cache; often beats dense+cross-encoder outright on identifier-heavy queries, at higher storage cost.

### Reranking
A two-stage pattern: cheap retriever pulls top ~50–100 candidates, then a heavier model reorders for precision. This is where most precision gains come from.

- **Cross-encoders** — jointly encode query+chunk for maximum accuracy; can't be precomputed, so latency scales with candidate count (hence the two-stage design).
- **Commercial rerankers** — Cohere Rerank and Voyage `rerank-2.5` (the latter adds *instruction-following*: steer relevance with a natural-language instruction). Open-source alternatives (e.g. ZeroEntropy, BGE) have closed much of the gap.

### Citation & attribution
- **Inline generation** — citations emitted *during* generation are far more faithful than citations bolted on afterward.
- **API-level provenance** — Anthropic's Citations API returns character-level spans into source documents; treat structured, span-level attribution as a design requirement for any regulated use case, not a nicety.
- Citation does not eliminate hallucination — a model can cite a real source and still misstate it — so attribution must be *verified*, not assumed. Couple it with [[guardrails-and-output-validation]].

## Design decisions & trade-offs

| Decision | The real trade-off |
|---|---|
| **Chunk size & strategy** | Recall vs. precision vs. token cost. Contextual/late chunking adds ingest cost to buy retrieval quality. |
| **Dense vs. hybrid vs. late-interaction** | Semantic recall vs. exact-match precision vs. storage/latency. Hybrid is the safe default; ColBERT for identifier-heavy domains. |
| **Rerank or not** | Biggest single precision lever, but adds latency + per-call cost (esp. commercial APIs). Almost always worth it above toy scale. |
| **One-shot vs. agentic retrieval** | Latency/cost/complexity vs. answer quality on multi-hop questions. Iterative loops can 2–4× quality but blow latency and token budgets. |
| **Flat vector RAG vs. GraphRAG** | GraphRAG wins "global"/multi-hop questions but historically carried heavy indexing cost (early Microsoft GraphRAG could run to tens of thousands of dollars in tokens on large corpora; newer variants like LazyGraphRAG cut this sharply). Don't reach for it until flat RAG demonstrably fails. |
| **RAG vs. long-context vs. fine-tuning** | See below — usually not exclusive. |

### RAG vs. long-context vs. fine-tuning
The most common strategic question, and most teams get it wrong by treating it as either/or. The current consensus:

- **RAG** when knowledge is large, dynamic, must be cited, or must stay governable/separable from the model. Default first choice for Q&A over proprietary data.
- **Fine-tuning** when you need *behavior* — voice, format, decision policy, structured output — not new facts; or when a fine-tuned small model is dramatically cheaper at high volume. "Fine-tune for how the model behaves, RAG for what it knows."
- **Long-context** for prototyping and small/medium static corpora. ~20–24× the per-query cost of RAG at scale; great shortcut, poor production architecture past a few hundred pages.
- **Hybrid is the mature answer:** retrieval for facts + fine-tuning for style/policy. ~60% of production systems combine approaches. See [[model-selection-and-routing]].

> [!warning] "Just use a 1M-token window" is a prototyping convenience, not an architecture. It does not give provenance, blows the cost budget at volume, and degrades on retrieval-in-the-middle. Long context complements RAG (fewer, richer chunks) — it does not replace it.

## State of the art

- **Contextual retrieval is mainstream.** Prepending LLM-generated chunk context before embedding, combined with hybrid search and reranking, is the strong baseline — not an exotic technique.
- **Agentic / iterative RAG is the dominant enterprise pattern.** Retrieval is embedded *inside* the model's reasoning loop: the agent decides *when* and *what* to retrieve, critiques its own evidence, and re-queries when confidence is low. Self-RAG (learned reflection tokens for adaptive retrieval) and Corrective RAG / CRAG (evaluate retrieved docs, take corrective action — e.g. web fallback — when they're weak) are the reference patterns. Reported gains: faithfulness ~0.95 vs. ~0.79 for naive RAG. This is RAG converging with [[agentic-system-design]] and [[multi-agent-orchestration]].
- **GraphRAG matured past its cost problem.** Microsoft's GraphRAG (entity/relationship extraction → Leiden community detection → hierarchical summaries) answers *global* and *multi-hop* questions flat RAG can't, with large accuracy gains on those query classes. The 2025–26 wave (ROGRAG, agentic graph-search workflows, structure-aware expansion) attacked the indexing cost that made the original impractical.
- **Late-interaction (ColBERT-family) rerankers** feel near-instant because document representations precompute, and win on identifier-heavy retrieval; supported natively in stores like Qdrant and LanceDB.
- **Instruction-following rerankers** (Voyage `rerank-2.5`) let you steer relevance judgments with natural-language instructions per query.
- **Eval moved from vibes to panels.** RAGAS is the de-facto starting framework — its four-metric panel (**faithfulness, answer relevancy, context precision, context recall**) gives diagnostic coverage of the common failure modes, and crucially separates *retrieval* metrics from *generation* metrics so you know which half to fix. DeepEval adds CI/CD integration; TruLens, Langfuse, and Patronus cover production tracing, hallucination, and bias. The discipline: evaluate retrieval and generation independently, on a versioned golden set, in the pipeline. See [[ai-evaluation-and-quality]].

## Pitfalls & anti-patterns

- **Blaming the LLM for retrieval failures.** If the right chunk wasn't retrieved, no model can answer faithfully. Instrument and evaluate retrieval *first* (context recall/precision), in isolation.
- **Dense-only retrieval on enterprise data.** Semantic vectors miss exact identifiers, codes, names. Always pair with lexical/BM25 (hybrid).
- **Naive fixed-size chunking** that severs context across boundaries — then wondering why answers are fragmented. Use structural/semantic/contextual chunking.
- **Skipping the reranker** to save latency, leaving the highest-precision lever on the table.
- **Trusting citations without verifying them.** A cited answer can still be wrong; attribution must be checked at claim level, not assumed.
- **No evaluation harness.** "It looked good in the demo" is not a quality bar. Without a golden set and a metric panel, every change is a guess.
- **Reaching for GraphRAG / full agentic loops prematurely.** They add real cost and latency. Exhaust hybrid + contextual + rerank before escalating complexity.
- **Stale index / silent corpus drift.** RAG's freshness advantage evaporates if ingestion lags. Treat the index as a pipeline with its own SLOs and lineage — see [[ai-data-fabric]].
- **Ignoring access control at retrieval time.** Multi-tenant RAG must filter by entitlement *before* generation, or you leak data across tenants.

## See also

- [[vector-and-embedding-stores]]
- [[ai-data-fabric]]
- [[context-engineering]]
- [[llm-application-architecture]]
- [[model-selection-and-routing]]
- [[ai-evaluation-and-quality]]
- [[guardrails-and-output-validation]]
- [[agentic-system-design]]

## Sources

- [Anthropic — Introducing Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval)
- [Microsoft Research — Project GraphRAG](https://www.microsoft.com/en-us/research/project/graphrag/)
- [Anthropic — Citations API docs](https://docs.anthropic.com/en/docs/build-with-claude/citations)
- [RAG Is Not Dead: Advanced Retrieval Patterns That Actually Work in 2026 (DEV)](https://dev.to/young_gao/rag-is-not-dead-advanced-retrieval-patterns-that-actually-work-in-2026-2gbo)
- [Hybrid Search: BM25, Vector & Reranking 2026 (Digital Applied)](https://www.digitalapplied.com/blog/hybrid-search-bm25-vector-reranking-reference-2026)
- [RAG Evaluation: Metrics, Frameworks & Testing 2026 (Prem AI)](https://blog.premai.io/rag-evaluation-metrics-frameworks-testing-2026/)
- [RAG vs Fine-tuning vs Long Context: When to Use What (Medium)](https://medium.com/@officialpreksha2166/rag-vs-fine-tuning-vs-long-context-when-to-use-what-and-why-most-teams-get-it-wrong-388cc446ff3c)
- [Next-Generation Agentic RAG with LangGraph, 2026 Edition (Medium)](https://medium.com/@vinodkrane/next-generation-agentic-rag-with-langgraph-2026-edition-d1c4c068d2b8)
- [Open-source alternatives to Cohere Rerank in 2026 (ZeroEntropy)](https://zeroentropy.dev/articles/open-source-alternatives-to-cohere-rerank/)
