---
title: "Karpathy Named It. I Built One on My Notes."
aliases: [LLM Knowledge Base, personal deep research agent, memory folder index.yaml]
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, llm-knowledge-base, progressive-disclosure, deep-research, context-engineering]
updated: 2026-06-30
source_url: https://www.decodingai.com/p/llm-knowledge-base-obsidian-readwise-notebooklm
source_type: article
ingested: 2026-06-30
feeds: [llm-knowledge-base, recursive-language-models, model-context-protocol]
---

# Karpathy Named It. I Built One on My Notes.

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Date:** 2026-04-21 · **URL:** https://www.decodingai.com/p/llm-knowledge-base-obsidian-readwise-notebooklm

## Key takeaways

- An **LLM Knowledge Base** (Karpathy's term) is a deep-research agent over your *private* curated
  data — Obsidian notes, Readwise highlights, NotebookLM research — rather than the public web that
  every general-purpose deep-research tool (Perplexity, Gemini Deep Research) shares. "Your own
  curated thinking" is the edge no other user has.
- Built as **three Claude Code skills** — `/research_create` (build a `memory/` folder for a topic),
  `/research_search` (read side: query an existing `memory/` via `index.yaml`), `/research_distill`
  (extract only the sources actually used into a portable `research.md`) — over three CLI adapters
  (`obsidian`, `readwise`, `nlm`).
- **No vector DB, no RAG, no embeddings, no chunking.** The filesystem is state; Markdown + YAML +
  JSON is the wire format. References stay perfectly traceable back to source URLs.
- The `memory/` folder is built around **`index.yaml`** — per-source metadata (`uri_highlights`,
  `uri_full`, `original_path`, `origin`, summary, relevance score). The LLM reads the index first,
  then opens only 3–5 relevant files. This *is* **progressive disclosure**, the same pattern skills
  use internally.
- **Three layers of detail per source:** (1) the `summary` field in `index.yaml`, always loaded;
  (2) a key-highlights file (high signal when the highlights were made manually by a human reader —
  not every source has one, and "it's better not to have it at all than to have an LLM extract it");
  (3) the `uri_full` complete document, read only as a last resort.
- **CLIs over MCP**, for three reasons: (1) *token economics* — a skill enters context at ~100 tokens
  of metadata and loads its body only when invoked, whereas Notion's MCP server dumps ~20,000 tokens
  of self-documenting tools at startup (~200× more context before doing anything); (2) CLIs compose
  with bash (`jq`, redirects) without round-tripping through the LLM; (3) Markdown is the native
  language of LLMs (Simon Willison: MD + YAML frontmatter is "more in the spirit of LLMs than MCP").
- **Context isolation is the central design choice.** The key invariant: *the orchestrator never
  loads source files.* Researcher subagents touch raw files in isolated context windows; the
  orchestrator only sees compacted JSON summaries and moves files with `mv`. Subagents compress tens
  of thousands of input tokens into 1,000–2,000 output tokens — "that compression ratio is the whole
  point." (Geoffrey Huntley / Ralph Loops: the primary context window should act as a *scheduler*.)
- `/research_create` runs **multi-round query expansion with gap analysis**: orchestrator dispatches
  one researcher subagent per query in parallel; a `gap_analyzer` reads deduped findings via `jq`
  (no full reads) and emits the next round's queries; a `reranker` scores candidates 0.0–1.0 using
  the cheapest sufficient signal (metadata → head/tail → full read last); a `builder` emits the YAML
  deterministically (seeds first at score 1.0, then descending).

## Notable claims (with location)

- **CLI vs MCP token cost:** skill ≈ 100 tokens of boot metadata vs Notion MCP ≈ 20,000 tokens =
  "roughly 200× less context before you have done anything." (¶ "We chose CLIs over MCP…")
- **Filesystem beats vector RAG at small scale:** LlamaIndex's head-to-head benchmark — a
  filesystem-explorer agent beat a hybrid vector-RAG pipeline on **correctness (8.4 vs 6.4)** and
  **relevance (9.6 vs 8.0)** at sub-60-document scale, precisely because the LLM saw whole files
  instead of chunks. (¶ after Image 8)
- **"For personal-scale research involving hundreds of sources, a well-structured `memory/` folder
  with an `index.yaml` beats a RAG pipeline on every axis"** — full lineage to source URLs,
  portability, lower cost (no embedding model or vector store). (§ What's Next)
- Ties explicitly to **Recursive Language Models**: "when the corpus fits in context with progressive
  disclosure, fancy retrieval is overkill." (§ How /research_distill Works, citing the author's RLM post)
- Subagent compression: tens of thousands of input tokens → **1,000–2,000 output tokens** per file.
- For Obsidian, using its CLI (which leverages its index) is **~10× more efficient** than letting the
  LLM roam the vault.

## Key visuals

> Curated, localized diagrams. Dropped: the `memory/`-dir screenshot, two `index.yaml` code
> screenshots, and the course-ad GIF (chrome / output-screenshot per the keep-drop rubric).

- ![[2026-06-30-decodingai-12-personal-llm-knowledge-base-01.png|From three scattered tools to a queryable research memory to a grounded article]] — the end-to-end loop in one frame
- ![[2026-06-30-decodingai-12-personal-llm-knowledge-base-02.png|System at a glance — three skills, three CLI adapters, one memory folder]] — overall architecture
- ![[2026-06-30-decodingai-12-personal-llm-knowledge-base-03.png|Token economics — skill ~100 tokens vs MCP ~20,000 tokens at boot]] — the CLI-over-MCP argument
- ![[2026-06-30-decodingai-12-personal-llm-knowledge-base-04.png|The full /research_create multi-round pipeline]] — orchestrator schedules, subagents read
- ![[2026-06-30-decodingai-12-personal-llm-knowledge-base-05.png|Three layers of detail per source]] — progressive disclosure: summary → key-highlights → full doc

## Feeds these wiki pages

- [[llm-knowledge-base]]
- [[recursive-language-models]]
- [[model-context-protocol]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
