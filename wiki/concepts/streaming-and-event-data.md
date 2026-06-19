---
title: Streaming and Event Data
aliases: [streaming, event streaming, Kafka, Kinesis, Pub/Sub]
type: concept
domain: data
priority: P1
roadmap_ref: "5.2"
status: stub
tags: [data, streaming, events, kafka]
updated: 2026-06-19
sources: []
---

# Streaming and Event Data

> [!summary]
> Processing data as continuous, ordered streams of events in motion rather than static batches, enabling real-time pipelines and event-driven systems.

**Priority:** 🟠 P1 · **Domain:** [[tier-2-solid|Data Architecture]] · **Roadmap:** §5.2

## What it is

Streaming and event data architectures treat each change as an immutable event published to a durable log. Consumers process these events with low latency for analytics, integration, and reactive workflows. Platforms differ in ordering guarantees, retention, and delivery semantics (at-least-once vs. exactly-once).

## Key concepts

- Apache Kafka / AWS Kinesis / Google Pub/Sub
- Log-based messaging, partitions, and ordering
- Stream processing (Flink, Kafka Streams)
- Delivery semantics and backpressure
- Windowing and stateful processing

## See also

- [[event-sourcing-and-cqrs]]
- [[event-driven-architecture]]
- [[data-storage-paradigms]]
- [[data-governance-and-lineage]]
- [[distributed-systems-reliability]]

## Sources

- _Stub — no sources ingested yet._
