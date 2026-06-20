---
title: Data Storage Paradigms
aliases: [lakehouse, data mesh, data warehouse, OLTP, OLAP, Iceberg, Delta Lake]
type: concept
domain: data
status: mature
tags: [data, storage, lakehouse, warehouse, mesh, oltp, olap, iceberg, delta-lake, hudi]
updated: 2026-06-20
sources:
  - "https://datalakehousehub.com/blog/2025-09-2026-guide-to-data-lakehouses/"
  - "https://www.onehouse.ai/blog/apache-hudi-vs-delta-lake-vs-apache-iceberg-lakehouse-feature-comparison"
  - "https://lakefs.io/blog/hudi-iceberg-and-delta-lake-data-lake-table-formats-compared/"
  - "https://dev.to/dataformathub/apache-iceberg-the-open-data-stack-why-the-lakehouse-is-real-in-2026-2218"
  - "https://xenoss.io/blog/apache-iceberg-delta-lake-hudi-comparison"
---

# Data Storage Paradigms

> [!summary]
> Data storage at scale resolves into a hierarchy of choices: what workload type (OLTP vs. OLAP), what storage pattern (warehouse, lake, or lakehouse), and which open table format (Iceberg, Delta Lake, or Hudi) governs the lake layer. The 2026 consensus has converged on the lakehouse as the unified analytical architecture — open table formats on object storage, ACID transactions, time travel, and multi-engine access — but the lakehouse complements rather than replaces OLTP systems and specialized analytical databases.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

Data storage paradigms define where and how data lives at organizational scale. The two fundamental workload types drive divergent storage designs:

**OLTP (Online Transaction Processing):** low-latency, high-concurrency, write-heavy workloads. Optimized for single-row reads and writes with ACID guarantees. Examples: order processing, user registration, inventory updates. Storage engines: PostgreSQL, MySQL, CockroachDB, DynamoDB, Spanner.

**OLAP (Online Analytical Processing):** high-throughput, read-heavy, scan-oriented workloads. Optimized for aggregating large volumes of data across many rows. Examples: revenue dashboards, cohort analysis, ML feature generation. Storage engines: Snowflake, BigQuery, Redshift, ClickHouse, DuckDB.

The defining tension: OLTP systems can answer "what is the current state of order #12345?" in <10ms; OLAP systems can answer "what is the revenue by product by region for the last 90 days?" in seconds over billions of rows. No single system optimally serves both.

## Why it matters

Architecture decisions about data storage are expensive to reverse — data is heavy, migrations are risky, and downstream consumers bind to storage APIs. Choosing a data warehouse when a lakehouse fits the workload (or vice versa) compounds technical debt at the data layer for years.

The architect's decisions here cascade: the data platform shapes what ML teams can build (see [[ai-data-fabric]]), what streaming pipelines can ingest into (see [[streaming-and-event-data]]), and what governance policies can be enforced (see [[data-governance-and-lineage]]).

## Key concepts / building blocks

### Data Warehouse

A data warehouse is a purpose-built OLAP system: columnar storage, massive parallel query execution, SQL interface, optimized for read-heavy analytical workloads.

**Strengths:**
- Extremely fast analytical queries over structured data
- Managed SQL interface; accessible to analysts without infrastructure knowledge
- Auto-scaling compute (Snowflake virtual warehouses, BigQuery slots, Redshift Serverless)
- Built-in data sharing across accounts/organizations

**Limitations:**
- Structured data only (or semi-structured with caveats); unstructured data does not fit
- Proprietary formats; data is locked in the vendor's storage
- Expensive at scale; each vendor charges premium for storage + compute
- Poor fit for ML training (limited file format support; not designed for large sequential reads)

**Leading platforms:** Snowflake (cross-cloud, best data sharing), BigQuery (GCP-native, serverless, best for infrequent queries billed per TB), Redshift (AWS-native, deep VPC integration), Databricks SQL (built on the lakehouse).

### Data Lake

A data lake stores raw data in its native format on cheap object storage (S3, GCS, ADLS) — structured, semi-structured (JSON, Parquet), and unstructured (images, audio, documents).

**Strengths:**
- Lowest storage cost (object storage is ~$0.023/GB/month vs. >$0.20/GB for managed warehouses)
- Schema-on-read flexibility: raw data is preserved; transformation happens at query time
- Native ML/data science access: Parquet files, Python, Spark, notebooks

**Limitations without a table format:**
- No ACID transactions: concurrent writes corrupt data; partial writes leave inconsistent state
- No time travel: historical versions unavailable
- No efficient updates/deletes: changing a row requires rewriting the entire file
- Query performance poor without careful file layout management (small file problem, missing statistics)

These limitations led to the lakehouse pattern.

### Lakehouse

The lakehouse unifies data lake economics (cheap object storage) with data warehouse capabilities (ACID, SQL, schema enforcement) via **open table formats** that sit on top of object storage and add a transactional metadata layer.

**Core properties of a lakehouse:**
- ACID transactions on object storage
- Time travel (query the state of data at any past timestamp)
- Schema evolution without rewriting data
- Efficient upserts and deletes (not just append-only)
- Multi-engine access: the same data is queryable by Spark, Flink, Presto/Trino, DuckDB, Snowflake External Tables, BigQuery Omni

> [!summary]
> The 2026 consensus: a successful lakehouse is layered — cloud object storage for durability and cost, an open table format for transactions and evolution, a catalog for governance and discoverability, and a flexible consumption layer serving SQL, BI, notebooks, and AI agents.

### Open table formats

Open table formats are the technical substrate of the lakehouse. All three solve the same core problems (ACID on object storage, time travel, schema evolution) but with different design choices.

**Apache Iceberg:**
- De facto open standard for enterprises seeking vendor independence
- Manifest-based metadata: snapshots point to manifests that list data files; efficient for large tables with many partitions
- Hidden partitioning: partitioning is an implementation detail, not a query concern; partition evolution without table rewrite
- Row-level deletes via delete files (position and equality deletes)
- Best for: multi-engine environments, AI/agent workloads needing open catalog APIs, regulatory reporting, any context requiring maximum openness

**Delta Lake:**
- Created by Databricks; append-only transaction log (`_delta_log`) with JSON entries and Parquet checkpoints
- Deep Databricks integration; best performance within the Databricks ecosystem
- Delta Live Tables for declarative pipeline management
- Best for: Databricks-centric organizations; teams using Unity Catalog for governance

**Apache Hudi (Hadoop Upserts Deletes and Incrementals):**
- Created by Uber for high-frequency CDC (Change Data Capture) and upsert workloads
- Two table types: Copy-on-Write (COW, simpler, slower writes) and Merge-on-Read (MOR, faster writes, slower reads)
- Best for: streaming CDC ingestion, real-time upsert-heavy pipelines, AWS-heavy teams (native EMR integration)

**Practical reality (2026):** mature teams often use multiple formats — Hudi for real-time CDC ingestion, Delta Lake for Databricks analytics, Iceberg for cross-engine or regulatory access. The formats are increasingly interoperable via Apache XTable (formerly OneTable) translation layer.

### Data Mesh

Data mesh is an organizational and architectural pattern that decentralizes data ownership: instead of a central data team owning all data, each domain team owns their data as a **data product** — a well-defined, versioned, discoverable, and reliable dataset with a published interface.

**Four principles (Zhamak Dehghani):**
1. **Domain ownership** — the team that produces the data owns and maintains its quality
2. **Data as a product** — data sets are products with SLAs, documentation, versioning
3. **Self-serve data platform** — infrastructure enables teams to publish data products without central bottleneck
4. **Federated computational governance** — global standards (schemas, security, compliance) enforced by policy, not centrally operated pipelines

**Data mesh vs. lakehouse:** these are complementary, not competing. The lakehouse provides the storage and compute substrate; data mesh provides the organizational model for ownership. A data mesh can be implemented on a lakehouse.

**Caution:** data mesh requires significant organizational maturity. "Domain ownership" works when domains are stable and teams have data engineering expertise. Applied prematurely, it produces data sprawl with inconsistent quality and no central discoverability.

### Storage/compute separation

Modern data platforms separate storage (where data lives) from compute (where queries run). Object storage (S3, GCS, ADLS) is the storage tier; query engines (Spark, Trino, BigQuery, Snowflake) scale independently.

**Benefits:**
- Scale each independently: more compute for peak query periods without paying for more storage
- Multiple compute engines can query the same data simultaneously (Flink for streaming, Spark for batch, Trino for SQL)
- Cheapest storage tier for cold/warm data

**The catalog layer:** with storage/compute separation, a catalog manages the metadata that connects engines to data files. Apache Iceberg REST Catalog, AWS Glue Data Catalog, Databricks Unity Catalog, and Apache Polaris (incubating) are the major options. The catalog is increasingly the governance chokepoint: access control, audit, lineage, and data discovery all flow through it.

## Design decisions & trade-offs

**Warehouse vs. lakehouse:**

| Criteria | Warehouse | Lakehouse |
|---|---|---|
| Primary consumers | SQL analysts, BI tools | ML/AI teams + SQL analysts |
| Data types | Structured only | All (structured + unstructured) |
| Update patterns | Append or merge via SQL | Upsert, delete, streaming CDC |
| Vendor lock-in | High (proprietary format) | Low (open formats) |
| SQL performance | Best-in-class, managed | Excellent with proper tuning |
| Cost at petabyte scale | High | Lower (object storage) |

**Which table format?**

| Default to Iceberg when... | Default to Delta Lake when... | Default to Hudi when... |
|---|---|---|
| Multi-engine access required | Already Databricks-centric | High-frequency CDC from RDBMS |
| AI/agent workload needing open catalog | Unity Catalog in use | AWS EMR native integration needed |
| Regulatory reporting needing open audit | Delta Live Tables attractive | MOR write performance required |
| Maximum openness is a constraint | | |

**When is data mesh appropriate?** When: the organization has >4 independent domain teams producing data, a central data team has become a bottleneck, domains already have engineering maturity, and leadership will fund domain-level data ownership. Not appropriate for: small organizations, immature domains, or when enforcing centralized governance is a hard requirement.

## State of the art

The lakehouse has moved from emerging pattern to mainstream production architecture. Apache Iceberg is converging as the dominant open standard with support from AWS, Google, Azure, Databricks, Snowflake, and Apple. Delta Lake remains the natural choice for Databricks-centric stacks.

**The AI lakehouse:** in 2026, AI workloads are reshaping lakehouse requirements. LLMs and AI agents need transparent metadata, open catalog APIs, and format-level support for diverse query engines. Iceberg's specification-driven design and manifest-based metadata serve these needs better than proprietary warehouse formats. Feature stores and vector stores are increasingly built as lakehouse layers (see [[ai-data-fabric]]).

**DuckDB**: the in-process OLAP engine that reads Parquet, Iceberg, and Delta Lake files directly — enabling analytical queries on laptops or in serverless functions without a cluster. Rapidly displacing Spark for small-to-medium analytical workloads.

## Pitfalls & anti-patterns

**The data swamp.** A data lake without governance, schema enforcement, or a catalog. Data lands without documentation, schemas drift silently, and consumers can't trust what they read. Apply governance from day one: catalog registration, schema validation, ownership assignment.

**The small file problem.** Streaming ingestion writing many small files to object storage. Each file = one S3 API call; millions of small files make query planning slow and expensive. Compact files regularly (Iceberg's `rewrite_data_files` procedure, Delta Lake `OPTIMIZE`, Hudi compaction service).

**Treating the lakehouse as a warehouse replacement everywhere.** SQL analysts familiar with managed warehouses (Snowflake, BigQuery) will find raw lakehouse ergonomics harder. Provide a SQL interface (Athena, Trino, BigQuery Omni, Databricks SQL) over the lakehouse; don't force analysts to write Spark.

**Premature data mesh adoption.** Decentralizing data ownership before teams have the data engineering maturity to build reliable data products. Domain teams that produce inconsistent, undocumented data products create more problems than a central team with bottlenecks.

## See also

- [[streaming-and-event-data]]
- [[data-governance-and-lineage]]
- [[ai-data-fabric]]
- [[event-sourcing-and-cqrs]]
- [[cloud-cost-modeling]]
- [[feature-stores]]

## Sources

- Data Lakehouse Hub. (2025). The 2025 & 2026 Ultimate Guide to the Data Lakehouse Ecosystem. https://datalakehousehub.com/blog/2025-09-2026-guide-to-data-lakehouses/
- Onehouse. (2026). Apache Hudi vs Delta Lake vs Apache Iceberg — Lakehouse Feature Comparison. https://www.onehouse.ai/blog/apache-hudi-vs-delta-lake-vs-apache-iceberg-lakehouse-feature-comparison
- LakeFS. (2026). Hudi vs Iceberg vs Delta Lake: Data Lake Table Formats Compared. https://lakefs.io/blog/hudi-iceberg-and-delta-lake-data-lake-table-formats-compared/
- DataFormatHub. (2026). Apache Iceberg: The Open Data Stack — Why the Lakehouse is Real in 2026. https://dev.to/dataformathub/apache-iceberg-the-open-data-stack-why-the-lakehouse-is-real-in-2026-2218
- Xenoss. (2026). Apache Iceberg vs Delta Lake vs Hudi: Choose the Right Table Format. https://xenoss.io/blog/apache-iceberg-delta-lake-hudi-comparison
