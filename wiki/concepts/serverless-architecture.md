---
title: Serverless Architecture
aliases: [serverless, FaaS, functions-as-a-service, scale-to-zero, BaaS]
type: concept
domain: cloud
status: mature
tags: [cloud, serverless, faas, lambda, cold-start, scale-to-zero, cost]
updated: 2026-06-20
sources:
  - "https://middleware.io/blog/serverless-architecture/"
  - "https://blog.madrigan.com/en/blog/202606091637/"
  - "https://witechpedia.com/wiki/serverless-computing-architecture/"
  - "https://mmcommunications.vn/en/serverless-architecture-web-development-guide-n603"
---

# Serverless Architecture

> [!summary]
> Building systems from event-triggered, fully managed compute (Functions-as-a-Service) and managed backing services where the provider handles all provisioning, scaling, and patching. Serverless scales to zero when idle and bills by execution time, making it economically superior for spiky, event-driven, and low-to-medium throughput workloads. The trade-offs — cold starts, statelessness, execution time limits, and vendor lock-in — become architectural constraints to design around rather than problems to solve.

**Domain:** [[tier-1-edge|Cloud Architecture]]

## What it is

Serverless architecture has two components:

**Functions-as-a-Service (FaaS)** — compute units that execute in response to a trigger (HTTP request, queue message, scheduled timer, storage event), scale automatically from zero to thousands of concurrent executions, and are billed per invocation and execution duration. AWS Lambda, Azure Functions, Google Cloud Functions, and Cloudflare Workers are the dominant FaaS platforms.

**Backend-as-a-Service (BaaS)** — fully managed services that replace traditionally self-operated infrastructure: databases (DynamoDB, Firestore, PlanetScale), queues (SQS, Pub/Sub), storage (S3, Blob Storage), authentication (Cognito, Auth0), and search. Serverless architectures compose FaaS + BaaS into a system with near-zero operational surface area.

> Serverless does not mean "no servers" — it means the developer does not manage servers. The provider's servers execute the code.

## Why it matters

**Pay per use economics** — a serverless function that handles 1,000 requests/day costs fractions of a cent per month in compute. A containerized service running idle 23 hours/day costs the same as one running at capacity. For spiky, event-driven, or low-baseline workloads, serverless eliminates idle compute spend entirely.

**Operational elimination** — no OS patching, no capacity planning, no cluster management. For teams without dedicated infrastructure engineers, serverless dramatically reduces time-to-first-working-endpoint.

**Over 70% of AWS users** run at least some production workloads on Lambda (Datadog State of Serverless, 2025), confirming it is no longer experimental.

## Key concepts / building blocks

### Execution model

A FaaS invocation lifecycle:
1. **Trigger** fires (HTTP, event, schedule, stream record)
2. Provider either reuses a **warm instance** (sub-millisecond initialization) or starts a **cold instance** (cold start: download container, start runtime, load code)
3. Function executes within its memory + CPU allocation
4. Execution ends; the instance is held warm briefly, then recycled

**Billing** is per GB-second: (memory allocated in GB) × (execution duration in seconds). A 1024 MB function running 500 ms costs the same as a 512 MB function running 1,000 ms.

### Cold starts

The cold start is the latency cost of initializing a new function instance. It varies by platform, runtime, and function size:

| Platform / runtime | Typical cold start |
|---|---|
| AWS Lambda (Node.js, Python) | 100–500 ms |
| AWS Lambda (Java) | 1–10 s |
| AWS Lambda SnapStart (Java) | <1 s (snapshot-based restore) |
| Google Cloud Functions 2nd gen | 100–400 ms |
| Cloudflare Workers (V8 isolates) | <5 ms (no container, no OS) |
| Azure Functions (Consumption) | 100 ms – 2 s |

Cold start mitigation strategies:
- **Provisioned concurrency** (Lambda) / **minimum instances** (Cloud Functions) — reserve warm instances; eliminates cold starts at cost of idle billing
- **Lightweight runtimes** — Go, Node.js, Python have faster cold starts than Java/JVM
- **Minimize package size** — load only required dependencies; use lazy imports
- **AWS Lambda SnapStart** — snapshots the initialized JVM state; restores in <1 s regardless of application size

> [!tip] Database connection pools are the real latency culprit
> For most 2026 applications, cold start is no longer the primary latency bottleneck — database connection establishment, dependency initialization, and large payload downloads are. Fix those first.

### Execution limits

FaaS platforms impose hard limits architects must design around:

| Constraint | AWS Lambda | Azure Functions (Consumption) | Cloud Functions |
|---|---|---|---|
| Max execution time | 15 minutes | 10 minutes (5 min default) | 60 minutes (2nd gen) |
| Max memory | 10 GB | 1.5 GB | 32 GB (2nd gen) |
| Max payload (sync) | 6 MB (request) / 256 KB (response via async) | 100 MB | 32 MB |
| Max concurrent executions | 1,000 (soft limit, raisable) | Variable | 1,000 per region |

For long-running tasks: use Step Functions / Durable Functions / Cloud Workflows to chain multiple function invocations across the time limit. For large payloads: pass references (S3 URLs, blob URIs) rather than raw data.

### Statelessness

FaaS functions are stateless by design: no guarantee that the next invocation runs on the same instance. All durable state must live in managed services:
- **Session state** → DynamoDB, ElastiCache/Redis, Firestore
- **Files / blobs** → S3, Blob Storage, GCS
- **Task state** → Step Functions, Durable Functions, workflow engines
- **Queue / buffer** → SQS, Pub/Sub

Statelessness is a feature: it enables horizontal scaling without coordination. Designs that require instance-local state (e.g., in-memory caches) must be re-architected.

### Scale-to-zero economics

The cost model favors serverless when:
- Traffic is spiky or unpredictable
- Baseline load is low (idle periods are long)
- Invocations are short (seconds, not minutes)

The cost model favors containers when:
- Traffic is high and sustained (always-on workloads)
- Invocations are long (approaching the time limit)
- The workload requires large memory or custom hardware (GPU inference, high-IOPS)

Rule of thumb: serverless is cheaper below ~1 million invocations/month at moderate memory; above that, benchmark against equivalent container costs.

### Serverless-first architecture pattern (2026)

The 2026 standard pattern combines FaaS with BaaS backends:

```
API Gateway → Lambda → DynamoDB
                    → SQS → Lambda (async processor)
                    → S3 (artifacts)
```

Variants:
- **Async with queuing**: API Gateway → Lambda (sync, validates, enqueues) → SQS → Lambda (async, heavy processing)
- **Event-sourced**: DynamoDB Streams → Lambda → downstream services
- **Scheduled**: EventBridge Scheduler → Lambda (cron jobs, periodic tasks)

## Design decisions & trade-offs

**Serverless vs. containers (ECS/EKS/Cloud Run):**

| Dimension | Serverless (FaaS) | Containers |
|---|---|---|
| Idle cost | Zero | Minimum reserved capacity |
| Cold start | Present | Startup time of service (configurable) |
| Execution limit | Hard (15 min Lambda) | None (long-running processes) |
| Memory limit | 10 GB (Lambda) | As much as the instance has |
| GPU workloads | Not supported | Supported |
| Stateful connections | Difficult | Natural |
| Ops burden | Near-zero | Moderate (even with managed k8s) |

**Cloud Run (GCP) and Azure Container Apps** are a useful middle ground: container-packaged (no execution time limits, larger payloads), but scale-to-zero and billed per request like serverless. Preferred when FaaS limits bind but operational simplicity is still required.

**Provisioned concurrency: when to use:**
Use when p99 latency SLA cannot tolerate cold start spikes, and the cost of reserved warm instances is justified by the traffic volume. For high-traffic APIs, provisioned concurrency on a subset of capacity (warm the minimum, scale into cold for burst) balances cost and latency.

**Monolithic function vs. micro-function:**
One large function vs. many small single-purpose functions. Micro-functions maximize the principle of least privilege (each function only has the permissions it needs) and enable independent scaling, but produce deployment complexity. Start with function-per-route or function-per-domain; split further only when scaling or security policy demands it.

## State of the art

Serverless adoption has matured past the experimental phase: >70% of AWS users run Lambda in production (Datadog, 2025). The 2026 focus is on **serverless-first full-stack architectures** that combine FaaS with vector databases, streaming pipelines, and AI inference endpoints — all fully managed.

Cold start improvements (Lambda SnapStart, Cloudflare Workers V8 isolates, GCF 2nd gen) have reduced cold start as a disqualifying factor. The remaining hard limits (execution time, memory, payload size) are the actual architectural constraints to evaluate.

The AI integration pattern is Lambda/Cloud Functions as the orchestration glue around AI API calls: inbound → Lambda (validates, routes) → Bedrock/OpenAI API → Lambda (post-processes) → DynamoDB. This pattern is economical because the token-generation time (the expensive wait) is provider-billed, not function-billed — the function is effectively idle during the LLM call.

## Pitfalls & anti-patterns

**In-process state.** Storing state in function-level variables or in-memory data structures and assuming they persist across invocations. They may, and they may not. Stateless-by-contract is the only correct mental model.

**Synchronous chains at scale.** Chaining multiple synchronous Lambda calls (A → B → C) via direct invocation. Latency accumulates additively; error handling becomes brittle; cold starts compound. Use SQS or Step Functions for multi-step flows.

**Ignoring connection pool limits.** Lambda can open thousands of concurrent DB connections. Without connection pooling (RDS Proxy, PgBouncer) or a serverless-compatible database (Aurora Serverless, PlanetScale), connection exhaustion is a common production failure.

**Underestimating cost at sustained high volume.** Serverless pricing is always-on at high request rates. Benchmark and compare against container costs before committing to serverless for sustained >100 req/s workloads.

**Unbounded fan-out.** A single Lambda invocation that triggers hundreds of child invocations (e.g., one S3 upload → process each line → one Lambda per line) can exhaust regional concurrency limits and produce cascading throttling.

## See also

- [[event-driven-architecture]]
- [[cloud-native-patterns]]
- [[kubernetes-at-design-level]]
- [[cloud-cost-modeling]]
- [[ai-gpu-economics]]
- [[distributed-systems-reliability]]

## Sources

- Middleware. (2026). Serverless Architecture in 2026: How It Works, Benefits. https://middleware.io/blog/serverless-architecture/
- Madrigan. (2026). Serverless 2025: Architectural Patterns for Resilient and High-Performance Systems. https://blog.madrigan.com/en/blog/202606091637/
- Witechpedia. (2026). Serverless Computing Architecture: The Complete FaaS Guide. https://witechpedia.com/wiki/serverless-computing-architecture/
- MM Communications. (2025). Serverless Architecture 2025: Complete Guide. https://mmcommunications.vn/en/serverless-architecture-web-development-guide-n603
