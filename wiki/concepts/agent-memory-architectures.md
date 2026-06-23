---
title: Agent Memory Architectures
aliases: [agent memory, LLM memory, conversational memory]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, agent-memory, knowledge-graph, pole-o, rag, graphrag]
updated: 2026-06-23
sources:
  - raw/2026-06-20-graphrag-02-agentic-graphrag.md
  - raw/2026-06-20-graphrag-03-neo4j-agent-memory.md
  - raw/2026-06-20-graphrag-04-knowledge-graph-ontology.md
  - raw/2026-06-20-graphrag-05-keep-knowledge-graph-clean.md
  - raw/2026-06-23-decodingai-08-agent-memory.md
---

# Agent Memory Architectures

> [!summary]
> How AI agents persist, recall, and update knowledge across conversations and sessions. Agent memory is distinct from context (ephemeral per call) and RAG (retrieval from a static corpus): it is a living, updatable knowledge store that compounds over time — enabling agents to track identity, relationships, preferences, and past reasoning rather than starting from zero each session.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Agent memory is the mechanism by which an agent accumulates knowledge beyond its context window and across session boundaries. Without it, every conversation starts from scratch and the agent loses preferences, relationships, and past reasoning patterns. As Paul Iusztin puts it: "Memory is the component that transforms a stateless chat application into a personalized agent."

The evolution of agent memory follows an arc: plain RAG (retrieve from static corpus) → agentic RAG (agent decides when to retrieve) → **agent memory** (agent reads *and writes*, compounding knowledge over time).

The fundamental problem with simpler approaches:

- **File-system memory** (used by Claude Code, Cursor): append-only logs the agent re-reads from scratch each session. Context fragments and rots as the knowledge base grows past ~50 documents.
- **Vector index memory**: fuzzy semantic recall but no identity tracking, no merge, no way to know if this is the same entity mentioned yesterday. No temporal modeling.
- **Knowledge graph memory**: structured identity + typed relationships + time. The right substrate for compounding agent intelligence.

## Key concepts / building blocks

### Four memory types (functional taxonomy)

A complementary taxonomy to the 3-tier architecture below — organized by *what* is stored and *where*:

| Memory type | Description | Persistence |
|---|---|---|
| **Internal Knowledge** | The model's pre-trained world knowledge encoded in weights | Permanent, frozen at training time |
| **Context Window** | The information slice passed during one inference call — the model's "reality" for that call | Ephemeral (one call) |
| **Short-Term Memory** | Active context across a session: recent turns, working state, tool outputs | Session-scoped (volatile) |
| **Long-Term Memory** | External persistent storage for cross-session personalization and accumulated facts | Persistent (disk) |

The context window is not really "memory" in the durable sense — it is the interface through which all memory types are accessed. [[context-engineering]] is the discipline of assembling short-term memory + long-term retrieval into the right context window slice for each call.

**Long-term memory subtypes** (by the nature of what is stored):

- **Semantic memory** — individual facts and structured knowledge: `"User prefers vegetarian meals"`, product attributes, domain knowledge. The agent's encyclopedia. Stored as entities or fact nodes.
- **Episodic memory** — past interactions with timestamps: what happened, when, and who was involved. Enables relationship continuity ("last Tuesday the user mentioned..."). Stored as event/interaction records.
- **Procedural memory** — learned workflows and multi-step task patterns: the agent's muscle memory for repeatable processes. A monthly report procedure, a customer escalation workflow. Stored as reasoning traces or workflow templates.

### Three memory tiers (graph architecture)

The `neo4j-labs/agent-memory` reference architecture uses **1 graph, 3 tiers** joined by typed edges:

**Short-term memory** — the linear message sequence. `:Message` nodes chained by `:NEXT` edges, scoped to a `:Conversation`. Holds the current session context in ordered, queryable form.

**Long-term memory** — the typed entity graph. Deduplicated `:Entity` nodes with vector embeddings and arbitrary typed domain relationships. Holds everything the agent has learned about the world: people, organizations, objects, events, locations.

**Reasoning memory** — a tree per agent run. `:ReasoningTrace` root with child `:ReasoningStep` nodes capturing thoughts and tool calls. Stores past successful and failed thinking patterns. Analogous to Reinforcement Learning but baked into the database rather than the model weights — the agent can one-shot future similar requests or avoid repeating past mistakes.

Three typed edges stitch the tiers together. These make every cross-tier question a single Cypher query:

| Edge | Connects |
|---|---|
| `:MENTIONS` | Short-term → long-term (a conversation references an entity) |
| `:INITIATED_BY` | Reasoning → short-term (a reasoning trace was started by a conversation) |
| `:TOUCHED` | Reasoning → long-term (a reasoning step read or modified an entity) |

### Storage approaches for long-term memory

Three approaches for persisting long-term memory, with different trade-offs:

| Approach | Mechanism | Pros | Cons |
|---|---|---|---|
| **Raw Strings** | Natural language facts stored as text | Simple setup; preserves nuance and emotional tone | Imprecise retrieval; hard to update; no structural clarity about state changes |
| **Entities (JSON/Structured)** | Typed records with fields and schemas | Precise field-level filtering; easy updates; ideal for semantic memory | Requires upfront schema design; rigid if data doesn't fit the structure |
| **Knowledge Graphs** | Nodes and typed relationships in a graph DB | Complex relationship modeling; temporal awareness; auditable reasoning paths | Highest complexity/cost; difficult to convert from unstructured text; potentially slower retrieval |

The choice depends on domain breadth and relationship complexity. For narrow vertical agents: "our data wasn't actually that big... we could retrieve relevant data with simple SQL queries" (Iusztin, 2026) — don't over-engineer the storage layer. For agents that accumulate knowledge across many users, conversations, and entities, knowledge graphs provide the relationship traversal and deduplication capabilities that flat stores cannot.

### The memory cycle (10 steps)

The full memory lifecycle in an agent system:

1. **User input** — triggers the memory pipeline
2. **Ingestion** — populates long-term memory via data pipelines or API calls (async, not in the call path)
3. **Retrieval** — pulls relevant long-term memory into short-term using search tools
4. **Short-term assembly** — combines retrieved facts with current user input, recent history, LLM output schema
5. **Context engineering** — slices and formats short-term memory to fit the context window (see [[context-engineering]])
6. **Inference** — passes the assembled window to the LLM for response generation
7. **Loop** — LLM output fed back into short-term memory for next-turn context
8. **Update from short-term** — new user facts extracted and written to long-term memory (episodic, semantic)
9. **Update from external world** — continuous refresh of long-term memory via data pipelines
10. **Persistence** — saves short-term session state for next session (enables conversation continuity)

### POLE+O ontology

Agent memory requires an ontology — a schema specifying what entity types exist and how they relate. The POLE+O model (borrowed from intelligence analysis) provides a minimal, generic, extensible starting point:

| Base type | Covers |
|---|---|
| Person | People, aliases, personas |
| Object | Physical or digital things (tools, products, documents) |
| Location | Places, addresses, regions |
| Event | Meetings, transactions, incidents, deployments |
| Organization | Companies, teams, institutions |

POLE+O's power is its **fixed top level**. There are always exactly 5 base types to filter on, keeping the graph consistently queryable as it grows. Each type is extensible with domain-specific subtypes (e.g. `:Entity:Person:Individual`, `:Entity:Location:City`).

> [!tip] Start generic, extend through data exploration
> Trying to design the perfect ontology upfront freezes projects. Real shipped ontologies (22 domains in Neo4j's create-context-graph catalog) land at 10–12 entity types each: a shared POLE+O base + 5–7 domain-specific subtypes. The workflow: run a generic POLE+O extraction → inspect the graph for clashes where generic labels mislabel real data → add one subtype per clash → repeat.

**Two special primitives beyond POLE+O:**

**`:Fact` nodes** — atomic triplets (subject, predicate, object) with optional bi-temporal validity (`valid_from`, `valid_until`). Retrieved *only* via semantic/text search — no graph relationships. The fallback for any claim that doesn't cleanly fit a noun. Keeps the ontology small and unblocks early ingestion. "Eiffel Tower is 330 m tall" is one Fact node. Early on, lean on Facts; as the schema matures, migrate claims toward typed entities.

**`:Preference` nodes** — things a noun likes or dislikes. Fields: `category`, `preference`, `context`, `confidence`, `embedding`. Connected via `SUPERSEDED_BY` when preferences change. Attached to `:Person` by default. The personalization layer — what makes future responses feel tailored.

### Three-stage extraction pipeline

Routing every mention through an LLM multiplies cost for marginal recall on common entities. The pipeline uses a **speed-versus-accuracy cascade**:

1. **spaCy** — fast statistical NER for high-confidence common entities (proper nouns, organizations, locations).
2. **GLiNER / GLiREL** — zero-shot extraction for domain-specific entity and relationship types the statistical model misses.
3. **LLM stage** — fires only when the prior two stages leave ambiguity, or when relationship semantics require real understanding.

All stages are constrained to the defined ontology types. This constraint enables the LLM stage to be replaced with a cheap fine-tuned model (Gemini Flash Lite, Claude Haiku) as the schema stabilizes.

### Entity normalization: resolution vs. deduplication

> [!warning] The most common source of graph corruption
> Conflating resolution and deduplication into one fuzzy name-similarity check silently corrupts graphs. They are two distinct decisions answering two distinct questions.

**Entity resolution** — "What should we call this?" Finds the canonical name without any node merges.

The short-circuit chain (stops at first confident match):
1. Exact match against existing canonical names of the same type
2. Fuzzy match (RapidFuzz token-based comparison) for typos, abbreviations, word-order variants
3. Semantic match (light embeddings on name only) for paraphrase forms

Outcome: updates `canonical_name` property only. "NYC", "New York", "New York City" all collapse to one canonical name. Maintain an `aliases` list: every new surface form that resolves to the canonical name gets appended for future fast lookup. **No graph merges happen in resolution.**

**Entity deduplication** — "Is this the same real-world entity?" The identity check. Merges *can* happen here.

The system embeds the full entity context (name + type + attributes — not just the bare name) and compares against existing same-type nodes:

| Score | Action |
|---|---|
| ≥ 0.95 | Auto-merge |
| 0.85 – 0.95 | Create `:SAME_AS {status:'pending', confidence}` edge → human review queue |
| < 0.85 | Create new node |

The combined score is a weighted blend: `0.7 × embedding similarity + 0.3 × fuzzy similarity`.

The `:SAME_AS` review queue is a Cypher query over pending edges ordered by confidence. Reviewers confirm or reject each pair.

> [!warning] Asymmetric error cost
> A false merge is **silent and unrecoverable** without re-ingesting from raw source. A false split is noisy but recoverable — fix the flag and merge later. When in doubt, leave the decision to a human.

**The dream pipeline** — a nightly re-dedup pass over recently ingested nodes only (not the full graph). Catches collisions from parallel ingest (two mentions of the same entity processed simultaneously never compared against each other at write time). Uses pre-computed embeddings so no fresh model calls — primarily DB reads and writes.

### Retrieval algorithm

Because all three tiers live on one graph, a single retrieval composes multiple search modes in the same Cypher query:

- Vector similarity over `:Entity` embeddings (semantic entry points)
- Multi-hop expansion over typed relationships (2-3 hops for context)
- Time-ordered `:NEXT` walk for conversation history
- `:INITIATED_BY` and `:TOUCHED` lookups for reasoning trace provenance

No cross-store join logic. No orchestrator. One query engine.

## Design decisions & trade-offs

### Storage approach selection

Start with the simplest approach that satisfies the use case:
- **Raw strings** work for prototype personalization with a small, focused knowledge domain.
- **Entities (SQL/JSON)** are the right fit for most vertical AI agents — structured, queryable, and operationally simple.
- **Knowledge graphs** are justified when entity relationships are complex, multi-hop traversal is required, or temporal modeling of relationships matters.

Don't reach for a knowledge graph because it sounds sophisticated. Structured SQL entities cover most production vertical agent use cases.

### Single mutable collection vs. append-only log

**Single mutable collection:** each extraction directly upserts into the queryable store. Real-time visibility, simpler ops, no audit trail. Best for most use cases.

**Append-only log (two collections):** every event lands in an immutable log; periodic materialization squashes events into canonical records. Gains: versioning, temporality, reversibility of bad extractions. Cost: RAM + operational complexity. Choose only when you genuinely need time-travel or the ability to replay history.

### Database selection

| Use case | Recommendation |
|---|---|
| Small–medium scale, ≤3-hop traversals, thousands of nodes | Postgres or MongoDB — simpler, no extra infrastructure |
| Deep traversals, community detection, graph algorithms, data exploration | Neo4j |

Don't design for Google scale when processing thousands of documents. A single database (Postgres or MongoDB) handles nodes, vectors, and short graph lookups together.

### Scope of Preference extraction

Start with Preferences attached to `:Person` only. Extend to Organizations, Events, or Objects only when a concrete use case demands it. Keep the graph small and low-noise early.

### Human-in-the-loop threshold calibration

The 0.85 / 0.95 dedup thresholds are not universal. Tune them based on:
- How uniform the entity names in your corpus are (diverse naming → lower thresholds)
- The cost of a false merge in your domain (medical / financial → very conservative)
- The volume of human review your team can handle

## State of the art

The `neo4j-labs/agent-memory` open-source SDK (Neo4j Labs, 2026) is the most complete reference implementation. It ships 3-tier memory, POLE+O ontology, a 3-stage extraction pipeline, composite entity resolver, SAME\_AS dedup pattern, and a 15-tool FastMCP server with 9 framework adapters (LangChain, LlamaIndex, etc.). The SDK exposes `MemoryClient.get_context()` that fuses all three tiers in one graph call.

mem0 and cognee are alternative open-source agent memory solutions with slightly different resolution/dedup approaches. mem0 specializes in episodic memory compression and cross-session continuity for chatbot-style agents.

As of mid-2026, Claude Code and similar harnesses use file-system memory (progressive disclosure over markdown files). As knowledge bases scale past tens of documents, performance degrades and a graph-backed memory layer becomes the right next step.

## Pitfalls & anti-patterns

**Perfect-ontology paralysis.** Designing an exhaustive schema before running any extraction freezes the project. Start with generic POLE+O, ship, discover clashes from real data, extend incrementally.

**Over-engineering the storage layer.** Building a knowledge graph for a narrow vertical agent whose data "wasn't actually that big" — a common mistake when simpler SQL queries would suffice. Match storage complexity to actual relationship and scale requirements.

**Skipping the dream pipeline.** Parallel ingest creates invisible duplicate nodes that the live pipeline never compares. Without the nightly re-dedup pass, duplicates accumulate silently until the graph becomes untrustworthy.

**Embedding only the entity name for deduplication.** Bare-name similarity fuses "Jensen Huang the NVIDIA CEO" with "Jensen Huang the Taipei dermatologist" and "Paris France" with "Paris Texas." Always embed full entity context.

**Merging in the gray zone automatically.** A false merge corrupts the graph invisibly. The `:SAME_AS` pending edge pattern exists precisely so humans catch uncertain cases before they become permanent.

**No reasoning memory.** Without storing thinking traces, the agent repeats failed strategies and cannot one-shot future similar requests. Reasoning memory is the least-discussed tier and the most impactful for compounding intelligence.

**Ignoring the Facts fallback.** Forcing every claim into the ontology leads to over-engineering. Facts let the system capture knowledge immediately; type migration happens later as patterns emerge.

## See also

- [[graphrag]] — GraphRAG retrieval patterns built on top of a knowledge graph
- [[retrieval-augmented-generation]] — the retrieval foundation agent memory extends
- [[context-engineering]] — how agent memory feeds the context window efficiently
- [[vector-and-embedding-stores]] — the semantic search layer underlying entity retrieval
- [[model-context-protocol]] — MCP as the interface exposing `search_memory` and `write_memory` to agents
- [[agentic-system-design]] — where memory fits in the broader agent architecture
- [[human-in-the-loop-design]] — human review for uncertain dedup decisions
- [[agentic-loop]] — the execution context that reads and writes agent memory each iteration

## Sources

- Iusztin, P. (2026-05-05). Building Agentic GraphRAG Systems. Decoding AI. https://www.decodingai.com/p/agentic-graphrag
- Iusztin, P. (2026-05-19). Inside Neo4j's Agent Memory. Decoding AI. https://www.decodingai.com/p/understanding-neo4j-graph-agent-memory-system
- Iusztin, P. (2026-05-26). Stop Chasing the Perfect Ontology. Decoding AI. https://www.decodingai.com/p/ship-a-knowledge-graph-ontology-in-5-minutes
- Iusztin, P. (2026-06-02). How to Keep Your AI Agent's Knowledge Graph Clean. Decoding AI. https://www.decodingai.com/p/keep-knowledge-graph-clean
- Iusztin, P. (2026). How Does Memory for AI Agents Work? Decoding AI. raw/2026-06-23-decodingai-08-agent-memory.md
- Neo4j Labs. (2026). neo4j-labs/agent-memory. GitHub. https://github.com/neo4j-labs/agent-memory
- Neo4j Labs. (n.d.). POLE+O Data Model. https://neo4j.com/labs/agent-memory/explanation/poleo-model/
- Neo4j Labs. (n.d.). Entity Resolution and Deduplication. https://neo4j.com/labs/agent-memory/explanation/resolution-deduplication/
- Monigatti, L. (n.d.). The Evolution From RAG to Agentic RAG to Agent Memory. https://www.leoniemonigatti.com/blog/from-rag-to-agent-memory.html
