---
title: Synthetic Data
aliases: [synthetic data, synthetic training data, privacy-preserving synthetic data, data augmentation, model collapse, self-instruct]
type: concept
domain: data
status: mature
tags: [data, synthetic-data, training-data, privacy, model-collapse, augmentation]
updated: 2026-06-27
sources:
  - "https://www.digitalapplied.com/blog/synthetic-data-generation-llm-training-decision-guide-2026"
  - "https://futureagi.com/blog/synthetic-data-fine-tuning-llms/"
  - "https://arxiv.org/abs/2305.17493"
  - "https://research.google/blog/synthetic-and-federated-privacy-preserving-domain-adaptation-with-llms-for-mobile-applications/"
  - "https://tetrate.io/learn/ai/synthetic-data-generation-llms"
---

# Synthetic Data

> [!summary]
> Synthetic data is model- or simulation-generated data that **augments or replaces** scarce,
> expensive, or privacy-sensitive real data. In 2026 it is a mainstream strategy — Gartner projects
> that **>60% of AI training on sensitive data will use synthetic datasets**, and the EU AI Act
> explicitly recognizes it for compliance. It powers instruction and preference data (Self-Instruct,
> Evol-Instruct, Constitutional AI, DPO pairs), tool-use traces, evaluation sets, edge-case
> augmentation, and privacy substitution. The architect's job is matching the **generation method to
> the use case** and managing the genuinely distinct failure modes: **model collapse** (recursively
> training on synthetic output), fidelity/diversity gaps, and **false privacy** (a generator can
> memorize and leak the real seed data). It is distinct from [[model-customization]] (which *consumes*
> it), [[data-privacy-engineering]] (privacy substitution is *one* use), and
> [[ai-evaluation-and-quality]] (synthetic *eval* data).

**Domain:** [[tier-2-solid|Data Architecture]]

## What it is

Instead of collecting and labeling real data, you **generate** it — most commonly today by prompting
a strong "teacher" LLM, but also via simulation or statistical/GAN methods. The point is to produce
training, evaluation, or test data where real data is scarce, costly, slow to label, or legally
locked behind privacy constraints. Synthetic data is a *complement* to real data, not usually a
wholesale replacement (see model collapse below).

## Why it matters

**Data is the bottleneck.** Frontier-quality real labeled data is scarce, expensive, slow to acquire,
and frequently privacy-restricted. Synthetic data unlocks the cases real data can't reach:

- **Privacy** — generate realistic data that stands in for real PII, so you can train and share
  *without storing* the sensitive original (a key technique in [[data-privacy-engineering]]); the EU
  AI Act treats it as a compliance tool.
- **Scarcity and cold start** — bootstrap a task before real usage data exists.
- **Edge cases** — manufacture rare scenarios (fraud, failures, long-tail inputs) that are
  underrepresented in real data.
- **Alignment and capability** — instruction, preference, and tool-use data at a scale and cost human
  labeling can't match.

But it carries distinct, real risks an architect must own — it is not free, clean data.

## Key concepts / building blocks

### Use cases and generation methods

| Use case | Method |
|---|---|
| Instruction tuning | **Self-Instruct**, **Evol-Instruct** (evolve prompts to increase difficulty/diversity) |
| Safety / refusal | **Constitutional AI** (model critiques and revises against principles) |
| Preference alignment | **DPO/IPO preference pairs** (generated chosen/rejected) |
| Tool-using agents | Synthetic **function-call traces** |
| Retrieval evaluation | Synthetic **RAG QA** sets |
| Robustness | **Edge-case augmentation** |
| Privacy | **Privacy substitution** (synthetic stand-ins for real records) |

These feed [[model-customization]] (the training side) and [[ai-evaluation-and-quality]] (eval sets).

### Model collapse

A peer-reviewed phenomenon: a model trained recursively on its own (or others') synthetic output
**degrades** — losing the distribution's tails and collapsing toward the mean, getting blander and
less diverse each generation. The fix is **not** to avoid synthetic data but to **accumulate real
data alongside it** rather than replace it. Synthetic-only training loops are the danger.

### Fidelity, diversity, and coverage

Synthetic data is only useful if it **matches the real distribution** and is **diverse** — homogeneous
synthetic data teaches a narrow, brittle model. Evaluate the *data itself* (fidelity, diversity,
coverage, label correctness) before training on it.

### False privacy

"Synthetic" does not automatically mean "private." A generator trained on real data can **memorize
and reproduce** specific records, so naive synthetic data can leak the very PII it was meant to
protect. Privacy-preserving generation needs **differential privacy** on the generator (or federated
generation) and explicit leakage testing — see [[data-privacy-engineering]].

## Design decisions & trade-offs

- **Synthetic vs. real vs. hybrid.** **Hybrid** (real + synthetic) is the default: synthetic for
  scale, coverage, and privacy; real to anchor the distribution and prevent collapse. Pure-synthetic
  risks collapse and distribution drift; real-only is scarce, costly, and privacy-locked.
- **Privacy substitution requires proof.** Replacing real data with synthetic reduces exposure only
  if the generator is differentially private and leakage-tested. Treat unproven "synthetic =
  anonymous" claims as the [[data-privacy-engineering|pseudonymization-vs-anonymization]] trap.
- **Method by use case.** Instruction, preference, eval, and augmentation each need different
  generation recipes and carry different failure modes — don't apply one pipeline to all.
- **Teacher model: quality, bias, and licensing.** Distilling from a frontier model can violate its
  terms of service, and it **amplifies the teacher's biases and errors** at scale. Check the license
  and audit for inherited flaws.
- **Generation cost/speed vs. human labeling.** Synthetic is far cheaper and faster than human
  annotation, but the savings are real only if the data passes a quality gate.
- **Always eval the synthetic data before use.** Fidelity/diversity/leakage gates are the equivalent
  of [[data-pipelines-and-orchestration|pipeline quality gates]] for generated data.

## State of the art

- **Mainstream and compliance-recognized**: Gartner projects >60% of sensitive-data AI training uses
  synthetic data; the EU AI Act names it as a compliance tool.
- **Standard recipes**: Self-Instruct / Evol-Instruct for instruction data, Constitutional AI for
  safety, generated DPO pairs for alignment, function-call traces for agents, synthetic RAG QA for
  retrieval eval.
- **Privacy-preserving generation** (differential privacy + federated, e.g. Google's on-device work)
  is an active, productionizing area.
- **Model collapse is a recognized risk** with an accepted mitigation ("accumulate, don't replace").
- **Agents increasingly generate their own training/eval traces**, tightening the loop with
  [[model-customization]] and [[ai-evaluation-and-quality]].

## Pitfalls & anti-patterns

- **Model collapse.** Recursive synthetic-only training that degrades diversity and quality. Keep real
  data in the mix.
- **False privacy.** Synthetic data that leaks memorized seed PII because generation wasn't
  differentially private or leakage-tested.
- **Low diversity / fidelity.** Homogeneous or off-distribution synthetic data producing a narrow,
  brittle model.
- **Replacing real data wholesale.** Treating synthetic as a full substitute rather than an augment.
- **No evaluation of the data itself.** Training on generated data without fidelity/diversity/leakage
  gates.
- **Teacher ToS / bias inheritance.** Distilling from a frontier model against its license, or
  scaling up its biases and errors.
- **Synthetic for facts the model must get right.** Generated data can encode plausible-but-wrong
  "facts" — validate against ground truth for knowledge-bearing tasks.

## See also

- [[model-customization]]
- [[data-privacy-engineering]]
- [[ai-evaluation-and-quality]]
- [[ai-data-fabric]]
- [[data-pipelines-and-orchestration]]
- [[model-supply-chain-security]]
- [[compliance-and-regulation]]

## Sources

- [Digital Applied — Synthetic Data for LLM Training: Decision Guide 2026](https://www.digitalapplied.com/blog/synthetic-data-generation-llm-training-decision-guide-2026)
- [Future AGI — Synthetic Data for LLM Fine-Tuning: Methods & Stack](https://futureagi.com/blog/synthetic-data-fine-tuning-llms/)
- [Shumailov et al. — The Curse of Recursion: Training on Generated Data Makes Models Forget (model collapse), arXiv:2305.17493](https://arxiv.org/abs/2305.17493)
- [Google Research — Synthetic and federated: privacy-preserving domain adaptation with LLMs](https://research.google/blog/synthetic-and-federated-privacy-preserving-domain-adaptation-with-llms-for-mobile-applications/)
- [Tetrate — Synthetic Data Generation with LLMs: Techniques and Use Cases](https://tetrate.io/learn/ai/synthetic-data-generation-llms)
