---
title: Compliance and Regulation
aliases: [compliance, regulation, GDPR, regulatory design, privacy by design]
type: concept
domain: security
status: mature
tags: [security, compliance, regulation, privacy, gdpr, hipaa, ai-act, pci-dss, dora]
updated: 2026-06-21
sources:
  - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02016R0679-20160504
  - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689
  - https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf
  - https://www.hhs.gov/hipaa/for-professionals/security/index.html
  - https://www.pcisecuritystandards.org/document_library/?document=pci_dss
  - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32022R2554
---

# Compliance and Regulation

> [!summary]
> Compliance and regulation is the practice of treating legal and regulatory constraints as first-class design inputs — not post-hoc audits. The cheapest compliance is compliance by construction: data residency, minimisation, audit logs, and access controls baked into the architecture before a single line of production code ships.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Regulatory requirements place concrete constraints on how data is collected, stored, processed, and disclosed; how AI systems are designed and operated; and what controls and evidence organisations must maintain. Architects who encounter these requirements late — during a security review, a vendor audit, or a regulatory examination — face expensive retrofits: adding encryption to databases that weren't designed for key management, implementing data residency in systems built with cross-region replication, or providing audit logs that the system was never instrumented to produce.

Compliance by construction treats each requirement as a design input alongside performance, cost, and reliability. The outcome is a system that is compliant by virtue of how it is built, not by virtue of a checklist applied after the fact.

The regulatory landscape is not static. Privacy law, sector-specific rules, and AI-specific legislation are all expanding simultaneously. Architects need working fluency across the major regimes — not legal expertise, but enough understanding to identify which requirements apply to a given system and to ask the right questions before committing to a design.

## Why it matters

Retrofitting compliance is expensive in every dimension. GDPR's right-to-erasure requirement on a system built with immutable event logs requires building a separate erasure mechanism or restructuring the log. PCI DSS's requirement to isolate card data environment (CDE) components is near-impossible to add to a flat-network architecture after the fact. The EU AI Act's audit log requirements (append-only, ≥6 months retention, hash-chained) require infrastructure that must be planned before the AI system is deployed.

The penalty profile makes non-compliance a business risk, not only a legal one: GDPR fines up to €20M or 4 % of global annual turnover; EU AI Act fines up to €35M or 7 % of global turnover for prohibited AI practices; PCI DSS non-compliance can result in card scheme disqualification. These are not edge cases — enforcement activity has increased significantly since 2022.

For AI systems specifically, the combination of GDPR (training data contains personal data), EU AI Act (the model is a high-risk system), and sector regulation (the model operates in healthcare or finance) stacks compliance requirements that must all be met simultaneously.

## Key concepts

### Privacy regulation (GDPR and successors)

**GDPR** (EU Regulation 2016/679, in force May 2018) is the reference privacy regime. Key requirements with direct architectural implications:

| Requirement | Architectural implication |
|---|---|
| Lawful basis for processing | Data collection must be gated on consent or legitimate interest; systems must record the basis per data category |
| Data minimisation | Collect only what is necessary; schema design and API contracts should enforce this |
| Purpose limitation | Data collected for one purpose cannot be reused for another without a new lawful basis |
| Data subject rights (access, erasure, portability, rectification) | Systems must support per-user export, deletion, and correction; immutable logs need erasure mechanisms |
| Breach notification (72 hours) | Requires incident detection infrastructure and a documented response process |
| Cross-border transfer | Data leaving the EU/EEA requires SCCs, BCRs, or an adequacy decision; affects where systems can be deployed |
| Data Protection by Design | Privacy controls must be integrated into system design, not added later |

GDPR's adequacy framework: the EU Commission has recognised a small number of jurisdictions (UK, Switzerland, Japan, South Korea, US under the EU-US Data Privacy Framework) as providing adequate protection. Transfers outside the adequacy list require Standard Contractual Clauses (SCCs) or Binding Corporate Rules.

Privacy law outside the EU follows GDPR patterns but differs in scope and enforcement: CCPA/CPRA (California), LGPD (Brazil), PDPA (Thailand, Singapore), PIPL (China). Architects building global systems should treat GDPR as the design floor — other regimes are generally less strict, so a GDPR-compliant design is usually compliant elsewhere.

### Sector-specific regulation

**HIPAA** (US healthcare): the Security Rule requires administrative, physical, and technical safeguards for electronic Protected Health Information (ePHI). Technical requirements: access controls, audit logs, transmission security (encryption in transit), and integrity controls. The Privacy Rule governs disclosure. AI systems processing health data are covered entities or business associates and must execute BAAs with their cloud providers.

**PCI DSS 4.0** (payment cards, effective March 2025): twelve requirements covering the Card Data Environment (CDE). Architectural mandates: network segmentation to isolate CDE, encryption at rest and in transit for card data, access controls with least privilege, continuous vulnerability scanning, and annual penetration testing. PCI DSS 4.0 adds customised approach options for controls, giving more flexibility but requiring more documentation.

**SOX** (US financial reporting): IT general controls (ITGC) govern systems that produce financial data. Change management, access controls, and audit logging are the primary technical controls. Not a direct cryptography or network requirement — the audit trail and access control implications are the relevant architectural constraints.

**DORA** (EU Digital Operational Resilience Act, in force January 2025): applies to financial entities in the EU and their ICT service providers. Requires: ICT risk management framework, incident reporting (major ICT incidents within 4 hours of classification), digital operational resilience testing (TLPT — threat-led penetration testing for significant institutions), and third-party ICT risk management (including cloud providers). DORA is the first EU regulation that directly governs cloud providers serving financial entities.

### AI regulation

**EU AI Act** (Regulation 2024/1689, phased enforcement from 2024 through August 2026): the first comprehensive AI regulation. Risk tiering drives technical requirements:

| Risk tier | Examples | Key requirements |
|---|---|---|
| Unacceptable (banned) | Social scoring, real-time public biometric surveillance | Prohibited outright |
| High-risk | Healthcare AI, hiring decisions, credit scoring, biometric identification | Conformity assessment, technical documentation, audit logs (≥6 months, append-only), HITL (Article 14), accuracy/robustness testing |
| Limited-risk | Chatbots, deepfake generators | Transparency disclosures (AI-generated content labelling) |
| Minimal-risk | Spam filters, AI-assisted search | No mandatory requirements |

High-risk AI systems require registration in an EU database, CE marking (for products), and a post-market monitoring system. General Purpose AI (GPAI) models above a compute threshold (10²³ FLOPs) face additional obligations including security testing and model documentation.

**NIST AI RMF 1.0** (2023): voluntary US framework with four functions — GOVERN (accountability), MAP (context), MEASURE (analysis), MANAGE (response). Not legally binding but increasingly referenced in US federal procurement and sector guidance. The RMF's GOVERN function maps directly to the accountability chain in [[agent-governance-and-policy]] and [[delegate-review-own]].

**US Executive Order 14110** (2023): requires red-teaming for frontier models above a compute threshold, safety reporting, and watermarking for AI-generated content. The OMB follow-on guidance applies to federal agencies.

### Compliance by design: implementation patterns

**Data residency.** Requirements to keep data within a jurisdiction (EU data in EU, health data in the country of collection) translate to: region selection in multi-cloud architectures, replication topology constraints, and exclusion of global services that move data across regions by default (some CDN edge caches, global DNS, multi-region databases).

**Data minimisation.** Schema design principle: collect the minimum fields required for the stated purpose. API contracts should not request unnecessary fields. Feature engineering pipelines should not load PII into training datasets unless the feature directly requires it.

**Right to erasure.** Architecturally, erasure is hard in:
- Immutable event logs (solution: pseudonymisation — store a user token in the log, not the real identity; erase the token mapping table)
- Replicated databases (solution: ensure erasure runs across all replicas and backups within the retention window)
- Embeddings / trained models (solution: training data governance + differential privacy; model retraining or fine-tuning with data removed)
- Backups (solution: encrypt backups with per-user keys; erasure = key deletion)

**Audit logging.** Most regulations require evidence that controls are operating. The audit log must be: complete (all relevant events captured), append-only (no modification or deletion), tamper-evident (hash-chaining or external integrity verification), retained for the required period (GDPR: no specific retention period but "no longer than necessary"; EU AI Act Article 12: ≥6 months; PCI DSS: 12 months), and access-controlled (read access for auditors; no write access for any operational account).

**Shared responsibility.** Cloud providers handle physical and infrastructure compliance (data centre audits, hardware disposal, network security). Customers are responsible for: data classification, access controls to their accounts, encryption key management (for CMK), their own application security, and their data's residency and retention. The shared responsibility model is documented per provider (AWS, GCP, Azure all publish SR models by service) and must be mapped to each regulatory requirement.

**Compliance as code.** Automated evidence collection reduces manual audit burden: AWS Config / Azure Policy / GCP Security Command Center detect drift from compliant configurations continuously; Infracost + OPA enforce cost and policy gates in IaC pipelines; CloudTrail / Audit Logs provide tamper-evident records that can be exported directly to auditors. The target state: compliance evidence is generated automatically as a byproduct of normal operations, not assembled manually before an audit.

## Design decisions and trade-offs

**Compliance scope containment.** The most effective compliance technique is reducing the scope of regulated data. If card data never touches the application server (handled entirely by a PCI-compliant payment processor via tokenisation), PCI DSS scope shrinks dramatically. If PII is pseudonymised at collection and the key is held in a separate system, GDPR obligations are reduced for most downstream systems. Scope containment is cheaper and more reliable than making a large system compliant.

**Data residency vs. resilience.** Strict data residency constraints (EU data in EU only) limit the geographic options for disaster recovery. An active-active multi-region architecture that satisfies normal resilience requirements may not be available if both active regions must be within the jurisdiction. Data residency and resilience must be co-designed.

**Privacy-preserving ML vs. compliance.** Training a model on personal data incurs GDPR obligations. Alternatives: federated learning (model trained on device, only gradients shared), differential privacy (mathematical noise added to training data or model outputs to prevent individual identification), synthetic data generation. These techniques add training complexity and may reduce model quality; the trade-off is compliance scope containment vs. model capability.

**Regulation stacking.** A US healthcare company with EU employees operating AI-assisted hiring runs under HIPAA, GDPR, and the EU AI Act simultaneously. Requirements from multiple regimes must be reconciled; where they conflict, the stricter requirement prevails. Legal counsel determines applicability; architects design to the resulting requirement set.

## State of the art

**EU AI Act enforcement** began in phases from 2024: prohibited practices (Article 5) banned from February 2025; GPAI model obligations from August 2025; high-risk system requirements fully in force from August 2026. The Article 14 HITL mandate and Article 12 audit log requirements are driving architectural changes in AI systems across all regulated sectors. See [[human-in-the-loop-design]] and [[agent-governance-and-policy]].

**DORA** became applicable January 2025, driving significant architectural work in EU financial services: ICT risk registers, cloud provider contractual requirements (Article 30), and TLPT programmes for systemic institutions. The major cloud providers (AWS, Azure, GCP) have published DORA-aligned contracts and compliance documentation.

**Privacy-enhancing technologies** (PETs): differential privacy has moved from research to production (Apple and Google use it for telemetry aggregation; the US Census Bureau uses it for published data). Homomorphic encryption remains impractical for most workloads; secure multi-party computation is in production for specific use cases (private set intersection for fraud detection). Synthetic data generation (Gretel.ai, Mostly AI, SDV) is widely adopted for test environments and ML feature engineering.

**SOC 2 Type II** is the de-facto compliance framework for SaaS companies outside sector-specific regulation. The five Trust Service Criteria (Security, Availability, Processing Integrity, Confidentiality, Privacy) map to most of the controls discussed here. A SOC 2 Type II report is increasingly a procurement requirement for B2B software.

> [!tip]
> Build the data map before designing the system: what personal data is collected, where it lives, who can access it, and how long it is retained. The data map is the input to the compliance design; without it, compliance is guesswork.

## Pitfalls and anti-patterns

- **Compliance as a post-build audit.** Every requirement discovered after architecture is set costs 5–10× more to address than if designed in.
- **Conflating compliance with security.** A compliant system is not necessarily a secure system. PCI DSS compliance does not guarantee the system won't be breached; it guarantees the controls that reduce breach risk and limit scope.
- **Scope creep of regulated data.** Systems that don't need PII often acquire it incrementally through log enrichment, debugging instrumentation, or feature additions. Regular data audits prevent scope inflation.
- **Manual audit evidence collection.** Producing compliance evidence manually before an audit is slow, error-prone, and opaque. Automated, continuous evidence collection is the production standard.
- **Backup blindspot.** Backup and disaster recovery systems regularly escape compliance controls. Backups must be encrypted, access-controlled, and subject to the same erasure obligations as primary systems.
- **Over-relying on the cloud provider's shared responsibility.** Cloud providers handle infrastructure; the customer owns everything above it. "The cloud provider is SOC 2 certified" does not mean the customer's application is.
- **GDPR adequacy assumption.** Transferring data to a jurisdiction without checking the adequacy status or executing SCCs is a GDPR violation regardless of the technical security controls in place.

## See also

- [[ai-governance-frameworks]] — framework-level AI governance aligned with regulation
- [[data-governance-and-lineage]] — data cataloguing, classification, and lineage as compliance infrastructure
- [[encryption-and-key-management]] — encryption controls required by most regulatory regimes
- [[human-in-the-loop-design]] — EU AI Act Article 14 HITL mandate
- [[agent-governance-and-policy]] — audit log and policy requirements for AI systems
- [[zero-trust-architecture]] — access control framework underlying most compliance requirements
- [[cloud-governance-at-scale]] — organisational governance for multi-account cloud environments

## Sources

- European Parliament (2016). *General Data Protection Regulation — Regulation (EU) 2016/679.* https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:02016R0679-20160504
- European Parliament (2024). *EU AI Act — Regulation (EU) 2024/1689.* https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689
- NIST (2023). *AI Risk Management Framework 1.0.* NIST AI 100-1. https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf
- US HHS (2024). *HIPAA Security Rule Guidance.* https://www.hhs.gov/hipaa/for-professionals/security/index.html
- PCI Security Standards Council (2022). *PCI DSS v4.0.* https://www.pcisecuritystandards.org/document_library/?document=pci_dss
- European Parliament (2022). *Digital Operational Resilience Act — Regulation (EU) 2022/2554.* https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32022R2554
