---
title: Multi-Agent Orchestration
aliases: [multi-agent systems, agent orchestration]
type: concept
domain: ai-agentic
priority: P0
roadmap_ref: "1.1.1"
status: draft
tags: [ai-agentic, agents, orchestration, workflows]
updated: 2026-06-19
sources:
  - "https://www.anthropic.com/engineering/building-effective-agents"
---

# Multi-Agent Orchestration

> [!summary]
> The coordination of multiple LLM calls/agents toward a shared goal — deciding how work is
> split, ordered, and recombined. The first architectural fork is **workflow vs. agent**:
> *workflows* orchestrate LLMs and tools through **predefined code paths** (predictable,
> debuggable); *agents* let the model **dynamically direct** its own process (flexible,
> costlier, harder to control). Most production value comes from the five composable workflow
> patterns — reach for autonomous, dynamically-orchestrated agents only when the subtask graph
> genuinely can't be predicted.

**Priority:** 🔴 P0 · **Domain:** [[tier-1-edge|AI & Agentic Architecture]] · **Roadmap:** §1.1.1

## What it is

Multi-agent orchestration is the design discipline of arranging several LLM calls — each with
its own role, tools, and context — so they collaborate reliably on tasks too large or too
varied for one call. The orchestrator chooses an execution topology and manages how outputs
flow between participants. The goal is to gain specialization and parallelism *without* losing
coherence or control. Per Anthropic's [[agentic-system-design|"Building Effective Agents"]]
guidance, the foundational unit underneath all of this is the **augmented LLM** (a model with
retrieval, tools, and memory), and the right default is the *simplest* composition that works.

## Why it matters (2026, senior architect lens)

Orchestration is where cost, latency, and reliability are won or lost. A predefined **workflow**
gives you predictability, easy evaluation, and a debuggable code path; a dynamic **agent** buys
flexibility at the price of non-determinism, token blow-up, and compounding errors. The senior
move is to **name the topology explicitly** and justify each step up the complexity ladder —
not to default to "a swarm of agents" because it demos well. The same orchestration choices
drive [[ai-gpu-economics|token economics]] and [[ai-agent-observability|observability]] burden.

## Key concepts / building blocks

The five composable patterns, in increasing complexity (Anthropic):

- **Prompt chaining** — sequential steps, each LLM call processing the previous output, with
  programmatic *gates* between them. For tasks that cleanly decompose into fixed subtasks;
  trades latency for accuracy.
- **Routing** — classify the input, then dispatch to a specialized follow-up (and often a
  cheaper/expensive model split, e.g. Haiku for easy, Sonnet for hard). Separation of concerns.
- **Parallelization** — *sectioning* (independent subtasks run concurrently) and *voting*
  (same task run N times for diverse outputs / thresholded decisions). For speed or confidence.
- **Orchestrator-workers** — a central LLM **dynamically** decomposes the task, delegates to
  worker LLMs, and synthesizes results. Topologically like parallelization, but subtasks are
  **determined at runtime**, not pre-defined. The canonical dynamic multi-agent pattern
  (e.g. a coding change across an unknown set of files).
- **Evaluator-optimizer** — a generator LLM and a critic LLM in a refinement loop; for tasks
  with clear evaluation criteria where iteration measurably helps.

Above these sit **autonomous agents**: LLMs using tools in a loop on environmental feedback,
planning independently with stopping conditions.

## Design decisions & trade-offs

| Decision | The real trade-off |
|---|---|
| **Workflow vs. agent** | Predictability/debuggability vs. flexibility. Use a workflow whenever the control flow is knowable; reserve agents for unpredictable step counts. |
| **Predefined vs. dynamic decomposition** | Parallelization (fixed subtasks) is cheaper and more testable than orchestrator-workers (runtime subtasks). Only pay for dynamism when you can't enumerate the subtasks. |
| **Sequential vs. parallel** | Latency vs. token cost and coordination overhead. Parallel fan-out cuts wall-clock but multiplies tokens and needs result aggregation. |
| **One model vs. tiered** | Routing easy work to cheaper models saves cost but adds a classification failure surface. |
| **How much autonomy** | Autonomy scales to open-ended tasks but raises cost and compounding-error risk — confine to trusted/sandboxed environments with guardrails. |

## State of the art (2026)

The field has converged on Anthropic's framing: **start simple, add agents last.** Independent
results reinforce restraint — under a fixed compute budget single agents often match multi-agent
systems, and large-scale trace studies find multi-agent frameworks failing at high rates from
specification/coordination/verification gaps (see [[agentic-system-design]]). Frameworks
(Claude Agent SDK, LangGraph, Strands, CrewAI) make orchestration easier but add abstraction
that can obscure the underlying prompts; understand the code beneath them. Hand-offs and
contracts between agents are covered in [[agent-to-agent-protocols]].

## Pitfalls & anti-patterns

- **Reaching for orchestrator-workers** when fixed parallelization (or a single call) would do.
- **Over-decomposition** — so many tiny agents that coordination overhead dwarfs the work.
- **Ignoring the bill** — treating an N× token multiplier as free because the demo worked once.
- **No gates** between chained steps, so an early error propagates silently.
- **Framework lock-in without understanding** the prompts/loops underneath.

## See also

- [[agentic-system-design]]
- [[agent-to-agent-protocols]]
- [[human-in-the-loop-design]]
- [[agents-as-system-citizens]]
- [[model-selection-and-routing]]
- [[ai-agent-observability]]
- [[context-engineering]]

## Sources

- [Anthropic — Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) (workflows vs. agents; the five composable patterns; orchestrator-workers; ACI principles) — captured at [[2026-06-19-anthropic-building-effective-agents]]
