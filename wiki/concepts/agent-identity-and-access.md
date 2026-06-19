---
title: Agent Identity and Access
aliases: [agent IAM, agent RBAC, agent ABAC]
type: concept
domain: ai-agentic
status: stub
tags: [ai-agentic, agents, identity, security]
updated: 2026-06-19
sources: []
---

# Agent Identity and Access

> [!summary]
> Assigning agents their own identities and enforcing scoped, least-privilege access via RBAC/ABAC, quotas, and credential management so an agent can only do what its role permits.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Agent identity and access applies established IAM thinking to autonomous agents: each agent (or agent instance) gets a distinct, verifiable identity and a tightly scoped set of permissions. Role-based and attribute-based access controls, spending and rate quotas, and short-lived credentials prevent an over-broad or compromised agent from causing wide damage. It is the enforcement layer beneath "agents as system citizens."

## Key concepts

- RBAC and ABAC for agents
- Least-privilege scoping
- Cost and rate quotas
- Credential and secret management for agents
- Per-agent identity and attestation

## See also

- [[agents-as-system-citizens]]
- [[agent-governance-and-policy]]
- [[iam-and-secrets-management]]
- [[zero-trust-architecture]]

## Sources

- _Stub — no sources ingested yet._
