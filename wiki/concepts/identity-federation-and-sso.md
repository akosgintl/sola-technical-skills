---
title: Identity Federation & SSO
aliases: [SSO, single sign-on, identity federation, SAML, SCIM, federated identity, identity provider, identity gateway]
type: concept
domain: security
status: mature
tags: [security, identity, sso, saml, oidc, scim, federation]
updated: 2026-06-26
sources:
  - "https://clerk.com/articles/oidc-vs-saml-for-enterprise-sso-a-2026-decision-guide"
  - "https://guptadeepak.com/sso-deep-dive-saml-oauth-and-scim-in-enterprise-identity-management/"
  - "https://datatracker.ietf.org/doc/html/rfc7644"
  - "https://ssojet.com/blog/identity-federation-protocols-platform-architects"
  - "https://builder.aws.com/content/3F0DzoOH7GDjdn1oEeCvaFKFQfS/how-identity-federation-works-on-aws-saml-oidc-and-iam-identity-center"
---

# Identity Federation & SSO

> [!summary]
> Single sign-on (SSO) lets a user authenticate once with a trusted **identity provider (IdP)** and
> reach many applications without re-authenticating; **federation** extends that trust *across
> organizational boundaries* so an app can accept identities from a customer's or partner's IdP. The
> architecture is three things: the **trust relationships** between IdPs and service providers, the
> **protocols** that carry assertions (SAML, OIDC), and the **lifecycle sync** that keeps accounts
> current (**SCIM** provisioning/deprovisioning). It is distinct from its neighbors:
> [[iam-and-secrets-management]] is the IAM/RBAC/secrets foundation and [[api-security]] is token
> validation at the API — this page is the **cross-organization identity plane**, and in B2B SaaS
> it is a hard requirement: ship SSO *and* SCIM or fail the security review.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

- **SSO** — one authentication event grants access to many apps within a trust domain.
- **Federation** — the trust spans *separate organizations or IdPs*: your app trusts assertions
  issued by an external IdP it doesn't control. (Federated SSO = SSO across that boundary.)

The actors: the **IdP** authenticates the user and issues an assertion/token; the **service
provider (SP)** / relying party consumes it and grants access; a **trust relationship** (exchanged
metadata, signing keys) lets the SP believe the IdP. The protocol mechanics (SAML assertions, OIDC
ID tokens / JWT validation) are covered in [[iam-and-secrets-management]] and [[api-security]]; this
page is about the *topology and lifecycle*.

## Why it matters

- **It's table stakes for B2B.** Enterprise procurement in 2026 requires SAML *or* OIDC SSO, **SCIM**
  for user lifecycle, and MFA + audit logging. SCIM was a requirement for ~74% of enterprise SaaS
  deals over $100k ARR; shipping SSO without SCIM fails security reviews. Federation isn't a feature,
  it's an entry ticket to selling up-market.
- **It shrinks the attack surface.** One strong, phishing-resistant authentication at the IdP
  (passkeys/FIDO2 — see [[iam-and-secrets-management]]) replaces a password per app.
- **Centralized deprovisioning is the security payoff.** Fire an employee and the IdP revokes access
  everywhere at once — *if* lifecycle is wired correctly. Orphaned accounts left behind are a classic
  compliance finding.

## Key concepts / building blocks

### SAML vs. OIDC

| | **SAML 2.0** | **OIDC** |
|---|---|---|
| Era / format | Mature; XML assertions | Modern; JSON / JWT on OAuth 2.0 |
| Strength | Vast enterprise/regulated installed base | Cloud-native, mobile/SPA-friendly |
| B2B reality | Enterprises hand you SAML metadata on day one | Mid-market and new deployments prefer it |

The practical rule for B2B SaaS: **if you sell to enterprise, support both** behind one
enterprise-connection model. SAML isn't going away for a decade; OIDC wins new deployments.

### SCIM — the lifecycle half

SSO authenticates; **SCIM** (System for Cross-domain Identity Management) *provisions*: the IdP
automatically creates, updates, and **deactivates** accounts in the app as workforce changes happen.
The contrast that trips teams up:

- **JIT (just-in-time) provisioning** creates the account on first SSO login — simple, but it
  **never deprovisions**. The IdP blocks login, yet the app still holds an active account →
  orphaned accounts.
- **SCIM** pushes the full lifecycle, including deactivation. This is why enterprises demand it
  *alongside* SSO, not as a later evaluation.

### Federation models: direct vs. brokered

- **Direct federation** — each SP trusts each IdP directly. Simple at small scale; becomes O(N×M)
  and operationally expensive as partner/IdP count grows.
- **Brokered federation (identity gateway)** — the SP trusts one **broker** that federates many
  external IdPs. Reduces app-side complexity to a single trust, at the cost of a dependency (and a
  potential single point of failure). The common implementation is an **identity gateway** (Keycloak,
  Auth0, Entra External ID, WorkOS-style) that accepts customers' SAML/OIDC and issues *internal*
  OIDC JWTs to downstream services — so the apps speak one protocol regardless of the customer's IdP.

### Workforce vs. customer identity (CIAM)

**Workforce** identity (employees, B2B partners) optimizes for federation, SCIM, and least
privilege. **CIAM** (customer identity) optimizes for scale, UX, self-service registration, consent,
and social login. They are different products with different priorities; conflating them is a common
design error.

### Session, logout, and trust hygiene

Single logout (SLO), token/session lifetimes, and rigorous **assertion validation** (signature,
audience, issuer, expiry — the SAML analogue of the [[api-security|JWT validation]] discipline) are
where federation quietly breaks or leaks.

## Design decisions & trade-offs

- **SAML, OIDC, or both.** Selling up-market means **both** — the enterprise installed base is SAML,
  new/mobile is OIDC. A provider/gateway that supports both behind one integration is the pragmatic
  answer.
- **SCIM vs. JIT.** JIT is the cheap path to "we have SSO," but the missing deprovisioning is a
  security and compliance liability. SCIM is the enterprise requirement; plan for it from the start.
- **Direct vs. brokered federation.** Direct trust is simplest at small partner counts; a broker /
  identity gateway is the scalable choice as IdPs multiply — accepting a new runtime dependency and
  the need to keep *it* highly available.
- **Build vs. buy the IdP.** Managed (Okta, Entra, Auth0, WorkOS) vs. self-hosted (Keycloak) vs. DIY.
  **Don't DIY federation** — rolling your own SAML/OIDC is a reliable source of subtle, exploitable
  bugs. Buy or adopt a hardened implementation.
- **Centralizing on one IdP.** Consolidation gives consistent policy and one place to deprovision —
  but makes the IdP a blast-radius single point: an IdP outage can lock everyone out of everything.
  Plan break-glass access and resilience ([[disaster-recovery-and-continuity]]).

## State of the art

- **OIDC is winning new deployments; SAML remains entrenched** in enterprise and regulated estates —
  both for at least another decade, so B2B platforms ship both.
- **SCIM is a hard procurement requirement**, not an optional extra; identity gateways
  (Keycloak/Auth0/Entra External ID/WorkOS) are the standard way B2B SaaS absorbs heterogeneous
  customer IdPs behind one internal protocol.
- **Passwordless / passkeys (FIDO2)** at the IdP are mainstream, making the single federated login
  phishing-resistant.
- **The frontier is non-human and agent identity** — service accounts and AI agents as federated
  principals — connecting this to [[iam-and-secrets-management]] (NHIs) and
  [[agent-identity-and-access]].

## Pitfalls & anti-patterns

- **JIT without SCIM.** Offboarded users leave orphaned accounts the app still honors — a recurring
  compliance finding.
- **Shipping SSO without SCIM.** Fails enterprise security review; the lifecycle is half the product.
- **OIDC-only when selling to enterprise.** They arrive with SAML metadata; OIDC-only loses the deal.
- **DIY federation.** Hand-rolled SAML/OIDC with subtle signature/audience validation bugs.
- **The IdP as an unmitigated single point of failure.** No break-glass path when the IdP is down =
  total lockout.
- **Weak assertion validation.** Skipping SAML signature/audience checks — the federation analogue of
  accepting `alg:none` JWTs ([[api-security]]).
- **Conflating CIAM and workforce identity.** Forcing a customer-scale identity product to do
  enterprise federation, or vice versa.

## See also

- [[iam-and-secrets-management]]
- [[api-security]]
- [[zero-trust-architecture]]
- [[agent-identity-and-access]]
- [[compliance-and-regulation]]
- [[disaster-recovery-and-continuity]]

## Sources

- [Clerk — OIDC vs SAML for Enterprise SSO: A 2026 Decision Guide](https://clerk.com/articles/oidc-vs-saml-for-enterprise-sso-a-2026-decision-guide)
- [Gupta — SSO Deep Dive: SAML, OAuth, and SCIM in Enterprise Identity](https://guptadeepak.com/sso-deep-dive-saml-oauth-and-scim-in-enterprise-identity-management/)
- [RFC 7644 — System for Cross-domain Identity Management (SCIM) Protocol](https://datatracker.ietf.org/doc/html/rfc7644)
- [SSOJet — Identity Federation Protocols Every Platform Architect Should Know](https://ssojet.com/blog/identity-federation-protocols-platform-architects)
- [AWS Builder — How Identity Federation Works: SAML, OIDC, and IAM Identity Center](https://builder.aws.com/content/3F0DzoOH7GDjdn1oEeCvaFKFQfS/how-identity-federation-works-on-aws-saml-oidc-and-iam-identity-center)
