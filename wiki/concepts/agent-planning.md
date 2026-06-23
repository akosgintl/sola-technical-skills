---
title: Agent Planning
aliases: [ReAct, plan-and-execute, agent reasoning, agentic planning, ReAct pattern, ReAct agent]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, planning, react, plan-and-execute, langgraph, reasoning, agents]
updated: 2026-06-23
sources:
  - raw/2026-06-23-decodingai-06-agent-planning.md
  - raw/2026-06-23-decodingai-07-react-agents.md
  - "https://www.decodingai.com/p/ai-agents-planning"
  - "https://www.decodingai.com/p/building-production-react-agents"
  - "https://arxiv.org/abs/2210.03629"
  - "https://langchain-ai.github.io/langgraph/"
---

# Agent Planning

> [!summary]
> Agent planning is the discipline of having an LLM reason about what to do before doing it — separating the "what next?" decision from the tool execution step. Without an explicit planning phase, agents degrade into reactive tool loops: each observation triggers the next action without a coherent strategy, producing meandering paths and compounding errors. The two canonical planning patterns are **ReAct** (interleaved reasoning and action) and **Plan-and-Execute** (upfront decomposition then execution); modern reasoning LLMs internalize both into their inference process.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

A naive agent implementation is a tool-calling loop: the model receives a task, calls a tool, receives the result, calls another tool. This works for simple sequential tasks but fails for complex ones because each action is local — the model optimizes the next step without a view of the overall trajectory. The agent reacts to observations rather than pursuing a strategy.

Agent planning decouples the deciding from the doing:

> "Ask the model to first plan or reason, and then, as a distinct step, produce a final answer or take an action in the form of tools."

This separation enables iterative planning: observations from actions feed back into subsequent planning decisions, adjusting strategy rather than just choosing the next local action.

All production agent planning patterns are variants of two foundations: **ReAct** and **Plan-and-Execute**.

## Why it matters

**Planning is the difference between tool loops and agents.** A tool loop discovers the solution accidentally; an agent with planning decomposes the problem, tracks progress, and adapts strategy when observations don't match expectations. Planning is what makes an agent coherent across multi-step tasks.

**Error recovery requires planning.** When a tool fails, a reactive loop either ignores the failure or retries blindly. A planning agent observes the failure, reasons about what it implies for the goal, and decides whether to retry, take a different path, or escalate. Planning is what makes failure handling intelligent.

**Efficiency through decomposition.** Plan-and-Execute patterns can identify which subtasks are independent and execute them in parallel — a capability that reactive loops cannot access because each step is decided only after the previous one completes.

## Key concepts / building blocks

### ReAct: Reason + Act

ReAct (Yao et al., arXiv:2210.03629) creates an interleaved Thought–Action–Observation cycle:

1. **Thought** — the model reasons about what to do next given current state
2. **Action** — the model selects and executes a tool
3. **Observation** — the tool output is returned and added to context
4. (Repeat until done)

Every cycle updates the model's understanding before selecting the next action. The model is always planning from observed state, not from a static assumption.

**LangGraph implementation:** Two nodes and conditional edges form the loop:

- **Model node** — receives the full message history (including past tool outputs as `ToolMessage` objects), generates a `Thought` and optionally one or more `tool_calls` in the `AIMessage`.
- **Tools node** — `ToolNode` executes all pending `tool_calls` in parallel (via `Send` objects), returns `ToolMessage` results, appends to state.
- **Conditional edge** — routes back to the model node if more tool calls are needed; routes to END when the model generates `structured_response` with no pending tool calls.

State management: `AgentState` maintains `messages: Sequence[BaseMessage]` — the full Thought-Action-Observation history — plus `structured_response` for the terminal typed output. An `add_messages` reducer appends each new message without overwriting history, giving the model complete visibility into all past reasoning and tool outcomes.

**Exit conditions:**
1. Model generates no `tool_calls` and `structured_response` is populated
2. Maximum iteration limit reached (mandatory safety rail — see [[agentic-loop]])

**ReAct characteristics:**

| Attribute | Characteristic |
|---|---|
| Planning granularity | Per-step; adapts after each observation |
| Parallelism | None within a reasoning cycle; sequential by design |
| Interpretability | High — full Thought trail is auditable |
| Error recovery | Natural — failures appear as observations; model can revise strategy |
| Failure mode | Infinite loops if stopping condition is unclear |
| Best fit | Exploratory tasks with uncertain paths; tasks requiring dynamic adaptation |

### Plan-and-Execute

Plan-and-Execute separates planning from execution into two explicit phases:

1. **Planner** — decomposes the goal into a detailed multi-step plan upfront. The plan is an inspectable artifact: a structured sequence of subtasks with dependencies noted.
2. **Evaluator** — validates the plan for feasibility and logical consistency before execution begins.
3. **Executor** — runs the plan steps, either sequentially or in parallel where dependencies allow.
4. **Replan** — if execution results reveal that the plan was wrong or incomplete, the planner is re-invoked to adjust.

For the same research task a ReAct agent would address step-by-step, a Plan-and-Execute agent would: generate a complete plan upfront (3 broad queries, then parallel searches, then scraping and summarization), validate the plan, execute all independent steps in parallel batches, then replan if gaps appear.

**Plan-and-Execute characteristics:**

| Attribute | Characteristic |
|---|---|
| Planning granularity | Upfront; whole trajectory before execution |
| Parallelism | High — independent subtasks run concurrently |
| Interpretability | High — the plan is a named artifact; reviewable before execution |
| Error recovery | Replanning required; rigid adherence to bad plans is the failure mode |
| Failure mode | Over-commitment to flawed initial plans |
| Best fit | Well-defined, predictable tasks where parallelism matters |

### Trade-off: ReAct vs. Plan-and-Execute

| Criterion | ReAct | Plan-and-Execute |
|---|---|---|
| Task predictability | Unknown upfront | Predictable structure |
| Latency | Higher (sequential cycles) | Lower (parallel execution) |
| Adaptability | High (revises each step) | Lower (commits to plan) |
| Cost | Higher (more model calls per decision) | Lower (batch execution) |
| Debugging | Full trace of every decision | Plan is a clean inspection point |

Hybrid approaches combine both: a planner generates a high-level structure; a ReAct loop executes each subtask adaptively. This is the pattern used by multi-agent research systems where the orchestrator plans and specialized subagents execute reactively.

### Modern reasoning LLMs: planning internalized

Contemporary models (Gemini 2.5 with `thinking_budget`, Claude with extended thinking, OpenAI o3) perform the planning phase as internal reasoning steps — "thinking tokens" not shown in the output but influencing the generation. The practical effect:

- Planning and action selection happen within a single API call
- No separate "planning node" is needed in the agent graph
- The single model node generates both the plan and the first action
- Latency is lower than two-call ReAct; cost depends on thinking budget

For most new production agents using reasoning-capable models, a single-node graph is sufficient: the model internally plans, selects tools, observes, and re-plans — the developer's job is to define tools, state, and exit conditions, not to implement the planning loop.

## Design decisions & trade-offs

**When to use ReAct vs. Plan-and-Execute:**
- Use ReAct for exploratory, open-ended tasks (research, debugging, code review) where the optimal path is unknown upfront.
- Use Plan-and-Execute for structured tasks where the subtasks are predictable and independent execution parallelism matters (data processing pipelines, batch content generation).
- Use a reasoning LLM with built-in thinking for either pattern when the model supports it — it combines the benefits of both at lower operational complexity.

**Separation of writer and judge:**
The subagent that produces a plan should not be the same instance that approves it. A separate evaluator with independent context catches feasibility failures and logical contradictions that the planner rationalizes away. This mirrors the [[delegate-review-own|delegate-review-own]] principle at the planning phase.

**Exit condition design:**
The most common production failure in planning loops is an agent that cannot determine it is done. Define verifiable exit conditions (see [[agentic-loop]]): a concrete stopping signal (all tests pass, all sources retrieved, final answer generated) rather than a fuzzy one ("done enough"). Enforce a maximum iteration ceiling regardless — no planning pattern guarantees convergence without it.

**Human checkpoints at plan boundaries:**
For high-stakes tasks, inserting a [[human-in-the-loop-design|human review checkpoint]] after the plan is generated (before execution begins) is the highest-leverage oversight point. A flawed plan produces flawed execution; catching it early avoids executing wrong work.

## State of the art

LangGraph (LangChain, 2024–2026) is the dominant production implementation framework for both patterns. Its stateful graph model maps directly to the ReAct cycle (model node + tools node + conditional edges) and to Plan-and-Execute (planner node + evaluator node + parallel executor nodes). LangGraph GA v1.0.10 ships built-in `ToolNode`, `create_react_agent`, and `interrupt()`-based HITL support.

As of mid-2026, Gemini 2.5 Flash/Pro, Claude 3.5+, and OpenAI o3 all support native extended thinking. For most use cases, the recommendation has shifted from implementing explicit planning loops to selecting a reasoning model and configuring its thinking budget — the implementation complexity drops substantially.

Opik, LangSmith, and Weights & Biases Weave provide agent-level observability for both patterns — tracing the full Thought-Action-Observation sequence across potentially hundreds of steps, which is the primary debugging surface for planning failures.

## Pitfalls & anti-patterns

**Running tools in a loop without planning.** Reactive tool loops are not agents — they are expensive search procedures that accumulate cost without strategy. Each step optimizes locally; the global trajectory degrades into a random walk toward the first locally plausible answer.

**Infinite loops from underspecified stopping conditions.** A planning loop that can't recognize completion runs until it hits a token budget or times out. Every planning loop must have a deterministic exit path.

**Rigid Plan-and-Execute without replanning.** Committing fully to an initial plan and executing it without observation feedback produces wrong answers confidently. Build in a replan step triggered when execution results deviate materially from plan assumptions.

**Planning node as a separate LLM call when not needed.** Adding explicit planning nodes for models with built-in reasoning capability adds latency and cost without benefit. Use the model's native planning; reserve explicit planning nodes for models that lack extended thinking.

**No max iteration limit.** Both ReAct and Plan-and-Execute can loop indefinitely given ambiguous stopping conditions. Always enforce a hard ceiling on iterations — treat it as a non-negotiable safety rail, not an optimization.

## See also

- [[agentic-loop]]
- [[agentic-system-design]]
- [[llm-tool-use]]
- [[llm-structured-outputs]]
- [[multi-agent-orchestration]]
- [[human-in-the-loop-design]]
- [[ai-agent-observability]]

## Sources

- Iusztin, P. (Decoding AI). Writing AI Agents From Scratch: Planning Is The Key. https://www.decodingai.com/p/ai-agents-planning
- Iusztin, P. (Decoding AI). Building Production ReAct Agents From Scratch. https://www.decodingai.com/p/building-production-react-agents
- Yao, S., et al. (2022). ReAct: Synergizing Reasoning and Acting in Language Models. arXiv:2210.03629. https://arxiv.org/abs/2210.03629
- LangChain AI. (2026). LangGraph Documentation. https://langchain-ai.github.io/langgraph/
- raw/2026-06-23-decodingai-06-agent-planning.md
- raw/2026-06-23-decodingai-07-react-agents.md
