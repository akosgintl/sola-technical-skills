---
title: Model Selection and Routing
aliases: [model routing, LLM routing, LLM cascade, model cascade]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, llm, routing, cost, latency, model-selection]
updated: 2026-06-21
sources:
  - https://arxiv.org/abs/2406.18665
  - https://arxiv.org/abs/2406.02524
  - https://docs.litellm.ai/docs/routing
  - https://arxiv.org/abs/2310.11511
  - https://arxiv.org/abs/2502.17392
  - https://www.anthropic.com/pricing
---

# Model Selection and Routing

> [!summary]
> Model selection and routing is the practice of matching each LLM request to the cheapest model that meets quality requirements — through difficulty-based cascades, capability routing, and fallback chains — reducing inference cost 30–50 % while maintaining output quality.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

No single model is optimal for all requests. A simple factual lookup does not need a frontier reasoning model; a complex multi-step derivation does. Model selection and routing exploits this mismatch: classify the request by difficulty, domain, or required capability, send it to the most cost-efficient model that can handle it, and fall back to a more capable model only when the smaller one fails.

At the architecture level this encompasses three distinct decisions: **which model** (capability vs. cost fit), **at what latency** (streaming, batch, or deferred), and **via what capability** (direct inference, RAG-augmented context, or fine-tuned specialisation). Getting these right is the largest single cost lever available to an LLM application operator.

## Why it matters

Frontier model pricing makes naive routing expensive at scale. At mid-2026 list prices: Claude Sonnet 4.6 costs $3/$15 per million input/output tokens; Claude Opus 4.8 costs $15/$75; Claude Haiku 4.5 costs $0.80/$4. A question answerable by Haiku costs ~19× less than the same question sent to Opus. At 10 million requests per day, that difference is the distinction between a viable and an unviable unit economics model.

RouteLLM (Stanford/LMSYS, arXiv:2406.18665) demonstrated that a trained router reduces frontier-model calls by 40–50 % with less than 5 % quality degradation on standard benchmarks. Even a simple heuristic router (question length + keyword signals) captures a meaningful fraction of this saving without training data.

Beyond cost, routing enables **reliability**: if the preferred model is rate-limited, overloaded, or returning errors, a fallback chain keeps the application available. And routing enables **capability matching** — some tasks (long-context analysis, vision, code) have clear model-specific performance advantages regardless of cost.

## Key concepts

### The cost–latency–quality triangle

Every routing decision is a trade-off across three axes:

| Axis | Low end | High end |
|---|---|---|
| Cost | Small model (Haiku, GPT-4o-mini) | Frontier model (Opus, GPT-o3) |
| Latency | Streaming, fast inference | Extended thinking, long context |
| Quality | Adequate for structured tasks | Required for open-ended reasoning |

The router's job is to find the Pareto-optimal assignment: send each request to the cheapest model that clears a quality threshold for that request class.

### Routing strategies

**Difficulty-based cascade (RouteLLM pattern).** A lightweight router model or scoring function estimates request difficulty and assigns a tier:

1. Easy (factual Q&A, extraction, classification) → small model
2. Medium (multi-step reasoning, summarisation with nuance) → mid-tier model  
3. Hard (novel reasoning, long-context synthesis, ambiguous instruction) → frontier model

RouteLLM trains a reward-model-based and a matrix-factorisation-based router; both outperform heuristic classifiers on MMLU, MT-Bench, and GSM8K.

**Capability routing.** Route based on the task modality or domain:

- Code generation → model with strong HumanEval/SWE-bench scores (Claude Sonnet, GPT-4o, Gemini 2.5)
- Vision/multimodal → model with image input support
- Very long context (>100k tokens) → model with large context window and documented attention quality at that length
- Tool use / function calling → model with structured output reliability

**Cost-ceiling routing.** Set a maximum cost-per-request budget. The router selects the highest-capability model that fits the budget; if no model fits (e.g., an unusually long prompt), the request queues for batch processing at a cheaper rate.

**Fallback chains.** Define an ordered list: `[primary, fallback_1, fallback_2]`. On timeout, rate-limit (HTTP 429), or safety refusal, retry the next model in chain. LiteLLM's router implements this with configurable `num_retries`, `timeout`, and `allowed_fails` per model.

### Speculative decoding

A latency-optimisation technique rather than a cost-saving one: a small "draft" model generates candidate tokens at high speed; a large "verifier" model confirms or rejects them in parallel. Accepted tokens are committed; rejected tokens are regenerated by the verifier. Net effect: frontier-model quality at near-small-model throughput for tasks where the draft model is frequently correct. Used internally by major inference providers (Anthropic, Google) and available via Hugging Face `assisted_generation`.

### Prompt vs. RAG vs. fine-tune decision

Routing also applies to the *capability acquisition* decision — how to make a model competent at a task:

| Approach | When to choose | Cost profile |
|---|---|---|
| **Prompting** | Task is general; few-shot examples fit in context | Token cost only; zero setup |
| **RAG** | Knowledge is large, dynamic, or proprietary; model lacks it | Token cost + retrieval infra |
| **Fine-tuning** | Task is narrow and repetitive; latency/cost must be minimised; model behaviour must be shaped | Training cost + hosting; amortises at high volume |
| **Prompt caching** | Stable system prompt + few-shot examples; same prefix repeated across many requests | 90 % cost reduction on cached prefix (Anthropic, Google) |

Fine-tuning is frequently over-selected. It is justified when: (a) the task is stable enough that training data will remain relevant, (b) volume is high enough to amortise training cost, and (c) prompting + RAG does not meet latency or cost targets. For most new applications, prompting with a well-chosen model tier and RAG for knowledge gaps reaches acceptable quality faster. See [[model-customization]] for the techniques (LoRA/QLoRA, DPO, distillation) and economics behind this row.

### Batch vs. real-time routing

Not all requests need real-time responses. Async batch APIs (Anthropic Batch API, OpenAI Batch API) offer 50 % cost reduction in exchange for ≤24-hour turnaround. The routing decision adds a third option alongside small-model and frontier-model: is this request latency-sensitive? If not, defer to batch at the cheapest tier.

## Design decisions and trade-offs

**Router model vs. heuristic router.** A trained router (RouteLLM) beats heuristics on accuracy but requires labelled preference data (human or model-generated) and adds an inference call. Heuristic routers (token count, keyword signals, task type tag) are zero-setup but capture less saving. Start with heuristics; invest in a trained router only after the routing decision is demonstrably the cost bottleneck.

**Model-agnostic routing layer vs. provider lock-in.** LiteLLM provides a unified OpenAI-compatible API across providers (Anthropic, OpenAI, Azure, Cohere, Bedrock), enabling transparent provider substitution. The trade-off: the abstraction layer adds a network hop and must track per-provider rate limits and auth. Worthwhile for multi-provider setups; overhead for single-provider.

**Routing transparency.** Users and operators should be able to inspect which model handled a request (for quality debugging and cost attribution). Log the model ID alongside the request ID in every response.

**Quality threshold calibration.** The router's decision depends on what "good enough" means for each task class. Define this threshold with an [[ai-evaluation-and-quality|eval harness]] before deploying a router — otherwise the "easy" bucket will silently accumulate low-quality responses.

## State of the art

**RouteLLM (arXiv:2406.18665, Stanford/LMSYS 2024)** is the canonical reference router. It offers four router types (SW-ranking, matrix factorisation, BERT classifier, LLM judge) and reports 40–50 % GPT-4 call reduction on MMLU with <5 % quality drop on a preference threshold of 0.4.

**FrugalGPT (arXiv:2310.11511, Stanford 2023)** introduced the cascade concept: call the cheapest model; if confidence is below threshold, escalate. At the same accuracy as GPT-4, FrugalGPT reduces API cost by up to 98 % on a mixed-difficulty benchmark.

**LiteLLM** (open source, Python) is the de-facto routing middleware: unified API for 100+ models, fallback chains, load balancing, spend tracking, and a Redis-backed rate-limit cache. Widely deployed as a reverse proxy in front of enterprise LLM traffic.

**Model-specific routing cues (mid-2026):**
- Claude Haiku 4.5 at $0.80/$4: structured extraction, classification, short-form generation
- Claude Sonnet 4.6 at $3/$15: reasoning tasks, code, RAG pipelines — the workhorse tier
- Claude Opus 4.8 at $15/$75 (or $5/$25 for Opus 4.6): open-ended synthesis, novel reasoning, long-document analysis
- GPT-4o-mini: fast, cheap, strong at structured output; competitive with Haiku for JSON extraction
- Gemini 2.5 Pro: best-in-class for million-token context windows; lowest cost at very long context

**Multi-agent routing (arXiv:2502.17392, 2025)** extends the pattern to agent-task assignment: an orchestrator routes sub-tasks to specialised agents rather than models, using the same difficulty/capability heuristics but across an agent registry rather than a model API.

> [!tip]
> The cheapest path: enable prompt caching on your most reused system prompts first (90 % token reduction on the cached prefix). Then segment requests by task type and route the largest easy-task bucket to a small model. Only then invest in a trained difficulty router.

## Pitfalls and anti-patterns

- **Routing all traffic to a single frontier model.** The simplest choice and the most expensive at scale. Even crude heuristic routing typically saves 20–30 %.
- **No fallback chain.** Rate limits and outages are certain at production volume. A single-model dependency turns a provider incident into an application outage.
- **Fine-tuning as the first resort.** Training a fine-tuned model to handle a task that prompting can handle is weeks of work and ongoing cost. Prompting + a well-chosen model tier resolves most capability gaps faster.
- **Routing without quality measurement.** Moving traffic to a cheaper model without an eval gate means quality regressions are invisible until users complain. Always define a quality threshold before deploying a router.
- **Ignoring latency in the routing signal.** A difficulty-based router that sends a complex request to a slow frontier model may miss a latency SLA. Include latency budget as a first-class routing input alongside quality threshold.
- **Prompt caching misses.** Prompt caching requires the cached prefix to be identical character-for-character. Dynamically assembled system prompts that vary per-user break the cache. Separate the stable prefix from the dynamic suffix.

## See also

- [[ai-evaluation-and-quality]] — defining and measuring the quality thresholds the router needs
- [[llm-application-architecture]] — where the router sits in the end-to-end LLM app stack
- [[ai-gpu-economics]] — token pricing tables and self-hosted vs. API cost crossover
- [[context-engineering]] — prompt caching, context budgeting, and window management
- [[retrieval-augmented-generation]] — RAG as the alternative to fine-tuning for knowledge grounding
- [[model-customization]] — fine-tuning, LoRA/QLoRA, DPO, and distillation techniques behind the capability-acquisition decision
- [[small-language-models]] — the small-specialist tier a router sends narrow tasks to
- [[ai-gateway]] — the control-plane component that operationalizes routing, fallback, budgets, and caching for all LLM traffic
- [[agentic-system-design]] — multi-agent task routing

## Sources

- Ong, I. et al. (2024). *RouteLLM: Learning to Route LLMs with Preference Data.* arXiv:2406.18665. https://arxiv.org/abs/2406.18665
- Shnitzer, T. et al. (2023). *Large Language Model Routing with Benchmark Datasets.* arXiv:2309.15789. Stanford University.
- Chen, L. et al. (2023). *FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance.* arXiv:2310.11511. https://arxiv.org/abs/2310.11511
- Hu, S. et al. (2024). *Toward Optimal LLM Cascades.* arXiv:2406.02524. https://arxiv.org/abs/2406.02524
- LiteLLM (2025). *LiteLLM Router — Load Balancing and Fallbacks.* https://docs.litellm.ai/docs/routing
- Zhuge, M. et al. (2025). *Agent-as-a-Judge: Multi-Agent Task Routing.* arXiv:2502.17392. https://arxiv.org/abs/2502.17392
- Anthropic (2026). *Model Pricing — Claude API.* https://www.anthropic.com/pricing
