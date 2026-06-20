---
title: API Styles and Protocols
aliases: [REST, GraphQL, gRPC, API styles, API design, AsyncAPI, webhooks]
type: concept
domain: integration
status: mature
tags: [integration, api, rest, graphql, grpc, asyncapi, webhooks, websockets, protobuf]
updated: 2026-06-20
sources:
  - "https://devstarsj.github.io/2026/03/17/graphql-vs-rest-vs-grpc-comparison-2026/"
  - "https://www.javacodegeeks.com/2026/02/graphql-vs-rest-vs-grpc-the-2026-api-architecture-decision.html"
  - "https://wundergraph.com/blog/graphql-vs-federation-vs-trpc-vs-rest-vs-grpc-vs-asyncapi-vs-webhooks"
  - "https://pockit.tools/blog/rest-graphql-trpc-grpc-api-comparison-2026/"
  - "https://www.digitalapplied.com/blog/graphql-vs-rest-2026-api-architecture-decision-matrix"
  - "https://www.carrierintegrations.com/asyncapi-vs-webhook-hell-why-73-of-european-carrier-integrations-are-moving-to-event-driven-standards-in-2025/"
---

# API Styles and Protocols

> [!summary]
> The selection between API paradigms — REST, GraphQL, gRPC, and async/event protocols — based on consumer needs, performance requirements, and coupling implications. In 2026 the answer is rarely one-size-fits-all: public APIs default to REST (83% of public APIs), internal microservice communication to gRPC (60–80% bandwidth reduction), and frontend-to-BFF to GraphQL or tRPC. The architect's job is to match style to context and resist chasing trends.

**Domain:** [[tier-2-solid|Integration & API Architecture]]

## What it is

An API style defines the communication contract between a producer (the service) and a consumer (client, other service, or agent). The choice encodes assumptions about coupling, payload format, transport, and whether the interaction is synchronous (request/response) or asynchronous (fire-and-forget, streaming).

The main styles in 2026:
- **REST** — resource-oriented HTTP; the dominant public API style
- **GraphQL** — client-defined queries over a typed schema; dominant for flexible client-driven APIs
- **gRPC** — typed RPC over HTTP/2 with Protobuf; dominant for high-performance internal service-to-service
- **AsyncAPI / webhooks** — async push; event-driven integration without polling
- **WebSockets** — bidirectional persistent connections; real-time push
- **tRPC** — end-to-end type-safe RPC for TypeScript stacks; emerging alternative in full-stack JS

## Why it matters

API design decisions propagate through the entire system. A REST API chosen for an internal service-to-service integration carries JSON parsing overhead, HTTP/1.1 limitations, and loose typing that gRPC avoids. A GraphQL API chosen for a simple CRUD endpoint adds a schema layer, a query parser, and resolver complexity that REST doesn't. Wrong choices are expensive to undo because they cross service and team boundaries.

## Key concepts / building blocks

### REST (Representational State Transfer)

**How it works:** Resources modeled as URLs; state transferred via standard HTTP verbs (GET, POST, PUT, PATCH, DELETE). Responses are typically JSON. Stateless — each request carries all necessary context.

**Strengths:**
- Universal support (every HTTP client, every browser, every language)
- Human-readable URLs and payloads; easy to debug with cURL
- Cacheability at the HTTP layer (GET responses cacheable by CDNs, proxies)
- No tooling dependency — no code generation required
- 83% of public APIs use REST (2026)

**Weaknesses:**
- Over-fetching (endpoint returns more data than the client needs) and under-fetching (client needs data from multiple endpoints)
- No strict schema enforcement (OpenAPI specs help but are optional)
- JSON parsing overhead vs. binary protocols
- HTTP/1.1 multiplexing limitations (mitigated by HTTP/2)

**Best fit:** public-facing APIs with diverse consumer types, simple CRUD APIs, APIs consumed by browsers, any context where client diversity outweighs performance concerns.

### GraphQL

**How it works:** A single endpoint; clients submit declarative queries describing exactly which fields they need across any depth of the data graph. The server resolves only what was requested. A typed schema (`schema.graphql`) defines all types and their relationships.

**Strengths:**
- Eliminates over-fetching and under-fetching — clients get exactly what they ask for
- Single endpoint for the entire API surface; no endpoint proliferation
- Strongly typed schema as the API contract; introspection enables code generation
- Excellent for mobile clients where bandwidth matters
- 61%+ of organizations use GraphQL in production (up from <10% in 2021)

**Weaknesses:**
- Schema design discipline required; bad schemas produce N+1 query problems
- Caching is harder than REST (query-dependent; requires persisted queries or APQ)
- Introspection can expose the full API surface to attackers (disable in prod or use depth limits)
- Overkill for simple, stable data models

**Best fit:** BFF (Backend for Frontend) layers serving multiple client types (web + mobile + TV), complex data graphs with deep relationships, teams where frontend teams define their own data requirements.

**GraphQL Federation** (Apollo Federation, WunderGraph Cosmo) — composes multiple downstream GraphQL subgraphs into one unified schema. Used at scale when different teams own different parts of the data graph.

### gRPC

**How it works:** Typed remote procedure calls over HTTP/2 using Protocol Buffers (Protobuf) for serialization. `.proto` files define the service contract; code generators produce clients and servers in any supported language.

**Strengths:**
- Binary Protobuf: 60–80% bandwidth reduction vs. JSON for equivalent payloads
- HTTP/2 native: multiplexing, header compression, bidirectional streaming
- Strong contract enforcement via generated code; breaking changes fail at compile time
- First-class streaming: server-streaming, client-streaming, bidirectional streaming
- Low latency: the de facto standard for internal microservice communication at Netflix, Uber, Google

**Weaknesses:**
- Protobuf requires a build toolchain and `.proto` file management across services
- Not human-readable (binary encoding); gRPC-specific tooling required for debugging
- Limited browser support (grpc-web is a workaround, not native)
- Schema evolution requires care (backward compatibility rules for Protobuf fields)

**Best fit:** internal service-to-service communication where performance matters, polyglot microservices teams, streaming data flows between backend services, any internal API with >50 req/s where JSON overhead is material.

### AsyncAPI and webhooks

**Webhooks:** HTTP callbacks — the server POSTs to a URL when an event occurs. Simple to implement; fragile at scale (no retry semantics, no delivery guarantee, no ordering, no standard contract). 73% of European carrier integrations are moving away from ad-hoc webhooks to AsyncAPI-based event standards (2025).

**AsyncAPI:** the specification standard for describing event-driven APIs (analogous to OpenAPI for REST). Supports Kafka, MQTT, AMQP, WebSockets, and webhooks as underlying transports. Enables contract-first development for async APIs — consumer and producer teams agree on message schemas before implementation. Version 3.0 (2024) is the current standard.

**When to use async over sync:**
- Consumer doesn't need an immediate response
- The operation takes >500 ms (async avoids holding a connection)
- Multiple consumers need the same event independently (pub/sub vs. point-to-point)
- See [[event-driven-architecture]] for the full treatment

### WebSockets

Bidirectional persistent TCP connection over HTTP; the server can push data without a client poll. Use for: real-time chat, live dashboards, collaborative editing, live game state, real-time agent output streaming.

**Not a general-purpose API replacement** — WebSockets carry connection state and are harder to load-balance and scale than stateless HTTP. Use specifically when push latency matters and you cannot tolerate polling.

### API selection decision matrix

| Situation | Recommended style | Reason |
|---|---|---|
| Public API with diverse consumers | REST | Universality, cacheability, no toolchain |
| Internal microservice to microservice | gRPC | Binary efficiency, streaming, strong typing |
| BFF serving multiple client types | GraphQL | Eliminates over/under-fetching; client-driven |
| Full-stack TypeScript app | tRPC | End-to-end type safety; no schema file |
| Long-running operation (>500 ms) | Async (AsyncAPI + broker) | Don't hold HTTP connections; decouple |
| Real-time push (chat, live data) | WebSockets | Bidirectional, low-latency push |
| Event notification to external systems | Webhooks (or AsyncAPI) | Push-based; avoid polling |
| Agent-to-tool invocation | [[model-context-protocol\|MCP]] | Structured tool-use protocol for LLM agents |

### The hybrid architecture reality

The best teams in 2026 use multiple protocols by layer:
```
Public API:           REST (OpenAPI spec, versioned)
Frontend → BFF:       GraphQL or tRPC  
Service → Service:    gRPC (Protobuf contracts)
Async events:         AsyncAPI (Kafka, SQS, Pub/Sub)
Real-time push:       WebSockets
```

This is not complexity for its own sake — each layer has a different performance, consumer, and coupling profile that makes a different protocol optimal.

## Design decisions & trade-offs

**REST vs. GraphQL for public APIs:**
GraphQL's flexibility is valuable when client diversity is high (web, mobile, TV, third-party developers). It is over-engineering when: you have one client type, the data model is simple and stable, or caching is critical (CDN caching of REST GET responses is trivial; GraphQL caching is query-dependent and complex).

**gRPC vs. REST for internal services:**
Default to gRPC for new internal services where the team can adopt the Proto toolchain. Use REST internally only when: one side is a browser, the team cannot adopt the toolchain, or an existing REST API is already in place and migration cost exceeds the performance benefit.

**Webhooks vs. polling:**
Both are worse than a managed event bus (see [[event-driven-architecture]]). Webhooks are point-to-point and fragile; polling wastes resources. If you're designing a new integration pattern, prefer AsyncAPI + a broker. Webhooks are only the right answer when you're integrating with external third-party systems that only offer webhooks.

**Schema evolution:**
- REST/JSON: additive changes are safe (add fields); breaking changes require API versioning (v1/v2 path prefix or Accept header versioning)
- gRPC/Protobuf: field numbers are the contract; never reuse field numbers; adding new optional fields is backward-compatible
- GraphQL: additive changes safe; deprecate fields rather than removing; schema registry enforces compatibility

## State of the art

REST remains the dominant public API style (83% of public APIs in 2026). GraphQL crossed 61% enterprise production adoption, primarily as a BFF layer. gRPC is the de facto standard for internal service-to-service at high-throughput organizations (Netflix, Uber, Google, Cloudflare).

AsyncAPI 3.0 (2024) has become the contract standard for event-driven APIs, with tooling (code generators, mock servers, validation) now comparable to the OpenAPI ecosystem. The WunderGraph / Apollo Federation ecosystem has matured, making GraphQL federation production-viable for large organizations with multi-team API surfaces.

**MCP ([[model-context-protocol]])** is the emerging protocol for AI agent-to-tool communication — effectively gRPC semantics (typed, structured, tool-invocation) adapted for LLM agent contexts. Worth tracking as the "API style for agents" story matures.

## Pitfalls & anti-patterns

**REST for everything, including internal high-throughput.** Choosing REST for service-to-service calls at >100 req/s where JSON parsing overhead is material. gRPC's binary encoding pays for itself quickly.

**GraphQL for simple stable data.** Adding schema + resolver + introspection complexity for a CRUD API that has one client and three fields. REST is simpler.

**Webhooks without retry semantics.** Delivering business-critical events via webhooks with no delivery confirmation, retry logic, or dead-letter handling. Webhooks will fail silently; treat them as unreliable.

**One endpoint per relationship in REST (under-fetching).** Requiring clients to make 5 sequential API calls to render one screen is a REST design failure. Fix the API design (composite endpoints, embedding) rather than treating N+1 as inevitable.

**Breaking changes without versioning.** Removing or renaming fields in a REST or GraphQL API consumed by external parties. Version the API; maintain the old version for a documented deprecation period.

## See also

- [[api-gateways-and-service-mesh]]
- [[coupling-and-versioning-discipline]]
- [[event-driven-architecture]]
- [[model-context-protocol]]
- [[cloud-native-patterns]]

## Sources

- DevStarSJ. (2026). GraphQL vs REST vs gRPC in 2026: Choosing the Right API. https://devstarsj.github.io/2026/03/17/graphql-vs-rest-vs-grpc-comparison-2026/
- Java Code Geeks. (2026). GraphQL vs. REST vs. gRPC: The 2026 API Architecture Decision. https://www.javacodegeeks.com/2026/02/graphql-vs-rest-vs-grpc-the-2026-api-architecture-decision.html
- WunderGraph. (2024). When to use GraphQL vs Federation vs tRPC vs REST vs gRPC vs AsyncAPI vs WebHooks. https://wundergraph.com/blog/graphql-vs-federation-vs-trpc-vs-rest-vs-grpc-vs-asyncapi-vs-webhooks
- Pockit. (2026). REST vs GraphQL vs tRPC vs gRPC in 2026: The Definitive Guide. https://pockit.tools/blog/rest-graphql-trpc-grpc-api-comparison-2026/
- Digital Applied. (2026). GraphQL vs REST 2026: API Architecture Decision Matrix. https://www.digitalapplied.com/blog/graphql-vs-rest-2026-api-architecture-decision-matrix
- Carrier Integrations. (2025). AsyncAPI vs Webhook Hell: Why 73% of European Integrations Are Moving to Event-Driven Standards. https://www.carrierintegrations.com/asyncapi-vs-webhook-hell-why-73-of-european-carrier-integrations-are-moving-to-event-driven-standards-in-2025/
