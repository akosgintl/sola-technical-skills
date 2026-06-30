---
title: LLM Structured Outputs
aliases: [structured outputs, LLM output schemas, structured LLM responses, typed LLM outputs]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, llm, structured-outputs, pydantic, json-schema, validation, production]
updated: 2026-06-23
sources:
  - raw/2026-06-23-decodingai-03-llm-structured-outputs.md
  - raw/2026-06-23-decodingai-07-react-agents.md
  - "https://www.decodingai.com/p/llm-structured-outputs-the-only-way"
  - "https://www.decodingai.com/p/building-production-react-agents"
  - "https://docs.pydantic.dev/latest/"
  - "https://ai.google.dev/gemini-api/docs/structured-output"
---

# LLM Structured Outputs

> [!summary]
> Structured outputs enforce a schema on LLM responses, converting probabilistic text into typed, validated data structures. They are the boundary layer between a non-deterministic model and deterministic downstream code — the difference between a system that occasionally fails because "regex patterns didn't match" and one where invalid output is caught immediately at the output boundary, before it can corrupt downstream state.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

LLM responses are inherently free-text — the model produces tokens that look like the desired format but are not guaranteed to conform to it. Structured outputs impose a formal schema on that output, ensuring the response is parseable as a typed object before any downstream code touches it.

The framing from Paul Iusztin's "AI Agents Foundations" series is precise: structured outputs are "a bridge between LLM (Software 3.0) and Python (Software 1.0)" — the contract at the boundary between probabilistic generation and deterministic computation. Without this bridge, any change in the model's phrasing, any hallucinated field, or any missing key propagates silently through the pipeline and surfaces as a runtime exception or corrupted output far from its source.

![[2026-06-23-decodingai-03-llm-structured-outputs-01.png|Structured outputs bridging the LLM and downstream code]]
*Figure: Structured outputs as the bridge between probabilistic LLM generation and deterministic downstream code — source [[2026-06-23-decodingai-03-llm-structured-outputs]].*

The canonical failure mode: a production demo crashes because regex parsing fails on a slightly different response format than the model was trained to produce. Data types become inconsistent. Downstream processes can't handle the unpredictable structure. This is solved by schema enforcement at the output boundary, not by more careful prompting.

## Why it matters

**Programmability.** A validated Pydantic object is a first-class Python value — indexable, iterable, type-checked, and introspectable. Raw text is not. Structured outputs are what make LLM responses composable with the rest of a codebase.

**Type safety.** Validation fires immediately on malformed output — fail-fast rather than fail-later. A binary score expressed as `Annotated[int, Ge(0), Le(1)]` cannot be returned as 1.5, "yes", or None. The constraint is expressed once and enforced on every response.

**Orchestration reliability.** In [[agentic-system-design|workflow patterns]], each step's output is the next step's input. If that output lacks a required field or has an unexpected type, the pipeline halts mid-run. Structured outputs make the data contract explicit and testable — the same way function signatures make API contracts explicit.

**Cost reduction.** When the LLM is constrained to generate only the structured fields, it emits fewer tokens than it would in a free-form response that includes explanation, caveats, and formatting. For high-volume pipelines, this is a measurable FinOps win.

**LLM-as-judge workflows.** Evaluation pipelines (assessing generated content against criteria) are among the highest-value structured output use cases. A `CriterionScore` with a binary score and a reason field is the canonical shape: the score is machine-processable for aggregation; the reason is human-readable for debugging.

## Key concepts / building blocks

### Three implementation tiers

**Tier 1 — Manual JSON prompting.** Craft a prompt that includes an example JSON structure (often wrapped in XML tags like `<document>`). Parse the response by stripping Markdown code blocks and calling `json.loads`. No validation. Any deviation from the expected format produces an unhandled exception or silent corruption. This tier is the starting point for understanding, not the endpoint for production.

**Tier 2 — Pydantic schema generation.** Define a Pydantic `BaseModel` subclass with typed fields and constraints. Pydantic generates the JSON Schema automatically via `.model_json_schema()`. Inject this schema into the prompt so the model knows the exact contract. The model returns JSON; parse it with `model.model_validate_json(response_text)`. Validation fires on malformed output immediately.

```python
class CriterionScore(pydantic.BaseModel):
    criterion: Literal["revenue_forecast", "user_growth", "facts"]
    score: Annotated[int, Ge(0), Le(1)]
    reason: str
```

Nested models, optional fields, and discriminated unions are all expressible. The JSON Schema the model receives includes the constraints — so the model has an explicit spec, not just an example.

**Tier 3 — Native API structured output.** Modern provider APIs (Gemini, OpenAI) accept the Pydantic class directly as a schema parameter. The vendor handles schema injection, response formatting, and parsing. The response arrives already deserialized into the Pydantic object.

```python
config = types.GenerateContentConfig(
    response_mime_type="application/json",
    response_schema=Scores
)
```

This eliminates manual schema injection, reduces prompt complexity, and is optimized by the vendor for accuracy. The result is more reliable than Tier 2 and substantially simpler than Tier 1.

### Structured output strategies in agentic loops

In a [[agentic-loop|ReAct agent loop]], structured outputs surface at the final step — the agent reasons and acts with flexible tool calls during the loop, then generates a typed final answer when done. Two strategies:

**ToolStrategy (flexible)** — The Pydantic schema is registered as a special "tool." When the agent is ready to terminate, it "calls" this tool with the final data as arguments. The framework intercepts the call, parses the arguments into the model, stores the result in `structured_response` state, and routes to END. Works with any tool-calling model.

**ProviderStrategy (native)** — Uses the provider's JSON mode directly. More reliable with supported models; removes the extra tool-call indirection. Trades portability for accuracy.

Key principle: structured outputs should be generated only at the final step, not during reasoning. Constraining intermediate reasoning to a fixed schema reduces the agent's flexibility during the decision phase.

## Design decisions & trade-offs

**Pydantic vs. native API:** Pydantic Tier 2 is portable across any API that accepts prompt text; Tier 3 native is simpler and more accurate but couples you to the specific provider. For production systems at volume, native API is preferred. For abstracted multi-provider systems, Tier 2 provides the portability layer.

**Strict vs. lenient schemas:** Narrow schemas (few fields, strict types) reduce hallucination surface and output tokens. Wide schemas (many optional fields) give flexibility but increase the chance the model fills optional fields with plausible-sounding nonsense. Design schemas around what code actually consumes, not what would be nice to have.

**Retry on validation failure:** Pydantic validation failure is a signal the model misunderstood the schema. The right response is usually a retry with the error message appended ("your previous response failed validation because: ..."). Libraries like Instructor automate this retry loop. Cap retries at 2–3 to avoid runaway cost.

**Schema in prompt vs. schema injection:** Injecting the full JSON Schema into the prompt is verbose but explicit. The native API approach removes this overhead. For Tier 2 implementations, prefer injecting a minimal description plus a concrete example over dumping the full JSON Schema.

## State of the art

Native structured output support is now standard across all major provider APIs. Gemini 2.5 Flash/Pro, GPT-4o, and Claude 3.x all support schema-constrained generation through their configuration APIs. The provider-native approach is the current recommended path for new production systems.

Instructor (Python library) wraps any provider API and adds automatic retry-on-failure for structured output — a lightweight alternative to building custom retry logic on top of Pydantic. It has become a popular middle layer between Tier 2 and Tier 3.

For [[ai-evaluation-and-quality|LLM-as-judge evaluation pipelines]], structured outputs are now the default pattern: a typed score + reason schema is both machine-processable and human-auditable, closing the loop between automated evaluation and debugging.

## Pitfalls & anti-patterns

**Regex parsing as the output boundary.** Regex fails silently on format variants the model produces. The entire point of structured outputs is to replace regex with schema validation. If you're still using regex to parse LLM output, you're one model update away from a production failure.

**Wide schemas as a catch-all.** A schema with 20 optional fields doesn't enforce a contract — it just documents what the model might return. Keep schemas narrow; add fields only when downstream code actually uses them.

**Constraining reasoning steps.** Requiring structured output on every intermediate reasoning step prevents the model from using natural language chain-of-thought. Apply schema constraints at the output boundary only.

**No retry on validation failure.** A single validation failure treated as a hard error discards a response that might be recoverable with a corrective re-prompt. Always retry once with the validation error message before failing the call.

**Over-reliance for security.** Structured output validates shape and type — not semantic correctness. A structured response can have all the right fields and still contain hallucinated content. Pair with [[guardrails-and-output-validation|content guardrails]] for safety-critical applications.

## See also

- [[guardrails-and-output-validation]]
- [[llm-tool-use]]
- [[agentic-system-design]]
- [[agentic-loop]]
- [[agent-planning]]
- [[ai-evaluation-and-quality]]
- [[llm-application-architecture]]

## Sources

- Iusztin, P. (Decoding AI). LLM Structured Outputs: The Silent Hero of Production AI. https://www.decodingai.com/p/llm-structured-outputs-the-only-way
- Iusztin, P. (Decoding AI). Building Production ReAct Agents From Scratch. https://www.decodingai.com/p/building-production-react-agents
- Pydantic. (2024). Pydantic v2 Documentation. https://docs.pydantic.dev/latest/
- Google. (2026). Gemini API — Structured Output. https://ai.google.dev/gemini-api/docs/structured-output
- OpenAI. (2024). Structured Outputs. https://platform.openai.com/docs/guides/structured-outputs
- raw/2026-06-23-decodingai-03-llm-structured-outputs.md
- raw/2026-06-23-decodingai-07-react-agents.md
