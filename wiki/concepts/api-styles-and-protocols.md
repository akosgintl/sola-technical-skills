---
title: API Styles and Protocols
aliases: [REST, GraphQL, gRPC, API styles]
type: concept
domain: integration
priority: P1
roadmap_ref: "6.1"
status: stub
tags: [integration, api, rest, graphql, grpc]
updated: 2026-06-19
sources: []
---

# API Styles and Protocols

> [!summary]
> The selection between API paradigms — REST, GraphQL, gRPC, and async/event APIs — based on the consumer needs, performance profile, and coupling each implies.

**Priority:** 🟠 P1 · **Domain:** [[tier-2-solid|Integration & API Architecture]] · **Roadmap:** §6.1

## What it is

API styles and protocols define how systems expose and consume capabilities. REST offers ubiquity and cacheability; GraphQL gives clients flexible queries over a typed graph; gRPC delivers high-performance typed RPC over HTTP/2; async/event APIs decouple producers and consumers. The architect's job is matching style to consumer and workload.

## Key concepts

- REST / HTTP and resource modeling
- GraphQL schema and query flexibility
- gRPC and Protocol Buffers
- Async / event-driven APIs (AsyncAPI)
- Selection criteria: latency, coupling, client diversity

## See also

- [[api-gateways-and-service-mesh]]
- [[coupling-and-versioning-discipline]]
- [[event-driven-architecture]]
- [[model-context-protocol]]

## Sources

- _Stub — no sources ingested yet._
