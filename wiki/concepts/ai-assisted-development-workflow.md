---
title: AI-Assisted Development Workflow
aliases: [AI coding workflow, grill to PRD to kanban, AFK agents, Ralph loop, day shift night shift, away from keyboard agents, human-in-the-loop vs AFK]
type: concept
domain: ai-agentic
status: draft
tags: [ai-agentic, ai-coding, workflow, agentic-loop, planning, code-review, tdd]
updated: 2026-06-30
sources:
  - raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
  - raw/2026-06-30-pocock-01-software-fundamentals-keynote.md
  - raw/2026-06-30-pocock-03-building-great-agent-skills.md
---

# AI-Assisted Development Workflow

> [!summary]
> A repeatable pipeline for building software *with* coding agents that keeps the human on the
> strategic layer and the agent on the tactical one: **align** (grill the human to a shared
> understanding) → **specify** (write a PRD as the destination) → **decompose** (split it into a
> Kanban DAG of vertical-slice issues) → **implement AFK** (a Ralph-style loop runs the backlog
> away-from-keyboard) → **QA & review** (in a fresh context, where taste is imposed and new issues
> are filed). The design is governed by two LLM constraints — a [[context-engineering|smart
> zone/dumb zone]] and Memento-like forgetting — and by a thesis that runs through all of it: this
> is *not* specs-to-code that ignores the code. The codebase stays the battleground; software
> fundamentals ([[deep-modules|deep modules]], [[tracer-bullets|vertical slices]], TDD) are what
> make the loop produce good output instead of compounding slop.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

An end-to-end operating procedure for agentic coding, distilled from Matt Pocock's workshop and
keynote. It separates work into a **human-in-the-loop** front half (alignment, specification,
decomposition — the "day shift") and an **AFK** ("away from keyboard") back half (implementation —
the "night shift"), with QA and review closing the loop. Each stage is a small, named
[[agent-skill-design|skill]], and each is sized to stay inside the agent's smart zone.

The whole thing is built around two hard constraints of LLMs:

- **The smart zone / dumb zone.** As a context window fills, quality degrades (attention scales
  quadratically with tokens). Pocock's working marker is ~100K tokens regardless of the advertised
  window — bigger windows mostly "ship more dumb zone," better for retrieval than for coding. So
  every task is *sized to fit the smart zone.* (See [[context-engineering]].)
- **Memento-like forgetting.** An agent resets to the same clean state every time you clear context.
  Pocock prefers **clearing over compacting**: a cleared context is always identical and optimizable,
  whereas compaction accumulates sediment. This is why each stage starts fresh rather than carrying a
  bloated history forward.

## Why it matters

- **It replaces the failing "specs-to-code" loop.** Writing a spec, generating code, and then only
  ever editing the spec (never the code) produces *worse* code each pass — software entropy by
  another name. Keeping the code in view at every stage, and investing in its design, is what lets AI
  compound value instead of degrading. See [[vibe-coding-governance]] and [[spec-driven-development]].
- **It puts the human where humans are irreplaceable.** Alignment and QA — the points where taste,
  domain knowledge, and strategic judgment matter — stay human (and often *multi*-human). Everything
  mechanizable is mechanized. Fully automating idea/QA/research yields tasteless slop.
- **It scales by parallelism, not by bigger contexts.** Because the backlog is a DAG of independent
  vertical slices, multiple agents can work it at once via [[git-worktrees-parallel-agents|worktree
  isolation]] — throughput grows by fanning out, not by stuffing more into one window.

## Key concepts / building blocks

### Stage 1 — Align (grill to a shared design concept)

Start not by asking for a plan but by being *interviewed*. A **grill** skill ("interview me
relentlessly about every aspect of this plan until we reach a shared understanding; walk each branch
of the decision tree, resolving dependencies one by one; recommend an answer to each question")
turns the agent into an adversary that asks 40–100 questions. The goal is Frederick Brooks' **design
concept** (*The Design of Design*) — the shared, partly tacit idea of what you're building — *not* an
asset. This is deliberately preferred over default plan mode, which is too eager to skip alignment
and emit a plan (a [[agent-skill-design|leg-work]] failure). Inputs from the world (a client brief, a
meeting transcript) are fed *into* the grilling session to validate assumptions. The output is a rich
conversation history — the raw material for the next stage.

### Stage 2 — Specify (write the PRD as a destination document)

Summarize the alignment into a **product requirements document**: problem statement, solution, user
stories, explicit implementation and **testing decisions**, and an **out-of-scope** section that
captures negative decisions and the definition of done. Its exact shape doesn't matter much; it is
the *destination*. Notably, Pocock does **not** read the PRD back — because, having reached a shared
design concept in stage 1, he is only checking the model's (reliable) summarization, not its
judgment. The PRD also begins naming the **modules** to be created or modified, keeping the
[[deep-modules|module map]] in view from the start.

### Stage 3 — Decompose (PRD → Kanban DAG of vertical slices)

Break the PRD into independently grabbable issues, written as **[[tracer-bullets|vertical slices]]**
(tracer bullets), each with blocking relationships to the others — a Kanban board that is really a
**directed acyclic graph**. This is reviewed cheaply by the human: a mis-sliced backlog (horizontal,
or wrongly ordered) poisons everything downstream, and the agent's first cut is often too horizontal
("create the service" with nothing visible). The DAG is what makes parallel execution possible — a
plain numbered phase plan is a single loop only one agent can run.

### Stage 4 — Implement AFK (the Ralph loop)

Now the human leaves the loop. A **Ralph (Ralph Wiggum) loop** specifies the destination and then
repeatedly makes a small change toward it. The minimal form (`once.sh`) cats all issue markdown plus
the last few commits plus a prompt into the agent with edits auto-accepted; the AFK form wraps it in
a loop inside a Docker sandbox. The implement prompt: work AFK on AFK-tagged issues only; pick the
next task by priority (critical bugs → infra → tracer bullets → polish); explore the repo; use
**TDD** to complete it; run the feedback loops. Run the *once* version by hand repeatedly first to
tune the prompt before letting it loop.

### Stage 5 — QA & review (in a fresh, smart-zone context)

- **Review in the smart zone.** Clear context before the automated review step, so the reviewer
  reasons in the smart zone rather than the dumb zone that produced the code. Pocock implements with
  a cheaper model and reviews with a stronger one.
- **Push vs. pull for standards.** Let the *implementer* **pull** coding standards (skills it may
  read if it has a question); **push** the standards to the *reviewer* so it has both the code and
  the rules to compare. See [[delegate-review-own]].
- **Human QA imposes taste.** The human exercises the running feature, catching what tests don't
  (e.g. a missing migration). QA is also where *new* issues are filed back onto the Kanban board — the
  loop's feedback into itself.

### Feedback loops are the ceiling

Across every stage, the quality of the feedback loops (types, tests, browser access) caps the quality
of AI output — "the rate of feedback is your speed limit." A codebase without good feedback loops
can't be coded well by AI; improving the loops (and the [[deep-modules|testable boundaries]] they
depend on) raises the ceiling.

### Day shift / night shift

A useful mental model: the human's **day shift** front-loads all the planning, queuing a large
backlog; the agent's **night shift** works it AFK. The planning effort buys hours of unattended
implementation.

## Design decisions & trade-offs

- **Own your stack vs. adopt a framework.** Pocock deliberately hand-rolls thin skills rather than
  adopting Spec Kit / OpenSpec / Taskmaster, citing **inversion of control**: while there's no clear
  winner and things change fast, owning the planning stack means you can observe and fix it when it
  breaks. The cost is building and maintaining it yourself. (Contrast [[spec-driven-development-tools]].)
- **Clear vs. compact.** Clearing gives a reproducible clean state but discards everything; compaction
  retains a lossy summary but accumulates sediment and behaves non-deterministically. Pocock favors
  clearing and re-grounding from durable artifacts (issues, commits).
- **Don't over-optimize the PRD.** Polishing the plan has diminishing returns; the leverage is in the
  *alignment* (stage 1) and the *QA* (stage 5), not in a perfect destination document.
- **Keep or discard planning docs? (doc rot.)** Pocock discards PRDs/issues after completion (closing
  GitHub issues) rather than letting markdown drift from the evolved code and mislead future agents.
  Database migrations are the counter-case — a deterministic running record worth keeping. The
  trade-off is provenance vs. doc rot; choose per artifact.
- **Human-in-the-loop vs. AFK per task.** Tag each task. Alignment and the genuinely judgment-heavy
  calls are human-in-the-loop (and benefit from *more* humans, mob-style); implementation is AFK.
  Mis-tagging a judgment task as AFK is how slop gets shipped.
- **Sequential vs. parallel implementation.** A sequential Ralph loop is simplest to get working and
  observe; the DAG enables parallel agents (Pocock's *Sandcastle* runs planner → per-issue
  implementer sandboxes → reviewer → merger across worktrees). Parallelism multiplies throughput and
  merge/review surface together — see [[git-worktrees-parallel-agents]].

## State of the art

By 2026 the agentic-coding community has largely converged on a plan-heavy, implement-AFK shape:
align → specify → decompose → loop → review, with parallel agents in isolated worktrees as the
throughput lever. Tooling spans owned thin-skill stacks (Pocock's `mattpococks-skills`, *Sandcastle*),
[[spec-driven-development-tools|SDD toolchains]] (Spec Kit, OpenSpec, Spec Kitty), and Kanban/issue
frameworks (BEADS). The unresolved frontiers are the same ones practitioners flag live: **code-review
volume** scales with agent output and nobody has a clean answer beyond "expect to review more";
**front-end work** resists the loop because it's multimodal and needs human eyes (mitigated by
throwaway prototypes fed back into grilling); and **merge-conflict resolution** when
parallel agents touch overlapping code. The durable lesson cutting across all of it: agentic coding
rewards the decades-old software fundamentals — clear feedback loops, deep modules, vertical slices,
TDD, and a human investing in the design every day.

## Pitfalls & anti-patterns

- **Specs-to-code that ignores the code.** Re-running the compiler on an edited spec and never
  looking at the output — compounds entropy into slop.
- **Skipping alignment for an eager plan.** Letting the agent jump to a plan asset before a shared
  design concept exists (the plan-mode leg-work failure).
- **Reviewing in the dumb zone.** Running the review in the same bloated context that wrote the code,
  so the reviewer is dumber than the implementer. Clear first.
- **Horizontal decomposition.** A backlog sliced by layer instead of by [[tracer-bullets|vertical
  slice]], deferring all feedback to the end.
- **Over-indexing on the PRD.** Polishing the destination document while under-investing in alignment
  and QA, where the real leverage is.
- **Doc rot.** Keeping stale PRDs/issues that drift from the code and silently misdirect future
  agents.
- **Automating taste away.** Mechanizing QA, idea generation, and prototyping end-to-end and shipping
  tasteless output nobody shaped.
- **Letting tasks outgrow the smart zone.** Not sizing work to the context window, so the agent slides
  into the dumb zone mid-task.

## See also

- [[tracer-bullets]]
- [[deep-modules]]
- [[agent-skill-design]]
- [[context-engineering]]
- [[git-worktrees-parallel-agents]]
- [[delegate-review-own]]
- [[agentic-loop]]
- [[spec-driven-development]]
- [[vibe-coding-governance]]
- [[human-in-the-loop-design]]

## Sources

- Pocock, M. — *Full Walkthrough: Workflow for AI Coding* (workshop). raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
- Pocock, M. — *Software Fundamentals Matter More Than Ever* (keynote). raw/2026-06-30-pocock-01-software-fundamentals-keynote.md
- Pocock, M. — *Building Great Agent Skills: The Missing Manual*. raw/2026-06-30-pocock-03-building-great-agent-skills.md
