---
title: Data Pipelines & Orchestration
aliases: [data pipelines, ETL, ELT, dbt, Airflow, Dagster, medallion architecture, data orchestration, modern data stack]
type: concept
domain: data
status: mature
tags: [data, pipelines, etl, elt, dbt, airflow, orchestration, medallion]
updated: 2026-06-26
sources:
  - "https://www.alpsagility.com/modern-data-stack-orchestration-2026"
  - "https://dagster.io/learn/elt"
  - "https://docs.getdbt.com/docs/build/incremental-models"
  - "https://learn.microsoft.com/en-us/azure/databricks/lakehouse/medallion"
  - "https://airflow.apache.org/docs/"
---

# Data Pipelines & Orchestration

> [!summary]
> A data pipeline moves and transforms data from source systems into analytics- and ML-ready form;
> orchestration schedules and sequences that work so it runs reliably, in order, with retries and
> visibility. The 2026 default is **ELT** (load raw, then transform *in* the warehouse/lakehouse)
> over ETL, organized as the **medallion architecture** (bronze → silver → gold) and built from a
> **composable stack** — ingestion + transformation + orchestration — rather than a monolith. This
> is distinct from its data-domain neighbors: [[streaming-and-event-data]] is the *real-time* path,
> [[data-storage-paradigms]] is *where data lives*; this page is *how data gets there and gets
> shaped*. The architect's calls are ETL-vs-ELT, batch-vs-incremental, the orchestrator model, and
> designing pipelines that are **idempotent and reproducible**.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

A pipeline has four stages: **ingest** (pull from sources), **land** (store raw), **transform**
(clean, conform, model), and **serve** (to BI, ML, [[feature-stores|features]], reverse-ETL). The
defining modern choice is *where transformation happens*:

- **ETL** — transform *before* loading. The classic pattern; still right when you must redact/secure
  data before it lands (see [[data-privacy-engineering]]) or the destination compute is expensive.
- **ELT** — load raw first, transform *inside* the warehouse/lakehouse with its cheap elastic
  compute. The default for most new cloud projects in 2026; keeps the raw copy and defers schema.

The **composable modern data stack** assembles best-of-breed tools: managed ingestion
(Fivetran/Airbyte) → object storage / warehouse → in-warehouse transformation (**dbt**) →
**orchestration** (Airflow/Dagster/Prefect) → BI/ML — versus an all-in-one platform
(Databricks/Snowflake).

## Why it matters

AI and analytics are only as good as the data fabric feeding them — pipelines are where **data
quality, freshness, cost, and reproducibility** are won or lost. A brittle pipeline silently emits
bad data, and the cost surfaces far downstream as wrong dashboards, wrong decisions, and poisoned
[[model-customization|training sets]]. The architect owns the *patterns* — idempotency,
incrementality, lineage, orchestration topology — because those are what make a pipeline estate
trustworthy and affordable at scale rather than a thicket of fragile cron jobs.

## Key concepts / building blocks

### The medallion architecture

The dominant layering on a lakehouse:

| Layer | Contents | Purpose |
|---|---|---|
| **Bronze** | Raw, immutable, as-ingested | Replayable source of truth; reprocess without re-pulling |
| **Silver** | Cleaned, conformed, deduplicated, typed | A trustworthy, queryable foundation |
| **Gold** | Business-ready marts, metrics, ML features | Powers dashboards, self-service, model training |

Bronze→silver→gold maps onto the [[data-storage-paradigms|lakehouse]] layers and is essentially an
ELT pipeline expressed as data tiers.

### Ingestion

Batch pulls (full or **incremental**) and **CDC** ([[saga-and-outbox-patterns|change data
capture]], e.g. Debezium) for low-latency replication. Managed connectors (Fivetran/Airbyte) trade
cost for not maintaining bespoke extractors.

### Transformation — dbt

**dbt** is the in-warehouse transformation standard: modular SQL models, built-in tests, versioning,
and auto-generated lineage/docs. It brings software engineering (version control, tests, CI, code
review) to the transformation layer — the shift that made ELT trustworthy.

### Orchestration

The scheduler/sequencer that turns individual jobs into a reliable DAG with dependencies, retries,
backfills, and observability:

- **Airflow** — the ubiquitous, task-centric (imperative DAG) standard; nearly every data engineer
  knows it.
- **Dagster** — **asset-centric** (software-defined assets): you declare the *data products* and
  their dependencies, aligning with how teams think about data. Rising fast.
- **Prefect** — lightweight, Pythonic, dynamic flows.

The 2026 best practice is to let the orchestrator trigger dbt immediately after ingestion completes,
then run quality tests — a single governed DAG, not scattered crons.

### Incremental processing, backfills, and late data

**Incremental models** process only new/changed rows (essential at scale; full-refresh is
prohibitively expensive on large tables). This introduces **watermarks**, **backfills** (reprocessing
historical partitions), and **late/out-of-order data** handling — the same event-time concerns as
[[streaming-and-event-data]], in batch form.

### Idempotency, reproducibility, and quality gates

- **Idempotency** — a re-run (after a failure or a backfill) must not duplicate or corrupt data.
  Partition-overwrite and merge/upsert patterns make reruns safe (same discipline as
  [[saga-and-outbox-patterns|idempotent consumers]]).
- **Quality gates** — in-pipeline assertions (dbt tests, Great Expectations, Soda) fail the run
  before bad data reaches gold. Feeds [[data-governance-and-lineage]].
- **Lineage** — emit OpenLineage events so transformations are traceable end-to-end.

## Design decisions & trade-offs

- **ELT vs. ETL.** ELT (cheap warehouse compute, raw retained, flexible, schema-on-read) is the
  default. Choose ETL when privacy/compliance requires transforming or redacting *before* the data
  lands ([[data-privacy-engineering]]), or when destination compute is the bottleneck.
- **Batch vs. incremental vs. streaming.** Full-refresh is simplest but doesn't scale; incremental
  is cheaper but adds watermark/backfill/late-data complexity; streaming buys freshness at
  operational cost. Match latency need to cost — most analytics doesn't need real time
  ([[streaming-and-event-data]]).
- **Orchestrator model: task-centric vs. asset-centric.** Airflow (imperative tasks, ubiquitous
  talent pool) vs. Dagster (software-defined *assets*, data-product thinking, better lineage/testing
  ergonomics). Pick by how the team reasons about data and what skills exist.
- **Composable stack vs. monolithic platform.** Best-of-breed (Fivetran + dbt + Airflow) maximizes
  flexibility and avoids lock-in but you integrate and operate the seams; an all-in-one
  (Databricks/Snowflake) reduces integration at the cost of platform lock-in. A
  [[trade-off-judgment|reversibility]] call.
- **Build vs. buy ingestion.** Managed connectors cost per-row/seat but eliminate connector
  maintenance; DIY extractors give control at ongoing engineering cost.
- **Idempotency/incrementality vs. simplicity.** Idempotent incremental pipelines are more code than
  naive full-refresh — worth it as data volume and rerun frequency grow.

## State of the art

- **ELT is the default**; **dbt** is the de-facto transformation layer, bringing tests/versioning/CI
  to SQL.
- **Airflow remains dominant** for orchestration, with **Dagster's software-defined assets** the
  fastest-growing alternative and the clearest expression of "data as products."
- **Medallion on the lakehouse** is the mainstream organizing pattern; **composable stacks** are
  favored over monolithic platforms.
- **Declarative / asset-based orchestration** and **OpenLineage** lineage emission are converging the
  pipeline and [[data-governance-and-lineage|governance]] layers.
- **AI integration**: pipelines feed [[feature-stores]] and [[ai-data-fabric]]; LLM-assisted pipeline
  and dbt-model generation is emerging (with the human owning correctness and tests).

## Pitfalls & anti-patterns

- **Non-idempotent pipelines.** A rerun or backfill that duplicates or corrupts rows. Design merge/
  partition-overwrite from the start.
- **No incrementality at scale.** Full-refreshing billion-row tables nightly — a cost and runtime
  blowup.
- **Untested, scattered transformation logic.** SQL spread across notebooks and scripts with no
  tests → silent bad data. Consolidate in tested dbt models.
- **No quality gates.** Bad data flows straight to gold and into models because nothing asserted
  freshness/completeness/validity mid-pipeline.
- **Cron sprawl as orchestration.** Independent cron jobs with no dependency graph, retries, or
  observability — failures cascade invisibly. Use a real orchestrator.
- **Ignoring late and out-of-order data.** Pipelines that assume data arrives complete and on time
  silently drop or mis-aggregate late records.
- **The mega-DAG.** One monolithic pipeline nobody can reason about or safely change.
- **PII into bronze unredacted.** Raw landing of sensitive data with no minimization — see
  [[data-privacy-engineering]].

## See also

- [[data-storage-paradigms]]
- [[streaming-and-event-data]]
- [[data-governance-and-lineage]]
- [[ai-data-fabric]]
- [[feature-stores]]
- [[saga-and-outbox-patterns]]
- [[data-privacy-engineering]]
- [[cost-optimization-practice]]

## Sources

- [Alps Agility — Modern Data Stack Orchestration 2026 (Airflow vs Prefect vs Dagster vs dbt vs Fivetran)](https://www.alpsagility.com/modern-data-stack-orchestration-2026)
- [Dagster — What Is ELT, Pros/Cons & Steps to Build a Pipeline](https://dagster.io/learn/elt)
- [dbt — Incremental models](https://docs.getdbt.com/docs/build/incremental-models)
- [Microsoft Learn — Medallion architecture on the lakehouse](https://learn.microsoft.com/en-us/azure/databricks/lakehouse/medallion)
- [Apache Airflow — Documentation](https://airflow.apache.org/docs/)
