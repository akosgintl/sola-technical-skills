---
title: Retrieval-Augmented Generation
aliases: [RAG, retrieval augmented generation, retrieval-augmented generation]
type: concept
domain: ai-agentic
status: mature
tags: [llm, retrieval, vector-search, rag, grounding, reranking, graphrag, embeddings, question-parsing, enterprise]
updated: 2026-06-22
sources:
  - "https://www.anthropic.com/news/contextual-retrieval"
  - "https://www.microsoft.com/en-us/research/project/graphrag/"
  - "https://dev.to/young_gao/rag-is-not-dead-advanced-retrieval-patterns-that-actually-work-in-2026-2gbo"
  - "https://www.digitalapplied.com/blog/hybrid-search-bm25-vector-reranking-reference-2026"
  - "https://blog.premai.io/rag-evaluation-metrics-frameworks-testing-2026/"
  - "https://medium.com/@officialpreksha2166/rag-vs-fine-tuning-vs-long-context-when-to-use-what-and-why-most-teams-get-it-wrong-388cc446ff3c"
  - "https://docs.anthropic.com/en/docs/build-with-claude/citations"
  - "https://towardsdatascience.com/document-intelligence-a-series-on-building-rag-brick-by-brick-from-minimal-to-corpus-scale/"
  - "https://towardsdatascience.com/baseline-enterprise-rag-from-pdf-to-highlighted-answer-enterprise-document-intelligence-vol-1-1/"
  - "https://towardsdatascience.com/embeddings-arent-magic-the-predictable-failure-modes-of-rag-retrieval-enterprise-document-intelligence-vol-1-2/"
  - "https://towardsdatascience.com/rerankers-arent-magic-either-when-the-cross-encoder-layer-is-worth-the-cost-enterprise-document-intelligence-vol-1-2bis/"
  - "https://towardsdatascience.com/rag-is-not-machine-learning-and-the-ml-toolkit-solves-the-wrong-problem/"
  - "https://towardsdatascience.com/from-regex-to-vision-models-which-rag-technique-fits-which-problem/"
  - "https://towardsdatascience.com/question-parsing-in-rag-structure-before-you-search/"
  - "https://towardsdatascience.com/what-the-question-parser-extracts-from-a-user-string-keywords-scope-shape-decomposition-clarification/"
  - "https://towardsdatascience.com/dispatching-the-parsed-rag-question-chunk-strategy-model-tier-activations-audit/"
  - "https://towardsdatascience.com/when-rag-users-ask-vague-questions-clarify-once-learn-the-default/"
---

# Retrieval-Augmented Generation

> [!summary]
> **RAG** grounds an LLM's output in an external corpus retrieved at query time, rather than relying solely on parametric (trained-in) knowledge. The naive pipeline — *chunk → embed → retrieve → (rerank) → generate with citations* — is a commodity; the value has moved up-stack. For **enterprise production**, the hard parts are: **question parsing** (structuring queries into retrieval and generation briefs before searching), **retrieval quality** (expert keyword dictionaries + hybrid search over vector-only), a **diagnostic grid** that matches technique to document type, faithful **citation/attribution**, and the strategic call of **RAG vs. long-context vs. fine-tuning**. RAG is not a model feature — it is a *system* whose quality is dominated by the retrieval layer, not the generator, and whose failure modes are engineering problems with traceable root causes, not ML optimization targets.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

RAG decouples *knowledge* from the *model*. Instead of baking facts into weights, you keep them in an external store and inject the relevant slice into the prompt at inference time. This buys three properties a base model cannot give you: **freshness** (update the corpus, not the model), **provenance** (you can cite the source span), and **governance** (source data stays separable, access-controlled, and deletable — which matters for GDPR, audit, and tenancy).

A useful distinction: **augmented** vs. **grounded**. The original 2020 academic RAG *blends* retrieved passages with the model's parametric knowledge. In regulated enterprise production, the stricter requirement is *grounded* generation: every factual claim must be backed by a retrieved passage; the model's parametric memory is excluded from factual content. This is not just a style choice — it is the only design that enables span-level attribution and audit trails in legal, insurance, and financial contexts.

The canonical four-brick flow:

1. **Ingest & parse** — split source documents into retrievable units with structure preserved (lines, tables, sections, TOC, bounding boxes).
2. **Question parse** — transform the user's string into a structured brief before touching retrieval: extract keywords (from user input, LLM rewrites, expert dictionaries, anchor regex), infer answer shape and type, scope hints, decomposition pattern, and two consumer briefs (RetrievalQuery / GenerationBrief). See [[rag-query-understanding]].
3. **Embed & index** — map chunks to dense (and/or sparse) vectors via an embedding model; store in a [[vector-and-embedding-stores|vector store]] with metadata for filtering.
4. **Retrieve** — cascade: structure/TOC → keyword/expert-dict → hybrid (dense + BM25) → optional rerank. Use the RetrievalQuery brief, not the raw user string.
5. **Rerank** — a heavier cross-encoder/late-interaction model reorders candidates; worth doing when signal dilution is the failure mode, not the default first lever.
6. **Generate** — the LLM answers *grounded* in the retrieved context using the GenerationBrief (original wording, format constraints, disambiguation cues, distractors), emitting inline citations.

Every stage is a design surface. The difference between a demo and a production system lives almost entirely in stages 1, 2, and 4 — parsing and retrieval, not generation.

## Why it matters

Three reasons to invest here over chasing the latest model:

- **Retrieval is the dominant error source.** Most "hallucinations" in a RAG system are actually *retrieval failures* — the right chunk was never fetched, so the model confabulated. Anthropic's contextual-retrieval work reports that fixing the retrieval layer alone cut failures by ~49%, and ~67% with reranking added. You get more leverage from the retriever than from a bigger LLM.
- **It is the cheapest, most governable way to ground an LLM in proprietary data.** Long-context prompting is ~20–24× more expensive per query at scale and doesn't give you provenance; fine-tuning bakes knowledge in opaquely and goes stale. For dynamic, citable, access-controlled data, RAG is still the default. The "RAG is dead" claims that follow every long-context release have not survived contact with production economics.
- **RAG is the substrate for agents.** Agentic systems don't do one-shot retrieval — they *search, read, reason, re-search* in loops. RAG quality directly caps agent quality. See [[agentic-system-design]] and [[context-engineering]].

The common failure mode is treating RAG as a library call — or worse, as a machine-learning optimization problem. It is a **search engineering** problem: every wrong answer is a bug with a traceable root cause (parser degradation, vocabulary gap, ranking error), not statistical noise to minimize in aggregate. This has practical consequences: don't sweep chunk sizes as hyperparameters; instead, trace failed queries to the exact stage that failed and fix it. Don't apply train/test splits; instead, measure corpus coverage, retrieval recall, and generation faithfulness separately per query type.

## Key concepts / building blocks

### Chunking

The most under-rated lever. Options, roughly in order of sophistication:

- **Fixed-size / sliding window** — simple, but slices sentences and destroys context across boundaries. A baseline, not a target state.
- **Recursive / structural** — split on document structure (headings, paragraphs, markdown, code blocks). The sane default.
- **Semantic chunking** — group sentences by embedding similarity so a chunk is one coherent idea.
- **Contextual retrieval (Anthropic, 2024)** — prepend a 50–100-token LLM-generated summary to each chunk situating it in its parent document *before* embedding. Cheap with prompt caching; one of the highest-ROI techniques available.
- **Late chunking** — embed the whole document first, then pool token embeddings into chunks, preserving cross-chunk context. Solves the same boundary problem as contextual retrieval from the other direction; which wins depends on the embedding model.

> [!tip] Chunk size is a recall/precision trade-off. Small chunks → precise matches but fragmented context. Large chunks → context but diluted vectors and wasted tokens. Tune against an eval set, never by intuition. Route different question types to different chunk granularities rather than picking one global size.

### Expert keyword dictionaries

The most underused enterprise lever. Vector embeddings surface candidate synonyms; domain experts validate and codify them into dictionaries (`deductible ↔ excess, franchise`; `blood sugar ↔ A1C, HbA1c`; `force majeure ↔ act of God, unforeseeable circumstances`). Production retrieval then runs against dictionaries using keyword search — fast, auditable, zero latency vs. embedding lookup.

This beats embedding-only approaches because: (1) enterprise OOV terms (internal product codes, regulatory citations, field-specific jargon) simply lack web-scale training data; (2) dictionaries are human-readable and auditable; (3) adding a synonym is a row insertion, not a retraining run. The discovery phase still uses embeddings — validate then codify, don't embed in production.

### Embeddings & retrieval

- **Dense (semantic)** — captures meaning; misses exact identifiers, SKUs, error codes, rare terms.
- **Sparse / lexical (BM25)** — exact keyword match; strong precisely where dense fails.
- **Hybrid** — run both, fuse scores (Reciprocal Rank Fusion is the workhorse). Hybrid is the assumed baseline, not an enhancement; dense-only retrieval is an anti-pattern for enterprise corpora full of identifiers.
- **Multi-vector / late interaction (ColBERT)** — encode query and document as *token-level* embeddings and score with a MaxSim operator at search time. Document vectors precompute and cache; often beats dense+cross-encoder outright on identifier-heavy queries, at higher storage cost.
- **Line-level embedding** — embedding full pages as single vectors dilutes answer-bearing content in surrounding noise. For enterprise corpora, embed at line or paragraph level; aggregate to page only for generation context.

**Six structural embedding failure modes** that fine-tuning cannot fix:

| Failure mode | What happens | Fix |
|---|---|---|
| OOV terms | Internal product codes, regulatory citations rank below random text | Expert keyword dictionary |
| Q-A mismatch | Topical similarity ≠ answer relevance ("capital of France?" ranks "capital" passages over "Paris") | Route through question parsing; separate topic from expected answer |
| Negation blindness | "NOT a city" pulls city passages closer; "not the deductible" worsens results | Keep negations in GenerationBrief, not RetrievalQuery |
| Magnitude blindness | "value greater than 1M" ranks "1M" first, "3B" (correct) last | Regex confirmation on typed answer fields |
| Procedure over answer | Dense text about procedures outranks the actual answer line | Line-level embedding; structural retrieval |
| Signal dilution | Embedding a 300-500 word page buries answer-bearing lines | Embed line/paragraph level |

### Reranking

A two-stage pattern: cheap retriever pulls top ~50–100 candidates, then a heavier model reorders for precision.

- **Cross-encoders** — jointly encode query+chunk for maximum accuracy; can't be precomputed, so latency scales with candidate count (hence the two-stage design).
- **Commercial rerankers** — Cohere Rerank and Voyage `rerank-2.5` (the latter adds *instruction-following*: steer relevance with a natural-language instruction). Open-source alternatives (e.g. ZeroEntropy, BGE) have closed much of the gap.

**When rerankers help:** the clearest win is signal dilution — when correct answers are buried in topically noisy pages, cross-encoders reliably recover them. Yes/no question ranking also improves with ms-marco-trained models.

**When rerankers don't:** negation (no learned signal for logical complementation), exact identifiers (need exact-match indexing, not similarity scoring), listing queries (need aggregation pipelines, not ranking), OOV vocabulary (outside training distributions). Empirically, on 4 of 5 expected reranker-win scenarios, strong embedding models match or beat cross-encoders — and the cost-performance curve sometimes inverts (larger rerankers rank correct synonyms below distractors). The marginal dollar invests better in expert keyword dictionaries, question parsing, or classify-before-retrieve (narrowing 200K documents to ~800 before any scoring) than in an additional ranking layer.

### Citation & attribution

- **Inline generation** — citations emitted *during* generation are far more faithful than citations bolted on afterward.
- **Structured output schemas** — enforce typed citations (start/end page + line, confidence, direct quote, caveat) via Pydantic; null fields allow honest "not found" responses. "I don't know" expressed as `complete_answer_found: false` is more valuable than a padded, unreliable answer.
- **API-level provenance** — Anthropic's Citations API returns character-level spans into source documents; treat structured, span-level attribution as a design requirement for any regulated use case, not a nicety.
- Citation does not eliminate hallucination — a model can cite a real source and still misstate it — so attribution must be *verified*, not assumed. Couple it with [[guardrails-and-output-validation]].

## Design decisions & trade-offs

| Decision | The real trade-off |
|---|---|
| **Chunk size & strategy** | Recall vs. precision vs. token cost. Contextual/late chunking adds ingest cost to buy retrieval quality. Route question types to different granularities rather than picking one global size. |
| **Dense vs. hybrid vs. expert-dict vs. late-interaction** | Semantic recall vs. exact-match precision vs. auditability vs. storage/latency. Hybrid is the safe default; expert dictionaries for domain-specific enterprise corpora; ColBERT for identifier-heavy domains. |
| **Rerank or not** | Clear win for signal-dilution scenarios; marginal or negative elsewhere. Invest upstream (question parsing, classify-before-retrieve) before adding a reranker. |
| **One-shot vs. agentic retrieval** | Latency/cost/complexity vs. answer quality on multi-hop questions. Iterative loops can 2–4× quality but blow latency and token budgets. |
| **Flat vector RAG vs. GraphRAG** | GraphRAG wins "global"/multi-hop questions but historically carried heavy indexing cost (early Microsoft GraphRAG could run to tens of thousands of dollars in tokens on large corpora; newer variants like LazyGraphRAG cut this sharply). Don't reach for it until flat RAG demonstrably fails. |
| **Diagnostic grid: document type × question type** | Match technique to problem before writing code. Fixed-template docs + controlled questions → regex, no LLM. Heterogeneous structured + free queries → full retrieval pipeline. Visually rich → vision models. Running the classic playbook on fixed-template documents is wasteful; skipping it on heterogeneous corpora is broken. |
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
- **Question parsing is the overlooked production differentiator.** Structuring the user's string into a typed ParsedQuestion before retrieval — extracting keywords (from user input, LLM rewrites, expert dictionaries), answer shape and type, scope hints, and decomposition patterns — and then splitting into separate RetrievalQuery and GenerationBrief consumer briefs, delivers +15 percentage-point accuracy gains in measured production deployments. Teams that route the raw user string to every pipeline stage leave most of their quality on the table before retrieval has even started. See [[rag-query-understanding]].
- **Expert keyword dictionaries as primary retrieval layer.** The enterprise production pattern is: run embeddings to discover candidate synonyms → expert validation → codify into dictionaries → production retrieval uses keyword search. This is faster, auditable, and more accurate on enterprise corpora than embedding-only retrieval.
- **Per-failure-mode evaluation** replaces aggregate metrics. Trace failed queries to the stage that failed: if the retrieved passages contained the answer, it's an LLM failure; if not, it's a retrieval failure. Break down by query type (conceptual, exact-reference, negation, listing, aggregation) rather than reporting a single recall number. A team that found their accuracy plateau was caused by OCR degradation in 30% of documents — not embeddings — would have caught it in one day with per-stage evaluation instead of six months of embedding tuning.
- **Agentic / iterative RAG is the dominant enterprise pattern.** Retrieval is embedded *inside* the model's reasoning loop: the agent decides *when* and *what* to retrieve, critiques its own evidence, and re-queries when confidence is low. Self-RAG (learned reflection tokens for adaptive retrieval) and Corrective RAG / CRAG (evaluate retrieved docs, take corrective action — e.g. web fallback — when they're weak) are the reference patterns. Reported gains: faithfulness ~0.95 vs. ~0.79 for naive RAG. This is RAG converging with [[agentic-system-design]] and [[multi-agent-orchestration]].
- **GraphRAG matured past its cost problem.** Microsoft's GraphRAG (entity/relationship extraction → Leiden community detection → hierarchical summaries) answers *global* and *multi-hop* questions flat RAG can't, with large accuracy gains on those query classes. The 2025–26 wave (ROGRAG, agentic graph-search workflows, structure-aware expansion) attacked the indexing cost that made the original impractical.
- **Late-interaction (ColBERT-family) rerankers** feel near-instant because document representations precompute, and win on identifier-heavy retrieval; supported natively in stores like Qdrant and LanceDB.
- **Instruction-following rerankers** (Voyage `rerank-2.5`) let you steer relevance judgments with natural-language instructions per query.
- **Eval moved from vibes to panels.** RAGAS is the de-facto starting framework — its four-metric panel (**faithfulness, answer relevancy, context precision, context recall**) gives diagnostic coverage of the common failure modes, and crucially separates *retrieval* metrics from *generation* metrics so you know which half to fix. DeepEval adds CI/CD integration; TruLens, Langfuse, and Patronus cover production tracing, hallucination, and bias. The discipline: evaluate retrieval and generation independently, on a versioned golden set, in the pipeline. See [[ai-evaluation-and-quality]].

## Pitfalls & anti-patterns

- **Blaming the LLM for retrieval failures.** If the right chunk wasn't retrieved, no model can answer faithfully. Instrument and evaluate retrieval *first* (context recall/precision), in isolation. Diagnose before spending on model upgrades.
- **Treating RAG as a machine-learning problem.** Sweeping chunk sizes as hyperparameters and applying train/test splits is category error. Wrong answers are bugs with traceable root causes, not statistical noise. Fix: trace failed queries end-to-end; route question types to different strategies instead of sweeping one global parameter.
- **Routing the raw user string to retrieval.** Embedding the user's full question — disambiguation cues, negations, format instructions, excluded terms and all — poisons retrieval. Parse the question first; send only the RetrievalQuery brief to the retriever.
- **Dense-only retrieval on enterprise data.** Semantic vectors miss exact identifiers, codes, names. Always pair with lexical/BM25 (hybrid).
- **Skipping expert keyword dictionaries.** Embedding fine-tuning cannot recover enterprise OOV terms; a week of expert validation delivers what months of training cannot. "Franchise = deductible" is not in web training data.
- **Naive fixed-size chunking** that severs context across boundaries — then wondering why answers are fragmented. Use structural/semantic/contextual chunking.
- **Defaulting to a reranker for every scenario.** Rerankers are worth the cost for signal dilution; they fail on negation, exact identifiers, and listing queries. Invest upstream first.
- **Trusting citations without verifying them.** A cited answer can still be wrong; attribution must be checked at claim level, not assumed.
- **No evaluation harness.** "It looked good in the demo" is not a quality bar. Without a golden set and per-failure-mode metrics, every change is a guess.
- **Applying the classic RAG playbook regardless of document type.** A fixed-template invoice corpus + engineer-controlled questions is a regex problem. A vision-rich schematic corpus is a vision model problem. Run the diagnostic grid first.
- **Reaching for GraphRAG / full agentic loops prematurely.** They add real cost and latency. Exhaust hybrid + contextual + rerank before escalating complexity.
- **Stale index / silent corpus drift.** RAG's freshness advantage evaporates if ingestion lags. Treat the index as a pipeline with its own SLOs and lineage — see [[ai-data-fabric]].
- **Ignoring access control at retrieval time.** [[multi-tenancy-architecture|Multi-tenant]] RAG must filter by entitlement *before* generation, or you leak data across tenants.

## See also

- [[rag-query-understanding]]
- [[vector-and-embedding-stores]]
- [[ai-data-fabric]]
- [[context-engineering]]
- [[llm-application-architecture]]
- [[model-selection-and-routing]]
- [[model-customization]]
- [[ai-evaluation-and-quality]]
- [[guardrails-and-output-validation]]
- [[agentic-system-design]]
- [[graphrag]]

## Sources

- [Anthropic — Introducing Contextual Retrieval](https://www.anthropic.com/news/contextual-retrieval)
- [Microsoft Research — Project GraphRAG](https://www.microsoft.com/en-us/research/project/graphrag/)
- [Anthropic — Citations API docs](https://docs.anthropic.com/en/docs/build-with-claude/citations)
- [RAG Is Not Dead: Advanced Retrieval Patterns That Actually Work in 2026 (DEV)](https://dev.to/young_gao/rag-is-not-dead-advanced-retrieval-patterns-that-actually-work-in-2026-2gbo)
- [Hybrid Search: BM25, Vector & Reranking 2026 (Digital Applied)](https://www.digitalapplied.com/blog/hybrid-search-bm25-vector-reranking-reference-2026)
- [RAG Evaluation: Metrics, Frameworks & Testing 2026 (Prem AI)](https://blog.premai.io/rag-evaluation-metrics-frameworks-testing-2026/)
- [RAG vs Fine-tuning vs Long Context: When to Use What (Medium)](https://medium.com/@officialpreksha2166/rag-vs-fine-tuning-vs-long-context-when-to-use-what-and-why-most-teams-get-it-wrong-388cc446ff3c)
- [Angela Shi — Enterprise Document Intelligence: Series Overview (TDS, May 2026)](https://towardsdatascience.com/document-intelligence-a-series-on-building-rag-brick-by-brick-from-minimal-to-corpus-scale/)
- [Angela Shi — Baseline Enterprise RAG, From PDF to Highlighted Answer (TDS, May 2026)](https://towardsdatascience.com/baseline-enterprise-rag-from-pdf-to-highlighted-answer-enterprise-document-intelligence-vol-1-1/)
- [Angela Shi — Embeddings Aren't Magic: Predictable Failure Modes (TDS, May 2026)](https://towardsdatascience.com/embeddings-arent-magic-the-predictable-failure-modes-of-rag-retrieval-enterprise-document-intelligence-vol-1-2/)
- [Angela Shi — Rerankers Aren't Magic Either (TDS, May 2026)](https://towardsdatascience.com/rerankers-arent-magic-either-when-the-cross-encoder-layer-is-worth-the-cost-enterprise-document-intelligence-vol-1-2bis/)
- [Angela Shi — RAG Is Not Machine Learning (TDS, Jun 2026)](https://towardsdatascience.com/rag-is-not-machine-learning-and-the-ml-toolkit-solves-the-wrong-problem/)
- [Angela Shi — From Regex to Vision Models: Technique Selection Grid (TDS, Jun 2026)](https://towardsdatascience.com/from-regex-to-vision-models-which-rag-technique-fits-which-problem/)
- [Angela Shi — Question Parsing in RAG (TDS, Jun 2026)](https://towardsdatascience.com/question-parsing-in-rag-structure-before-you-search/)
- [Angela Shi — What the Question Parser Extracts (TDS, Jun 2026)](https://towardsdatascience.com/what-the-question-parser-extracts-from-a-user-string-keywords-scope-shape-decomposition-clarification/)
- [Angela Shi — Dispatching the Parsed RAG Question (TDS, Jun 2026)](https://towardsdatascience.com/dispatching-the-parsed-rag-question-chunk-strategy-model-tier-activations-audit/)
- [Angela Shi — When RAG Users Ask Vague Questions (TDS, Jun 2026)](https://towardsdatascience.com/when-rag-users-ask-vague-questions-clarify-once-learn-the-default/)
- [Open-source alternatives to Cohere Rerank in 2026 (ZeroEntropy)](https://zeroentropy.dev/articles/open-source-alternatives-to-cohere-rerank/)
