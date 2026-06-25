---
title: Spec-Driven Development Tools
aliases: [SDD tools, spec-kit, Spec Kitty, Kiro, OpenSpec, Tessl, BMad]
type: concept
domain: emerging
status: mature
tags: [emerging, spec-driven-development, tooling, ai-coding, comparison]
updated: 2026-06-25
sources:
  - https://github.com/github/spec-kit
  - https://github.com/cameronsjo/spec-compare
  - https://kiro.dev/docs/specs/feature-specs/
  - https://github.com/Priivacy-ai/spec-kitty
  - https://www.infoworld.com/article/4171332/4-cutting-edge-tools-for-spec-driven-development.html
  - https://daily.dev/posts/understanding-spec-driven-development-kiro-spec-kit-and-tessl-wbu9w3aj6
  - https://www.augmentcode.com/tools/best-spec-driven-development-tools
  - https://www.augmentcode.com/tools/kiro-vs-antigravity
  - https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
  - https://github.com/bmad-code-org/BMAD-METHOD
  - raw/2026-06-25-ssd01-02-research-report.md
  - raw/2026-06-25-ssd01-03-research-report.md
  - raw/2026-06-25-ssd01-04-research-report.md
---

# Spec-Driven Development Tools

> [!summary]
> The 2026 [[spec-driven-development|spec-driven development]] tool landscape sorts into three bands by how much authority the spec holds over the code: **spec-first** tools that scaffold then discard (GitHub Spec Kit, Kiro, BMad), **spec-anchored** tools that keep the spec living (OpenSpec, Spec Kitty), and **spec-as-source** platforms that regenerate code from the spec (Tessl). The right choice turns on three axes: greenfield vs. brownfield, whether you need parallel multi-agent work, and how much sync discipline your team will sustain.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

These are the toolkits that operationalize SDD — turning the abstract "spec is the source of truth" principle into concrete files, slash commands, and agent integrations. They differ less in their happy-path workflow (nearly all follow some variant of *requirements → design/plan → tasks → implement*) than in three structural choices: where the spec lives in the maturity ladder, whether they handle *change* to existing specs, and whether they isolate parallel agents with [[git-worktrees-parallel-agents|git worktrees]].

## Why it matters

Tool choice locks in a workflow. A greenfield-optimized tool (Spec Kit) makes brownfield change awkward; a discard-the-spec tool leaves no living documentation; a single-tree tool can't run parallel agents without friction. Picking the wrong band for your work converts SDD's intended speedup into ceremony. Because the field is young and the tools are evolving fast (versions below are point-in-time from the spec-compare research), the durable thing to learn is the *taxonomy*, not the version numbers.

## Key concepts / building blocks

### The maturity bands (and which tool sits where)

| Band | Spec's authority | Tools |
|---|---|---|
| **Spec-First** | Spec precedes code, then discarded | GitHub Spec Kit, Kiro, BMad Method |
| **Spec-Anchored** | Spec persists and evolves with code | OpenSpec, Spec Kitty |
| **Spec-as-Source** | Only the spec is edited; code regenerates | Tessl |

This mirrors the three levels in [[spec-driven-development|SDD]] theory — the same ladder, instantiated in tooling.

### The tools

| Tool | License / backing | Maturity | Differentiator | Worktrees |
|---|---|---|---|---|
| **GitHub Spec Kit** | Open source (GitHub) | Production (v0.8.x) | Reference SDD impl; 7-phase slash commands; 30+ agents | ✗ |
| **Kiro** | Proprietary (AWS) | GA since Nov 2025 (v0.12.x) | Spec-first **agentic IDE**; EARS `requirements.md`/`design.md`/`tasks.md` | ✗ |
| **Spec Kitty** | Open source (Priivacy-ai) | Active (v3.x) | **Built-in worktree orchestration**; Kanban dashboard; sub-agent implement+review | ✓ |
| **OpenSpec** | MIT | Production (v1.x) | **Brownfield delta format** (ADDED/MODIFIED/REMOVED); lightweight | (via OpenCode) |
| **Tessl** | Proprietary | Active | **Spec-as-Source**: edit spec, regenerate code; Framework + Registry | ✗ |
| **BMad Method** | Open source | Stable (v6.x) | Enterprise framework, **~21 specialized agents** | ✗ |

**GitHub Spec Kit** is the canonical open-source implementation, open-sourced 2 September 2025 (Den Delimarsky / from John Lam's research) under MIT, and the breakout success of the category — roughly 110K GitHub stars by mid-2026 (up ~40K since February). Its seven phases — `constitution → specify → clarify → plan → tasks → analyze → implement` — are exposed as `/speckit.*` slash commands and run across 30+ agents (Claude Code, Copilot, Cursor, Gemini CLI, Codex, Windsurf, Zed). Artifacts are durable files: `.specify/memory/constitution.md`, `specs/<feature>/spec.md`, `plan.md`, `tasks.md`. The v0.10 line replaced `--ai` flags with an `--integration` system plus extensions/presets and an agent-skills install mode. GitHub explicitly frames it as "an experiment designed to test how well the methodologies behind SDD actually work," not a finished product. Battle-tested on greenfield; `/speckit.clarify` is a workaround for small changes, and there is no worktree support.

**Kiro** (AWS) is the spec-first idea delivered as a full agentic IDE (a Code OSS / VS Code fork) — public preview July 2025, GA 17 November 2025, and positioned as the successor to Amazon Q Developer. It reportedly reached 250,000+ developers in its first three months. Each feature is the [[ears-notation|EARS]]-based triple `requirements.md` / `design.md` / `tasks.md`, plus "steering" files (product/tech/structure) and event-triggered hooks. Its distinctive capability is **formal requirements analysis** — using SMT (satisfiability-modulo-theories) solvers to detect specification contradictions before coding — alongside property-based testing that verifies code against spec *invariants*, not just examples. AWS cites enterprise wins at Delta Air Lines and Rackspace. Weaknesses: static specs that don't auto-update with code, tight AWS lock-in, and an early pricing rollout that drew criticism. Like Spec Kit it lacks worktrees and is inefficient for tiny edits.

**Spec Kitty** (Priivacy-ai) is the parallel-work specialist: it pioneered automatic per-feature [[git-worktrees-parallel-agents|git worktree]] creation, parallel isolation, and cleanup, paired with a local Kanban dashboard, a mission system, governance commands (`spec-kitty dispatch`), and auto-merge — all as an open-source Python CLI, no SaaS subscription. Its 0.14 line popularized a pattern where Claude Code writes the spec, plans, designs tasks, then launches **sub-agents** to implement and review each task.

**OpenSpec** (Fission-AI) is the brownfield answer: lightweight, tool-agnostic (works with 20+ assistants via slash commands, no API keys or MCP required, "no Python, 5-minute setup"), and on the Thoughtworks Technology Radar. Its **delta format** (`ADDED` / `MODIFIED` / `REMOVED`) expresses *change* against a single source-of-truth spec rather than restating it, directly attacking SDD's hardest problem. Artifacts: `proposal.md`, `specs/`, `design.md`, `tasks.md`. It pairs with OpenCode and git worktrees for [[git-worktrees-parallel-agents|parallel agents]].

**Tessl** is the commercial bet on full **spec-as-source**, founded by Guy Podjarny (ex-Snyk founder) and funded with $125M before shipping a product. Specs are `.spec.md` files with YAML frontmatter; generated code can carry a `// GENERATED FROM SPEC - DO NOT EDIT` marker with 1:1 spec-to-file mapping. It is now public as the Tessl Framework + Spec Registry, with MCP integration. Highest ambition, highest barrier to entry — and the clearest test of whether spec-as-source generalizes beyond safety-critical embedded work.

**BMad Method** (Breakthrough Method for Agile AI-Driven Development) is the enterprise heavyweight — an MIT-licensed multi-agent framework (~50K GitHub stars, v6.x) that uses specialized **agent personas** (Analyst, PM, Architect, Developer, QA) handing off artifacts (brief → PRD → architecture → sharded story files), mirroring an agile team. Installs via `npx bmad-method install`. Powerful for large, traceable efforts, but, as the comparison literature dryly notes, "a sledgehammer to crack a nut" for trivial changes.

### Adjacent tooling: ADEs and parallel runners

The lines blur with **agentic IDEs / ADEs** (agentic development environments). Google's **Antigravity** (a free ADE) and **Warp** (a terminal-based ADE) compete with Kiro on developer experience rather than on a formal spec workflow. Separately, parallel-agent runners like **Conductor** (macOS) and skills frameworks like **Superpowers** automate [[git-worktrees-parallel-agents|git worktrees]] without being full SDD tools.

Two more adjacent layers matter. **Org-scale platforms** — Augment Code's **Cosmos** (a cloud Context Engine maintaining living specs and architectural memory across hundreds of microservices / 400K+ files, with OS-level cgroup isolation between agents) and **Zenflow/Zencoder** (massively parallel workflows with cross-agent verification gates) — push SDD from the local workspace toward fleet scale. And beneath all of these sits the **context-file standard**: `CLAUDE.md` (Anthropic) and the cross-tool `AGENTS.md` convention (donated to the Linux Foundation's Agentic AI Foundation in late 2025, alongside MCP), plus Anthropic's composable **Agent Skills**. These hold the durable, cross-session project context (stack, conventions, guardrails) that specs reference but don't duplicate; Spec Kit's skills-mode aligns with this substrate. Thoughtworks' own **SPDD** (Structured Prompt-Driven Development) is a related variant that versions the *prompts* themselves as first-class artifacts.

## Design decisions & trade-offs

**Greenfield vs. brownfield is the first fork.** Spec Kit, Kiro, and BMad shine on 0-to-1 work; OpenSpec is purpose-built for modifying existing systems. Using a greenfield tool on a mature codebase forces the awkward "re-specify the whole thing to change one behavior" anti-pattern — the modification problem in practice.

**Open source vs. proprietary.** Spec Kit, Spec Kitty, OpenSpec, and BMad are open and agent-agnostic; Kiro and Tessl are proprietary and more integrated. Open tools avoid lock-in and run across your existing agents; proprietary tools trade that for a smoother, opinionated experience.

**Worktree support gates parallelism.** If you intend to run multiple [[multi-agent-orchestration|agents]] concurrently on different features, the absence of worktree orchestration (Spec Kit, Kiro, BMad, Tessl) is real friction — you bolt it on manually or pick Spec Kitty / OpenSpec+OpenCode. See [[git-worktrees-parallel-agents]].

**Ambition vs. adoptability.** Spec-as-source (Tessl) is the most powerful model but demands trust that regenerated code is never hand-edited — a large cultural leap. Spec-first (Spec Kit) is trivially adoptable but lets specs rot. Spec-anchored is the pragmatic middle most teams can actually sustain.

## State of the art

The selection guidance from the [[spec-driven-development|spec-compare]] research, current as of mid-2026:

| Your situation | Pick | Why |
|---|---|---|
| Greenfield, 0-to-1 | **Spec Kit** | Production-ready, constitution-driven, agent-agnostic |
| Brownfield, small iterative changes | **OpenSpec** | Delta format, lightweight |
| Parallel feature development | **Spec Kitty** | Most complete built-in worktree management |
| Enterprise, heavyweight workflows | **BMad Method** | ~21-agent comprehensive coverage |
| Want a polished native IDE | **Kiro** | GA, integrated agentic IDE, EARS specs |
| Spec-as-source regeneration | **Tessl** | Public Framework + Registry |

The trajectory is toward (1) better brownfield/modification support across all tools, (2) worktree-based parallelism becoming table stakes, and (3) convergence of the SDD workflow with agentic IDEs (Kiro, Antigravity, Warp) so the spec lifecycle lives where the developer already works. Reception is not uniformly enthusiastic: Thoughtworks places SDD at "Assess" (not "Adopt") on its Technology Radar, and hands-on reviewers (Scott Logic, Marmelab) report Spec Kit generating overwhelming volumes of markdown for small features — a reminder that tool ceremony is a cost, and the heaviest tool is rarely the right default.

> [!tip]
> Don't start by picking a tool — start by placing your work on the maturity ladder and the greenfield/brownfield/parallel axes. The tool falls out of that. And whatever you pick, the [[ears-notation|EARS]] requirements layer and a living spec matter more than the brand.

## Pitfalls & anti-patterns

- **Tool before taxonomy.** Adopting the trendiest tool without deciding which maturity band fits your team's sync discipline leads to abandoned specs.
- **Greenfield tool on brownfield code.** Re-specifying an entire system to change one behavior; use a delta-based tool (OpenSpec) instead.
- **Heavyweight framework on trivial work.** BMad's 21 agents or full Spec Kit ceremony for a one-line fix is pure overhead.
- **Chasing version numbers.** These tools move weekly; the durable knowledge is the taxonomy and trade-offs, not v0.8.18 vs v0.12.x.
- **Ignoring the worktree question until it hurts.** Discovering mid-adoption that your tool can't run parallel agents forces a painful switch; decide up front. See [[git-worktrees-parallel-agents]].

## See also

- [[spec-driven-development]] — the methodology these tools implement
- [[ears-notation]] — the requirements notation Kiro and others generate
- [[git-worktrees-parallel-agents]] — the parallelism feature that separates Spec Kitty/OpenSpec from the rest
- [[multi-agent-orchestration]] — running implement/review sub-agents per task
- [[vibe-coding-governance]] — the ungoverned alternative these tools discipline
- [[developer-experience]] — SDD tooling as part of the platform DX surface

## Sources

- GitHub (2026). *Spec Kit.* https://github.com/github/spec-kit
- Jo, C. (2026). *spec-compare — Research Comparing 6 Spec-Driven Development Tools.* https://github.com/cameronsjo/spec-compare
- Kiro (2026). *Feature Specs.* https://kiro.dev/docs/specs/feature-specs/
- Priivacy-ai (2026). *Spec Kitty.* https://github.com/Priivacy-ai/spec-kitty
- InfoWorld (2026). *4 cutting-edge tools for spec-driven development.* https://www.infoworld.com/article/4171332/4-cutting-edge-tools-for-spec-driven-development.html
- daily.dev (2026). *Understanding Spec-Driven Development: Kiro, spec-kit, and Tessl.* https://daily.dev/posts/understanding-spec-driven-development-kiro-spec-kit-and-tessl-wbu9w3aj6
- Augment Code (2026). *6 Best Spec-Driven Development Tools for AI Coding in 2026* / *Kiro vs Antigravity.* https://www.augmentcode.com/tools/best-spec-driven-development-tools · https://www.augmentcode.com/tools/kiro-vs-antigravity
- Böckeler, B. (2025). *Understanding Spec-Driven Development: Kiro, spec-kit, and Tessl.* martinfowler.com. https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html
- Research syntheses (ingested 2026-06-25): [[2026-06-25-ssd01-02-research-report]], [[2026-06-25-ssd01-03-research-report]], [[2026-06-25-ssd01-04-research-report]]
