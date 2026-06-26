---
title: Service Decomposition
aliases: [microservices, modular monolith, monolith vs microservices, service granularity, distributed monolith, strangler fig]
type: concept
domain: integration
status: mature
tags: [integration, microservices, monolith, modular-monolith, granularity, architecture]
updated: 2026-06-26
sources:
  - "https://martinfowler.com/bliki/MonolithFirst.html"
  - "https://martinfowler.com/bliki/StranglerFigApplication.html"
  - "https://www.oreilly.com/library/view/building-microservices-2nd/9781492034018/"
  - "https://www.horizonlabs.com.au/insights/microservices-vs-modular-monolith-choosing-right-architecture-2026"
  - "https://www.devx.com/uncategorized/microservices-backlash-monoliths-comeback-2026/"
---

# Service Decomposition

> [!summary]
> Service decomposition is the decision of how to slice a system into **separately deployable
> units**, and how big each unit should be — the spectrum from a single monolith, through a
> **modular monolith**, to **microservices** (and the over-fine nano-service trap beyond). It is
> a different question from [[domain-driven-design|where the boundaries are]] (DDD finds the
> seams) and from [[coupling-and-versioning-discipline|keeping them decoupled]] (that's the
> discipline after splitting): decomposition decides *whether and how much to physically split at
> all*. The current default is **modular-monolith-first with selective extraction** — treat
> microservices as an operational cost you buy only when team-scale or independent-scaling demands
> it. The cardinal sin is the **distributed monolith**: all the cost of microservices, none of the
> benefit.

**Domain:** [[tier-2-solid|Integration & API Architecture]]

## What it is

Decomposition sits on a spectrum of how a system is packaged and deployed:

| Style | Deployment unit | Internal structure | Operational cost | Fits |
|---|---|---|---|---|
| **Monolith** | One deployable | Often a big ball of mud | Lowest | Early-stage, small teams, unclear domain |
| **Modular monolith** | One deployable | Strongly-decoupled modules along [[domain-driven-design\|bounded contexts]] | Low | The 2026 default for most systems |
| **Microservices** | Many deployables | One service per capability, own database | High | Team-scale or independent-scaling pressure |
| **Nano-services / functions** | Very many tiny deployables | One operation each | Very high | Rarely justified; usually an anti-pattern |

The two questions decomposition answers are *granularity* ("how big is a service?") and *timing*
("split now or later?"). Both are expensive to get wrong and moderately expensive to reverse —
which is why the senior move is to defer irreversible splitting until the drivers are real.

## Why it matters

Decomposition determines the system's **team autonomy, deployment frequency, scaling profile,
failure modes, and operational cost** all at once — and these consequences compound. Split too
coarse and every team is serialized behind a shared deployable (no independent release). Split too
fine, or along the wrong lines, and you get a **distributed monolith**: services so tightly coupled
(shared database, synchronous call chains) that they must deploy together anyway — now with network
latency, partial-failure modes, and distributed-data pain on top. You paid the microservices tax
and got monolith coupling.

The reason this is an architect's call and not a framework default is that the *right* answer is
driven by organizational and load realities, not fashion — and 2026 has seen a pronounced
**microservices backlash**, with teams consolidating over-split systems back toward modular
monoliths after discovering the operational bill.

## Key concepts / building blocks

### What actually justifies a split

Reach for a separate service only when you need one of these *independences* — and a monolith or
module can't give it:

- **Independent deployability / team autonomy** — a team can release without coordinating with
  others (the dominant reason; Conway's Law and Amazon's "two-pizza team" framing). See
  [[systems-thinking-over-syntax]].
- **Independent scaling** — one capability has a wildly different load/resource profile (a GPU
  inference path, a bursty ingestion pipeline) and you want to scale it alone.
- **Independent technology / lifecycle** — a component needs a different runtime, language, or
  release cadence.
- **Fault isolation** — a failure in one capability must not take down others.

"It's modern," "it'll scale someday," and "the org chart has N teams so we need N services" are
**not** on this list.

### Granularity heuristics

- **Bounded context as the upper bound.** A service should not be *larger* than a bounded context
  (that re-merges models); it can be *smaller*, but rarely should be.
- **Team-ownable.** A service should fit within one team's ownership; a service that spans teams
  recreates coordination. A team can own several services.
- **Avoid nano-services.** A service per entity or per operation multiplies network hops,
  deployment units, and failure surface for no autonomy gain.

### Decomposition strategies

- **By business capability / subdomain.** The default: align services to
  [[domain-driven-design|DDD subdomains]], not technical layers (no "UI service / logic service /
  data service").
- **Strangler Fig (for migration).** Incrementally extract modules from a monolith behind a façade,
  one clear-boundaried capability at a time, retiring the old path as the new one takes traffic —
  rather than a risky big-bang rewrite.
- **By volatility / scaling need.** Extract the parts that change on a different cadence or scale
  differently first; leave the stable core in the monolith.

### Modular monolith as the staging ground

A modular monolith keeps strongly-decoupled modules (clear interfaces, no cross-module database
access) in a **single deployable**. It buys most of the boundary benefits of microservices —
clean seams, team ownership of modules — without the distributed-systems tax, and it leaves clean
extraction points for the Strangler Fig later. This is why it is the recommended default starting
point in 2026.

## Design decisions & trade-offs

- **Modular-monolith-first vs. microservices-first.** Start with a well-modularized monolith and
  extract selectively when a real driver appears. Microservices-first pays the full operational
  cost (distributed data, network failure, observability, deployment orchestration) before you know
  where the boundaries truly are. Rough thresholds floated in practice — extracting once you cross
  ~1M requests/day or ~50 developers — are *signals, not rules*; the trigger is a concrete driver,
  not a number.
- **Granularity: coarse vs. fine.** Too coarse → no independent deployability. Too fine →
  distributed monolith, coordination overhead, and latency from chatty inter-service calls. The
  sweet spot is team-ownable and bounded-context-aligned.
- **Data is the real cost of splitting.** Microservices imply database-per-service, which turns
  in-process transactions into distributed-data problems (eventual consistency,
  [[saga-and-outbox-patterns|sagas and the outbox]]) — see also
  [[coupling-and-versioning-discipline]] and [[event-sourcing-and-cqrs]]. Underestimating this is
  the most common reason microservices migrations stall.
- **Platform investment lowers the microservices tax.** Internal developer platforms (Backstage,
  Port, Cortex) plus Kubernetes, a service mesh, and GitOps make a 20-service estate maintainable
  by a small platform team — but that platform is itself an investment to budget. See
  [[developer-experience]], [[kubernetes-at-design-level]], [[api-gateways-and-service-mesh]].
- **Reversibility favors the modular monolith.** Merging services back together is painful;
  splitting a clean module out is comparatively easy. Prefer the path that keeps the expensive,
  hard-to-reverse decision (distribution) deferred until the cheap-to-reverse one (modularization)
  has revealed stable boundaries. This is [[trade-off-judgment|reversibility-first judgment]].

## State of the art

- **The microservices backlash is real.** 2026 has a visible "monolith comeback": teams
  consolidating prematurely-split systems, and high-profile reports of cost/latency wins from
  re-merging. The pendulum has settled on *selective* decomposition, not "microservices by default."
- **Modular monolith is the recommended default** for most new systems, with the Strangler Fig as
  the sanctioned path to extract services when a driver materializes.
- **IDPs made microservices operationally accessible** to smaller teams — Backstage/Port/Cortex +
  GitOps abstract away much of the Kubernetes/mesh/observability burden — which paradoxically makes
  the *discipline* of not over-splitting more important, since the technical barrier is lower.
- **Decomposition-framework research** (automated boundary recommendation from monolith codebases)
  is maturing but remains an assist to human/DDD judgment, not a replacement.

## Pitfalls & anti-patterns

- **The distributed monolith.** Services coupled by a shared database or synchronous call chains —
  must deploy together, fail together, but pay full network cost. The defining failure of bad
  decomposition. Antidote: [[coupling-and-versioning-discipline|database-per-service + async]].
- **Premature decomposition.** Splitting before the domain boundaries are stable, so service edges
  churn constantly and integration cost explodes. Model first ([[domain-driven-design]]); split
  later.
- **Resume/ideology-driven microservices.** Adopting microservices because they're "best practice"
  rather than for a concrete independence driver.
- **Nano-services.** Decomposing to the point where coordination and network overhead dwarf the work.
- **Splitting by technical layer.** A "frontend service / business-logic service / database service"
  carves across capabilities, maximizing coupling.
- **Ignoring the operational tax.** Treating microservices as free once the code is split —
  forgetting distributed observability, deployment orchestration, and distributed data.
- **Service/team mismatch.** A service no single team owns recreates the coordination the split was
  meant to remove (Conway's Law working against you).

## See also

- [[domain-driven-design]]
- [[coupling-and-versioning-discipline]]
- [[saga-and-outbox-patterns]]
- [[cloud-native-patterns]]
- [[event-driven-architecture]]
- [[kubernetes-at-design-level]]
- [[api-gateways-and-service-mesh]]
- [[developer-experience]]
- [[trade-off-judgment]]

## Sources

- [Fowler, M. — MonolithFirst](https://martinfowler.com/bliki/MonolithFirst.html)
- [Fowler, M. — Strangler Fig Application](https://martinfowler.com/bliki/StranglerFigApplication.html)
- [Newman, S. — Building Microservices, 2nd Edition (O'Reilly)](https://www.oreilly.com/library/view/building-microservices-2nd/9781492034018/)
- [Horizon Labs — Microservices vs Modular Monolith: Architecture Choice 2026](https://www.horizonlabs.com.au/insights/microservices-vs-modular-monolith-choosing-right-architecture-2026)
- [DevX — Microservices Backlash 2026: When Monoliths Make a Comeback](https://www.devx.com/uncategorized/microservices-backlash-monoliths-comeback-2026/)
