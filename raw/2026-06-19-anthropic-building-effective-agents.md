---
title: Building Effective Agents (Anthropic)
aliases: [building effective agents]
type: source
domain: ai-agentic
status: seed
tags: [source, agents, orchestration, workflows]
updated: 2026-06-19
source_url: https://www.anthropic.com/engineering/building-effective-agents
source_type: article
ingested: 2026-06-19
feeds: ["multi-agent-orchestration", "agentic-system-design", "agent-to-agent-protocols"]
---

# Building Effective Agents (Anthropic)

> [!info] Source metadata
> **Authors:** Erik Schluntz & Barry Zhang (Anthropic) · **Published:** 2024-12-19 ·
> **URL:** https://www.anthropic.com/engineering/building-effective-agents ·
> **Captured:** 2026-06-19 via firecrawl (`--only-main-content`).

## Key takeaways

- **Workflows vs. agents** is the load-bearing distinction. *Workflows* orchestrate LLMs +
  tools through **predefined code paths**; *agents* let the LLM **dynamically direct** its own
  process and tool use. Both are "agentic systems."
- **Start simple.** Find the simplest solution; add complexity only when it demonstrably
  improves outcomes. Often a single optimized LLM call + retrieval + examples is enough.
- **Five composable workflow patterns**, in increasing complexity: prompt chaining, routing,
  parallelization (sectioning + voting), orchestrator-workers, evaluator-optimizer.
- **Orchestrator-workers** ≈ parallelization topologically, but the subtasks are **not
  pre-defined** — the orchestrator determines them from the input. This is the canonical
  *dynamic* multi-agent pattern (e.g. coding across an unknown set of files).
- **Autonomous agents** = LLMs using tools in a loop on environmental feedback; use for
  open-ended problems with no predictable step count, in trusted/sandboxed environments,
  accepting higher cost and compounding-error risk.
- **Three principles** for agents: simplicity, transparency (show planning steps), and a
  carefully crafted **agent-computer interface (ACI)** — invest in tool docs/testing as much
  as in prompts.
- Frameworks (Claude Agent SDK, Strands, Rivet, Vellum) speed the start but add abstraction
  that obscures prompts/responses; understand the underlying code.

## Feeds these wiki pages

- [[multi-agent-orchestration]] — the five workflow patterns + orchestrator-workers (primary)
- [[agentic-system-design]] — workflows-vs-agents, "start simple", simplicity/transparency/ACI
- [[agent-to-agent-protocols]] — hand-off and decomposition boundaries

---
*Raw source — captured verbatim below; do not edit. Analysis lives above this line.
Full scrape cached at `.firecrawl/anthropic-building-effective-agents.md`.*

## Building blocks, workflows, and agents (verbatim excerpts)

**Augmented LLM** — the basic building block: an LLM enhanced with retrieval, tools, and
memory; the model generates its own queries, selects tools, decides what to retain. One way
to implement the augmentations is the Model Context Protocol.

**Workflow: Prompt chaining** — decomposes a task into a sequence of steps, each LLM call
processing the previous output; add programmatic "gates" on intermediate steps. Use when a
task cleanly decomposes into fixed subtasks; trades latency for accuracy.

**Workflow: Routing** — classifies an input and directs it to a specialized follow-up;
allows separation of concerns and specialized prompts. Use for distinct categories better
handled separately when classification is accurate (e.g. route easy queries to Haiku, hard
ones to Sonnet).

**Workflow: Parallelization** — two variants: *Sectioning* (independent subtasks run in
parallel) and *Voting* (same task run multiple times for diverse outputs). Use for speed or
when multiple perspectives raise confidence (e.g. one model answers while another screens
for inappropriate content; multiple prompts vote on a vulnerability review).

**Workflow: Orchestrator-workers** — a central LLM dynamically breaks down tasks, delegates
to worker LLMs, and synthesizes their results. Use for complex tasks where you can't predict
the subtasks (e.g. coding changes across an unknown number of files). Key difference from
parallelization: subtasks are determined by the orchestrator, not pre-defined.

**Workflow: Evaluator-optimizer** — one LLM generates a response while another evaluates and
gives feedback in a loop. Use when there are clear evaluation criteria and iterative
refinement adds measurable value (e.g. literary translation; multi-round search).

**Agents** — LLMs using tools based on environmental feedback in a loop; begin from a command
or discussion, then plan and operate independently, gaining "ground truth" from the
environment each step, pausing at checkpoints/blockers, with stopping conditions (e.g. max
iterations) for control. Higher cost and compounding-error potential; test in sandboxes with
guardrails.

**Summary principles** — build the *right* system, not the most sophisticated. Maintain
simplicity; prioritize transparency (show planning steps); craft the agent-computer
interface (ACI) via thorough tool documentation and testing.
