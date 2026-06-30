---
title: AI Evaluation and Quality
aliases: [LLM eval, evals, AI quality, LLM evaluation, eval harness]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, evaluation, quality, llm-eval, hallucination, drift]
updated: 2026-06-30
sources:
  - raw/2026-06-23-decodingai-03-llm-structured-outputs.md
  - raw/2026-06-30-theneuralmaze-01-eval-vs-patching-failures.md
  - https://arxiv.org/abs/2306.05685
  - https://arxiv.org/abs/2212.10560
  - https://arxiv.org/abs/2309.15217
  - https://arxiv.org/abs/2407.10457
  - https://arxiv.org/abs/2501.05249
  - https://wandb.ai/site/weave
---

# AI Evaluation and Quality

> [!summary]
> AI evaluation and quality is the discipline of systematically measuring whether an AI system is correct, safe, and reliable — across offline test suites, production monitoring, and agent-trajectory analysis — so that changes to prompts, models, or retrieval are governed by evidence rather than intuition.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

An LLM application without an eval harness is a system where every change is a guess. Swapping model versions, tuning a prompt, adjusting retrieval chunk size, or changing a guardrail — all of these affect output quality in ways that manual spot-checking cannot reliably detect. AI evaluation installs a measurement layer that makes these effects visible and comparable.

The discipline spans three tiers: **offline evaluation** (curated test sets run before deployment), **online monitoring** (production traffic analysis after deployment), and **agent-specific evaluation** (trajectory and tool-call correctness for agentic workflows). Together they form a feedback loop that closes the gap between "seems to work in demos" and "demonstrably works in production."

## Why it matters

Quality is the invisible cost. A poorly prompted or model-mismatch application produces plausible-sounding but wrong answers — and in most deployments there is no automated mechanism to detect this. Studies of RAG systems using the RAGAS framework show that retrieval recall and answer faithfulness frequently diverge: a system can retrieve relevant context 90 % of the time yet still hallucinate in 30 % of responses if context synthesis is weak.

Beyond individual response quality, regression is the operational risk: a prompt change that improves one task class degrades another. Without a regression suite, engineering teams discover these regressions through user complaints, often days or weeks after deployment. The cost of an eval harness is the engineering time to build it; the cost of not having one compounds continuously.

For regulated domains (healthcare, finance, legal), evaluation artefacts are increasingly a compliance input: EU AI Act Article 9 requires risk management systems that include "testing procedures" for high-risk AI, and the NIST AI RMF MAP function explicitly includes measurement of AI system performance.

## Key concepts

### Offline evaluation

**Curated test sets.** A ground-truth dataset of inputs and expected outputs, partitioned by task class (factual QA, summarisation, extraction, reasoning). Evaluated against metrics appropriate to the task: exact match, F1, ROUGE, BERTScore, or LLM-as-judge score.

**LLM-as-judge (arXiv:2306.05685).** A capable model (often a frontier model or a purpose-fine-tuned judge) evaluates the output against criteria: coherence, faithfulness, helpfulness, safety. Scales to open-ended tasks where reference answers do not exist. The seminal MT-Bench paper demonstrated strong correlation between GPT-4-as-judge scores and human preferences. Known biases that must be controlled for:

| Bias | Description | Mitigation |
|---|---|---|
| Position bias | Judges favour the first response when comparing two | Randomise order; use reference-free absolute scoring |
| Verbosity bias | Longer responses score higher regardless of quality | Add length-penalty instruction; calibrate on known-bad verbose outputs |
| Self-evaluation bias | Models rate their own outputs higher | Use a different model as judge |
| Sycophancy | Judge inflates scores when responses confirm the judge's priors | Include adversarial examples in calibration set |

**Reference-based metrics** (ROUGE, BLEU, BERTScore) work where a canonical reference answer exists (summarisation, translation, extraction). They are poor proxies for open-ended generation quality and should not be the primary metric for conversational or reasoning tasks.

### RAG-specific evaluation: RAGAS framework

RAG systems require evaluation of both retrieval and generation. The RAGAS framework (arXiv:2309.15217) defines four component metrics:

| Metric | What it measures | Score range |
|---|---|---|
| **Faithfulness** | Does the answer use only information present in the retrieved context? | 0–1 |
| **Answer relevance** | Does the answer address the question? | 0–1 |
| **Context precision** | Are retrieved chunks relevant to the question? | 0–1 |
| **Context recall** | Does the retrieved context contain the information needed? | 0–1 |

Pathological splits are diagnostically useful: high context recall + low faithfulness → the model is ignoring context and hallucinating. High faithfulness + low context recall → retrieval is the bottleneck.

TruLens (open source) implements RAG triad evaluation (groundedness, answer relevance, context relevance) as an instrumentation layer that can be added to any LangChain or LlamaIndex pipeline.

### Hallucination measurement

Hallucination — generating factual claims not supported by the retrieved context or training knowledge — is the primary quality failure mode for LLM applications. Measurement approaches:

- **Faithfulness scoring** (RAGAS/TruLens): checks generated claims against retrieved context; does not check against world knowledge.
- **Factual consistency NLI**: a natural language inference model classifies each generated sentence as entailed, neutral, or contradicted by a reference. AlignScore and SummaC are established open-source options.
- **Semantic entropy (arXiv:2406.xxx)**: measures model uncertainty by sampling multiple responses and computing semantic clustering; high entropy = the model is uncertain = higher hallucination risk. Provides a per-query confidence signal without a reference answer.
- **LLM self-consistency**: generate N samples at temperature > 0 and check agreement. High disagreement is a hallucination signal.

> [!warning]
> No hallucination metric is 100 % reliable. Faithfulness scores miss hallucinations that are consistent with (but not present in) retrieved context. Self-consistency misses confident-but-wrong responses. Layer multiple signals and monitor for systematic failure modes per domain.

### Agent trajectory evaluation

For agentic workflows, response-level metrics are insufficient. The unit of evaluation shifts to the **trajectory**: the full sequence of observations, reasoning steps, tool calls, and outputs that the agent produces to complete a task.

Key agent-specific metrics:

| Metric | Description |
|---|---|
| Task completion rate | Did the agent achieve the stated goal? (binary or partial credit) |
| Tool call accuracy | Did the agent call the right tool with the right arguments? |
| Trajectory efficiency | How many steps did the agent take vs. the minimum needed? |
| Error recovery rate | When the agent received a tool error, did it recover appropriately? |
| Hallucinated tool calls | Did the agent invent tool capabilities or arguments that don't exist? |

Trajectory evaluation requires a **judge agent** or a human reviewing the step log, not just the final output. WebArena and τ-bench (arXiv:2407.10457) are the standard agentic benchmarks as of mid-2026; τ-bench simulates realistic tool-use scenarios across retail and airline domains.

### Production monitoring (online evaluation)

After deployment, the eval discipline shifts to continuous measurement on live traffic:

- **Distribution shift detection**: embed incoming questions in a vector space and monitor cluster drift; sudden shift signals out-of-distribution queries arriving (e.g., a new user segment or a product change).
- **LLM-as-judge on sampled traffic**: run the offline judge on a random sample (1–5 %) of production requests. Statistically significant quality drop triggers a regression review.
- **Human feedback loop**: thumbs up/down, explicit corrections, and escalation signals are high-signal quality labels. Aggregate weekly; watch for trend breaks.
- **Latency and cost as quality proxies**: unexpectedly long responses (verbose hallucination pattern) and cost-per-query spikes (excessive retries, context overflow) are leading indicators of quality problems.

### Eval-driven development

The recommended workflow, analogous to test-driven development: **write the eval before changing the prompt or model**. The sequence:

1. Define the success criterion for the change (what does "better" mean here, measurably?).
2. Build or extend the test set to cover the target behaviour.
3. Establish a baseline score on the current system.
4. Make the change.
5. Re-run the eval; accept if improvement >= threshold AND no regression on other task classes.

![[2026-06-23-decodingai-03-llm-structured-outputs-02.png|Scientific-method optimization loop]]
*Figure: The optimize-evaluate loop: configure → run → measure → compare → repeat until metrics clear the bar — source [[2026-06-23-decodingai-03-llm-structured-outputs]].*

This disciplines prompt engineering from an art into a measured engineering practice.

## Design decisions and trade-offs

**LLM-as-judge vs. human labels.** Human labels are ground truth but expensive and slow. LLM-as-judge scales indefinitely and can run in CI, but inherits the judge model's biases. Use human labels to calibrate the judge (ensure judge agreement with humans on a sample); then use the judge at scale.

**Specialised eval model vs. same model as application.** Using the same model as both judge and application introduces self-evaluation bias. A different model family or a fine-tuned judge model gives an independent signal. Prometheus-2 (arXiv:2405.01535) is a fine-tuned open-source judge that outperforms GPT-4-as-judge on evaluation benchmarks.

**Offline eval depth vs. CI speed.** A comprehensive eval suite that takes 20 minutes to run will be skipped. Design a fast "smoke eval" (< 2 min, critical paths only) for every CI run, and a full eval suite run nightly or on release branches.

**Evaluation data contamination.** If test examples are leaked into the model's training data (or into the prompt's few-shot examples), scores are inflated. Treat the eval set as sensitive; never include test examples in prompts or fine-tuning data. This is not a niche risk: contamination accumulated badly enough that **MMLU, HumanEval, HellaSwag, and the original GSM8K have effectively been retired** — top models cluster in the 90s and the scores no longer rank frontier work. Lexical-obfuscation defenses (shuffling MCQ options, synonym substitution, reversible ciphers) mostly fail because models trained on the obfuscated formats too; the field's response was harder benchmarks with cleaner splits (e.g. LiveBench), not abandoning evals.

**Hold the split order, and don't confuse patching with improvement.** Train on one chunk, tune (prompt edits, rules, patches) against a *validation* chunk, and touch the *test* chunk only once at the end — "the validation set is where you're allowed to fail; the test set is where failing means something." Reverse-engineering a fix from the exact case that failed and then scoring it on a set that includes that case contaminates your own evaluation: the metric goes up but stops meaning anything. Patching one surfaced failure at a time is overfitting in its most literal form — it does not tell you the system got better, only that you memorized the cases you happened to see ([[2026-06-30-theneuralmaze-01-eval-vs-patching-failures|Mai / The Neural Maze]]). Note the residual trap a clean split does *not* fix: ticket-shaped **sampling bias** means an honest number can still be honest about the wrong region of the input space.

## State of the art

**Weights & Biases Weave (2024–2026)** provides trace-level LLM application observability with built-in eval primitives: per-call scoring, judge integration, regression dashboards, and dataset management. It is the de-facto platform for teams already using W&B for ML experiment tracking.

**LangSmith (LangChain)** and **Braintrust** are alternatives targeting LLM-application-specific evaluation workflows, with dataset management, human annotation interfaces, and CI integration.

**Evals as unit tests pattern (Anthropic cookbook):** define each prompt's expected behaviour as a structured test case with `inputs`, `criteria`, and a judge function. Store evals in version control alongside the prompt. CI runs the eval suite; a failing eval blocks the PR. This operationalises the eval-driven development workflow above.

**τ-bench (arXiv:2407.10457, 2024):** the standard agentic tool-use benchmark as of mid-2026, covering realistic multi-turn tool interactions across two domains (airline, retail). Current frontier models (Claude Sonnet 4.6, GPT-4o) achieve 60–70 % task completion; τ-bench failures are dominated by error recovery and multi-step plan revision.

**HELMET benchmark (arXiv:2501.05249, 2025):** evaluates long-context LLMs across RAG, summarisation, ICL, re-ranking, and citation tasks with application-aligned metrics. Finds that commercial models significantly outperform open-source at >32k context; performance cliffs at 128k+ are common.

> [!tip]
> The minimum viable eval harness: one JSON file of `{input, expected_output}` pairs per task class, one LLM-as-judge function, and a CI step that fails if the mean judge score drops below a threshold. This baseline catches 80 % of regressions and takes one afternoon to build.

## Pitfalls and anti-patterns

- **No eval harness at all.** Quality is invisible; every production incident is a surprise.
- **Only evaluating on the happy path.** Test sets that cover only easy, well-formed inputs give false confidence. Include adversarial examples, edge cases, and the inputs that caused past incidents.
- **Using the same model as judge and application.** Self-evaluation bias inflates scores. Use a different model family or a fine-tuned judge.
- **Benchmark over-fitting.** Optimising prompts specifically against the eval set (rather than the underlying behaviour) produces scores that don't generalise. Treat the eval set as a held-out test set, not a training signal.
- **Offline only.** A system that scores well offline but degrades on production traffic (distribution shift, adversarial inputs, novel query patterns) will not be caught. Online sampling + judge is mandatory at production scale.
- **Manual evaluation at scale.** Human review of every production response is neither economical nor consistent. Define the sampling strategy and automate as much of the scoring as possible, reserving human review for low-confidence judge outputs.
- **Ignoring trajectory for agents.** Evaluating only the final answer of an agentic workflow misses incorrect intermediate steps that produced a correct output by luck, or correct intermediate steps that were followed by an erroneous synthesis.

## See also

- [[guardrails-and-output-validation]] — output validation as runtime complement to offline evals
- [[model-selection-and-routing]] — eval thresholds drive the routing quality gate
- [[ai-agent-observability]] — production monitoring and trace collection
- [[llm-application-architecture]] — where the eval harness plugs into the LLM app stack
- [[context-engineering]] — context quality directly affects faithfulness scores
- [[retrieval-augmented-generation]] — RAGAS metrics and RAG-specific quality concerns

## Sources

- Zheng, L. et al. (2023). *Judging LLM-as-a-Judge with MT-Bench and Chatbot Arena.* arXiv:2306.05685. https://arxiv.org/abs/2306.05685
- Liang, P. et al. (2022). *Holistic Evaluation of Language Models (HELM).* arXiv:2212.10560. https://arxiv.org/abs/2212.10560
- Es, S. et al. (2023). *RAGAS: Automated Evaluation of Retrieval Augmented Generation.* arXiv:2309.15217. https://arxiv.org/abs/2309.15217
- Yao, S. et al. (2024). *τ-bench: A Benchmark for Tool-Agent-User Interaction in Real-World Domains.* arXiv:2407.10457. https://arxiv.org/abs/2407.10457
- Yen, H. et al. (2025). *HELMET: How to Evaluate Long-Context Language Models Effectively and Thoroughly.* arXiv:2501.05249. https://arxiv.org/abs/2501.05249
- Weights & Biases (2026). *Weave — LLM Application Evaluation and Observability.* https://wandb.ai/site/weave
- Mai & Otero Pedrido, M. (2026-06-20). *You Didn't Fix the Model. You Memorized the Failure.* The Neural Maze. https://theneuralmaze.substack.com/p/you-didnt-fix-the-model-you-memorized
