---
title: Guardrails and Output Validation
aliases: [guardrails, output validation, safety filters, LLM guardrails]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, guardrails, safety, validation, security]
updated: 2026-06-21
sources:
  - https://docs.nvidia.com/nemo/guardrails/latest/about/overview.html
  - https://github.com/guardrails-ai/guardrails
  - https://guardrailsai.com/blog/nemoguardrails-integration
  - https://developer.nvidia.com/blog/stream-smarter-and-safer-learn-how-nvidia-nemo-guardrails-enhance-llm-output-streaming/
  - https://abacktools.com/blog/guardrails-ai-structured-output-validation-json-schema
  - https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/
---

# Guardrails and Output Validation

> [!summary]
> Deterministic safety layers wrapped around a probabilistic LLM: input rails screen for injected or disallowed content before the model sees it; output rails enforce schemas, redact PII, detect hallucinations, and validate policy compliance before the result reaches a user or downstream system. Together they convert an unpredictable model into a component with enforceable boundaries.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

Language models are probabilistic — they produce plausible-sounding text, not guaranteed-correct structured data. Guardrails are the deterministic wrapper layer that imposes predictability. They operate at two points in the LLM pipeline:

- **Input rails:** Inspect what enters the model — screen for [[prompt-injection|prompt injection]], off-topic requests, PII, jailbreak patterns, and disallowed content before the LLM processes anything.
- **Output rails:** Inspect what the model produces — enforce JSON/Pydantic schema conformance, strip sensitive data, run fact-checking and hallucination detection, block disallowed content categories, and gate tool calls before they execute.

For agentic systems, a third category matters: **execution rails** that intercept tool invocations and validate inputs and outputs before and after each tool call in an agent loop.

## Why it matters

Without guardrails, an LLM system has a probabilistic failure mode at every step: wrong JSON schema breaks a downstream API; leaked PII creates a compliance breach; a hallucinated citation undermines trust; an injected instruction redirects an agent to an attacker's goal. These failures compound in multi-step agentic workflows — an error in step 2 of 10 propagates through eight more actions before anything surfaces.

Guardrails are the mechanism that makes the gap between "the model usually behaves" and "the system always behaves within spec" narrow enough to operate at production scale. They are also the practical complement to [[ai-specific-security|AI-specific security]] controls: where security focuses on adversarial inputs, guardrails focus on structural correctness and policy compliance across all inputs.

## Key concepts

### The five NeMo rail types

NVIDIA NeMo Guardrails (open source, 2023+) is the most widely deployed guardrail framework, using a custom DSL called Colang to define rails:

| Rail type | Stage | Responsibility |
|---|---|---|
| Input rails | Pre-LLM | Screen user messages for injections, off-topic requests, disallowed content |
| Dialog rails | Conversation flow | Enforce allowed conversation patterns; block forbidden topics |
| Retrieval rails | Pre-retrieval | Filter knowledge base queries; prevent poisoned retrieval |
| Execution rails | Tool call boundary | Validate tool inputs before invocation; validate tool outputs before use |
| Output rails | Post-LLM | Schema check, PII redaction, fact-check, content policy, quality gate |

Each rail type can invoke a secondary LLM call (for semantic checks) or a deterministic function (for schema validation, regex redaction). Execution rails are the critical addition for agentic use — they make tool calls auditable and constrained.

### Guardrails AI — validator-based output enforcement

Guardrails AI (open source, Python) takes a different approach: validators are composable Python functions that assert properties on LLM output, attached to a `Guard` object wrapping an LLM call.

```python
guard = Guard.from_pydantic(output_class=MySchema)
validated = guard(llm_api=openai.completions.create, prompt=...)
```

When the model returns non-conforming output, the Guard automatically retries (up to a configurable limit). Built-in validators cover: schema conformance, PII detection (via Microsoft Presidio), profanity, competitor mentions, URL validity, SQL injection, regex patterns, and more. Custom validators are single Python functions.

Two structured-output mechanisms: **function calling** for models that support it (schema embedded in the tool spec); **prompt optimization** for models that don't (schema injected into the system prompt).

### Defense-in-depth guardrail architecture

Guardrails are most effective as layered, not single-point, defenses:

```
User input
  → [1] Input validation  (injection scan, PII check, topic filter)
  → [2] Prompt hardening  (structured prompt template, context isolation)
  → [3] LLM call
  → [4] Retrieval rails   (if RAG: filter retrieved docs before injecting)
  → [5] Output validation (schema, PII redaction, hallucination check)
  → [6] Execution rails   (if tool use: validate tool args + tool output)
  → [7] Action gate       (HITL for high-risk tool executions)
  → Downstream system
```

No single layer is comprehensive — attackers who get through input validation can still succeed at the prompt hardening layer, and vice versa. Treating guardrails as one check (not a pipeline) is the primary failure mode.

### Structured output enforcement

Structured output is the most universally applicable guardrail: instead of hoping the model produces valid JSON, force it to. Three mechanisms in 2026:

- **Native JSON mode / tool-use schema** (OpenAI, Anthropic, Google): model is constrained to output valid JSON matching a schema; fastest, lowest latency.
- **Pydantic + Instructor library**: the model's output is parsed against a Pydantic model; invalid fields trigger automatic retry with the validation error fed back as a correction prompt.
- **Guardrails AI Guard**: schema + validators as a wrapper; retry logic built in.

For complex schemas, Pydantic + Instructor is the most ergonomic; for simple JSON, native schema enforcement has the lowest overhead.

## Design decisions & trade-offs

**Latency cost of semantic rails.** Deterministic rails (schema validation, regex, PII scanners) add milliseconds. Semantic rails that call a secondary LLM (topic classifiers, hallucination detectors, fact-checkers) add 200–800 ms per call. For latency-sensitive paths, restrict semantic rails to output-only (not on every token during streaming), or run them asynchronously and block on the result only before tool execution.

**Streaming compatibility.** Output rails traditionally operate on the complete response. NeMo Guardrails (as of 2025) added output streaming support — rails are applied to chunks as they arrive, enabling content filtering without waiting for the full response. This reduces time-to-first-validated-token but complicates stateful validators (like hallucination checks that need the full answer).

**Rail coverage vs. maintenance burden.** Every validator is a policy claim that must be maintained. Validators that are too aggressive produce false positives (blocking legitimate outputs); validators that are too permissive give a false sense of safety. Start with structural validators (schema, PII), prove their accuracy, then add semantic validators incrementally.

**Probabilistic defenses are not guarantees.** LLM-based safety classifiers are themselves probabilistic. An attacker who knows the classifier model can craft inputs that evade it. Guardrails reduce the attack surface and raise the cost of attack; they do not eliminate it. Pair with [[human-in-the-loop-design|HITL gates]] for actions where the consequence of a missed detection is high.

## State of the art

**NVIDIA NeMo Guardrails** is the most feature-complete open-source framework as of 2026, with five rail types, streaming support, Colang DSL for declarative rail definitions, and integration with LangChain, LlamaIndex, and direct OpenAI/Anthropic calls. Red Hat OpenShift AI ships a managed NeMo deployment path.

**Guardrails AI** (open source, PyPI: `guardrails-ai`) is the most ecosystem-compatible Python framework, with a hub of 40+ pre-built validators, Pydantic schema enforcement, and structured retry logic. It integrates with any LLM API.

**Microsoft Agent Governance Toolkit** (April 2026, MIT license) adds a **semantic intent classifier** as an input rail specifically for agentic use cases — identifying goal hijacking (OWASP Agentic Top 10 risk #1) and tool misuse attempts before they reach the agent loop.

**Anthropic's Constitutional AI and model-level safety** (as of Claude 3.x+) provides a baseline of model-level safety that reduces — but does not eliminate — the need for application-layer guardrails. Model-level safety is not programmable; application guardrails are. Both are necessary.

Most production LLM systems in 2026 use at minimum: native structured output (schema enforcement) + a PII scanner + a prompt injection detector on user inputs. Full five-layer defense-in-depth is standard for regulated domains and agentic systems with tool-use capabilities.

## Pitfalls & anti-patterns

- **Single-point guardrail.** One check at the input or output stage, treating it as sufficient. Guardrails only work as a pipeline — each layer catches what the previous missed.
- **Semantic-only validation.** Using an LLM to check an LLM creates circular failure modes. Pair semantic validators with deterministic ones (schema, regex, known-list checks).
- **Ignoring retrieval rails.** In RAG pipelines, the retrieval step is the largest injection surface. Guardrails that skip retrieval-stage filtering are incomplete.
- **Treating guardrails as a deployment gate.** Running safety checks once at launch, then not monitoring in production. Model behaviour drifts; inputs change; rails need continuous monitoring.
- **No retry logic for structured output.** Accepting the first LLM response even if it fails schema validation, rather than re-prompting with the validation error.
- **Over-reliance on guardrails for security.** Guardrails reduce risk; they don't replace [[prompt-injection|prompt injection]] defenses, [[iam-and-secrets-management|least-privilege access]], or [[human-in-the-loop-design|HITL gates]] for high-impact actions.

## See also

- [[prompt-injection]]
- [[ai-specific-security]]
- [[human-in-the-loop-design]]
- [[llm-application-architecture]]
- [[ai-evaluation-and-quality]]
- [[agent-governance-and-policy]]

## Sources

- NVIDIA NeMo Guardrails — Overview: https://docs.nvidia.com/nemo/guardrails/latest/about/overview.html
- NVIDIA Technical Blog — NeMo Guardrails Output Streaming: https://developer.nvidia.com/blog/stream-smarter-and-safer-learn-how-nvidia-nemo-guardrails-enhance-llm-output-streaming/
- Guardrails AI GitHub: https://github.com/guardrails-ai/guardrails
- Guardrails AI — NeMo Integration: https://guardrailsai.com/blog/nemoguardrails-integration
- Aback Tools — Guardrails AI Structured Output Validation with JSON Schema: https://abacktools.com/blog/guardrails-ai-structured-output-validation-json-schema
- Microsoft Agent Governance Toolkit (April 2026): https://opensource.microsoft.com/blog/2026/04/02/introducing-the-agent-governance-toolkit-open-source-runtime-security-for-ai-agents/
