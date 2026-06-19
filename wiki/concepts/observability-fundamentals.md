---
title: Observability Fundamentals
aliases: [observability, metrics logs traces, SLO, SLI, telemetry]
type: concept
domain: observability
priority: P1
roadmap_ref: "8.1"
status: stub
tags: [observability, metrics, logs, traces, slo]
updated: 2026-06-19
sources: []
---

# Observability Fundamentals

> [!summary]
> The capability to understand a system's internal state from its external outputs — metrics, logs, and traces — and to define reliability targets via SLOs and SLIs.

**Priority:** 🟠 P1 · **Domain:** [[tier-2-solid|Observability & Reliability]] · **Roadmap:** §8.1

## What it is

Observability is the property that lets operators ask arbitrary questions about a system's behavior without shipping new code. It rests on the three pillars — metrics, logs, and traces — increasingly unified under OpenTelemetry. Service Level Indicators (SLIs) measure user-facing behavior; Service Level Objectives (SLOs) set targets and drive error budgets.

## Key concepts

- The three pillars: metrics, logs, traces
- OpenTelemetry as the instrumentation standard
- SLI / SLO / error budgets
- Cardinality, sampling, and cost control
- Dashboards, alerting, and on-call

## See also

- [[distributed-systems-reliability]]
- [[ai-agent-observability]]
- [[api-gateways-and-service-mesh]]
- [[cost-optimization-practice]]

## Sources

- _Stub — no sources ingested yet._
