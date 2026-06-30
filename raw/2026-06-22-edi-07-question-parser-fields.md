---
title: "What the Question Parser Extracts: Keywords, Scope, Shape, Decomposition, Clarification"
aliases: [edi-question-parser-fields, parsed-question-schema]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, question-parsing, schema, keywords, decomposition]
updated: 2026-06-30
source_url: https://towardsdatascience.com/what-the-question-parser-extracts-from-a-user-string-keywords-scope-shape-decomposition-clarification/
source_type: article
ingested: 2026-06-22
feeds: [rag-query-understanding]
---

# What the Question Parser Extracts: Keywords, Scope, Shape, Decomposition, Clarification

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** June 17, 2026 · **URL:** https://towardsdatascience.com/what-the-question-parser-extracts-from-a-user-string-keywords-scope-shape-decomposition-clarification/

## Key takeaways

- ParsedQuestion transforms a query into a typed, relational database row with five field families:

1. **Keywords** — from four sources: explicit user input (highest precision), LLM rewrites (3-5 alternative phrasings in document vocabulary), expert dictionary (domain synonyms), anchor regex patterns (regulatory codes, ISOs). Explicit extraction beats HyDE for bounded domains (cost + auditability).

2. **Answer shape + type** — two independent axes: shape (cardinality: single/listing/table/tree/nested_json) + type (value category: text/amount/date/iban/address). Type enables regex confirmation ("two-signal match" — keywords + currency pattern for amount questions).

3. **Scope hints** — structural location: page ranges, TOC section refs, layout types (table/image/header). Applied before retrieval runs.

4. **Decomposition** — four patterns: independent (parallel), sequential (second depends on first), unified (synonymous terms searched together), conditional (conditions become scope filters). ~30% of queries in production were compound; adding decomposition significantly improved satisfaction.

5. **Clarification** — when input is too ambiguous, parser returns clarification question rather than guessing.

- Satellite tables: `concepts_df` (domain concepts + dispatch defaults), `concept_keywords_df` (vocabulary mappings), `answer_types_df`, `answer_shapes_df`.
- Production: one consolidated LLM call returning full schema (cheaper, faster than step-by-step). Sub-tasks injected from satellite tables so new types require only row insertion.
- "Correct spelling before keyword extraction" — typos cause zero-hit searches.
- Production results (broker corpus): parsing latency 280ms average; 71% single decomposition, 19% independent; 4% clarification trigger rate; parsing enabled vs. disabled: 91% vs. 76% accuracy (+15 points).

## Key visuals

Localized to `raw/assets/2026-06-22-edi-07-question-parser-fields/` (2 diagrams, visual backfill 2026-06-30; registry-table screenshots dropped).

| Asset | Diagram | Embedded |
|---|---|---|
| `…-01.png` | Question parsing positioning in the four-brick architecture | |
| `…-02.png` | Question-parsing data flow (question_df + satellite tables) | [[rag-query-understanding]] |

## Feeds these wiki pages

- [[rag-query-understanding]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
