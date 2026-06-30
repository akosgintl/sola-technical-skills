---
title: "Building Production ReAct Agents From Scratch"
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, react, langgraph, agents, production, structured-outputs]
updated: 2026-06-30
source_url: https://www.decodingai.com/p/building-production-react-agents
source_type: article
ingested: 2026-06-23
feeds: [agent-planning, agentic-loop]
---

# Building Production ReAct Agents From Scratch

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Series:** AI Agents Foundations #7 · **URL:** https://www.decodingai.com/p/building-production-react-agents

## Key takeaways

- ReAct = Reason (Thought) → Act (Action) → Observe cycle implemented as a stateful graph with two primary nodes (model, tools) and conditional edges.
- LangGraph `StateGraph`: model node (reasoning + tool selection) + tools node (execution) + conditional edges (`should_continue`) = the ReAct loop.
- State: `AgentState` with `messages: Sequence[BaseMessage]` and `structured_response: Optional[...]`; `add_messages` reducer preserves full conversation history.
- Model node: receives state → generates `AIMessage` with `tool_calls` pending → routes to tools or END.
- Tools node (`ToolNode`): executes `tool_calls`, uses `Send` objects for parallel execution, wraps errors in `ToolMessage` (prevents crashes).
- Exit conditions: (1) model generates no `tool_calls` + `structured_response` populated, or (2) conditional edge explicitly routes to END.
- Two structured output strategies: **ToolStrategy** (schema as a special tool — works with any tool-calling model) vs. **ProviderStrategy** (native JSON mode — more reliable with supported models).
- Modern reasoning models (Gemini Flash, Claude) handle planning + tool selection in one API call — single model node is sufficient; no separate planning node needed.
- Production requirements: robust error handling, max iteration limits, structured output validation, parallel tool execution, observability integration.
- Author built this after studying LangGraph source code to understand why it was more complex than needed for simple cases.

## Notable claims (with location)

- "Simple conditional logic and basic loops that should require minimal effort become complex when forced into graph paradigms."
- ToolStrategy: agent "calls" the Pydantic schema as a tool to signal completion; framework parses args into model; triggers loop termination.
- Failure handling: agent observes tool failures as data points — resilience is built into the ReAct observation phase.

## Key visuals

Localized to `raw/assets/2026-06-23-decodingai-07-react-agents/` (1 diagram, visual backfill 2026-06-30). Two further diagrams in this article are byte-identical reuses of figures in [[2026-06-23-decodingai-06-agent-planning]] (cross-article image reuse) and were not re-localized.

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | Theoretical ReAct loop vs. LangGraph implementation | [[agent-planning]] |

## Feeds these wiki pages

- [[agent-planning]]
- [[agentic-loop]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
