---
title: LLM Knowledge Base
aliases: [LLM wiki, personal deep research agent, memory folder, index.yaml knowledge base]
type: concept
domain: ai-agentic
status: draft
tags: [ai-agentic, llm, progressive-disclosure, deep-research, context-engineering, knowledge-management]
updated: 2026-06-30
sources:
  - https://www.decodingai.com/p/llm-knowledge-base-obsidian-readwise-notebooklm
  - https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
  - https://www.llamaindex.ai/blog/did-filesystem-tools-kill-vector-search
  - raw/2026-06-30-decodingai-12-personal-llm-knowledge-base.md
---

# LLM Knowledge Base

> [!summary]
> A knowledge base that an LLM **pre-compiles** from your private, curated sources into a structured,
> interlinked set of files — so understanding *compounds* and the same question is never researched
> twice. Unlike RAG, which re-reads raw documents on every query, the model reads a lightweight
> **index** first and opens only the few files it needs (progressive disclosure). The filesystem is
> the state; Markdown + YAML + JSON is the wire format. No vector database, no embeddings, full
> lineage back to source URLs.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

An **LLM Knowledge Base** (a term popularised by Andrej Karpathy) inverts the usual retrieval
relationship. Instead of an agent re-reading raw documents on every query — the RAG model — the
agent compiles those documents *once* into a curated, navigable structure and then queries that
structure. Karpathy's mental model: *the note-taking app is the IDE, the LLM is the programmer, the
knowledge base is the codebase* — and like a codebase, it is maintained, refactored, and grows in
value over time. (This very wiki is built on that pattern; see [[index]] and the schema in
`CLAUDE.md`.)

In Paul Iusztin's implementation, the knowledge base is a **`memory/` folder** assembled from three
private sources — Obsidian notes, Readwise highlights, NotebookLM research — that no general-purpose
deep-research tool (Perplexity, Gemini Deep Research) can reach. The point is leverage over *your own
curated thinking*: the books you highlighted, the notes you wrote, the transcripts you dumped. That
is the signal nobody else has.

![[2026-06-30-decodingai-12-personal-llm-knowledge-base-01.png|From three scattered tools to a queryable research memory to a grounded article]]
*Figure: From three scattered tools (Obsidian, Readwise, NotebookLM) to a queryable research memory to a grounded article — the end-to-end loop in one frame — source [[2026-06-30-decodingai-12-personal-llm-knowledge-base]].*

The folder is built around an **`index.yaml`** that holds, per source, a summary plus metadata
(`origin`, `original_path`, `uri_highlights`, `uri_full`, relevance score). The agent reads the index
first, then opens only the 3–5 files it actually needs — never the whole corpus.

## Why it matters

For personal- to team-scale research (hundreds, not millions, of sources), a well-structured
`index.yaml` over files beats a RAG pipeline on nearly every axis that matters:

- **Traceability.** Every claim has full lineage back to a source URL. No chunk-to-document guessing.
- **Portability.** The self-contained `memory/` folder can be handed to any agent, which gets up to
  speed instantly. No shared vector store to provision.
- **Cost & simplicity.** No embedding model, no chunking strategy, no vector DB to maintain, no
  retrieval-eval loop. The filesystem *is* the index.
- **Compounding.** Answers are filed back as durable pages, so the same question is never researched
  from scratch twice — the inverse of RAG's re-read-everything-every-time default.

This sits alongside [[recursive-language-models]] as the second member of a broader "files over
vectors" thesis: when the corpus fits within reach of progressive disclosure, fancy retrieval is
overkill. LlamaIndex's head-to-head benchmark makes the point concretely — at sub-60-document scale a
filesystem-explorer agent beat a hybrid vector-RAG pipeline on **correctness (8.4 vs 6.4)** and
**relevance (9.6 vs 8.0)**, precisely because the model saw whole files instead of chunks.

## Key concepts / building blocks

**The index as the entry point.** `index.yaml` is the table of contents and the router. Because it
is *structured* data, the agent writes code over it — `jq` filters, Python sorts, `awk` projections —
slicing by origin, relevance threshold, tags, author, date range, or notebook.

**Progressive disclosure — three layers of detail.** The agent stays as shallow as it can:

1. **Summary** — two to three sentences per source, living in `index.yaml`, *always* loaded. Enough
   to answer "what do I have on X?" or build a table of contents.
2. **Key-highlights file** — the condensed, high-signal points. Most powerful when the highlights
   were made *manually by a human reader* (Readwise). Not every source has this layer — "it's better
   not to have it at all than to have an LLM extract it."
3. **Full document** (`uri_full`) — read only when the highlights are insufficient or absent.

![[2026-06-30-decodingai-12-personal-llm-knowledge-base-05.png|Three layers of detail per source — summary, key-highlights, full document]]
*Figure: Three layers of detail per source — the agent stays at Layer 1 (the index summary) unless it has a reason to descend — source [[2026-06-30-decodingai-12-personal-llm-knowledge-base]].*

**Raw sources are immutable.** The Obsidian/Readwise/NotebookLM files are the raw, human-maintained
data; the pipeline never writes to them. On top, a build step produces an *ephemeral* `memory/`
folder scoped to one topic — so the same raw data feeds many research projects without contamination.
(This wiki encodes the same split: an immutable `raw/` layer and a compiled `wiki/` layer.)

**CLI adapters, not MCP servers.** Each source is reached through a small CLI (`obsidian`, `readwise`,
`nlm`) rather than a [[model-context-protocol|MCP]] server — a deliberate token-economics call
(see trade-offs below). For Obsidian specifically, querying through its CLI (which uses the vault
index) is ~10× more efficient than letting the LLM roam the files.

## Design decisions & trade-offs

**Files + index over a vector store.** The defensible call at personal/team scale: trade the recall
ceiling of whole-file reading for traceability, portability, zero infra, and the ability to script
over structured metadata. The crossover point is corpus size — past many thousands of documents, or
when latency is user-facing, a [[retrieval-augmented-generation|RAG]]/[[vector-and-embedding-stores|vector]]
pipeline (or a hybrid: vector search narrows the haystack, then file-reading works the residual) wins.

**CLIs over MCP — token economics.** A Claude Code skill enters context at ~100 tokens of boot
metadata and loads its body only when invoked; an MCP server (e.g. Notion's) dumps ~20,000 tokens of
self-documenting tool definitions at startup whether used or not — roughly **200× more context before
you do anything**. CLIs also compose with bash (`jq`, redirects) without round-tripping through the
LLM, and Markdown-with-frontmatter is "more in the spirit of LLMs than MCP" (Simon Willison). The
trade-off: you give up MCP's standardised discovery and cross-client portability.

![[2026-06-30-decodingai-12-personal-llm-knowledge-base-03.png|Token economics — skill ~100 tokens vs MCP ~20,000 tokens at boot]]
*Figure: A skill enters context at ~100 tokens of metadata; an MCP server dumps ~20,000 tokens of tool definitions at boot, whether you use them or not — source [[2026-06-30-decodingai-12-personal-llm-knowledge-base]].*

**Orchestrator never loads source files.** The central invariant for keeping the build affordable:
researcher [[multi-agent-orchestration|subagents]] read raw files in isolated context windows and
hand back compacted JSON summaries (tens of thousands of input tokens → 1,000–2,000 output tokens);
the orchestrator only schedules and moves files with `mv`. Geoffrey Huntley's framing (Ralph Loops):
your primary context window should act as a *scheduler*, dispatching expensive work to subagents.
That compression ratio is the whole point.

## State of the art

The reference build is three Claude Code skills over the three CLIs:

- **`/research_create`** — builds a `memory/` folder for a topic via **multi-round query expansion
  with gap analysis**: the orchestrator dispatches one researcher subagent per query in parallel; a
  `gap_analyzer` reads deduped findings via `jq` and emits the next round's queries; a `reranker`
  scores candidates 0.0–1.0 using the cheapest sufficient signal (metadata → head/tail → full read
  last); a `builder` emits the YAML deterministically (seed URIs first at score 1.0, then descending).
- **`/research_search`** — the read side: hand any agent the folder and it queries `index.yaml` with
  progressive disclosure, never loading source files up front.
- **`/research_distill`** — given a finished draft, walks every source and extracts only the ones
  *actually used* into a single portable `research.md`, keeping downstream generation loops grounded.

![[2026-06-30-decodingai-12-personal-llm-knowledge-base-04.png|The full /research_create multi-round pipeline]]
*Figure: The full `/research_create` pipeline — the orchestrator schedules; subagents do the heavy reads — source [[2026-06-30-decodingai-12-personal-llm-knowledge-base]].*

The pattern echoes Anthropic's "code on a filesystem" guidance (models navigate filesystems well and
can read tool definitions on demand rather than all up front) and the progressive-disclosure model
inside [[agent-skill-design|agent skills]]. It is the deployable, filesystem-state cousin of
[[recursive-language-models]] — a succession of agents connected by file state rather than a
persistent shared REPL.

## Pitfalls & anti-patterns

**Letting an LLM fabricate the high-signal layer.** Auto-extracted "key highlights" dilute the very
signal that makes a human reader's manual highlights valuable. Omit the layer rather than synthesise it.

**Loading source files into the orchestrator.** Breaks the cost model — the orchestrator's context
balloons and the compression benefit evaporates. Keep reads inside subagents.

**Reaching for vectors at small scale.** Embeddings, chunking, and a vector store add infra, latency,
and a traceability gap that whole-file reading does not have. Adopt them at the crossover, not by default.

**Treating the ephemeral `memory/` folder as permanent.** It is a per-topic build over immutable raw
data; mutating raw sources through the pipeline contaminates every other project that draws on them.

**Confusing it with a chatbot over your notes.** The value is *compiled, compounding* knowledge with
lineage — not a one-shot semantic search. Skipping the compile/distill steps reduces it to RAG.

## See also

- [[recursive-language-models]] — the REPL-based sibling in the "files over vectors" thesis
- [[retrieval-augmented-generation]] — the approach this replaces at small/medium scale
- [[context-engineering]] — progressive disclosure is context engineering applied to a corpus
- [[model-context-protocol]] — the alternative integration path traded away for token economics
- [[agent-skill-design]] — progressive disclosure as a skill-design pattern
- [[multi-agent-orchestration]] — the orchestrator/subagent fan-out the build relies on
- [[agent-memory-architectures]] — the filesystem-as-memory lineage
- [[llm-application-architecture]] — where a knowledge base sits in the full LLM stack

## Sources

- Iusztin, P. (2026-04-21). *Karpathy Named It. I Built One on My Notes.* Decoding AI. https://www.decodingai.com/p/llm-knowledge-base-obsidian-readwise-notebooklm
- Karpathy, A. (2026). *LLM Knowledge Base* (gist). https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f
- LlamaIndex. (2026). *Did Filesystem Tools Kill Vector Search?* https://www.llamaindex.ai/blog/did-filesystem-tools-kill-vector-search
- raw/2026-06-30-decodingai-12-personal-llm-knowledge-base.md
