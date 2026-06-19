---
title: AI / Agent Observability
aliases: [agent observability, LLM observability, agentic observability, GenAI observability]
type: concept
domain: observability
status: mature
tags: [observability, ai-agentic, llm, tracing, opentelemetry, evals, reliability]
updated: 2026-06-19
sources:
  - https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/
  - https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/
  - https://www.braintrust.dev/articles/agent-observability-complete-guide-2026
  - https://latitude.so/blog/ai-agent-failure-detection-guide
  - https://www.langchain.com/resources/agent-observability
  - https://mlflow.org/articles/what-is-agent-observability-a-2026-developer-guide/
  - https://www.datadoghq.com/blog/llm-otel-semantic-convention/
---

# AI / Agent Observability

> [!summary]
> AI/agent observability is the practice of instrumenting LLM-driven and agentic systems so you can see *why* they did what they did — capturing the full reasoning chain as hierarchical, causally-linked traces (prompts, tool calls, retrievals, tokens, cost, latency) and continuously *judging the quality* of outputs in production, not just their availability. It exists because agents fail in ways classic [[observability-fundamentals|metrics/logs/traces]] never anticipated: the service is "up", every span is HTTP 200, and the answer is still wrong, looping, or drifting. The current stack standardizes on **OpenTelemetry GenAI semantic conventions** for the traces and layers **online evaluation / LLM-as-judge** scoring on top.

**Domain:** [[tier-2-solid|Observability & Reliability]]

## What it is

Classic observability answers *"is the system healthy and fast?"* with the three pillars: metrics, logs, traces, plus SLOs/SLIs. Agent observability keeps all of that and adds a fourth question that has no analogue in deterministic systems: ***"was the output correct and well-reasoned?"***

The unit of analysis shifts from the request to the **trajectory** — the ordered sequence of LLM calls, tool invocations, retrievals, planning steps, and hand-offs an agent executes to reach an outcome. A single user turn can fan out into dozens of spans across multiple models and tools. The job of agent observability is to:

1. **Trace the decision path** — capture every step as a nested span with its inputs, outputs, model, prompt, tokens, cost, and latency, so the full reasoning chain is reconstructable and replayable.
2. **Surface non-deterministic failure modes** — the same input can succeed once and fail the next, so you instrument for *behavioral* failures (wrong tool, infinite loop, hallucinated grounding, context decay) that emit no error and break no health check.
3. **Monitor quality and drift in production** — run evaluators (often an LLM judge) continuously over sampled live traffic to detect regression *as it happens*, not in a post-mortem.

## Why it matters

The exposure here is asymmetric. A latency regression is annoying; an agent that confidently approves the wrong refund, leaks data through an injected instruction, or silently degrades after a model-provider update is a business and compliance incident. The failure modes triaged most often are **cascading errors in multi-step agents, indirect prompt injection through retrieved content, and observability gaps that hide failures until they become incidents** ([Latitude](https://latitude.so/blog/ai-agent-failure-detection-guide)).

Three things make this a P0 you must *own*, not delegate:

- **Your existing monitoring is structurally blind to it.** APM tooling correlates errors and latency; it has no concept of "the answer was wrong" or "step 7 failed because step 3's output was corrupted." Causal dependencies between steps are invisible to event-per-tool logging — you get independent log lines and must reconstruct the chain by hand ([Latitude](https://latitude.so/blog/ai-agent-failure-detection-guide)).
- **Quality is a runtime property, not a release-time one.** Because behavior depends on a non-deterministic model, a frozen prompt, and shifting retrieved context, you cannot certify quality once at deploy and forget it. This is the operational counterpart to [[ai-evaluation-and-quality]]: offline evals gate releases; *online* evals watch production.
- **It is the evidence layer for governance.** [[agent-governance-and-policy]] and [[accountable-human-layer|accountable-human]] sign-off both require an audit trail of what the agent saw, decided, and acted on. The trace *is* that record.

## Key concepts / building blocks

- **Trace / trajectory / span hierarchy.** A trace is one end-to-end task; spans nest to show agent → sub-agent → tool → LLM call. Hierarchical, causally-linked spans let you replay and root-cause across non-deterministic workflows ([Latitude](https://latitude.so/blog/ai-agent-failure-detection-guide)).
- **OpenTelemetry GenAI semantic conventions.** The emerging standard (`gen_ai.*` attributes) for naming LLM and agent telemetry so it is portable across backends. Operation names include `chat`, `invoke_agent`, `execute_tool`, and `embeddings`; attributes carry the model (`gen_ai.request.model`), provider (`gen_ai.provider.name`), agent/tool name, and token usage (`gen_ai.usage.input_tokens` / `output_tokens`, including cached tokens) ([OTel spec](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/), [Datadog](https://www.datadoghq.com/blog/llm-otel-semantic-convention/)). As of early 2026 **client spans have exited experimental; agent and framework spans remain experimental but stable in practice**, covering four areas: client spans, agent spans, events (prompt/completion content), and metrics.
- **Token, cost & latency telemetry.** First-class span attributes — input/output/cached tokens, computed cost, time-to-first-token, tool latency — feed both reliability dashboards and [[ai-gpu-economics|token-economics]]/[[cloud-cost-modeling|cost]] showback.
- **Online (production) evals.** Inline scorers and LLM-as-judge checks run on live (sampled) traces so quality regressions surface as they happen; failing traces are auto-promoted into the offline eval suite, so the suite grows from real user behavior ([Braintrust](https://www.braintrust.dev/articles/agent-observability-complete-guide-2026)).
- **LLM-as-judge.** A model scores nuanced, non-programmatic qualities — goal completion, faithfulness, tone, helpfulness. Pair it with **code-based / deterministic checks** for objective criteria (schema valid, tool succeeded). Judges must be aligned to human labels and versioned, or they drift too.
- **Agent-specific signals.** Tool-call correctness, task/goal completion, trajectory efficiency (steps vs. optimal), and **reasoning-drift detection** — e.g. comparing step-1 reasoning to final-step reasoning: if the final step no longer references the original goal, the agent has likely drifted ([Latitude](https://latitude.so/blog/ai-agent-failure-detection-guide)).
- **Drift monitoring.** Watch for input drift (changing user/query distribution), output-quality drift (judge scores trending down), and **silent provider drift** (a model endpoint updated under you). "Set-and-forget" deployment is itself a named failure mode.

## Design decisions & trade-offs

- **OTel-native vs. SDK-native instrumentation.** Emitting OTel GenAI spans keeps you portable and lets agent telemetry flow into the *same* backend as the rest of your distributed system — a real win for correlation and for not running a second observability silo. SDK-native auto-instrumentation (e.g. one env var for a LangChain/LangGraph stack) is faster to working traces but carries lock-in. The key call: **standardize on OTel semantic conventions at the wire level** even when using a vendor SDK, so you can swap the backend later. Phoenix, Langfuse, and (since March 2026) LangSmith all speak OTel.
- **Sampling vs. completeness.** Full-fidelity tracing of every prompt and completion is expensive (storage, and judge-token cost) and a data-governance liability — prompts and completions can contain PII. Decide what to capture (metadata always; content sampled or redacted), and sample online evals over a subset of traffic as an early-warning system rather than scoring 100%.
- **Judge cost and trust.** LLM-as-judge adds inference cost and is itself non-deterministic. Reserve judges for the subjective dimensions; use cheap deterministic checks everywhere possible; calibrate judges against human-labeled sets and treat the judge as a versioned artifact under [[ai-evaluation-and-quality]].
- **Build vs. buy vs. self-host.** Managed (LangSmith, Braintrust, Arize) gets you there fastest; self-hostable open source (Langfuse — MIT, Postgres+ClickHouse; Phoenix — OTel-native, open source) wins where **data sovereignty** and cost discipline dominate. Map this to your compliance posture, not to feature checklists.
- **Observability vs. guardrails — different jobs.** Observability *detects* and explains; [[guardrails-and-output-validation|guardrails]] *prevent* at runtime. You need both: a guardrail blocks the bad output; the trace tells you why the agent tried it. Don't conflate the dashboard with the control.

## State of the art

- **The standard:** OpenTelemetry GenAI semantic conventions, driven by the GenAI SIG since 2024. Client spans are stable; agent/framework spans experimental-but-stable. Datadog, Honeycomb, and New Relic ingest them natively; LangChain, CrewAI, AutoGen/AG2 emit them ([OTel agent spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/)).
- **Tooling landscape:**
  - **Langfuse** — MIT, self-hostable, framework-agnostic via OTel; default where data sovereignty and cost matter.
  - **LangSmith** — fastest path for LangChain/LangGraph stacks; added OTel support March 2026; highest lock-in.
  - **Arize Phoenix** — open-source, OTel-native; strong eval-metrics library; best for OTel-native infra without lock-in.
  - **Braintrust** — eval-first workflow tying online scoring back into datasets.
  - **OpenLLMetry (Traceloop)** — OTel instrumentation layer that emits GenAI spans into *any* OTel backend.
  - **MLflow 3** — production-grade evaluation with built-in judges, multi-turn eval, and integration with RAGAS/DeepEval/Phoenix/TruLens ([MLflow](https://mlflow.org/articles/what-is-agent-observability-a-2026-developer-guide/)).
- **The dominant pattern:** *span-per-tick tracing from day one* + *continuous LLM-as-judge over sampled production traces* + a feedback loop that converts failing production traces into eval cases ([Braintrust](https://www.braintrust.dev/articles/agent-observability-complete-guide-2026), [LangChain](https://www.langchain.com/resources/agent-observability)). Trace-based evaluation — scoring the *trajectory*, not just the final answer — is now standard for tool-calling and task-completion metrics.

## How it differs from classic observability

| Classic ([[observability-fundamentals]]) | AI / agent observability |
|---|---|
| Question: is it up and fast? | Adds: was the output *correct and well-reasoned*? |
| Unit: request / transaction | Unit: trajectory (multi-step reasoning chain) |
| Failure = error code, exception, latency breach | Failure = wrong tool, loop, hallucination, drift — often HTTP 200 |
| Deterministic; reproduce by replaying input | Non-deterministic; same input may pass then fail |
| Signals: metrics, logs, traces | Adds: token/cost spans, eval scores, judge verdicts |
| Validate quality at release | Validate quality *continuously in production* |
| Alerts on thresholds | Alerts on threshold *and* on quality/drift regression |

It is an **extension**, not a replacement — built on the same OTel trace primitives and the same SLO discipline from [[distributed-systems-reliability]], with quality elevated to a first-class, monitored signal.

## Pitfalls & anti-patterns

- **Treating "200 OK" as success.** The single biggest gap: health checks are green while answers are wrong. Always pair availability with a quality signal.
- **Logging tool calls as independent events.** Without a parent trace and causal links you cannot find that step 7 failed because of step 3 — manual correlation that doesn't scale.
- **Set-and-forget deployment.** No drift monitoring means a silent provider model update or shifting input distribution degrades you invisibly. Continuous online eval is the mitigation.
- **Trusting an uncalibrated judge.** An LLM-as-judge not aligned to human labels (and not versioned) gives false confidence; judge it before you trust it.
- **Capturing raw prompts/completions everywhere.** PII and cost blow-up; redact, sample, and govern trace content as sensitive data.
- **Running a separate AI observability silo.** Emit OTel and unify with system telemetry, or you lose end-to-end correlation across the app the agent lives in.
- **Eval-only or trace-only.** Traces without scores explain failures you didn't catch; scores without traces flag failures you can't diagnose. You need both, joined.

## See also

- [[observability-fundamentals]]
- [[ai-evaluation-and-quality]]
- [[distributed-systems-reliability]]
- [[agentic-system-design]]
- [[guardrails-and-output-validation]]
- [[ai-gpu-economics]]
- [[agent-governance-and-policy]]
- [[multi-agent-orchestration]]

## Sources

- [OpenTelemetry — Semantic conventions for GenAI agent and framework spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-agent-spans/)
- [OpenTelemetry — Semantic conventions for generative client AI spans](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/)
- [Braintrust — Agent observability: the complete guide for 2026](https://www.braintrust.dev/articles/agent-observability-complete-guide-2026)
- [Latitude — Detecting AI agent failure modes in production](https://latitude.so/blog/ai-agent-failure-detection-guide)
- [LangChain — AI agent observability: tracing, testing, and improving agents](https://www.langchain.com/resources/agent-observability)
- [MLflow — What is agent observability? A 2026 developer guide](https://mlflow.org/articles/what-is-agent-observability-a-2026-developer-guide/)
- [Datadog — LLM Observability natively supports OpenTelemetry GenAI semantic conventions](https://www.datadoghq.com/blog/llm-otel-semantic-convention/)
- [Latitude — Best AI agent observability tools 2026 comparison](https://latitude.so/blog/best-ai-agent-observability-tools-2026-comparison)
