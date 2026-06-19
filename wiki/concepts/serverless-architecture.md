---
title: Serverless Architecture
aliases: [serverless, FaaS, functions-as-a-service]
type: concept
domain: cloud
priority: P0
roadmap_ref: "2.3.2"
status: stub
tags: [cloud, serverless, faas]
updated: 2026-06-19
sources: []
---

# Serverless Architecture

> [!summary]
> Building applications from managed, event-triggered compute (functions and managed services) that scales automatically and bills per use, shifting operational burden to the provider.

**Priority:** 🔴 P0 · **Domain:** [[tier-1-edge|Cloud Architecture]] · **Roadmap:** §2.3.2

## What it is

Serverless architecture composes systems from functions-as-a-service and fully managed backing services, where the provider handles provisioning, scaling, and patching. Compute runs in response to events, scales to zero when idle, and is billed by execution. The trade-offs center on cold starts, statelessness, execution limits, vendor lock-in, and cost behavior at high, steady volume.

## Key concepts

- Functions-as-a-service (FaaS)
- Event triggers and scale-to-zero
- Cold starts and execution limits
- Statelessness and managed backing services
- Pay-per-use cost behavior

## See also

- [[event-driven-architecture]]
- [[cloud-native-patterns]]
- [[kubernetes-at-design-level]]
- [[cloud-cost-modeling]]

## Sources

- _Stub — no sources ingested yet._
