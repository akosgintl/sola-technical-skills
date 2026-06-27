---
title: AI Gateway
aliases: [AI gateway, LLM gateway, LLM proxy, model gateway, AI control plane, LiteLLM]
type: concept
domain: ai-agentic
status: mature
tags: [ai-agentic, llm, gateway, routing, cost-governance, observability, guardrails]
updated: 2026-06-27
sources:
  - "https://www.digitalapplied.com/blog/llm-gateway-architecture-2026-engineering-reference"
  - "https://guptadeepak.com/tools/top-5-ai-gateways-2026/"
  - "https://docs.litellm.ai/docs/proxy/quick_start"
  - "https://portkey.ai/"
  - "https://contabo.com/blog/litellm-vs-ai-gateways/"
---

# AI Gateway

> [!summary]
> An AI gateway is the control-plane proxy between your applications/agents and LLM providers — a
> single endpoint that adds multi-provider **routing and fallback**, **caching** (including
> semantic), per-team/per-key **rate limiting and budgets**, **guardrails and PII redaction**,
> **virtual keys / secret vaulting**, and unified **observability** of LLM calls. It is the "API
> gateway for LLM traffic": the place where the cross-cutting concerns of an LLM platform converge so
> they aren't reimplemented (inconsistently) in every application. It is distinct from
> [[model-selection-and-routing]] (the routing *strategy* the gateway *executes*),
> [[model-context-protocol|MCP]] (the tool/data protocol), and general
> [[api-gateways-and-service-mesh|API gateways]] (HTTP traffic, not token- or model-aware).

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

As LLM usage spreads across an organization, every application independently re-solves the same
problems: provider API keys, retries and fallback, cost tracking, caching, guardrails, and logging.
An AI gateway centralizes them behind one (usually OpenAI-compatible) endpoint that fronts many
providers. The distinction worth holding: [[model-selection-and-routing]] is the *strategy* (which
model for which request); the AI gateway is the *infrastructure component* that operationalizes that
strategy alongside governance, cost, caching, and observability for **all** LLM traffic.

## Why it matters

Without a gateway, governance is impossible: spend can't be capped per team, policy can't be enforced
uniformly, and swapping a model means touching every app. The gateway gives an organization three
things at once:

- **Central control & cost visibility** — virtual keys, per-team budgets, real-time spend, quotas —
  the answer to runaway LLM bills (the operational side of [[ai-gpu-economics]]).
- **A provider-abstraction seam** — a unified API across 100+ providers means you can route, fall
  back, and swap models without application changes, reducing lock-in.
- **Consistent policy** — guardrails, PII redaction, and observability applied once, in the path of
  every call, instead of per-app and uneven.

It is, in short, the enterprise **LLM control plane**.

## Key concepts / building blocks

- **Unified API / provider abstraction** — one OpenAI-compatible interface in front of Anthropic,
  OpenAI, Google, Bedrock, self-hosted, etc.; the seam that enables portability.
- **Routing & fallback** — executes the [[model-selection-and-routing]] policy (difficulty cascades,
  capability routing) and fails over on 429/timeout/outage.
- **Cost governance** — virtual keys, per-team/user/key **budgets**, real-time spend tracking, alerts,
  token quotas.
- **Caching** — exact and **semantic** caching at the gateway, so repeated/paraphrased prompts skip
  the model (see [[caching-strategies]]).
- **Guardrails & safety** — centralized input/output filtering, **PII redaction**, and policy
  enforcement (see [[guardrails-and-output-validation]] and [[data-privacy-engineering]]).
- **Observability** — unified logging/tracing/metrics for every call (tokens, latency, cost, model,
  prompt) — feeds [[ai-agent-observability]].
- **Security** — provider keys vaulted in the gateway (apps never hold them); per-tenant rate limiting
  and access control (see [[multi-tenancy-architecture]] and [[api-security]]).

## Design decisions & trade-offs

- **Build vs. buy vs. self-host.** **LiteLLM** is the open-source self-hosted standard (broad provider
  coverage, virtual keys, budgets); **Portkey** is the managed control plane with the strongest
  guardrails/observability; **Cloudflare AI Gateway** is near-zero-ops managed edge caching; **Kong AI
  Gateway** fits enterprises already on Kong (PII redaction, SSO); **Helicone** leads on cost
  visibility. Choose by control vs. ops-overhead and existing platform.
- **Self-hosted vs. managed.** Self-hosting keeps data and keys in your boundary (residency,
  [[data-privacy-engineering|privacy]]) at the cost of running an HA service; managed offloads ops but
  routes your prompts through a vendor.
- **Centralized gateway vs. per-app SDK.** A central gateway gives uniform governance and cost control,
  at the cost of a network hop and a **critical dependency in every LLM call's path** — it must be HA,
  and apps should degrade/bypass if it's down.
- **Reuse the existing API gateway vs. an LLM-specialized one.** A general gateway (Kong/APIM) gives
  one control plane; an LLM-specialized gateway is token-aware, knows the model catalog, and does
  semantic caching and budgets natively.
- **How much to centralize.** Routing and guardrails in the gateway maximize consistency; pushing them
  into apps maximizes flexibility. Bias to the gateway for policy that must be uniform.
- **Latency of the hop vs. the value.** The extra hop adds latency, but caching and fallback usually
  net positive — measure rather than assume.

## State of the art

- **The AI gateway is now a recognized category** with a clear field: **LiteLLM** (OSS standard),
  **Portkey** (managed control plane + guardrails), **Cloudflare AI Gateway** (edge, zero-ops),
  **Kong AI Gateway** (enterprise mesh), **Helicone** (cost observability), **Vercel AI Gateway**.
- **Semantic caching, guardrails, PII redaction, and per-key budgets are standard features**, not
  differentiators.
- **Gateways are extending to agent and MCP traffic** — governing tool calls and multi-step agent runs,
  not just single completions.
- **Cost governance is the dominant adoption driver** as LLM spend becomes a board-level line item.

## Pitfalls & anti-patterns

- **The gateway as an unmonitored single point of failure.** It sits in the path of every LLM call —
  run it HA and give applications a fallback/bypass.
- **Re-implementing per app instead of centralizing.** Inconsistent keys, retries, cost tracking, and
  guardrails — the exact sprawl the gateway exists to remove.
- **No cost governance.** Deploying a gateway but not using budgets/quotas — runaway spend continues.
- **Apps holding provider keys directly.** Defeats the vaulting benefit and scatters secrets.
- **Latency-blind semantic caching.** An over-loose similarity threshold returns "close enough"
  answers that are wrong (see [[caching-strategies]]).
- **Lock-in to proprietary gateway features** that negate the provider-abstraction benefit the gateway
  was adopted for.
- **Treating it as just a proxy.** Skipping the guardrails and observability is leaving most of the
  value on the table.

## See also

- [[model-selection-and-routing]]
- [[llm-application-architecture]]
- [[model-context-protocol]]
- [[guardrails-and-output-validation]]
- [[ai-gpu-economics]]
- [[caching-strategies]]
- [[ai-agent-observability]]
- [[api-gateways-and-service-mesh]]

## Sources

- [Digital Applied — LLM Gateway Architecture: 2026 Engineering Reference](https://www.digitalapplied.com/blog/llm-gateway-architecture-2026-engineering-reference)
- [Deepak Gupta — Top 5 AI Gateways 2026 (Kong vs Portkey vs LiteLLM vs Cloudflare vs Helicone)](https://guptadeepak.com/tools/top-5-ai-gateways-2026/)
- [LiteLLM — Proxy (AI Gateway) docs](https://docs.litellm.ai/docs/proxy/quick_start)
- [Portkey — Control plane for AI traffic](https://portkey.ai/)
- [Contabo — LiteLLM vs Portkey, Kong & Cloudflare: AI Gateways Compared](https://contabo.com/blog/litellm-vs-ai-gateways/)
