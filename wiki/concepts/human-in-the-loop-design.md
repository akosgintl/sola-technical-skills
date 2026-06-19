---
title: Human-in-the-Loop Design
aliases: [HITL, approval gates]
type: concept
domain: ai-agentic
priority: P0
roadmap_ref: "1.1.3"
status: stub
tags: [ai-agentic, agents, governance]
updated: 2026-06-19
sources: []
---

# Human-in-the-Loop Design

> [!summary]
> The deliberate placement of human approval, review, and intervention points within agentic workflows so that consequential actions are gated, auditable, and reversible — operationalizing "delegate, review, own."

**Priority:** 🔴 P0 · **Domain:** [[tier-1-edge|AI & Agentic Architecture]] · **Roadmap:** §1.1.3

## What it is

Human-in-the-loop design decides where a human must approve, can override, or is merely notified as an agent executes. It balances autonomy against risk: low-stakes steps run unattended, while irreversible or high-impact actions pause for confirmation. Good HITL design makes the gates explicit, low-friction, and traceable rather than bolting on approvals as an afterthought.

## Key concepts

- Approval gates and confirmation checkpoints
- "Delegate, review, own" responsibility model
- Risk-tiered autonomy levels
- Escalation and override paths
- Auditability of human decisions

## See also

- [[multi-agent-orchestration]]
- [[delegate-review-own]]
- [[accountable-human-layer]]
- [[agent-governance-and-policy]]

## Sources

- _Stub — no sources ingested yet._
