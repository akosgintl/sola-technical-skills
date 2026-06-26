---
title: Agentic Harness
aliases: [agent harness, harness architecture, coding agent harness, agentic harness system design]
type: concept
domain: ai-agentic
status: draft
tags: [agents, harness, claude-code, subagents, skills, permissions, sandbox, memory, runtime, system-design]
updated: 2026-06-26
sources:
  - raw/2026-06-26-decodingai-10-agentic-harness-system-design.md
---

# Agentic Harness

> [!summary]
> An **agentic harness** is the framework that wraps an LLM and its tools and turns a
> bare reasoning loop into a runnable system — message queue, sandbox, permission layer,
> skills, memory, subagent catalog, durable runtime, and front-ends. The agent loop
> itself is small (~150 lines) and commoditized; the harness is the ~80% of the
> architecture that is now standardized around a common shape (Claude Code is the
> reference implementation). The architect's job is no longer to build a harness from
> scratch but to make one decision per component: **build, configure, or use as-is** —
> and to spend the scarce "build" budget only where it buys a moat (memory/context),
> while configuring the safety-critical layers (permissions, sandbox) deterministically.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

If the [[agentic-loop]] is the engine — an LLM observing, calling tools, and iterating —
the **harness** is the rest of the car: everything around the loop that makes it safe,
durable, multi-user, observable, and useful in production. Where [[agentic-system-design]]
asks *how many agents and in what topology*, the harness asks *what infrastructure does a
single coding-agent platform need*, and answers it as a layered architecture.

Paul Iusztin's framing (Decoding AI) reverse-engineers this anatomy from production
coding agents and makes one structural claim: roughly **80% of a harness is commoditized**
— the same components, in the same arrangement, across implementations — leaving ~20% for
genuine customization. That makes the central design activity a triage: for each
component, decide **build / configure / use-as-is**.

**The five layers (inner to outer):**

| Layer | What lives here | Default verdict |
|---|---|---|
| **Agent** | The loop: LLM + tools in a [[agent-planning\|ReAct]] pattern (~150 LOC stripped of optimization) | Use as-is |
| **Harness** | Message queue, sandbox, services (memory, LLM gateway), skills, permission system, agent catalog + subagents | Configure |
| **Runtime** | Durable execution (Prefect, Temporal, Kitaru): non-blocking HITL, scheduling, durability, credentials proxy | Use / configure |
| **Presentation** | Multiple front-ends (TUI, web, mobile) over a pub/sub bus or custom services | Configure |
| **Observability** | Tracing, logging, metrics across the whole stack | Use as-is |

## Why it matters

**The leverage has moved up a layer.** Writing a tool-calling loop is no longer where
the engineering value is — the loop is ~150 lines and every framework ships one. The
durable differentiation is in *how you assemble and constrain the harness around it*:
which tools each agent may touch, what the permission rules are, where code executes, and
— above all — what context the agent carries between turns and across runs. Iusztin's
sharpest line is the warning against getting the build/configure/use call wrong:
*"Overbuild, and you burn weeks reimplementing… Under-build, and you stay a renter of
someone else's system."*

**Most of the safety lives in the boring, AI-free parts.** The component that makes the
whole thing safe to run unattended is the permission layer, which *"has almost no AI in
it."* Deterministic allow/deny rules, a sandbox jail, and monotonic permission narrowing
are trustworthy precisely *because* no model decides them. Treating a model-side
instruction (e.g. "you are in read-only plan mode") as a security control is the central
mistake — from a security view it should be **treated as already bypassed**. This is the
same lesson as [[prompt-injection]]: never let the model be the guard on its own actions.

**Memory is the moat.** Almost every other layer is commoditized; the one place a custom
build pays off is the context/memory layer. Behind an [[model-context-protocol|MCP]]
server it becomes **harness-independent and fully yours** — portable across Claude Code,
Codex, or whatever replaces them — which is exactly where proprietary advantage
accumulates. See [[agent-memory-architectures]] and [[context-engineering]].

## Key concepts / building blocks

### Tools — *use as-is, configure scope*

Every tool conforms to one interface: **name + input schema + execute method**. A
reference harness (Claude Code) ships ~40 built-ins across families: File I/O
(read/write/edit/glob/grep), Execution (bash), Orchestration (plan mode, sleep, agent
spawning, worktrees), Tasks (a state machine for tracking work), Web (search/fetch),
[[model-context-protocol|MCP]] (external tool servers), and Scheduling (cron, remote
triggers, skills). The verdict: **configure which tools each agent may call; build new
domain tools as MCP servers** rather than forking the harness. See [[llm-tool-use]].

### Agent catalog & subagents — *configure / use-as-is*

Agents are **configuration files (YAML/markdown), not code** — so a new agent is
discoverable without modifying the loop. A minimal catalog: **Build** (primary mode,
default), **Plan** (primary, read-only), **General-Purpose** (subagent fallback),
**Explore** (subagent, cheap model, read-only), **Code Reviewer** (subagent, git-aware).
Each declares allowed tools, disallowed tools (patterns like `Bash(git *)`), and
permissions.

A **subagent** is *"the same loop re-entered with a cloned context and a restricted tool
list."* Its output is compressed by a ~30-second summarizer; parent and child communicate
over **queues** (the parent awaits the result); and only the **summarized** output
re-injects into the parent's context. The topology is deliberately **master–slave
orchestration, not a peer-to-peer swarm** — the same convergence documented in
[[agentic-system-design]] and [[multi-agent-orchestration]]: an orchestrator owning
context, spawning isolated children, with no peer chatter.

### Skills — *configure heavily (highest ROI)*

Skills are **markdown recipes** (instructions + an allowed tool set). The pipeline:
collect from three sources (bundled, user-defined, MCP servers) → cap the total at **~1%
of the context window** → inject as a system reminder. **Progressive disclosure** is the
trick that makes this scale: skill *names* are always loaded, but *bodies* load only
on-demand, so a harness can carry dozens of skills without context bloat. Iusztin rates
skills the **highest return-on-effort** customization — they encode your workflows without
touching any code. See the skills discussion in [[agentic-loop]].

### Memory — *build your own layer*

Default memory loads into context *before* each turn. The reference file-backed design:

- **User-authored** `.md` files — `AGENTS.md` (always loaded) and `**/AGENTS.md`
  (per-directory, loaded when working in that subtree).
- **LLM-extracted** files — `MEMORY.md` (an index, ~200 lines) and
  `logs/YYYY-MM-DD.md` (daily, append-only).
- A **small-model side-query ranks topics without embeddings** — cheap relevance
  scoring instead of a vector store.

Alternatives include SQLite-backed stores or append-only session trees. The
highest-leverage move is to put this layer **behind an MCP server** so it is portable
across harnesses. See [[agent-memory-architectures]], [[vector-and-embedding-stores]].

### Sandbox — *use as-is, configure execution location*

The sandbox decides **where tool calls execute**: **Remote** (Modal, RunPod, GCP),
**Local-with-jail** (Docker, Firecracker), or **Direct-on-host** (no isolation). A useful
reframing: sandboxes are **distributed workers**, so one harness can fan out parallel
remote jobs. The jail is *derived from the permission rules* and **always denies writes to
settings files** — you cannot let an agent rewrite the rules that constrain it. See
[[network-segmentation]], [[confidential-computing]].

### Permission layer — *configure carefully, no AI*

For every tool call the permission system resolves one of three outcomes:

- **Allow** — execute immediately.
- **Ask** — surface to the user; execute on approval, otherwise deny.
- **Deny** — synthesize a denial tool-result the model sees as a normal observation.

It combines two inputs: **agent modes** (`default`, `acceptEdits`, `bypassPermissions`,
`plan`) and **user rules** (config files with wildcards, e.g. `Bash(git *)`). The
load-bearing distinction:

> [!warning] Deterministic vs. prompt-side enforcement
> **Deterministic** controls — allow/deny rules, the sandbox jail, monotonic permission
> narrowing — are trustworthy. **Prompt-side** controls — e.g. "plan mode" implemented as
> a system reminder telling the model to stay read-only — are *suggestions*. From a
> security standpoint a prompt-side control should be **treated as already bypassed**.
> Real safety on critical actions comes from [[human-in-the-loop-design|human-in-the-loop]],
> not from instructing the model to behave.

**Monotonic narrowing**: a child agent can never hold more permission than its parent.
This is the harness analogue of least-privilege ([[zero-trust-architecture]],
[[agent-identity-and-access]]).

### Message flow & compaction

The happy path: user message → TUI → **priority queue** → wait for agent availability →
agent loop (stream → check → tool call → append → recurse) → answer → TUI → user.
**Compaction** triggers as token usage approaches the context limit, collapsing history to
`[system prompt] + [summary] + [recent tail]` — the harness-level expression of
[[context-engineering]].

## Design decisions & trade-offs

**The build/configure/use triage** is the whole discipline. Iusztin's component verdicts:

| Component | Decision | Why |
|---|---|---|
| Core loop | **Use as-is** | Optimized, ~150 LOC; nothing to gain by rebuilding |
| Built-in tools | **Use as-is** | Commoditized and stable |
| Tool scope | **Configure** | This is your access-control surface |
| Agent catalog | **Configure** | Define modes, tool restrictions, permissions |
| Subagents | **Use as-is** | Master–slave topology is sufficient |
| Skills | **Configure heavily** | Highest ROI; encodes your workflows |
| Memory layer | **Build (custom MCP)** | Proprietary context = the moat |
| Sandbox location | **Configure** | Local vs. remote vs. direct, per risk/cost |
| Permissions | **Configure carefully** | The safety layer; get it deterministic |

**Build vs. rent.** The failure modes are symmetric. Overbuilding reimplements
commoditized plumbing and falls behind the upstream harness; underbuilding leaves you a
renter with no portable advantage. The defensible position is: rent the loop and tools,
own the context layer.

**Where execution runs** trades isolation against cost and latency: direct-on-host is
fastest and least safe; local jail (Docker/Firecracker) balances; remote workers
(Modal/RunPod) add isolation *and* parallelism but cost network round-trips and infra.
Drive the choice from blast radius, not convenience — see [[ai-specific-security]].

**Durability is a runtime concern, not a loop concern.** Non-blocking human-in-the-loop,
scheduling, retries across crashes, and credential proxying belong in the durable runtime
(Temporal/Prefect/Kitaru), not bolted into the agent. This keeps the loop small and
testable and lets a [[delegate-review-own|review gate]] pause for hours without holding a
process open.

## State of the art

- **Claude Code is the de-facto reference harness** for this anatomy — its ~40 tools,
  agent-as-config catalog, skills with progressive disclosure, file-backed memory
  (`AGENTS.md` / `MEMORY.md` / daily logs), permission modes, and sandbox/jail are the
  components most other harnesses are converging on. Codex and Cursor implement
  overlapping subsets (see [[agentic-loop]] State of the art).
- **Agents-as-configuration** (YAML/markdown, not code) is now the norm, making catalogs
  shareable and lintable rather than forked code.
- **MCP-backed memory** is the emerging best practice for the one component worth
  building, precisely because it survives a change of harness ([[model-context-protocol]]).
- **Durable-execution runtimes** (Temporal, Prefect, and agent-specific layers like
  Kitaru) are increasingly the substrate under long-running agents, supplying the
  scheduling/HITL/durability the loop deliberately omits.

## Pitfalls & anti-patterns

- **Trusting prompt-side guards.** Treating "you are in read-only mode" (a system
  reminder) as a security boundary. It is a suggestion; assume it is bypassed and enforce
  deterministically.
- **Rebuilding the commoditized 80%.** Hand-rolling the loop, tool interface, or queue
  to feel in control — weeks spent reimplementing what every harness already ships.
- **No custom context layer.** Renting every layer including memory, so nothing
  proprietary accumulates and you have no moat.
- **Letting agents write their own rules.** Permitting writes to settings/permission
  files; the jail must always deny these.
- **Permissions that fail open.** An `Ask` timeout that defaults to *allow*, or a child
  agent that escapes its parent's tool restrictions (broken monotonic narrowing).
- **Skill / context bloat.** Eager-loading skill bodies instead of using progressive
  disclosure, or blowing past the ~1%-of-context budget so the working context starves.
- **Peer-to-peer subagents.** Reinventing swarm chatter instead of the master–slave,
  summarize-and-return topology the harness is built around (see [[agentic-system-design]]).

## See also

- [[agentic-loop]]
- [[agentic-system-design]]
- [[multi-agent-orchestration]]
- [[agent-memory-architectures]]
- [[context-engineering]]
- [[model-context-protocol]]
- [[llm-tool-use]]
- [[human-in-the-loop-design]]
- [[agent-identity-and-access]]
- [[agent-governance-and-policy]]
- [[prompt-injection]]
- [[ai-agent-observability]]

## Sources

- Iusztin, P. (Decoding AI). *Agentic Harness System Design*. raw/2026-06-26-decodingai-10-agentic-harness-system-design.md — five-layer anatomy; build/configure/use framework; tools, catalog, subagents, skills, memory, sandbox, and permission layers; message flow and compaction.
