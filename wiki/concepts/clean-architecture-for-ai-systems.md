---
title: Clean Architecture for AI Systems
aliases: [clean architecture for AI, structuring AI projects, AI project structure, four-layer AI architecture]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, architecture, clean-architecture, project-structure, dependency-rule, python, dependency-injection]
updated: 2026-06-30
sources:
  - raw/2026-06-30-decodingai-11-python-ai-clean-architecture.md
  - https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
  - https://www.cosmicpython.com/book/preface.html
  - https://docs.pydantic.dev/latest/
  - https://langchain-ai.github.io/langgraph/
  - https://modelcontextprotocol.io/
---

# Clean Architecture for AI Systems

> [!summary]
> Clean architecture for AI systems organizes an LLM/agent codebase into four **conceptual** layers — domain, application, infrastructure, serving — whose dependencies point **inward only**. The domain (entities + AI logic units) and the application (workflows) never know about the infrastructure (LLM providers, stores) or the serving surface (MCP/API/CLI). The layers are virtual boundaries enforced through interfaces and dependency injection, **not** a literal folder hierarchy — that distinction is what keeps the structure usable.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Clean architecture (Robert C. Martin) and its Python lineage (the "ports and adapters" / hexagonal style popularised by *Architecture Patterns with Python*) applied to LLM and agent codebases. The system is divided into four layers, ordered from the core outward:

| Layer | Role ("the…") | Holds | Knows about |
|---|---|---|---|
| **Domain** | *What* | Business **entities** (Pydantic models) + **Nodes** — self-contained AI units of work (a prompt + its logic) | Nothing below it |
| **Application** | *How* | **Workflows** that orchestrate domain nodes into a sequence; depends on **interfaces**, not implementations | Domain only |
| **Infrastructure** | *External deps* | Concrete implementations: LLM providers, vector/SQL/object stores, file loaders, API clients | Domain + application interfaces |
| **Serving** | *Interface* | The exposed surface: [[model-context-protocol|MCP]] server, FastAPI/REST endpoints, CLI commands | Everything |

![[2026-06-30-decodingai-11-python-ai-clean-architecture-03.png|Four layers — serving, infrastructure, app, domain — with example components in each]]
*Figure: The four conceptual layers with concrete example components — entities and AI nodes at the core, workflows above, swappable infrastructure (Claude/Ollama/Gemini models, InMemory/SQLite/PostgreSQL memory) and serving surfaces (MCP, FastAPI, CLI) on the outside — source [[2026-06-30-decodingai-11-python-ai-clean-architecture]].*

The defining constraint is the **dependency rule**: source-code dependencies point only inward. The inner layers — where the business value and the AI logic live — are pure and dependency-free; the volatile, replaceable parts (which model, which database, which transport) live on the outside and are injected in.

## Why it matters

Most LLM codebases rot the same way: prompts, model clients, retrieval calls, and parsing get tangled into one another until swapping a provider or writing a test means touching everything. The dependency rule is the antidote — it buys four concrete properties that matter in production:

- **Polymorphism / swappability.** Because the inner layers depend on interfaces, you change a model or a store by changing configuration, not code: Gemini ↔ a local Ollama model, in-memory ↔ S3, SQLite ↔ Postgres.
- **Testability.** Inject a `FakeModel` or a mock store and the domain logic runs offline, deterministically, with no API spend — the same seam that enables [[ai-evaluation-and-quality|evals]] and CI.
- **Modularity.** Domain nodes become reusable "Lego bricks" — an `ArticleWriter` or `LLMJudge` node drops into any workflow.
- **Maintainability.** Separation of concerns localises change; a provider deprecation is an infrastructure-layer edit, invisible to the domain.

It connects directly to [[deep-modules]] (the interface is narrow, the implementation deep and hidden) and to [[llm-application-architecture]] (this is *how you lay out* the layers that page describes).

![[2026-06-30-decodingai-11-python-ai-clean-architecture-01.png|Concentric layers with arrows pointing inward toward the domain core]]
*Figure: The dependency rule visualised — outer layers depend on inner ones, never the reverse — source [[2026-06-30-decodingai-11-python-ai-clean-architecture]].*

## Key concepts / building blocks

### Domain: entities and nodes
- **Entities** — Pydantic data models that carry the business meaning (`Article`, `Research`, `Report`). They give the system [[llm-structured-outputs|typed, validated structures]] to pass between steps.
- **Nodes** — self-contained AI units of work, each bundling a prompt and its logic (`ArticleWriter`, `DocumentAnalyzer`, `QueryGenerator`, `LLMJudge`). A node is the smallest reusable unit of agentic behaviour and maps cleanly onto a step in an [[agentic-loop]] or a [[multi-agent-orchestration|multi-agent]] graph.

### Application: workflows over interfaces
The application layer sequences nodes into **workflows** (`GenerateArticleWorkflow`: research → write → review). It calls dependencies through **interfaces** — `Loader`, `Runnable`, `Renderer`, `Toolkit` — and is "not aware of specific infrastructure components or serving elements." Orchestration engines such as [[agentic-loop|LangGraph]], DBOS, or [[data-pipelines-and-orchestration|Prefect]] live here.

### Infrastructure: concrete adapters
Every interface gets one or more concrete implementations: `GeminiModel`, `OllamaModel`, `ClaudeModel`, `FakeModel`; `InMemory`, `SQLiteMemory`, `PostgreSQLMemory`; `MarkdownLoader`, `S3Loader`. These are the **adapters** — the only place that imports a vendor SDK.

### Serving: the injection point
The serving layer ([[model-context-protocol|MCP]] server, REST API, or CLI) is where the wiring happens: it reads config, **builds** the chosen infrastructure instances, and **injects** them into the application orchestrator. This is classic dependency injection — the outer layer composes the object graph that the inner layers merely consume.

![[2026-06-30-decodingai-11-python-ai-clean-architecture-06.png|Six-step request flow down through serving, application, domain, infrastructure and back up]]
*Figure: Data flow for a `generate_article` request — serving builds and injects infrastructure, the workflow drives domain nodes, nodes use infrastructure through interfaces, and the `Article` entity returns up the stack — source [[2026-06-30-decodingai-11-python-ai-clean-architecture]].*

### Layers are virtual; folders are flat
The single most important practical point: **do not mirror the layers as folders.** Organize by functionality instead, under one package:

```
src/package_name/
├── entities/    # Domain: Pydantic data models
├── nodes/       # Domain: AI logic units (prompt + logic)
├── workflows/   # Application: orchestration
├── models/      # Infrastructure: LLM implementations
├── memory/      # Infrastructure: storage
├── mcp/         # Serving: MCP server interface
└── utils/       # Shared utilities
```

The layer is a property of *what a module depends on*, not the directory it sits in.

## Design decisions & trade-offs

- **Decouple only what is worth decoupling.** An interface earns its keep only when you will plausibly have a second implementation (a second provider, a fake for tests, a future store). Abstracting a dependency you will never swap is pure overhead — see [[trade-off-judgment]]. *"If you never plan to swap from PostgreSQL to MySQL, abstract ORM layers provide no value."*
- **Organize by actionability, not by type.** Keep a feature's prompt, node, and logic together as a cohesive module rather than scattering them across `/prompts`, `/nodes`, `/chains`. Folder-per-type minimises duplication but maximises the number of files you must open to understand one feature; actionability optimises for the reader. (Contrast with the layered-by-type discipline that suits stable [[domain-driven-design|DDD]] service code.)
- **Interfaces vs. duck typing.** Python lets you inject anything that quacks right, with no formal interface. Explicit `Protocol`/ABC interfaces make the seam discoverable and lint-checkable at the cost of ceremony; informal duck typing is lighter but leaves the contract implicit. Prefer explicit interfaces at layer boundaries that cross a team or a release.
- **Where the workflow engine lives.** Putting LangGraph/Prefect in the application layer keeps orchestration testable and provider-agnostic; reaching into infrastructure from a workflow (a direct SDK call for "just this one step") is the first crack that collapses the dependency rule.
- **Simplicity over purity.** The architecture is a default to grow into, not a gate to pass. A three-file script does not need four layers; introduce a seam when a real second implementation or a real test need appears.

![[2026-06-30-decodingai-11-python-ai-clean-architecture-04.png|Config selecting between alternative infrastructure implementations behind one interface]]
*Figure: Polymorphism in practice — one interface, many infrastructure implementations chosen by configuration — source [[2026-06-30-decodingai-11-python-ai-clean-architecture]].*

## State of the art

- **Pydantic** is the de-facto entity layer for Python AI code — typed models double as the [[llm-structured-outputs|structured-output]] schema, so the domain entity and the model's output contract are the same object.
- **LangGraph** (GA v1.0) is the common application-layer choice for stateful workflows with checkpointing and interrupt/resume; DBOS and Prefect cover durable-execution and data-pipeline framings of the same layer.
- **[[model-context-protocol|MCP]]** has become a standard serving surface for AI capabilities, sitting alongside FastAPI and CLI as a first-class transport — a clean fit for the serving layer because it is purely an adapter over the application orchestrator.
- The pattern is the AI-specific instance of a broader move: *Architecture Patterns with Python* (Percival & Gregory) brought ports-and-adapters, repository, and unit-of-work patterns into mainstream Python, and AI codebases inherit them with "Nodes" standing in for domain services.

## Pitfalls & anti-patterns

- **Rigid layer folders.** Physical `domain/`, `application/`, `infrastructure/`, `interface/` directories invite circular imports and constant "which folder does this go in?" friction. Keep layers conceptual; keep folders flat and functional.
- **Folder-per-type sprawl.** `/prompts` + `/nodes` + `/chains` forces you to chase one feature across three trees. Co-locate by actionability.
- **Over-abstraction.** An interface and a factory for a dependency that has exactly one implementation forever is speculative generality — cost with no swap to show for it.
- **Leaky inner layers.** A domain node that imports `openai` or reads an env var has broken the dependency rule; the vendor SDK belongs in infrastructure, the config read belongs in serving.
- **Skipping injection.** Instantiating a concrete `GeminiModel` inside a workflow (instead of receiving it) destroys testability and swappability — the two main reasons to adopt the pattern at all.
- **Architecture before need.** Spinning up all four layers for a prototype is the inverse mistake of spaghetti code; both ignore the actual requirements. Start simple, add seams under pressure.

## See also

- [[llm-application-architecture]] — the stack layers this pattern organises
- [[deep-modules]] — narrow interface, deep hidden implementation: the same principle at module scope
- [[domain-driven-design]] — the entity/aggregate vocabulary the domain layer borrows
- [[agentic-system-design]] — where nodes and workflows become autonomous agents
- [[model-context-protocol]] — a common serving-layer transport
- [[llm-structured-outputs]] — Pydantic entities as the output contract
- [[trade-off-judgment]] — "decouple only what is worth decoupling" generalised
- [[service-decomposition]] — choosing module and service seams at the system level

## Sources

- Iusztin, P. (2026). *Design Python AI Projects That Scale.* Decoding AI. — captured at [[2026-06-30-decodingai-11-python-ai-clean-architecture]]
- Martin, R. C. (2012). *The Clean Architecture.* https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
- Percival, H. & Gregory, B. (2020). *Architecture Patterns with Python.* https://www.cosmicpython.com/
- Pydantic documentation. https://docs.pydantic.dev/latest/
- LangGraph documentation. https://langchain-ai.github.io/langgraph/
- Model Context Protocol. https://modelcontextprotocol.io/
