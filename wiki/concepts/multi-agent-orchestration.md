---
title: Multi-Agent Orchestration
aliases: [multi-agent systems, agent orchestration]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, agents, orchestration, workflows, langgraph, crewai, sdk]
updated: 2026-06-27
sources:
  - "https://www.anthropic.com/engineering/building-effective-agents"
  - "https://openreview.net/forum?id=fAjbYBmonr"
  - "https://letsdatascience.com/blog/ai-agent-frameworks-compared"
  - "https://presenc.ai/research/multi-agent-orchestration-frameworks-2026"
  - "https://alicelabs.ai/en/insights/best-ai-agent-frameworks-2026"
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

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Multi-agent orchestration is the design discipline of arranging several LLM calls — each with
its own role, tools, and context — so they collaborate reliably on tasks too large or too
varied for one call. The orchestrator chooses an execution topology and manages how outputs
flow between participants. The goal is to gain specialization and parallelism *without* losing
coherence or control. Per Anthropic's [[agentic-system-design|"Building Effective Agents"]]
guidance, the foundational unit underneath all of this is the **augmented LLM** (a model with
retrieval, tools, and memory), and the right default is the *simplest* composition that works.

## Why it matters

Orchestration is where cost, latency, and reliability are won or lost. A predefined **workflow**
gives you predictability, easy evaluation, and a debuggable code path; a dynamic **agent** buys
flexibility at the price of non-determinism, token blow-up, and compounding errors. The key
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

### The five patterns, visualized

![[2026-06-19-anthropic-building-effective-agents-02.png|Prompt chaining: LLM calls in sequence with gates between steps]]
*Figure: Prompt chaining — sequential calls with programmatic gates. Source [[2026-06-19-anthropic-building-effective-agents]].*

![[2026-06-19-anthropic-building-effective-agents-03.png|Routing: a classifier dispatches the input to a specialized follow-up]]
*Figure: Routing — classify, then dispatch to a specialized handler. Source [[2026-06-19-anthropic-building-effective-agents]].*

![[2026-06-19-anthropic-building-effective-agents-04.png|Parallelization: fan the task out to parallel calls and aggregate]]
*Figure: Parallelization — sectioning/voting across parallel calls, then aggregate. Source [[2026-06-19-anthropic-building-effective-agents]].*

![[2026-06-19-anthropic-building-effective-agents-05.png|Orchestrator-workers: an orchestrator decomposes at runtime and a synthesizer recombines]]
*Figure: Orchestrator-workers — runtime decomposition by the orchestrator, recombined by a synthesizer. Source [[2026-06-19-anthropic-building-effective-agents]].*

![[2026-06-19-anthropic-building-effective-agents-06.png|Evaluator-optimizer: a generator and a critic LLM in a refinement loop]]
*Figure: Evaluator-optimizer — generator + critic in a refinement loop. Source [[2026-06-19-anthropic-building-effective-agents]].*

### Context flow and result synthesis

Each topology implies a different way state moves between participants — an orchestration concern
distinct from the wire-level [[agent-to-agent-protocols|state-passing protocol]]:

- **Prompt chaining** passes each step's full output forward; the risk is *context accretion* — the
  chain accumulates tokens at every hop. Trim each hand-off to what the next step actually needs
  (see [[context-engineering]]).
- **Routing** passes the input plus a classification label; state stays small.
- **Parallelization** fans the same (or partitioned) context out to N workers and must **aggregate**
  their results — by concatenation, voting/quorum, or a reducer LLM.
- **Orchestrator-workers** is the hardest: the orchestrator builds a **scoped context bundle** per
  worker (goal + just-enough background), then **synthesizes** heterogeneous worker outputs into a
  coherent whole. The synthesis step is where most quality is won or lost.

The default is **scoped context per participant**, not a shared blackboard — it bounds cost and the
blast radius of a bad or compromised participant (the scoped-vs-shared state trade-off is detailed
in [[agent-to-agent-protocols]]).

## Hand-off design: specialist chains

A common production topology is a **chain of specialists**, each owning one stage and handing a
typed artifact to the next — for example a **schema → API → test → review** pipeline for a code
change:

1. **Schema agent** produces the data/contract definition.
2. **API agent** consumes the schema and implements endpoints against it.
3. **Test agent** consumes the API contract and writes tests.
4. **Review agent** checks the whole against the original spec and either approves or returns it.

Two rules make these chains reliable:

- **Make the hand-off a typed contract, not prose.** Each stage should emit a structured artifact
  ([[llm-structured-outputs|structured output]]) the next stage consumes deterministically — the
  orchestration-level analogue of the wire contract in [[agent-to-agent-protocols]]. Loose prose
  hand-offs are exactly the *coordination gap* the MAST study found behind a large share of
  multi-agent failures.
- **Put a verifier at the end (and optionally between stages).** A review/evaluator stage closes the
  MAST *verification gap* — a chain with no agent checking the result against the spec ships
  plausible-but-wrong output. This is the [[human-in-the-loop-design|review gate]] /
  [[delegate-review-own|delegate-review-own]] pattern expressed inside the orchestration.

## Runaway and loop prevention

Autonomous and dynamically-orchestrated agents fail *expensively* — spinning in a loop, retrying a
failing action, or fanning out without bound. Because the failure mode is cost and time, not just a
wrong answer, orchestration needs explicit brakes:

- **Hard stopping conditions.** Every agentic loop needs a termination guarantee beyond "the model
  decides it's done": a **max-iteration cap**, a **wall-clock timeout**, and a **token/cost budget**
  that aborts the run. Anthropic's guidance is explicit that autonomous agents require clear stopping
  conditions.
- **No-progress / loop detection.** Detect repetition — identical or cyclic tool calls, unchanging
  state, oscillation between two actions — and break out rather than burn budget (see the
  runaway-prevention discussion in [[agentic-loop]]).
- **Cost circuit breaker.** Track spend per run and trip at a threshold — the same
  [[distributed-systems-reliability|circuit-breaker]] logic applied to token economics, so one
  runaway agent can't spend unbounded money.
- **Bounded delegation and fan-out.** Cap delegation depth (two levels is the practical maximum —
  see [[agent-to-agent-protocols]]) and the number of parallel workers, so dynamic decomposition
  can't explode combinatorially.
- **Sandbox the blast radius.** Confine autonomous loops to scoped credentials and reversible
  actions, with a [[human-in-the-loop-design|human gate]] on anything irreversible — autonomy raises
  compounding-error risk, so contain what a runaway can touch.

## Design decisions & trade-offs

| Decision | The real trade-off |
|---|---|
| **Workflow vs. agent** | Predictability/debuggability vs. flexibility. Use a workflow whenever the control flow is knowable; reserve agents for unpredictable step counts. |
| **Predefined vs. dynamic decomposition** | Parallelization (fixed subtasks) is cheaper and more testable than orchestrator-workers (runtime subtasks). Only pay for dynamism when you can't enumerate the subtasks. |
| **Sequential vs. parallel** | Latency vs. token cost and coordination overhead. Parallel fan-out cuts wall-clock but multiplies tokens and needs result aggregation. |
| **One model vs. tiered** | Routing easy work to cheaper models saves cost but adds a classification failure surface. |
| **How much autonomy** | Autonomy scales to open-ended tasks but raises cost and compounding-error risk — confine to trusted/sandboxed environments with guardrails. |

## State of the art

The field has converged on Anthropic's framing: **start simple, add agents last.** Independent
results reinforce restraint — under a fixed compute budget single agents often match multi-agent
systems, and the MAST study (Qiu et al., 2024; OpenReview:fAjbYBmonr) found multi-agent
LLM systems failing 41–87% of the time, with failures clustering in three categories:
specification gaps (ambiguous task decomposition), coordination gaps (hand-off breakdowns),
and verification gaps (no agent checking whether the result is correct). See [[agentic-system-design]]
for the full failure-mode taxonomy.

**Framework landscape (mid-2026):**

| Framework | Position | Production status |
|---|---|---|
| **LangGraph** | Complex, stateful orchestration; strongest persistence + checkpointing | GA v1.0.10 (Oct 2025 GA); dominant enterprise footprint |
| **CrewAI** | Rapid multi-agent prototyping; broadest protocol support (MCP + A2A) | v1.10.1; 44,600+ GitHub stars; strongest demo-to-prototype ergonomics |
| **Claude Agent SDK** | MCP-native development; in-process server model with lifecycle hooks | v0.1.48; best fit for Anthropic-native agentic stacks |
| **OpenAI Agents SDK** | Simplicity-first; fastest path from zero to working agent | Stable; best for teams unfamiliar with orchestration |
| **Strands (AWS)** | AWS-integrated serverless orchestration | Early GA; favored for Lambda-based agentic workflows |
| **AutoGen** | Research-oriented; flexible role assignment | v0.4+; popular in academic and experimental contexts |

Framework selection guidance: choose LangGraph when workflow complexity is the primary challenge;
CrewAI when multi-agent collaboration is central; Claude Agent SDK when MCP integration and
lifecycle management matter. All frameworks add abstraction that can obscure the underlying
prompts — understand the code beneath them. Hand-offs and contracts between agents are covered
in [[agent-to-agent-protocols]].

## Pitfalls & anti-patterns

- **Reaching for orchestrator-workers** when fixed parallelization (or a single call) would do.
- **Over-decomposition** — so many tiny agents that coordination overhead dwarfs the work.
- **Ignoring the bill** — treating an N× token multiplier as free because the demo worked once.
- **No gates** between chained steps, so an early error propagates silently.
- **No termination guarantee** — an autonomous loop with no max-iteration cap, timeout, or cost
  budget can run away on spend.
- **No final verifier** — a specialist chain that never checks its output against the spec (the MAST
  verification gap), shipping confident-but-wrong results.
- **Framework lock-in without understanding** the prompts/loops underneath.

## See also

- [[agentic-system-design]]
- [[agent-to-agent-protocols]]
- [[agentic-loop]]
- [[human-in-the-loop-design]]
- [[delegate-review-own]]
- [[agents-as-system-citizens]]
- [[model-selection-and-routing]]
- [[llm-structured-outputs]]
- [[ai-agent-observability]]
- [[context-engineering]]

## Sources

- [Anthropic — Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents) (workflows vs. agents; the five composable patterns; orchestrator-workers; ACI principles) — captured at [[2026-06-19-anthropic-building-effective-agents]]
- Qiu, Y., et al. (2024). Why Do Multi-Agent LLM Systems Fail? MAST taxonomy (specification / coordination / verification gaps; 41–87% failure rates). OpenReview: https://openreview.net/forum?id=fAjbYBmonr
- Let's Data Science. (2026). AI Agent Frameworks 2026: LangGraph vs CrewAI & More. https://letsdatascience.com/blog/ai-agent-frameworks-compared
- Presenc AI. (2026). Multi-Agent Orchestration Frameworks 2026. https://presenc.ai/research/multi-agent-orchestration-frameworks-2026
- Alice Labs. (2026). Best AI Agent Frameworks 2026: 7 Production-Tested Rankings. https://alicelabs.ai/en/insights/best-ai-agent-frameworks-2026
