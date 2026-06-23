---
title: "Context Engineering Guide 101"
aliases: []
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, context-engineering, llm, rag, memory]
updated: 2026-06-23
source_url: https://www.decodingai.com/p/context-engineering-2025s-1-skill
source_type: article
ingested: 2026-06-23
feeds: [context-engineering]
---

# Context Engineering Guide 101

> [!info] Source metadata
> **Author/Org:** Paul Iusztin (Decoding AI) · **Series:** AI Agents Foundations #2 · **URL:** https://www.decodingai.com/p/context-engineering-2025s-1-skill

## Key takeaways

- Context engineering = "finding the ideal set of functions to assemble a context that maximizes the quality of the LLM's output for a given task."
- Karpathy's OS analogy: "LLMs are like a new kind of operating system, where the model acts as the CPU and its context window functions as the RAM."
- Five context components: (1) system prompt, (2) message history, (3) user preferences/past experiences (episodic memory), (4) retrieved information (semantic memory / RAG), (5) tool and output schemas.
- Context decay: model performance drops significantly after 32,000 tokens even with larger advertised limits.
- Tool confusion: Gorilla benchmark — "nearly all models perform worse when given more than one tool."
- Format optimization: YAML is 66% more token-efficient than JSON.
- Context ordering: place critical instructions first, recent/relevant data last (U-shaped attention pattern).
- Isolation strategy: split complex problems across multiple specialized agents, each with focused context windows.
- Context engineering sits at the intersection of AI Engineering, Software Engineering, Data Engineering, and MLOps.

## Notable claims (with location)

- Author built a workflow that took 30 minutes to run due to naive context approach (practical failure example).
- "Mastering context engineering is less about learning a specific algorithm and more about building intuition."
- Series of 9 parts covering the full AI Agents Foundations stack from workflows to multimodal agents.

## Feeds these wiki pages

- [[context-engineering]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
