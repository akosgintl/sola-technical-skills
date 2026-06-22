---
title: "From Regex to Vision Models: Which RAG Technique Fits Which Problem"
aliases: [edi-technique-selection, rag-diagnostic-grid]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, technique-selection, diagnostic-grid, enterprise]
updated: 2026-06-22
source_url: https://towardsdatascience.com/from-regex-to-vision-models-which-rag-technique-fits-which-problem/
source_type: article
ingested: 2026-06-22
feeds: [retrieval-augmented-generation, llm-application-architecture]
---

# From Regex to Vision Models: Which RAG Technique Fits Which Problem

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** June 2, 2026 · **URL:** https://towardsdatascience.com/from-regex-to-vision-models-which-rag-technique-fits-which-problem/

## Key takeaways

- Most teams apply the same "classic RAG playbook" to all problems. "Most RAG problems don't deserve the classic playbook."
- **Two-axis diagnostic grid** determines which technique to use:
  - **Document complexity axis** (5 tiers): (1) fixed template → regex; (2) family of templates → regex + LLM fallback; (3) heterogeneous structured → parse structure + TOC retrieval; (4) unstructured/OCR'd → hybrid retrieval; (5) visually rich → vision models.
  - **Question control axis** (4 tiers): A = engineer-templated; B = user fills predefined slots; C = free one-shot query; D = free query with clarification loop.
- Grid intersection maps to specific techniques. Top-left (fixed templates + controlled questions) = no LLM needed.
- Three critical warnings: (1) long context ≠ retrieval replacement (lost-in-the-middle, cost at scale, no audit trail); (2) fancy techniques often reduce to keyword work; (3) simplicity wins — "at two million docs a year, a regex on a VM is a rounding error; an LLM per document is sixty thousand euros."
- Position systems around "the expert who already knows the documents" — amplify, don't replace domain expertise.
- Run diagnostic with domain experts in the room before writing code.

## Notable claims (with location)

- HyDE example: generates ML-textbook vocabulary that doesn't match operational document vocabulary — reinventing what domain experts already know.
- Diagnostic questions before coding: How alike are documents? How are questions framed? Can the system ask for clarification? Do answers require audit-grade traceability?
- Vol. 1 #4 of Enterprise Document Intelligence series.

## Feeds these wiki pages

- [[retrieval-augmented-generation]]
- [[llm-application-architecture]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
