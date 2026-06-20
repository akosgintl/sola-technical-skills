---
title: Encryption & Key Management
aliases: [encryption at rest, encryption in transit, key management, KMS, HSM, TLS]
type: concept
domain: security
status: stub
tags: [encryption, key-management, kms, hsm, tls, cryptography, secrets]
updated: 2026-06-20
sources: []
---

# Encryption & Key Management

> [!summary]
> Encryption at rest and in transit is the baseline of data protection — it ensures that even if storage or network channels are compromised, raw data is unusable without the keys. Key management is where the complexity lives: how keys are generated, rotated, stored, and scoped is what separates nominal compliance from genuine security. In AI systems, key management extends to protecting model weights, inference endpoints, and training data pipelines.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Encryption at rest protects stored data (databases, object storage, block volumes, backups) using symmetric ciphers (AES-256 is the current standard). Encryption in transit uses TLS 1.3 to protect data moving between services, clients, and networks. Key Management Systems (KMS) — cloud-native (AWS KMS, Azure Key Vault, GCP Cloud KMS) or on-prem/HSM-backed — handle key lifecycle: creation, rotation, revocation, and audit.

## Why it matters

- ...

## Key concepts / building blocks

- **Envelope encryption** — data encrypted by a Data Encryption Key (DEK); DEK encrypted by a Key Encryption Key (KEK) held in KMS
- **Key rotation** — automatic periodic rotation limits blast radius of key compromise
- **Hardware Security Modules (HSMs)** — tamper-resistant hardware for key generation and storage
- **TLS 1.3** — current transport standard; eliminates legacy cipher suites and forward secrecy gaps
- **Mutual TLS (mTLS)** — both sides present certificates; the foundation of service mesh security
- **Customer-managed keys (CMK)** — tenant owns the KEK, cloud provider cannot decrypt at rest
- **Secrets management** — runtime injection of credentials/keys via Vault, AWS Secrets Manager, etc.

## Design decisions & trade-offs

> [!todo] verify

## State of the art

> [!todo] verify

## Pitfalls & anti-patterns

- Hard-coding secrets in source code or container images
- Long-lived static keys with no rotation schedule
- Encrypting data but logging it in plaintext (audit logs, debug output)
- Trusting TLS termination at the load balancer but transmitting cleartext internally (not zero-trust)
- Using customer-managed keys without an operational runbook for key loss (permanent data loss risk)

## See also

- [[zero-trust-architecture]]
- [[iam-and-secrets-management]]
- [[compliance-and-regulation]]
- [[ai-specific-security]]
- [[model-supply-chain-security]]
- [[confidential-computing]]

## Sources

