---
title: API Security
aliases: [API security, OWASP API Top 10, BOLA, broken object level authorization, API authentication, API authorization, OAuth2, OIDC, JWT validation]
type: concept
domain: security
status: mature
tags: [security, api, owasp, authentication, authorization, oauth, bola]
updated: 2026-06-26
sources:
  - "https://owasp.org/API-Security/editions/2023/en/0x11-t10/"
  - "https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/"
  - "https://datatracker.ietf.org/doc/html/rfc9700"
  - "https://openid.net/developers/how-connect-works/"
  - "https://www.wiz.io/academy/api-security/owasp-api-security"
---

# API Security

> [!summary]
> API security is securing the API layer — now the dominant application attack surface as systems
> decompose into services and expose endpoints to web, mobile, partners, and autonomous agents.
> Its defining risk is **broken authorization**, above all **BOLA** (Broken Object Level
> Authorization) — an API that trusts a client-supplied object ID without checking that the caller
> *owns* that object — which alone accounts for roughly 40% of API attacks. The discipline is
> applied [[zero-trust-architecture|zero trust]] at the API layer: strong authentication
> (OAuth2/OIDC/JWT/mTLS), **authorization re-checked on every request at the right granularity**
> (object, property, function), resource limits (rate limiting, quotas), and knowing your full API
> inventory. The **OWASP API Security Top 10 (2023)** is the shared vocabulary.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

APIs are a *distinct* security surface from classic web apps, which is why OWASP maintains a
separate **API Security Top 10**. The differences drive the risk profile: clients are machines, not
browsers; requests carry **object identifiers** the client can manipulate; there is no human or UI
to constrain inputs; and the same endpoint is exposed broadly to first-party apps, partners, and
increasingly [[model-context-protocol|agents and MCP servers]]. The OWASP API Security Top 10
(2023):

| ID | Risk |
|---|---|
| **API1** | **Broken Object Level Authorization (BOLA)** — the dominant API risk |
| **API2** | Broken Authentication |
| **API3** | Broken Object Property Level Authorization (mass assignment / excessive data exposure) |
| **API4** | Unrestricted Resource Consumption (rate/quotas/cost) |
| **API5** | Broken Function Level Authorization (BFLA — admin endpoints) |
| **API6** | Unrestricted Access to Sensitive Business Flows |
| **API7** | Server-Side Request Forgery (SSRF) |
| **API8** | Security Misconfiguration |
| **API9** | Improper Inventory Management (shadow/zombie APIs) |
| **API10** | Unsafe Consumption of APIs (trusting upstream/third-party APIs) |

## Why it matters

APIs are the primary breach vector for modern systems, and the failures are overwhelmingly
**authorization** failures the architecture must prevent by design, not bugs a scanner finds. A
single missing object-level ownership check leaks *every* user's data: change `/orders/123` to
`/orders/124` and read someone else's order. [[service-decomposition|Decomposition]] multiplies the
number of APIs, and agentic systems add machine callers that probe endpoints systematically — so the
attack surface is growing precisely as it becomes harder to reason about manually. This sits with
the architect because the durable controls — the authorization model, the token strategy, the
enforcement topology — are design-time decisions, and belong in the
[[threat-modeling|threat model]].

## Key concepts / building blocks

### Authentication — proving who is calling

- **OAuth 2.0 / OAuth 2.1** — a delegated *authorization* framework (grants scoped access via
  tokens). Use the **authorization code flow with PKCE** for user-facing clients and **client
  credentials** for service-to-service. OAuth 2.1 consolidates best practice: PKCE mandatory, the
  implicit and password grants removed.
- **OpenID Connect (OIDC)** — the *identity* layer on top of OAuth2; the ID token tells you *who*
  the user is. OAuth2 is for access; OIDC is for authentication — conflating them is a common error.
- **JWT validation** — self-contained tokens scale (no central lookup) but must be validated
  rigorously: verify the signature, **reject `alg:none`**, pin the algorithm, and check `exp`,
  `aud`, and `iss`. Most JWT vulnerabilities are validation shortcuts.
- **mTLS** — mutual TLS for service-to-service authentication, often terminated in a
  [[api-gateways-and-service-mesh|service mesh]].
- **API keys** identify an *application*, not authenticate a *user*. They are a weak primary control
  — fine for rate-limiting/attribution, insufficient for protecting sensitive data alone.

### Authorization — the part that actually breaks

The recurring failure is checking authorization at the wrong granularity (or only at login):

- **Object level (BOLA / API1)** — on *every* request, verify the authenticated principal is allowed
  to act on *this specific object*. **Never trust a client-supplied ID** for the authorization
  decision; derive ownership from the session/token and the data model.
- **Object-property level (API3)** — don't return or bind whole objects blindly: **excessive data
  exposure** (leaking fields the client shouldn't see) and **mass assignment** (letting a client set
  fields like `isAdmin`) are the two faces. Use explicit allow-lists for serialization and binding.
- **Function level (BFLA / API5)** — guard administrative/privileged endpoints; don't rely on the
  UI hiding them.

### Resource consumption and business-flow abuse

- **Rate limiting, quotas, pagination, and payload-size limits** (API4) are *security* controls, not
  just performance ones — they blunt DoS, brute force, scraping, and runaway cost.
- **Sensitive business flow protection** (API6) — legitimate flows (signup, checkout, password reset)
  abused at scale by bots; needs anomaly detection and friction, not just per-request auth.

### API inventory and the enforcement point

- **Inventory (API9)** — you cannot secure what you don't know exists. **Shadow** APIs (undocumented)
  and **zombie** APIs (old, unretired versions) are prime targets. An accurate OpenAPI catalog is a
  security control. Pairs with [[coupling-and-versioning-discipline|versioning/deprecation discipline]].
- **The gateway is the policy enforcement point** for *coarse* controls — authN, token validation,
  scope checks, rate limiting, schema (positive-security) validation. But **object-level
  authorization cannot live at the gateway** — only the service has the domain data to know who owns
  what. Splitting these correctly is the key topology decision (see [[api-gateways-and-service-mesh]]).

## Design decisions & trade-offs

- **Where authorization lives — and what the gateway cannot do.** Push coarse authN, scope, and rate
  limiting to the gateway; keep **object- and property-level authorization in the service**, where
  ownership is knowable. The most common catastrophic mistake is assuming the gateway "handles auth"
  and omitting per-object checks in the service.
- **Token format: JWT vs. opaque.** Self-contained JWTs validate without a network call (scalable)
  but are hard to revoke — mitigate with short TTLs plus refresh, or token introspection. Opaque
  tokens are trivially revocable but require a central lookup. Choose by revocation needs vs. scale.
- **mTLS vs. token-based for service-to-service.** mTLS (mesh-managed) gives strong mutual identity
  with no app code; tokens carry richer authorization context. Many systems use both — mTLS for
  transport identity, a token for scoped authorization.
- **Positive vs. negative security.** A positive model (validate every request against an OpenAPI
  schema at the gateway — reject anything not explicitly allowed) is stronger than a negative model
  (block known-bad). It costs keeping the schema accurate.
- **Rate-limit granularity.** Per-user, per-key, and per-IP each catch different abuse; combine them,
  and treat limits as both an abuse and a [[ai-gpu-economics|cost]] control.
- **Zero trust at the API layer.** Authenticate and authorize *every* call on its own merits; grant
  no implicit trust from network position. This is [[zero-trust-architecture]] expressed for APIs.

## State of the art

- **OWASP API Security Top 10 (2023)** is the reference standard; **BOLA remains #1**, still ~40% of
  API attacks — authorization, not exotic exploits, is where APIs fail.
- **OAuth 2.1** consolidates the secure defaults (PKCE everywhere, implicit/password grants gone);
  **mTLS-secured service meshes** are the norm for east-west traffic.
- **Runtime API security tooling** (discovery + behavioral detection — Salt, Akamai/Noname,
  Cloudflare, cloud-native API security in Wiz-class platforms) addresses inventory and BOLA-style
  abuse that static review misses.
- **Positive-security schema enforcement** (OpenAPI validation at the gateway) is increasingly
  standard.
- **Agentic/MCP expansion**: as agents call tools and APIs autonomously, the API surface and the
  confused-deputy/over-scoped-token risks grow — connecting API security to
  [[ai-specific-security]] and [[model-context-protocol]].

## Pitfalls & anti-patterns

- **BOLA: trusting client-supplied IDs.** No per-object ownership check on each request — the single
  most common and most damaging API flaw.
- **"The gateway handles auth."** Assuming coarse gateway authN covers object-level authorization.
  It can't; the service must.
- **JWT validation shortcuts.** Accepting `alg:none`, skipping signature/`exp`/`aud`/`iss` checks.
- **API keys as authentication.** Treating an app-identifying key as proof of a user's identity.
- **No resource limits.** Missing rate limiting/pagination/payload caps — DoS, scraping, and cost
  blowouts.
- **Excessive data exposure / mass assignment.** Returning or binding whole objects instead of
  explicit field allow-lists.
- **Shadow and zombie APIs.** Undocumented or un-retired endpoints with no inventory or monitoring.
- **Security misconfiguration.** Verbose error leakage, permissive CORS (`*`), missing TLS, default
  credentials.

## See also

- [[zero-trust-architecture]]
- [[iam-and-secrets-management]]
- [[identity-federation-and-sso]]
- [[api-gateways-and-service-mesh]]
- [[api-styles-and-protocols]]
- [[multi-tenancy-architecture]]
- [[threat-modeling]]
- [[ai-specific-security]]
- [[model-context-protocol]]
- [[network-segmentation]]

## Sources

- [OWASP API Security Top 10 (2023)](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)
- [OWASP API1:2023 — Broken Object Level Authorization](https://owasp.org/API-Security/editions/2023/en/0xa1-broken-object-level-authorization/)
- [RFC 9700 — Best Current Practice for OAuth 2.0 Security](https://datatracker.ietf.org/doc/html/rfc9700)
- [OpenID Connect — How it works](https://openid.net/developers/how-connect-works/)
- [Wiz — OWASP API Security Top 10 risks and mitigations](https://www.wiz.io/academy/api-security/owasp-api-security)
