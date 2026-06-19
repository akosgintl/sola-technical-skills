---
title: Vector and Embedding Stores
aliases: [vector database, embedding store, vector store, ANN search]
type: concept
domain: data
priority: P0
roadmap_ref: "5.4.1"
status: stub
tags: [data, ai, vectors, embeddings, search]
updated: 2026-06-19
sources: []
---

# Vector and Embedding Stores

> [!summary]
> Databases that index high-dimensional embedding vectors for approximate-nearest-neighbor similarity search, the retrieval backbone of RAG and semantic search.

**Priority:** 🔴 P0 · **Domain:** [[tier-2-solid|Data Architecture]] · **Roadmap:** §5.4.1

## What it is

Vector and embedding stores persist the numeric embeddings produced by ML models and support fast similarity queries over them using approximate-nearest-neighbor (ANN) indexes. They power semantic retrieval, recommendation, and the retrieval step in RAG. Options range from dedicated databases to vector extensions on existing stores.

## Key concepts

- Embeddings and similarity metrics (cosine, dot, L2)
- ANN indexes (HNSW, IVF, ScaNN)
- Dedicated stores (Pinecone, Weaviate, Qdrant, Milvus) vs. pgvector
- Hybrid search (dense + sparse/keyword)
- Metadata filtering and re-ranking

## See also

- [[ai-data-fabric]]
- [[feature-stores]]
- [[retrieval-augmented-generation]]
- [[data-storage-paradigms]]

## Sources

- _Stub — no sources ingested yet._
