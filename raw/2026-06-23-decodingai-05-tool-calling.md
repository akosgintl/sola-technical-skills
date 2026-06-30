---
title: "Tool Calling: From Scratch to Production"
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, tool-use, tool-calling, production, llm]
updated: 2026-06-30
source_url: https://www.decodingai.com/p/tool-calling-from-scratch-to-production
source_type: article
ingested: 2026-06-23
feeds: [llm-tool-use]
---

# Tool Calling: From Scratch to Production

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Series:** AI Agents Foundations #5 · **URL:** https://www.decodingai.com/p/tool-calling-from-scratch-to-production

## Key takeaways

- Tools are an agent's "hands and senses" — read actions (access external information) and write actions (take external effects). Write actions are often irreversible.
- **Read tools**: real-time APIs, database queries, document retrieval, web search. **Write tools**: code execution (sandboxed), email/calendar, DB writes, file system changes.
- 5-step flow: (1) user sends task + tool definitions → (2) LLM responds with `function_call` → (3) system parses and executes → (4) output returned to LLM → (5) LLM generates final response.
- Manual implementation: define Python function with clear docstring → create JSON schema dict → build tool registry (`handler` + `declaration`) → inject into system prompt → parse `<tool_call>` XML tag from response.
- Framework optimization: decorators (`@tool`) automatically generate schemas from function signatures.
- Native API (Gemini): pass functions directly as `tools=` parameter in `GenerateContentConfig`; SDK generates schemas automatically and handles parsing.
- Code execution: run in sandboxed environments (Docker, gVisor) to prevent security issues.
- Production monitoring: use LLMOps platforms (Opik) to track tool call latency, token usage, cost per invocation, and A/B test configurations.

## Notable claims (with location)

- "Tool calling is at the core of what makes an AI agent useful."
- "Understanding how to build, monitor, and debug tool interactions is one of the most important skills for an AI Engineer."
- Agents in production use 10–100+ tools simultaneously — LLMOps observability is critical at that scale.

## Key visuals

Localized to `raw/assets/2026-06-23-decodingai-05-tool-calling/` (3 diagrams, visual backfill 2026-06-30).

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | LLM agent interacting with external tools | |
| `…-02.png` | Five-step tool-calling request-execute-respond flow | [[llm-tool-use]] |
| `…-03.png` | Mapping agent actions to tool calls and outputs | |

## Feeds these wiki pages

- [[llm-tool-use]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
