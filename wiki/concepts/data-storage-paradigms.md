---
title: Data Storage Paradigms
aliases: [lakehouse, data mesh, data warehouse, OLTP, OLAP]
type: concept
domain: data
priority: P1
roadmap_ref: "5.1"
status: stub
tags: [data, storage, lakehouse, warehouse, mesh]
updated: 2026-06-19
sources: []
---

# Data Storage Paradigms

> [!summary]
> The architectural choices for where and how data lives — warehouse, lake, lakehouse, or mesh — and the transactional vs. analytical workloads they serve.

**Priority:** 🟠 P1 · **Domain:** [[tier-2-solid|Data Architecture]] · **Roadmap:** §5.1

## What it is

Data storage paradigms describe the major patterns for organizing data at scale. Warehouses optimize structured analytics; lakes hold raw multi-format data cheaply; lakehouses unify both with open table formats; data mesh decentralizes ownership into domain-aligned data products. The OLTP/OLAP split separates transactional from analytical processing.

## Key concepts

- Lakehouse vs. data mesh vs. data warehouse
- OLTP vs. OLAP workloads
- Open table formats (Iceberg, Delta Lake, Hudi)
- Data products and domain ownership (mesh)
- Storage/compute separation

## See also

- [[streaming-and-event-data]]
- [[data-governance-and-lineage]]
- [[ai-data-fabric]]
- [[event-sourcing-and-cqrs]]
- [[cloud-cost-modeling]]

## Sources

- _Stub — no sources ingested yet._
