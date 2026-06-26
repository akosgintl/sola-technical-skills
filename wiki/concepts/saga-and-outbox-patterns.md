---
title: Saga & Outbox Patterns
aliases: [saga, saga pattern, outbox pattern, transactional outbox, distributed transactions, two-phase commit, idempotency, compensating transaction, dual-write problem, exactly-once]
type: concept
domain: data
status: mature
tags: [data, integration, saga, outbox, idempotency, distributed-transactions, eventual-consistency]
updated: 2026-06-26
sources:
  - "https://microservices.io/patterns/data/saga.html"
  - "https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html"
  - "https://www.infoq.com/articles/saga-orchestration-outbox/"
  - "https://www.conduktor.io/glossary/implementing-cdc-with-debezium"
  - "https://debezium.io/documentation/reference/stable/transformations/outbox-event-router.html"
---

# Saga & Outbox Patterns

> [!summary]
> Once a business operation spans multiple services (or a service and a message broker), the
> single-database ACID transaction is gone — and a distributed two-phase commit is usually
> unavailable or undesirable. The saga/outbox family is how you stay *correct* anyway. A **saga**
> decomposes a distributed transaction into a sequence of **local** transactions, each publishing
> an event/command, with **compensating transactions** to semantically undo on failure. The
> **transactional outbox** solves the **dual-write problem** — writing state to the DB *and*
> publishing an event can't be atomic across two systems — by recording the event in the same
> local transaction and relaying it afterward. And because brokers deliver **at-least-once**,
> every consumer must be **idempotent**. The trade is explicit: you give up ACID and accept
> eventual consistency plus hand-designed compensation.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

[[service-decomposition|Splitting a system into services]] with a database each means a business
action like "place order → reserve inventory → charge payment → schedule shipping" now touches
several stores owned by several services. There is no shared transaction to wrap it. The classic
answer — **two-phase commit (2PC)** — is generally rejected in modern distributed systems: it
blocks on a coordinator, tanks availability (any participant down stalls the commit), and isn't
supported by most cloud datastores and brokers.

So you decompose the distributed transaction into **local** transactions coordinated by
asynchronous messages, and accept **eventual consistency**. The three patterns that make this
correct:

- **Saga** — the sequence of local transactions + the compensation logic to unwind a partial
  failure.
- **Transactional outbox** — the mechanism that lets each step atomically *change state and emit
  its event*.
- **Idempotency** — the consumer-side safety net that makes at-least-once delivery harmless.

## Why it matters

These are not optional refinements — they are the **correctness backbone** of any decomposed,
[[event-driven-architecture|event-driven]] system. Skip them and the failure modes are concrete
and expensive:

- **The dual-write problem.** The naive "commit to the DB, then publish to Kafka" is two writes
  to two systems with no shared transaction. If the process dies between them, you have state with
  no event (the saga stalls silently) or — if you publish first — an event with no state. Data
  diverges and nobody notices until reconciliation.
- **Duplicate delivery.** Brokers almost universally guarantee *at-least-once*. A non-idempotent
  consumer double-charges the card, double-ships the order, or double-applies the credit.
- **Stuck or inconsistent sagas.** A multi-step flow that fails at step 3 with no compensation
  leaves inventory reserved and payment uncharged forever.

## Key concepts / building blocks

### Saga: local transactions + compensation

A saga is an ordered set of local transactions T1…Tn. If Ti fails, the saga runs **compensating
transactions** Ci-1…C1 to semantically undo the completed steps. Compensation is *not* a rollback
— the local commits already happened and are visible; you issue *new* business actions that negate
them (`PaymentRefunded`, `InventoryReleased`). Two recovery directions:

- **Backward recovery** — compensate completed steps and abort (the default).
- **Forward recovery** — retry the failed step until it succeeds (for steps that *must* complete).

### Orchestration vs. choreography

| Axis | **Choreography** | **Orchestration** |
|---|---|---|
| Control | None — each service reacts to events and emits its own | A central orchestrator issues commands and awaits replies |
| Coupling | Low; aligns with [[event-driven-architecture\|EDA]]/Kafka | Services coupled to the orchestrator |
| Visibility | Emergent — the flow lives across services | Centralized — the flow is one readable definition |
| Debugging | Hard; no single place shows the saga state | Easier; the orchestrator holds the state machine |
| Best for | Few steps, simple flows | Many steps, complex branching, auditability |

Neither changes whether the system is *correct* — both still need idempotency, an outbox, and
explicit compensation. The choice decides *where control and visibility live*.

### The transactional outbox

To emit an event atomically with a state change, write both **in one local transaction**: the
business row(s) *and* a row in an **outbox** table. A separate **relay** then publishes outbox
rows to the broker and marks them sent. Because the two writes share one ACID transaction, there's
no dual-write gap. Two relay mechanisms:

- **Polling publisher** — a worker polls the outbox table for unsent rows. Simple; adds DB load
  and latency.
- **Change Data Capture (CDC)** — a tool tails the database transaction log (Postgres WAL, MySQL
  binlog) and publishes new outbox rows with no polling and strict ordering. **Debezium** is the
  de-facto production choice (its Outbox Event Router is purpose-built for this).

### Idempotency — the non-negotiable

Under at-least-once delivery, every step will eventually run twice. Make consumers idempotent:

- **Idempotency key / dedup store** — record processed message IDs (an "inbox" table); skip
  duplicates.
- **Natural idempotency** — design operations so re-applying is a no-op (`SET status='paid'`
  rather than `balance -= amount`).

"Exactly-once" in practice is **effectively-once**: outbox (no lost/duplicated *emission*) +
idempotent consumers (no duplicated *effect*) — not a magic broker setting.

## Design decisions & trade-offs

- **First, question the boundary.** A saga is a *consequence* of [[service-decomposition|splitting]].
  If an operation needs a multi-step distributed transaction across services that always change
  together, the cheaper fix may be to *not split them* — keep them in one bounded context with a
  local ACID transaction. Reach for a saga only when the split is genuinely justified. This is
  [[domain-driven-design|boundary judgment]] feeding back into data design.
- **Choreography vs. orchestration by step count.** Default to choreography for short, simple flows
  (lowest coupling, EDA-native); move to orchestration as steps, branching, and the need for
  centralized visibility/debugging grow. Watch choreography for *event sprawl* — cyclic event
  chains nobody can trace.
- **Outbox relay: polling vs. CDC.** Polling is trivial to stand up and fine at low volume; CDC
  (Debezium) removes polling overhead and preserves ordering at the cost of running CDC
  infrastructure. Choose by scale and existing platform.
- **Compensation design is the hard part.** Some actions aren't cleanly compensable (an email sent,
  a physical shipment). Design for it with *semantic locks* and *pending* states (reserve, then
  confirm/cancel) so the irreversible action happens last or behind a confirmation.
- **Eventual consistency is a UX decision, not just a backend one.** Users will observe in-between
  states ("payment processing"). Design the product for it rather than pretending the write is
  instant.
- **Durable execution as managed orchestration.** Engines like **Temporal**, AWS Step Functions,
  and Azure Durable Functions encode the saga state machine, retries, and compensation into a
  persistence layer — trading a platform dependency for far less bespoke coordinator code. See
  [[distributed-systems-reliability]].

## State of the art

- **Outbox + CDC is the standard production combo.** Debezium 2.5+ on Kafka (KRaft), deployed via
  Kubernetes/Strimzi with OpenTelemetry/Prometheus observability, is the common reference stack for
  reliable event emission.
- **Durable-execution engines** (Temporal especially) have become a default way to implement
  orchestrated sagas without hand-rolling the state machine, retry, and compensation logic.
- **Idempotency + dead-letter-queue monitoring** are now baseline expectations, not advanced
  practice — the patterns are mature and well-documented (microservices.io, AWS Prescriptive
  Guidance).
- **"Effectively-once" is the accepted framing**, replacing the misleading promise of broker-level
  "exactly-once" — correctness comes from the application patterns, not the transport.

## Pitfalls & anti-patterns

- **Dual write without an outbox.** "Save to DB, then publish" is the single most common
  data-consistency bug in microservices. Use the outbox.
- **Non-idempotent consumers.** Assuming exactly-once delivery. At-least-once is the reality; dedupe
  or design natural idempotency.
- **Distributed 2PC across services.** Reaching for a blocking two-phase commit — poor availability,
  poor support, fragile under partition.
- **Sagas with no (or impossible) compensation.** A multi-step flow that can't unwind a partial
  failure, or steps that are physically un-compensable placed before failable ones.
- **Choreography sprawl.** So many services reacting to each other's events that no one can describe
  the end-to-end flow — and cyclic event loops creep in. Switch to orchestration when this happens.
- **Ignoring eventual-consistency UX.** Surfacing a half-completed saga as if it were final, or
  re-reading a lagging projection right after a write (see [[event-sourcing-and-cqrs]]).
- **Sagas papering over a bad boundary.** Using elaborate distributed-transaction machinery to glue
  together two services that should have been one.

## See also

- [[service-decomposition]]
- [[event-driven-architecture]]
- [[event-sourcing-and-cqrs]]
- [[coupling-and-versioning-discipline]]
- [[streaming-and-event-data]]
- [[distributed-systems-reliability]]
- [[domain-driven-design]]

## Sources

- [microservices.io — Saga pattern (Chris Richardson)](https://microservices.io/patterns/data/saga.html)
- [AWS Prescriptive Guidance — Transactional outbox pattern](https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/transactional-outbox.html)
- [InfoQ — Saga Orchestration for Microservices Using the Outbox Pattern](https://www.infoq.com/articles/saga-orchestration-outbox/)
- [Conduktor — Implementing CDC with Debezium](https://www.conduktor.io/glossary/implementing-cdc-with-debezium)
- [Debezium — Outbox Event Router](https://debezium.io/documentation/reference/stable/transformations/outbox-event-router.html)
