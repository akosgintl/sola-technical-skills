---
title: "Design Python AI Projects That Scale"
aliases: [clean architecture for AI, structuring AI projects]
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, architecture, clean-architecture, python, project-structure, dependency-rule, mcp]
updated: 2026-06-30
source_url: https://www.decodingai.com/p/how-to-design-python-ai-projects
source_type: article
ingested: 2026-06-30
feeds: [clean-architecture-for-ai-systems, llm-application-architecture, deep-modules, domain-driven-design, agentic-system-design]
---

# Design Python AI Projects That Scale

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Date:** 2026-01-13 · **URL:** https://www.decodingai.com/p/how-to-design-python-ai-projects

## Key takeaways

- **Clean architecture, adapted for AI.** Organize an AI system into **four conceptual layers** with dependencies that point *inward only*. The layers are *virtual concepts*, not a literal folder hierarchy — that distinction is the whole article.
- **The four layers:**
  1. **Domain ("the What")** — business entities and the core AI units of work, independent of any DB or LLM. **Entities** are Pydantic data models (`Article`, `Research`, `Report`, `Profile`); **Nodes** are self-contained AI logic units (`ArticleWriter`, `DocumentAnalyzer`, `QueryGenerator`, `LLMJudge`) that bundle a prompt + logic.
  2. **Application ("the How")** — orchestrates domain elements into **workflows** (LangGraph, DBOS, Prefect). Defines sequence and business logic; knows nothing about concrete infrastructure. Depends on **interfaces** (`Loader`, `Runnable`, `Renderer`, `Toolkit`), not implementations.
  3. **Infrastructure ("External Dependencies")** — concrete implementations: LLM providers (`GeminiModel`, `OllamaModel`, `ClaudeModel`, `FakeModel`), storage/memory (`InMemory`, `SQLiteMemory`, `PostgreSQLMemory`), file operators (`MarkdownLoader`, `S3Loader`). Invisible to the inner layers.
  4. **Serving ("the Interface")** — exposes functionality: MCP server (resources/tools/prompts), FastAPI endpoints, CLI commands.
- **The Dependency Rule:** "Dependencies must always point inward. The outer layers know about inner layers, but application and domain layers must never be aware of infrastructure and serving layers." This is what enables polymorphism, testability, and infra swapping.
- **Folder structure is flatter than the layers.** Don't create physical `domain/`, `application/`, `infrastructure/`, `interface/` folders. Organize by functionality: `entities/`, `nodes/`, `workflows/`, `models/`, `memory/`, `mcp/`, `utils/` under `src/package_name/`.
- **Three mistakes to avoid:**
  1. **Rigid layer hierarchy** — physical layer folders cause circular imports and "where does this file go?" confusion. Layers are conceptual boundaries.
  2. **Folder-per-type** — scattering one feature across `/prompts`, `/nodes`, `/chains` raises cognitive load. Organize by **actionability**: keep related logic together as self-contained, reusable modules.
  3. **Over-engineering** — "Decouple only what is worth decoupling." If you'll never swap PostgreSQL for MySQL, an abstract ORM layer is dead weight.
- **Dependency injection at the seam.** The serving layer instantiates concrete infrastructure from config and **injects** it into the application orchestrator, which calls domain nodes via interfaces (`loader.load()`, `model.invoke()`).
- **Payoffs:** polymorphism (swap Gemini↔local, disk↔S3 by config), testability (inject `FakeModel`/mocks), modularity (domain nodes as reusable "Lego bricks"), maintainability (separation of concerns).
- **Final rule:** "Start with these principles, but always prioritize simplicity over purity." Goal = systems easy to change, test, and understand — not architectural perfection.

## Notable claims (with location)

- The four layers are "virtual concepts" — repeated as the central framing.
- **Kitchen analogy:** domain = ingredients, application = recipes, infrastructure = equipment, serving = how customers receive food; swapping equipment doesn't change the recipe.
- Writing-agent worked example: client → MCP server (builds infra from config) → instantiates `GenerateArticleWorkflow` + injects infra → workflow calls domain nodes in sequence → `Article` entity returned up the stack (6-step data flow, diagram 06).

## Key visuals

Localized to `raw/assets/2026-06-30-decodingai-11-python-ai-clean-architecture/` (6 diagrams, captured at ingest 2026-06-30).

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | Clean architecture — dependencies point inward only | [[clean-architecture-for-ai-systems]] |
| `…-02.png` | The dependency rule: outer layers know inner, never reverse | |
| `…-03.png` | "Structuring AI Projects" — the four layers with example components | [[clean-architecture-for-ai-systems]] |
| `…-04.png` | Polymorphism: swap infrastructure implementations via config | |
| `…-05.png` | Writing-agent app mapped onto the four layers | |
| `…-06.png` | Data flow: a request traversing the layers (6 steps) | [[clean-architecture-for-ai-systems]] |

## Feeds these wiki pages

- [[clean-architecture-for-ai-systems]] (new page — primary)
- [[llm-application-architecture]], [[deep-modules]], [[domain-driven-design]], [[agentic-system-design]], [[model-context-protocol]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
