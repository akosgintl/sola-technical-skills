---
title: Model Customization
aliases: [fine-tuning, fine tuning, LoRA, QLoRA, PEFT, DPO, instruction tuning, model adaptation, distillation, RLHF]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, llm, fine-tuning, lora, peft, dpo, distillation, training]
updated: 2026-06-26
sources:
  - "https://arxiv.org/abs/2106.09685"
  - "https://arxiv.org/abs/2305.14314"
  - "https://arxiv.org/abs/2305.18290"
  - "https://huggingface.co/docs/peft/index"
  - "https://huggingface.co/docs/trl/index"
  - "https://bigdataboutique.com/blog/fine-tuning-llms-when-rag-isnt-enough"
---

# Model Customization

> [!summary]
> Model customization is the family of techniques that change a model's **weights or learned
> behavior** to specialize it for a task — as opposed to [[context-engineering|prompting]] and
> [[retrieval-augmented-generation|RAG]], which leave the weights untouched. It spans full
> fine-tuning, parameter-efficient methods (LoRA/QLoRA), preference optimization (DPO/RLHF),
> reinforcement fine-tuning, and distillation. The governing principle in current practice:
> **fine-tune for *form*, retrieve for *facts*.** Customization shapes tone, format, structured
> output, refusal behavior, and narrow-domain skill; it is the wrong tool for injecting
> knowledge that changes weekly. The senior call is rarely *how* to fine-tune — it is *whether
> to*, given that prompting plus RAG resolves most capability gaps faster and cheaper.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Three levers make a model competent at a task, in increasing cost and commitment:

1. **Prompting** — instructions and few-shot examples in the context window. Weights fixed.
2. **RAG** — inject relevant knowledge at inference time. Weights fixed. See
   [[retrieval-augmented-generation]].
3. **Customization** — *change the model itself* so the behavior is baked in.

The established sequence is **Prompt → RAG → Fine-tune → Distill**: exhaust the cheaper, more
reversible levers before touching weights. Customization is justified when prompting and RAG
leave a durable gap — a format the model won't hold reliably, a tone or policy it keeps
drifting from, a latency/cost target a long few-shot prompt can't meet, or a narrow domain
where a small tuned model beats a large general one.

The decision *between* these levers is owned by [[model-selection-and-routing]]; this page owns
what customization actually *is* and how to do it without setting money on fire.

## Why it matters

For most teams the right answer is **not** to fine-tune — which is exactly why it deserves an
architect's attention. Fine-tuning is the most over-selected technique in the LLM toolkit: it
*feels* like the serious-engineering move, so teams reach for it before exhausting prompting
and RAG, then inherit a training pipeline, a hosting bill, an eval burden, and a maintenance
treadmill (every base-model upgrade invites a re-tune). The value of understanding
customization is largely the judgment to **defer it** — and to recognize the minority of cases
where it genuinely pays:

- **Form and behavior at scale** — a guaranteed output schema, house tone, or refusal policy
  that prompting only approximates. Baking it into weights removes the per-request prompt tax.
- **Cost/latency at high volume** — a small fine-tuned model can match a frontier model on a
  *narrow* task at a fraction of the per-token cost; at millions of requests/day this is the
  difference between viable and unviable [[ai-gpu-economics|unit economics]].
- **Distillation** — compress a frontier model's competence on your task into a small, cheap,
  fast student model you control.
- **Specialized domains** — legal, biomedical, code in a proprietary framework — where the base
  model's prior is thin and examples are too numerous to prompt.

## Key concepts / building blocks

### The adaptation spectrum

| Technique | What it changes | Typical use |
|---|---|---|
| **Continued pre-training** | Broad weights, unsupervised on raw domain corpus | Inject a whole domain/language register; expensive, rare |
| **Supervised fine-tuning (SFT)** | Weights, on labeled input→output pairs | The workhorse: teach a task, format, or style from examples |
| **Preference optimization** (RLHF, **DPO**, ORPO, KTO) | Weights, on *preferred* vs. *rejected* pairs | Align tone, helpfulness, refusal — "make it behave like this, not that" |
| **Reinforcement fine-tuning (RFT)** | Weights, via a verifiable reward signal | Tasks with checkable answers (math, code, structured extraction) |
| **Distillation** | A *new smaller* model's weights | Compress a teacher's task competence into a cheap student |

### Parameter-efficient fine-tuning (PEFT) — the default mechanism

Full fine-tuning updates every weight and needs memory for the whole model plus optimizer
states — expensive and storage-heavy (a full copy per task). **PEFT** freezes the base and
trains a tiny add-on:

- **LoRA** (Low-Rank Adaptation) inserts small low-rank adapter matrices into attention/MLP
  layers and trains only them — roughly **0.1–1% of parameters**, typical ranks 8–64. The
  output is a small adapter (tens of MB) you swap onto the frozen base.
- **QLoRA** quantizes the *base* model to 4-bit while keeping adapters in higher precision,
  making **70B-class fine-tuning viable on a single GPU**. This is the default recipe in 2026:
  QLoRA on a strong open base (Llama / Mistral class) fits on one rented A100-80GB.
- **Adapters are composable and hot-swappable.** One frozen base can serve many task adapters,
  enabling multi-tenant LoRA serving — a key cost/operations advantage over full fine-tunes.

### Preference optimization: DPO as the new default

Classic **RLHF** (SFT → reward model → PPO) is powerful but operationally heavy. **Direct
Preference Optimization (DPO)** collapses it into a single supervised-style loss over
preferred/rejected pairs — simpler, more stable, and competitive in quality. It (and cousins
**ORPO**, **KTO**) has displaced the PPO pipeline for most teams. Reach for full RLHF only when
you need a reusable reward model or online exploration.

### Reinforcement fine-tuning (RFT)

Where a task has a **verifiable reward** (the math answer is right, the code passes tests, the
JSON validates), RFT trains the model against that automated signal rather than human
preferences. Strong for reasoning, code, and tool-use tasks; weak where "good" is subjective.

### Quantization (a deployment lever, not a training one)

Post-training quantization (4-bit/8-bit, GPTQ/AWQ) shrinks a model for cheaper, faster serving
without retraining. It is adjacent to customization (QLoRA uses it during training) but is
really a **serving-cost** decision — trading a little quality for a lot of memory/throughput.
See [[ai-gpu-economics]].

### Form, not facts

The single most useful heuristic: **fine-tune to change how the model behaves; retrieve to
change what it knows.** Knowledge that updates (docs, prices, inventory) belongs in RAG, where
it can change without retraining. Baking facts into weights guarantees they go stale and forces
a re-tune to correct them.

## Design decisions & trade-offs

- **Whether to customize at all.** Default to *no*. Exhaust prompting (and prompt caching) and
  RAG first; they are faster, reversible, and need no training data or hosting. Customize only
  when a measured gap survives both — and you can name *which*: form, cost-at-volume, or narrow
  skill. This is the [[model-selection-and-routing|capability-acquisition decision]].
- **Open-weight vs. hosted fine-tuning vs. frontier.** You can fine-tune **open-weight** models
  (full control, you own serving *and* the [[model-supply-chain-security|weight provenance]]),
  use a **provider fine-tuning API** (managed, but limited to the models and knobs they expose),
  or you **cannot** weight-fine-tune a closed frontier model at all — there you're limited to
  prompting/RAG. Pick the control/effort point you're equipped to operate.
- **LoRA vs. full fine-tune.** LoRA/QLoRA wins almost always: ~99% cheaper, small swappable
  adapters, multi-tenant serving, and *less* catastrophic forgetting because the base is frozen.
  Full fine-tuning is reserved for deep behavioral change or continued pre-training.
- **Data quality over quantity.** A few thousand clean, representative, correctly-formatted
  examples beat a noisy large set. Curation and a held-out eval set are the real work; the
  training run is the easy part.
- **Eval-gate everything.** Without a task [[ai-evaluation-and-quality|eval harness]], you
  cannot tell whether a fine-tune helped, overfit, or regressed general ability. Measure against
  the *un-tuned* baseline (prompt+RAG) — sometimes the baseline wins.
- **Account for the maintenance treadmill.** A fine-tune is pinned to a base model. When a
  materially better base ships, your adapter may be obsolete and the cheapest path is to re-tune
  — or to discover prompting the new base now suffices. Budget for this; don't treat a fine-tune
  as a one-time cost.

## State of the art

- **The default recipe** is QLoRA on a strong open base, trained with the **Hugging Face PEFT +
  TRL** stack (SFT, DPO, ORPO, KTO loops), often accelerated by **Unsloth** or configured via
  **Axolotl**. A typical run produces a ~tens-of-MB adapter in hours on a single rented GPU.
- **DPO is the de-facto preference method**, having largely replaced the SFT→reward-model→PPO
  pipeline for teams that don't need a standalone reward model.
- **RFT / verifiable-reward training** is the fastest-rising area, popularized for math/code and
  now appearing in provider fine-tuning offerings — riding the same reasoning-model wave as
  [[agentic-loop|test-time compute]].
- **Distillation into small task models** is a mainstream cost play: use a frontier model to
  generate/label data, then distill into a small student you host cheaply. Pairs with
  [[model-selection-and-routing|routing]] (the student handles the easy bucket).
- **Model merging** (e.g. MergeKit-style weight averaging / task-vector arithmetic) lets teams
  combine several fine-tunes without retraining — useful but still empirical.
- **Multi-adapter serving** (serving many LoRA adapters over one base) is increasingly
  supported by inference servers, making per-customer or per-task fine-tunes operationally cheap.

## Pitfalls & anti-patterns

- **Fine-tuning to inject knowledge.** The most common mistake. Facts belong in
  [[retrieval-augmented-generation|RAG]]; weights make them stale and un-updatable.
- **Reaching for fine-tuning first.** Skipping prompting + RAG straight to a training pipeline —
  weeks of work and ongoing cost to solve what a better prompt or a small RAG index would.
- **Training on thin or dirty data.** Small, unrepresentative, or inconsistently-formatted sets
  overfit and teach the wrong pattern. Garbage in, confidently-wrong out.
- **No baseline and no eval gate.** Shipping a fine-tune without comparing it to prompt+RAG and
  measuring on a held-out set — you can't prove it helped, and may have regressed general ability.
- **Catastrophic forgetting.** Aggressive full fine-tuning on a narrow set can erode the model's
  general competence. PEFT mitigates this; a held-out general-capability eval catches it.
- **Ignoring the base-model treadmill.** Treating a fine-tune as done forever. Base upgrades can
  obsolete it — or make plain prompting good enough.
- **Forgetting the supply chain.** A fine-tuned weight artifact is a security and provenance
  surface like any other model. See [[model-supply-chain-security]].

## See also

- [[model-selection-and-routing]]
- [[retrieval-augmented-generation]]
- [[context-engineering]]
- [[llm-application-architecture]]
- [[ai-gpu-economics]]
- [[ai-evaluation-and-quality]]
- [[model-supply-chain-security]]

## Sources

- [Hu, E. et al. (2021). LoRA: Low-Rank Adaptation of Large Language Models. arXiv:2106.09685](https://arxiv.org/abs/2106.09685)
- [Dettmers, T. et al. (2023). QLoRA: Efficient Finetuning of Quantized LLMs. arXiv:2305.14314](https://arxiv.org/abs/2305.14314)
- [Rafailov, R. et al. (2023). Direct Preference Optimization. arXiv:2305.18290](https://arxiv.org/abs/2305.18290)
- [Hugging Face — PEFT documentation](https://huggingface.co/docs/peft/index)
- [Hugging Face — TRL (SFT, DPO, ORPO, KTO)](https://huggingface.co/docs/trl/index)
- [BigData Boutique — Fine-Tuning LLMs in 2026: When RAG Isn't Enough](https://bigdataboutique.com/blog/fine-tuning-llms-when-rag-isnt-enough)
