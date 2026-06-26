---
title: Streaming and Event Data
aliases: [streaming, event streaming, Kafka, Kinesis, Pub/Sub, Flink, stream processing]
type: concept
domain: data
status: mature
tags: [data, streaming, events, kafka, flink, kinesis, windowing, exactly-once]
updated: 2026-06-20
sources:
  - "https://www.confluent.io/learn/apache-flink/"
  - "https://www.onehouse.ai/blog/apache-spark-structured-streaming-vs-apache-flink-vs-apache-kafka-streams-comparing-stream-processing-engines"
  - "https://nightlies.apache.org/flink/flink-docs-stable/docs/concepts/stateful-stream-processing/"
  - "https://oneuptime.com/blog/post/2026-02-20-streaming-kafka-flink/view"
  - "https://www.conduktor.io/glossary/what-is-apache-flink-stateful-stream-processing"
---

# Streaming and Event Data

> [!summary]
> Streaming architectures treat each data change as an immutable event published to a durable log, processed continuously with low latency rather than periodically in batches. The canonical stack is Kafka as the durable event backbone and Apache Flink as the stateful stream processor. The architect's decisions center on delivery semantics (at-least-once vs. exactly-once), windowing strategy (event-time vs. processing-time), and when streaming genuinely justifies its operational cost over batch.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

Streaming and batch are two answers to the same question: "how do we process data that keeps arriving?" Batch accumulates data and processes it periodically (every hour, every night); streaming processes each event as it arrives, typically within milliseconds to seconds.

The key architectural choice is the **event log** — an immutable, ordered, durable sequence of events that consumers read at their own pace. Unlike a queue (where messages are deleted after consumption), an event log retains events for a configurable period, allowing multiple independent consumers, replay of historical data, and time-travel debugging.

Streaming architectures fit workloads requiring:
- **Real-time analytics** — dashboards, fraud detection, anomaly detection where latency matters
- **Event-driven integration** — services reacting to changes in other services without polling
- **Data pipeline enrichment** — joining, aggregating, or transforming events in flight before they land in a warehouse or lakehouse
- **Continuous ETL** — replacing nightly batch jobs with continuous low-latency ingestion

## Why it matters

Batch pipelines introduce latency equal to their batch interval. For fraud detection, "we'll check in an hour" means the fraud succeeds. For real-time dashboards, "we'll update at midnight" means the operational team is flying blind. For microservice integration, batch polling creates tight temporal coupling and wasted load.

Streaming reduces data latency from hours to seconds, which is not always necessary but is frequently the capability gap that blocks real-time products. The cost: streaming adds operational complexity, requires rethinking consistency models, and demands more expertise than batch ETL.

## Key concepts / building blocks

### The event log model

The event log (exemplified by Apache Kafka) differs from traditional message queues in four ways:
1. **Durability** — events are written to disk, replicated across brokers, and retained for a configurable period (hours, days, indefinitely)
2. **Multiple consumers** — any number of consumer groups can read the same log independently, each at their own offset
3. **Replay** — consumers can seek backward and re-read events from any point; enables reprocessing on schema changes or bug fixes
4. **Ordering** — events within a partition are totally ordered; ordering across partitions requires additional coordination

**Partitioning:** Kafka partitions distribute a topic across brokers for parallelism. Events with the same key always go to the same partition (ordering guarantee per key). Consumer group members each claim one or more partitions. Throughput scales by adding partitions; adding consumers beyond the partition count has no effect.

### Streaming platforms

| Platform | Positioning | Retention | Ordering | Managed offering |
|---|---|---|---|---|
| **Apache Kafka** | High-throughput durable log; de facto standard | Configurable (hours → indefinite) | Per-partition total order | Confluent Cloud, MSK (AWS), HDInsight |
| **AWS Kinesis Data Streams** | AWS-native streaming; simpler ops than Kafka | 1–365 days | Per-shard total order | Fully managed |
| **Google Pub/Sub** | GCP-native; global; at-least-once default | 7–31 days | No ordering guarantee (Pub/Sub Lite: per-partition) | Fully managed |
| **Azure Event Hubs** | Azure-native; Kafka-compatible protocol | 1–90 days | Per-partition total order | Fully managed; Kafka endpoint |
| **Apache Pulsar** | Multi-tenant; tiered storage; geo-replication | Tiered (hot/warm/cold) | Per-partition total order | StreamNative Cloud |

**Kafka vs. managed queues:** Kafka is operationally complex but delivers the highest throughput (millions of events/sec per cluster), configurable retention, and replay. Managed cloud queues (SQS, Pub/Sub, Event Hubs) are operationally simpler but trade some flexibility. For greenfield cloud-native work, Confluent Cloud or AWS MSK reduces Kafka's operational burden while preserving its capabilities.

### Delivery semantics

The three delivery guarantees, in increasing reliability and cost:

**At-most-once:** events may be lost; never duplicated. Lowest overhead. Appropriate for metrics where occasional loss is acceptable (UDP-style telemetry).

**At-least-once:** events are guaranteed to be delivered but may be duplicated on retry or reprocessing. The standard for most event-driven systems. Requires consumers to be idempotent (process the same event twice without side effects).

**Exactly-once:** no loss, no duplication. Kafka provides exactly-once semantics for Kafka-to-Kafka flows via the transactional producer API (introduced in Kafka 0.11). Extending exactly-once to external sinks (databases, APIs) requires idempotent writes on the sink side — the messaging system can guarantee at-most-once delivery to the sink, but idempotency of the sink is necessary for the full guarantee.

> [!warning]
> "Exactly-once" in Kafka means exactly-once within Kafka's transaction boundary. Writing to an external database or API requires the sink to be idempotent. True end-to-end exactly-once requires both Kafka transactions AND idempotent external writes.

### Stream processing engines

Stream processing applies transformations, joins, aggregations, and enrichments to event streams in flight.

**Apache Flink** — the dominant stateful stream processor for production workloads. Key capabilities:
- **Event-time semantics** — processes events by when they occurred (event timestamp), not when they arrived at the processor, correctly handling out-of-order events
- **Checkpointing** — periodic consistent snapshots of all operator state to durable storage (Chandy-Lamport algorithm); enables exactly-once processing and fault recovery by replaying input from the last checkpoint
- **Savepoints** — manually triggered checkpoints; enable planned maintenance, version upgrades, and A/B deployments of streaming jobs
- **Watermarks** — signals that declare "all events with timestamp ≤ T have arrived"; determines when to close time windows and emit results
- **Rich windowing** — tumbling (fixed non-overlapping), sliding (overlapping), session (gap-based), and global windows

**Kafka Streams** — a Java library (not a separate cluster) for stream processing that runs inside your application. Simpler operations than Flink (no cluster to manage); best for moderate-complexity processing tightly coupled to Kafka.

**Apache Spark Structured Streaming** — micro-batch model; processes events in small time windows (trigger every N seconds or milliseconds). Good for teams already invested in Spark; higher latency than Flink's true streaming.

| Dimension | Flink | Kafka Streams | Spark Structured Streaming |
|---|---|---|---|
| Processing model | True streaming | True streaming | Micro-batch |
| Latency | Milliseconds | Milliseconds | Seconds |
| State | Rich managed state | RocksDB per partition | Limited |
| Operations | Separate cluster | Embedded in app | Spark cluster |
| Best for | Complex stateful pipelines | Moderate Kafka-native processing | Spark-invested teams |

### Windowing and stateful processing

Streaming jobs often need to aggregate over time. Windows define how to group events:

| Window type | Definition | Example use |
|---|---|---|
| Tumbling | Fixed, non-overlapping intervals (0:00–1:00, 1:00–2:00) | Revenue per minute |
| Sliding | Fixed size, slides by step (0:00–5:00, 1:00–6:00) | Moving average |
| Session | Events grouped by inactivity gap (session ends after 30s without events) | User session analytics |

**Event time vs. processing time:** always prefer event time (the time embedded in the event) over processing time (the time the processor received the event). Network delays and consumer lag mean processing time is unreliable for ordering. Watermarks handle late-arriving events; configure a maximum allowed lateness beyond which events are dropped or routed to a side output.

**State backends:** Flink's stateful operations (windowed aggregations, joins, pattern matching) store state in configurable backends. RocksDB (local disk) is the default for large state; in-memory for small state. State is checkpointed to remote storage (S3, HDFS) on each checkpoint.

### Backpressure

When a consumer processes slower than the producer produces, events accumulate. Proper streaming systems propagate backpressure upstream (Flink does this automatically): the slow stage signals the fast stage to produce more slowly. Without backpressure, the event log fills, memory is exhausted, or events are dropped.

In Kafka terms: backpressure is managed by consumer lag monitoring. Alert when consumer group lag grows beyond a threshold — the consumer cannot keep up with the producer rate.

## Design decisions & trade-offs

**Streaming vs. batch: the honest decision**

| Condition | Recommendation |
|---|---|
| Latency requirement >1 hour | Batch; streaming adds complexity without payoff |
| Multiple consumers need the same events independently | Streaming log (vs. queue per consumer) |
| Need to replay history for reprocessing or new consumers | Streaming with log retention |
| Complex stateful enrichment with sub-minute latency | Flink |
| Simple event-driven integration without aggregation | Event-driven architecture (SQS, Pub/Sub) — see [[event-driven-architecture]] |

**Partition count planning:** partitions are the unit of parallelism in Kafka. Under-partitioned topics become throughput bottlenecks that cannot be fixed without repartitioning (a disruptive operation). Over-partitioned topics waste resources and increase end-to-end latency. Rule of thumb: plan for 3–4× expected throughput at launch; Kafka's recommended maximum is ~4000 partitions per broker.

**Schema evolution:** streaming pipelines are long-running; event schemas will change. Always use a schema registry (Confluent Schema Registry, AWS Glue Schema Registry) with Avro or Protobuf. Enforce backward-compatible schema evolution: add optional fields, never remove or rename required fields without a versioned migration.

## State of the art

Kafka remains the dominant event streaming backbone in 2026, with Confluent Cloud and AWS MSK making it operationally accessible for teams without Kafka expertise. Apache Flink has matured into the production-grade stateful processing standard, used by Uber, Netflix, Alibaba, and Apple.

**Flink SQL and the streaming lakehouse:** Flink 1.18+ ships Flink SQL, a dialect that makes streaming joins and aggregations accessible without Java/Scala. Combined with Iceberg or Delta Lake as the sink, Flink enables continuous incremental writes to a lakehouse — replacing daily batch ingestion with sub-minute freshness. See [[data-storage-paradigms]] and [[ai-data-fabric]].

**RisingWave** and **Materialize** are emerging stream processing systems targeting SQL-centric teams who want streaming semantics without Flink's operational complexity.

## Pitfalls & anti-patterns

**Streaming everything.** Batch is simpler and cheaper for workloads that tolerate latency. Streaming adds operational burden; justify it with a concrete latency requirement.

**Ignoring consumer lag.** A streaming pipeline that falls behind its input rate silently accumulates lag until it causes an incident. Monitor consumer group lag as a primary health metric; alert before it becomes problematic.

**Processing-time windows.** Using processing time instead of event time for windowed analytics. Out-of-order events (common with mobile clients, distributed producers) produce incorrect results. Use event time + watermarks.

**No schema registry.** Evolving event schemas without a schema registry and compatibility enforcement. A single incompatible schema change breaks all consumers.

**Not accounting for reprocessing.** Streaming jobs will fail and need to restart. Design consumers to handle reprocessing from the last checkpoint: idempotent writes, exactly-once where necessary. Stateless consumers are the simplest to reprocess; stateful consumers require savepoints for planned changes.

## See also

- [[event-sourcing-and-cqrs]]
- [[event-driven-architecture]]
- [[data-storage-paradigms]]
- [[data-pipelines-and-orchestration]]
- [[data-governance-and-lineage]]
- [[distributed-systems-reliability]]
- [[ai-data-fabric]]

## Sources

- Confluent. (2026). What Is Apache Flink? Architecture & Use Cases. https://www.confluent.io/learn/apache-flink/
- Onehouse. (2026). Spark Structured Streaming vs. Apache Flink vs. Kafka Streams — Comparing Stream Processing Engines. https://www.onehouse.ai/blog/apache-spark-structured-streaming-vs-apache-flink-vs-apache-kafka-streams-comparing-stream-processing-engines
- Apache Flink. (2026). Stateful Stream Processing. https://nightlies.apache.org/flink/flink-docs-stable/docs/concepts/stateful-stream-processing/
- OneUptime. (2026). How to Build Real-Time Data Pipelines with Kafka and Flink. https://oneuptime.com/blog/post/2026-02-20-streaming-kafka-flink/view
- Conduktor. (2026). What Is Apache Flink? Stateful Stream Processing. https://www.conduktor.io/glossary/what-is-apache-flink-stateful-stream-processing
