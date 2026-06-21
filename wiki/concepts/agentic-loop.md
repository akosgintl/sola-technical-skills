---
title: Agentic Loop
aliases: [loop engineering, agent loop, agentic loop, loop-based development, loop-engineering]
type: concept
domain: ai-agentic
status: mature
tags: [agent-loops, agentic, loop-engineering, sub-agents, skills, automation]
updated: 2026-06-21
sources:
  - raw/2026-06-21-loop-engineering.md
  - "https://www.anthropic.com/engineering/building-effective-agents"
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

The term **loop engineering** (popularized mid-2026 by Peter Steinberger, creator of OpenClaw, and independently confirmed by Boris Turney, who leads Claude Code at Anthropic) describes the practice of designing these loops rather than prompting agents directly. The practitioner's job shifts from "write the best prompt" to "design the trigger, define the verifiable goal, and build the skills and tools the loop will use."

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

**Separation of writer and judge:**
The sub-agent that produces output should not be the sub-agent that decides whether it is good enough. The reviewing sub-agent should have access to the verifiable goal (test results, spec) and independent context, not just the writer's narrative of what it did.

**Skills maintenance overhead:**
Skills must be kept current. A skill encoding an outdated convention silently degrades loop quality on every run. Treat skill maintenance as part of the engineering workflow — skills are code, not documentation.

## State of the art

As of mid-2026, agentic loop patterns have reached production-grade tooling:

- **OpenAI Codex** has a built-in agentic loop that runs autonomously until the stated task is complete, including work tree isolation.
- **Anthropic Claude Code** supports work trees, sub-agent spawning, schedule-based automations, and persistent skills — all components of the 5+1 anatomy above.
- **Cursor** supports automation-based loop patterns via its tool invocation and agent session infrastructure.

The paradigm shift was catalyzed by two independent public statements in mid-2026: Peter Steinberger (OpenClaw) stating that developers should no longer prompt agents but design loops, and Boris Turney (Claude Code, Anthropic) independently stating that his job is now to write loops, not prompts. The convergence from both the OpenAI and Anthropic ecosystems accelerated adoption.

Addy Osmani's 5+1 framework (automations, work trees, skills, plugins, sub-agents + memory) is the current canonical anatomy for describing and designing agentic loops.

## Pitfalls & anti-patterns

**The token furnace.** A loop without a verifiable exit condition never knows it is done. It generates confident output indefinitely, producing what looks like productivity while accumulating cost without convergence.

**Fuzzy goal optimization.** If the verifiable goal is underspecified, the loop optimizes toward whatever proxy it can measure — often something easy to maximize that diverges from actual quality. This can produce outcomes worse than a single careful manual pass.

**Unconstrained overnight runs.** Running loops unattended without budget caps is the primary source of runaway costs. Treat supervised loop runs as the default; unsupervised runs require demonstrated reliability and hard budget guardrails.

**Skill-less loops.** Running a loop without skills means the agent re-derives project conventions on every run — expensive in tokens and inconsistent in output. This is the most common waste pattern in early agentic loop adoption.

**Mistaking automation for a loop.** A fixed automation executes predetermined steps in order; it does not observe state or adapt. A loop's value comes from the decision-maker being inside the execution cycle. Building a sophisticated automation and calling it a loop produces none of the adaptability benefits.

## See also

- [[context-engineering]]
- [[multi-agent-orchestration]]
- [[agent-memory-architectures]]
- [[agentic-system-design]]
- [[human-in-the-loop-design]]
- [[agent-governance-and-policy]]
- [[ai-agent-observability]]

## Sources

- François, L. (2026). Loop Engineering Explained. Towards AI / YouTube. raw/2026-06-21-loop-engineering.md
- Anthropic. (2025). Building effective agents. https://www.anthropic.com/engineering/building-effective-agents
