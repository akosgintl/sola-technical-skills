---
title: Agents as System Citizens
aliases: [agents as first-class actors]
type: concept
domain: ai-agentic
priority: P0
roadmap_ref: "1.2"
status: stub
tags: [ai-agentic, agents, architecture]
updated: 2026-06-19
sources: []
---

# Agents as System Citizens

> [!summary]
> Treating agents as first-class actors in a system — with identities, permissions, quotas, and audit trails — rather than as ephemeral scripts, so they can be governed like any other principal.

**Priority:** 🔴 P0 · **Domain:** [[tier-1-edge|AI & Agentic Architecture]] · **Roadmap:** §1.2

## What it is

This is the architectural stance that an agent is a durable participant in a system, comparable to a user or a service, and must be modeled as such. That means each agent has an identity, scoped access to resources, rate/cost quotas, and a logged history of its actions. The shift reframes agent design from prompt engineering toward systems and identity engineering.

## Key concepts

- Agents as principals with identity
- Least-privilege access and quotas
- Audit trails and accountability
- Governance and policy enforcement
- Lifecycle and provisioning of agents

## See also

- [[agent-identity-and-access]]
- [[agent-governance-and-policy]]
- [[multi-agent-orchestration]]
- [[iam-and-secrets-management]]

## Sources

- _Stub — no sources ingested yet._
