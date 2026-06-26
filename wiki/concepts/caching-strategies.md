---
title: Caching Strategies
aliases: [caching, cache, cache-aside, read-through, write-through, write-behind, semantic caching, cache invalidation, cache stampede, CDN caching]
type: concept
domain: cloud
status: mature
tags: [cloud, caching, performance, latency, redis, cdn, semantic-cache]
updated: 2026-06-26
sources:
  - "https://redis.io/docs/latest/develop/use-cases/cache-aside/"
  - "https://www.hellointerview.com/learn/system-design/core-concepts/caching"
  - "https://aws.amazon.com/builders-library/caching-challenges-and-strategies/"
  - "https://www.averagedevs.com/blog/caching-strategies-redis-cdn"
  - "https://pyimagesearch.com/2026/04/27/semantic-caching-for-llms-fastapi-redis-and-embeddings/"
---

# Caching Strategies

> [!summary]
> Caching keeps a cheaper-to-access copy of data closer to the consumer to cut latency and offload
> the system of record. Done well it is the highest-leverage performance and cost lever there is;
> done carelessly it is a source of subtle staleness bugs and a new failure mode. The discipline
> has three parts: **where** the cache sits (client → CDN/edge → application → distributed store →
> database), **which pattern** keeps it populated and consistent (cache-aside, read/write-through,
> write-behind), and **how it is invalidated** — the genuinely hard part ("there are only two hard
> things in computer science: cache invalidation and naming things"). Treat a cache as a primary
> architectural layer with explicit lifecycles, not a bolt-on `@cacheable`.

**Domain:** [[tier-1-edge|Cloud Architecture]]

## What it is

A cache trades **freshness and memory for speed and load reduction**: it stores the result of an
expensive operation (a query, a computation, a remote call, an LLM generation) so subsequent
requests can skip it. Good cache candidates are **read-heavy, expensive to produce, and tolerant of
some staleness**. The layers, outermost to innermost:

| Layer | Example | Wins | Watch out for |
|---|---|---|---|
| **Client / browser** | HTTP `Cache-Control`, local storage | Zero network | You can't invalidate it remotely |
| **CDN / edge** | Cloudflare, Fastly, CloudFront, edge KV | Global low latency, origin offload | Stale edge copies; purge propagation |
| **Reverse proxy / gateway** | Varnish, nginx, API gateway cache | Centralized HTTP caching | Cache-key correctness |
| **Application** | In-process / local (Caffeine, local LRU) | Fastest in-app | Per-instance inconsistency |
| **Distributed** | Redis, Memcached, ElastiCache | Shared across instances, large | Network hop; a dependency to operate |
| **Database** | Query cache, materialized views | Close to the data | Limited control; invalidation cost |

## Why it matters

Latency, cost, and scale are all bought with caching: a cache hit can be orders of magnitude
cheaper and faster than recomputing or re-fetching, and offloading reads is often what lets the
system of record scale at all. But every cache layer is a **second copy of the truth**, which means
a **consistency liability** (the copy can be stale) and a **new failure mode** (the cache itself can
be down, cold, or stampeded). The architectural decision is therefore never "should we add a cache"
in isolation — it is "what staleness can this read tolerate, how will we invalidate, and what
happens on a miss or a cache outage." Caching that ignores those questions converts a performance
optimization into a correctness and reliability problem.

## Key concepts / building blocks

### Read and write patterns

- **Cache-aside (lazy loading)** — the application checks the cache; on a miss it loads from the DB
  and populates the cache. The most common pattern; the cache only ever holds requested data.
  Downside: the first request always misses, and stale entries persist until invalidated/expired.
- **Read-through** — the cache library itself loads from the DB on a miss (transparent to the app).
- **Write-through** — writes go to the cache *and* the DB synchronously; the cache is always
  consistent with the last write, at the cost of write latency.
- **Write-behind (write-back)** — writes hit the cache and are flushed to the DB asynchronously;
  fastest writes, but risks data loss if the cache fails before flush.
- **Write-around** — writes go straight to the DB, bypassing the cache; good when written data isn't
  immediately re-read.
- **Refresh-ahead** — proactively refresh hot entries before they expire, hiding the miss latency.

A common production blend: **cache-aside for reads, write-through for critical updates,
refresh-ahead for hot keys.**

### Invalidation — the hard part

- **TTL / expiry** — simplest: entries expire after a set time. Trades guaranteed-eventual freshness
  for tolerated staleness; choosing the TTL is the whole game.
- **Explicit invalidation** — the writer deletes/updates the key on change. Fresh, but easy to miss a
  path and leave a stale entry.
- **Event-driven invalidation** — a change feed ([[saga-and-outbox-patterns|CDC]]) invalidates
  affected keys. Most accurate, most infrastructure.
- **Versioned / immutable keys** — embed a version or content hash in the key so a new version is a
  new key and old entries age out (the standard for static assets).

### Eviction and sizing

When the cache is full, an **eviction policy** decides what to drop: **LRU** (least recently used,
the default), **LFU** (least frequently used), **FIFO**, or pure TTL. An unbounded cache is a memory
leak; always set a max size and eviction policy.

### Failure modes

- **Cache stampede / thundering herd** — a popular key expires and thousands of concurrent requests
  miss and hit the origin at once. Mitigations: **request coalescing / single-flight** (one request
  recomputes, others wait), a **mutex lock** (Redis `SETNX`), and **probabilistic early expiration**
  (refresh slightly before TTL, jittered) so keys don't expire in lockstep.
- **Cache penetration** — requests for keys that don't exist bypass the cache and flood the DB.
  Mitigate with **negative caching** (cache the "not found") and **Bloom filters**.
- **Hot keys** — a single key receives disproportionate traffic, overloading one shard. Mitigate by
  replicating/splitting the key or adding a local tier in front.
- **Cold cache** — after a flush or deploy the hit rate is zero and the origin takes full load. Warm
  critical keys proactively.

### Semantic and prompt caching (the LLM twist)

LLM workloads add two cache types:

- **Prompt (KV) caching** — providers cache the model's state for a stable context prefix, cutting
  cost and latency dramatically on reuse. The economics and constraints (the prefix must be
  byte-stable) live in [[ai-gpu-economics]] and [[context-engineering]].
- **Semantic caching** — instead of an exact-key lookup, match a new query to a prior one by
  **embedding similarity**; on a near-match, return the cached answer. It cuts cost on repetitive,
  paraphrased queries but introduces a *relevance* risk (a "close enough" match that isn't), so it
  needs a tuned similarity threshold and an eval gate. Pairs with [[retrieval-augmented-generation]]
  and [[vector-and-embedding-stores]].

## Design decisions & trade-offs

- **Staleness tolerance sets the TTL — and whether to cache at all.** The first question is how stale
  a read may be. Stock price: seconds. Product catalog: minutes. A long TTL maximizes hit rate and
  minimizes load but widens the staleness window; a short TTL is the reverse. Name the tolerance per
  data type rather than picking a global TTL.
- **Cache-aside vs. write-through.** Cache-aside is simple and resilient (a cache miss just costs a DB
  read) but allows stale reads; write-through keeps the cache consistent at the cost of write latency
  and caching data that may never be read. Most systems mix them by data criticality.
- **Local vs. distributed.** In-process caches are the fastest but diverge across instances (each has
  its own copy); a distributed cache (Redis) is consistent across the fleet but adds a network hop and
  an operational dependency. A two-tier (local in front of distributed) blends both.
- **Closer is faster but harder to invalidate.** Pushing cache to the CDN/edge slashes latency but
  multiplies the copies you must purge and widens propagation delay. Trade reach against invalidation
  control.
- **Cache as availability crutch.** Serving a stale entry when the origin is down is a legitimate
  [[distributed-systems-reliability|graceful-degradation]] move — but it is a *correctness* decision
  to make deliberately, not a default.
- **Don't cache prematurely.** A cache is a distributed-systems liability with real failure modes.
  Measure first; cache the proven hot, expensive paths — not everything "to be safe."

## State of the art

- **Multi-tier caching is treated as a first-class architectural layer** with defined lifecycles and
  explicit invalidation, driven by edge computing, real-time APIs, and AI workloads.
- **Redis remains the dominant distributed cache**; CDNs (Cloudflare/Fastly/CloudFront) plus edge
  KV/compute push caching to the edge — adjacent to [[wasm-at-the-edge]].
- **Stampede protection is standard**: single-flight/request coalescing and probabilistic early
  expiration are common library features rather than bespoke code.
- **Semantic caching for LLMs** (embedding-similarity match, often Redis-backed) is an emerging cost
  lever for high-volume, repetitive AI traffic — feeding [[ai-gpu-economics]] and
  [[cost-optimization-practice]].

## Pitfalls & anti-patterns

- **No invalidation strategy.** Relying on vibes or a guessed TTL, leaving stale data indefinitely.
  Decide TTL/explicit/event-driven invalidation per data type up front.
- **Unprotected stampede.** A hot key expiring with no coalescing turns one miss into a self-inflicted
  origin DDoS.
- **Caching everything / premature caching.** Adding caches before measuring, inheriting all the
  consistency and failure liabilities for paths that weren't hot anyway.
- **Unbounded cache.** No max size or eviction policy → memory exhaustion.
- **Treating the cache as source of truth.** A cache must be reconstructable; data that exists *only*
  in the cache is lost on a flush or eviction.
- **Read-your-writes violations.** A user updates data but a stale cache shows the old value — a
  classic, confidence-eroding bug. Invalidate (or write-through) on the user's own writes.
- **Per-user dynamic content with a shared key.** Destroys hit rate (or leaks data across users).
  Key by the right dimensions; mirror of the prompt-cache "stable prefix" rule in [[ai-gpu-economics]].

## See also

- [[cloud-native-patterns]]
- [[ai-gpu-economics]]
- [[context-engineering]]
- [[retrieval-augmented-generation]]
- [[api-gateways-and-service-mesh]]
- [[distributed-systems-reliability]]
- [[cost-optimization-practice]]

## Sources

- [Redis — Cache-aside pattern](https://redis.io/docs/latest/develop/use-cases/cache-aside/)
- [Hello Interview — Caching for System Design](https://www.hellointerview.com/learn/system-design/core-concepts/caching)
- [Amazon Builders' Library — Caching challenges and strategies](https://aws.amazon.com/builders-library/caching-challenges-and-strategies/)
- [AverageDevs — Advanced Caching: Redis, CDNs, and Cache Invalidation at Scale](https://www.averagedevs.com/blog/caching-strategies-redis-cdn)
- [PyImageSearch — Semantic Caching for LLMs: FastAPI, Redis, and Embeddings (2026)](https://pyimagesearch.com/2026/04/27/semantic-caching-for-llms-fastapi-redis-and-embeddings/)
