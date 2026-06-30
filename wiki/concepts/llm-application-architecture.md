---
title: LLM Application Architecture
aliases: [LLM app stack, LLM application stack, LLM system design]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, llm, architecture, system-design, rag, orchestration]
updated: 2026-06-30
sources:
  - raw/2026-06-22-edi-00-series-intro.md
  - https://www.anthropic.com/research/building-effective-agents
  - https://arxiv.org/abs/2312.10997
  - https://arxiv.org/abs/2407.01421
  - https://python.langchain.com/docs/introduction
  - https://microsoft.github.io/semantic-kernel/
  - https://arxiv.org/abs/2401.18059
---

# LLM Application Architecture

> [!summary]
> LLM application architecture is the end-to-end design of a production system built around a language model: how context is assembled, how external knowledge is retrieved, how memory persists, how outputs are validated, and how the model fits into — rather than becomes — the overall application.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

The LLM is one component in a system, not the system itself. A production LLM application surrounds the model with infrastructure that compensates for its limitations: a retrieval layer because the model's training knowledge is bounded; a context assembly layer because inputs must be structured within the token window; a memory layer because the model is stateless between calls; a validation layer because outputs are probabilistic; and an orchestration layer because complex tasks require multiple sequential or parallel calls.

This page describes the canonical stack layers, the reference architectures built from them, and the design decisions that connect them. The progression runs from the simplest deployment (direct prompt → model → response) through RAG to full agentic systems.

## Why it matters

Most LLM project failures are not model failures — they are application failures: context assembled in the wrong order, retrieval returning irrelevant chunks, no retry logic on tool errors, no validation of structured output format. The model's capabilities are a ceiling; the application architecture determines how close to that ceiling actual quality reaches.

Understanding the stack matters for cost as well. The largest cost levers — [[context-engineering|prompt caching]], [[model-selection-and-routing|routing to cheaper models]], batch inference — are architectural decisions made at design time, not at model-selection time.

## Key concepts

### The stack layers

A production LLM application has five layers, each composable independently:

```
┌─────────────────────────────────────┐
│         Orchestration Layer          │  workflow routing, multi-step control
├─────────────────────────────────────┤
│         Context Assembly Layer       │  prompt construction, token budgeting
├──────────────┬──────────────────────┤
│  Retrieval   │     Memory Layer      │  RAG / search  │  short-term + long-term
│  Layer       │                       │
├──────────────┴──────────────────────┤
│              Model API Layer         │  model calls, streaming, tool use
├─────────────────────────────────────┤
│         Validation & Safety Layer    │  output parsing, guardrails, retries
└─────────────────────────────────────┘
```

**Model API layer.** The call to the model: input tokens in, output tokens out. Key design points: streaming vs. batch, tool/function calling schema, structured output mode (JSON mode, tool-use schema), and [[model-selection-and-routing|model routing]]. Prompt caching targets the system prompt section of this call.

**Retrieval layer.** External knowledge the model does not have is fetched on demand. [[retrieval-augmented-generation|RAG]] is the dominant pattern: embed the query → retrieve top-k chunks from a [[vector-and-embedding-stores|vector store]] → inject into context. Hybrid search (dense + BM25 via RRF) is the 2025–2026 production baseline. [[graphrag|GraphRAG]] extends this for multi-hop relational queries.

**Memory layer.** The model is stateless; memory is the application's responsibility. Three tiers: *in-context* (conversation history in the current window), *external short-term* (key-value store for session state), *external long-term* ([[agent-memory-architectures|episodic and semantic stores]]). For single-turn applications the in-context tier suffices; agentic systems require all three.

**Context assembly layer.** Constructs the input that goes to the model. The standard layout: system prompt → retrieved context → conversation history → user message → tool results. Token budget allocation (how many tokens each zone gets) and ordering (recency bias, lost-in-the-middle effects) are [[context-engineering]] decisions with measurable quality impact.

**Orchestration layer.** For multi-step tasks, controls the sequence of model calls, tool calls, and conditional branches. Simple chains are linear (`prompt → model → parse → tool → model`); agentic workflows use loops, parallel branches, and sub-agent delegation. See [[agentic-system-design]] and [[multi-agent-orchestration]].

**Validation and safety layer.** Parses model output into the expected format (Pydantic, JSON Schema), retries on malformed output, and applies [[guardrails-and-output-validation|guardrails]]. Also the layer where [[prompt-injection]] input sanitisation lives.

### Reference architectures

**Simple prompt → response.** One model call; no retrieval, no memory, no orchestration. Appropriate for: classification, extraction from a provided document, code generation from a specification. The entire application logic lives in the system prompt and the output parser.

**RAG pipeline.** Query → embed → retrieve → assemble context → model → validate. The workhorse for knowledge-intensive applications. The retrieval step is the main quality variable; context assembly order is secondary. See [[retrieval-augmented-generation]] for the full pattern.

![[2026-06-22-edi-00-series-intro-01.png|Baseline RAG pipeline: inputs, pipeline, outputs]]
*Figure: A baseline RAG reference architecture — document/question parsing, retrieval, generation, and validated JSON output — source [[2026-06-22-edi-00-series-intro]].*

**Agentic loop.** The model decides at each step which tool to call based on the current state. The loop continues until the model emits a `FINAL` signal or a stopping condition is met (max iterations, budget). See [[agentic-loop]] for the architectural primitives. The application must manage state serialisation, [[human-in-the-loop-design|interrupt/resume]], and error recovery.

**Multi-agent workflow.** An orchestrator model routes sub-tasks to specialised agents. Each sub-agent has its own context window, tool set, and memory scope. The orchestrator synthesises results. Appropriate when: the task is too large for one context window, sub-tasks benefit from specialist models, or parallelism reduces latency. See [[multi-agent-orchestration]].

### Tool use and function calling

Tool use is the mechanism by which the model requests external actions. The model emits a structured tool call (tool name + arguments); the application executes it; the result is injected back into context. This pattern underlies all agentic behaviour.

Design principles for tool schemas:
- **One tool per action** — avoid multi-action tools; they make routing and validation harder.
- **Include examples in the tool description** — models use description content as the primary signal for when to invoke a tool.
- **Return structured results** — JSON responses are easier for the model to parse than free text; reduce hallucinated field values.
- **Design for partial failure** — every tool call may fail; the system must handle timeouts, permission errors, and malformed results gracefully.

[[model-context-protocol|MCP]] (Model Context Protocol) is the emerging standard for tool registration and execution, providing a discoverable, server-hosted tool registry that any MCP-compatible client can connect to.

### Streaming and latency

For user-facing applications, streaming (token-by-token output delivery) is the UX standard. Time-to-first-token (TTFT) is the perceived latency. Architecture implications:

- Place the model call as early in the pipeline as possible (retrieve in parallel with the model call if retrieval is query-independent).
- Avoid synchronous post-processing that blocks the stream (validation can run on a finalised buffer, not mid-stream).
- Use [[observability-fundamentals|distributed tracing]] to measure per-step latency; the retrieval step is frequently the bottleneck, not the model call.

### Caching strategy

Three caching tiers:

| Tier | What is cached | Savings |
|---|---|---|
| Prompt cache | Stable system prompt prefix | 90 % cost reduction on cached tokens (Anthropic/Google native) |
| Semantic cache | Full request → response, keyed by embedding similarity | 100 % cost savings on cache hits; adds ~5 ms lookup |
| Retrieval cache | Embedding vectors for frequently queried documents | Eliminates re-embedding cost; Redis/in-memory TTL |

Prompt caching requires the cached prefix to be identical byte-for-byte. Design the system prompt so the stable prefix (persona, tools, rules) comes first; dynamic content (user context, session data) follows.

## Design decisions and trade-offs

**Framework vs. custom orchestration.** LangChain, LlamaIndex, and Semantic Kernel offer pre-built chains, integrations, and retrieval pipelines. The trade-off: faster to bootstrap; harder to debug production failures (abstraction layers obscure tool calls and token counts). Anthropic's own guidance (*Building Effective Agents*) recommends starting with the minimum necessary abstraction — direct API calls plus lightweight utility functions — and introducing framework components only when they demonstrably reduce complexity.

**Stateless vs. stateful design.** Stateless application servers (each request is self-contained) are easier to scale horizontally and have no session-state consistency problems. Stateful designs (persistent conversation threads, long-running agent sessions) require a session store, increase blast radius of server failures, and need explicit eviction policies. Default to stateless; introduce statefulness only where the user experience requires it.

**Monolithic vs. modular context.** Assembling the entire context in one place (monolithic) is simple to reason about. Distributing context assembly across middleware (plugins, injectors) is more flexible but makes the final prompt opaque. Prefer a single, inspectable context assembly function with logged output; modular injection complicates debugging.

**Single-model vs. multi-model.** A single-model application is simpler, cheaper to debug, and avoids inter-model consistency problems. Multi-model (router → specialist models) reduces cost and enables capability matching but adds routing logic, fallback handling, and evaluation complexity. Justify multi-model with measured cost savings, not theoretical efficiency.

**Synchronous vs. event-driven.** HTTP request/response is the default and easiest to reason about. Event-driven designs (queue-based task dispatch, webhook callbacks) enable long-running tasks and decoupling of producers and consumers. Use event-driven when: task duration exceeds typical HTTP timeout (>30 s), the caller does not need to wait, or throughput requirements exceed what synchronous handling can provide.

## State of the art

**Orchestration frameworks (mid-2026):**
- **LangGraph** (GA v1.0, LangChain) — graph-based workflow with persistent checkpointing, interrupt/resume, and sub-graph composition. The production choice for stateful agentic workflows.
- **Anthropic Agent SDK v0.1.48** — minimal orchestration layer designed around the Anthropic API's native tool use; low abstraction, high debuggability.
- **Semantic Kernel (Microsoft)** — enterprise-oriented; strong Azure integration, plugin model compatible with OpenAI and Anthropic; used in Copilot Stack.
- **LlamaIndex** — retrieval-first; best-in-class for RAG pipeline construction, document parsing pipelines, and hybrid search integration.

**Tool integration:** MCP (Model Context Protocol, Anthropic 2024) has been adopted by all major LLM providers and IDE vendors (VS Code, JetBrains, Cursor) as the standard for discoverable tool registries.

**Structured output:** native JSON mode and `tool_use` schema are now standard across Anthropic, OpenAI, and Google APIs, eliminating the need for regex-based output parsing in most cases. Pydantic + Instructor remains the preferred library for type-safe, retry-equipped structured extraction.

**Production pattern (Anthropic Building Effective Agents, 2024):** start with the simplest workflow that solves the problem — often a single augmented LLM call. Add complexity (parallelisation, sub-agents, loops) only when the simpler design demonstrably fails. Complexity compounds failure modes.

> [!tip]
> The simplest architecture that works is always preferable. Before adding retrieval, check whether a well-structured prompt with a long context window solves the problem. Before adding orchestration, check whether a single model call with tool use suffices. Every added layer is a new failure mode.

## Pitfalls and anti-patterns

- **Framework-first design.** Choosing LangChain or LlamaIndex before understanding what the application actually needs leads to fighting the framework's abstractions. Start with direct API calls; extract helpers when patterns repeat.
- **Context stuffing.** Injecting as much context as possible into the window without regard to relevance order or token budget degrades quality (lost-in-the-middle) and inflates cost. Budget deliberately: system prompt, retrieved context, history, user turn — each zone has a target size.
- **No streaming.** Users perceive a 3-second wait for the first token as fast; a 3-second wait for the full response as slow. Add streaming to all user-facing endpoints.
- **Synchronous long-running tasks over HTTP.** Tasks that take >10 seconds should be async (queue + webhook or polling) — not a hung HTTP connection.
- **Ignoring tool error handling.** Tools fail (timeouts, permission denied, malformed input). An agent with no error recovery strategy will stall or hallucinate a resolution. Design explicit retry, fallback, and escalation paths for every tool.
- **No observability.** Without tracing, a quality regression in production is undiagnosable. Instrument every model call and tool call with a trace ID from the start.
- **Mutable system prompts.** System prompt changes are application changes; they should go through version control, eval suites, and staged rollout — not ad-hoc edits in a database.

## See also

- [[clean-architecture-for-ai-systems]] — how to lay out these stack layers in a codebase (dependency rule, four layers)
- [[agentic-system-design]] — the architectural patterns for autonomous agent behaviour
- [[context-engineering]] — context budget allocation and prompt caching
- [[retrieval-augmented-generation]] — the retrieval layer in depth
- [[agent-memory-architectures]] — the memory layer in depth
- [[model-selection-and-routing]] — routing to the right model for each request
- [[ai-gateway]] — the control-plane proxy that fronts providers with routing, budgets, caching, and guardrails
- [[guardrails-and-output-validation]] — the validation and safety layer
- [[model-context-protocol]] — tool registration and execution standard
- [[agentic-loop]] — loop engineering for repeating agentic tasks
- [[ai-evaluation-and-quality]] — the eval harness that governs all of the above
- [[ai-agent-observability]] — tracing and monitoring in production

## Sources

- Anthropic (2024). *Building Effective Agents.* Anthropic Research Blog. https://www.anthropic.com/research/building-effective-agents
- Zhao, W. et al. (2023). *A Survey of Large Language Models.* arXiv:2303.18223.
- Wu, Q. et al. (2023). *AutoGen: Enabling Next-Gen LLM Applications via Multi-Agent Conversation.* arXiv:2308.08155.
- Chase, H. (2024). *LangChain Introduction.* https://python.langchain.com/docs/introduction
- Microsoft (2024). *Semantic Kernel — Open-Source SDK for LLM Apps.* https://microsoft.github.io/semantic-kernel/
- Guo, X. et al. (2024). *Large Language Model Based Multi-Agents: A Survey of Progress and Challenges.* arXiv:2402.01680. https://arxiv.org/abs/2401.18059
