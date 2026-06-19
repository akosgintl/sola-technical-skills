---
title: Agent-to-Agent Protocols
aliases: [A2A, inter-agent communication]
type: concept
domain: ai-agentic
priority: P0
roadmap_ref: "1.1.2"
status: stub
tags: [ai-agentic, agents, protocols]
updated: 2026-06-19
sources: []
---

# Agent-to-Agent Protocols

> [!summary]
> The conventions and mechanisms by which agents decompose tasks, share state, exchange messages, and handle each other's failures — the "wire protocol" of collaboration between autonomous agents.

**Priority:** 🔴 P0 · **Domain:** [[tier-1-edge|AI & Agentic Architecture]] · **Roadmap:** §1.1.2

## What it is

Agent-to-agent protocols define how agents talk to one another rather than to a human or a single model. They cover how a task is broken into subtasks, how shared or scoped state is passed along, and how an agent recovers when a peer returns bad output or times out. Emerging standards (e.g. A2A-style protocols) aim to make agents from different vendors interoperable, much as MCP standardizes tool access.

## Key concepts

- Task decomposition and delegation
- Shared vs. scoped state passing
- Message formats and capability discovery
- Failure handling, retries, and timeouts
- Interoperability standards (A2A, agent cards)

## See also

- [[multi-agent-orchestration]]
- [[model-context-protocol]]
- [[agents-as-system-citizens]]
- [[agent-governance-and-policy]]

## Sources

- _Stub — no sources ingested yet._
