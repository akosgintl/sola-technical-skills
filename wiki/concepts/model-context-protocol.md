---
title: Model Context Protocol
aliases: [MCP, model context protocol, mcp]
type: concept
domain: ai-agentic
status: mature
tags: [llm, agents, mcp, integration, protocol, ai-security, oauth, governance]
updated: 2026-06-30
sources:
  - "https://modelcontextprotocol.io/specification/2025-11-25"
  - "https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization"
  - "https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/"
  - "https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/"
  - "https://www.truefoundry.com/blog/blog-mcp-tool-poisoning-gateway-defense"
  - "https://arxiv.org/pdf/2512.08290"
  - "https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year"
  - "https://workos.com/blog/everything-your-team-needs-to-know-about-mcp-in-2026"
---

# Model Context Protocol

> [!summary]
> **MCP is the "USB-C for AI tools"**: an open, JSON-RPC 2.0 protocol that standardizes how
> an LLM application (the **host**, via embedded **clients**) connects to external tools, data,
> and prompts exposed by **servers**. Anthropic shipped it in late 2024; every major
> model vendor has adopted it, and Anthropic donated it to the Linux Foundation's **Agentic AI
> Foundation**. It is the M×N integration collapse — write a tool once, every
> MCP-aware agent can use it — but it ships with a genuinely new security surface (tool poisoning,
> confused-deputy, prompt injection *through tool results*) that you own at design time.

**Domain:** [[tier-1-edge|AI & Agentic Architecture]]

## What it is

MCP is an open application-layer protocol that gives LLM-driven applications a single, typed
way to discover and call external capabilities, instead of bespoke glue per integration. It is
explicitly modeled on the **Language Server Protocol (LSP)**: as LSP lets any editor talk to any
language toolchain, MCP lets any agent runtime talk to any tool/data provider.

Three roles, all speaking **JSON-RPC 2.0** over a transport:

- **Host** — the LLM application (Claude Desktop/Code, ChatGPT, Copilot, your own agent runtime).
- **Client** — a connector *inside* the host; one client holds one stateful session to one server.
- **Server** — a service exposing capabilities (a GitHub server, a Postgres server, an internal CRM server).

This is the M×N → M+N collapse: instead of every host integrating every tool, each side implements
MCP once. That is the entire reason the protocol won — it is a coordination standard, not a feature.

## Why it matters

By early 2026 MCP crossed ~97M monthly SDK downloads (Python + TypeScript) and 10,000+ public
servers, and is supported by Anthropic, OpenAI, Google, Microsoft, and AWS. In December 2025
Anthropic donated MCP to the **Agentic AI Foundation (AAIF)** under the Linux Foundation
(founding members include Block, OpenAI, AWS, Google, Microsoft, Cloudflare, Bloomberg). The
"protocol war" is over; MCP is now the de-facto **vertical integration layer** for agents.

The significance is threefold:

1. **It is the integration substrate your agent strategy now standardizes on.** Choosing MCP vs. a
   custom integration is a load-bearing decision (see trade-offs below), and "we'll wrap everything
   in MCP" is rarely the right default.
2. **It moves an untrusted, model-readable control plane into your perimeter.** Tool descriptions,
   resource contents, and tool *results* all flow into the model's context — and the model acts on
   them. That makes MCP a [[prompt-injection]] and [[ai-specific-security|AI security]] problem, not
   just a plumbing problem.
3. **Multi-tenant + regulated products inherit MCP's identity, audit, and scoping gaps.** The spec
   gives you OAuth hooks and consent principles, but per-tenant isolation, audit trails, and
   compliance logging are *your* responsibility — see [[agent-identity-and-access]] and
   [[agent-governance-and-policy]].

## Key concepts / building blocks

**Server primitives** (what a server offers the host):

- **Tools** — model-invokable functions with a JSON-Schema input (`tools/list`, `tools/call`).
  These are *arbitrary code execution* paths; the spec flags tool descriptions/annotations as
  **untrusted unless the server is trusted**.
- **Resources** — URI-addressable context/data (files, rows, documents), *application-controlled*
  (the host decides what to surface), not autonomously pulled by the model.
- **Prompts** — server-supplied templated messages/workflows, *user-controlled* (e.g. a slash command).

**Client primitives** (what a host can offer back to a server):

- **Sampling** — server asks the host to run an LLM completion (recursive/agentic behavior). The spec
  *intentionally limits server visibility* into the prompt and requires user approval.
- **Elicitation** — server requests additional input from the user mid-flow.
- **Roots** — server queries the filesystem/URI boundaries it is allowed to operate in.

**Transports:**

- **stdio** — local subprocess; the original, default for desktop/local servers. Simple, but the
  server runs with the host user's ambient privileges.
- **Streamable HTTP** — the current standard for remote, production servers: an HTTPS endpoint,
  multiple concurrent clients, horizontal scaling, and OAuth 2.1 auth. (Superseded the older
  HTTP+SSE transport.)

**Authorization (remote MCP):** the spec treats the MCP server as an **OAuth 2.1 Resource Server**.
It requires **Protected Resource Metadata (RFC 9728)** — a 401 returns `WWW-Authenticate` pointing
to a PRM document whose `authorization_servers` field tells the client where to get a token —
plus **Resource Indicators (RFC 8707)** so tokens are *audience-bound to that server*. The server
**MUST NOT** accept or pass through tokens minted for some other upstream API; that single rule is
what closes the OAuth confused-deputy hole.

## Design decisions & trade-offs

**Protocol (MCP) vs. custom integration — the call you actually make.**

Reach for **MCP** when:
- The capability is **reused across multiple hosts/agents** (the M×N case) — this is its core payoff.
- You want **dynamic discovery** (`tools/list`) so the agent adapts without a redeploy.
- You're targeting an **ecosystem of third-party agents** (ChatGPT, Copilot, Claude) and want one server to serve all.
- You want a **uniform consent/audit chokepoint** for tool use across many tools.

Stay with a **custom/direct integration** (plain SDK call, function tool, REST) when:
- There is exactly **one consumer** and one provider — MCP's indirection is pure overhead.
- The path is **latency- or throughput-critical** (high-volume RAG retrieval, tight loops); MCP adds a JSON-RPC hop and a model round-trip to *decide* to call.
- The operation is **deterministic and doesn't need model reasoning** — call the API directly from code; don't route it through the LLM at all.
- You can't accept the **untrusted-tool-description** threat model for that data domain.
- **Context/token economics dominate.** A server dumps its full tool catalog into the model's context at boot — e.g. Notion's MCP server is ~20,000 tokens of self-documenting tools whether used or not, versus ~100 tokens for a lazily-loaded skill/CLI (~200× more boot context). When you control the client and want a minimal context budget, a CLI the agent calls via bash (composing with `jq`, redirects, no model round-trip) can beat MCP. See [[llm-knowledge-base]] for this CLI-over-MCP argument worked through.

> [!tip] Heuristic: MCP earns its keep at the **many-to-many** boundary and as a **governance chokepoint**.
> For one-to-one, latency-bound, or fully-deterministic paths, a direct call is simpler and safer.

**Local (stdio) vs. remote (Streamable HTTP).** Local is frictionless for a single developer but
runs with ambient user privilege and has no real authN/authZ story — fine for a workstation, wrong
for a product. Remote MCP with OAuth 2.1 is the only defensible posture for multi-tenant SaaS, but
you now own token audience-binding, per-tenant scoping, and an MCP **gateway**.

**Per-tenant scoping in [[multi-tenancy-architecture|multi-tenant products]].** The protocol does **not** isolate tenants for you.
You must: (1) bind every token to a single tenant and a single server audience; (2) scope which
tools/resources a tenant's agent can even *see* at `tools/list` (don't leak the catalog across
tenants); (3) push tenant identity through to the downstream system so the *real* backend enforces
row-level authz — never trust the agent to self-segregate. This is [[agent-identity-and-access]]
territory: agents are first-class principals ([[agents-as-system-citizens]]) and need their own
least-privilege identity, not a shared service account.

**Audit, permission boundaries, compliance logging.** MCP's spec gives you the *hooks* (consent
prompts, OAuth, capability negotiation) but no built-in audit trail. Architect it: log every
`tools/call` with caller identity, tenant, tool, arguments, and result hash; gate sensitive tools
behind explicit human approval ([[human-in-the-loop-design]]); enforce allow-lists and policy at a
gateway, not in prompts. Treat this as part of [[agent-governance-and-policy]] and your
[[compliance-and-regulation|compliance]] evidence chain.

## State of the art

- **Spec cadence & governance.** The current stable spec is **2025-11-25** (stateful JSON-RPC core,
  Streamable HTTP, hardened OAuth). The **2026-07-28** release candidate moves toward a **stateless
  protocol core** that scales on ordinary HTTP, plus an **Extensions** framework, a **Tasks**
  extension for long-running work, **MCP Apps** (server-rendered UI/widgets in chat), and further
  OAuth/OIDC alignment. Now governed by the Linux Foundation **AAIF**.
- **Remote-first is the enterprise default.** ChatGPT's MCP support is remote-first; Microsoft routes
  org MCP through Copilot Studio with **Entra dynamic client registration**; Azure DevOps shipped a
  remote MCP server. Google's *consumer* Gemini still lacks custom MCP connectors (CLI + Gemini
  Enterprise only). The practical lesson: target **Streamable HTTP + OAuth 2.1** for anything you ship.
- **Registries.** The official **MCP Registry** is the central clearinghouse for discovering/publishing
  servers — and is itself now a supply-chain trust boundary you must vet ([[model-supply-chain-security]]).
- **A2A vs MCP — complementary, not competing.** **A2A** (Agent2Agent, Google→Linux Foundation,
  150+ orgs by 2026) is the **horizontal** layer: agents discovering, authenticating, and delegating
  *to other agents* across org boundaries. **MCP is the vertical layer**: an agent connecting *down*
  to tools/data. The emerging default stack: an agent uses **A2A** to delegate to a specialist, which
  uses **MCP** to call its tools. See [[agent-to-agent-protocols]] and [[api-styles-and-protocols]]
  for where each fits in the integration taxonomy.

## Security posture (the part architects underweight)

MCP's power — arbitrary data access and code execution, with descriptions the model reads and trusts —
*is* its risk. Treat MCP as untrusted ingress. Key threats:

- **Tool poisoning.** A malicious/compromised server writes adversarial instructions *into a tool
  description* that the host hands straight to the model with no sanitization and full ambient authority.
  **CVE-2025-54136 ("MCPoison")** showed the **rug-pull** variant: a benign tool/config is approved on
  day 1, then silently mutated to exfiltrate keys on day 7. Mitigation: pin and re-verify tool
  definitions; alert on description changes; treat tool metadata as code in review.
- **Confused deputy.** An agent holding privileged tools is tricked into using them on behalf of someone
  who shouldn't have them — including the OAuth token-passthrough variant. Mitigation: audience-bound
  tokens (RFC 8707), no token reuse across servers, downstream re-authorization.
- **Prompt injection via tool *results*.** A tool can return content (a web page, an email, a row) that
  contains instructions the model then obeys. This is the hardest one — it is [[prompt-injection]] with
  a privileged action surface attached. Mitigation: treat all tool output as untrusted data, not
  instructions; constrain what actions can follow a retrieval; human approval on consequential writes.
- **Cross-server interference.** With many servers on one agent, a malicious server can shadow or
  intercept calls meant for a trusted one. Mitigation: namespace and isolate servers; don't co-mingle
  untrusted and high-privilege servers in one session.

> [!warning] The recurring fix is an **MCP gateway**: a control point *outside* the host that inspects
> every tool schema and result before it reaches a model — zero-trust ingress for tool discovery,
> the way a load balancer treats inbound HTTP. Pair it with per-tool allow-lists, audience-bound
> OAuth, and human-in-the-loop on consequential actions. See [[ai-specific-security]].

## Pitfalls & anti-patterns

- **Treating tool descriptions/results as trusted.** They are attacker-controllable inputs to your model. Never.
- **One shared service account for all tenants/agents.** Destroys per-tenant scoping and auditability; give each agent its own least-privilege identity.
- **Shipping local stdio servers as a product.** No real authZ, ambient privilege — fine for a laptop, negligent for multi-tenant SaaS.
- **Token passthrough to upstream APIs.** Re-introduces the confused-deputy hole the spec works to close; always audience-bind.
- **Wrapping *everything* in MCP.** Deterministic, single-consumer, or latency-critical paths belong in direct code, not behind the model.
- **No audit trail.** The spec won't give you one; if you can't reconstruct who-called-what-on-whose-behalf, you have no compliance story.
- **Installing servers from the registry without vetting.** Treat third-party servers as supply-chain dependencies.

## See also

- [[agentic-system-design]]
- [[agents-as-system-citizens]]
- [[agent-identity-and-access]]
- [[agent-governance-and-policy]]
- [[ai-specific-security]]
- [[prompt-injection]]
- [[agent-to-agent-protocols]]
- [[api-styles-and-protocols]]
- [[llm-knowledge-base]] — the CLI-over-MCP token-economics trade-off in practice

## Sources

- [MCP Specification 2025-11-25 — modelcontextprotocol.io](https://modelcontextprotocol.io/specification/2025-11-25)
- [MCP Authorization spec (OAuth 2.1, RFC 9728/8707)](https://modelcontextprotocol.io/specification/2025-11-25/basic/authorization)
- [The 2026 MCP Roadmap — MCP Blog](https://blog.modelcontextprotocol.io/posts/2026-mcp-roadmap/)
- [MCP has prompt injection security problems — Simon Willison](https://simonwillison.net/2025/Apr/9/mcp-prompt-injection/)
- [MCP Tool Poisoning (CVE-2025-54136) — TrueFoundry](https://www.truefoundry.com/blog/blog-mcp-tool-poisoning-gateway-defense)
- [SoK: Security and Safety in the MCP Ecosystem — arXiv 2512.08290](https://arxiv.org/pdf/2512.08290)
- [A2A surpasses 150 organizations — Linux Foundation](https://www.linuxfoundation.org/press/a2a-protocol-surpasses-150-organizations-lands-in-major-cloud-platforms-and-sees-enterprise-production-use-in-first-year)
- [Everything your team needs to know about MCP in 2026 — WorkOS](https://workos.com/blog/everything-your-team-needs-to-know-about-mcp-in-2026)
