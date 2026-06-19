---
title: Event-Driven Architecture
aliases: [EDA, event driven]
type: concept
domain: cloud
priority: P0
roadmap_ref: "2.3.1"
status: stub
tags: [cloud, events, messaging, architecture]
updated: 2026-06-19
sources: []
---

# Event-Driven Architecture

> [!summary]
> An architectural style where components communicate by producing and reacting to events, enabling loose coupling, asynchronous scale, and temporal decoupling between producers and consumers.

**Priority:** 🔴 P0 · **Domain:** [[tier-1-edge|Cloud Architecture]] · **Roadmap:** §2.3.1

## What it is

Event-driven architecture (EDA) replaces direct request/response calls with events that producers emit and consumers subscribe to, often through a broker or event bus. This decouples services in time and dependency, allowing each to scale and evolve independently. It introduces its own challenges around ordering, idempotency, delivery guarantees, and eventual consistency.

## Key concepts

- Producers, consumers, and brokers
- Pub/sub vs. event streaming
- Delivery semantics and idempotency
- Choreography vs. orchestration
- Eventual consistency

## See also

- [[cloud-native-patterns]]
- [[serverless-architecture]]
- [[streaming-and-event-data]]
- [[event-sourcing-and-cqrs]]
- [[api-styles-and-protocols]]

## Sources

- _Stub — no sources ingested yet._
