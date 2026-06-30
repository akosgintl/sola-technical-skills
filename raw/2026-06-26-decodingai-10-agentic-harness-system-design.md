---
title: "Agentic Harness System Design"
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, agentic-harness, claude-code, subagents, skills, permissions, sandbox, memory, runtime]
updated: 2026-06-30
source_url: https://www.decodingai.com/p/agentic-harness-system-design
source_type: article
ingested: 2026-06-26
feeds: [agentic-harness, agentic-system-design, agentic-loop, agent-memory-architectures, model-context-protocol]
---

# Agentic Harness System Design

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Series:** AI Agents Foundations (harness deep-dive) · **URL:** https://www.decodingai.com/p/agentic-harness-system-design

## Key takeaways

- An **agentic harness** is the framework wrapping an LLM + its tools — the infrastructure that orchestrates how the agent interacts with external systems. Roughly **80% of harness architecture is commoditized**; ~20% is where you customize. The governing question per component: **build, configure, or use as-is?**
- **Five-layer architecture:** (1) **Agent** — innermost loop, LLM + tools in a ReAct pattern, ~150 LOC stripped of optimization; (2) **Harness** — wraps the agent with message queue, sandbox, services (memory, LLM gateway), skills, permission system, agent catalog + subagents; (3) **Runtime** — durable execution (Prefect, Temporal, Kitaru): non-blocking HITL, scheduling, durability, credentials proxy; (4) **Presentation** — multiple front-ends (TUI, web, mobile) over a pub/sub bus; (5) **Observability** — tracing, logging, metrics across the stack.
- **Tools (use as-is, configure scope):** one interface = name + input schema + execute. Claude Code ships ~40 built-ins across families — File I/O (read/write/edit/glob/grep), Execution (bash), Orchestration (plan mode, sleep, spawning, worktrees), Tasks (state machine), Web (search/fetch), MCP (external servers), Scheduling (cron, remote triggers, skills). Verdict: configure which tools each agent may call; build new domain tools as MCP servers.
- **Agent catalog (configure, rarely build):** agents are config files (YAML/markdown), not code — discoverable without touching the loop. Minimal catalog: Build (primary, default), Plan (primary, read-only), General-Purpose (subagent fallback), Explore (subagent, cheap model, read-only), Code Reviewer (subagent, git-aware). Each declares allowed/disallowed tools (patterns like `Bash(git *)`) and permissions. **Safety by narrowing: a child agent can never exceed parent permissions (monotonic narrowing).**
- **Subagents (use as-is):** "the same loop re-entered with a cloned context and a restricted tool list." Output compressed by ~30-second summarizers; communication over queues (parent awaits); topology is **master–slave orchestration, not peer-to-peer swarms**; only summarized output re-injects into parent context.
- **Skills (configure heavily — highest ROI):** markdown recipes (instructions + allowed tools). Pipeline: collect from three sources (bundled, user-defined, MCP) → cap at ~1% of context window → inject as system reminder. **Progressive disclosure**: skill *names* always loaded, *bodies* load on-demand — scales to dozens without context bloat.
- **Memory (build your own layer — the moat):** default memory loads into context before turns. File-backed (Claude Code pattern): user `.md` files `AGENTS.md` (always) + `**/AGENTS.md` (per-directory); LLM-extracted `MEMORY.md` (index, ~200 lines) + `logs/YYYY-MM-DD.md` (daily append-only); a small-model side-query ranks topics **without embeddings**. Alternatives: SQLite-backed, append-only session trees. Verdict: "the highest-leverage move is a custom memory layer behind an MCP server — harness-independent, fully yours." The context layer is your moat.
- **Sandbox (use as-is, configure location):** decides where tool calls execute — Remote (Modal, RunPod, GCP), Local-with-jail (Docker, Firecracker), or Direct-on-host (no isolation). Sandboxes act as distributed workers — one harness manages parallel remote jobs. The jail derives from permission rules and **always denies writes to settings files**.
- **Permission layer (configure carefully — essentially no AI):** resolves each tool call to **Allow** (execute), **Ask** (surface to user), or **Deny** (synthesize a denial tool-result). Two inputs: agent modes (`default`, `acceptEdits`, `bypassPermissions`, `plan`) + user rules (wildcards like `Bash(git *)`). **Critical distinction:** deterministic enforcement (allow/deny rules, sandbox jail, monotonic narrowing) is trustworthy; **prompt-side enforcement (plan mode via system reminder) is a suggestion and, from a security view, should be treated as already bypassed.** Real safety = human-in-the-loop on critical decisions.
- **Message flow (happy path):** user → TUI → priority queue → wait for agent availability → agent loop (stream → check → tool call → append → recurse) → answer → TUI → user. **Compaction** activates near the context limit, keeping `[system prompt] + [summary] + [recent tail]`.
- **Build/Configure/Use verdict table:** core loop = use as-is (optimized, ~150 LOC); built-in tools = use as-is; tool scope = configure; agent catalog = configure; subagents = use as-is; skills = configure heavily; memory = **build custom MCP**; sandbox location = configure; permissions = configure carefully.

## Notable quotes

- "Overbuild, and you burn weeks reimplementing… Under-build, and you stay a renter of someone else's system."
- The permission layer "has almost no AI in it, yet it's what makes the whole system safe to run."
- "The context layer behind an MCP server is the moat. It's harness-portable, fully yours."

## Key visuals

Localized to `raw/assets/2026-06-26-decodingai-10-agentic-harness-system-design/` (9 diagrams, visual backfill 2026-06-30). Embedded into [[agentic-harness]].

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | Three-tier decision: use-as-is / configure / build | |
| `…-02.png` | Five-layer agentic harness architecture | [[agentic-harness]] |
| `…-03.png` | Message flow: priority gate, loop, compaction | [[agentic-harness]] |
| `…-04.png` | Parent orchestrator spawning a subagent | |
| `…-05.png` | Parent-subagent channel with output compression | |
| `…-06.png` | Skills pipeline injected as a system reminder | |
| `…-07.png` | Three memory designs (file / SQLite / session-tree) | |
| `…-08.png` | Bash execution routing (remote/local/host) | |
| `…-09.png` | Permission decision tree (modes + rules) | |

## Feeds

- [[agentic-harness]] (new page — primary)
- [[agentic-system-design]], [[agentic-loop]], [[agent-memory-architectures]], [[model-context-protocol]], [[human-in-the-loop-design]], [[agent-governance-and-policy]]
