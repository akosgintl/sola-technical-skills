---
title: Tracer Bullets & Vertical Slices
aliases: [tracer bullets, vertical slice, vertical slices, walking skeleton, horizontal slicing, tracer code]
type: concept
domain: meta
status: draft
tags: [meta, software-design, feedback-loops, ai-coding, task-decomposition, pragmatic-programmer]
updated: 2026-06-30
sources:
  - raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
  - raw/2026-06-30-pocock-01-software-fundamentals-keynote.md
  - "https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/"
---

# Tracer Bullets & Vertical Slices

> [!summary]
> A **tracer bullet** (Hunt & Thomas, *The Pragmatic Programmer*) is a thin, end-to-end slice of a
> system that touches every layer — UI, API, service, database — and actually runs, so you get
> *visible feedback* on whether the layers fit together long before any one layer is complete. The
> opposite is **horizontal slicing**: build all of the database, then all of the API, then all of
> the UI, and only discover at the end whether it integrates. For AI agents the distinction is
> decisive: left to themselves agents code horizontally, deferring feedback to the last phase and
> coding "blind" until then. Decomposing work into **vertical slices** is how you keep an agent in
> a fast feedback loop — and the rate of feedback is the agent's speed limit.

**Domain:** [[meta-skills|Cross-cutting meta-skills]]

## What it is

Systems have layers — deployable units (database, API, front end on a CDN) and, within them,
internal layers (a stack of services with dependencies on each other). There are two ways to cut
work across those layers:

- **Horizontal slice** — one layer at a time. Phase 1: the whole schema. Phase 2: the whole API.
  Phase 3: the whole UI. Nothing is *integrated* — and therefore nothing is testable end-to-end —
  until the last phase.
- **Vertical slice** — one thin thread of functionality through *all* the layers at once. "Award
  points for lesson completion, visible on the dashboard" carries a schema change, a new service
  method, and a minimal UI, all wired together. It does little, but it does it end-to-end and it
  *runs*.

The name comes from gunnery: tracer rounds carry a phosphor charge that glows in flight, so the
gunner sees a line in the sky and corrects aim in real time instead of firing blind. Tracer code
does the same for development — a working thread that lets you see where you're aiming and adjust.
The related term **walking skeleton** describes the first such slice: the smallest end-to-end
implementation that exercises the architecture's main components.

Tracer bullets are *not* prototypes. A [[ai-assisted-development-workflow|prototype]] is throwaway
code that answers a question and is discarded; a tracer bullet is real, production-bound code that
you keep and flesh out. Both exist to pull feedback earlier, but one is scaffolding and the other
is the first beam of the actual building.

## Why it matters

- **Feedback is the speed limit.** *The Pragmatic Programmer*'s "don't outrun your headlights":
  the rate at which you get feedback bounds the rate at which you can safely move. Horizontal
  slicing starves you of feedback until phase three; a vertical slice delivers it in phase one.
  This is doubly true for agents, whose output quality is capped by the quality and timeliness of
  their feedback loops (see [[deep-modules]], [[ai-assisted-development-workflow]]).
- **Agents code horizontally by default.** Given a big tranche of work, an agent will build the
  whole database layer, then the whole schema, then the API, then the front end — the human
  instinct to "get something small working and expand from there" is exactly what it lacks. Without
  intervention it codes blind, and integration failures surface only at the end when they are
  expensive to unwind.
- **Vertical slices are the unit of an AI backlog.** When a [[ai-assisted-development-workflow|PRD]]
  is broken into a Kanban board of issues, slicing them vertically is what makes each issue both
  *demonstrable* (it produces something visible to QA) and *independently grabbable* (it can be
  handed to a parallel agent). Horizontal issues are mutually blocking and yield nothing testable
  until combined.
- **It pairs with leading words.** "Vertical slice" is a high-density [[agent-skill-design|leading
  word]]: a well-known term that triggers the model's prior. Putting it in a skill and watching the
  reasoning traces echo "we'll do this as a thin vertical slice" is a reliable way to confirm the
  steer landed.

## Key concepts / building blocks

### The slice must be thin *and* complete

A good vertical slice is narrow in scope but full in depth: it may implement only one user story,
but that story reaches from the data model to something a person can see and click. Thinness keeps
it inside the agent's [[context-engineering|smart zone]]; completeness is what produces feedback.

### Detecting a horizontal slice masquerading as vertical

Even when told to slice vertically, an agent will often propose "create the gamification service"
as the first task — a single-layer chunk. The tell: the slice produces *nothing visible* and
exercises *no integration*. The correction is to demand that the first slice include some schema
change, some new service logic, *and* a minimal front-end representation — proof the thread runs
all the way through.

### Slices as a directed acyclic graph

Vertical slices have blocking relationships (slice B needs slice A's table) but are otherwise
independent, forming a DAG. That structure is what enables [[git-worktrees-parallel-agents|parallel
agents]]: slices with no path between them can be grabbed simultaneously, while a numbered,
sequential phase plan can only be worked by one loop.

### Definition of done per slice

Because each slice runs end-to-end, it has a concrete, demonstrable "done" — something QA can
exercise immediately. This is what lets the human re-enter the loop to impose taste at the slice
boundary rather than waiting for a big-bang integration.

## Design decisions & trade-offs

- **Vertical slicing has overhead.** Each slice re-touches every layer, so there is more
  context-switching than building one layer straight through. The payoff — early, continuous
  feedback — almost always dominates for non-trivial work, but for a genuinely single-layer change
  (a pure schema migration, a CSS-only tweak) a "horizontal" task is honest, not a smell.
- **Slice granularity vs. the smart zone.** Slices must be small enough that an agent implements
  one without drifting into the [[context-engineering|dumb zone]], yet large enough to cross all
  layers and produce something demonstrable. Too thin and the per-slice ceremony dominates; too
  thick and feedback is deferred again.
- **Who slices — human or agent.** Decomposing the PRD into vertical slices is cheap and high-
  leverage for the human to review even when an agent drafts it, because a mis-sliced backlog
  (horizontal, or wrongly ordered) poisons every downstream implementation run.
- **Tracer bullet vs. prototype vs. spike.** Choose by what you're de-risking: a *tracer bullet*
  when the architecture/integration is the risk (keep the code); a *prototype* when the UX or shape
  is the risk (throw it away); a *spike* when a specific technical unknown is the risk (timeboxed
  research).

## State of the art

Tracer bullets and walking skeletons are decades old, but AI-assisted development has made them
operationally central rather than stylistic. The reasoning is concrete: an agent's quality is
bounded by its feedback loops, and only an end-to-end slice produces real feedback (passing tests,
a working screen, a green type-check) rather than the illusion of progress from a half-built layer.
The 2026 practice — visible in Pocock's grill→PRD→Kanban→AFK workflow and in
[[spec-driven-development|spec-driven]] toolchains — is to require that PRD-to-issue decomposition
emit *vertical, traceable* slices, and to use the term itself as a steering [[agent-skill-design|leading
word]] inside the decomposition skill. The slices then double as the nodes of the parallelizable
DAG that [[git-worktrees-parallel-agents|worktree fan-out]] executes.

## Pitfalls & anti-patterns

- **Horizontal phasing by habit.** "Phase 1: all the data layer; Phase 2: all the API…" — feedback
  arrives only after the last phase, when integration bugs are most expensive.
- **A first slice that shows nothing.** "Create the service" as slice one: single-layer, no visible
  output, no integration exercised — a horizontal slice with a vertical label.
- **Slices too big for the smart zone.** A "vertical" slice that carries half the feature drags the
  agent into the dumb zone and defeats the point.
- **Confusing a tracer bullet with a prototype.** Keeping throwaway prototype code as if it were a
  tracer (it rots), or throwing away tracer code as if it were a prototype (you rebuild the thread).
- **Parallelizing coupled slices.** Fanning out slices that actually share files just relocates the
  conflict to merge time; only genuinely independent DAG nodes parallelize cleanly.

## See also

- [[ai-assisted-development-workflow]]
- [[deep-modules]]
- [[git-worktrees-parallel-agents]]
- [[agent-skill-design]]
- [[context-engineering]]
- [[spec-driven-development]]
- [[delegate-review-own]]

## Sources

- Hunt, A., & Thomas, D. — *The Pragmatic Programmer* (20th Anniversary Edition), "Tracer Bullets". https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/
- Pocock, M. — *Full Walkthrough: Workflow for AI Coding* (workshop). raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
- Pocock, M. — *Software Fundamentals Matter More Than Ever* (keynote). raw/2026-06-30-pocock-01-software-fundamentals-keynote.md
