---
title: LLM Tool Use
aliases: [tool calling, function calling, tool use, LLM tool calling, agent tools]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, tool-use, tool-calling, function-calling, agents, production]
updated: 2026-06-23
sources:
  - raw/2026-06-23-decodingai-05-tool-calling.md
  - raw/2026-06-23-decodingai-06-agent-planning.md
  - raw/2026-06-23-decodingai-07-react-agents.md
  - "https://www.decodingai.com/p/tool-calling-from-scratch-to-production"
  - "https://ai.google.dev/gemini-api/docs/function-calling"
  - "https://docs.anthropic.com/en/docs/build-with-claude/tool-use"
---

# LLM Tool Use

> [!summary]
> Tool use (also called function calling) is the mechanism by which an LLM requests the execution of external functions and incorporates their results into its reasoning. Tools are an agent's "hands and senses" — they extend a model from a static text transformer into an active system that can perceive real-world state (read actions) and take real-world effects (write actions). Tool calling is the load-bearing primitive of every production AI agent.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

LLMs have a fundamental constraint: their knowledge is frozen at training time. They cannot independently access real-time information, query databases, execute code, or take actions in external systems. Tool use solves this by embedding a structured protocol into the model interaction: the model describes the action it wants to take (as a structured function call), the runtime executes it, and the result is returned as a new observation the model can reason over.

The 5-step tool calling flow:

1. **User sends task** — the prompt includes both the task and a list of available tool definitions (JSON schemas).
2. **LLM responds with function call** — instead of a natural-language answer, the model returns a structured `function_call` object specifying the tool name and its arguments.
3. **Runtime parses and executes** — the host application extracts the tool call, looks up the corresponding function, and calls it with the provided arguments.
4. **Result returned to LLM** — the tool output is appended to the conversation as a new message and the model is re-invoked.
5. **LLM generates final response** — with the tool output in context, the model synthesizes the final user-facing answer.

This loop can repeat multiple times — tool calls triggering further tool calls — until the model determines it has enough information to answer, or a stopping condition is reached (see [[agent-planning]] for how planning patterns structure this loop).

![[2026-06-23-decodingai-05-tool-calling-02.png|Five-step tool-calling flow: request, execute, respond]]
*Figure: The five-step tool-calling flow — model requests a call, runtime executes, result returns, model responds — source [[2026-06-23-decodingai-05-tool-calling]].*

## Why it matters

**The transformation from text to action.** Without tools, an LLM can only produce text about the world. With tools, it can search the web, query a database, run code, send emails, and modify files. Tools are what make an agent useful beyond a chatbot.

**Composability.** Tools are the units of capability composition. An agent's power scales with the quality and breadth of its tool library, not just the model's intelligence. A weaker model with well-designed tools often outperforms a stronger model with no tools.

**The critical distinction — read vs. write:** Tool actions divide sharply by reversibility:

| Category | Examples | Risk |
|---|---|---|
| Read (access) | Web search, database queries, document retrieval, API reads | Low — no state change |
| Write (effect) | Code execution, email sending, database writes, file mutations | High — often irreversible |

Write actions require explicit authorization and, for consequential operations, [[human-in-the-loop-design|human-in-the-loop gates]]. The irreversibility asymmetry is why tool design is a security and governance concern, not just an engineering one.

## Key concepts / building blocks

### Tool definition anatomy

Every tool requires three elements:

1. **Function** — the actual implementation that executes when called. Docstrings matter: clear, distinctive descriptions prevent the model from confusing similar tools ("search for a product" vs. "look up a product by ID").

2. **JSON Schema** — the contract the model sees. Specifies name, description, parameter types, and required fields. The model uses this schema to generate valid function calls.

3. **Registry** — a lookup table mapping tool names to their handlers and schemas, enabling the runtime to dispatch calls and inject schema lists into prompts.

```python
TOOLS = {
    "google_search": {
        "handler": google_search_fn,
        "declaration": google_search_schema,
    }
}
TOOLS_SCHEMA = [tool["declaration"] for tool in TOOLS.values()]
```

### Schema quality drives selection accuracy

Gorilla Benchmark (University of California, Berkeley) found that "nearly all models perform worse when given more than one tool." The degradation stems from ambiguous tool descriptions — when two tools could plausibly handle the same input, the model either picks randomly or refuses. Mitigation:

- Write distinctive, non-overlapping descriptions for each tool
- Name tools with verbs that encode the action (`fetch_invoice_by_id` not `invoice_tool`)
- Group tools by capability domain; load only the relevant subset per task

### Framework-assisted tool use

Modern frameworks eliminate manual schema management. LangGraph's `@tool` decorator generates the JSON Schema from the function's type hints and docstring at decoration time. The LLM sees the same schema but the developer writes none of the boilerplate.

```python
@tool
def google_search(query: str) -> dict:
    """Searches Google for the given query and returns ranked results."""
    return {"results": ...}
```

Provider APIs (Gemini, OpenAI) go further: pass function objects directly in the `tools=` parameter; the SDK generates schemas, optimizes them per model, and handles parsing. This is the current recommended path for new production agents.

### Parallel tool execution

In production [[agentic-loop|ReAct agents]], a single model turn may produce multiple `tool_calls`. LangGraph's `ToolNode` executes these in parallel via `Send` objects, collecting all results before the next model turn. Parallel tool execution is the mechanism that makes agentic research (fetch 5 sources simultaneously) and agentic orchestration (dispatch 3 subtasks at once) practical.

### Tool categories in production

**Read tools (information access):**
- Knowledge base / vector DB retrieval (the RAG layer — see [[retrieval-augmented-generation]])
- Web search and URL scraping (Perplexity, Google, custom scrapers)
- Database queries (text-to-SQL translation; structured data access)
- Knowledge graph queries (entity lookups, multi-hop traversal)
- File system reads (local document access)

**Write tools (external effects):**
- Code execution (Python/JS interpreters in sandboxed Docker or gVisor environments)
- External API actions (email, calendar, CRM, project management)
- Database writes (INSERT, UPDATE, DELETE — require idempotency guarantees)
- File system writes (create, modify, delete)

Sandboxed code execution deserves special attention: it is the highest-capability tool class (the agent can compute anything) and the highest-risk (arbitrary code execution). Sandbox isolation (Docker, gVisor, Firecracker) is mandatory for any write-capable code execution tool in production.

## Design decisions & trade-offs

**Tool granularity.** Fine-grained tools (one action each) give the model precise control and are easier to test in isolation. Coarse-grained tools reduce the number of calls but constrain the model's action space. The practical sweet spot: atomic actions at the tool level, composed into higher-level workflows by the agent or by [[agentic-system-design|orchestrator-worker patterns]].

**Tool count per request.** More tools increase context consumption (schemas are tokens) and reduce selection accuracy. Load only the tools relevant to the current task; use a tool-routing layer for large toolsets (50+).

**Write tool authorization.** Never expose write tools without an authorization boundary. Options: (1) HITL gate (human approves before execution), (2) scope restriction (agent can only write to its designated workspace), (3) audit trail + reversibility (all writes are logged; mutations are soft-deletes with rollback). See [[agent-governance-and-policy]] for the policy enforcement layer.

**Idempotency for retries.** The tool calling loop may retry a tool call on transient failure. Non-idempotent write tools (send email, charge card) will double-send or double-charge on retry. Design write tools idempotent by default — use idempotency keys, check-before-write patterns, or queue-based deduplication.

## State of the art

As of mid-2026, tool calling is supported natively by all major provider APIs with automatic schema generation, parallel execution, and streaming support. The manual JSON schema approach has been replaced by decorator-based frameworks (LangGraph, LangChain, LlamaIndex) and provider-native function objects.

Production agents at scale (10–100+ tools) require LLMOps observability platforms (Opik, LangSmith, Weights & Biases Weave) to track tool call latency, token cost per invocation, and input/output values for debugging. Tool-level tracing is the primary diagnostic surface for agentic systems — without it, debugging a multi-step agent failure is impractical.

The emerging frontier is **model-driven tool discovery**: agents querying a tool catalog at runtime (via [[model-context-protocol|MCP]]) rather than receiving a fixed tool list, allowing toolsets to grow without redeployment.

## Pitfalls & anti-patterns

**Ambiguous tool descriptions.** Two tools with similar descriptions cause random tool selection. The model cannot resolve ambiguity from schema alone — it requires distinctive naming and clear scope boundaries.

**Unguarded write tools.** Exposing write-capable tools without authorization gates or sandboxing is the most common agentic security failure. Production write tools must have explicit boundaries.

**No idempotency on retries.** A retry on transient failure that re-executes a non-idempotent write action is a production incident waiting to happen. This is especially dangerous for payment, email, and data-deletion tools.

**Tool result injection.** A tool that returns attacker-controlled content (web scrape result, database row, user input) can inject instructions into the agent's context. This is the primary [[prompt-injection]] vector in tool-augmented agents — sanitize or structure tool outputs before they reach the model. See [[guardrails-and-output-validation]].

**No monitoring.** Tool calls are the primary cost and failure point in production agents. Running without per-tool latency and cost metrics makes capacity planning and debugging impossible.

## See also

- [[agent-planning]]
- [[agentic-loop]]
- [[agentic-system-design]]
- [[llm-structured-outputs]]
- [[model-context-protocol]]
- [[guardrails-and-output-validation]]
- [[prompt-injection]]
- [[agent-governance-and-policy]]
- [[human-in-the-loop-design]]
- [[ai-agent-observability]]

## Sources

- Iusztin, P. (Decoding AI). Tool Calling: From Scratch to Production. https://www.decodingai.com/p/tool-calling-from-scratch-to-production
- Iusztin, P. (Decoding AI). Writing AI Agents From Scratch: Planning Is The Key. https://www.decodingai.com/p/ai-agents-planning
- Iusztin, P. (Decoding AI). Building Production ReAct Agents From Scratch. https://www.decodingai.com/p/building-production-react-agents
- Google. (2026). Gemini API — Function Calling. https://ai.google.dev/gemini-api/docs/function-calling
- Anthropic. (2026). Tool Use — Claude API. https://docs.anthropic.com/en/docs/build-with-claude/tool-use
- raw/2026-06-23-decodingai-05-tool-calling.md
- raw/2026-06-23-decodingai-06-agent-planning.md
