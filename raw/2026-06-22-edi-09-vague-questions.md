---
title: "When RAG Users Ask Vague Questions: Clarify Once, Learn the Default"
aliases: [edi-vague-questions, rag-clarification-loop]
type: source
domain: ai-agentic
status: seed
tags: [source, rag, clarification, learned-defaults, question-parsing, enterprise]
updated: 2026-06-22
source_url: https://towardsdatascience.com/when-rag-users-ask-vague-questions-clarify-once-learn-the-default/
source_type: article
ingested: 2026-06-22
feeds: [rag-query-understanding, retrieval-augmented-generation]
---

# When RAG Users Ask Vague Questions: Clarify Once, Learn the Default

> [!info] Source metadata
> **Author/Org:** Angela Shi · **Date:** June 22, 2026 · **URL:** https://towardsdatascience.com/when-rag-users-ask-vague-questions-clarify-once-learn-the-default/

## Key takeaways

- Five failure patterns for vague single-document questions: (1) ambiguous field type ("the limit" on a contract with multiple limits), (2) missing page scope, (3) ambiguous date scope (multiple versions/endorsements), (4) ambiguous intent (cite vs. summarize vs. extract), (5) implicit entity ("the policyholder" when multiple roles listed).
- **Two Pydantic schemas** handle clarification: `ClarificationRequest` (emitted when ParsedQuestion field falls below confidence threshold) + `ClarificationDefault` (stores learned patterns).
- `ClarificationRequest` fields: `target_field`, `question_to_user`, `candidate_values`, `proposed_default`, `proposed_default_reason`, `audit`.
- `ClarificationDefault` fields: `target_field`, `doctype`, `sub_conditions` (stratifying keys), `candidate_votes` (weighted vote counts), `confidence` (0-1), `sample_size`, `last_refreshed`.
- **Confidence gates**: below 0.60 → always ask; 0.60-0.85 → ask occasionally to refresh; above 0.85 → apply silently.
- **Vote update rules**: explicit yes +1.0; explicit no −1.0; implicit acceptance (downstream eval confirms) +0.5; failure detection → stratification signal (not vote reduction).
- **Stratification**: when default fails on a subset of documents, system sub-conditions the default (e.g., `source_page=1` for body-type pages, `source_page=TOC` for coversheet-type pages).
- Pattern is NOT multi-turn dialogue — each request is independent. Learned default carries context across separate requests days or weeks apart.
- Minimal infrastructure: two Pydantic schemas + one lookup table column.
- Deferred concerns: multi-field clarifications (bundle, don't sequence), adversarial users (per-user reputation signals), cross-tenant default sharing.

## Notable claims (with location)

- Worked example (broker contract, 12 cases): confidence built from single confirmation at 0.78/12 cases → silent application → failure detection → stratification. Shows the full learning arc.

## Feeds these wiki pages

- [[rag-query-understanding]]
- [[retrieval-augmented-generation]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
