---
title: Recursive Language Models
aliases: [RLM, RLMs, recursive LM]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, llm, context-engineering, inference, orchestration]
updated: 2026-06-30
sources:
  - https://arxiv.org/abs/2512.24601
  - https://www.decodingai.com/p/recursive-language-models
  - https://www.primeintellect.ai/blog/rlm
  - https://dextralabs.com/blog/recursive-language-models-rlm/
  - https://towardsdatascience.com/going-beyond-the-context-window-recursive-language-models-in-action
  - raw/2026-06-20-recursive-language-models.md
---

# Recursive Language Models

> [!summary]
> An inference-time orchestration pattern where the model treats its input as an external REPL environment rather than loading it into the context window. The model writes code to programmatically explore, filter, and recursively process data by spawning isolated worker sub-models — scaling effective input to millions of tokens without retrieval infrastructure.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Recursive Language Models (RLMs) are an inference-time strategy that reframes the data-ingestion problem: instead of feeding a large document into the context window, the system loads it into a persistent **Read-Eval-Print Loop (REPL)** as an external variable. The model receives only metadata about the data (size, structure, a short prefix) and a symbolic handle to the REPL. It then writes Python code to selectively read, filter, chunk, or regex-match the data on demand.

When the model identifies a sub-task, it calls a primitive such as `llm_query(prompt, chunk)` to spawn a fresh, isolated **worker sub-model**. The worker processes only the relevant slice and returns a condensed result. REPL variables persist across turns, letting the root model aggregate findings progressively. The loop terminates when the model calls `FINAL(answer)`.

RLMs are model-agnostic — they work with any code-capable LLM and any data format addressable via code.

## Why it matters

The standard approaches to large-context problems each have ceilings:

- **Context stuffing (CAG):** degrades via *context rot* — attention weakens over long contexts, and earlier information loses influence. API reliability also breaks down at very large windows.
- **RAG:** solves capacity but introduces chunking strategy, embedding pipelines, vector databases, retrieval evaluation, and zigzag query patterns that inflate latency.

RLMs offer a third path: keep the data outside the window entirely and let the model navigate it programmatically. Only constant-size metadata and sub-call results enter the root model's context, keeping it bounded regardless of input size. This avoids the n-squared attention cost of stuffing while removing the retrieval infrastructure of RAG.

![[2026-06-20-recursive-language-models-01.png|RAG vs. context stuffing (CAG) vs. RLM]]
*Figure: Three approaches to large inputs — RAG (6 moving parts), context stuffing (context rot at scale), and RLMs (simple + scalable) — source [[2026-06-20-recursive-language-models]].*

> [!tip] RLMs as context engineering on autopilot
> Traditional [[context-engineering]] requires manually curating what enters the context window. RLMs delegate that decision to the model — it decides what to filter, chunk, and process on each turn.

## Key concepts / building blocks

**REPL environment.** A persistent interactive runtime (e.g. Python kernel) where variables — including the full input data — survive across iterations. The model writes and executes code; only REPL stdout (truncated) is appended to the model's history.

![[2026-06-20-recursive-language-models-02.png|RLM REPL mechanism: LLM writes code, interacts with the document as an external variable]]
*Figure: The RLM REPL mechanism — the model writes code to access the document held as an external variable, rather than loading it into context — source [[2026-06-20-recursive-language-models]].*

**Root controller.** A frontier model that plans the reasoning process, writes exploration code, and coordinates sub-calls. It never reads raw data directly — only metadata and execution results enter its context.

**Worker sub-models.** Cheaper, faster models spawned via `llm_query()` for specific localised sub-tasks. External tools (web search, file I/O) are given *only* to workers, keeping the root controller's context clean.

**`llm_query(prompt, chunk)` primitive.** The recursive call that spawns a worker. The system pauses REPL execution, runs the sub-call, and injects the result back as a REPL value.

**Aggregation buffer.** A persistent REPL variable where the model accumulates partial findings across turns. The final answer is assembled incrementally, not in one shot.

**`FINAL(answer)` termination.** An explicit signal that stops the loop and surfaces the result.

## Design decisions & trade-offs

**Root model tier.** Use a frontier model for the root controller — it is responsible for planning, code correctness, and synthesising the final answer. The cost is amortised because worker sub-calls use cheaper models. See [[model-selection-and-routing]] for the cost-quality triangle that informs this choice.

**Recursive depth.** `maxDepth = 1` is usually sufficient; deeper recursion amplifies error propagation through the call tree.

**Iteration budget.** `maxIterations` of 10–50 caps runaway cost. Calibrate to expected trajectory length for the problem class.

**REPL output truncation.** `maxStdoutLength` prevents a single verbose sub-call from flooding the root model's context. Set it aggressively — the model can re-query if needed.

**Sandboxing.** The model generates and executes arbitrary code. Production deployments require isolated execution environments (containers, VMs) with explicit permission gating for sensitive operations.

**RLM vs. RAG decision framework:**

| Favour RLMs when | Favour RAG when |
|---|---|
| No retrieval infrastructure built yet | Latency is user-facing |
| Multi-hop or exploratory reasoning needed | Corpus is large and pre-indexed |
| Document set fits on disk but not in context | Chunking quality is already tuned |
| Deep synthesis across the full corpus required | Real-time or streaming queries |

**Hybrid pattern.** For large corpora, combine both: semantic search narrows the candidate set → RLM reasons deeply over the refined subset. Retrieval narrows the haystack; RLMs work the residual.

## State of the art

The seminal paper is Zhang, Kraska & Khattab (2025), arXiv:2512.24601, from MIT CSAIL. They tested RLMs up to 10 million tokens on GPT-5 and Qwen3-Coder, showing that RLM performance degrades more slowly with input length and task complexity than base models.

Benchmark: LongBench-v2 CodeQA — Qwen3-Coder with a Python REPL outperformed the base model on codebase comprehension tasks by decomposing questions into parallel sub-queries and aggregating results.

![[2026-06-20-recursive-language-models-05.png|RLM decomposing a codebase via recursive parallel sub-queries to worker models]]
*Figure: The root model decomposes a codebase into recursive, parallel sub-queries dispatched to worker sub-models — source [[2026-06-20-recursive-language-models]].*

The only production-ready implementation as of mid-2026 is **DSPy's `dspy.RLM` module** (`dspy.ai`). Claude Code and Cursor use summarisation-based context compression, file-system state tracking, and progressive disclosure — a succession of agents connected by file state rather than a persistent shared REPL. This pattern sits at the context-assembly and retrieval+memory layers of the [[llm-application-architecture]] five-layer stack.

**Practical approximation without a true REPL:** load data into a directory with an `index.yaml` (URIs + 1–2 sentence summaries per file), expose it to the agent as metadata, and spawn focused subagents to read specific slices. The filesystem serves as a proxy for REPL state — slower but deployable today. This maps to the [[multi-agent-orchestration]] fan-out pattern applied to document exploration, and when workers run as remote agents the [[agent-to-agent-protocols|A2A protocol layer]] applies. Developed as a first-class pattern in [[llm-knowledge-base]], where an `index.yaml` over curated files replaces the retrieval stack at personal/team scale — backed by LlamaIndex's benchmark showing a filesystem-explorer agent beating hybrid vector RAG on correctness (8.4 vs 6.4) and relevance (9.6 vs 8.0) at sub-60-document scale.

## Pitfalls & anti-patterns

**Using RLMs for real-time chat.** Trajectory length variance creates unpredictable latency. Wrong use case — RLMs are for deep-thinking, batch-style workloads.

**No guardrails.** Without `maxIterations`, `maxDepth`, and `maxStdoutLength`, a single query can produce runaway API costs or infinite loops.

**Unsandboxed code execution.** The model generates and runs arbitrary Python. Production deployments without isolation are a code-execution vulnerability.

**Mistaking the filesystem approximation for the real pattern.** Agents writing results to disk and the next agent reading them lack true REPL variable persistence. Treat it as a starting point, not an equivalent.

**Not handling generated code errors.** RLMs self-correct: if generated code fails, the traceback feeds back as a REPL event and the model adjusts on the next turn. Build the harness to surface errors rather than abort on first failure.

**Applying RLMs to small inputs.** The orchestration overhead is not justified when context stuffing would suffice. Use RLMs when input genuinely exceeds comfortable context limits.

## See also

- [[context-engineering]] — the discipline RLMs automate for large inputs
- [[retrieval-augmented-generation]] — the infrastructure RLMs can replace or complement
- [[llm-application-architecture]] — where RLMs fit in the full LLM stack
- [[agentic-system-design]] — orchestrator/worker patterns RLMs instantiate
- [[multi-agent-orchestration]] — parallel sub-call coordination
- [[agent-memory-architectures]] — REPL as a short-term memory mechanism
- [[model-selection-and-routing]] — root controller vs. worker model tier selection
- [[agent-to-agent-protocols]] — protocol layer when worker sub-models run as remote agents
- [[llm-knowledge-base]] — the filesystem-state sibling: `index.yaml` over curated files in place of retrieval

## Sources

- Zhang, A. L., Kraska, T., & Khattab, O. (2025). *Recursive Language Models.* arXiv:2512.24601. https://arxiv.org/abs/2512.24601
- Iusztin, P. (2026-04-07). *Your RAG Pipeline Is Overkill.* Decoding AI. https://www.decodingai.com/p/recursive-language-models
- Prime Intellect. (2026). *Recursive Language Models: the paradigm of 2026.* https://www.primeintellect.ai/blog/rlm
- Dextra Labs. (2026). *Why Recursive Language Models (RLMs) Beat Long-Context LLMs.* https://dextralabs.com/blog/recursive-language-models-rlm/
- Mansurova, M. (2026-03-30). *Going Beyond the Context Window: Recursive Language Models in Action.* Towards Data Science. https://towardsdatascience.com/going-beyond-the-context-window-recursive-language-models-in-action
- raw/2026-06-20-recursive-language-models.md
