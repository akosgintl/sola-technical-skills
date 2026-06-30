---
title: GraphRAG
aliases: [Graph RAG, graph retrieval-augmented generation, knowledge graph RAG]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, graphrag, knowledge-graph, retrieval, rag, ontology]
updated: 2026-06-30
sources:
  - raw/2026-06-20-graphrag-01-production-engineer-agent.md
  - raw/2026-06-20-graphrag-02-agentic-graphrag.md
  - raw/2026-06-30-theneuralmaze-02-temporal-knowledge-graph-memory.md
---

# GraphRAG

> [!summary]
> Retrieval-Augmented Generation (RAG) where retrieval is guided by a knowledge graph rather than vector similarity alone. Instead of pulling the most similar text chunks, GraphRAG traverses typed relationships — surfaces connected, structurally-reasoned context. Best for coverage and synthesis questions that span multiple entities, not for simple similarity lookups.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

GraphRAG is a set of RAG patterns where retrieval is guided by graph structure, not just similarity scores. The underlying store is a **knowledge graph** — nodes represent entities (services, teams, people, concepts), edges represent typed relationships (DEPENDS\_ON, OWNED\_BY, CAUSED\_BY), and properties on both store metadata and embeddings.

The core insight is that enterprise and agentic questions are **coverage and synthesis questions**, not similarity questions:

- *"What do we know about failures related to service X?"* — needs graph traversal across services, incidents, runbooks, teams.
- *"Summarize everything related to this initiative and its dependencies."* — needs multi-hop expansion, not top-k chunks.

A similarity-based retriever returns the most relevant paragraphs. GraphRAG returns a connected slice of the organization's knowledge — the blast radius, the ownership chain, the historical patterns.

![[2026-06-20-graphrag-02-agentic-graphrag-01.png|Fragmented sources unified into a single knowledge graph]]
*Figure: GraphRAG unifies fragmented sources (docs, notes, APIs) into one queryable knowledge graph — source [[2026-06-20-graphrag-02-agentic-graphrag]].*

> [!tip] GraphRAG is a data modeling problem
> The critical insight from practice: GraphRAG fails not because of retrieval algorithms, but because of schema design. Letting the LLM invent entity types freely produces 17 node types and 34 relationship types from just 5 documents. **The ontology must come first** — see [[agent-memory-architectures]] for the POLE+O approach.

## Why it matters

Three structural problems make GraphRAG valuable over plain [[retrieval-augmented-generation|RAG]]:

1. **Context rot.** As the context window fills with retrieved chunks, signal-to-noise collapses. GraphRAG retrieves a structured, bounded subgraph — not a page of similar paragraphs.
2. **Data fragmentation.** In production and agent systems, knowledge lives in silos: docs, notes, emails, Slack threads, runbooks, postmortems. A knowledge graph is the semantic layer that connects them.
3. **Relational memory.** Agent memory naturally maps to a graph: people have preferences, met other people, visited locations, completed tasks — all anchored in time. Flat vector stores cannot model identity, ownership, or temporal relationships.

GraphRAG is the right tool when knowledge is **relational** and queries require following connections. Palantir built its enterprise platform on ontologies; Google's Search KG and Microsoft's internal ops tools use the same pattern.

## Key concepts / building blocks

### Knowledge Graph

- **Nodes** — entities (Service, Team, Incident, Runbook, Person, Location, Organization, etc.)
- **Edges** — typed relationships (`DEPENDS_ON`, `OWNED_BY`, `CAUSED_BY`, `RELATED_TO`)
- **Properties** — metadata on nodes and edges (summaries, timestamps, embeddings, confidence scores)

Embeddings attach to nodes (derived from LLM-generated summaries, not raw text) to enable semantic search as the entry point into the graph.

### Property Graph vs. RDF

Two formats exist. RDF expresses every property as a triplet, exploding the graph size. **Property graphs** (Neo4j's model) attach metadata as JSON on the entity or relationship. Agent stacks use property graphs in practice — they are more compact and queryable.

![[2026-06-20-graphrag-02-agentic-graphrag-04.png|RDF triplets vs. labeled property graph]]
*Figure: RDF (every property a triplet) vs. the labeled property graph (metadata as JSON on nodes/edges) — source [[2026-06-20-graphrag-02-agentic-graphrag]].*

### Ontology

An ontology is the formal schema: which entity types exist, which relationship types connect them, which properties each carries. A **constrained ontology** is essential:
- Without it: the LLM invents types freely → 5 docs → 17 node types, 34 edge types, including `part_of`, `Part Of`, `part of` as three separate types.
- With it: the LLM can only extract what you defined. Constrained scope allows cheaper, fine-tuned extraction models.

Real ontologies are small (10–12 entity types). See [[agent-memory-architectures]] for the POLE+O base model.

### Two-phase process

**Phase 1 — Graph Generation:**
1. Source documents → text chunks
2. Chunks → element extraction (entities + relationships as intermediate representations)
3. Elements → LLM-generated summaries → graph objects (nodes + edges + properties)
4. Graph → community detection (hierarchical Leiden algorithm) → community summaries (the primary retrieval unit for global queries)

![[2026-06-20-graphrag-01-production-engineer-agent-04.png|The GraphRAG pipelines: ingestion, extraction, retrieval]]
*Figure: Pipelines in the GraphRAG approach — ingestion → extraction → retrieval — source [[2026-06-20-graphrag-01-production-engineer-agent]].*

**Phase 2 — Query Answering:**
1. Semantic search over node embeddings → entry points into the graph
2. Graph traversal across typed edges to expand the result (2–3 hops standard)
3. Merge findings into a structured answer

## Design decisions & trade-offs

### Extraction modes

| Mode | Mechanism | When to use |
|---|---|---|
| Structured | Schema-guided; LLM outputs only defined entity types | Production — preferred |
| Semi-structured | Metadata + lineage without LLM (e.g. parse email links) | Document ontology, known structure |
| Unstructured | LLM invents its own labels | Discovery/exploration only; never for grounded retrieval |

### Retrieval strategy: bottom-up vs. top-down

**Bottom-up** (entity-first): semantic + text search → RRF merge → 2-3 hop expansion across typed edges. Returns deep, specific context. Better for precise questions.

**Top-down** (community-first): hop across community summaries for a high-level overview of a topic. Better for broad synthesis. Higher context cost.

The two-stage algorithm: Stage 1 runs text + semantic search, merges results via **Reciprocal Rank Fusion (RRF)** to get entry points. Stage 2 walks 2-3 hops across typed edges. This is where GraphRAG adds over plain RAG.

![[2026-06-20-graphrag-02-agentic-graphrag-10.png|Two-stage retrieval: RRF entry points then graph traversal]]
*Figure: Two-stage retrieval — semantic+text search merged by RRF, then multi-hop graph traversal — source [[2026-06-20-graphrag-02-agentic-graphrag]].*

![[2026-06-20-graphrag-02-agentic-graphrag-11.png|Bottom-up entity-first vs. top-down community-first traversal]]
*Figure: Bottom-up (entity-first, precise) vs. top-down (community-first, synthesis) traversal — source [[2026-06-20-graphrag-02-agentic-graphrag]].*

### Data model: append-only log vs. single mutable collection

**Append-only log (two collections):** every extraction event lands in an immutable log; a periodic materialization step squashes events into one canonical record. Gives versioning, temporality, and reversibility. Costs RAM and operational complexity.

**Single mutable collection:** each extraction directly upserts into the queryable collection. Simpler ops, real-time visibility, no audit trail.

*Decision:* Choose single collection when operational simplicity outweighs audit needs. Choose append-only when you genuinely need re-playability or the ability to revert bad extractions.

![[2026-06-20-graphrag-02-agentic-graphrag-07.png|Two-collection MongoDB shape: immutable append-only log plus a materialized view]]
*Figure: The append-only data model — an immutable event log squashed into a materialized view — source [[2026-06-20-graphrag-02-agentic-graphrag]].*

![[2026-06-20-graphrag-02-agentic-graphrag-08.png|Single-collection MongoDB data model with nodes and edges coexisting]]
*Figure: The single-collection model — nodes and edges upserted into one queryable store — source [[2026-06-20-graphrag-02-agentic-graphrag]].*

### Database selection

| Choice | When |
|---|---|
| Postgres or MongoDB | ≤2–3 hop traversals; thousands of nodes; simpler ops; avoid multi-DB overhead |
| Neo4j | Deep traversals; specialized graph algorithms (community detection, path finding); data exploration at scale |

### GraphRAG vs. plain RAG — when to choose

| Dimension | Plain [[retrieval-augmented-generation\|RAG]] | GraphRAG |
|---|---|---|
| **Query type** | Similarity ("find relevant paragraphs") | Relational ("who owns X? what caused Y? trace this dependency") |
| **Knowledge structure** | Flat document corpus | Entity-relationship graph |
| **Infrastructure cost** | Low (vector DB + chunker) | High (graph DB + ontology + extraction pipeline) |
| **Retrieval latency** | Fast (single ANN lookup) | Slower (graph traversal, multi-hop) |
| **Multi-hop reasoning** | Poor (requires re-querying) | Native (edge traversal) |
| **Update cost** | Cheap (upsert chunks) | Moderate (entity normalization, dedup pipeline) |
| **Best fit** | FAQ, document search, semantic similarity | Agent memory, org knowledge bases, incident analysis, dependency mapping |

**Default choice:** start with plain RAG. Move to GraphRAG when queries require multi-entity relationships, traversal over ownership/dependency chains, or compounding agent memory across sessions.

### Real-time vs. historical context layering

In production systems, two retrieval layers serve different purposes:
- **Knowledge graph** — documented structure, historical patterns, ownership, dependencies
- **MCP servers / live APIs** — current state (metrics, recent deployments, active incidents)

MCP data takes priority for the current incident. Encode the priority in the system prompt and flag discrepancies explicitly when MCP and graph contradict each other.

### Update frequency

Production topology changes slowly. Daily graph sync (nightly scheduled job) is typically sufficient. Real-time events go through MCP; the graph is the durable semantic layer.

## State of the art

Microsoft Research introduced the term GraphRAG and demonstrated its value over plain RAG for global queries on narrative private data (2024). Their implementation uses hierarchical community detection and community summaries as the primary retrieval unit.

That community-summary design is built for **static** corpora — when the underlying data changes you recompute large parts of the graph, and query-time multi-step summarisation can take tens of seconds. That is a non-starter for agent *memory*, which must update its world model mid-conversation and answer in real time. **Graphiti (Zep)** targets this dynamic regime: it folds new information in *incrementally* as discrete episodes (no whole-graph recompute), uses a **bi-temporal model** (tracking both when an event happened and when the system learned it) to mark contradicted facts superseded rather than deleting them, and keeps query-time fast by fusing vector + BM25 + graph traversal into one hybrid query with no LLM call on the read path (sub-second p95). The lesson: GraphRAG-style community summarisation is for analysing fixed datasets; temporal-graph memory is for agents that learn continuously — see [[agent-memory-architectures]].

The LlamaIndex `PropertyGraph` integration provides built-in support for agentic GraphRAG queries on Neo4j. The `neo4j-labs/agent-memory` SDK (open-source, 2026) ships a complete graph-backed agent memory layer with 15 MCP tools, POLE+O ontology, and a 3-stage extraction pipeline.

**Agentic GraphRAG** closes the loop: the agent not only reads from the KG but also writes to it autonomously via `write_memory` tools, enabling continual learning — the agent ingests the current conversation into the graph, updating preferences and facts in real time.

![[2026-06-20-graphrag-02-agentic-graphrag-02.png|Complete agentic GraphRAG system: data + memory pipelines, MCP server, harness]]
*Figure: A complete agentic GraphRAG system — data and memory pipelines feeding a unified graph store served to the agent over MCP — source [[2026-06-20-graphrag-02-agentic-graphrag]].*

## Pitfalls & anti-patterns

**Schema-free extraction.** Allowing the LLM to invent entity and relationship types produces unusable noise within tens of documents. Always define an ontology before running extraction.

**Using GraphRAG when similarity suffices.** GraphRAG has higher infrastructure cost than plain RAG. Use it when questions genuinely require relational traversal. For simple "find the relevant paragraph" queries, vector RAG is cheaper and faster.

**Ignoring resolution and deduplication.** Without entity normalization, the same service (or person) appears as multiple nodes with no edges between them. Graph traversal then misses connected context — silently. See [[agent-memory-architectures]] for the resolution/dedup pipeline.

**Treating community summaries as the only retrieval mode.** Top-down global queries via community summaries are expensive (large context) and slow. Use bottom-up entity + edge traversal for precise questions; reserve top-down for genuine synthesis tasks.

**Not instrumenting retrieval.** Without observability (prompt traces, Cypher query logs, retrieved subgraph inspection), it is impossible to know whether the graph is returning the right context or silently missing connections.

## See also

- [[retrieval-augmented-generation]] — the foundation GraphRAG extends
- [[agent-memory-architectures]] — POLE+O ontology, 3-tier memory, extraction/dedup pipeline
- [[context-engineering]] — GraphRAG as a strategy for managing context quality
- [[vector-and-embedding-stores]] — the semantic search layer GraphRAG builds on
- [[agentic-system-design]] — how GraphRAG fits in the broader agent architecture
- [[model-context-protocol]] — MCP as the interface between agent and GraphRAG memory

## Sources

- Muscalagiu, A. I. (2026-01-20). Your Agent's Reasoning Is Fine — Its Memory Isn't. Decoding AI. https://www.decodingai.com/p/designing-production-engineer-agent-graphrag
- Iusztin, P. (2026-05-05). Building Agentic GraphRAG Systems. Decoding AI. https://www.decodingai.com/p/agentic-graphrag
- Larson, J. (2024). GraphRAG: Unlocking LLM Discovery on Narrative Private Data. Microsoft Research. https://www.microsoft.com/en-us/research/blog/graphrag-unlocking-llm-discovery-on-narrative-private-data/
- Negro, A., et al. (n.d.). Knowledge Graphs and LLMs in Action. Manning. https://www.manning.com/books/knowledge-graphs-and-llms-in-action
- LlamaIndex. (n.d.). Agentic GraphRAG with Property Graphs. https://developers.llamaindex.ai/python/examples/property_graph/agentic_graph_rag_vertex/
- Otero Pedrido, M. (2026-06-04). Building Agent Memory with Knowledge Graphs. The Neural Maze. raw/2026-06-30-theneuralmaze-02-temporal-knowledge-graph-memory.md
