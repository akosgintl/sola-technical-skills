---
title: Feature Stores
aliases: [feature store, ML feature store]
type: concept
domain: data
status: stub
tags: [data, ai, ml, features]
updated: 2026-06-19
sources: []
---

# Feature Stores

> [!summary]
> A centralized system for defining, computing, storing, and serving ML features consistently across training and inference, eliminating training/serving skew.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

A feature store manages the engineered inputs that ML models consume. It provides an offline store for batch training and a low-latency online store for inference, guaranteeing the same feature definitions are used in both. This solves training/serving skew, enables feature reuse across teams, and tracks feature lineage and freshness.

## Key concepts

- Offline vs. online stores
- Training/serving consistency (skew avoidance)
- Feature definitions, versioning, and reuse
- Point-in-time correctness
- Tooling (Feast, Tecton, vendor platforms)

## See also

- [[ai-data-fabric]]
- [[vector-and-embedding-stores]]
- [[data-governance-and-lineage]]
- [[streaming-and-event-data]]

## Sources

- _Stub — no sources ingested yet._
