---
title: AI Governance Frameworks
aliases: [AI governance, responsible AI frameworks, NIST AI RMF, ISO 42001]
type: concept
domain: security
status: mature
tags: [security, ai-governance, compliance, nist-ai-rmf, iso-42001, responsible-ai]
updated: 2026-06-21
sources:
  - https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf
  - https://www.iso.org/standard/81230.html
  - https://oecd.ai/en/ai-principles
  - https://www.imda.gov.sg/resources/press-releases-factsheets-and-speeches/press-releases/2024/singapore-imda-model-ai-governance-framework
  - https://www.microsoft.com/en-us/ai/responsible-ai
  - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689
---

# AI Governance Frameworks

> [!summary]
> AI governance frameworks provide structured vocabularies, processes, and accountability mechanisms for identifying, assessing, and managing the risks of AI systems. For architects they translate into concrete programme design: an AI inventory, risk tiers, pre-deployment review gates, and the documentation artefacts that regulators and auditors will inspect.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

An AI governance framework is a structured set of principles, processes, roles, and documentation requirements that an organisation adopts to manage the risks of its AI systems across their lifecycle — from design through deployment to decommissioning. Frameworks differ from regulations: a regulation imposes legally binding obligations; a framework provides a structured vocabulary and process for fulfilling obligations, whether regulatory or self-imposed.

The practical output of an AI governance programme is not a document — it is an operating system: a model inventory that tracks every AI system in production, a risk classification that determines what oversight each system requires, a pre-deployment review gate that ensures required controls exist before a system goes live, and an ongoing monitoring process that detects behavioural drift, safety incidents, and compliance gaps after deployment.

Architects interact with governance frameworks primarily at two points: when designing an AI system (what risk tier applies? what documentation must exist? what HITL gates are required?), and when reviewing an existing system for compliance (does this system have the audit trail, the model card, the red-team report that its risk tier requires?).

## Why it matters

The cost of ungoverned AI is concentrated and delayed: a biased hiring model, a hallucinating medical assistant, or a financial forecasting tool that fails at the tail runs for months before the harm is visible. Governance frameworks create the detection mechanisms — monitoring, red-teaming, incident reporting — that surface these failures before they accumulate.

Regulatory convergence is also accelerating. The EU AI Act, NIST AI RMF, ISO/IEC 42001, and Singapore's IMDA framework all share a common structural logic (inventory → risk tier → controls → monitoring), which means a governance programme built on one framework can achieve compliance with the others with incremental effort. Building a governance programme before regulatory obligations land is the lower-cost path.

For the architect, governance frameworks are a source of design requirements: the EU AI Act's Article 12 audit log mandate, the NIST AI RMF MAP function's system context requirements, and ISO 42001's management review cadence all translate into infrastructure and process choices that are much cheaper to build in than to retrofit.

## Key frameworks

### NIST AI RMF 1.0

The US National Institute of Standards and Technology AI Risk Management Framework (published 2023) is the reference voluntary framework. It structures AI governance into four core functions:

| Function | Purpose | Key activities |
|---|---|---|
| **GOVERN** | Establish accountability and culture | Assign AI roles and responsibilities; define risk tolerance; build governance structures |
| **MAP** | Understand AI context and risk | Inventory AI systems; classify risk; identify stakeholders and harm scenarios |
| **MEASURE** | Analyse and quantify risk | Evaluate system performance on safety/fairness/reliability/explainability; quantify uncertainty |
| **MANAGE** | Prioritise and treat risk | Implement controls; document residual risk; establish incident response; decommission when needed |

GOVERN runs continuously and creates the conditions for the other three. MAP, MEASURE, and MANAGE cycle through each AI system at intervals proportional to its risk tier.

The NIST AI RMF Playbook provides 600+ suggested actions across the four functions, but the framework is explicitly non-prescriptive — organisations select the actions appropriate to their risk profile and context. This makes it more adaptable than the EU AI Act but harder to audit against.

**AI RMF Profiles** allow organisations to document their current state (Current Profile), their target state (Target Profile), and the gap between them — providing a structured roadmap for governance maturity.

### ISO/IEC 42001

The first international management system standard for AI (analogous to ISO 27001 for information security). An ISO 42001 certification demonstrates that an organisation has implemented a systematic, audited AI management system.

Key structural elements:
- **Context of the organisation:** identify internal/external stakeholders, AI objectives, AI system scope.
- **Leadership:** top management commitment; AI policy; roles and responsibilities.
- **Planning:** risk and opportunity assessment; AI objectives with measurable targets.
- **Support:** resources, competence, awareness, documentation.
- **Operation:** AI system lifecycle controls; impact assessments; supplier requirements.
- **Performance evaluation:** monitoring, measurement, internal audit, management review.
- **Improvement:** nonconformity handling; continual improvement.

ISO 42001 integrates with ISO 27001 (information security) and ISO 9001 (quality management), allowing organisations with existing management system certifications to extend them to AI governance. A combined ISO 27001 + ISO 42001 audit covers most of the technical controls required by the EU AI Act and NIST AI RMF.

### OECD AI Principles

The OECD Principles on AI (adopted by 50+ countries) define five high-level principles:
1. **Inclusive growth, sustainable development, and well-being** — AI should benefit people and the planet.
2. **Human-centred values and fairness** — AI should respect the rule of law, human rights, and democratic values.
3. **Transparency and explainability** — AI actors should be transparent about AI capabilities and limitations.
4. **Robustness, security, and safety** — AI systems should function reliably and safely across their lifecycle.
5. **Accountability** — AI actors should be accountable for the proper functioning of AI systems.

The OECD Principles are the genealogical source for most national AI policies. The EU AI Act, NIST AI RMF, and Singapore IMDA framework all trace directly to these principles. Understanding them clarifies why the technical requirements in specific frameworks exist.

### Singapore IMDA Model AI Governance Framework

Singapore's framework is notable for its practical, organisation-level guidance — more granular than the OECD principles and less legalistic than the EU AI Act. The January 2026 v3 update adds an **Agentic AI supplement** covering autonomous agent-specific risks:
- Defining clear objective specifications and guardrails before deployment
- Human oversight proportional to consequence severity
- Agent action logging and audit trail requirements
- Multi-agent trust chain governance

The IMDA framework is the most directly actionable for practitioners building AI systems, with worked examples and self-assessment tools.

### EU AI Act

Covered in [[compliance-and-regulation]], but its governance architecture is worth restating here. The EU AI Act is a governance framework *with legal force*. Its key governance instruments:
- **Risk classification system** — the highest-stakes framework decision: which tier does this system belong to?
- **Conformity assessment** — high-risk systems must complete a conformity assessment (self-assessment or third-party audit) before deployment.
- **Technical documentation** — required for high-risk systems: training data description, system architecture, performance metrics, risk assessment, HITL description.
- **EU database registration** — deployers of high-risk AI in regulated sectors must register before deployment.
- **Post-market monitoring** — ongoing performance tracking and incident reporting after deployment.

### Microsoft Responsible AI Standard

Microsoft's internal responsible AI framework (public version available) defines six principles: fairness, reliability and safety, privacy and security, inclusiveness, transparency, and accountability. It operationalises these through:
- **Impact assessments** at design time (Responsible AI Impact Assessment template)
- **Red team testing** for frontier models and high-stakes applications
- **Sensitivity review** for features that involve personal data or sensitive categories
- The **Azure AI Content Safety** API as a programmatic guardrail

Microsoft's framework is valuable as a practitioner model: it shows how a large engineering organisation implements governance at scale, with concrete review gates and tooling.

## Governance programme design

### The model inventory

Every governance programme starts with an inventory of AI systems. Without knowing what AI systems exist, no risk assessment can be performed and no controls can be assigned. The inventory captures:
- System name and purpose
- Risk tier classification
- Training data description and provenance
- Model type and version
- Deployed contexts and user population
- Owner and accountable executive
- Last review date

The AI inventory is the governance programme's source of truth. It should be version-controlled, access-controlled, and reviewed on a quarterly cadence for new systems and for status changes on existing ones.

### Risk classification

The risk tier determines the oversight level. Using the EU AI Act categories as a practical scaffold:

| Tier | Criteria | Governance requirements |
|---|---|---|
| Critical / High-risk | Output affects consequential decisions (hiring, credit, healthcare, criminal justice); biometric processing; critical infrastructure | Full conformity assessment; technical documentation; HITL; audit logs; post-market monitoring |
| Significant | Output influences but does not determine consequential decisions; broad user population | Abbreviated impact assessment; model card; monitoring plan; periodic red-team |
| Standard | Internal tooling; output reviewed by humans before use; low consequence | Brief impact assessment; standard monitoring; annual review |
| Minimal | Narrow, low-stakes automation; no sensitive data | Inventory entry only |

### Pre-deployment review gate

A governance gate before production deployment requires documented evidence that:
1. Risk classification is complete and approved.
2. Required controls exist (HITL, audit logs, guardrails proportional to tier).
3. Impact assessment is complete.
4. Technical documentation exists (for high-risk systems).
5. Red-team or safety testing report exists (for critical systems).
6. Monitoring plan is in place.

The gate is a process checkpoint, not a technical control — it requires a human decision that the documentation is complete and the controls are appropriate. See [[human-in-the-loop-design]] and [[delegate-review-own]].

### Ongoing monitoring and incident response

Post-deployment governance activities:
- **Performance monitoring:** accuracy, fairness, and reliability metrics tracked in production (see [[ai-evaluation-and-quality]]).
- **Drift detection:** distributional shift in inputs or outputs that indicates the system is operating outside its validated context.
- **Incident reporting:** a defined process for identifying, classifying, and reporting AI incidents — to internal stakeholders and, for regulated systems, to competent authorities (EU AI Act Article 73 requires reporting of serious incidents).
- **Periodic review:** model cards and risk assessments reviewed annually (or after significant model changes).

## Design decisions and trade-offs

**Single framework vs. composite.** An organisation operating under EU AI Act obligations and US federal contracts may find NIST AI RMF more aligned with US procurement requirements while ISO 42001 provides the audit-ready documentation structure. A composite programme (NIST AI RMF as the operational framework, ISO 42001 as the management system, EU AI Act as the compliance checklist) is more work to establish but reduces redundancy compared to three separate programmes.

**Centralised vs. federated governance.** A centralised AI Review Board (ARB) ensures consistent risk classification but becomes a bottleneck as AI adoption scales. A federated model (each business unit applies the framework independently, with central audit) scales better but requires governance training investment and periodic audits to maintain consistency. Most organisations start centralised and federate as the programme matures.

**Documentation depth vs. velocity.** Heavy documentation requirements slow AI deployment. The risk tier calibration is the key lever: minimal-risk systems should have near-zero documentation overhead; the heavy requirements should apply only to the systems that genuinely warrant them. A governance programme that applies the same documentation burden to a spam filter and a loan adjudication system is poorly calibrated.

## State of the art

**ISO/IEC 42001** certifications began in 2024; the major certification bodies (BSI, DNV, Bureau Veritas) are now offering 42001 audits. Early adopters are primarily enterprises in regulated sectors (financial services, healthcare) that already have ISO 27001 and are extending their management system.

**NIST AI RMF adoption** is driven by US federal procurement requirements. OMB Memorandum M-24-10 (March 2024) directs federal agencies to use the AI RMF for managing AI risks in government applications. Federal contractors with AI in scope are increasingly expected to demonstrate AI RMF alignment.

**EU AI Act governance infrastructure** is maturing: the European AI Office (established 2024) is developing conformity assessment guidance, harmonised standards under the AI Act (CEN-CENELEC JTC 21), and the EU AI database registration interface. High-risk AI system operators have until August 2026 for full compliance.

**Agentic AI governance gap.** All major frameworks were designed for traditional ML systems (defined training data, stable model, predictable output distribution). Autonomous agents — which plan, use tools, and produce non-deterministic action sequences — are a poorly covered case. The Singapore IMDA v3 Agentic supplement and OWASP Agentic AI Top 10 (2025) are the leading edge of framework extension; formal standardisation is 1–2 years out. See [[agent-governance-and-policy]] for the current best practices.

> [!tip]
> Start the governance programme with the inventory, not the framework. A complete AI inventory — what systems exist, who owns them, what data they use — is the prerequisite for every other governance activity. It can be done with a spreadsheet before any framework is selected, and it immediately surfaces the highest-risk systems that need governance first.

## Pitfalls and anti-patterns

- **Framework selection as a substitute for governance.** Adopting a framework acronym without implementing its processes produces documentation without controls. The framework is the scaffolding; the programme is the structure.
- **Applying the same oversight to all AI.** A spam classifier and a credit scoring model require very different governance investment. Risk tier calibration is the governance programme's most important design decision.
- **Governance as a pre-deployment checklist only.** Systems that passed their pre-deployment review and are never reviewed again drift: the data changes, the use case expands, the user population shifts. Post-deployment monitoring and periodic review are not optional extras.
- **No AI inventory.** A governance programme without an inventory is governing an unknown population. Shadow AI (AI tools adopted without IT knowledge) is the inventory's most important gap to close.
- **Red-teaming as theatre.** Red-team exercises that test for already-known issues without adversarial creativity produce false assurance. Effective red-teaming requires access to the system, time, and a team motivated to find failures.
- **Treating NIST AI RMF as compliance.** The AI RMF is voluntary and non-prescriptive. It cannot be "passed." Organisations that claim AI RMF compliance without specifying what actions they implemented are claiming something the framework does not offer.

## See also

- [[compliance-and-regulation]] — EU AI Act, GDPR, and sector regulatory requirements
- [[agent-governance-and-policy]] — policy-as-code and OWASP Agentic AI governance for autonomous systems
- [[human-in-the-loop-design]] — HITL as the core EU AI Act Article 14 control
- [[ai-evaluation-and-quality]] — measurement functions that feed the AI RMF MEASURE function
- [[ai-specific-security]] — security controls that overlap with governance requirements
- [[delegate-review-own]] — the individual-level accountability discipline underlying governance

## Sources

- NIST (2023). *AI Risk Management Framework 1.0.* NIST AI 100-1. https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf
- ISO (2023). *ISO/IEC 42001:2023 — Information Technology — AI — Management System.* https://www.iso.org/standard/81230.html
- OECD (2024). *OECD AI Principles.* https://oecd.ai/en/ai-principles
- IMDA Singapore (2026). *Model AI Governance Framework v3 with Agentic AI Supplement.* https://www.imda.gov.sg/resources/press-releases-factsheets-and-speeches/press-releases/2024/singapore-imda-model-ai-governance-framework
- Microsoft (2025). *Microsoft Responsible AI Standard.* https://www.microsoft.com/en-us/ai/responsible-ai
- European Parliament (2024). *EU AI Act — Regulation (EU) 2024/1689.* https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689
