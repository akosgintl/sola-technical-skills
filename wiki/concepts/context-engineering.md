---
title: Context Engineering
aliases: [context window management, context window design, prompt context design, context curation]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, llm, context, context-window, prompt-engineering, rag, caching]
updated: 2026-06-21
sources:
  - "https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents"
  - "https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents"
  - raw/2026-06-20-recursive-language-models.md
  - "https://arxiv.org/abs/2307.03172"
  - "https://arxiv.org/abs/2406.16008"
  - "https://arxiv.org/abs/2604.01664"
  - "https://agentmarketcap.ai/blog/2026/04/11/agent-context-engineering-sliding-windows-memory-2026"
  - "https://blog.jetbrains.com/research/2025/12/efficient-context-management/"
  - raw/2026-06-21-loop-engineering.md
---

# Context Engineering

> [!summary]
> Context engineering is the discipline of deciding what information enters a model's context window — what to include, in what form, in what order, and how much. It extends beyond prompt engineering to cover the full lifecycle of information flowing into every LLM call: retrieval, compression, ordering, pruning, and window budgeting. As context windows grew from 4K to 1M+ tokens, the bottleneck shifted from capacity to signal-to-noise: context engineering is now where most of an agent system's quality and cost is won or lost.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Context engineering is the practice of designing the information architecture around each LLM call, not just the prompt text. It treats the context window as a **finite, expensive resource** to be curated — selecting what to include, compressing what has grown stale, ordering information for maximum attention, and offloading the rest to external memory or retrieval systems.

Anthropic's September 2025 post ["Effective context engineering for AI agents"](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) crystallized the field shift: building with language models had moved from *"find the right words"* (prompt engineering) to *"design the right information configuration"* — covering system prompts, retrieved documents, conversation history, tool outputs, and the interleaving of all of them. The key question is not what to say but what to show.

## Why it matters

**Context failures dominate production agent issues.** A 2025–2026 analysis of enterprise AI deployments found that nearly 65% of agent failures were attributable to context drift or memory loss during multi-step reasoning — not model capability gaps.

**More context ≠ better output.** The "lost in the middle" problem (Liu et al., 2023; arXiv:2307.03172) demonstrated a 30%+ accuracy drop on multi-document QA when the relevant document shifted from position 1 to position 10 in a 20-document context. A 2024 calibration study (arXiv:2406.16008) confirmed a U-shaped attention bias: models reliably attend to the start and end of context, while the middle competes against strong positional anchors.

**Cost and latency are linear in token count.** Every token in the context window costs inference time and money. Context engineering is simultaneously a quality problem and a FinOps problem — the same decisions that improve output quality reduce per-call cost.

## Key concepts / building blocks

### Context window budgeting

The context window is divided into competing zones, each with a cost:

| Zone | Content | Typical allocation |
|---|---|---|
| System prompt | Instructions, persona, tool definitions | 10–30% |
| Retrieved context | RAG chunks, memory, tool outputs | 30–60% |
| Conversation history | Prior turns, summaries | 10–30% |
| Generation headroom | Space for the model's output | 10–20% |

Budget each zone explicitly. When any zone grows, another must shrink. Without explicit budgeting, conversation history expands until it crowds out retrieved context.

### Information ordering

LLM attention exhibits a **U-shaped positional bias**: information at the start and end of context receives the most reliable attention; the middle is systematically under-attended.

Practical implications:
- Put the most critical instruction or constraint **first** in the system prompt
- Put the most relevant retrieved content **last** (closest to the generation point)
- Don't bury critical facts in the middle of long context blocks
- Use structured delimiters (XML tags, headers) to make structure explicit and help the model identify where high-signal content lives

### Compression and summarization

For long-running agents, verbatim history grows without bound. Three compression patterns in order of fidelity:

1. **Sliding window (Keep-Last-N)** — retain only the most recent N turns verbatim; drop everything older. Cheapest; loses early context permanently.
2. **Hierarchical summarization** — compress older turns into progressively shorter summaries. Retains semantics; costs an extra LLM call per summarization pass.
3. **Selective preservation** — extract and preserve key facts, decisions, and constraints from older turns; discard narrative. Highest fidelity; requires extraction logic.

The 2026 production consensus is a layered approach: sliding window for the live session, hierarchical summarization for sessions older than N turns, memory offloading for long-term retention (see [[agent-memory-architectures]]).

### Prompt caching

Anthropic's prompt caching (available on Claude 3.x+) caches the KV state of the context prefix, delivering up to 90% cost reduction and 85% latency reduction on cache hits. The key design constraint: **the cached prefix must be stable across calls**. Long, dynamic system prompts that change per-request destroy cache efficiency.

Design implications:
- Move stable content (instructions, tool definitions, reference material) as high in the system prompt as possible
- Move dynamic content (current date, user-specific context, live data) to the end of the system prompt or into the user turn
- Use explicit `cache_control: ephemeral` breakpoints at the stability boundary

### Relevance selection and retrieval

Not all retrieved content is equally relevant. Relevance selection decisions:

- **Top-k filtering** — retrieve only the k most similar chunks; trade recall for density
- **Reranking** — use a cross-encoder to re-score candidates post-retrieval (higher quality, extra latency)
- **Maximal marginal relevance (MMR)** — penalize redundancy; prefer diverse, complementary chunks
- **Query expansion** — rewrite the query before retrieval to surface more relevant results
- **Late chunking** — chunk at retrieval time rather than ingestion time to preserve document-level embeddings

### Three patterns for large inputs

When input exceeds comfortable window capacity, there are three architectural patterns:

| Pattern | Mechanism | Infrastructure cost | Latency | Quality risk |
|---|---|---|---|---|
| Context stuffing (CAG) | Load everything into one call | None | Low | Context rot at long lengths |
| RAG | Retrieve relevant chunks via embeddings | High (vector DB, chunking pipeline, retrieval eval) | Medium | Retrieval misses; zigzag query patterns |
| [[recursive-language-models\|RLMs]] | Model navigates data as external REPL variable | Low (just a sandboxed runtime) | High / variable | Code fragility; error propagation |

RLMs represent a shift from *manual* context curation to *programmatic* curation: the model itself decides what to read, filter, and summarize on each turn, eliminating the need to predetermine what fits. See [[recursive-language-models]] for the full treatment.

## Design decisions & trade-offs

**Summarize vs. truncate vs. retrieve:**
- Truncation (sliding window) is cheapest and loses early context; use when the recent turns are sufficient.
- Summarization preserves semantics but costs an extra LLM call and introduces compression artifacts; use for medium-term retention.
- Retrieval (RAG / agent memory) is the right answer when the agent runs across sessions or accumulates knowledge over time; see [[agent-memory-architectures]] for the graph-backed approach.

**When to compress proactively vs. reactively:**
Reactive compression (trigger when window exceeds threshold) causes latency spikes mid-task. Proactive compression (maintain a rolling summary after each turn) keeps latency predictable but adds baseline cost. Prefer proactive for user-facing agents; reactive for batch pipelines.

**Cache design as a first-class constraint:**
Treat prompt caching hit rate as a KPI alongside latency and cost. A 10% cache miss rate on a high-volume agent endpoint can flip the economics of the entire system.

**ContextBudget (arXiv:2604.01664)** — a 2026 approach that treats the remaining context capacity as a first-class runtime signal: the agent receives real-time feedback on remaining token budget and autonomously adjusts retrieval depth and verbosity to stay within budget without external truncation.

## State of the art

Anthropic's [September 2025 post](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) catalyzed industry recognition of context engineering as a distinct discipline — distinct from prompt engineering and from RAG. Their follow-up ["Effective harnesses for long-running agents"](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) addressed the operational side: context management across tool call loops, managing growing output artifact sizes, and preventing runaway context accumulation.

By 2026, production teams have converged on three complementary patterns (AgentMarketCap, 2026):
1. **Sliding window** for live session history
2. **Hierarchical summarization** for session archives
3. **Memory offloading** (graph-backed agent memory) for cross-session retention

Context-aware adaptive routing is emerging: AgentSwing (arXiv:2603.27490) dynamically routes long-horizon web agent tasks across parallel context management strategies based on real-time window utilization signals — a preview of context management becoming a runtime control loop rather than a static design decision.

LOCA-bench (arXiv:2602.07962) provides a reproducible benchmark for agent context degradation under extreme context growth — the first standardized measure of "context rot" in production-realistic multi-step tasks.

By mid-2026, the leading edge has moved beyond per-call context decisions toward [[agentic-loop|loop engineering]]: designing loops in which the agent autonomously manages its own context cycles — loading skills, invoking tools, summarizing intermediate state — without per-step human prompting. Context engineering decisions (window budgeting, compression strategy, cache layout, skill density) remain essential; in loop architectures they become the substrate that loop designers specify once in skills and memory, rather than curating on every call.

## Pitfalls & anti-patterns

**Context stuffing.** Dumping all available information into the context window assumes the model will filter it — but context rot and the lost-in-the-middle bias mean it won't. Summarize and select; don't trust the model to ignore irrelevant tokens.

**Uniform truncation.** Dropping the oldest turns without summarization discards the early instructions and constraints that framed the task. Always summarize before truncating turns that contain task-critical context.

**Dynamic system prompts.** Changing the system prompt per-request destroys prompt cache hit rate. Cache savings compound across calls; a volatile system prompt can eliminate them entirely.

**No context budget monitoring.** In long-running agents, tool output size is unpredictable. Without monitoring, a single verbose tool response can consume the remaining window mid-task, causing silent truncation or hard errors.

**Treating context engineering as prompt engineering.** Context engineering is an architecture discipline: it involves data pipelines (chunking, embedding), storage (vector DBs, graph memory), runtime loops (summarization, retrieval), and cost modeling. It cannot be solved by rewriting the system prompt.

## See also

- [[agentic-loop]]
- [[llm-application-architecture]]
- [[retrieval-augmented-generation]]
- [[recursive-language-models]]
- [[agent-memory-architectures]]
- [[graphrag]]
- [[model-selection-and-routing]]
- [[ai-gpu-economics]]

## Sources

- Anthropic. (2025-09-29). Effective context engineering for AI agents. https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- Anthropic. (2025). Effective harnesses for long-running agents. https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- Liu, N. F., et al. (2023). Lost in the Middle: How Language Models Use Long Contexts. arXiv:2307.03172. https://arxiv.org/abs/2307.03172
- Peysakhovich, A., & Lerer, A. (2024). Found in the Middle: Calibrating Positional Attention Bias Improves Long Context Utilization. arXiv:2406.16008. https://arxiv.org/abs/2406.16008
- Iusztin, P. (2026-04-07). Your RAG Pipeline Is Overkill. Decoding AI. https://www.decodingai.com/p/recursive-language-models
- AgentMarketCap. (2026-04-11). Agent Context Engineering 2026: Sliding Windows, Hierarchical Summarization, and Memory Offloading. https://agentmarketcap.ai/blog/2026/04/11/agent-context-engineering-sliding-windows-memory-2026
- JetBrains Research. (2025-12). Cutting Through the Noise: Smarter Context Management for LLM-Powered Agents. https://blog.jetbrains.com/research/2025/12/efficient-context-management/
- Wang, Y., et al. (2026). ContextBudget: Budget-Aware Context Management for Long-Horizon Search Agents. arXiv:2604.01664. https://arxiv.org/abs/2604.01664
- François, L. (2026). Loop Engineering Explained. Towards AI / YouTube. raw/2026-06-21-loop-engineering.md
