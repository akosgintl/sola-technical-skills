---
title: RAG Query Understanding
aliases: [question parsing RAG, ParsedQuestion, RAG query parsing, rag-question-parsing]
type: concept
domain: ai-agentic
status: mature
tags: [rag, question-parsing, query-understanding, retrieval, enterprise, schema, dispatching]
updated: 2026-06-22
sources:
  - "https://towardsdatascience.com/question-parsing-in-rag-structure-before-you-search/"
  - "https://towardsdatascience.com/what-the-question-parser-extracts-from-a-user-string-keywords-scope-shape-decomposition-clarification/"
  - "https://towardsdatascience.com/dispatching-the-parsed-rag-question-chunk-strategy-model-tier-activations-audit/"
  - "https://towardsdatascience.com/when-rag-users-ask-vague-questions-clarify-once-learn-the-default/"
  - "https://towardsdatascience.com/document-intelligence-a-series-on-building-rag-brick-by-brick-from-minimal-to-corpus-scale/"
  - "https://towardsdatascience.com/rag-is-not-machine-learning-and-the-ml-toolkit-solves-the-wrong-problem/"
---

# RAG Query Understanding

> [!summary]
> Most RAG pipelines route the raw user string directly to an embedding model. This is wrong in two ways: it sends disambiguation cues, negations, and format instructions into a system that cannot process them, and it conflates what retrieval needs with what generation needs. **Query understanding** — parsing the user's string into a typed, structured `ParsedQuestion` before touching the retrieval index — is the overlooked brick that separates demo-quality from production-quality RAG. A clean parse delivers two separate consumer briefs (one for the retriever, one for the generator), routes compound questions to the right strategies, handles vague queries with a learnable clarification loop, and gives every answer a full audit trail. Measured production improvement: +15 percentage points accuracy versus unstructured routing.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Query understanding is the second brick in a four-brick enterprise RAG architecture (parse documents → **parse question** → retrieve → generate). It transforms a free-text user query into a typed, relational row — the `ParsedQuestion` — that downstream bricks can act on precisely instead of guessing.

The core insight is that retrieval and generation need different things from the same question:

- **RetrievalQuery** needs: topic in document vocabulary, anchor keywords, scope filters. It must *not* contain negations, format instructions, or disambiguation cues — these confuse similarity scoring.
- **GenerationBrief** needs: original user wording (preserving intent), format constraints, disambiguation cues, excluded terms. It must reach the LLM intact so it can reason, exclude, and contrast.

Routing "What is the maximum coverage amount? Don't confuse it with the deductible, they're often listed together" as a raw string to embedding retrieval pulls deductible-bearing passages *closer* and loses the format hint. Parsing it first cleanly separates "retrieve passages about coverage limit" (retrieval) from "the user wants the coverage amount, not the deductible, and knows they co-occur" (generation).

The `question_df` table mirrors `line_df` from document parsing: one row per question, columns for each parsing capability, linked to satellite tables for domain vocabulary and type registries.

## Why it matters

- **Retrieval-stage confusion is irreversible.** Once negations, distractors, and format constraints contaminate the retrieval brief, no downstream reranker or LLM can fully recover. The LLM is good at distinguishing and excluding — but only if the right passages were retrieved in the first place.
- **Compound questions are common and invisible.** In measured production, ~30% of user queries are compound; standard single-vector retrieval silently merges them, returning answers that are partially correct or misrouted. Decomposition at parse time routes each sub-question to the appropriate strategy.
- **Typed answer expectations unlock regex confirmation.** Knowing a question expects an `amount` allows the retrieval layer to apply currency-pattern regex alongside keywords — a "two-signal match" that dramatically reduces false positives.
- **Deterministic routing enables auditability.** In regulated industries (insurance, legal, financial services), a deterministic dispatcher reading the ParsedQuestion is auditable; a runtime-LLM-deciding-its-own-routing is not. "The pipeline tunes embedding models and chunk sizes but routes the raw user string to every brick" — this describes most teams, and leaves most quality on the table.

## Key concepts / building blocks

### The five field families

A complete `ParsedQuestion` has five field families:

**1. Keywords** — from four sources, in descending priority weight:
- *Explicit user terms* — highest precision; exactly what the user named
- *LLM rewrites* — 3–5 alternative phrasings that match document vocabulary (not general vocabulary)
- *Expert dictionary* — domain synonyms and aliases curated by practitioners (`deductible ↔ excess, franchise, self-insured retention`; `blood sugar ↔ A1C, HbA1c, fasting plasma glucose`)
- *Anchor regex patterns* — high-signal tokens matching regulatory codes, ISO references, product identifiers

The satellite `concept_keywords_df` table holds `(concept, language, keyword, weight)` tuples. Adding a synonym is a row insertion; no prompt edits or retraining needed.

**2. Answer shape and type** — two independent axes:

| Dimension | Values | Purpose |
|---|---|---|
| **Shape** (cardinality) | single, listing, table, tree, nested_json | Determines chunk strategy and aggregation pipeline |
| **Type** (value category) | text, amount, date, IBAN, address, boolean | Enables regex confirmation (currency patterns for `amount`, date patterns for `date`) |

A listing-shape question must route to an aggregation sweep, not a top-k ranking. A single-type `amount` question should trigger a currency-regex confirmation pass alongside keyword retrieval.

**3. Scope hints** — structural location clues applied before retrieval runs:
- Page ranges or document position hints
- TOC section references
- Layout type constraints (table, image, header)
- Detection context (line-level vs. paragraph-level for regex confirmation)
- Answer context (surrounding text scope: line, paragraph, page, section, chapter, document)

**4. Decomposition** — handles compound questions:

| Pattern | Description | Execution |
|---|---|---|
| Independent | Two unrelated sub-questions | Parallel |
| Sequential | Second depends on first answer | Sequential; pass result as context |
| Unified | Synonymous terms for the same concept | Single combined query |
| Conditional | "If X then Y" | Condition becomes scope filter |

**5. Clarification** — when ambiguity is unresolvable by parse alone, return a structured `ClarificationRequest` rather than guessing and producing a confidently wrong answer.

### RetrievalQuery and GenerationBrief

After the five field families are populated, the parser derives two consumer briefs:

**RetrievalQuery** contains: topic, topic rewrites in document vocabulary, anchor keywords, scope filters. Nothing that would confuse similarity scoring.

**GenerationBrief** contains: original user wording, format constraints, disambiguation cues, negative constraints (what to exclude), answer type and shape. The LLM reads this to distinguish, exclude, and format — operations retrieval cannot do.

> [!tip] Exclusions belong to GenerationBrief, not RetrievalQuery. "Not the deductible" as a retrieval filter causes line-level, page-level, or section-level exclusions that remove the answer alongside the noise. Retrieve broadly on all relevant terms; let generation apply negative filters.

### Dispatching

The dispatcher reads the `ParsedQuestion` plus the document profile and makes three routing decisions without LLM involvement:

**1. Chunk strategy** — three fields from the `answer_context` axis:
- `detection_context`: granularity for regex confirmation (line for amounts/dates, paragraph for narrative)
- `answer_context`: surrounding text scope for generation
- `chunk_strategy`: sequential for single facts vs. combined for synthesized answers

**2. Model tier** — cascading defaults: concept-level override > type-level default > project fallback. Four conceptual tiers (nano / mini / standard / reasoning) mapped in `llm_model_tiers_df`.

**3. Activation flags** — document-aware downgrades prevent confident wrong answers. Word documents disable `extract_page_numbers` (page breaks are renderer-dependent). Scanned PDFs downgrade `extract_table_cells` when OCR quality is flagged.

Three approaches to dispatch routing:

| Approach | Mechanism | Verdict |
|---|---|---|
| A — User explicit | Arguments at call time | Debugging / override only |
| **B — Deterministic dispatcher** | Code reads ParsedQuestion + doc profile | **Recommended** for enterprise |
| C — LLM autonomous | Model decides its own routing at runtime | Rejected: reproducibility and cost control |

Approach B is auditable, reproducible, and cost-bounded. The `_meta` audit block captures decomposition pattern, activation states, skip reasons, iterations, retrieval methods, model and prompt versions — the full provenance chain per answer.

### Clarification learning loop

When a `ParsedQuestion` field falls below a confidence threshold, the system emits a `ClarificationRequest` rather than silently guessing:

```
ClarificationRequest:
  target_field: which field is ambiguous
  question_to_user: focused clarification prompt
  candidate_values: proposed options
  proposed_default: system's recommended value
  proposed_default_reason: rationale
  audit: tracking metadata
```

After each resolution, the system updates a `ClarificationDefault` record with vote-weighted learning:

| Signal | Vote update |
|---|---|
| Explicit yes (user confirms) | +1.0 |
| Implicit acceptance (eval confirms silently applied default) | +0.5 |
| Explicit no (user corrects) | −1.0 for proposed; +1.0 for chosen |
| Failure detection (default returns null) | Stratification trigger, not vote change |

Confidence gates determine behavior: below 0.60 → always ask; 0.60–0.85 → ask occasionally to refresh; above 0.85 → apply silently. When a default fails on a document subset, the system stratifies the default (e.g., `source_page=1` for body-type contracts, `source_page=TOC` for coversheet-type contracts) rather than decrementing votes.

This is not multi-turn dialogue. Each request is independent; the learned default carries context across separate requests occurring days or weeks apart. Infrastructure cost: two Pydantic schemas and one lookup table column.

## Design decisions & trade-offs

| Decision | The real trade-off |
|---|---|
| **One LLM call vs. step-by-step parsing** | Step-by-step lets you test sub-tasks in isolation; consolidated single call reduces latency ~5×. Start step-by-step in development; consolidate for production with a single `FullParse` schema. |
| **Expert dictionary vs. HyDE** | HyDE generates general-domain vocabulary that misses enterprise OOV terms. Expert dictionaries are more accurate, faster, and auditable. Use embeddings to *discover* candidates; experts to *validate*; dictionaries to *serve*. |
| **Deterministic dispatcher vs. LLM routing** | LLM routing is flexible but violates reproducibility and cost-control requirements in regulated industries. Deterministic dispatcher is inspectable by domain experts and can be unit-tested. |
| **Clarify vs. infer** | Silently applying a wrong default produces a "steady drip of subtly wrong answers." Asking too often erodes user experience. Confidence gating (0.60 / 0.85 thresholds) calibrates between asking and applying. |
| **Single parsed question vs. decomposed sub-questions** | Over-decomposing compound questions adds latency; under-decomposing conflates unrelated retrievals. Prefer unified pattern (single search, combined keywords) for related terms; independent only when sub-questions have genuinely separate retrieval targets. |

## State of the art

- **Question parsing as production differentiator.** The Enterprise Document Intelligence series (Angela Shi, 2026) reports +15 percentage points accuracy in a measured broker-corpus deployment (91% vs. 76%) from question parsing alone — before any embedding or reranker changes. Parsing latency was 280ms; 71% single, 19% independent decomposition, 4% clarification trigger rate.
- **Relational data model for questions.** Treating questions as rows in a typed `question_df` table (parallel to `line_df` for document lines) enables SQL-style querying, versioning, and per-question-type evaluation — a structural shift from treating questions as ephemeral strings.
- **Satellite tables as the configuration surface.** New answer types, question shapes, vocabulary concepts, and model tier mappings are row insertions in satellite tables, not prompt edits or code changes. This makes the parsing schema production-safe to extend.
- **Clarification defaults as institutional memory.** The vote-weighted `ClarificationDefault` stores learned patterns per doctype — a lightweight but durable form of corpus intelligence that reduces user-facing clarification requests over time without model retraining.

## Pitfalls & anti-patterns

- **Routing the raw user string to retrieval.** The canonical anti-pattern. Negations, distractors, format hints, and disambiguation cues all distort embedding similarity.
- **Keyword extraction as complete parsing.** Pulling keywords is step one; answer shape, type, scope, decomposition, and consumer brief splitting are equally important and frequently skipped.
- **Putting exclusions in RetrievalQuery.** Removes the answer alongside the noise (line-, page-, or section-level). Keep negative constraints in GenerationBrief.
- **Caching parsed questions without document profile.** The same question on a Word document vs. a scanned PDF requires different activation flags. Never cache by question text alone.
- **Over-relying on embeddings for specialized vocabulary.** OOV enterprise terms simply lack web training data; no embedding model upgrade recovers them. Expert dictionary is the only fix.
- **Over-decomposing compound questions.** Decompose only when sub-questions have genuinely separate retrieval targets; unnecessary decomposition adds latency and breaks unified concepts.
- **Mixing format constraints into retrieval brief.** "Return a table comparing X and Y" belongs in GenerationBrief only; it directs the LLM's output format, not the retriever's scoring.
- **Hand-setting all activation flags.** Flags should come from the deterministic dispatcher reading the parsed question + document profile, with manual overrides only for debugging.

## See also

- [[retrieval-augmented-generation]]
- [[vector-and-embedding-stores]]
- [[llm-application-architecture]]
- [[ai-evaluation-and-quality]]
- [[context-engineering]]
- [[guardrails-and-output-validation]]

## Sources

- [Angela Shi — RAG Questions Need Parsing Too (TDS, Jun 2026)](https://towardsdatascience.com/question-parsing-in-rag-structure-before-you-search/)
- [Angela Shi — What the Question Parser Extracts (TDS, Jun 2026)](https://towardsdatascience.com/what-the-question-parser-extracts-from-a-user-string-keywords-scope-shape-decomposition-clarification/)
- [Angela Shi — Dispatching the Parsed RAG Question (TDS, Jun 2026)](https://towardsdatascience.com/dispatching-the-parsed-rag-question-chunk-strategy-model-tier-activations-audit/)
- [Angela Shi — When RAG Users Ask Vague Questions (TDS, Jun 2026)](https://towardsdatascience.com/when-rag-users-ask-vague-questions-clarify-once-learn-the-default/)
- [Angela Shi — Enterprise Document Intelligence: Series Overview (TDS, May 2026)](https://towardsdatascience.com/document-intelligence-a-series-on-building-rag-brick-by-brick-from-minimal-to-corpus-scale/)
- [Angela Shi — RAG Is Not Machine Learning (TDS, Jun 2026)](https://towardsdatascience.com/rag-is-not-machine-learning-and-the-ml-toolkit-solves-the-wrong-problem/)
