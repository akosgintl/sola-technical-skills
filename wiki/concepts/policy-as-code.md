---
title: Policy as Code
aliases: [PaC, policy-as-code]
type: concept
domain: platform
status: stub
tags: [platform, policy, governance, security]
updated: 2026-06-19
sources: []
---

# Policy as Code

> [!summary]
> Expressing governance, security, and compliance rules as version-controlled code that is automatically evaluated against infrastructure and deployments.

**Domain:** [[tier-2-solid|Platform Engineering & IaC]]

## What it is

Policy as Code (PaC) encodes organizational rules — naming, tagging, network boundaries, allowed regions, cost guardrails — as executable policies enforced in CI/CD and at admission time. It shifts compliance left, turning manual review into automated, testable gates. This is increasingly the control plane for reviewing AI-generated infrastructure.

## Key concepts

- Open Policy Agent (OPA) / Rego
- HashiCorp Sentinel
- Kyverno — Kubernetes-native policy
- Admission control and CI/CD policy gates
- Guardrails vs. blockers; advisory vs. mandatory enforcement

## See also

- [[ai-generated-iac-reviewer]]
- [[infrastructure-as-code]]
- [[cicd-pipeline-architecture]]
- [[cloud-governance-at-scale]]
- [[software-supply-chain-security]]

## Sources

- _Stub — no sources ingested yet._
