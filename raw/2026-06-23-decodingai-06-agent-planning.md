---
title: "Writing AI Agents From Scratch: Planning Is The Key"
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, agent-planning, react, plan-and-execute, reasoning]
updated: 2026-06-30
source_url: https://www.decodingai.com/p/ai-agents-planning
source_type: article
ingested: 2026-06-23
feeds: [agent-planning, agentic-loop]
---

# Writing AI Agents From Scratch: Planning Is The Key

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Series:** AI Agents Foundations #6 · **URL:** https://www.decodingai.com/p/ai-agents-planning

## Key takeaways

- "Planning is the missing piece between tool loops and true AI agents."
- Running tools in a loop without planning fails in complex scenarios — the agent reacts to each observation without a clear strategy or goal decomposition.
- Key insight: separate planning from execution — "ask the model to first plan or reason, and then, as a distinct step, produce a final answer or take an action."
- **ReAct** (Reason + Act): continuous Thought → Action → Observation cycle. High interpretability, natural error recovery; sequential so potentially slower.
- **Plan-and-Execute**: planner decomposes upfront → evaluator validates feasibility → executor runs steps (sequential or parallel). Efficient via batching; less flexible for exploratory problems; risks rigid adherence to imperfect plans.
- Modern reasoning LLMs (Gemini with `thinking_budget`) internalize the planning phase — combines planning and execution into a single API call, reducing latency and cost.
- Practical monitoring is critical because LLMs handle planning autonomously across potentially hundreds of steps.
- Discovery context: author was building ZTRON (financial services AI agent) and found the tool-calling system was reacting without a clear strategy.

## Notable claims (with location)

- "Modern AI agents at their core implement derivatives of ReAct and Plan-and-Execute patterns."
- ReAct: two LLM calls per loop — one for reasoning, one for action selection — maintaining full context history.
- Plan-and-Execute advantage: parallelization and batch processing for predictable, well-defined tasks.

## Key visuals

Localized to `raw/assets/2026-06-23-decodingai-06-agent-planning/` (5 diagrams, visual backfill 2026-06-30).

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | Separating planning/reasoning from action/tool-calling | |
| `…-02.png` | ReAct (Reason + Act) interleaved loop | [[agent-planning]] |
| `…-03.png` | Plan-and-Execute agent pattern | [[agent-planning]] |
| `…-04.png` | Input / reasoning / output tokens with reasoning LLMs | |
| `…-05.png` | ReAct agents with reasoning LLMs | |

## Feeds these wiki pages

- [[agent-planning]]
- [[agentic-loop]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
