---
title: Observability Fundamentals
aliases: [observability, metrics logs traces, SLO, SLI, telemetry, OpenTelemetry]
type: concept
domain: observability
status: mature
tags: [observability, metrics, logs, traces, slo, sli, opentelemetry, prometheus, error-budget]
updated: 2026-06-20
sources:
  - "https://opentelemetry.io/docs/concepts/observability-primer/"
  - "https://uptrace.dev/blog/sla-slo-monitoring-requirements"
  - "https://core.cz/en/blog/2025/observability-opentelemetry-2026/"
  - "https://oneuptime.com/blog/post/2026-02-06-error-budgets-opentelemetry/view"
  - "https://www.cloudraft.io/blog/opentelemetry-observability-guide-optimization"
  - "https://peerobyte.com/blog/observability-in-2026-metrics-logs-traces-and-why-opentelemetry-matters/"
---

# Observability Fundamentals

> [!summary]
> Observability is the capability to understand a system's internal state from its external outputs — without shipping new code or SSH-ing into production. It rests on three telemetry pillars (metrics, logs, traces) unified under OpenTelemetry, and converts reliability into a concrete engineering contract via SLIs, SLOs, and error budgets. In 2026, observability is a design requirement, not a post-launch afterthought.

**Domain:** [[tier-2-solid|Observability & Reliability]]

## What it is

Traditional monitoring asks: "Is this thing up?" Observability asks: "Why is it behaving this way?" The difference is exploratory capability — observable systems let operators ask arbitrary questions about behavior with existing instrumentation, rather than requiring new probes for each new question.

The three pillars:
- **Metrics** — numeric time-series: request rates, error rates, latency percentiles, saturation. Cheap to aggregate; great for dashboards and alerts; poor for root-cause drill-down.
- **Logs** — timestamped event records: structured (JSON) or unstructured text. Rich context per event; expensive at scale without sampling/aggregation; great for debugging specific requests.
- **Traces** — distributed call graphs: a single request traced across service hops, showing latency and errors per hop. Essential for understanding distributed systems; requires instrumentation at every service boundary.

**They compound.** An alert fires on a metric (error rate spike); the trace on the erroring request shows which service hop failed; the logs on that service at that timestamp show the exception. Each pillar is weak alone; together they close the debugging loop.

## Why it matters

Distributed cloud-native systems are not debuggable by logging into a single server. The mean time to recover (MTTR) from incidents is dominated by time to diagnose root cause, not time to fix. Observable systems cut MTTR by providing the data needed to diagnose without ad-hoc investigation.

SLOs convert the reliability conversation from subjective ("is it fast enough?") to objective ("we agreed on 99.9% success rate; we're at 99.94%; we have budget left"). This unlocks sustainable engineering velocity: teams ship confidently while error budget remains; they slow down when budget is exhausted.

## Key concepts / building blocks

### OpenTelemetry (OTel)

OpenTelemetry is the vendor-neutral standard for producing, collecting, and exporting telemetry — the result of merging OpenCensus (Google) and OpenTracing. In 2026 it is the de facto default for new instrumentation.

**Three components:**
1. **API/SDK in the application** — language-specific libraries (Go, Java, Python, JS, .NET) that instrument code to produce traces, metrics, and logs
2. **OTLP protocol** — the OpenTelemetry Protocol; vendor-neutral wire format for exporting telemetry to a collector or backend
3. **Semantic conventions** — standard attribute names (`http.method`, `db.statement`, `service.name`) that make telemetry comparable across services and vendors

**The OTel Collector** is optional middleware that receives, processes (sample, filter, enrich), and exports telemetry to one or more backends. It decouples instrumentation from backend vendor — instrument once, swap backends by reconfiguring the collector.

**Automatic instrumentation** (Java agent, Python auto-inst, Node.js) captures HTTP, gRPC, database calls, and message queue interactions without code changes — the fastest path to baseline coverage.

### Metrics

**Instrument types:**
- **Counter** — monotonically increasing (request count, error count)
- **Gauge** — current value that can go up or down (queue depth, memory usage)
- **Histogram** — distribution of values; used to compute percentiles (p50, p95, p99 latency)

**The RED method** (Rate, Errors, Duration) gives the three metrics every service should expose:
- **Rate** — requests per second
- **Errors** — error rate (as count or percentage)
- **Duration** — latency distribution (p50, p95, p99)

The OTel Collector's `spanmetrics` connector auto-generates RED metrics from traces, eliminating duplicate instrumentation for services already traced.

**Prometheus** is the standard scrape-based metrics system in cloud-native environments. Managed equivalents: Amazon Managed Prometheus (AMP), Azure Monitor Metrics, Google Cloud Monitoring. Long-term storage at scale: Thanos, Cortex, VictoriaMetrics.

### Logs

**Structured logging** (JSON, logfmt) is mandatory for machine-readable observability. Unstructured text requires fragile parsing. Every log line should carry: timestamp, log level, service name, `trace_id`, `span_id` (for trace correlation), and relevant business context.

**Log aggregation patterns:**
- Fluent Bit — CNCF-graduated lightweight collector; sidecar or DaemonSet in Kubernetes
- Loki (Grafana) — label-indexed log aggregation; cheap storage; integrates natively with Grafana dashboards
- OpenSearch / Elasticsearch — full-text search; higher cost; better for complex log queries

**Cost control:** Logs at INFO/DEBUG for every request at scale becomes expensive quickly. Strategies: sample verbose logs (1-in-N), drop repeated identical events, use trace-based sampling (keep full logs only for erroring traces), tiered retention (hot 7 days, warm 30 days, cold/archive 1 year).

### Distributed Tracing

A trace spans the entire lifecycle of a request — from the browser through the API gateway, across N microservices, into databases and queues. Each unit of work is a **span** with: service name, operation, start/end timestamps, status, and attributes. Spans share a `trace_id` propagated in HTTP headers (`traceparent`, `tracestate` — W3C Trace Context spec).

**Sampling strategies:**
- **Head-based** — decide at the trace entry point whether to sample. Simple; loses interesting tail latency and low-frequency error traces.
- **Tail-based** — buffer spans in the collector; decide after seeing the complete trace ("always keep erroring traces"). More complete; requires buffering infrastructure.

**Backends:** Jaeger (open-source), Grafana Tempo (cost-efficient), Zipkin (legacy), Honeycomb, Datadog APM.

### SLI / SLO / Error Budget

**Service Level Indicator (SLI)** — a specific measurable property of the service relevant to users:
- Availability SLI: `(successful requests) / (total requests)` (HTTP 2xx/3xx = success)
- Latency SLI: `(requests served in <200ms) / (total requests)`
- Freshness SLI: `(data items refreshed in <60s) / (total data items)`

**Service Level Objective (SLO)** — the target value for an SLI over a rolling window:
- "99.9% of requests succeed over a 30-day rolling window"
- "95% of requests complete in <200ms over a 28-day window"

SLOs are the engineering team's reliability contract with the product — not a legal guarantee (that is the SLA). SLOs drive alerting: page on burn rate that threatens missing the SLO, not on raw error counts.

**Error Budget** — the allowed failure headroom: `(1 - SLO) × window_duration`. At 99.9% over 30 days = 43.8 minutes of downtime budget. Error budgets make reliability a shared currency:
- Budget remaining → feature velocity is healthy; ship
- Budget low → slow down; focus on reliability work
- Budget exhausted → freeze releases; SRE escalation triggers

**Multi-window, multi-burn-rate alerting** (Google SRE book pattern): alert on fast burn (1-hour window at 14× burn rate = page immediately) AND slow burn (6-hour window at 6× burn rate = ticket). Avoids both false negatives (slow bleed depleting budget) and false positives (brief spike that self-resolves).

### Alerting principles

**Alert on symptoms, not causes.** Page when users are affected (error rate up, latency up), not when an internal process looks odd. CPU/GC/memory metrics belong on dashboards, not pagers.

**Every alert needs a next action.** An alert that produces "look at the dashboard" is not actionable. Link alerts to runbooks.

**Saturation alerting.** Alert before resources are exhausted: 80% disk, 85% memory, 90% connection pool. Buffer time enables human response before full failure.

## Design decisions & trade-offs

**Build vs. buy for observability backend:**
- Self-hosted (Prometheus + Grafana + Tempo + Loki) is cost-effective but operationally complex at scale
- Managed (Datadog, New Relic, Honeycomb, Dynatrace) reduces operational burden at higher spend; typically justified above ~100-node clusters or multi-team orgs
- OTel's OTLP makes backend switching feasible — instrument once, reconfigure the collector to change backends

**Cardinality management:**
High-cardinality labels (user ID, request ID as Prometheus label dimensions) cause metric storage to explode. Metrics are for aggregated signals; put high-cardinality context in traces and logs. Prometheus drops series with too many label combinations; Datadog bills by custom metric count.

**Sampling trade-off:**
100% tracing produces the most complete data but is expensive. Head-based 1-10% sampling is cheap but loses rare error traces. Tail-based sampling (keep erroring traces, sample success) is the best quality/cost ratio but requires more infrastructure.

## State of the art

OpenTelemetry reached all-stable signals (traces, metrics, logs) in 2024-2025 and is the default instrumentation standard in 2026 — replacing Jaeger's proprietary SDKs, Prometheus-only instrumentation, and inconsistent logging formats.

**Profiles** (continuous profiling) is becoming OTel's fourth signal: CPU/memory/lock contention flame graphs per service, correlatable with traces. Pyroscope (Grafana) and Parca lead here.

**AI-augmented observability:** anomaly detection, automated root-cause correlation, and incident summarization are shipping in Datadog, Dynatrace, and New Relic. Still noisy in 2026; useful as triage assist, not a replacement for engineer judgment.

## Pitfalls & anti-patterns

**Observability theater.** Dashboards no one reads, alerts everyone ignores. The test: if a service degrades right now, can the on-call engineer diagnose the root cause in under 15 minutes using existing telemetry alone?

**Cardinality explosions.** User IDs or request IDs as Prometheus label dimensions. Crashes Prometheus; generates large bills in managed systems. Use traces for high-cardinality context; metrics for aggregations.

**Missing trace context propagation.** Instrumenting only some services. A trace that breaks crossing a service boundary is useless. Propagate `traceparent` headers through every hop: HTTP, gRPC, message queues, async jobs.

**Unstructured logs.** Free-text log lines that cannot be parsed by the aggregator. Structured JSON from day one; regexing free-text is costly and fragile.

**Alert fatigue.** Paging on every anomaly trains on-call to tune it out. Alert only on user-impacting symptoms; route informational signals to dashboards and tickets.

## See also

- [[distributed-systems-reliability]]
- [[ai-agent-observability]]
- [[cloud-native-patterns]]
- [[api-gateways-and-service-mesh]]
- [[cost-optimization-practice]]

## Sources

- OpenTelemetry. (2026). Observability Primer. https://opentelemetry.io/docs/concepts/observability-primer/
- Uptrace. (2025). Defining SLA/SLO-Driven Monitoring Requirements in 2025. https://uptrace.dev/blog/sla-slo-monitoring-requirements
- Core Systems. (2025). Observability Beyond Logs — OpenTelemetry and Monitoring's Future. https://core.cz/en/blog/2025/observability-opentelemetry-2026/
- OneUptime. (2026). How to Calculate Error Budgets from OpenTelemetry Trace and Metric Data. https://oneuptime.com/blog/post/2026-02-06-error-budgets-opentelemetry/view
- CloudRaft. (2026). OpenTelemetry Observability Guide: Optimize Metrics, Logs, and Traces at Scale. https://www.cloudraft.io/blog/opentelemetry-observability-guide-optimization
- Peerobyte. (2026). Observability in 2026: Metrics, Logs, Traces, and Why OpenTelemetry Matters. https://peerobyte.com/blog/observability-in-2026-metrics-logs-traces-and-why-opentelemetry-matters/
