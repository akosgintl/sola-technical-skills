---
title: Agent Skill Design
aliases: [agent skills, skill design, writing skills, skill checklist, leading words, context pointer, user-invoked skills, model-invoked skills, SKILL.md]
type: concept
domain: ai-agentic
status: draft
tags: [ai-agentic, agent-skills, prompting, context-engineering, skill-design]
updated: 2026-06-30
sources:
  - raw/2026-06-30-pocock-03-building-great-agent-skills.md
  - raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
  - "https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills"
---

# Agent Skill Design

> [!summary]
> An **agent skill** is a packaged, reusable instruction set — a description plus a `SKILL.md`
> procedure plus optional reference files — that an agent loads on demand to perform a task a
> particular way. As skills proliferate ("skill hell": many freely downloadable skills, no shared
> way to tell good from bad), the scarce thing is a *rubric*. Matt Pocock's checklist supplies one
> along four axes: **trigger** (how the skill is invoked), **structure** (how it's laid out
> internally), **steering** (how it makes the agent actually do the thing), and **pruning** (how to
> keep it as small as possible). The through-line is that a skill is a context-engineering artifact:
> every word costs tokens and attention, so the craft is packing maximum behavioral steer into the
> fewest tokens that load only when needed.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

A skill has three parts: a **description** (a one-line summary), the **`SKILL.md`** (the body — the
"meat"), and any **reference material** bundled alongside it. The description is a *context pointer*:
a small piece of text that sits in the agent's context and points to a larger resource the agent can
pull in if it decides it's relevant. When invoked, the agent reads `SKILL.md` into its context
window and follows it.

This is **progressive disclosure** applied to instructions: don't load the full procedure until it's
needed; keep only a cheap pointer resident, and expand it on demand. Skills are the unit in which
that discipline is packaged and shared — the connective tissue between
[[context-engineering|context engineering]] and the [[agentic-harness|agentic harness]] the skill
runs inside.

## Why it matters

- **Skills are where reusable agent behavior is captured — or where it rots.** A good skill turns a
  team's operating procedure into something an agent reliably executes; a bad one wastes tokens,
  fires at the wrong time, or quietly does nothing. Without a rubric, organizations accumulate
  skills they can't evaluate and don't get the promised leverage.
- **Every skill has a cost, and the cost has two currencies.** A *model-invoked* skill's
  description sits in context on every request — its **context load**. A *user-invoked* skill keeps
  context cheap but pushes **cognitive load** onto the operator, who must remember it exists and
  invoke it. There is no free skill; design is choosing which cost to pay.
- **It is downstream of, and feeds, every other AI-coding practice.** Skills are how
  [[ai-assisted-development-workflow|the grill→PRD→Kanban→AFK workflow]] is operationalized, how
  [[deep-modules|deep-module]] and [[tracer-bullets|vertical-slice]] thinking gets steered into an
  agent, and how [[delegate-review-own|coding standards]] are pushed to a reviewer. The quality of
  the skills is the quality of the system.

## Key concepts / building blocks

### 1 · Trigger — user-invoked vs. model-invoked

Every skill can always be **user-invoked** (the operator names it, e.g. `/skill-name`). A skill can
*additionally* be **model-invoked** if its description is exposed to the agent, which may then decide
to pull it in. Setting `disable model invocation: true` keeps the description visible only to the
user.

| | Model-invoked | User-invoked |
|---|---|---|
| Flexibility | Agent or user can fire it | Only the operator fires it |
| Cost | **Context load** — a description in context every request; 100 skills = 100 descriptions | **Cognitive load** — the operator must know it exists and when to use it |
| Failure mode | **Unpredictability** — the model may decline to invoke even when ideal, forcing evals to verify firing | Reliance on operator skill / "piloting" |

Pocock's skills lean **user-invoked** (full control, no context bloat, no firing evals — at the cost
of operator expertise); the *Superpowers* set leans **model-invoked** (hands the agent the ability,
at the cost of context load and unpredictability). The decision is genuinely two-sided — pick by
whether you value predictability and a lean context, or hands-off flexibility.

### 2 · Structure — steps + reference, kept small

Two internal units compose most skills:

- **Steps** — the step-by-step procedure the skill walks through.
- **Reference** — supporting material the steps consult (a template, a definition, a checklist).

A skill can be all steps, all reference, or both. To write one from scratch: work out the steps,
then work out what reference each step needs, and place that reference in its own spot.

The governing constraint: **keep `SKILL.md` as small as possible.** Smaller skills are easier to
maintain and audit, and every word shaved is a token shaved on every load. The lever for shrinking
is **branches**: if a piece of reference is used by only one of the skill's branches (paths through
it), move it *out* of `SKILL.md` behind a **context pointer** to a separate file — an **external
reference** that loads only when that branch runs. Reference used on *every* branch stays inline.

### 3 · Steering — leading words and leg work

**Leading words** are high-density terms that pack a lot of meaning into a small space ("vertical
slice", "deep module", "tracer bullet"). Put a leading word in the skill and the agent repeats it —
in its thinking tokens and its output — and that re-emphasis changes its behavior, *provided the
word names a concept in the model's prior*. The technique is verifiable: you can watch the reasoning
traces echo the word ("we'll do this as a thin vertical slice"). When an agent isn't doing what you
want, the fix is usually to make the leading words more consistent and more powerful. English is a
wide API; agents are good at helping you find candidate leading words.

**Leg work** is the amount of effort an agent invests in a step. Agents under-invest in a step when
they can see a more attractive later goal — the classic case is plan mode, where "ask clarifying
questions" is skimped because the model is racing toward "create a plan". The fix is to **split** the
work so the agent sees only the current step: make "grill" its own skill, completed before the
"write a PRD" skill ever appears. Hiding the future step is the strongest lever for forcing leg work
on the current one. (Splitting isn't always needed — reserve it for steps that demand an extra chunk
of effort.)

### 4 · Pruning — keep it small

Large skills are a *symptom*. Three failure modes inflate them:

- **Duplication.** The same reference (a template, a definition) repeated in several places. Enforce
  a **single source of truth** per piece, across reference material too.
- **Sediment.** Material accreted over time as many contributors add their own notes and nobody
  feels brave enough to delete others' — leaving stale, often irrelevant content. Fix by
  *structure* first (move single-branch material out, relocate misplaced content) and by *deletion*
  for the genuinely stale.
- **No-ops.** Text that *looks* instructive but doesn't change behavior in the skill's context — e.g.
  a paragraph telling the agent to "write a long detailed commit message" when it already would.
  Find them with the **deletion test**: remove the passage and see whether behavior changes; if not,
  it was a no-op.

### The full sweep

Trigger (is it firing at the right times? context vs. cognitive load) → Structure (branches; steps
and reference; single-branch material out of `SKILL.md`) → Steering (leading words appearing in
traces; enough leg work, or split to force it) → Pruning (sediment, crud, and especially no-ops via
the deletion test).

## Design decisions & trade-offs

- **Context load vs. cognitive load** is the foundational trade and has no universal answer. Favor
  model-invoked when hands-off flexibility matters and the skill set is small; favor user-invoked
  when you want a lean context, predictable firing, and are willing to be an expert operator.
- **Inline vs. external reference.** Inlining everything keeps a skill self-contained but bloats
  every load and couples unrelated branches; externalizing behind context pointers keeps `SKILL.md`
  lean but adds files and one more hop the agent must choose to follow. Split on the branch
  boundary: always-used reference stays in; single-branch reference goes out.
- **Split skills vs. one big skill.** Splitting forces leg work and isolates context per step, but
  multiplies artifacts and invocation overhead. Split where a step is being skimped or needs its own
  isolated context; otherwise keep the procedure together.
- **Leading words vs. spelled-out instructions.** A leading word is dense and self-reinforcing but
  only works if it maps to a real prior the model holds; an obscure or invented term needs the
  spelled-out version. Prefer well-known terminology; coin sparingly and define when you must.
- **Predictability vs. flexibility (the meta-trade).** Model invocation buys flexibility at the cost
  of needing evals to trust that skills fire correctly. Removing model invocation removes that whole
  class of problem — at the cost of leaning on the operator.

## State of the art

Agent skills moved from a Claude/Anthropic feature to a cross-harness pattern through 2025–2026, with
large community skill libraries (Pocock's `mattpococks-skills`, *Superpowers*) and a *writing great
skills* skill that encodes the checklist above so an agent can audit and improve other skills —
including community-authored ones before you trust them. The live debate is exactly the trigger
trade-off: model-invoked "give the agent superpowers" ergonomics versus user-invoked control and
predictability. The deeper trend is treating skills as first-class
[[context-engineering|context-engineering]] artifacts — measured in tokens loaded, evaluated for
firing accuracy, and pruned for no-ops — rather than as prose documentation that happens to live in
the repo.

## Pitfalls & anti-patterns

- **Reflexively making everything model-invoked.** More flexible, but it taxes context on every
  request and introduces firing unpredictability you must then eval away.
- **A bloated `SKILL.md`.** The master failure — usually a symptom of duplication, sediment, or
  no-ops rather than genuinely necessary length.
- **Inlining single-branch reference.** Loading material most invocations never use, on every
  invocation.
- **No-ops.** Instructions that don't move behavior; survive only because nobody ran the deletion
  test.
- **Sediment.** Multi-author accretion nobody prunes; the slow death of a shared skill.
- **Leading words with no prior.** Coining a dense term the model doesn't recognize and expecting the
  steer to land.
- **Skipping leg work by design.** A single skill that shows the agent the final goal up front, so it
  skimps every intermediate step.

## See also

- [[ai-assisted-development-workflow]]
- [[context-engineering]]
- [[agentic-harness]]
- [[deep-modules]]
- [[tracer-bullets]]
- [[delegate-review-own]]
- [[spec-driven-development-tools]]

## Sources

- Pocock, M. — *Building Great Agent Skills: The Missing Manual*. raw/2026-06-30-pocock-03-building-great-agent-skills.md
- Pocock, M. — *Full Walkthrough: Workflow for AI Coding* (workshop). raw/2026-06-30-pocock-02-ai-coding-workflow-walkthrough.md
- Anthropic — *Equipping agents for the real world with Agent Skills*. https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills
