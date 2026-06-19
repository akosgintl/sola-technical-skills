---
title: Event Sourcing and CQRS
aliases: [CQRS, event sourcing, command query responsibility segregation]
type: concept
domain: data
priority: P1
roadmap_ref: "5.2.2"
status: stub
tags: [data, event-sourcing, cqrs, patterns]
updated: 2026-06-19
sources: []
---

# Event Sourcing and CQRS

> [!summary]
> Two complementary patterns: storing state as an append-only log of events (event sourcing) and separating write and read models (CQRS) for independent scaling and modeling.

**Priority:** 🟠 P1 · **Domain:** [[tier-2-solid|Data Architecture]] · **Roadmap:** §5.2.2

## What it is

Event sourcing persists every state change as an immutable event, reconstructing current state by replaying the log — giving full auditability and temporal queries. CQRS (Command Query Responsibility Segregation) splits the model that handles writes from the one optimized for reads. The two are often combined but each can be used alone.

## Key concepts

- Append-only event store as source of truth
- Command vs. query models (CQRS)
- Projections and read-model rebuilds
- Snapshots, replay, and eventual consistency
- Trade-offs vs. CRUD complexity

## See also

- [[streaming-and-event-data]]
- [[event-driven-architecture]]
- [[data-storage-paradigms]]
- [[coupling-and-versioning-discipline]]

## Sources

- _Stub — no sources ingested yet._
