---
title: Agentic Harness
aliases: [agent harness, harness architecture, coding agent harness, agentic harness system design]
type: concept
domain: ai-agentic
status: mature
tags: [agents, harness, claude-code, subagents, skills, permissions, sandbox, memory, runtime, hooks, system-design]
updated: 2026-06-26
sources:
  - raw/2026-06-26-decodingai-10-agentic-harness-system-design.md
  - "https://code.claude.com/docs/en/sub-agents"
  - "https://code.claude.com/docs/en/skills"
  - "https://code.claude.com/docs/en/settings"
  - "https://code.claude.com/docs/en/memory"
---

# Agentic Harness

> [!summary]
> An **agentic harness** is the framework that wraps an LLM and its tools and turns a
> bare reasoning loop into a runnable system — message queue, sandbox, permission layer,
> skills, memory, subagent catalog, durable runtime, and front-ends. The agent loop
> itself is small (~150 lines) and commoditized; the harness is the ~80% of the
> architecture that has standardized around a common shape (Claude Code is the reference
> implementation). The architect's job is no longer to build a harness from scratch but to
> make one decision per component: **build, configure, or use as-is** — spending the scarce
> "build" budget only where it buys a moat (memory/context) while configuring the
> safety-critical layers (permissions, sandbox, hooks) **deterministically**, never
> trusting a model-side instruction as a control.

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
component, decide **build / configure / use-as-is**. The component descriptions below are
grounded in **Claude Code**, the most fully documented reference harness.

**The five layers (inner to outer):**

| Layer | What lives here | Default verdict |
|---|---|---|
| **Agent** | The loop: LLM + tools in a [[agent-planning\|ReAct]] pattern (~150 LOC stripped of optimization) | Use as-is |
| **Harness** | Message queue, sandbox, services (memory, LLM gateway), skills, permission system, hooks, agent catalog + subagents | Configure |
| **Runtime** | Durable execution (Prefect, Temporal, Kitaru): non-blocking HITL, scheduling, durability, credentials proxy | Use / configure |
| **Presentation** | Multiple front-ends (TUI, web, mobile) over a pub/sub bus or custom services | Configure |
| **Observability** | Tracing, logging, metrics across the whole stack | Use as-is |

![[2026-06-26-decodingai-10-agentic-harness-system-design-02.png|The five-layer agentic harness architecture]]
*Figure: The five-layer agentic harness — agent, harness, runtime, presentation, observability — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].*

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
it."* Deterministic allow/deny rules, a sandbox jail, `PreToolUse` hooks, and monotonic
permission narrowing are trustworthy precisely *because* no model decides them. Claude
Code's own documentation draws the line explicitly: CLAUDE.md and skills are *"context,
not enforced configuration… To block an action regardless of what Claude decides, use a
PreToolUse hook."* Treating a model-side instruction (e.g. "you are in read-only plan
mode") as a security control is the central mistake — from a security view it should be
**treated as already bypassed**. This is the same lesson as [[prompt-injection]]: never
let the model be the guard on its own actions.

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

Agents are **configuration files (markdown + YAML frontmatter), not code** — so a new
agent is discoverable without modifying the loop. In Claude Code they live in
`.claude/agents/` (project) or `~/.claude/agents/` (user); only `name` and `description`
are required, and a single subagent file exposes a deep configuration surface:

| Field | Purpose |
|---|---|
| `tools` / `disallowedTools` | Allowlist / denylist of tools (`disallowedTools` applied first, then `tools` resolves against the remainder) |
| `model` | `sonnet` / `opus` / `haiku` / `fable` / full ID / `inherit` (default) — route cheap work to a small model |
| `permissionMode` | `default`, `acceptEdits`, `plan`, `auto`, `dontAsk`, `bypassPermissions` |
| `skills` | Skills preloaded (full content injected) at startup |
| `memory` | Persistent memory scope (`user` / `project` / `local`) for cross-session learning |
| `hooks` | Lifecycle hooks scoped to this subagent (e.g. a `PreToolUse` validator) |
| `isolation: worktree` | Run in a throwaway [[git-worktrees-parallel-agents\|git worktree]] |

The built-in catalog matches Iusztin's "minimal catalog" almost exactly: **Explore**
(Haiku, read-only — Write/Edit denied), **Plan** (read-only research for plan mode), and
**general-purpose** (all tools, multi-step). Claude delegates automatically based on each
agent's `description`.

A **subagent** is *"the same loop re-entered with a cloned context and a restricted tool
list."* The Claude Code mechanics confirm the picture: each subagent *"runs in its own
context window"* starting **fresh and isolated** (it does not see the parent's history),
and *"only the relevant summary returns to your main conversation."* Parent and child do
not chat peer-to-peer — the topology is **master–slave orchestration**, the same
convergence documented in [[agentic-system-design]] and [[multi-agent-orchestration]].
Subagents can nest, but depth is capped (a subagent at depth five cannot spawn further) —
a structural guard against runaway fan-out.

![[2026-06-26-decodingai-10-agentic-harness-system-design-04.png|Parent orchestrator spawns a subagent that returns a compressed summary]]
*Figure: A parent orchestrator spawns an isolated subagent and gets back only a compressed summary (master–slave, not peer-to-peer) — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].*

### Skills — *configure heavily (highest ROI)*

A skill is a `SKILL.md` file: **YAML frontmatter** (`description` + optional
`allowed-tools`, `disallowed-tools`, `disable-model-invocation`, `user-invocable`,
`model`) plus a markdown body of instructions. **Progressive disclosure** is the load-
bearing mechanism: *"a skill's body loads only when it's used, so long reference material
costs almost nothing until you need it"* — the description is always available so Claude
can decide to load it, while the body stays out of context until invoked. This is exactly
why skills scale to dozens without context bloat. Two frontmatter switches control
*who* triggers a skill — `disable-model-invocation: true` (only the user can run it, for
side-effecting workflows like `/deploy`) and `user-invocable: false` (only Claude loads
it, for background knowledge). Skills live at enterprise / personal (`~/.claude/skills/`)
/ project (`.claude/skills/`) / plugin scope, and support **dynamic context injection**
(`` !`git diff HEAD` `` runs the command and inlines its output before Claude sees the
skill). Iusztin rates skills the **highest return-on-effort** customization — they encode
your workflows without touching any code. See the skills discussion in [[agentic-loop]].

![[2026-06-26-decodingai-10-agentic-harness-system-design-06.png|Skills merged from three sources and injected as a system reminder]]
*Figure: The skills pipeline — bundled / user / MCP skills merged and injected as a system reminder, with progressive disclosure — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].*

### Memory — *build your own layer*

> [!warning] The article says `AGENTS.md`; Claude Code reads `CLAUDE.md`
> Claude Code loads **`CLAUDE.md`**, not `AGENTS.md`. To reuse an existing `AGENTS.md`,
> import it from `CLAUDE.md` with `@AGENTS.md`. The generic "always-loaded user file" in
> the source maps to CLAUDE.md in this harness.

Claude Code carries two complementary memory systems, **both loaded at the start of every
session as context, not enforced config**:

- **CLAUDE.md (you write it).** Persistent instructions, discovered by **walking up the
  directory tree** and concatenated root-down; nested files in subdirectories load on
  demand when Claude reads files there. Target **under 200 lines**; supports `@path`
  imports (max depth four) and path-scoped `.claude/rules/`. Scopes: managed policy →
  user (`~/.claude/CLAUDE.md`) → project (`./CLAUDE.md`) → local (`CLAUDE.local.md`).
- **Auto memory (Claude writes it).** Per-repository, at
  `~/.claude/projects/<project>/memory/`: a **`MEMORY.md` index** (the **first 200 lines
  or 25 KB** load every session) plus **topic files** (`debugging.md`, `api-conventions.md`,
  …) read **on demand**, not at startup. Claude decides what is worth persisting from your
  corrections and preferences — relevance ranking by a side-query, **no embeddings**.

This is precisely the "LLM-extracted index + on-demand detail files, ranked without a
vector store" design Iusztin highlights. (The article's older `logs/YYYY-MM-DD.md`
daily-append framing has been superseded by topic files, but the principle — a small
always-loaded index over lazily-loaded detail — is the same.) The highest-leverage move
is to put a custom layer **behind an MCP server** so it is portable across harnesses. See
[[agent-memory-architectures]], [[vector-and-embedding-stores]].

![[2026-06-26-decodingai-10-agentic-harness-system-design-07.png|Three memory designs: file-backed, SQLite-backed, session-tree with a custom MCP layer]]
*Figure: Three memory designs — file-backed, SQLite-backed, and a session-tree behind a custom MCP layer — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].*

### Sandbox — *use as-is, configure execution location*

The sandbox decides **where tool calls execute**: **Remote** (Modal, RunPod, GCP),
**Local-with-jail** (Docker, Firecracker), or **Direct-on-host** (no isolation). A useful
reframing: sandboxes are **distributed workers**, so one harness can fan out parallel
remote jobs. The jail is *derived from the permission rules* and **always denies writes to
settings/config files** — Claude Code even hard-blocks writes to `.git`, `.claude`,
`.vscode`, and similar under `bypassPermissions`, because you cannot let an agent rewrite
the rules that constrain it. Managed settings can force `sandbox.enabled`. See
[[network-segmentation]], [[confidential-computing]].

![[2026-06-26-decodingai-10-agentic-harness-system-design-08.png|Bash execution routing: remote sandbox, local sandbox, or direct host]]
*Figure: Bash execution routing — remote sandbox, local jail, or direct-on-host per risk/cost — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].*

### Permission layer & hooks — *configure carefully, no AI*

For every tool call the permission system resolves one of three outcomes:

- **Allow** — execute immediately.
- **Ask** — surface to the user; execute on approval, otherwise deny.
- **Deny** — synthesize a denial tool-result the model sees as a normal observation.

In Claude Code these are `permissions.allow` / `permissions.ask` / `permissions.deny`
arrays in `settings.json`, with **`Action(pattern)`** rules (`Bash(git *)`,
`Read(./.env)`, `Write(...)`, `Edit(...)`) and glob wildcards (`*`, `**`). Rules **merge
across the scope hierarchy** (managed → local → project → user) and **deny always
overrides allow**. The session-level **modes** are `default`, `acceptEdits`, `plan`, and
`bypassPermissions` (plus `auto` / `dontAsk`), cycled with `Shift+Tab` and persisted via
`defaultMode`. Managed settings can pin `allowManagedPermissionRulesOnly` so user/project
rules cannot loosen org policy.

> [!warning] Deterministic vs. prompt-side enforcement
> **Deterministic** controls — allow/deny rules, the sandbox jail, `PreToolUse` hooks,
> monotonic permission narrowing — are trustworthy because the client enforces them
> *"regardless of what Claude decides."* **Prompt-side** controls — CLAUDE.md, skills, and
> "plan mode" delivered as context — are *suggestions*; the docs state plainly they are
> "not a hard enforcement layer." From a security standpoint a prompt-side control should
> be **treated as already bypassed**. The real enforcement primitive is the **hook**: a
> `PreToolUse` hook runs a shell command before a tool executes and can **exit 2 to block
> it** — e.g. a script that lets `SELECT` through but blocks `INSERT/UPDATE/DELETE`. Real
> safety on critical actions comes from this plus [[human-in-the-loop-design|human-in-the-loop]],
> not from instructing the model to behave.

**Monotonic narrowing**: a child agent can never hold more permission than its parent —
if the parent runs in `bypassPermissions` or `acceptEdits`, that *"takes precedence and
cannot be overridden"* by a child's frontmatter. This is the harness analogue of
least-privilege ([[zero-trust-architecture]], [[agent-identity-and-access]]).

![[2026-06-26-decodingai-10-agentic-harness-system-design-09.png|Permission decision tree combining agent modes and user-defined rules]]
*Figure: The permission decision tree — agent modes combined with user/managed rules resolve each call to allow/ask/deny — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].*

### Message flow & compaction

The happy path: user message → TUI → **priority queue** → wait for agent availability →
agent loop (stream → check → tool call → append → recurse) → answer → TUI → user.
**Compaction** triggers as token usage approaches the context limit, collapsing history to
`[system prompt] + [summary] + [recent tail]` — the harness-level expression of
[[context-engineering]].

![[2026-06-26-decodingai-10-agentic-harness-system-design-03.png|Message flow: priority gate, agentic loop, context compaction]]
*Figure: Message flow through the harness — priority gate → agentic loop → context compaction — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].* Notably, project-root CLAUDE.md **survives compaction** (it is
re-read from disk and re-injected), while conversation-only instructions do not — a
concrete reason to write durable rules to disk rather than the chat.

## Design decisions & trade-offs

**The build/configure/use triage** is the whole discipline. Iusztin's component verdicts:

![[2026-06-26-decodingai-10-agentic-harness-system-design-01.png|Three-tier decision per component: use as-is, configure, or build custom]]
*Figure: The per-component triage — use-as-is, configure, or build custom — spend the scarce "build" budget only where it buys a moat — source [[2026-06-26-decodingai-10-agentic-harness-system-design]].*

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
| Permissions / hooks | **Configure carefully** | The safety layer; get it deterministic |

**Build vs. rent.** The failure modes are symmetric. Overbuilding reimplements
commoditized plumbing and falls behind the upstream harness; underbuilding leaves you a
renter with no portable advantage. The defensible position is: rent the loop and tools,
own the context layer.

**Where execution runs** trades isolation against cost and latency: direct-on-host is
fastest and least safe; local jail (Docker/Firecracker) balances; remote workers
(Modal/RunPod) add isolation *and* parallelism but cost network round-trips and infra.
Drive the choice from blast radius, not convenience — see [[ai-specific-security]].

**Configuration-as-policy.** Because agents, skills, permissions, and memory are all
plain files in a known layout (`.claude/`), the harness's behavior is **version-controlled,
reviewable, and lintable** — the same governance posture as [[policy-as-code]] and
[[infrastructure-as-code]]. Managed-settings scopes let an org enforce non-overridable
rules (permission denylists, forced sandbox, required version) across every developer.

**Durability is a runtime concern, not a loop concern.** Non-blocking human-in-the-loop,
scheduling, retries across crashes, and credential proxying belong in the durable runtime
(Temporal/Prefect/Kitaru), not bolted into the agent. This keeps the loop small and
testable and lets a [[delegate-review-own|review gate]] pause for hours without holding a
process open.

## State of the art

- **Claude Code is the de-facto reference harness** for this anatomy. Its ~40 tools,
  agents-as-config catalog (`.claude/agents/`), skills with progressive disclosure
  (`SKILL.md`), two-tier file-backed memory (`CLAUDE.md` + auto-memory `MEMORY.md`/topic
  files), permission modes, hooks, and sandbox/jail are the components most other harnesses
  are converging on. Codex and Cursor implement overlapping subsets (see [[agentic-loop]]
  State of the art).
- **Agents and skills as configuration** (markdown + YAML, not code) is now the norm,
  making catalogs shareable, diffable, and lintable rather than forked code. The open
  **Agent Skills** standard (`SKILL.md`) is explicitly cross-tool.
- **Hooks are the real enforcement layer.** As harnesses make explicit that prompt-side
  instructions are advisory, deterministic `PreToolUse`/`PostToolUse` hooks (block on
  exit 2, run linters/validators) have become the supported way to impose hard guarantees.
- **MCP-backed memory** is the emerging best practice for the one component worth
  building, precisely because it survives a change of harness ([[model-context-protocol]]).
- **Durable-execution runtimes** (Temporal, Prefect, and agent-specific layers like
  Kitaru) increasingly sit under long-running agents, supplying the
  scheduling/HITL/durability the loop deliberately omits.

## Pitfalls & anti-patterns

- **Trusting prompt-side guards.** Treating CLAUDE.md, a skill, or "plan mode" (all
  delivered as context) as a security boundary. They are suggestions; assume they are
  bypassed and enforce with permission rules and hooks.
- **Rebuilding the commoditized 80%.** Hand-rolling the loop, tool interface, or queue
  to feel in control — weeks spent reimplementing what every harness already ships.
- **No custom context layer.** Renting every layer including memory, so nothing
  proprietary accumulates and you have no moat.
- **Letting agents write their own rules.** Permitting writes to settings/permission/
  config files; the jail must always deny these.
- **Permissions that fail open.** An `Ask` timeout that defaults to *allow*, or a child
  agent that escapes its parent's restrictions (broken monotonic narrowing).
- **Skill / context bloat.** Eager-loading skill bodies instead of using progressive
  disclosure, or letting CLAUDE.md grow past ~200 lines so working context starves and
  adherence drops.
- **Peer-to-peer subagents.** Reinventing swarm chatter instead of the master–slave,
  summarize-and-return topology the harness is built around (see [[agentic-system-design]]).
- **Unbounded subagent fan-out.** Spawning many subagents whose detailed results all
  return to the parent — re-flooding the very context the isolation was meant to protect.

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
- [[git-worktrees-parallel-agents]]
- [[policy-as-code]]
- [[ai-agent-observability]]

## Sources

- Iusztin, P. (Decoding AI). *Agentic Harness System Design*. raw/2026-06-26-decodingai-10-agentic-harness-system-design.md — five-layer anatomy; build/configure/use framework; tools, catalog, subagents, skills, memory, sandbox, and permission layers; message flow and compaction.
- [Claude Code Docs — Create custom subagents](https://code.claude.com/docs/en/sub-agents) — `.claude/agents/` layout, full frontmatter (`tools`/`disallowedTools`/`model`/`permissionMode`/`skills`/`memory`/`hooks`/`isolation`), fresh isolated context + summary-return, built-in Explore/Plan/general-purpose, nested-subagent depth limit, parent-precedence permission rule.
- [Claude Code Docs — Extend Claude with skills](https://code.claude.com/docs/en/skills) — `SKILL.md` structure, progressive disclosure (body loads on use), `allowed-tools`/`disable-model-invocation`/`user-invocable`, skill scopes, dynamic context injection.
- [Claude Code Docs — Settings & permissions](https://code.claude.com/docs/en/settings) — scope hierarchy, `permissions` allow/ask/deny, `Action(pattern)` rules, deny-overrides-allow, permission modes, managed-only enforcement.
- [Claude Code Docs — How Claude remembers your project](https://code.claude.com/docs/en/memory) — CLAUDE.md load order + `@import`, `AGENTS.md` relationship, auto-memory `MEMORY.md`/topic-file design (first 200 lines/25 KB), "context not enforced configuration / use a PreToolUse hook" distinction, compaction survival.
