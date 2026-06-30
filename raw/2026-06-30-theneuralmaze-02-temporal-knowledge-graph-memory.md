---
title: "Building Agent Memory with Knowledge Graphs"
aliases: [temporal knowledge graph memory, Graphiti agent memory, bi-temporal graph memory]
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, agent-memory, knowledge-graph, temporal-graph, graphiti, neo4j, rag]
updated: 2026-06-30
source_url: https://theneuralmaze.substack.com/p/building-agent-memory-with-knowledge
source_type: article
ingested: 2026-06-30
feeds: [agent-memory-architectures, graphrag]
---

# Building Agent Memory with Knowledge Graphs

> [!info] Source metadata
> **Author/Org:** Miguel Otero Pedrido (The Neural Maze) · **Date:** 2026-06-04 · **Access:** PAID (captured via authenticated browser session) · **URL:** https://theneuralmaze.substack.com/p/building-agent-memory-with-knowledge

## Key takeaways

- **"Most 'memory' in production agents is a vector database with a nice name."** You embed every
  turn, cosine-similarity to top-k, and call it memory — but it has no concept of identity, of who/
  what, or that facts can die. The canonical failure: user says "I moved to Madrid," and three turns
  later the agent recommends restaurants in the old city because both facts score high and nothing
  knows one replaced the other. "A filing cabinet with no concept of time."
- Three concrete vector-memory failure modes: (1) **identity** — partner Marta (week 1) vs colleague
  Marta (week 3) become two blobs retrieval mixes; (2) **currency** — old job title and new title both
  retrievable, agent can't tell which is current; (3) **multi-hop** — "who introduced me to my running
  club?" needs chaining 3 facts; vector similarity retrieves each in isolation. *Not a tuning problem* —
  swapping embedding models, raising top_k, adding a reranker won't fix a representation with no slot
  for identity, relationship, or time.
- **Knowledge graph = network of triples** (subject, relationship, object); things are nodes, connections
  are labelled directional edges. Buys four things vectors can't: **explainable reasoning** (the answer
  is a literal readable path), **multi-hop reasoning** (graph traversal vs praying the chunks land in
  top-k), **entity resolution** (reconcile or separate two "Marta"s explicitly — identity vs mere
  similarity), and a **flexible schema** (add entity/relationship types with no migration).
- **Temporal knowledge graph** is the leap: attach validity time to the *relationships*. "Lives in
  Barcelona" isn't deleted on a move — it's marked no-longer-valid as of the move date and a new
  "lives in Madrid" edge is created. Both preserved; the graph answers "where did they live last
  spring?" and "where now?" without contradicting itself. "The difference between a memory that
  accumulates and a memory that evolves."
- **RAG vs graph is not RAG-is-dead.** RAG (chunk → embed → store → nearest-neighbour → ground) is hard
  to beat for large mostly-static corpora, especially **hybrid** (BM25 keyword + vector semantic, fused
  via Reciprocal Rank Fusion). The trouble starts only when you ask RAG to be a *memory*.
- **Graphs are quietly displacing naive RAG for agent memory.** Microsoft's GraphRAG-style approach
  (extract entities → cluster into communities → LLM pre-computes community summaries) is built for
  *static* data — changes force recomputation and query-time summarisation can take tens of seconds.
  **Graphiti (Zep)** closes the gap: ingests new info as discrete **episodes**, incrementally folds each
  into the graph (extract + reconcile) without recomputing the whole; uses a **bi-temporal model**
  (when the event happened *and* when the system learned it); marks contradicted facts superseded rather
  than deleting; and keeps retrieval fast by **avoiding LLM calls at query time** — combining vector +
  BM25 + graph traversal into one hybrid query (Zep reports sub-second p95, fast enough behind a voice
  assistant). "Graphs aren't replacing the retrieval techniques RAG taught us; they wrap them in
  something that finally understands identity and time."
- **When to use each.** Vector RAG: document Q&A over large mostly-static corpora; relationships/time
  don't matter; simplest/cheapest/highest-write-throughput (embedding a chunk << LLM extraction per
  episode). Temporal graph (Graphiti): persistent cross-session agent memory; who-relates-to-whom and
  how-things-change are first-class; entity disambiguation + multi-hop; explainable answers. **Often
  both** — RAG for static document piles, graph for dynamic relationship-rich memory, merge results.
- **The cost, stated plainly:** every ingested episode costs an LLM call (entity + relationship
  extraction) → ~0.5–2 s latency and real money at volume; extraction is *not* guaranteed complete (may
  miss implicit relationships, no schema to validate against). "If your use case is search 10M static
  documents as fast and cheap as possible, a graph is the wrong tool. Know what you're buying."

## Notable claims (with location)

- Graphiti retrieval latency: **sub-second at p95**, low enough to sit behind a voice assistant —
  because it avoids query-time LLM calls (hybrid vector + BM25 + traversal). (§ How graphs are quietly
  replacing RAG)
- Per-episode write cost: **~0.5–2 s** and money per episode for LLM extraction; incompleteness +
  no schema validation are inherent. (⚠️ warning before "Let's build it")
- Microsoft GraphRAG community-summary approach: built for static data; updates force large
  recomputation; query-time multi-step summarisation can take **tens of seconds**. (same §)

## Reference build (worth noting, not wiki-bound)

- Framework-free stack: `graphiti-core` + **Neo4j 5.26** (Docker Compose, Bolt 7687 + Browser 7474) +
  a thin chat loop. `GraphMemory` wrapper exposes `remember()` (`add_episode` with `group_id` per user
  for isolation) and `recall()` (`client.search`, hybrid). Loop = recall context → ground reply →
  remember both sides. Neo4j Browser `MATCH (n)-[r]->(m) RETURN n, r, m` visualises edges gaining
  invalidation times when a fact is contradicted.

## Key visuals

> No original diagrams localized — the post's only embedded figure is an external screenshot of
> Microsoft's GraphRAG announcement, plus a walkthrough video and code blocks (dropped per the
> keep/drop rubric). Captured via authenticated browser (`get_page_text`), which returns text only.

## Feeds these wiki pages

- [[agent-memory-architectures]]
- [[graphrag]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
