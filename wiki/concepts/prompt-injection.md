---
title: Prompt Injection
aliases: [prompt injection, jailbreaking, indirect injection]
type: concept
domain: security
status: stub
tags: [security, ai-security, prompt-injection]
updated: 2026-06-19
sources: []
---

# Prompt Injection

> [!summary]
> An attack where adversarial instructions — placed directly or hidden in retrieved/tool content — hijack an LLM's behavior, the top security risk for agentic and RAG systems.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Prompt injection exploits the fact that an LLM cannot reliably separate trusted instructions from untrusted data in its context. Direct injection comes from a malicious user; indirect injection is smuggled in through documents, web pages, or tool outputs the model ingests. In agentic systems it can trigger data exfiltration or unauthorized actions, making it a systemic risk rather than a content-quality issue.

## Key concepts

- Direct vs. indirect (data-borne) injection
- Instruction/data confusion in LLMs
- Data exfiltration and tool misuse
- Mitigations: isolation, allow-lists, output checks
- Defense-in-depth, not a single fix

## See also

- [[ai-specific-security]]
- [[guardrails-and-output-validation]]
- [[model-supply-chain-security]]
- [[agent-governance-and-policy]]

## Sources

- _Stub — no sources ingested yet._
