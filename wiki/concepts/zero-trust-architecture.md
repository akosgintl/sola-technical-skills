---
title: Zero-Trust Architecture
aliases: [zero trust, ZTA, BeyondCorp, never trust always verify]
type: concept
domain: security
status: mature
tags: [security, zero-trust, identity, microsegmentation, beyondcorp, nist]
updated: 2026-06-20
sources:
  - "https://csrc.nist.gov/pubs/sp/800/207/final"
  - "https://nvlpubs.nist.gov/nistpubs/specialpublications/NIST.SP.800-207.pdf"
  - "https://www.graygroupintl.com/blog/zero-trust-security-architecture/"
  - "https://terrazone.io/nist-sp-800-207/"
  - "https://arxiv.org/pdf/2511.04925"
  - "https://tech-insider.org/zero-trust-architecture-why-every-company-needs-it-in-2026/"
---

# Zero-Trust Architecture

> [!summary]
> Zero-trust architecture (ZTA) replaces perimeter-based security ("inside is trusted, outside is not") with continuous verification of every request — regardless of network location. Every access decision evaluates identity, device posture, and context; grants the minimum privilege needed; and operates under the assumption that breach has already occurred. ZTA is not a product but an architectural philosophy codified in NIST SP 800-207, now extending from human users to non-human principals: services, workloads, and AI agents.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Traditional security built a hard perimeter (firewall, VPN) and trusted everything inside it. Once an attacker crossed the perimeter — via phishing, a compromised VPN credential, or a supply chain breach — they could move laterally with little resistance. This model collapsed with cloud adoption, remote work, and SaaS: the "inside" no longer maps to a physical network.

Zero trust abandons the perimeter entirely. The foundational principle: **never trust, always verify**. Every request — from any user, any device, any network location — must be authenticated, authorized, and continuously validated before access is granted. The evaluation considers:

- **Identity** — who or what is making the request (user, service, agent)
- **Device posture** — is the device managed, patched, and compliant?
- **Context** — location, time, behavior, sensitivity of the requested resource
- **Least privilege** — grant the minimum access required for the specific task

**Assume breach:** ZTA is designed to limit blast radius when (not if) a credential or device is compromised. Microsegmentation ensures a compromised account cannot move laterally to unrelated systems.

## Why it matters

By 2026, 60% of large enterprises have implemented measurable zero trust programs, up from less than 10% in 2023 (Gartner). The supply chain attacks, ransomware lateral movements, and cloud credential thefts of 2020-2025 all exploited perimeter trust assumptions. Zero trust is not a new idea but the removal of the assumption that was wrong all along.

The market reflects the urgency: zero trust security is valued at ~$31.6 billion in 2025, projected to reach $67.3 billion by 2028.

## Key concepts / building blocks

### NIST SP 800-207 — the reference framework

NIST Special Publication 800-207 (August 2020) is the definitive standards reference for ZTA. It defines:

- **Policy Engine (PE)** — makes the access grant/deny decision based on all available signals
- **Policy Administrator (PA)** — communicates the decision to the Policy Enforcement Point
- **Policy Enforcement Point (PEP)** — the gate that permits or blocks the connection

Every access request flows through PE → PA → PEP. The PE consults: identity provider, device compliance system, threat intelligence feeds, behavioral analytics, and resource sensitivity policy.

CISA's Zero Trust Maturity Model v2 (2023) extends NIST 800-207 into five pillars with three maturity stages (Traditional → Advanced → Optimal) per pillar.

### The five ZTA pillars (CISA model)

| Pillar | What it governs | Key technologies |
|---|---|---|
| **Identity** | Authentication and authorization of all principals | MFA, SSO, conditional access, PAM |
| **Devices** | Device compliance and health posture | MDM/EMM, EDR, device certificates |
| **Networks** | Traffic segmentation and encryption | Microsegmentation, SD-WAN, encrypted east-west |
| **Applications** | App-layer access control, not just network | ZTNA/SDP, per-app tunnels, WAF |
| **Data** | Data classification and protection | DLP, encryption, data labeling |

Mature ZTA eventually covers all five pillars. Most organizations start with Identity (highest ROI, fastest to implement) and then extend to Devices and Networks.

### Identity-first access (replacing VPN)

The traditional VPN model grants network access; ZTA grants application access. ZTNA (Zero Trust Network Access) / SDP (Software-Defined Perimeter) replaces VPN:
- Clients authenticate to a ZTNA broker using identity + device posture
- The broker grants access to specific applications, not the underlying network
- Applications are invisible (dark) to unauthenticated users — no open ports to scan

Vendors: Cloudflare Access, Zscaler Private Access (ZPA), Google BeyondCorp Enterprise, Palo Alto Prisma Access, Tailscale.

**BeyondCorp (Google, 2014):** the reference implementation that shifted Google from VPN to identity-aware proxies for all internal applications. Employees access applications via a single identity-aware proxy that verifies Google account + managed device posture on every request. No VPN required. Widely cited as the practical proof that zero trust is operationally viable at scale.

### Microsegmentation

Microsegmentation places fine-grained security boundaries around individual workloads, applications, or data stores — not around network subnets. In a microsegmented network:
- East-west (lateral) traffic between services requires explicit policy, not implicit network trust
- A compromised workload can reach only the services it is explicitly allowed to reach
- Policies follow workloads as they move (not tied to IP addresses or subnets)

**Implementation options:**
- **Host-based (software-defined):** policies enforced by the OS firewall or eBPF agent on each host (Illumio, Guardicore, Zscaler)
- **Network-based:** enforced by the network fabric (NSX, ACI)
- **Kubernetes-native:** NetworkPolicy objects enforced by the CNI (Cilium, Calico) — see [[kubernetes-at-design-level]]

### Continuous / context-aware authentication

ZTA does not authenticate once at login and trust for the session. It continuously re-evaluates access:
- **Adaptive MFA** — trigger step-up authentication when risk signals change (new device, unusual location, sensitive resource)
- **Session risk scoring** — ongoing behavioral analytics; revoke session if score crosses threshold
- **Just-in-time (JIT) access** — elevated privileges granted for specific tasks, auto-expire; no standing privileged access

### Non-human identity (the 2026 expansion)

ZTA originally focused on human users. In 2026, non-human identities (NHIs) — service accounts, workload identities, API keys, AI agents — represent the majority of access requests and the fastest-growing attack surface.

**NSA 2026 discovery guideline:** makes discovery of non-person entities an explicit security requirement. Organizations must catalog every service account, API key, certificate, and OAuth client.

**NIST IR 8596 recommendation:** "cryptographic authentication methods and continuous validation" for machine-to-machine communications — apply the same ZTA principles to service-to-service traffic as to users.

See [[iam-and-secrets-management]] for the implementation details and [[agent-identity-and-access]] for AI agent identity patterns.

### ZTA and AI agents (emerging)

AI agents introduce a new category of non-human principals that are harder to govern than static service accounts:
- Agents act on behalf of users with delegated permissions
- Agent behavior is non-deterministic and may invoke tools with broad impact
- Agent sessions may be long-running with accumulated context that changes risk profile

ZTA principles applied to agents: minimum necessary tool permissions, time-bounded sessions, per-action re-authorization for sensitive operations, and audit logging of all tool invocations. See [[ai-specific-security]].

## Design decisions & trade-offs

**Where to start the ZTA journey:**
Most organizations cannot implement ZTA across all five pillars simultaneously. The recommended sequence:
1. **Identity pillar first** — deploy MFA universally; implement SSO with conditional access policies; eliminate shared accounts. Highest ROI, fastest to implement.
2. **ZTNA to replace VPN** — eliminates the biggest perimeter risk; often the second phase
3. **Device posture** — integrate MDM/EDR signals into conditional access decisions
4. **Microsegmentation** — most complex; apply incrementally to highest-risk segments first
5. **Data classification and DLP** — the longest-horizon work; requires data inventory first

**Cloud provider ZTA services:**
- AWS: IAM + SCPs + VPC endpoints + PrivateLink + SSO (IAM Identity Center) + GuardDuty for behavioral detection
- Azure: Entra ID (conditional access, PIM, privileged identity) + Azure Firewall + Defender for Identity
- GCP: BeyondCorp Enterprise + VPC Service Controls + Cloud IAM + Chronicle for detection

**Performance impact:**
ZTA adds latency on the authentication path. ZTNA proxies add ~10-50ms per connection establishment. Mitigate with: token caching (validate per session, not per request), efficient policy engines, and edge deployment of ZTNA brokers close to users.

## State of the art

ZTA adoption has moved from early-adopter to enterprise mainstream in 2025-2026, driven by ransomware insurance requirements, US Executive Order 14028 (federal agencies must adopt ZTA), and the EU NIS2 Directive (identity and access management as a requirement).

The 2026 frontier is **workload and agent identity** — applying the same ZTA rigor to service-to-service and agent-to-tool traffic that was originally applied only to human users. arXiv:2511.04925 demonstrates ZTA in microservices using identity federation; the same patterns extend to AI agent architectures.

**AI-augmented policy engines:** ML-based risk scoring (behavior analytics, UEBA) is being integrated into ZTA policy engines to make conditional access decisions dynamically rather than based on static rules alone.

## Pitfalls & anti-patterns

**ZTA as a VPN replacement only.** Replacing VPN with ZTNA and declaring "we've done zero trust." ZTA is an architecture across all five pillars, not a single product category.

**Implicit trust in east-west traffic.** Applying zero trust to north-south (user → app) while leaving east-west (service → service) traffic implicitly trusted within the cluster. Microsegmentation must apply internally.

**Excessive MFA friction.** Deploying MFA everywhere with constant prompts. Risk-based/adaptive MFA prompts only when risk signals warrant — otherwise users work around it.

**Standing privileged access.** Service accounts and admin accounts with always-on elevated permissions. Any credential compromise means immediate broad access. Use JIT elevation and auto-expiring permissions.

**No NHI inventory.** Not knowing how many service accounts, API keys, or machine credentials exist. Cannot apply ZTA to identities you haven't discovered. Inventory is the prerequisite.

## See also

- [[iam-and-secrets-management]]
- [[network-segmentation]]
- [[agent-identity-and-access]]
- [[ai-specific-security]]
- [[cloud-governance-at-scale]]
- [[compliance-and-regulation]]
- [[kubernetes-at-design-level]]

## Sources

- NIST. (2020). Special Publication 800-207: Zero Trust Architecture. https://csrc.nist.gov/pubs/sp/800/207/final
- NIST. (2020). SP 800-207 PDF. https://nvlpubs.nist.gov/nistpubs/specialpublications/NIST.SP.800-207.pdf
- Gray Group International. (2026). Zero Trust Security Architecture: The 2026 Implementation Guide. https://www.graygroupintl.com/blog/zero-trust-security-architecture/
- Terrazone. (2025). NIST SP 800-207: Complete Guide to Zero Trust Architecture. https://terrazone.io/nist-sp-800-207/
- Mitra, S. et al. (2025). Zero Trust Security Model Implementation in Microservices Using Identity Federation. arXiv:2511.04925. https://arxiv.org/pdf/2511.04925
- Tech Insider. (2026). Zero Trust Architecture: The 2026 Implementation Guide. https://tech-insider.org/zero-trust-architecture-why-every-company-needs-it-in-2026/
