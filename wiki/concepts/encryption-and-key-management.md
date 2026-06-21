---
title: Encryption & Key Management
aliases: [encryption at rest, encryption in transit, key management, KMS, HSM, TLS, envelope encryption]
type: concept
domain: security
status: mature
tags: [encryption, key-management, kms, hsm, tls, cryptography, secrets, pqc]
updated: 2026-06-21
sources:
  - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-52r2.pdf
  - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57pt1r5.pdf
  - https://csrc.nist.gov/pubs/fips/203/final
  - https://docs.aws.amazon.com/kms/latest/developerguide/overview.html
  - https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.140-3.pdf
  - https://datatracker.ietf.org/doc/html/rfc8446
---

# Encryption & Key Management

> [!summary]
> Encryption at rest and in transit is the non-negotiable baseline of data protection; key management is where security actually lives. How keys are generated, rotated, scoped, and protected determines whether encryption is nominal compliance or genuine defence — and the key hierarchy, not the cipher choice, is where architects should focus their attention.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Encryption converts plaintext into ciphertext readable only with the correct key. The cipher choice matters but is rarely the architect's decision: AES-256-GCM for symmetric encryption and TLS 1.3 for transport are the current standards, and cloud platforms apply them by default. What architects control is the **key management architecture**: who owns the keys, how they are stored, how long they live, how they are rotated, and how they are scoped to specific data or services.

The central insight: encrypting data with a poorly managed key provides weak security. An attacker who compromises a long-lived, widely scoped root key has access to everything protected by it. Key management is therefore the discipline of minimising blast radius — both of key compromise and of operational errors like accidental deletion.

## Why it matters

Encryption at rest is mandatory for most compliance frameworks (GDPR, HIPAA, PCI DSS 4.0, SOC 2 Type II, FedRAMP). But compliance and security are not the same thing. Provider-managed default encryption (SSE-S3, Google-managed keys) satisfies audit checkboxes while giving the cloud provider the ability to decrypt the data. Customer-managed keys (CMK) via a dedicated KMS are required wherever data sovereignty or tenant isolation is a real constraint — regulated industries, multi-tenant SaaS, and any context where the cloud provider must provably be unable to read the data.

For AI workloads specifically, key management extends to: protecting model weights in object storage (a leaked weight is a leaked capability and potentially a training-data leak), encrypting inference traffic between orchestrators and model servers, and securing feature stores and training pipelines that handle PII or confidential business data.

The post-quantum threat adds a time-horizon consideration: data encrypted today with RSA-2048 or ECDSA keys is harvestable now for decryption once a cryptographically relevant quantum computer exists. NIST published its first post-quantum cryptography (PQC) standards in August 2024 (FIPS 203/204/205). Migration planning should begin now for long-retention sensitive data.

## Key concepts

### Envelope encryption

The standard key hierarchy used by every cloud KMS:

```
Data Encryption Key (DEK)  ──encrypts──▶  ciphertext (stored with data)
Key Encryption Key (KEK)   ──encrypts──▶  encrypted DEK (stored alongside ciphertext)
Root Key (in KMS/HSM)      ──encrypts──▶  KEK
```

At read time: KMS decrypts the KEK using the root key; the KEK decrypts the DEK; the DEK decrypts the data. At no point does the root key leave the KMS (or HSM). This design means:

- **Key rotation** changes the KEK without re-encrypting the data (only the encrypted DEK needs re-wrapping).
- **Blast radius of key compromise** is scoped: compromise of one DEK exposes one dataset, not the whole keystore.
- **Separation of duties**: the entity that holds the data never holds the root key.

### KMS options

| Product | Type | FIPS 140 | CMK support | Notable capability |
|---|---|---|---|---|
| AWS KMS | Cloud-native | Level 3 (HSM-backed) | Yes (CMK + key policies) | Automatic annual rotation; key grants for cross-account |
| Azure Key Vault | Cloud-native | Level 3 (Premium SKU) | Yes | Managed HSM SKU for dedicated hardware; BYOK |
| GCP Cloud KMS | Cloud-native | Level 1 (software); Level 3 (Cloud HSM) | Yes | External key manager (EKM) for keys outside GCP |
| HashiCorp Vault | Self-hosted/cloud | Level 1 (software) | N/A — Vault is the KMS | Transit secrets engine; dynamic secrets; namespace isolation |
| AWS CloudHSM | Dedicated HSM | Level 3 | N/A — customer manages keys directly | Exclusive single-tenant hardware; PKCS#11/JCE interface |
| Azure Managed HSM | Dedicated HSM | Level 3 | Yes | MHSM security domain; quorum activation |

**Key choice heuristics:**
- Default cloud KMS (AWS KMS / Azure Key Vault / GCP KMS) satisfies most compliance requirements with low operational overhead.
- Customer-managed keys via KMS are required for regulated data sovereignty or multi-tenant isolation.
- Dedicated HSM (CloudHSM, Managed HSM) is required where the cloud provider must be physically excluded from key access (government, some financial regulations).
- HashiCorp Vault is the choice for multi-cloud or hybrid environments, or where dynamic short-lived secrets (database credentials, PKI certificates) need centralised management.

### TLS 1.3 and mTLS

TLS 1.3 (RFC 8446, 2018) is the current transport standard. Compared to TLS 1.2: removes RSA key exchange and static DH (no forward secrecy); mandates ephemeral key exchange (ECDHE) ensuring forward secrecy for all sessions; eliminates legacy cipher suites (RC4, 3DES, MD5); reduces handshake from 2 round trips to 1. NIST SP 800-52 Rev 2 requires TLS 1.2 as minimum and recommends TLS 1.3 for all new implementations.

**Mutual TLS (mTLS):** both endpoints present certificates for authentication. Where standard TLS authenticates only the server, mTLS authenticates both. It is the foundation of service mesh east-west security (Istio, Linkerd, Cilium) and the implementation mechanism for zero-trust east-west — even within a VPC, services prove identity before communicating.

TLS certificate lifecycle is a common operational failure point. cert-manager (Kubernetes) automates certificate issuance and renewal via ACME (Let's Encrypt) or internal PKI (Vault, AWS PCA). Unmonitored certificate expiry causes outages and is the root cause of a large fraction of production TLS incidents.

### Secrets management

Runtime secrets (database passwords, API keys, OAuth tokens) must never be stored in environment variables in plain form, in container images, or in version control. The production pattern: secrets are injected at runtime from a secrets store, as close to the point of use as possible, and are short-lived.

Two patterns:

**Dynamic secrets (HashiCorp Vault):** Vault generates a unique credential per request with a TTL. When the TTL expires, the credential is revoked automatically. A compromised dynamic credential has a bounded window of usefulness proportional to the TTL (typically minutes to hours). The application never sees a long-lived password.

**Static secrets with rotation:** Cloud secrets managers (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager) store credentials and trigger rotation on a schedule. The application fetches the secret at startup or on reference; the manager handles the rotation and version management. Rotation interval should be ≤90 days; 24 hours is achievable for credentials that support it.

### Post-quantum cryptography

NIST published three PQC standards in August 2024:
- **FIPS 203** — ML-KEM (Module Lattice Key Encapsulation Mechanism, based on CRYSTALS-Kyber): replaces RSA/ECDH for key exchange.
- **FIPS 204** — ML-DSA (Module Lattice Digital Signature Algorithm, based on CRYSTALS-Dilithium): replaces ECDSA/RSA for signatures.
- **FIPS 205** — SLH-DSA (Stateless Hash-Based DSA, based on SPHINCS+): hash-based signature alternative.

"Harvest now, decrypt later" attacks are already underway for high-value data. Priority migration: TLS for long-lived sessions, certificate issuance PKI, and any data with a confidentiality requirement extending past ~2030. AWS, Google, and Cloudflare have begun deploying hybrid TLS (classical + ML-KEM) on their infrastructure.

### AI workload encryption

- **Model weights** at rest: store in KMS-encrypted object storage with CMK scoped to the model serving service account only.
- **Inference traffic** in transit: mTLS between orchestrator and model server; TLS 1.3 for external API endpoints; no plaintext inference traffic even within a VPC.
- **Training data**: same encryption at rest requirements as production PII; training pipelines often access sensitive data and require the same access controls as the downstream model.
- **Gradient and checkpoint files**: encrypt in object storage; checkpoint files can contain memorised training data and should be treated as sensitive.

## Design decisions and trade-offs

**Provider-managed vs. customer-managed keys.** Provider-managed keys (default) are zero-operational-overhead and satisfy most audit requirements. CMK gives the customer control of the key lifecycle — including the ability to revoke access to all data by deleting or disabling the key — but introduces a new operational risk: losing the CMK means losing access to the data permanently. A CMK deployment requires a key recovery procedure, documented and tested.

**Software KMS vs. HSM.** Software KMS (standard AWS KMS, Azure Key Vault Standard) is sufficient for most workloads. Hardware HSM (FIPS 140-3 Level 3) adds tamper-resistance and is required for certain regulated environments (FIPS validation, some government contracts, PCI HSM for PIN processing). The cost jump is significant (~10× for dedicated HSM vs. shared KMS).

**Key scope width.** Broad key scope (one key for all S3 buckets) minimises operational complexity but maximises blast radius. Narrow scope (per-tenant, per-service keys) limits blast radius but multiplies key management operational burden. The right granularity is typically per-data-classification tier, not per-object.

**Rotation frequency.** NIST SP 800-57 recommends rotation intervals based on key type and usage volume. For symmetric data encryption keys: annual automatic rotation is the cloud KMS default; 90-day rotation is defensible for high-sensitivity workloads. Rotation more frequent than the application's deployment cadence creates operational complexity without proportional security benefit.

## State of the art

AWS KMS now supports automatic rotation with configurable intervals (from 90 days), on-demand rotation, and asymmetric key support (RSA, ECC, SM2). Azure Key Vault Premium offers FIPS 140-3 Level 3 validation with Managed HSM. GCP External Key Manager enables Bring Your Own Key (BYOK) where the encryption key never enters GCP — the most aggressive sovereignty option.

HashiCorp Vault 1.16 (2025) shipped improved dynamic secret backends for Kubernetes secrets, database credentials, and PKI, plus namespace-level isolation for enterprise multi-tenancy.

Cloudflare, AWS, and Google began hybrid TLS (X25519 + ML-KEM-768) deployment in 2024, providing quantum-resistant key exchange without waiting for client software updates. Support for ML-KEM in TLS 1.3 is standardised in RFC 9180.

cert-manager v1.14 (2025) added ML-DSA certificate issuance support for internal PKI, enabling post-quantum signatures in service mesh certificate chains.

> [!warning]
> Customer-managed key deletion is immediate and irreversible in most cloud KMS implementations. A key deletion without a recovery plan results in permanent data loss. Enforce a deletion waiting period (AWS KMS default: 7–30 days; Azure Key Vault: 7–90 day soft-delete) and restrict the `DeleteKey` / `kms:ScheduleKeyDeletion` permission to a break-glass principal.

## Pitfalls and anti-patterns

- **Secrets in source code or container images.** Detected by secret scanners (Trufflehog, GitLeaks, Semgrep); exploited trivially if the repo is ever exposed.
- **Long-lived static keys with no rotation.** A compromised key discovered 18 months after issuance has 18 months of blast radius.
- **Encrypting data but logging it in plaintext.** Application logs, CloudTrail events, and debug output regularly capture the plaintext of fields they are meant to protect.
- **TLS termination at the load balancer with cleartext internally.** Satisfies perimeter encryption; provides no protection for east-west traffic compromise or insider threat. Not zero-trust.
- **No CMK deletion protection.** Accidental or malicious key deletion causes permanent data loss. Deletion waiting periods and MFA-protected delete permissions are the safeguard.
- **No certificate expiry monitoring.** TLS certificate expiry is among the most preventable production outages. Monitor expiry with ≥30-day warning; automate renewal.
- **PQC deferral for long-lived sensitive data.** Data encrypted today with RSA-2048 may be harvestable now and decryptable post-quantum. Inventory data with long confidentiality requirements and begin migration planning.

## See also

- [[zero-trust-architecture]] — mTLS and identity-based access as ZTA network enforcement
- [[iam-and-secrets-management]] — credential management and the IAM layer above KMS
- [[network-segmentation]] — east-west encryption enforcement via service mesh
- [[compliance-and-regulation]] — regulatory requirements driving encryption choices
- [[ai-specific-security]] — model weight protection and inference endpoint security
- [[confidential-computing]] — hardware-level encryption of data in use (beyond at-rest and in-transit)
- [[post-quantum-cryptography]] — migration path for quantum-resistant algorithms

## Sources

- NIST (2019). *SP 800-52 Rev 2 — Guidelines for TLS Implementations.* https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-52r2.pdf
- NIST (2020). *SP 800-57 Part 1 Rev 5 — Recommendation for Key Management.* https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-57pt1r5.pdf
- NIST (2024). *FIPS 203 — Module-Lattice-Based Key-Encapsulation Mechanism Standard (ML-KEM).* https://csrc.nist.gov/pubs/fips/203/final
- AWS (2024). *AWS Key Management Service Developer Guide.* https://docs.aws.amazon.com/kms/latest/developerguide/overview.html
- NIST (2019). *FIPS 140-3 — Security Requirements for Cryptographic Modules.* https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.140-3.pdf
- IETF (2018). *RFC 8446 — The Transport Layer Security (TLS) Protocol Version 1.3.* https://datatracker.ietf.org/doc/html/rfc8446
