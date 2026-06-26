---
title: Domain-Driven Design
aliases: [DDD, bounded context, bounded contexts, ubiquitous language, strategic design, context mapping, event storming, anticorruption layer]
type: concept
domain: integration
status: mature
tags: [integration, ddd, bounded-context, modeling, microservices, architecture]
updated: 2026-06-26
sources:
  - "https://www.domainlanguage.com/ddd/"
  - "https://learn.microsoft.com/en-us/azure/architecture/microservices/model/domain-analysis"
  - "https://learn.microsoft.com/en-us/azure/architecture/microservices/model/tactical-domain-driven-design"
  - "https://www.eventstorming.com/"
  - "https://www.oreilly.com/library/view/implementing-domain-driven-design/9780133039900/"
---

# Domain-Driven Design

> [!summary]
> Domain-Driven Design (DDD) is the practice of building software whose structure mirrors the
> business domain it serves, by carving a complex domain into **bounded contexts** — boundaries
> within which a single model and a single **ubiquitous language** stay consistent — and mapping
> the relationships between them. It has two halves: **strategic** design (the boundaries, the
> language, the context map) and **tactical** design (aggregates, entities, value objects, domain
> events inside a context). For an architect the strategic half is the high-value part: bounded
> contexts are the *principled seams* along which systems are split into services and modules —
> the answer to "where should the boundaries go?" that tech layers and org charts get wrong.

**Domain:** [[tier-2-solid|Integration & API Architecture]]

## What it is

Eric Evans' DDD (2003) starts from a premise that still holds: the hard part of complex software
is not the technology but the **domain** — and the biggest source of defects is the translation
gap between how the business thinks and how the code is structured. DDD closes that gap by making
the domain model and its language the center of the design.

- **Strategic design** operates at the architecture level: decompose the problem domain into
  **subdomains**, define **bounded contexts** (the boundaries of model consistency), establish a
  **ubiquitous language** per context, and draw a **context map** of how contexts relate.
- **Tactical design** operates inside a single context: model it with **aggregates** (clusters of
  objects with a consistency boundary and a single root that enforces invariants), **entities**,
  **value objects**, **domain events**, **repositories**, and **domain services**.

The two are separable. You can get most of DDD's architectural value from strategic design alone;
the tactical patterns are an implementation style you adopt where the domain logic is rich enough
to justify it.

## Why it matters

- **Bounded contexts are the right seams.** The most expensive architecture mistake is splitting a
  system along the wrong lines — by technical layer (UI/service/DB) or by accident of org chart —
  producing services that must change together. DDD's bounded contexts follow *business capability*
  boundaries, which change independently. This is the modeling input that
  [[coupling-and-versioning-discipline|decoupling discipline]] and service decomposition both
  depend on; get it wrong and no amount of contract testing saves you.
- **Ubiquitous language removes translation bugs.** When the code, the conversations, and the
  domain experts all use the *same* word to mean the *same* thing within a context, a whole class
  of misunderstanding-driven defects disappears.
- **It directs effort to where it pays.** Classifying subdomains as **core / supporting / generic**
  tells you where to invest custom modeling (the core, your differentiator) and where to
  [[trade-off-judgment|buy or use off-the-shelf]] (generic — auth, billing, notifications).
- **It is the vocabulary AI codegen needs.** A documented ubiquitous language and explicit context
  boundaries are exactly the grounding that makes AI-generated code coherent rather than a pile of
  inconsistent terms; LLMs are also increasingly useful as a facilitator/scribe for the discovery
  workshops below. See [[spec-driven-development]] and [[vibe-coding-governance]].

## Key concepts / building blocks

### Bounded context — the central pattern

A bounded context is a boundary (a service, a module, a subsystem) within which one model and one
language apply unambiguously. The same term means different things in different contexts: a
*Customer* in **Sales** (a lead with a pipeline stage) is not the *Customer* in **Support** (an
entitlement and a ticket history) or in **Billing** (a payment account). Forcing one shared
"Customer" model across all of them is the canonical mistake DDD exists to prevent. Each context
owns its model; integration happens at the edges, not by sharing the model.

### Ubiquitous language

A rigorous, shared vocabulary built *with* domain experts and used everywhere inside a context —
in conversation, in the model, in the code, in the tests. It is bounded-context-scoped: there is
no single enterprise-wide language, by design.

### Subdomains: core, supporting, generic

| Subdomain | What it is | Investment strategy |
|---|---|---|
| **Core** | Your competitive differentiator | Build it yourself; put your best people and richest modeling here |
| **Supporting** | Necessary, specific to you, but not differentiating | Build simply or outsource; don't gold-plate |
| **Generic** | Solved problems (auth, payments, email) | Buy / adopt off-the-shelf; never hand-build |

This map is one of DDD's most practical outputs — it is a build-vs-buy heat map.

### Context mapping — the relationship patterns

The context map records how bounded contexts relate, with explicit upstream→downstream power
dynamics:

- **Partnership** — two contexts succeed or fail together; coordinated planning.
- **Shared Kernel** — a small shared model both own jointly (use sparingly — it re-couples them).
- **Customer–Supplier** — downstream's needs influence upstream's roadmap.
- **Conformist** — downstream simply accepts upstream's model (no negotiating power).
- **Anticorruption Layer (ACL)** — downstream builds a translation layer to keep a messy or legacy
  upstream model out of its own clean model. The key defensive pattern for integrating with legacy
  or third-party systems.
- **Open Host Service + Published Language** — upstream offers a well-defined, documented interface
  (e.g. a public API / event schema) for many downstreams.
- **Separate Ways** — the integration isn't worth it; duplicate instead.

### Tactical patterns (inside a context)

Briefly, the building blocks for a rich domain model: **aggregate** (a consistency boundary with a
single root that enforces invariants and is the unit of transactional change), **entity** (identity
over time), **value object** (immutable, defined by attributes), **domain event** (something
meaningful that happened — the bridge to [[event-driven-architecture]] and
[[event-sourcing-and-cqrs]]), **repository** (persistence abstraction), and **domain service**
(domain logic that doesn't belong to one entity). Adopt these where domain logic is rich; skip them
where the context is essentially CRUD.

### Event storming — discovering the model

A collaborative workshop (Alberto Brandolini) that maps a business process as a timeline of
**domain events**, then works backward to the **commands**, **actors**, and **aggregates** that
produce them — and the clusters that emerge are candidate **bounded contexts**. It is the dominant
modern technique for discovering boundaries when breaking down a monolith, precisely because it
puts domain experts and engineers at the same wall.

## Design decisions & trade-offs

- **Strategic first; tactical optional.** The boundaries and the language deliver most of the value.
  Importing the full tactical toolbox (aggregates/repositories everywhere) into a simple context is
  ceremony. Apply tactical DDD where the core domain's logic earns it.
- **A bounded context is not necessarily a microservice.** This is the decision that links DDD to
  deployment: a context is a *modeling* boundary; whether it becomes a separate deployable is a
  *separate* call about granularity and operational cost (the service-decomposition decision). A
  modular monolith can hold many bounded contexts as in-process modules. Decouple the model boundary
  from the deployment boundary.
- **Where to spend an Anticorruption Layer.** ACLs cost code and a translation hop but protect your
  core model from contamination by a legacy or vendor model. Spend them at your most valuable
  boundaries; accept Conformist elsewhere.
- **Core vs. generic discipline.** The most common misallocation is lavishing custom modeling on a
  generic subdomain (building a bespoke auth system) while under-investing in the core. The subdomain
  map is the corrective.
- **DDD is for complexity, not everything.** On a genuinely simple CRUD domain, full DDD is
  overhead. Reserve it for domains whose *business* complexity (not technical) is the real challenge.

## State of the art

- **DDD remains the standard method for carving microservice and module boundaries** — Microsoft's
  Azure Architecture Center, Vaughn Vernon's *Implementing DDD*, and most microservices guidance
  start from subdomains and bounded contexts rather than technical layers.
- **Event storming is the mainstream discovery technique**, especially for monolith decomposition and
  as a precursor to [[event-driven-architecture|event-driven]] and event-sourced designs.
- **The modular-monolith resurgence reinforces DDD, not replaces it:** teams increasingly keep
  bounded contexts as in-process modules and defer distribution — DDD provides the boundaries either
  way.
- **AI-assisted modeling** is emerging: LLMs as facilitators/scribes for event storming and as a
  check that code vocabulary matches the ubiquitous language — with the human owning the domain truth.

## Pitfalls & anti-patterns

- **Jumping to tactical patterns without strategic design.** Aggregates and repositories everywhere,
  but no bounded contexts or ubiquitous language — the most common way DDD is misapplied. The
  strategic half is the part that matters most.
- **The single canonical enterprise model.** Trying to make one "Customer"/"Product" model serve the
  whole organization. Bounded contexts exist precisely to reject this; the canonical model becomes a
  coupling magnet everyone fights over.
- **Forcing bounded-context = microservice 1:1, prematurely.** Splitting every context into its own
  deployable before the boundaries are stable produces a distributed monolith. Model first; distribute
  later. (Feeds the service-decomposition decision.)
- **No ubiquitous language in the code.** Domain experts say "policy", the code says "record" — the
  translation gap DDD was meant to close, reopened.
- **DDD on a CRUD/generic domain.** Modeling ceremony where a simple table would do.
- **Ignoring the context map.** Defining contexts but not their relationships leads to ad hoc, brittle
  integration and accidental coupling at the seams.

## See also

- [[service-decomposition]]
- [[coupling-and-versioning-discipline]]
- [[event-driven-architecture]]
- [[event-sourcing-and-cqrs]]
- [[api-styles-and-protocols]]
- [[systems-thinking-over-syntax]]
- [[spec-driven-development]]

## Sources

- [Evans, E. — Domain-Driven Design (domainlanguage.com)](https://www.domainlanguage.com/ddd/)
- [Microsoft Azure Architecture Center — Domain analysis for microservices](https://learn.microsoft.com/en-us/azure/architecture/microservices/model/domain-analysis)
- [Microsoft Azure Architecture Center — Tactical DDD](https://learn.microsoft.com/en-us/azure/architecture/microservices/model/tactical-domain-driven-design)
- [Brandolini, A. — EventStorming](https://www.eventstorming.com/)
- [Vernon, V. — Implementing Domain-Driven Design (O'Reilly)](https://www.oreilly.com/library/view/implementing-domain-driven-design/9780133039900/)
