---
title: IAM and Secrets Management
aliases: [IAM, identity and access management, secrets management, RBAC, ABAC, workload identity]
type: concept
domain: security
status: mature
tags: [security, iam, secrets, identity, rbac, abac, workload-identity, dynamic-credentials]
updated: 2026-06-20
sources:
  - "https://aembit.io/blog/why-traditional-iam-is-no-match-for-agentic-ai/"
  - "https://docs.cloud.google.com/iam/docs/workload-identity-federation"
  - "https://www.okta.com/identity-101/role-of-ai-in-iam/"
  - "https://www.ibm.com/think/topics/iam-deployment-guide"
  - "https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html"
  - "https://nhimg.org/faq/what-is-the-difference-between-rbac-and-abac-in-iam-governance/"
---

# IAM and Secrets Management

> [!summary]
> Identity and Access Management (IAM) governs who — and what — can access which resources, expressed through authentication, authorization models (RBAC, ABAC), and least-privilege policies. Secrets management handles the credentials themselves: vaulting, rotating, and distributing API keys, certificates, and tokens while keeping them out of code. Together they are the operational foundation of [[zero-trust-architecture]] and the security backbone of every cloud-native system. In 2026, non-human identities (NHIs) — service accounts, workload identities, AI agents — have surpassed human identities as both the most numerous and the fastest-growing attack surface.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

IAM covers two distinct but inseparable problems:

**Authentication** — proving identity. "Who are you?" Answered by: passwords + MFA, certificates, OIDC tokens, SAML assertions, or biometrics. Authentication proves the principal is who they claim to be.

**Authorization** — granting access. "What are you allowed to do?" Answered by: roles, policies, permission sets. Authorization happens after authentication and determines which resources and operations the authenticated principal may access.

**Secrets management** is the credential lifecycle complement: how are the keys, tokens, and certificates that authentication depends on generated, stored, rotated, distributed to workloads, and revoked?

## Why it matters

Every security breach involves a compromised identity or credential. The pattern is consistent: a phished password, a leaked API key in a GitHub repo, an overprivileged service account exploited after a container escape. IAM and secrets management are not supporting concerns — they are the primary attack surface for cloud infrastructure.

The 2026 expansion: traditional IAM was designed for human users. Cloud-native and AI systems generate orders of magnitude more non-human identities (service accounts, Lambda execution roles, pipeline tokens, agent sessions). NSA's 2026 guideline makes NHI discovery an explicit security requirement; organizations must catalog every service account, API key, certificate, and OAuth client across all environments.

## Key concepts / building blocks

### Authentication models

**MFA (Multi-Factor Authentication):** the baseline for human authentication. Factors: something you know (password), something you have (TOTP, hardware key), something you are (biometric). FIDO2/WebAuthn hardware keys (YubiKey) are phishing-resistant; TOTP is phishable (real-time phishing proxies can intercept codes). For privileged access, hardware keys are the standard.

**SSO (Single Sign-On):** one authentication event grants access to multiple systems. Protocols: SAML 2.0 (enterprise federation, IdP-initiated), OIDC/OAuth 2.0 (cloud-native, developer-friendly). Providers: Okta, Microsoft Entra ID (AAD), Google Workspace, Ping Identity.

**Passwordless:** FIDO2/WebAuthn passkeys replace passwords with public-key cryptography bound to the authenticating device. Phishing-resistant by design; the private key never leaves the device. Broadly supported in 2026 across major platforms (Apple, Google, Microsoft).

### Authorization models

**RBAC (Role-Based Access Control):** permissions are assigned to roles; principals are assigned to roles. "Developer role can read S3 buckets; Admin role can write them." Operationally simple; works well when access patterns align with stable job functions.

**ABAC (Attribute-Based Access Control):** access decisions based on attributes of the subject (user department, clearance level), resource (data classification, sensitivity), action (read, write, delete), and environment (time, location, device posture). More adaptive than RBAC; enables policies like "users from the finance department on managed devices can read financial data during business hours." More complex to implement and requires high-quality attribute data.

**Practical combination:** most systems use RBAC for coarse-grained access (role defines the base permissions) and ABAC conditions for fine-grained refinement (conditions on tags, context, device state). AWS IAM policies and Azure RBAC with conditions both follow this hybrid model.

**Least-privilege principle:** grant the minimum permissions required to perform the task, for the minimum duration needed. Operationalize through:
- Scoped IAM roles (not `AdministratorAccess` for everything)
- Just-in-time (JIT) elevation: elevated access granted on-demand, auto-expires
- Permission boundaries: IAM policies that cap the maximum effective permissions regardless of what roles are attached
- Access reviews: periodic review and revocation of granted permissions

### Workload identity and non-human identity (NHI)

**The static credential problem:** historically, services authenticated to other services using static API keys or passwords stored in environment variables or config files. This is the most common source of credential leaks — keys in Git repos, in container images, in CI/CD logs.

**Workload Identity Federation:** the solution — instead of static credentials, workloads authenticate using their platform identity (an OIDC token issued by the cloud provider or Kubernetes) and exchange it for short-lived access tokens. No static key ever exists.

| Platform | Mechanism | What it replaces |
|---|---|---|
| AWS | IAM Roles for Service Accounts (IRSA) / Pod Identity | Static access keys |
| GCP | Workload Identity Federation (WIF) | Service account key files |
| Azure | Managed Identity / Federated Identity Credential | Client secrets in config |
| Kubernetes | Projected ServiceAccount tokens | Long-lived SA tokens |
| GitHub Actions | OIDC to cloud provider | Static cloud credentials in secrets |

**OAuth 2.0 token exchange (RFC 8693):** standardized protocol for exchanging one token type for another with scoped, short-lived assertions. The foundation of workload identity federation across providers.

**Non-human identity governance:** the NSA 2026 guideline and NIST IR 8596 both emphasize that NHI management — discovery, least-privilege, rotation, and revocation — must be treated with the same rigor as human IAM. Key practices:
- **Inventory first:** catalog every service account, API key, certificate, OAuth client. Cannot govern what you have not discovered.
- **Eliminate static credentials:** replace with workload identity wherever the platform supports it
- **Short TTL:** even where static credentials are unavoidable, rotate them frequently (≤90 days; ≤24 hours for high-sensitivity)
- **Scope tightly:** each workload identity should have only the permissions it needs for its specific function

### Secrets management

**The core problem:** applications need secrets (database passwords, API keys, TLS private keys) at runtime. These must be kept out of: source code, container images, CI/CD logs, environment variables baked into container specs, and anywhere that gets checked in or logged.

**Secrets vaults:**
- **HashiCorp Vault:** the reference open-source secrets engine; dynamic credentials (generates database passwords on demand with TTL), PKI engine (issues short-lived TLS certs), transit encryption-as-a-service. Self-hosted or HCP Vault Secrets (managed).
- **AWS Secrets Manager:** managed; automatic rotation via Lambda; deep AWS integration; charged per secret
- **AWS SSM Parameter Store:** simpler, cheaper; good for config values + non-rotating secrets
- **Azure Key Vault:** managed; certificates, keys, secrets; Managed Identity integration
- **GCP Secret Manager:** managed; versioned; automatic rotation triggers

**Dynamic credentials:** instead of storing a static database password, Vault generates a unique temporary username/password pair for each application instance on demand, valid for the duration of the lease (e.g., 1 hour). When the lease expires, the credentials are automatically revoked. No shared secrets; no rotation scripts; no credential exposure window longer than the lease.

**Secret injection patterns:**
- **Environment variables at runtime** (acceptable; not at build time) — secrets manager SDK or init container injects at container start
- **Mounted volumes** — Vault Agent or CSI secrets store driver mounts secrets as files; applications read files
- **SDK fetch at runtime** — application fetches secrets directly from the vault API using workload identity; enables dynamic rotation without restart

**Anti-pattern to avoid:** secrets in environment variables baked into Dockerfile or Kubernetes Deployment spec YAML checked into Git. The secret becomes part of the image layer history and the repo history.

### Privileged Access Management (PAM)

PAM governs the highest-risk access: production database root, cloud account admin, SSH to production hosts. Key practices:
- **No standing privileged access:** admin rights are not permanently assigned; they are requested, approved (sometimes automated), and auto-expire (JIT PAM)
- **Just-enough access:** production access to read logs only, not to modify data
- **Session recording:** privileged sessions recorded and auditable (CyberArk, BeyondTrust, Teleport for infrastructure access)
- **Break-glass accounts:** emergency admin accounts that exist but are sealed; access triggers an alert and requires dual authorization

### IAM for AI agents

AI agents introduce a new IAM challenge: they act with delegated user authority, may be long-running, and invoke tools with real-world impact. Traditional IAM patterns (roles, static permissions) do not adequately model agent behavior.

Emerging patterns:
- **Delegated authorization scopes:** agents receive only the specific permission subset needed for the current task (not the user's full permissions)
- **Time-bounded sessions:** agent sessions auto-expire; re-authorization required for extended operations
- **Per-action confirmation gates:** sensitive tool invocations (send email, delete record) require human confirmation regardless of agent permissions
- **Agent identity distinct from user identity:** the agent has its own identity and audit trail, separate from the human it serves

See [[agent-identity-and-access]] for the full treatment.

## Design decisions & trade-offs

**RBAC vs. ABAC:**
Default to RBAC — it is simpler to implement, easier to audit, and understandable to operations teams. Add ABAC conditions when RBAC produces too many roles (role explosion) or when access must vary by resource attributes (sensitivity tags, data classification). ABAC only works well when attribute quality is high and policy design is mature.

**Centralized vs. federated identity:**
Large enterprises typically federate: one enterprise IdP (Entra ID, Okta) as the authoritative identity source; cloud providers, SaaS, and internal apps are service providers that trust the IdP's assertions. Avoids per-system credential silos; single off-boarding point. Requires the IdP to be highly available — it becomes a critical dependency for all authentication.

**Self-hosted Vault vs. managed secrets service:**
Vault gives maximum control (dynamic credentials, custom auth backends, multi-cloud) at the cost of operational overhead (HA cluster, unsealing, upgrades). Managed secrets services (AWS Secrets Manager, Azure Key Vault) reduce operational burden for secrets storage and rotation but lack Vault's dynamic credential generation and encryption-as-a-service. For most cloud-native teams: use the cloud provider's managed service for secrets storage + workload identity for service authentication; add Vault only when dynamic credentials or cross-cloud secrets governance justify the operational cost.

## State of the art

Workload identity federation has become the standard for cloud-native NHI authentication — replacing static keys in 2024-2026. GitHub Actions to AWS/GCP/Azure via OIDC is now the default CI/CD credential pattern. FIDO2 passkeys are becoming mainstream for human authentication.

**AI IAM gap:** traditional IAM was not designed for agentic AI. The industry is actively developing standards for agent identity, delegated authorization, and per-action audit. Aembit and similar platforms are purpose-built for NHI and agent identity governance. Expect this space to mature significantly in 2026-2027.

## Pitfalls & anti-patterns

**Static long-lived credentials everywhere.** API keys in `.env` files checked into Git, in container image environment variables, in CI/CD secrets stored as plaintext. Use workload identity and dynamic credentials wherever the platform supports it.

**Over-permissive service roles.** `AdministratorAccess` for a Lambda function that only reads DynamoDB. Every role should have only the permissions actually needed. Audit with AWS IAM Access Analyzer, Azure AD Access Reviews.

**No NHI inventory.** Cannot enforce least privilege or detect anomalous access for credentials you do not know exist. Automated discovery of service accounts and API keys is a prerequisite.

**Shared service accounts.** Multiple services authenticating with the same identity. Eliminates per-service auditability and makes rotation disruptive. Every service gets its own identity.

**Secrets in code.** The most persistent anti-pattern. Pre-commit hooks (git-secrets, Gitleaks, Detect-Secrets) catch secrets before they enter the repo; scanning tools catch them after.

## See also

- [[zero-trust-architecture]]
- [[agent-identity-and-access]]
- [[encryption-and-key-management]]
- [[cloud-governance-at-scale]]
- [[software-supply-chain-security]]
- [[infrastructure-as-code]]

## Sources

- Aembit. (2026). Why Traditional IAM Is No Match for Agentic AI. https://aembit.io/blog/why-traditional-iam-is-no-match-for-agentic-ai/
- Google Cloud. (2026). Workload Identity Federation — IAM Documentation. https://docs.cloud.google.com/iam/docs/workload-identity-federation
- Okta. (2026). The Role of AI in IAM: Securing the Agentic Frontier. https://www.okta.com/identity-101/role-of-ai-in-iam/
- IBM. (2026). Identity and Access Management (IAM) Deployment Guide. https://www.ibm.com/think/topics/iam-deployment-guide
- AWS. (2026). Define Permissions Based on Attributes with ABAC. https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html
- NHIMG. (2026). What Is the Difference Between RBAC and ABAC in IAM Governance? https://nhimg.org/faq/what-is-the-difference-between-rbac-and-abac-in-iam-governance/
