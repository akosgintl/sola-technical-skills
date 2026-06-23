---
title: "How Does Memory for AI Agents Work?"
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, agent-memory, short-term, long-term, semantic, episodic, procedural]
updated: 2026-06-23
source_url: https://www.decodingai.com/p/how-does-memory-for-ai-agents-work
source_type: article
ingested: 2026-06-23
feeds: [agent-memory-architectures]
---

# How Does Memory for AI Agents Work?

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Series:** AI Agents Foundations #8 · **URL:** https://www.decodingai.com/p/how-does-memory-for-ai-agents-work

## Key takeaways

- Four memory type taxonomy: (1) **Internal Knowledge** (model weights — static, frozen), (2) **Context Window** (the current inference call's "reality"), (3) **Short-Term Memory** (session RAM — volatile, fast, recent interactions), (4) **Long-Term Memory** (external persistent storage — cross-session personalization).
- Long-term memory subtypes: **Semantic** (facts/knowledge — encyclopedia entries, structured attributes), **Episodic** (past interactions with timestamps — "what happened and when"), **Procedural** (learned workflows and multi-step tasks — muscle memory for repeatable processes).
- Three storage approaches for long-term memory: (1) **Raw Strings** (simple, nuanced, imprecise retrieval, hard updates), (2) **Entities/JSON** (precise filtering, easy updates, schema required), (3) **Knowledge Graphs** (complex relationships, temporal awareness, highest complexity/cost).
- 10-step memory cycle: user input → ingestion → retrieval → short-term assembly → context engineering → inference → loop → update from short-term → update from external world → persistence.
- Practical insight: "our data wasn't actually that big... we could retrieve relevant data with simple SQL queries" — don't over-engineer memory if domain is narrow.
- "Memory is the component that transforms a stateless chat application into a personalized agent."

## Notable claims (with location)

- Context window = the LLM's "reality" during one inference call; short-term memory = working RAM across a session.
- Semantic memory example: `"User prefers vegetarian meals"` or `{"music": "User likes rock music"}`.
- Episodic memory example: "On Tuesday, the user expressed frustration that their brother always forgets their birthday."
- Procedural memory example: a monthly report procedure with defined steps (query DB → summarize → email user).

## Feeds these wiki pages

- [[agent-memory-architectures]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
