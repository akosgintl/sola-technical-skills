---
title: "Embeddings Aren't Magic: The Predictable Failure Modes of RAG Retrieval"
aliases: [edi-embeddings-failure-modes, vol-1-2]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, embeddings, failure-modes, keyword-dictionary, enterprise]
updated: 2026-06-22
source_url: https://towardsdatascience.com/embeddings-arent-magic-the-predictable-failure-modes-of-rag-retrieval-enterprise-document-intelligence-vol-1-2/
source_type: article
ingested: 2026-06-22
feeds: [retrieval-augmented-generation, vector-and-embedding-stores]
---

# Embeddings Aren't Magic: The Predictable Failure Modes of RAG Retrieval

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** May 30, 2026 · **URL:** https://towardsdatascience.com/embeddings-arent-magic-the-predictable-failure-modes-of-rag-retrieval-enterprise-document-intelligence-vol-1-2/

## Key takeaways

- Embeddings excel at: conceptual proximity, synonyms/paraphrase, typo tolerance, cross-lingual matching.
- Six structural failure modes that fine-tuning cannot fix:
  1. **OOV terms** — internal product codes, regulatory citations, industry jargon without web-scale attestation.
  2. **Question-answer mismatch** — topical similarity ≠ answer relevance; "Capital of France?" ranks passages about "capitals" over "Paris."
  3. **Negation blindness** — "NOT a city" pulls city passages closer; "not the deductible" worsens deductible retrieval.
  4. **Magnitude blindness** — "value greater than 1M" ranks "1M" first, "3B" (correct) last.
  5. **Procedure over answer** — procedure-dense passages outrank the actual answer line.
  6. **Signal dilution** — embedding a 300-500 word page as one vector drowns answer-bearing lines.
- Production fix: embed line-level, not page-level. Aggregate to page only for generation context.
- **Expert keyword dictionary workflow**: (1) run embeddings to surface candidates, (2) experts validate, (3) codify aliases, (4) production retrieval uses keyword search (fast, auditable). Examples: "deductible" ↔ "excess/franchise"; "blood sugar" ↔ "A1C/HbA1c"; "force majeure" ↔ "act of God."
- HyDE reframed: real value is surfacing domain keywords, not the embedding of a hypothetical answer.
- "Don't fine-tune embeddings on enterprise corpora" — failures are structural, not training gaps.
- Models tested: GloVe-avg (2014), all-MiniLM-L6-v2 (2021), text-embedding-ada-002 (2022), text-embedding-3-large (2024).

## Notable claims (with location)

- BM25 case study: team moved from 76% to 88% recall on exact-reference queries in one week by adding BM25, not three months fine-tuning embeddings.
- Break down evaluation by query type (conceptual, negation, exact-reference, acronym) — single aggregate recall hides which category fails.

## Feeds these wiki pages

- [[retrieval-augmented-generation]]
- [[vector-and-embedding-stores]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
