---
title: Event-Driven Architecture
aliases: [EDA, event driven, event-driven systems, message-driven architecture]
type: concept
domain: cloud
status: mature
tags: [cloud, events, messaging, kafka, eventbridge, choreography, orchestration, idempotency]
updated: 2026-06-20
sources:
  - "https://encore.dev/resources/event-driven-architecture"
  - "https://www.digitalapplied.com/blog/event-driven-architecture-message-queues-2026-engineering-reference"
  - "https://edana.ch/en/2025/07/19/event-driven-architecture-kafka-rabbitmq-sqs-why-your-systems-must-react-in-real-time/"
  - "https://leapcell.io/blog/orchestration-vs-choreography-event-driven-backend-integration"
  - "https://www.redpanda.com/guides/kafka-use-cases-event-driven-architecture"
  - "https://arxiv.org/abs/2512.16146"
---

# Event-Driven Architecture

> [!summary]
> An architectural style where services communicate by producing and reacting to events rather than direct request/response calls. Events decouple producers from consumers in time and dependency — producers don't know who consumes their events, consumers don't need producers online to do their work. The trade-offs are ordering, idempotency, eventual consistency, and operational complexity. EDA is the right architecture for high-throughput async workloads, complex choreography between microservices, and audit-trail-heavy domains; it is over-engineering for simple CRUD or low-volume workflows.

**Domain:** [[tier-1-edge|Cloud Architecture]]

## What it is

In event-driven architecture, a **producer** emits an event describing something that happened ("OrderPlaced", "PaymentProcessed", "InventoryUpdated") and publishes it to a **broker**. One or more **consumers** subscribe to the broker and react independently. Neither side knows directly about the other. The broker handles delivery, buffering, and — depending on the platform — ordering and durability.

EDA is contrasted with request/response: in REST or gRPC, the caller blocks until the callee responds and knows immediately if the call failed. In EDA, the producer fires and moves on; success is eventually confirmed (or not) through downstream state changes.

## Why it matters

**Loose temporal coupling** — a consumer can be offline when an event is produced; the broker holds the event until the consumer is ready. Services can be deployed, restarted, and scaled independently without coordination.

**Horizontal scale** — consumers scale independently by adding partitions or consumer instances. Kafka-based systems routinely process millions of events per second with linear horizontal scale.

**Auditability** — every state change is an immutable event. The stream is the audit log, which is particularly valuable in regulated domains (finance, healthcare) and for agent decision tracing (see [[ai-agent-observability]]).

**Complexity cost** — ordering, idempotency, delivery guarantees, schema evolution, and distributed debugging are all harder in EDA than in request/response. Don't reach for it unless the benefits justify these costs.

## Key concepts / building blocks

### Producers, brokers, and consumers

**Producer** — emits events; publishes to a topic or queue. No knowledge of which consumers exist.

**Broker** — the durable intermediary: Kafka, AWS SQS/SNS/EventBridge, Azure Service Bus/Event Grid, GCP Pub/Sub, RabbitMQ, Redpanda. Each has different delivery guarantees, ordering semantics, and operational profiles.

**Consumer** — subscribes to a topic or queue; processes events independently of the producer.

### Broker comparison

| Broker | Throughput | Ordering | Delivery guarantee | Best fit |
|---|---|---|---|---|
| **Apache Kafka / Redpanda** | Very high (millions/s) | Per-partition | At-least-once; exactly-once within Kafka | High-throughput streaming, event sourcing, audit logs |
| **AWS SQS Standard** | High | None | At-least-once | Simple async decoupling, background jobs |
| **AWS SQS FIFO** | Medium (~3K/s/queue) | Per message group | Exactly-once | Ordered processing, deduplication |
| **AWS EventBridge** | High | None guaranteed | At-least-once | AWS-native event routing, SaaS integration |
| **Azure Service Bus** | Medium-high | Per session | At-least-once / at-most-once | Enterprise messaging, dead-letter handling |
| **GCP Pub/Sub** | Very high | No global order | At-least-once | Google Cloud native; global scale |
| **RabbitMQ** | Medium | Per queue (strict) | At-least-once | Complex routing topologies, on-prem |

### Delivery semantics — the honest version

**At-most-once** — fire and forget; events may be lost. Never correct for business-critical events.

**At-least-once** — every event is delivered, but duplicates are possible. The production default. Consumers must be **idempotent** — processing the same event twice must produce the same result as processing it once.

**Exactly-once** — the ideal; rarely achievable end-to-end. Kafka provides exactly-once guarantees strictly within Kafka-to-Kafka flows (produce → read → transform → produce in a single transaction). The moment a consumer reads from Kafka and writes to PostgreSQL, that guarantee is gone. The database write is either committed or not; the Kafka offset commit is separate. The production answer is: **at-least-once delivery + idempotent consumers = effectively exactly-once**.

> [!warning] Exactly-once is a Kafka-internal guarantee
> Kafka's transaction API ensures exactly-once for read-process-write within Kafka. It does not apply to writes to external systems. Design all consumers as if they receive duplicates.

### Idempotency patterns

Every EDA consumer must handle duplicate events:
- **Natural idempotency** — some operations are inherently safe to repeat (SET value=X is idempotent; INSERT is not)
- **Idempotency key** — store a dedup table keyed by event ID; check before processing; insert-if-not-exists
- **Conditional writes** — use optimistic locking or compare-and-swap (if version=N then update)
- **Event ID in the message** — every event must carry a unique, stable ID the consumer can use for deduplication

### Choreography vs. orchestration

Two styles for coordinating multi-step processes (sagas):

**Choreography** — each service reacts to events and emits new events; no coordinator. Naturally decoupled; easy to add new participants. Difficult to follow the full flow (distributed logic, no single place to see the state machine). Debugging and error recovery require tracing across services.

**Orchestration** — a central coordinator (a saga orchestrator or workflow engine) explicitly calls each step and handles failures. Clearer flow visibility; easier error recovery and compensation logic. Tighter coupling to the orchestrator.

Rule of thumb: **choreography within a bounded context** (tight domain ownership); **orchestration across bounded contexts** (where visibility of the saga state matters more than loose coupling).

### The outbox pattern

A subtle but critical correctness issue: a service updates a database row and then publishes an event — two non-atomic operations. If the app crashes between the DB write and the broker publish, the event is lost and the system is inconsistent.

The **transactional outbox** solves this:
1. Write the state change AND the event to an `outbox` table inside the same database transaction
2. A separate **relay process** (Debezium CDC, custom poller) reads the outbox table and publishes events to the broker
3. The relay marks events as published once acknowledged by the broker

Either both the state change and the event are committed, or neither is. The atomicity of the database guarantees consistency; the relay provides eventual delivery.

### Event schema and evolution

Events are contracts between producers and consumers. Schema evolution discipline is mandatory:
- **Avro / Protobuf** with a schema registry (Confluent Schema Registry, AWS Glue Schema Registry) for backward/forward compatibility enforcement
- **Additive changes only** — never remove or rename a field; add new optional fields
- **AsyncAPI** — the emerging standard for defining event-driven API contracts (analogous to OpenAPI for REST). Provides contract-first development for message-driven systems; 73% of European carrier integrations are migrating to AsyncAPI-based contracts over ad-hoc webhooks (2025)

## Design decisions & trade-offs

**When EDA is right:**
- High-throughput asynchronous workloads (order processing, IoT ingestion, log aggregation)
- Multiple consumers need the same events independently (fan-out without coupling)
- Audit trail is a first-class requirement (the event log IS the audit log)
- Services need to evolve independently without coordinated deployments
- Temporal decoupling is valuable (consumers process at their own pace)

**When EDA adds cost without benefit:**
- Simple CRUD workflows where synchronous response is needed immediately
- Low-volume operations where the broker adds latency without throughput benefit
- Systems with few consumers and stable dependencies (request/response is simpler)
- When exactly-once end-to-end semantics are genuinely required and cannot be handled with idempotency

**Kafka vs. SQS vs. EventBridge (AWS-specific):**
- Use **Kafka/Redpanda** when you need partitioned ordering, high throughput, long retention, or event sourcing
- Use **SQS** for simple async decoupling, background job queues, and Lambda integration
- Use **EventBridge** for cross-service routing based on event patterns and SaaS integration — but note it does not guarantee ordering
- Use **EventBridge Pipes + SQS FIFO** when you need ordered EventBridge-style routing

## State of the art

EDA is the default integration pattern for microservices at scale in 2026. Kafka remains the dominant choice for high-throughput event streaming; Redpanda (Kafka-compatible, no ZooKeeper) has grown significantly for teams wanting simpler operations with Kafka semantics.

AsyncAPI 3.0 (2024) and growing tooling ecosystem position it as the contract standard for event-driven APIs, replacing ad-hoc documentation. Schema registries (Confluent, AWS Glue) are standard practice for teams with more than a handful of event types.

The research front: arXiv:2512.16146 (2025) provides a systematic analysis of Kafka event-streaming design patterns and benchmark practices, establishing a reference taxonomy for production Kafka architectures.

AI-era implications: event streams are the natural data source for real-time agent context, [[feature-stores|feature store]] streaming pipelines, and audit trails for agent decision tracing ([[ai-agent-observability]]).

## Pitfalls & anti-patterns

**Ignoring idempotency.** Assuming at-most-once delivery when the broker provides at-least-once. Every consumer must be designed for duplicates from day one.

**Skipping the outbox pattern.** Publishing events after database writes without atomicity. Silent event loss on crash; inconsistent distributed state.

**Schema anarchy.** Evolving event schemas without a registry or compatibility rules. Downstream consumers break on schema changes; impossible to detect until runtime.

**Choreography sprawl.** Distributing all business logic across choreographed event handlers until no single engineer can understand the full flow. Bounded use of choreography; orchestrate complex sagas.

**EventBridge for ordered flows.** EventBridge has no ordering guarantee. Using it where message order matters produces subtle, hard-to-reproduce bugs.

**Unbounded consumer lag.** Building consumers that fall behind under load without monitoring consumer group lag. A consumer that's 10 million events behind provides no value and may never catch up.

## See also

- [[cloud-native-patterns]]
- [[serverless-architecture]]
- [[streaming-and-event-data]]
- [[event-sourcing-and-cqrs]]
- [[domain-driven-design]]
- [[api-styles-and-protocols]]
- [[distributed-systems-reliability]]
- [[ai-agent-observability]]

## Sources

- Encore. (2026). Event-Driven Architecture in 2026: Patterns, Tools, and When to Use It. https://encore.dev/resources/event-driven-architecture
- Digital Applied. (2026). Event-Driven Architecture & Message Queues: 2026 Reference. https://www.digitalapplied.com/blog/event-driven-architecture-message-queues-2026-engineering-reference
- Edana. (2025). Event-Driven Architecture: Kafka, RabbitMQ, SQS Real-Time. https://edana.ch/en/2025/07/19/event-driven-architecture-kafka-rabbitmq-sqs-why-your-systems-must-react-in-real-time/
- Leapcell. (n.d.). Orchestration vs. Choreography — Event-Driven Backend Integration. https://leapcell.io/blog/orchestration-vs-choreography-event-driven-backend-integration
- Redpanda. (n.d.). Event-Driven Architecture with Apache Kafka. https://www.redpanda.com/guides/kafka-use-cases-event-driven-architecture
- Tsoukalas, A., et al. (2025). Analysis of Design Patterns and Benchmark Practices in Apache Kafka Event-Streaming Systems. arXiv:2512.16146. https://arxiv.org/abs/2512.16146
