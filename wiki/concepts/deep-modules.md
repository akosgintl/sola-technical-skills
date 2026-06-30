---
title: Deep Modules
aliases: [deep modules, shallow modules, module depth, design the interface delegate the implementation, gray box modules, A Philosophy of Software Design]
type: concept
domain: meta
status: draft
tags: [meta, software-design, modularity, testability, ai-coding, ousterhout]
updated: 2026-06-30
sources:
  - raw/2026-06-30-pocock-01-software-fundamentals-keynote.md
  - raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
  - "https://web.stanford.edu/~ouster/cgi-bin/aposd.php"
---

# Deep Modules

> [!summary]
> A **deep module** hides a lot of functionality behind a small, simple interface; a **shallow
> module** exposes a complex interface for little functionality. The distinction comes from John
> Ousterhout's *A Philosophy of Software Design*, and it is the single most useful lens for
> structuring a codebase that both humans and AI agents can navigate, test, and change safely. In
> the AI age it acquires a second payoff: a deep module is a **testable boundary** (one big test
> at the interface beats many brittle tests around tiny functions) and a **gray box** you can
> reason about from the outside — letting you *design the interface and delegate the
> implementation* to an agent without having to review every line inside.

**Domain:** [[meta-skills|Cross-cutting meta-skills]]

## What it is

Ousterhout defines a module's **depth** as the ratio of the functionality it provides to the
complexity of its interface. The interface is the cost a caller pays to use the module — every
method, parameter, and concept they must understand. The functionality is the benefit. A good
module maximizes benefit per unit of cost: **deep**.

- **Deep module** — simple interface, substantial hidden implementation. A caller learns a few
  concepts and gets a lot of behavior. Unix file I/O (`open`/`read`/`write`/`close`) is the
  canonical example: five calls hide buffering, permissions, device drivers, and on-disk layout.
- **Shallow module** — the interface is nearly as complex as the implementation. A pass-through
  method that adds a parameter and forwards the call is the limit case: it costs interface
  surface and conceptual load while hiding nothing.

A codebase trends deep or shallow as a whole. A **shallow codebase** is a sprawl of small files
each exporting many functions, with dependencies threaded across the graph — "lots of tiny blobs"
the reader must walk through to understand anything. A **deep codebase** is a smaller number of
larger modules, each wrapping related logic behind a simple interface, with the complexity hidden
*inside* the boundaries.

The classic counsel that pairs with depth is **information hiding**: each module encapsulates a
design decision (a data structure, an algorithm, a protocol) that the rest of the system cannot
see and therefore cannot depend on. Its opposite, **information leakage**, is the root cause of
shallowness — when a decision is smeared across many modules, changing it means changing all of
them.

## Why it matters

- **Complexity is what makes a system hard to change.** Ousterhout's definition: complexity is
  anything about a system's structure that makes it hard to understand and modify. Depth is the
  primary tool for fighting it — pushing complexity *down* into modules and out of the interfaces
  callers see. A codebase that is easy to change is the precondition for getting value out of AI;
  see [[vibe-coding-governance]] and [[systems-thinking-over-syntax]].
- **Shallow codebases defeat AI navigation.** An agent exploring a shallow codebase has to trace a
  large dependency graph of small units to understand what anything does — and frequently fails to
  reach the right module or grasp all the dependencies before it acts. AI is, left unaided,
  *good at generating* exactly this shallow sprawl, which then traps the next agent. Depth is what
  keeps a codebase legible to the model that has to work in it.
- **Deep modules are testable boundaries.** Where you draw test boundaries is the hardest testing
  decision (see below). A deep module answers it: wrap one big test boundary around the module's
  simple interface and you exercise a lot of real behavior with a stable, low-maintenance test.
  Shallow modules force a bad choice — a brittle test around every tiny function (which misses how
  they compose), or a sprawling test across many modules (which is flaky and needs heavy mocking).
- **Deep modules become gray boxes that save the human's attention.** Because the interface is
  simple and the behavior is verifiable from outside, you can treat the module's internals as a
  *gray box*: know its purpose and contract, design its interface deliberately, and **delegate the
  implementation** to an agent without reviewing every line. This is how teams ship more without
  the human's mental model collapsing — the antidote to "I can produce more code than ever but my
  brain can't keep up." Reserve full internal review for the modules where it matters (finance,
  security); let the testable boundary cover the rest. See [[delegate-review-own]].

## Key concepts / building blocks

### Depth = functionality ÷ interface complexity

The metric to optimize. Adding a feature should, ideally, add functionality without enlarging the
interface. Adding an interface concept without adding functionality (a configuration flag nobody
needs, a pass-through wrapper) makes the module shallower.

### Information hiding vs. leakage

Each module should encapsulate one or more design decisions invisible to its callers. When the
same decision (a date format, a wire protocol, a schema assumption) appears in several modules,
that is leakage — and the signal that a deeper module wants to be extracted to own that decision.

### The test-boundary problem

Testing is hard mostly because of *interdependent decisions*: how big a unit to test, what to
mock, which behaviors to cover. These cannot be chosen independently — a large unit is flakier and
warrants fewer behaviors; testing one unit means mocking its neighbors. A deep-module structure
collapses the decision: the module's interface *is* the natural test boundary, large enough to be
meaningful and simple enough to be stable. **Good codebases are easy to test, and a testable
codebase is one a feedback-driven agent thrives in** — feedback-loop quality is the ceiling on AI
output quality (see [[tracer-bullets]] and [[ai-assisted-development-workflow]]).

### Design the interface, delegate the implementation

The operating procedure that falls out of treating modules as gray boxes:

1. **You** own and carefully design the *interfaces* — they are where an agent most easily corrupts
   the design, and they are the part you must keep in your head.
2. **The agent** owns the *implementation* behind the interface, verified through tests at the
   boundary.
3. Keep the **module map** of the application part of your working memory — name the modules in the
   [[domain-driven-design|ubiquitous language]], in planning docs ([[ai-assisted-development-workflow|PRDs]]),
   and during implementation. Kent Beck's maxim applies: *invest in the design of the system every
   day.*

### Deepening an existing codebase

Turning a shallow codebase deep is a repeatable refactor, not a rewrite: scan for clusters of
related code threaded across small modules, and wrap each cluster behind one simple interface that
becomes a testable boundary. Pocock packages this as an *improve codebase architecture* skill; the
move is the same one Ousterhout describes — consolidate leaked decisions into a single deep module.

## Design decisions & trade-offs

- **Fewer, larger modules vs. many small ones.** The industry reflex (and many linters) push toward
  small files and short functions, which can manufacture shallowness. Depth argues for *fewer,
  deeper* modules. The judgment call is granularity: deep enough to hide a real design decision,
  not so deep it becomes a god-module with several unrelated responsibilities.
- **Interface scrutiny vs. implementation trust.** Spend your review budget on interfaces (hard to
  change, widely depended-on, easy for an agent to get subtly wrong) and economize on
  implementations behind a tested boundary. Invert this only where the internals carry
  irreducible risk.
- **Test boundary size.** Bigger boundaries catch integration bugs and resist refactor churn but
  localize failures less precisely; tiny boundaries pinpoint failures but miss composition bugs and
  ossify the internal structure. Depth pushes you toward the larger, interface-aligned boundary.
- **Relationship to bounded contexts.** Deep modules are the in-the-small version of the same
  instinct that [[domain-driven-design|bounded contexts]] apply in-the-large: put boundaries where
  they hide a coherent decision and minimize what crosses them.

## State of the art

Ousterhout's *A Philosophy of Software Design* (2018; 2nd ed. 2021) has become a touchstone in the
AI-coding discourse precisely because its vocabulary — depth, complexity, information hiding — is
*English a model can be steered with*. Practitioners (Matt Pocock among them) report that feeding
these decades-old design principles into prompts and skills measurably improves both the plans an
agent makes and the code it writes, because the principles translate directly into
[[agent-skill-design|leading words]] ("deep module", "simple interface", "testable boundary") that
show up in the model's reasoning traces and change its behavior. The pattern of *interface-first,
delegate-the-inside* has become a default for keeping large AI-generated codebases coherent and for
preserving the human's sense of a codebase they are no longer typing line by line.

## Pitfalls & anti-patterns

- **Shallow-module sprawl.** Many tiny files each exporting many functions, dependencies everywhere
  — the structure unaided AI tends to produce and then cannot navigate.
- **Pass-through / wrapper modules.** A layer that adds an argument and forwards the call: pure
  interface cost, zero hidden functionality.
- **Information leakage.** The same design decision (a format, a protocol, a schema) duplicated
  across modules, so a change touches all of them. The cue to extract a deep module.
- **Per-function test boundaries.** Wrapping every small function in its own test and mocking its
  neighbors — brittle, misses composition bugs, and ossifies a shallow structure instead of fixing
  it.
- **Reviewing implementations, rubber-stamping interfaces.** The exact inversion of where attention
  pays off — interfaces are where design erodes and where agents err.
- **Letting the agent own the module map.** Delegating the *shape* of the codebase (not just the
  code) means losing the sense of it; you can no longer improve what you no longer understand.

## See also

- [[ai-assisted-development-workflow]]
- [[tracer-bullets]]
- [[delegate-review-own]]
- [[domain-driven-design]]
- [[systems-thinking-over-syntax]]
- [[vibe-coding-governance]]
- [[service-decomposition]]
- [[agent-skill-design]]

## Sources

- Ousterhout, J. — *A Philosophy of Software Design* (2nd ed., 2021). https://web.stanford.edu/~ouster/cgi-bin/aposd.php
- Pocock, M. — *Software Fundamentals Matter More Than Ever* (keynote). raw/2026-06-30-pocock-01-software-fundamentals-keynote.md
- Pocock, M. — *Full Walkthrough: Workflow for AI Coding* (workshop). raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
