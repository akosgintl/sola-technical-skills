---
title: Agentic System Design
aliases: [agentic architecture, agent system design, single-agent vs multi-agent, agent topologies]
type: concept
domain: ai-agentic
status: mature
tags: [agents, orchestration, multi-agent, llm, system-design, human-in-the-loop]
updated: 2026-06-19
sources:
  - "https://www.anthropic.com/research/building-effective-agents"
  - "https://cognition.ai/blog/dont-build-multi-agents"
  - "https://www.anthropic.com/engineering/built-multi-agent-research-system"
  - "https://blog.langchain.com/how-and-when-to-build-multi-agent-systems/"
  - "https://www.langchain.com/resources/ai-agent-frameworks"
  - "https://arxiv.org/abs/2604.02460"
  - "https://openreview.net/forum?id=fAjbYBmonr"
---

# Agentic System Design

> [!summary]
> Agentic system design is the discipline of deciding **how many** LLM-driven agents
> a problem needs, **how they are wired together** (sequential vs. parallel, flat vs.
> hierarchical), **how control and context flow** between them, and **where humans sit**
> in the loop. The core judgment is restraint: start with the
> simplest single-agent loop, add a workflow before adding an agent, and add a second
> agent only when context isolation or true parallelism justifies the steep tax in
> tokens, latency, debuggability, and failure surface that multi-agent buys you.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

An **agent** is an LLM running in a loop: it observes, calls tools, reads the results,
and decides the next action until a stopping condition is met. **Agentic system design**
is the architecture *around* that loop — the topology of one or more agents, the control
and data flow between them, and the human checkpoints that make the whole thing safe to
own in production.

Anthropic's influential framing draws a sharp line between two things people lump
together as "agents":

- **Workflows** — LLM calls orchestrated through *predefined* code paths (prompt
  chaining, routing, parallelization). Deterministic scaffolding; the control flow is
  written by you, not decided by the model.
- **Agents** — the model *dynamically* directs its own process and tool use, deciding
  the control flow at runtime.

![[2026-06-19-anthropic-building-effective-agents-07.png|Autonomous agent: an LLM acting in a loop on environmental feedback until a stop condition]]
*Figure: Autonomous agent — the LLM plans and acts in a loop on environmental feedback, with explicit stopping conditions. Source [[2026-06-19-anthropic-building-effective-agents]].*

![[2026-06-19-anthropic-building-effective-agents-08.png|High-level flow of a coding agent as a concrete autonomous-agent example]]
*Figure: A coding agent as a concrete instance of the autonomous loop. Source [[2026-06-19-anthropic-building-effective-agents]].*

Most production "agentic" systems are actually workflows with one genuinely agentic
component, and that is usually the right answer. The design space this page navigates
is: **single agent vs. multiple agents**, and if multiple, **what topology and what
coordination contract** binds them.

![[2026-06-23-decodingai-01-ai-workflows-vs-agents-04.png|The autonomy slider from fully-controlled workflows to fully-autonomous agents]]
*Figure: Workflow vs. agent is a slider, not a binary — autonomy increases from fixed code paths to model-directed control — source [[2026-06-23-decodingai-01-ai-workflows-vs-agents]].*

## Why it matters

Agentic design is where the most expensive architecture mistakes are made,
because the failure mode is *seductive*: a multi-agent demo looks sophisticated, maps
neatly onto an org chart, and feels like good decomposition — then it ships and the
context fragments, the token bill multiplies, and nobody can debug a non-deterministic
five-agent conversation in production.

The key discipline here is **resisting premature distribution**. The same instinct that
stops you from splitting a monolith into 30 [[service-decomposition|microservices]] before you understand the
domain should stop you from splitting one agent into a swarm. Anthropic's own guidance
leads with *"find the simplest solution possible, and only increase complexity when
needed. This might mean not building agentic systems at all."* That sentence is the whole
job.

The economics are unforgiving. Anthropic reported their multi-agent research system used
roughly **15× the tokens** of a single chat interaction — viable for high-value research
tasks, ruinous for routine ones. A Stanford study by Tran & Kiela (2026) —
*Single-Agent LLMs Outperform Multi-Agent Systems on Multi-Hop Reasoning Under Equal
Thinking Token Budgets* — found that **under a fixed compute budget, single agents
frequently match or beat multi-agent systems**, and that many claimed multi-agent wins are
unaccounted-for extra computation rather than architectural benefit. Meanwhile the **MAST**
trace study (*Why Do Multi-Agent LLM Systems Fail?*, UC Berkeley, NeurIPS 2025), grounded in
1,600+ execution traces, found multi-agent frameworks failing **41–87%** of the time and
mapped the breakdowns to specification, coordination, and verification gaps. Knowing *when
the second agent pays for itself* is now a load-bearing architectural skill.

## Key concepts / building blocks

**Single-agent loop.** One model, one context window, one continuous chain of reasoning.
All state is visible to all decisions. Easiest to reason about, prompt, evaluate, and
debug. The default. Augment it with [[context-engineering]] and tools long before
reaching for a second agent. The foundational unit is the **augmented LLM** — a model
wired to retrieval, tools, and memory:

![[2026-06-19-anthropic-building-effective-agents-01.png|The augmented LLM: a model with retrieval, tools, and memory]]
*Figure: The augmented LLM — the basic building block underneath every agentic system. Source [[2026-06-19-anthropic-building-effective-agents]].*

**Workflow patterns (deterministic orchestration)** — Anthropic's five composable
building blocks, in rough order of complexity:

- **Prompt chaining** — fixed sequence of steps, optionally with programmatic gates
  between them. Use when a task cleanly decomposes into known subtasks.
- **Routing** — classify the input, dispatch to a specialized handler. Separation of
  concerns without multiple cooperating agents.
- **Parallelization** — *sectioning* (independent subtasks run concurrently) or *voting*
  (same task run N times for consensus/coverage).
- **Orchestrator–workers** — a central LLM *dynamically* decomposes a task, delegates to
  worker calls, and synthesizes results. Unlike parallelization, subtasks are **not**
  pre-defined — the orchestrator decides them at runtime. This is the workhorse pattern
  for open-ended work (e.g. "how many files need changing" is unknown up front).
- **Evaluator–optimizer** — a generator produces, an evaluator critiques, loop until a
  bar is met. Powerful when you have *clear evaluation criteria* and iterative refinement
  measurably helps.

**Multi-agent topologies** (when you genuinely need multiple autonomous agents):

- **Orchestrator / lead-agent** — one agent owns the task and context, spawns isolated
  subagents, and integrates their summarized results. No peer-to-peer channel. This is
  the current consensus shape (see State of the art).
- **Planner–executor** — one agent plans, separate agents execute steps. Clean
  separation of "what" from "how"; the plan is an inspectable artifact.
- **Hierarchical** — orchestrators of orchestrators; a tree (Google ADK's native shape).
  Reserve for genuinely large task trees — every layer multiplies the failure surface.
- **Hand-off chains** — control passes between specialists (schema → API → test →
  review). The natural shape for pipeline-like work where each stage has a different
  skill profile and quality bar.

**Coordination primitives** — covered in depth in [[multi-agent-orchestration]] and
[[agent-to-agent-protocols]]:

- **Task decomposition & delegation boundaries** — where to cut the work, and how much
  autonomy each piece gets. Bad cuts create agents that constantly need information they
  don't have.
- **Shared state / memory / context passing** — the hard problem. Cognition's central
  warning: *agents that don't share full context, or whose actions rest on conflicting
  implicit decisions, produce fragile systems.* See [[agent-memory-architectures]].
- **Failure handling, retries, loop prevention** — turn/step caps, budgets, idempotency,
  and timeouts (see below).
- **Human checkpoints** — approval gates and the [[delegate-review-own]] discipline.

## Design decisions & trade-offs

**The first decision: do you need an agent at all?** Workflows give predictability and
low latency for well-understood tasks; agents give flexibility and model-driven decision
making for open-ended ones, at the cost of latency, cost, and compounding errors. Many
"agent" requirements are satisfied by a single well-instrumented LLM call or a fixed
chain.

**The second decision: single agent vs. multiple agents.** Reach for multi-agent only
when one or more genuinely holds:

| Favors **single agent** | Favors **multi-agent** |
|---|---|
| Tasks share heavily-overlapping context | Subtasks are cleanly separable with little shared context |
| Decisions are tightly coupled / sequential | Work is **embarrassingly parallel** (e.g. breadth-first search/research) |
| Debuggability & cost are paramount | Task value is high enough to absorb ~10–15× tokens |
| Latency-sensitive | Throughput from parallelism beats a single context window's limits |
| You can't cleanly define hand-off contracts | Specialists have sharply different tools/quality bars |

Anthropic's research system is the canonical *pro* case: research is parallelizable,
each subagent explores an independent thread with its own context window, and the
lead agent synthesizes — it beat single-agent Opus by **90.2%** on their internal
research eval. Cognition's *Devin* (coding) is the canonical *con* case in its 2025
form: coding decisions are deeply interdependent, so fragmenting context produced
conflicting work; their answer was single-threaded execution with a dedicated
context-compression model.

**Hand-off design** is the make-or-break of any multi-agent system. A hand-off must
carry *enough* context for the receiver to act without re-deriving decisions, but
*little enough* that you're not just paying to copy the whole window. The two failure
modes are symmetric: too little context → conflicting implicit decisions (Cognition's
warning); too much → you've reinvented the single-agent loop with extra latency. Make
hand-offs **explicit, typed artifacts** (a schema, a plan, a structured task spec) —
not free-text chat — so they're inspectable and testable. The OpenAI Agents SDK makes
the hand-off the core primitive precisely because it's where systems break.

**Delegation boundaries** mirror service boundaries: cut where coupling is lowest. An
agent that constantly needs information owned by a sibling is a boundary drawn in the
wrong place — collapse them, or restructure so the orchestrator brokers the dependency.

**Failure handling & runaway prevention** is non-negotiable for anything you own:

- **Turn / step caps** and **dynamic budgets** — hard ceilings on reasoning-action
  cycles so a confused agent can't burn the budget. Cap, then escalate to a human or
  fail safe.
- **Idempotency & retries** — design tool calls so a retry can't double-charge a card or
  double-send an email; retries are how you survive a non-deterministic substrate.
- **Loop detection** — detect repeated no-progress states (same action, same result) and
  break out.
- **Timeouts with safe defaults** — if a human approval or a sub-agent doesn't respond in
  the window, default to *reject / no-op*, never to "proceed."

**Human-in-the-loop & the "delegate, review, own" stance.** You remain
**accountable** for what the system does, regardless of how much it automates. Gate on
*irreversibility and blast radius*, not on whim: financial transactions, data deletion,
production changes, and outbound communications pass through an approval gate; read-only
or trivially-reversible actions run autonomously. Synchronous gates suit safety-critical
real-time actions; asynchronous (queue-based) gates scale review without blocking. The
regulatory backdrop makes this concrete — **EU AI Act Article 14** requires
demonstrable, *trained and provable* human oversight for high-risk systems, with an
August 2026 compliance milestone. See [[human-in-the-loop-design]] and
[[accountable-human-layer]].

## State of the art

**The multi-agent debate has converged.** The polarized 2025 exchange — Cognition's
*"Don't Build Multi-Agents"* vs. Anthropic's *"How we built our multi-agent research
system"* — looked like a contradiction but resolved into a shared pattern:
**an orchestrator that owns context and spawns *isolated* subagents, getting summaries
back, with no peer-to-peer chatter.** Cognition's March 2026 *"Manage Devins"* coordinator
adopts the same isolation argument it once used to caution against multi-agent designs.
The disagreement was never really single vs. multi — it was *shared mutable context
between peers* (fragile) vs. *isolated subagents under one orchestrator* (workable).

**Framework landscape:**

- **LangGraph** — the de-facto default for stateful, auditable production workflows.
  Explicit directed graph (nodes = agents/tools/checkpoints, edges = transitions),
  which maps cleanly onto regulated-environment needs: audit trails, checkpoints,
  rollback, and human-approval steps. Largest enterprise deployment footprint.
- **OpenAI Agents SDK** (the productionized successor to *Swarm*) — lightweight;
  the **hand-off** is the core abstraction. Lowest-friction for GPT-centric agents.
- **CrewAI** — role-based "crews"; fastest idea-to-prototype, though teams often outgrow
  its role-based orchestration for complex control flow.
- **Microsoft Agent Framework** — reached v1.0 GA in April 2026, absorbing **AutoGen**
  (now in maintenance) and Semantic Kernel into one supported line.
- **Google ADK** — hierarchical agent tree as the native topology; strong A2A integration.

**Interoperability is now table stakes.** [[agent-to-agent-protocols|A2A]] lets an ADK
agent discover and invoke a LangGraph or CrewAI agent via a standard task interface, and
[[model-context-protocol|MCP]] standardizes how any agent reaches tools and data.
Increasingly the job is wiring heterogeneous agents across frameworks, not
picking one framework — see [[agents-as-system-citizens]].

**Observability is the gating constraint on scale.** Non-deterministic, multi-step,
multi-agent execution is undebuggable without tracing every decision, tool call, and
hand-off. [[ai-agent-observability]] has moved from nice-to-have to a precondition for
running these systems in production.

## Pitfalls & anti-patterns

- **Multi-agent theater.** Splitting into agents because it mirrors an org chart or looks
  impressive, not because the work is separable. Cost and fragility without benefit.
- **Building an agent where a workflow would do.** Paying agentic latency, cost, and
  non-determinism for a task with a known, fixed control flow.
- **Peer-to-peer context sharing.** Multiple agents mutating/reading shared context with
  conflicting implicit assumptions — Cognition's documented failure mode. Prefer one
  orchestrator owning context.
- **Free-text hand-offs.** Passing unstructured chat between agents instead of typed
  artifacts; impossible to validate, easy to silently corrupt.
- **No turn cap / no budget.** A confused agent loops until it exhausts the token budget.
  Always cap, then escalate or fail safe.
- **Non-idempotent tool calls under retry.** Retrying a non-idempotent action
  double-charges, double-sends, double-deploys.
- **Gates that fail open.** An approval timeout that defaults to "proceed" instead of
  "reject" turns a safety control into a rubber stamp.
- **Over-decomposition.** So many tiny agents that coordination overhead dwarfs the work
  — the distributed-monolith anti-pattern, reborn in agents.
- **Ignoring the bill.** Treating a 15× token multiplier as free because the demo worked
  on one query.

## See also

- [[agentic-harness]]
- [[multi-agent-orchestration]]
- [[agent-to-agent-protocols]]
- [[human-in-the-loop-design]]
- [[agents-as-system-citizens]]
- [[model-context-protocol]]
- [[retrieval-augmented-generation]]
- [[context-engineering]]
- [[ai-agent-observability]]
- [[delegate-review-own]]

## Sources

- [Anthropic — Building Effective Agents](https://www.anthropic.com/research/building-effective-agents) (workflow vs. agent distinction; the five composable patterns; "simplest solution" principle) — captured with diagrams at [[2026-06-19-anthropic-building-effective-agents]]
- [Anthropic — How we built our multi-agent research system](https://www.anthropic.com/engineering/built-multi-agent-research-system) (orchestrator + isolated subagents; ~15× tokens; +90.2% research eval)
- [Cognition — Don't Build Multi-Agents](https://cognition.ai/blog/dont-build-multi-agents) (context-sharing fragility; single-threaded execution; context compression)
- [LangChain — How and when to build multi-agent systems](https://blog.langchain.com/how-and-when-to-build-multi-agent-systems/) (when multi-agent helps vs. hurts; convergence on isolated subagents)
- [LangChain — The best AI agent frameworks in 2026](https://www.langchain.com/resources/ai-agent-frameworks) (framework landscape and positioning)
- [Tran & Kiela (Stanford, 2026) — Single-Agent LLMs Outperform Multi-Agent Systems on Multi-Hop Reasoning Under Equal Thinking Token Budgets](https://arxiv.org/abs/2604.02460) (single-agent parity/superiority under fixed compute budgets)
- [Why Do Multi-Agent LLM Systems Fail? (MAST, UC Berkeley, NeurIPS 2025)](https://openreview.net/forum?id=fAjbYBmonr) (1,600+ traces; 41–87% failure; specification/coordination/verification taxonomy)
- [Strata — Human-in-the-Loop: A 2026 Guide to AI Oversight](https://www.strata.io/blog/agentic-identity/practicing-the-human-in-the-loop/) (approval gates, turn limits, timeouts, EU AI Act Article 14)
