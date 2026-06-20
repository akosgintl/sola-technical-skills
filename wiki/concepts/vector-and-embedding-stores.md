---
title: Vector and Embedding Stores
aliases: [vector database, embedding store, vector store, ANN search, semantic search database]
type: concept
domain: data
status: mature
tags: [data, ai, vectors, embeddings, ann, hnsw, hybrid-search, pgvector, qdrant, milvus]
updated: 2026-06-20
sources:
  - "https://www.firecrawl.dev/blog/best-vector-databases"
  - "https://letsdatascience.com/blog/vector-databases-compared-pinecone-qdrant-weaviate-milvus-and-more"
  - "https://tensorblue.com/blog/vector-database-comparison-pinecone-weaviate-qdrant-milvus-2025"
  - "https://encore.dev/articles/best-vector-databases"
  - "https://arxiv.org/abs/2601.11557"
---

# Vector and Embedding Stores

> [!summary]
> Databases that index high-dimensional embedding vectors for approximate nearest-neighbor (ANN) similarity search — the retrieval backbone of RAG, semantic search, and agent memory. The critical architectural decision is not which database to pick first, but whether to use a dedicated vector store or add a vector extension to an existing database, and whether to enable hybrid search (dense + sparse) from day one. For most RAG workloads, hybrid search outperforms pure vector search; skip it only if benchmarks show it doesn't matter for your data.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

Vector stores persist the numerical embedding vectors produced by ML models and support fast similarity queries over them. An embedding is a fixed-length floating-point array (typically 384–3072 dimensions) that encodes the semantic meaning of a text chunk, image, or document. Similarity between embeddings (computed via cosine similarity, dot product, or Euclidean distance) approximates semantic similarity of the original content.

At query time, the user's query is also embedded, and the store returns the top-k most similar stored embeddings — the retrieval step in [[retrieval-augmented-generation|RAG]]. Because exhaustive comparison across millions of vectors is prohibitively slow, all production systems use **approximate nearest-neighbor (ANN)** algorithms that trade a small accuracy loss for orders-of-magnitude speed gains.

## Why it matters

Vector stores are the retrieval infrastructure for every LLM application that grounds responses in external data: RAG pipelines, semantic search, recommendation engines, duplicate detection, and [[agent-memory-architectures|agent long-term memory]]. The choice of index algorithm, similarity metric, and store architecture directly determines query latency, recall quality, and infrastructure cost at scale.

## Key concepts / building blocks

### Embedding generation

Embeddings are produced by an embedding model (separate from the generative LLM). Common options:

| Option | Dimensions | Strength |
|---|---|---|
| OpenAI text-embedding-3-large | 3072 (truncatable via Matryoshka) | High quality, hosted |
| OpenAI text-embedding-3-small | 1536 | Cost-efficient, hosted |
| Cohere embed-v4 | 1024 | Multimodal (text + image), hosted |
| sentence-transformers (BGE, E5, GTE) | 384–1024 | Open source, self-hosted, strong multilingual |
| Voyage AI | 1024–2048 | Strong domain-specific (legal, code, finance) |

**Matryoshka Representation Learning (MRL)** — embedding models trained with MRL can be truncated to smaller dimensions at query time, trading recall for lower storage and faster search. text-embedding-3-large can be safely truncated to 256 dimensions for many tasks.

### ANN indexing algorithms

**HNSW (Hierarchical Navigable Small World)** — graph-based ANN; the dominant production algorithm. Builds a multi-layer graph where upper layers coarsely navigate and lower layers refine. Advantages: fast queries (O(log N)), high recall, no training step required. Disadvantage: memory-intensive (graph structure lives in RAM). Used by: Qdrant, Weaviate, Milvus, pgvector.

**IVF (Inverted File Index)** — clusters vectors into Voronoi cells; at query time searches only the nearest clusters. More memory-efficient than HNSW at scale; lower recall at the same speed. Used for very large collections where HNSW RAM cost is prohibitive.

**ScaNN / DiskANN** — distance-aware quantization (Google ScaNN) or disk-based graph index (DiskANN) for billion-scale collections that exceed RAM. For specialist use cases.

### Similarity metrics

| Metric | Formula | Use when |
|---|---|---|
| Cosine similarity | cos(θ) between vectors | Text embeddings (most common) |
| Dot product | v₁ · v₂ | Embeddings trained with dot product (e.g. OpenAI) |
| L2 / Euclidean | ‖v₁ − v₂‖ | Image / spatial embeddings |

For most text use cases, cosine and dot product are interchangeable when vectors are normalized. Always check which metric your embedding model was trained with.

### Hybrid search (dense + sparse)

Pure vector search retrieves semantically similar content but misses exact keyword matches — a critical gap for product names, codes, identifiers, and rare terms that embeddings blur. Hybrid search combines:
- **Dense vector search** — semantic similarity via ANN
- **Sparse/keyword search** — BM25 or SPLADE for exact and frequency-weighted token matching

Results from both are merged via **Reciprocal Rank Fusion (RRF)** or a learned reranker. Hybrid search improves recall on most RAG workloads and should be the default, not an optional add-on.

Native hybrid support in 2026:
- **Milvus 2.5+** — native BM25 as sparse vectors; 30× latency advantage over Elasticsearch in internal benchmarks
- **Qdrant v1.9+** — named vectors hold both dense HNSW and sparse inverted index; server-side IDF since v1.15.2
- **Weaviate** — BM25 + vector hybrid with alpha blending
- **Elasticsearch / OpenSearch** — native hybrid via ELSER sparse model + kNN

### Metadata filtering

All production deployments need metadata filters (tenant ID, date range, document type, access control) applied alongside vector similarity. Two approaches:
- **Pre-filter** — apply filter first, then ANN search over matching subset. Exact but slow if the filtered subset is large.
- **Post-filter** — ANN search first, then filter. Fast but can miss results if filtered items are in the top-k.
- **Filtered HNSW** (Qdrant, Milvus) — filter applied during graph traversal, not before or after. Best recall/speed trade-off; the preferred approach.

### Late interaction / multi-vector models (ColBERT)

Standard bi-encoder embeddings compress a full document into one vector, losing fine-grained token-level interactions. ColBERT and ColPali produce **one vector per token**, then compute MaxSim at query time (max dot product across all token-pair combinations). Dramatically higher recall at the cost of storage and query compute. Supported natively by Qdrant (v1.9+), Vespa. Best for precision-critical retrieval (legal, medical, code search).

### Re-ranking

After ANN retrieval returns top-k candidates, a **cross-encoder reranker** (Cohere Rerank, Voyage Rerank, BGE-reranker) re-scores the candidates with full attention to both query and document. Cross-encoders are too slow for full-corpus search but accurate for the small top-k candidate set. Standard production pattern: retrieve top-50 via ANN, rerank to top-5 for the context window.

## Design decisions & trade-offs

### Dedicated vector store vs. vector extension

| Dimension | Dedicated (Pinecone, Qdrant, Weaviate, Milvus) | Extension (pgvector, Elastic kNN, MongoDB) |
|---|---|---|
| Performance | Optimized query planners, storage engines, index structures | Adds vector search to a general-purpose store; performance limitations at scale |
| Ops | Extra system to operate | Reuses existing infrastructure |
| Scale ceiling | Billions of vectors | Millions of vectors comfortably |
| Feature set | Filtered HNSW, hybrid, multi-vector, named vectors | Varies; pgvector supports HNSW and hybrid (pgvector 0.7+) |
| Best fit | Vector-first workloads, >10M vectors | Adding RAG to an existing Postgres/Mongo stack |

**pgvector** is the right default for teams that already run Postgres, collections under ~5M vectors, and teams that don't want another infrastructure dependency. Move to a dedicated store when queries slow past acceptable thresholds or when advanced features (filtered HNSW, native hybrid) are needed.

### Managed vs. self-hosted

Migration trigger heuristic: **50–100M vectors or $500+/month in cloud vector DB spend** signals it's time to evaluate self-hosted. Below that, managed (Pinecone, Zilliz Cloud) removes the operational burden at reasonable cost.

### Reranking: always vs. selectively

Cross-encoder reranking adds latency (50–200ms) but consistently improves precision. Use it when:
- Context window is constrained (you can only send top-3, not top-20)
- The downstream task is precision-critical (QA, legal, medical)
- Hybrid ANN retrieval still returns noisy results

Skip it when retrieval recall is already high enough and latency budget is tight.

## State of the art

The vector database market consolidated significantly in 2025–2026. The headline shifts:

**Qdrant** emerged as the SOTA open-source option: native filtered HNSW, named vectors for multi-vector (dense + sparse + ColBERT), server-side IDF for BM25, and the strongest benchmark recall/latency profile among self-hosted options.

**Milvus 2.5+** added native BM25 as first-class sparse vectors — making full hybrid search available without a separate keyword search service — and leads benchmark throughput at large scale (Zilliz Cloud managed offering).

**Turbopuffer** emerged as a serverless vector store for high-cardinality, sparse-access patterns (many tenants, infrequent per-tenant queries) — an alternative to the "one store per tenant" anti-pattern.

**pgvector 0.7+** (2025) added HNSW and basic hybrid search, raising the ceiling for Postgres-native vector workloads significantly.

From arXiv:2601.11557 (2026), information-theoretic binarization is an emerging alternative index family that promises further memory reduction beyond quantized HNSW — not yet production-mainstream but worth tracking.

## Pitfalls & anti-patterns

**Chunking only at ingest time.** Fixed-size chunk boundaries at indexing time often cut sentences mid-thought. Use **late chunking** or **semantic chunking** (split at sentence/section boundaries) for higher retrieval quality.

**Skipping hybrid search.** Pure vector search misses exact keyword matches for entity names, codes, and identifiers. Default to hybrid unless benchmarks prove it doesn't help for your specific dataset.

**Wrong similarity metric.** Using cosine similarity with a model trained to maximize dot product (OpenAI embeddings) silently degrades recall. Always match the metric to the model.

**No reranker in the pipeline.** ANN top-k is approximate and optimized for speed, not precision. A reranker on the candidate set is cheap compared to the gains. Don't skip it in production.

**No metadata filtering.** Without tenant scoping, all users' data bleed together at retrieval time — a data isolation failure, not just a quality issue.

**Ignoring the embedding model as a first-class choice.** The embedding model determines retrieval ceiling quality more than index algorithm. Benchmark embedding models on your domain data before committing to an index choice.

## See also

- [[retrieval-augmented-generation]]
- [[graphrag]]
- [[ai-data-fabric]]
- [[feature-stores]]
- [[agent-memory-architectures]]
- [[context-engineering]]
- [[data-storage-paradigms]]

## Sources

- Firecrawl. (2026). Best Vector Databases in 2026: A Complete Comparison Guide. https://www.firecrawl.dev/blog/best-vector-databases
- Let's Data Science. (2026). Vector Databases Compared: Pinecone vs Qdrant vs Weaviate. https://letsdatascience.com/blog/vector-databases-compared-pinecone-qdrant-weaviate-milvus-and-more
- TensorBlue. (2025). Vector Database Comparison 2025: Pinecone vs Weaviate vs Qdrant vs Milvus vs FAISS. https://tensorblue.com/blog/vector-database-comparison-pinecone-weaviate-qdrant-milvus-2025
- Encore. (2026). Best Vector Databases in 2026: Complete Comparison Guide. https://encore.dev/articles/best-vector-databases
- Bai, Y., et al. (2026). From HNSW to Information-Theoretic Binarization: Rethinking Scalable Vector Search. arXiv:2601.11557. https://arxiv.org/abs/2601.11557
