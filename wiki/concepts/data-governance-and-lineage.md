---
title: Data Governance and Lineage
aliases: [data governance, data lineage, data contracts, data catalog, Unity Catalog, OpenLineage, DataHub]
type: concept
domain: data
status: mature
tags: [data, governance, lineage, quality, data-catalog, data-contracts, unity-catalog, openlineage, datahub]
updated: 2026-06-20
sources:
  - "https://mdn.digital/insights/databricks-unity-catalog-enterprise-governance"
  - "https://www.kai-waehner.de/blog/2026/05/18/beyond-enterprise-data-lineage-the-case-for-a-platform-independent-data-catalog/"
  - "https://link.springer.com/chapter/10.1007/979-8-8688-2524-8_14"
  - "https://docs.databricks.com/aws/en/data-governance/unity-catalog/data-lineage"
  - "https://www.ovaledge.com/blog/data-lineage-tools"
  - "https://learn.microsoft.com/en-us/azure/databricks/data-governance/unity-catalog/data-lineage"
---

# Data Governance and Lineage

> [!summary]
> Data governance is the system of policies, ownership models, access controls, and quality rules that ensure data assets are trustworthy and compliant. Data lineage tracks every transformation a data asset passes through — from source to consumption — enabling impact analysis, audit, and debugging. Together they answer the two critical enterprise data questions: "Can I trust this data?" and "Where did it come from?" In 2026, governance has extended to AI assets (models, feature tables, evaluation datasets), driven by EU AI Act compliance requirements and the need to audit AI decisions.

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

Data governance and lineage are the control and visibility layers of a data platform. Without them, organizations face:
- **Trust failure:** analysts cannot determine whether a metric is correct or how it was computed
- **Compliance gaps:** unable to demonstrate to regulators that PII is handled correctly or that data flows are auditable
- **Blast radius blindness:** a schema change in an upstream table breaks 40 downstream dashboards and pipelines with no warning
- **Discovery failure:** engineers spend time rebuilding data assets that already exist, unaware they exist elsewhere

The four governance pillars that address these failures:

1. **Catalog** — makes data assets discoverable with rich metadata
2. **Lineage** — tracks data provenance and transformation chains
3. **Contracts** — formalizes producer/consumer expectations
4. **Access governance** — controls who can access what data and audits that access

## Why it matters

At small scale, governance is optional overhead. At enterprise scale, it becomes a prerequisite for any data-driven decision. The specific pressures in 2026:

**Regulatory compliance:** GDPR, CCPA, EU AI Act, HIPAA, SOX all require demonstrable data lineage and access controls. "We don't know where this data came from" is not a defensible answer to a regulator.

**AI Act compliance:** EU AI Act (enforcement 2025-2026) requires high-risk AI systems to document the datasets used for training and evaluation, the data preprocessing applied, and the lineage of model inputs. Unity Catalog's AI asset governance directly addresses this requirement.

**LLM data supply chains:** AI models are trained on data pipelines. If those pipelines are ungoverned, the model inherits the problems of its training data (bias, PII contamination, low quality).

**Scale:** 42 vendors now compete in the data catalog space (Baumann 2025). The market consolidation wave (Salesforce acquiring Informatica, Snowflake acquiring SelectStar, ServiceNow acquiring data.world) signals that governance is now a platform feature, not a standalone product.

## Key concepts / building blocks

### Data catalog

A data catalog is the discovery layer — a searchable index of every data asset in the organization, enriched with metadata:
- **Technical metadata:** schema, data types, partitioning, storage location
- **Business metadata:** owner, description, business glossary terms, SLAs
- **Operational metadata:** last updated, row count, data quality scores
- **Lineage:** upstream sources and downstream consumers

**The catalog enables:**
- Discovery: find existing data assets before creating duplicates
- Impact analysis: which pipelines and dashboards use this table? Safe to change the schema?
- Trust: last refreshed 6 months ago? Owner has left the company? Catalog surfaces these signals.

**Catalog products (2026):**

| Product | Type | Strengths |
|---|---|---|
| **Unity Catalog** (Databricks) | Platform-native | Deep Databricks integration; AI asset governance; open-sourced 2024 |
| **DataHub** (LinkedIn / open-source) | Open-source | Platform-independent; OpenLineage native; 3,000+ orgs in production; column-level lineage |
| **Apache Atlas** | Open-source | Hadoop ecosystem; Hive/HBase integration |
| **Microsoft Purview** | Managed | Azure-native; multi-cloud scanning; M365 data coverage |
| **Collibra** | Enterprise SaaS | Business glossary + governance workflows; strong for regulated industries |
| **Alation** | Enterprise SaaS | Query intelligence; analyst-facing search |

### Data lineage

Lineage answers "where did this data come from and what happened to it?" It records:
- **Source:** the origin system, table, or topic
- **Transformations:** every pipeline step, query, or model that touched the data
- **Destination:** where the data lands (warehouse table, dashboard, ML feature, downstream API)

**Lineage granularity levels:**

| Level | What it tracks | Use case |
|---|---|---|
| **Table/dataset** | Source table → target table via job | Impact analysis: "what breaks if I change this table?" |
| **Column** | Source column → target column via transformation | Data quality: "which column in the raw data produced this metric?" |
| **Row/record** | Individual record provenance | Regulatory: "where did this specific customer record come from?" |

Column-level lineage is the practical standard for analytics engineering — it enables understanding exactly which source columns feed which dashboard metrics.

**OpenLineage:** the open standard (CNCF project) for lineage metadata emission. Defines a JSON event schema for emitting lineage events from any pipeline runner (Airflow, Spark, dbt, Flink). Decouples lineage emission from the catalog — emit once, collect in any catalog that ingests OpenLineage events (DataHub, Marquez, OpenMetadata).

**Unity Catalog lineage (Databricks):** automatically captures lineage for all SQL queries and Delta Live Tables pipelines run in Databricks — no manual instrumentation required. Provides table-level and column-level lineage across notebooks, jobs, and DLT pipelines.

### Data contracts

A data contract is a formal, version-controlled agreement between the producer of a data asset and its consumers. It specifies:
- **Schema:** column names, types, nullable/required, valid value ranges
- **SLAs:** freshness (data is updated by time T), completeness (no more than X% null), row count SLAs
- **Semantics:** business definition of each field ("revenue excludes refunds but includes discounts")
- **Breaking change policy:** how the producer commits to communicate and manage schema changes

Data contracts shift the governance burden left: instead of consumers discovering broken schema changes in production, the contract requires producers to version schema changes and notify consumers in advance.

**Data contract formats:** emerging tooling includes ODCS (Open Data Contract Standard), Soda Data Contracts, and custom YAML schemas enforced in CI/CD. Integration with dbt + Great Expectations enables contract validation on every pipeline run.

**Without contracts:** a Kafka topic schema changes silently → 12 downstream consumers break → hours of debugging → business impact. With contracts: the schema change is detected at the producer CI stage; consumers are notified via contract versioning; breakage is caught before production.

### Data quality

Quality is the enforcement layer of governance — automated assertions that data meets the contract's specifications:

**Quality dimensions:**
- **Completeness:** non-null rates, required field coverage
- **Accuracy:** values within expected ranges, valid enumerations
- **Freshness:** data arrived within SLA
- **Consistency:** values match across tables (fact table amounts match dimension table aggregates)
- **Uniqueness:** no duplicate primary keys

**Quality tooling:**
- **Great Expectations** — Python-native; expectation suites as code; CI integration
- **dbt tests** — built-in (`not_null`, `unique`, `accepted_values`, `relationships`); custom SQL tests; runs with dbt models
- **Soda** — managed platform; monitors running data; alerts on SLA violations
- **Monte Carlo / Anomalo** — ML-based anomaly detection; "data observability" platforms that detect unusual patterns without pre-defined rules

### Access governance

Who can access which data under what conditions:

**Classification-first approach:**
1. Classify data assets by sensitivity: public, internal, confidential, restricted (PII, PHI, financial)
2. Define access policies per classification: restricted data requires data steward approval + business justification
3. Enforce in the catalog and the underlying data platform (Unity Catalog row-level and column-level security, BigQuery data policies, Snowflake row access policies)

**Column masking:** dynamically mask sensitive columns based on the querying user's role. A data analyst sees `name` as `***`; a data steward sees the full value. Unity Catalog, Snowflake, and BigQuery all support dynamic masking policies.

**Attribute-based access via tags:** tag columns with sensitivity classifications (PII, PHI, PCI) and attach masking/restriction policies to the tags — the policy follows the data as it moves across tables without manual re-annotation.

**Audit logging:** every data access event (who accessed what table, at what time, which rows were returned) is logged for compliance and anomaly detection.

### AI asset governance (2026)

Data governance has extended to ML/AI assets — models are data artifacts with their own lineage, quality, and access requirements:

- **Model governance:** version tracking, experiment lineage (which data, hyperparameters, and code produced this model), deployment audit trail
- **Feature store integration:** feature lineage from raw source to computed feature to model training set
- **EU AI Act compliance:** for high-risk AI systems, Unity Catalog provides the documentation of training data lineage, data preprocessing steps, and model evaluation datasets required by the Act
- **Evaluation dataset governance:** test datasets and benchmark results are governed assets — version-controlled, access-controlled, lineage-tracked

Unity Catalog extended to govern ML models, feature tables, and evaluation datasets in 2025, making it a single governance plane for both data and AI assets.

## Design decisions & trade-offs

**Platform-native catalog vs. platform-independent catalog:**

| Approach | Pros | Cons |
|---|---|---|
| **Platform-native** (Unity Catalog for Databricks, BigQuery Data Catalog) | Deep integration; automatic lineage; no configuration | Locked to the platform; multi-cloud or multi-tool organizations have gaps |
| **Platform-independent** (DataHub, OpenMetadata, Collibra) | Single pane across all sources; vendor-neutral; unified search | Manual integration work; lineage requires connector configuration; separate operational system |

**Practical recommendation:** for organizations standardized on Databricks, Unity Catalog's automatic lineage and AI asset governance justify platform-native adoption. For multi-cloud or heterogeneous stacks (Databricks + Snowflake + Redshift + Kafka), a platform-independent catalog with OpenLineage ingestion from all sources is the only way to get unified lineage.

**Data contracts: top-down mandate vs. bottom-up adoption:**
Top-down (all producers must sign contracts, enforced by platform team) ensures coverage but creates friction and slows producers. Bottom-up (high-value or high-consumer-count datasets prioritized) delivers value faster but leaves gaps. Recommended: mandate contracts for datasets with 3+ known consumers; make them optional but incentivized for others.

**Data quality: rules-based vs. anomaly detection:**
Rules-based quality (Great Expectations, dbt tests) requires explicit definition of each assertion — high precision, catches exactly what you specify. Anomaly detection (Monte Carlo, Anomalo) finds unexpected patterns without pre-definition — catches unknown unknowns but produces false positives. Use both: rules for SLA assertions, anomaly detection as the additional safety net.

## State of the art

By 2026, data governance has consolidated from a standalone discipline into a platform feature. Unity Catalog (open-sourced 2024) has become the default governance layer for Databricks-based data platforms. DataHub has formalized as an independent organization after separating from LinkedIn in 2025, with 3,000+ production deployments. OpenLineage is the open standard for lineage emission, supported by Airflow, Spark, dbt, Flink, and all major catalog products.

The frontier: **AI governance** as an extension of data governance. The EU AI Act is the forcing function; Unity Catalog's AI asset governance is the leading response. Expect data catalogs to become the audit infrastructure for AI system compliance over 2026-2027.

Market consolidation: 42 vendors documented in the 2025/2026 market perspective; significant acquisition activity signals the market is maturing out of standalone tools into platform-integrated governance.

## Pitfalls & anti-patterns

**Catalog as a one-time project.** A catalog populated manually during a governance initiative becomes stale within months. Governance that isn't automated (auto-discovery, auto-lineage, auto-quality alerts) is not governance — it's a snapshot that rots.

**Lineage at table level only.** Table-level lineage tells you "this pipeline reads these tables." Column-level lineage tells you "this metric is computed from these three columns via this transformation." Only column-level lineage enables root-cause debugging of data quality issues and accurate impact analysis for schema changes.

**Data contracts without enforcement.** A data contract as a README document that producers don't need to honor is not a contract — it's documentation. Contracts must be enforced in CI (schema validation on every PR) and at runtime (pipeline fails if contract is violated).

**Centralizing governance without decentralized ownership.** A central data team responsible for governing every dataset in the organization does not scale. The [[data-storage-paradigms]] data mesh principle applies here: governance is federated to domain teams (who own their data products and are responsible for quality and contracts), while the infrastructure (catalog, lineage, quality platform) is centralized.

**No sensitivity classification.** Applying uniform access controls to all data — everything is accessible or everything requires approval. Classification enables proportional control: public data is freely accessible; PII requires justification and audit; PHI requires HIPAA compliance chain.

## See also

- [[data-storage-paradigms]]
- [[streaming-and-event-data]]
- [[ai-data-fabric]]
- [[compliance-and-regulation]]
- [[coupling-and-versioning-discipline]]
- [[event-sourcing-and-cqrs]]

## Sources

- MDN Digital. (2026). Databricks Unity Catalog in 2026: The Enterprise Governance Layer Your Lakehouse Needs. https://mdn.digital/insights/databricks-unity-catalog-enterprise-governance
- Waehner, K. (2026). Beyond Enterprise Data Lineage: The Case for a Platform-Independent Data Catalog. https://www.kai-waehner.de/blog/2026/05/18/beyond-enterprise-data-lineage-the-case-for-a-platform-independent-data-catalog/
- Springer Nature. (2026). Open Data Governance with Unity Catalog. https://link.springer.com/chapter/10.1007/979-8-8688-2524-8_14
- Databricks. (2026). Data Lineage in Unity Catalog. https://docs.databricks.com/aws/en/data-governance/unity-catalog/data-lineage
- OvalEdge. (2026). Top 25 Data Lineage Tools for Reliable Analytics Governance. https://www.ovaledge.com/blog/data-lineage-tools
- Microsoft Learn. (2026). Data Lineage in Unity Catalog — Azure Databricks. https://learn.microsoft.com/en-us/azure/databricks/data-governance/unity-catalog/data-lineage
