---
title: Event Sourcing and CQRS
aliases: [CQRS, event sourcing, command query responsibility segregation, event store, projection]
type: concept
domain: data
status: mature
tags: [data, event-sourcing, cqrs, patterns, projections, snapshots, eventual-consistency]
updated: 2026-06-20
sources:
  - "https://medium.com/codetodeploy/cqrs-and-event-sourcing-the-architecture-behind-high-scale-systems-3f3f6098a2cd"
  - "https://www.techinterview.org/post/3233465463/system-design-event-sourcing/"
  - "https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing"
  - "https://dasroot.net/posts/2026/04/event-sourcing-cqrs-databases-eventstoredb-axon-polecat/"
  - "https://knowledgelib.io/software/system-design/cqrs-event-sourcing/2026"
---

# Event Sourcing and CQRS

> [!summary]
> Event sourcing and CQRS are two distinct patterns that are frequently combined. Event sourcing stores every state change as an immutable, append-only event — current state is derived by replaying the log, giving complete auditability and the ability to rebuild any past state. CQRS (Command Query Responsibility Segregation) separates the write model (commands that mutate state) from the read model (projections optimized for queries). Together they enable independent scaling of reads and writes, multiple purpose-built read models from a single event stream, and a full audit log by design. The cost is significant complexity — apply only to bounded contexts where the trade-off is justified.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

**CRUD vs. event sourcing — the fundamental difference:**

In a traditional CRUD system, the database stores the *current state*: updating a record overwrites the previous value. The history is lost.

In event sourcing, the database stores the *sequence of changes* that led to the current state. The current state is derived by replaying the event log. Example for an order:

```
OrderPlaced   { orderId: 42, items: [...], total: 150.00 }
PaymentReceived { orderId: 42, amount: 150.00, method: "card" }
OrderShipped  { orderId: 42, trackingId: "XYZ123" }
```

Current state = replay all events for `orderId: 42`. The history is not a log that might be queried — it *is* the primary storage. No event is ever updated or deleted in production; corrections are made by appending a compensating event.

**CQRS — why it pairs naturally with event sourcing:**

CQRS recognizes that the model optimized for handling a write command ("place this order") is rarely the same model optimized for answering a read query ("show me the last 50 orders with their status"). CQRS splits them:

- **Write side (Command):** validates the command, appends events to the event store
- **Read side (Query):** consumes events and maintains denormalized projections optimized for specific queries

The two sides can use different databases, different schemas, and scale independently.

## Why it matters

Event sourcing and CQRS add significant complexity. They are worth it in bounded contexts where:

- **Full audit log is a hard requirement** — financial transactions, medical records, legal contracts; the event log is the audit trail by design, not an afterthought
- **Temporal queries are needed** — "what was the state of this order at 3pm yesterday?" is trivial with event sourcing (replay up to timestamp) and hard with CRUD
- **Multiple independent read models** — different consumers (dashboard, search index, analytics, external reporting) need different views of the same data; each gets its own projection fed from the same event stream
- **Write throughput is high** — event stores are append-only and can be sharded by aggregate ID; no update contention
- **Regulatory compliance** — immutable event log satisfies audit requirements for SOX, GDPR, PCI DSS better than mutable CRUD tables

> [!warning]
> Do NOT apply event sourcing globally. It is a pattern for specific bounded contexts with specific requirements, not an architecture for the whole system. Most systems do not benefit from it; applying it everywhere multiplies operational complexity without proportional gain.

## Key concepts / building blocks

### The event store

The event store is the append-only log of domain events — the single source of truth. Requirements:

- **Append-only:** events are immutable once written; no updates, no deletes
- **Ordered:** events for an aggregate are strictly ordered; global ordering is often not required
- **Replayable:** consumers can read the stream from any point; enables projection rebuilds and new downstream consumers

**Aggregate streams:** events are organized by aggregate (the domain concept they belong to — an Order, a Customer, an Account). All events for `order-42` form one stream. A projection reads across streams to build a read model.

**Event store options:**
- **EventStoreDB** — purpose-built; native event sourcing; subscriptions and projections built in; the reference implementation
- **Kafka** — durable, partitioned event log; widely used as an event store backbone; lacks built-in aggregate stream semantics but provides excellent throughput and consumer group management
- **PostgreSQL with append-only tables** — viable for moderate-scale systems; no built-in projection engine; requires custom subscription mechanism
- **SQL Server 2025 / Polecat** — emerging SQL-native event sourcing support

### Projections (read models)

A projection consumes events from the event store and materializes a denormalized view optimized for a specific query pattern. Projections are:

- **Eventually consistent:** there is a lag between an event being written and the projection being updated — typically milliseconds to seconds
- **Rebuildable:** if the projection schema changes, drop the projection table and replay all events to rebuild it from scratch
- **Independent:** different projections can serve different use cases without affecting the write model

**Example projections from the same order event stream:**
- `orders_by_customer` — table keyed by customer ID for "show my orders" queries
- `orders_pending_shipment` — filtered view for warehouse dashboard
- `order_search_index` — Elasticsearch document for full-text search
- `revenue_by_product` — aggregated analytics table

Each projection is built by a separate consumer that processes the event stream and upserts into its own data store (PostgreSQL, Elasticsearch, Redis, DynamoDB — whatever fits the query pattern).

### Snapshots

Replaying the entire event history for an aggregate on every read becomes expensive as the event log grows. Snapshots solve this:

- Periodically serialize the current aggregate state (e.g., every 100 events or every N hours)
- On read, load the most recent snapshot and replay only events since the snapshot
- Snapshots do not replace events — they are a performance optimization that can be regenerated from the event log

### Command handling (the write side)

The CQRS write side follows a pattern:

1. Receive a **Command** (e.g., `PlaceOrderCommand`)
2. Load the current aggregate state (replay events or load snapshot + tail events)
3. **Validate** the command against the current state (is there enough inventory? is the user authorized?)
4. If valid, produce one or more **Events** (`OrderPlacedEvent`)
5. **Append** the events to the event store (with an expected version for optimistic concurrency)
6. Return success; projections update asynchronously

**Optimistic concurrency:** when appending events, specify the version the aggregate was at when loaded. If another command wrote events to the same aggregate in the meantime, the version won't match and the write fails — the command handler retries by reloading the latest state.

### CQRS without event sourcing

CQRS can be used without event sourcing. The simplest CQRS: a single PostgreSQL database where writes go to normalized tables and reads come from a denormalized view (or a separate read replica). This is far less complex than full event sourcing and is appropriate when:
- Read performance needs are very different from write patterns
- Reads can tolerate replication lag
- Full audit log is not required

Full event sourcing + CQRS is the more powerful but more complex combination.

## Design decisions & trade-offs

**When event sourcing is worth the cost:**

| Requirement | Event sourcing advantage | Without it |
|---|---|---|
| Immutable audit log | Built-in by design | Requires separate audit table with triggers |
| Temporal queries ("state at time T") | Replay to timestamp | Requires history tables (SCD Type 2) |
| Multiple read model variations | Each projection independently optimized | Denormalize in the same schema; coupling |
| Debugging production issues | Replay exact event sequence | Reconstruct from logs |
| GDPR right-to-erasure | Compensating event + projection rebuild | Update/delete cascade |

**The complexity cost is real:**
- Two separate data models to design and maintain
- Projection lag creates eventual consistency that callers must handle
- Event schema evolution requires careful versioning (upcasters for old event formats)
- Debugging is harder (must trace through event replay rather than query current state)
- Testing requires building event stores and projection runners

**Event schema evolution:** events are immutable but their schema will need to evolve. Strategies:
- **Upcasting:** a transformation layer converts old event formats to the current schema before the aggregate processes them — old events are never rewritten
- **Versioned event types:** `OrderPlacedV1`, `OrderPlacedV2` — explicit versioning in the event type name; each version has its own handler
- **Weak schema (JSON + forward compatibility):** add fields but never remove; old consumers ignore unknown fields; new consumers handle missing fields with defaults

## State of the art

Event sourcing is a mature pattern with well-understood trade-offs, not a new trend. The primary production frameworks (EventStoreDB, Axon Framework for Java, Marten for .NET) are stable. The most common production deployment: Kafka as the durable event backbone with Flink or custom consumers building projections into PostgreSQL, Elasticsearch, or DynamoDB read models.

**AI workload applications:** event sourcing is gaining attention for AI agent state management — recording every agent action as an immutable event enables replay, debugging, and audit of agent behavior. The same properties that make it valuable for financial systems (auditability, temporal queries) apply to agentic systems where understanding "what did the agent do and why" is critical.

## Pitfalls & anti-patterns

**Applying event sourcing everywhere.** The complexity is not justified for simple CRUD domains. Apply to bounded contexts with audit, temporal, or multi-projection requirements; use standard CRUD elsewhere.

**Storing derived state in events.** Events should record what *happened* (the fact), not what was *computed* (the result). `OrderShipped { trackingId: "X" }` is correct; `OrderShipped { trackingId: "X", customerEmail: "a@b.com", daysInWarehouse: 3 }` bakes derived/joined data into the immutable record — it will be wrong when the customer changes their email.

**Mutating events.** Updating or deleting events because "there was a mistake." The event log is immutable. Mistakes are corrected with compensating events: `OrderCancelled`, `PaymentRefunded`. GDPR erasure is handled by removing PII from projections (the event itself records the action without the data, or the data is encrypted and the key is deleted).

**No snapshot strategy.** An event log with millions of events per aggregate and no snapshots means every read replays the entire history. Design snapshot intervals from the start.

**Ignoring projection lag.** CQRS projections are eventually consistent. Callers that immediately query a projection after a write may not see the write yet. Design for this: return the result of the command (the events produced), not a re-read of the projection.

## See also

- [[streaming-and-event-data]]
- [[event-driven-architecture]]
- [[data-storage-paradigms]]
- [[coupling-and-versioning-discipline]]
- [[distributed-systems-reliability]]

## Sources

- CodeToDeploy. (2026). CQRS and Event Sourcing: The Architecture Behind High-Scale Systems. https://medium.com/codetodeploy/cqrs-and-event-sourcing-the-architecture-behind-high-scale-systems-3f3f6098a2cd
- TechInterview.org. (2026). System Design: Event Sourcing and CQRS — Append-Only Events, Projections, and Read Models. https://www.techinterview.org/post/3233465463/system-design-event-sourcing/
- Microsoft. (2025). Event Sourcing Pattern — Azure Architecture Center. https://learn.microsoft.com/en-us/azure/architecture/patterns/event-sourcing
- DasRoot. (2026). Event Sourcing and CQRS with Databases — EventStoreDB, Axon, Polecat. https://dasroot.net/posts/2026/04/event-sourcing-cqrs-databases-eventstoredb-axon-polecat/
- KnowledgeLib. (2026). CQRS and Event Sourcing: Implementation Guide. https://knowledgelib.io/software/system-design/cqrs-event-sourcing/2026
