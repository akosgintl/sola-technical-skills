---
title: Agent-to-Agent Protocols
aliases: [A2A, inter-agent communication, agent interoperability]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, agents, protocols, a2a, interoperability, orchestration]
updated: 2026-06-22
sources:
  - https://google.github.io/A2A/
  - https://openai.com/index/new-tools-for-building-agents/
  - https://arxiv.org/abs/2503.15547
  - https://techcommunity.microsoft.com/blog/microsoftdefenderatpblog/introducing-the-microsoft-agent-governance-toolkit/4415521
  - https://langchain-ai.github.io/langgraph/concepts/multi_agent/
  - https://modelcontextprotocol.io/introduction
---

# Agent-to-Agent Protocols

> [!summary]
> Agent-to-agent protocols define how autonomous agents discover each other's capabilities, delegate tasks, pass state, and handle failures — the wire-level conventions that make multi-agent systems composable across vendors, frameworks, and deployments.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

When a single agent calls a tool, the interaction is well-defined: the agent emits a structured call, the tool executes and returns. When an agent delegates to another agent, the interaction is richer and less standardised: the calling agent must discover what the peer agent can do, hand off a task with sufficient context, handle streaming progress, deal with partial failures, and integrate the result. Agent-to-agent (A2A) protocols define that interaction layer.

The problem is analogous to what REST, gRPC, and AsyncAPI solved for service-to-service communication — but agents are stateful, long-running, and non-deterministic in ways that fixed-schema services are not. The protocol must handle capability discovery, task lifecycle management, streaming results, and authentication between agents that may be running under different identities, on different infrastructure, or from different vendors.

Two complementary protocol layers have emerged: **MCP** ([[model-context-protocol]]) for agent-to-tool access (an agent calling tools and resources exposed by a server), and **A2A** for agent-to-agent delegation (an orchestrator assigning a task to a peer agent). They are designed to coexist.

## Why it matters

Without a shared protocol, multi-agent systems are proprietary stacks: LangGraph agents cannot delegate to CrewAI agents, Anthropic Agent SDK agents cannot call Google ADK agents, and enterprise teams cannot mix specialist agents from different vendors. The interoperability gap produces either framework lock-in or bespoke integration code between every pair of agent types.

A2A-style protocols solve this the same way HTTP solved the web: a shared message format and lifecycle that agents from any vendor can implement. The analogy from [[model-context-protocol|MCP]] is instructive — before MCP, every LLM client had its own tool integration format; after MCP, a single server implementation serves any MCP-compatible client. A2A extends that logic one layer up, to agent-to-agent delegation.

Security is the second driver. Without a protocol that includes authentication, an agent receiving a task from another agent has no way to verify the caller's identity or authority. OWASP's Agentic AI Top 10 names prompt injection via malicious agent input and privilege escalation through unchecked sub-agent delegation as top-tier risks. A protocol with identity and scope verification addresses both.

## Key concepts

### Google A2A protocol (April 2025)

Google's open-source A2A specification (co-authored with 50+ partners) is the leading inter-agent standard. Its core constructs:

**Agent Card** — a JSON metadata document hosted at `/.well-known/agent.json`. Describes the agent's capabilities, supported input/output modalities (text, file, structured data), authentication requirements, and endpoint URL. Agent discovery works by fetching the Agent Card. The card is the agent's "service contract" — what it can do and how to call it.

**Task lifecycle** — A2A defines a task state machine:

| State | Meaning |
|---|---|
| `submitted` | Task received; queued |
| `working` | Agent processing; may stream intermediate events |
| `input-required` | Agent paused; needs clarification from caller |
| `completed` | Task finished; artifact available |
| `failed` | Terminal failure; error provided |
| `cancelled` | Caller cancelled before completion |

Long-running tasks return a task ID immediately; the caller polls or receives push notifications for state transitions.

**Streaming** — A2A uses server-sent events (SSE) for streaming intermediate results. The agent emits partial outputs as events during the `working` state; the caller can display progress or act on partial results without waiting for completion.

**Push notifications** — for very long-running tasks, the agent pushes state updates to a caller-specified webhook rather than requiring polling. This decouples the caller's process lifetime from the task duration.

**Authentication** — A2A requires OpenID Connect (OIDC) or OAuth 2.0 between agents. The calling agent authenticates to the peer; the peer validates the caller's identity and scope before accepting the task. This makes agent identity ([[agent-identity-and-access]]) a prerequisite for A2A, not an afterthought.

### OpenAI handoff pattern

OpenAI's Agents SDK (released with the `transfer_to_agent()` primitive) implements a simpler synchronous handoff model: the orchestrator calls `transfer_to_agent(target_agent, context)`, which pauses the orchestrator, runs the target agent to completion, and returns the result. No persistent task ID; no streaming; no push notifications. Appropriate for synchronous, sequential workflows where task latency is acceptable and intermediate results are not needed.

The handoff model is the simplest A2A pattern and the right default for workflows where all agents are within the same process or a low-latency local network.

### LangGraph multi-agent state sharing

LangGraph's multi-agent pattern uses a **shared state graph**: each agent node reads from and writes to a typed state object passed between nodes. Rather than explicit message passing, agents communicate by modifying shared state. An orchestrator node routes to specialist nodes based on state content; the specialist updates state with its result; routing continues until a terminal node.

This pattern is tightly coupled (all agents must understand the shared state schema) but simple to reason about for bounded, designed workflows. It does not support cross-framework interoperability — all agents must be LangGraph nodes. For single-team, single-framework deployments it is the most operationally straightforward option.

### Microsoft IATP

The Inter-Agent Trust Protocol (IATP, part of the Microsoft Agent Governance Toolkit, April 2026) extends A2A with DID-based identity and a dynamic trust score (0–1000) updated per interaction. An agent presenting a DID-authenticated credential is assigned a trust tier; the receiving agent's policy engine decides what actions are permitted at that trust level. IATP is A2A-compatible and adds the governance layer that vanilla A2A delegates to the implementer. See [[agent-identity-and-access]].

### Task decomposition patterns

How an orchestrator breaks work down into sub-tasks determines the efficiency and correctness of A2A coordination:

**Sequential delegation.** Task A must complete before Task B starts. Simple; no parallelism benefit. Use when sub-tasks have hard dependencies.

**Parallel fan-out.** The orchestrator dispatches multiple sub-tasks simultaneously and collects results. Reduces end-to-end latency proportionally to the number of independent sub-tasks. Requires result aggregation logic in the orchestrator.

**Hierarchical delegation.** A sub-agent receives a complex sub-task and further delegates to its own sub-agents. Each level of hierarchy adds latency and error propagation risk. Limit to `maxDepth = 2` in practice; deeper hierarchies are hard to debug and monitor.

**Conditional routing.** The orchestrator delegates to different agents based on task type, content classification, or intermediate results. Analogous to the [[model-selection-and-routing|model routing]] pattern applied to agent selection.

### State passing: shared vs. scoped

A2A has no single answer for how state is passed between agents. Two patterns:

**Scoped context bundle.** The orchestrator constructs a self-contained context package per sub-task: goal, relevant background, constraints, and prior results. The sub-agent receives only what it needs. Blast radius of a compromised sub-agent is bounded — it cannot read state outside its package. See [[agent-governance-and-policy]] on scope narrowing on delegation.

**Shared external memory.** All agents read from and write to a shared store (vector store, key-value store, structured DB). Higher coordination expressiveness; higher blast radius; requires fine-grained access controls to prevent one agent reading another's sensitive state. See [[agent-memory-architectures]].

### Failure handling

A2A sub-agent failures are distinct from tool call failures: they are slower to detect, harder to classify, and may produce partial results that are worse than no result.

Handling patterns:
- **Timeout + retry.** Set an explicit task timeout; retry once on timeout before escalating. A2A's task state machine includes `failed` and `cancelled` states for graceful handling.
- **Fallback agent.** Route the task to a simpler, more reliable agent when the primary fails. Analogous to the fallback chain in [[model-selection-and-routing]].
- **Partial result handling.** For long-running tasks with intermediate streaming, the orchestrator may be able to use partial results if the agent fails mid-task. Design the aggregation buffer (see [[recursive-language-models]]) to handle incomplete inputs.
- **Supervisor escalation.** If a sub-task fails after retries, escalate to a supervisor agent or a [[human-in-the-loop-design|human review gate]] rather than silently dropping the task.

## Design decisions and trade-offs

**A2A vs. direct model orchestration.** A2A introduces HTTP-layer indirection and authentication overhead. For agents within a single framework (all LangGraph, all Anthropic Agent SDK), direct in-process orchestration is simpler, faster, and easier to debug. A2A becomes justified when: agents are from different vendors, agents run on separate infrastructure, or cross-organisation agent delegation is required.

**Synchronous handoff vs. async task lifecycle.** Synchronous handoff (OpenAI pattern) is simpler to reason about but blocks the orchestrator until the sub-task completes. Async task lifecycle (A2A full pattern) enables the orchestrator to do other work during a long sub-task, but requires polling/webhooks and idempotent state management. Choose sync for tasks expected to complete in seconds; async for tasks that may take minutes or longer.

**Shared state vs. scoped context.** Shared state maximises coordination expressiveness but requires every agent to trust every other agent's writes and adds coupling between agents. Scoped context is more secure and easier to audit but requires the orchestrator to construct each package deliberately. Default to scoped context; introduce shared state only for read-heavy coordination where copying context is impractical.

**Trust calibration between agents.** An orchestrator agent should not grant a sub-agent more authority than the orchestrator itself holds (no privilege escalation), and should grant the minimum scope needed for the delegated task. This is the same least-privilege principle from [[agent-identity-and-access]] applied to the A2A layer.

## State of the art

**Google A2A v0.2.5** (June 2026) is the most widely adopted specification, with reference implementations in Python and TypeScript and integrations in LangGraph, CrewAI, and Google ADK. The spec has achieved vendor adoption from IBM, SAP, Salesforce, and Workday alongside Google.

**Anthropic's approach** remains framework-level orchestration via the Agent SDK (orchestrator-worker pattern via `tool_use`) rather than a protocol-level A2A standard. MCP covers tool access; agent delegation is left to the orchestrator's tool-call primitives.

**OpenAI Agents SDK** handoff is the dominant pattern in single-framework OpenAI deployments. OpenAI has not published a standalone A2A-compatible protocol as of mid-2026.

**Cross-framework interoperability** is early-stage. A2A provides the specification; tooling for agent discovery registries, trust certificate authorities, and capability matching is maturing.

**The MCP + A2A stack** is the emerging production pattern: MCP for tool access (agent → tools, resources, data), A2A for agent delegation (orchestrator → specialist agents). The two protocols are complementary and both are needed for full multi-agent production deployments.

> [!tip]
> For a new multi-agent system, start with direct in-process orchestration (LangGraph state graph or Agent SDK handoffs) — no A2A overhead, full debuggability. Add A2A only when cross-framework or cross-organisation agent delegation is a concrete requirement. Premature protocol adoption adds complexity with no near-term benefit.

## Pitfalls and anti-patterns

- **No authentication between agents.** An agent that accepts tasks from any caller without identity verification is vulnerable to prompt injection via malicious orchestrators and privilege escalation. Require OIDC or OAuth 2.0 for all agent-to-agent calls in production.
- **Implicit trust of sub-agent output.** A sub-agent's response should be treated the same as any external input: validated, not trusted blindly. A compromised or hallucinating sub-agent can poison an orchestrator's context if its output is injected without sanitisation.
- **No task timeout.** Sub-tasks without explicit timeouts can hang indefinitely, blocking the orchestrator and consuming tokens. Set timeouts proportional to expected task duration; fail-fast is better than silent hang.
- **Unbounded delegation depth.** Hierarchical delegation without a `maxDepth` cap can recurse indefinitely. Two levels of hierarchy is usually the practical maximum.
- **Privilege escalation via sub-agent.** An orchestrator that passes its full-scope token or context to a sub-agent allows the sub-agent to act outside its intended boundary. Always narrow scope on delegation.
- **No observability across agent hops.** A trace ID propagated through every A2A call enables end-to-end request tracing. Without it, debugging a multi-agent failure requires reconstructing the call chain from logs of each agent in isolation. See [[ai-agent-observability]].

## See also

- [[multi-agent-orchestration]] — orchestration patterns, frameworks, and workflow design
- [[model-context-protocol]] — tool and resource access layer (complementary to A2A)
- [[agent-identity-and-access]] — identity and credential management for inter-agent authentication
- [[agent-governance-and-policy]] — scope narrowing, audit logging, and OWASP Agentic AI Top 10
- [[agentic-system-design]] — overall agent architecture including multi-agent topology
- [[agents-as-system-citizens]] — NHI governance for the agents participating in A2A protocols
- [[ai-agent-observability]] — distributed tracing across agent hops

## Sources

- Google (2025). *Agent-to-Agent (A2A) Protocol Specification.* https://google.github.io/A2A/
- OpenAI (2025). *New Tools for Building Agents — Agents SDK Handoff.* https://openai.com/index/new-tools-for-building-agents/
- Guo, T. et al. (2025). *A Survey on Agent-to-Agent Communication Protocols.* arXiv:2503.15547. https://arxiv.org/abs/2503.15547
- Microsoft (2026). *Microsoft Agent Governance Toolkit — IATP.* https://techcommunity.microsoft.com/blog/microsoftdefenderatpblog/introducing-the-microsoft-agent-governance-toolkit/4415521
- LangChain AI (2025). *LangGraph Multi-Agent Concepts.* https://langchain-ai.github.io/langgraph/concepts/multi_agent/
- Anthropic (2024). *Model Context Protocol Introduction.* https://modelcontextprotocol.io/introduction
