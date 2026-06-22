---
title: "RAG Questions Need Parsing Too: Turn the User's String Into Briefs for Retrieval and Generation"
aliases: [edi-question-parsing-intro]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, question-parsing, retrieval-brief, generation-brief]
updated: 2026-06-22
source_url: https://towardsdatascience.com/question-parsing-in-rag-structure-before-you-search/
source_type: article
ingested: 2026-06-22
feeds: [rag-query-understanding, retrieval-augmented-generation]
---

# RAG Questions Need Parsing Too

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** June 16, 2026 · **URL:** https://towardsdatascience.com/question-parsing-in-rag-structure-before-you-search/

## Key takeaways

- User questions require structured parsing before entering RAG pipelines. A parsed question produces **two separate consumer briefs** — one for retrieval, one for generation.
- Core problem: passing raw question "What is the maximum coverage amount? Don't confuse it with the deductible" to retrieval pulls deductible passages closer; disambiguation is stripped before it can reach generation.
- **RetrievalQuery** receives: topic, topic rewrites in document vocabulary, anchor keywords, scope filters.
- **GenerationBrief** receives: original user wording, format constraints, disambiguation cues, distractors.
- **Exclusions belong to generation, not retrieval.** Three failure modes if you filter at retrieval:
  1. Line-level: removes the answer ("The limit is €1.5M, with a deductible of €1M" deleted).
  2. Page-level: removes answer context.
  3. Section-level: removes relevant section by name.
- "Embeddings don't do exclusion" and BM25 negative queries remain fragile. Retrieve broadly; let generation distinguish and exclude.
- Key distinction: "Retrieval is similarity matching — good at finding closeness, bad at rejecting precisely. Generation is reading and reasoning — good at distinguishing, excluding, contrasting."
- `question_df` table mirrors `line_df` from document parsing: one row per question, columns for each parsing capability, links to satellite tables.
- Three levels: (1) natural user questions, (2) developer-written templates, (3) dialogue-based formulation — all share the same parsing machinery.

## Feeds these wiki pages

- [[rag-query-understanding]]
- [[retrieval-augmented-generation]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
