---
title: Agentic Loop
aliases: [loop engineering, agent loop, agentic loop, loop-based development, loop-engineering]
type: concept
domain: ai-agentic
status: mature
tags: [agent-loops, agentic, loop-engineering, sub-agents, skills, automation]
updated: 2026-06-26
sources:
  - raw/2026-06-21-loop-engineering.md
  - raw/2026-06-26-loop-engineering-osmani-anatomy.md
  - raw/2026-06-26-loop-engineering-langchain-stack.md
  - "https://addyosmani.com/blog/loop-engineering/"
  - "https://www.langchain.com/blog/the-art-of-loop-engineering"
  - "https://www.anthropic.com/engineering/building-effective-agents"
  - raw/2026-06-23-decodingai-01-ai-workflows-vs-agents.md
  - raw/2026-06-23-decodingai-06-agent-planning.md
  - raw/2026-06-23-decodingai-07-react-agents.md
---

# Agentic Loop

> [!summary]
> An agentic loop is a self-contained execution unit in which an AI agent observes state, decides the next action, executes it, verifies the result, and iterates — all without per-step human prompting. The paradigm, called **loop engineering**, shifts the developer's role from prompting agents to designing the trigger, verifiable goal, and context infrastructure (skills, memory, sub-agents) the loop uses autonomously. It is the natural evolution beyond [[context-engineering]]: instead of curating context for one interaction, the engineer designs a repeatable system across many interactions.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

An agentic loop is an autonomous execution unit that contrasts with two older patterns:

- **Prompt engineering**: one human prompt → one agent response → human reviews and re-prompts.
- **Cron job / fixed automation**: a predetermined sequence of steps runs on a schedule, with no decision-making inside the loop.

A loop is different because the **decision-maker is inside the loop**. The agent observes the current state, selects its next action, executes it, checks the outcome, and decides whether to continue, retry, roll back, or stop — without a human intervening between steps.

The term **loop engineering** (popularized mid-2026 by Peter Steinberger, creator of OpenClaw, and independently confirmed by Boris Cherny, who leads Claude Code at Anthropic) describes the practice of designing these loops rather than prompting agents directly. The practitioner's job shifts from "write the best prompt" to "design the trigger, define the verifiable goal, and build the skills and tools the loop will use."

**The autonomy slider.** A useful framing: loops and workflows are not binary categories but points on a spectrum from fully controlled (all steps predefined, high predictability) to fully autonomous (model decides every step, high adaptability). Most production systems sit in the middle as deliberate hybrids — a deterministic workflow handles known request types; an agentic loop handles open-ended ones. The design decision is: how much autonomy does this specific task actually require? (See [[agentic-system-design]] for the workflow-vs-agent decision framework.)

Every working agentic loop has two hard prerequisites:

1. **Trigger** — what starts the loop: a pull-request opening, a failing CI run, a schedule, a Slack message, or a manual first prompt.
2. **Verifiable goal** — what tells the agent it can stop. This may be deterministic (all tests pass, CI is green), soft (a reviewer sub-agent checks whether the UI matches the spec), or a list of predefined criteria. Without a verifiable goal, the loop has no exit condition and devolves into a "very confident token furnace."

## Why it matters

**The babysitting problem is solved by design.** The traditional human-in-the-loop coding workflow — prompt, accept edits, run tests, paste error, re-prompt — places the human in the feedback loop for every iteration. Agentic loops extract the human from that loop: the agent runs the feedback cycle internally, and the human reviews outcomes rather than driving steps.

**Compound value with skills.** A loop without reusable skills rediscovers project conventions from scratch on every run, burning tokens re-learning what is already known. A loop backed by well-maintained skills starts each run with full context and compounds: every new skill added is a permanent acceleration.

**Persistence and autonomy.** Unlike a single agent session, a well-built loop can survive a laptop closing, run on a schedule, spawn sub-agents, write intermediate state to files or project boards, and produce artifacts (PRs, tickets, summaries) without human presence.

**The leverage point has shifted.** The practitioner's skill differential is no longer in writing clever prompts — models handle that reliably. The differential is in designing robust loops: clear goals, appropriate safety rails, quality skills, and measurable exit conditions.

## Key concepts / building blocks

### Loop anatomy (Addy Osmani's 5+1 framework)

| Component | Role in the loop |
|---|---|
| **Automations** | The loop starts itself (schedule, event trigger) — no human needs to initiate each run |
| **Work trees** | Parallel isolated agents that do not overwrite each other's output; allows divergent exploration |
| **Skills** | Reusable markdown blocks encoding conventions, commands, test patterns — the compounding layer |
| **Plugins / connectors** | Tools the agent can invoke (GitHub, Linear, Slack, databases) to create real-world effects |
| **Sub-agents** | Separation of concerns: the writing agent ≠ the reviewing agent |
| **Memory** | Persistence across runs; the loop remembers what the model has forgotten |

Osmani frames the same five primitives as **product features rather than bespoke scripts**: a year ago a loop meant a pile of hand-maintained bash; now the primitives ship inside the coding agents themselves, and the capability map is near-identical across OpenAI Codex and Claude Code (automations ↔ scheduled tasks/`/loop`/`/goal`; worktrees ↔ `git worktree`/`isolation: worktree`; skills ↔ `SKILL.md`; connectors ↔ MCP; sub-agents ↔ `.codex/agents/` or `.claude/agents/`). The design discipline is therefore tool-agnostic: design a loop whose shape survives whichever agent you happen to be sitting in. Loop engineering "sits one floor above the [[agentic-harness|harness]]" — the harness is the environment a single agent runs inside; the loop is that harness made to run on a timer, spawn helpers, and feed itself.

### Stacking loops: the four-loop view

The 5+1 anatomy lists the *parts*; the **stacked-loops** view (Swyx's "loopcraft," instrumented by LangChain) describes how loops *nest*, each outer loop wrapping the one below. This reframes "loop engineering" as choosing how many layers a task justifies:

| Level | Loop | What it adds | Impact |
|---|---|---|---|
| 1 | **Agent loop** | A model calls [[llm-tool-use|tools]] until the task is complete | Automate work |
| 2 | **Verification loop** | A grader (deterministic or [[ai-evaluation-and-quality\|LLM-as-judge]]) scores output against a rubric and retries with feedback on failure | Ensure quality/correctness |
| 3 | **Event-driven loop** | An event (webhook, schedule, new document, message) fires the agent so it runs continuously in the background | Automated work at scale |
| 4 | **Hill-climbing loop** | An analysis agent reads production [[ai-agent-observability\|traces]] and rewrites the harness config (prompts, tools, graders) | Improvement, not just work |

The decisive property of loop 4 is that **its feedback arrow reaches *inside* and updates the inner loops directly** — each outer cycle makes the agent loop more effective, rather than merely re-running it. The same trace signal can feed prompt/tool tweaks, RL fine-tuning for open-weight models, or improved memory and retrieved skills. Loops 1–2 are well understood; the compounding value is now in loops 3–4, where agents are embedded in an ecosystem and improve against your own criteria over time. This is the mechanism behind the strategic claim that organizations building learning loops early — "where human judgment and token capital compound together" (Nadella) — gain an advantage that is hard to replicate.

Human oversight has a natural insertion point at *each* level: require approval before sensitive tool calls (loop 1), act as the grader for sensitive workflows (loop 2), approve outputs before release (loop 3), and review harness changes before they deploy (loop 4). See [[human-in-the-loop-design]].

### Internal planning: how the loop decides

The decision-making inside a loop is governed by a [[agent-planning|planning pattern]]. Bare loops (observe → act without reasoning) fail at complex tasks because each action is locally chosen without a strategy. Two canonical planning patterns structure loop decisions:

- **ReAct** (Reason + Act) — the loop interleaves explicit reasoning with action selection. The model generates a Thought, selects a [[llm-tool-use|tool]], observes the result, and reasons again. High interpretability; natural error recovery; adapts dynamically. The dominant pattern for exploratory loops.
- **Plan-and-Execute** — the loop opens by generating a complete plan, validates it, then executes steps (potentially in parallel). More efficient for predictable tasks where parallelism matters; less adaptive to unexpected tool outputs.

Modern reasoning models (Gemini 2.5, Claude with extended thinking) internalize planning into their inference process, making the Thought step implicit. For loops built on these models, explicit reasoning nodes are unnecessary — the model plans inside a single API call.

### Skills as the compounding lever

Skills (reusable, dense markdown files encoding project conventions) are the most underused component of agentic loops in practice. A skill encodes things the developer never wants the agent to re-derive: test commands, coding conventions, deployment patterns, examples of correct output. The skill is loaded once per loop run; it replaces the need to re-prompt conventions on every run.

Design guidance:
- One skill per task domain — do not create monolithic skill files that fill the context window.
- Make skills **dense but scoped**: maximize signal per token, minimize scope per file.
- Build an index skill so the agent can locate and load only the skills it needs for a given run.

### Verifiable goals vs. fuzzy goals

The quality of a loop's exit condition is the primary determinant of loop reliability. A fuzzy goal ("make it good") produces loops that run indefinitely or optimize toward the wrong proxy. A verifiable goal produces loops that converge reliably.

| Goal type | Example | Risk |
|---|---|---|
| Deterministic | All unit tests pass; CI is green | Low; objective check |
| Soft / model-judged | Reviewer sub-agent checks UI against spec | Medium; depends on reviewer quality |
| Criteria list | Predefined subjective checklist | Medium; must be explicit and complete |
| Fuzzy | "Improve this"; "make it better" | High; no convergence signal |

### Safety rails (required for any production loop)

Every serious loop needs hard limits that override the agent's own assessment:

- **Max iteration count** — a ceiling on how many cycles the loop can run before halting.
- **No-progress detection** — halt if consecutive iterations produce no meaningful state change.
- **Token / dollar budget cap** — a per-run or per-day ceiling enforced outside the agent.
- **External verification** — run tests, type-check, diff against spec; do not accept the agent's claim of "done" as the sole exit signal.

## Design decisions & trade-offs

**When to build a loop vs. when to just prompt:**
- Task is one-off → prompt the model directly; a loop adds overhead without benefit.
- Task repeats with a clear pass/fail signal → a loop pays for itself in the second run.
- Goal is still vague → define the goal first; a loop with a fuzzy goal can produce worse outcomes than a careful manual pass.

**Autonomy budget:**
The cost of a loop scales super-linearly with autonomy and run time. An agent that self-prompts, reviews itself, spawns helpers, and retries can burn millions of tokens overnight. Treat token/dollar budget as a first-class design constraint, not an afterthought. Start with supervised, manual-launch loops; extend to fully autonomous only when value per token is demonstrated.

**Separation of writer and judge (adversarial code review):**
The sub-agent that produces output should not be the sub-agent that decides whether it is good enough — "the model that wrote the code is too nice grading its own homework." This maker/checker split, sometimes called **adversarial code review**, is what makes a loop's "it's done" mean something while you are not watching; give the reviewer different instructions and often a different model. Claude Code's `/goal` applies the same split to the *stop condition itself*: a fresh model decides whether the loop is complete after each turn, rather than the model that did the work.

**Skills maintenance overhead:**
Skills must be kept current. A skill encoding an outdated convention silently degrades loop quality on every run. Treat skill maintenance as part of the engineering workflow — skills are code, not documentation.

### The human cost ledger: what loops do not remove

A better loop makes three problems *sharper*, not easier — and none of them are tokens. Osmani names them precisely:

| Liability | What it is | Mitigation |
|---|---|---|
| **Intent debt** | The agent starts every run cold and fills any gap in your intent with a confident guess. | Write intent down on the outside as skills — conventions, build steps, the "we don't do it like this because of that incident." Skills are how intent stops costing you every cycle. |
| **Comprehension debt** | The faster the loop ships code you didn't write, the wider the gap between what exists and what you understand. | Read what the loop produced; verification ("done" is a claim, not a proof) stays a human responsibility. |
| **Orchestration tax** | Worktrees remove the *mechanical* collision of parallel agents, but your review bandwidth — not the tool — is the real ceiling on parallelism. | Scale concurrency to the review capacity you actually have, not to what the tool permits. |
| **Cognitive surrender** | The comfortable posture of accepting whatever the loop returns without forming an opinion. | Treat loop design as judgment work; it is the cure when done to move faster on understood work, the accelerant when done to avoid understanding. |

The defining warning: **"two people can build the exact same loop and get completely opposite results."** One uses it to move faster on work they understand; the other to avoid understanding the work at all. The loop does not know the difference — which is why the leverage moved to loop *design*, and why design is harder than prompt engineering, not easier.

## State of the art

As of mid-2026, agentic loop patterns have reached production-grade tooling:

- **OpenAI Codex** has a built-in agentic loop that runs autonomously until the stated task is complete, including work tree isolation.
- **Anthropic Claude Code** supports work trees, sub-agent spawning, schedule-based automations, and persistent skills — all components of the 5+1 anatomy above.
- **Cursor** supports automation-based loop patterns via its tool invocation and agent session infrastructure.
- **LangGraph** implements the ReAct loop natively (model node + tools node + conditional edges), with built-in state management and HITL interrupt support.
- **LangChain / LangSmith** instrument the higher stack levels: `create_agent` for the agent loop, `RubricMiddleware` for the verification loop, LangSmith Deployment (cron triggers, webhooks) and Fleet channels for the event-driven loop, and LangSmith **Engine** (a trace-analysis agent) for the hill-climbing loop that rewrites harness config. OpenClaw "heartbeats" are a common event-driven trigger.

The vocabulary itself converged in mid-2026: the **stacked-loops / "loopcraft"** framing (Swyx) names how loops nest, and Osmani's 5+1 anatomy names the parts. Together they moved "loop engineering" from a Twitter slogan to a design discipline with named primitives, named liabilities, and product support across both major coding-agent ecosystems.

The paradigm shift was catalyzed by two independent public statements in mid-2026: Peter Steinberger (OpenClaw) stating that developers should no longer prompt agents but design loops, and Boris Cherny (Claude Code, Anthropic) independently stating that his job is now to write loops, not prompts. The convergence from both the OpenAI and Anthropic ecosystems accelerated adoption.

Addy Osmani's 5+1 framework (automations, work trees, skills, plugins, sub-agents + memory) is the current canonical anatomy for describing and designing agentic loops.

## Pitfalls & anti-patterns

**The token furnace.** A loop without a verifiable exit condition never knows it is done. It generates confident output indefinitely, producing what looks like productivity while accumulating cost without convergence.

**Fuzzy goal optimization.** If the verifiable goal is underspecified, the loop optimizes toward whatever proxy it can measure — often something easy to maximize that diverges from actual quality. This can produce outcomes worse than a single careful manual pass.

**Unconstrained overnight runs.** Running loops unattended without budget caps is the primary source of runaway costs. Treat supervised loop runs as the default; unsupervised runs require demonstrated reliability and hard budget guardrails.

**Skill-less loops.** Running a loop without skills means the agent re-derives project conventions on every run — expensive in tokens and inconsistent in output. This is the most common waste pattern in early agentic loop adoption.

**Mistaking automation for a loop.** A fixed automation executes predetermined steps in order; it does not observe state or adapt. A loop's value comes from the decision-maker being inside the execution cycle. Building a sophisticated automation and calling it a loop produces none of the adaptability benefits.

**No planning inside the loop.** A loop that reacts to observations without reasoning about strategy is a tool-calling loop, not an agent. See [[agent-planning]] for the planning patterns that give loops coherent multi-step reasoning.

## See also

- [[agentic-harness]]
- [[context-engineering]]
- [[agent-planning]]
- [[llm-tool-use]]
- [[multi-agent-orchestration]]
- [[agent-memory-architectures]]
- [[agentic-system-design]]
- [[human-in-the-loop-design]]
- [[agent-governance-and-policy]]
- [[ai-agent-observability]]

## Sources

- François, L. (2026). Loop Engineering Explained. Towards AI / YouTube. raw/2026-06-21-loop-engineering.md
- Osmani, A. (2026-06-07). Loop Engineering. https://addyosmani.com/blog/loop-engineering/ — raw/2026-06-26-loop-engineering-osmani-anatomy.md
- Runkle, S. (2026-06-16). The Art of Loop Engineering. LangChain. https://www.langchain.com/blog/the-art-of-loop-engineering — raw/2026-06-26-loop-engineering-langchain-stack.md
- Anthropic. (2025). Building effective agents. https://www.anthropic.com/engineering/building-effective-agents
- Iusztin, P. (Decoding AI). AI Workflows vs Agents: The Autonomy Slider. raw/2026-06-23-decodingai-01-ai-workflows-vs-agents.md
- Iusztin, P. (Decoding AI). Writing AI Agents From Scratch: Planning Is The Key. raw/2026-06-23-decodingai-06-agent-planning.md
- Iusztin, P. (Decoding AI). Building Production ReAct Agents From Scratch. raw/2026-06-23-decodingai-07-react-agents.md
