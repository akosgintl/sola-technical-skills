---
title: Infrastructure as Code
aliases: [IaC, infrastructure-as-code]
type: concept
domain: platform
priority: P1
roadmap_ref: "4.1"
status: stub
tags: [platform, iac, automation]
updated: 2026-06-19
sources: []
---

# Infrastructure as Code

> [!summary]
> Managing and provisioning infrastructure through declarative, version-controlled definition files rather than manual configuration or ad-hoc scripts.

**Priority:** 🟠 P1 · **Domain:** [[tier-2-solid|Platform Engineering & IaC]] · **Roadmap:** §4.1

## What it is

Infrastructure as Code (IaC) treats servers, networks, and cloud resources as software artifacts defined in machine-readable files. Tools apply these definitions to reach a desired state, making infrastructure reproducible, reviewable, and auditable. Declarative tools (Terraform/OpenTofu) describe the target state; imperative or hybrid tools (Pulumi, CDK) use general-purpose languages to generate it.

## Key concepts

- Terraform / OpenTofu — declarative, provider-based, state-driven
- AWS CDK / cloud-native SDKs — IaC in general-purpose languages
- Pulumi — multi-cloud IaC with real programming languages
- State management, drift detection, and idempotency
- Modules, reuse, and environment promotion

## See also

- [[ai-generated-iac-reviewer]]
- [[policy-as-code]]
- [[cicd-pipeline-architecture]]
- [[developer-experience]]
- [[cloud-governance-at-scale]]

## Sources

- _Stub — no sources ingested yet._
