---
title: AI / GPU Economics
aliases: [GPU economics, token economics, inference cost, AI cost]
type: concept
domain: finops
status: stub
tags: [finops, ai, gpu, inference, tokens]
updated: 2026-06-19
sources: []
---

# AI / GPU Economics

> [!summary]
> The cost structure of running AI workloads — GPU capacity, token-based inference pricing, and model tiering — and how to architect for affordable scale.

**Domain:** [[tier-2-solid|FinOps & Cost Architecture]]

## What it is

AI/GPU economics covers the distinctive cost drivers of AI systems: scarce and expensive GPU compute for training and self-hosted inference, and per-token pricing for hosted LLM APIs. Architects manage this through model tiering (routing easy tasks to cheaper models), caching, batching, and deciding between hosted APIs and self-hosted inference.

## Key concepts

- Token economics and per-request inference cost
- GPU capacity, utilization, and scheduling
- Model tiering and routing for cost ([[model-selection-and-routing]])
- Hosted API vs. self-hosted inference trade-offs
- Caching, batching, and quantization for cost

## See also

- [[cloud-cost-modeling]]
- [[cost-optimization-practice]]
- [[model-selection-and-routing]]
- [[llm-application-architecture]]

## Sources

- _Stub — no sources ingested yet._
