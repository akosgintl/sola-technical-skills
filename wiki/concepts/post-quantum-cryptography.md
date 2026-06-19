---
title: Post-Quantum Cryptography
aliases: [PQC, post-quantum cryptography, quantum-safe crypto]
type: concept
domain: emerging
priority: P3
roadmap_ref: "9.6"
status: stub
tags: [emerging, security, cryptography, quantum]
updated: 2026-06-19
sources: []
---

# Post-Quantum Cryptography

> [!summary]
> Cryptographic algorithms designed to remain secure against attacks by future large-scale quantum computers, replacing today's vulnerable public-key schemes.

**Priority:** 🟢 P3 · **Domain:** [[tier-3-watch|Emerging & Adjacent]] · **Roadmap:** §9.6

## What it is

Post-quantum cryptography (PQC) covers algorithms believed resistant to quantum attacks such as Shor's algorithm, which would break RSA and elliptic-curve cryptography. NIST has standardized initial schemes (e.g. ML-KEM/Kyber for key exchange, ML-DSA/Dilithium for signatures). The architectural priority is crypto-agility and addressing "harvest now, decrypt later" risk for long-lived secrets.

## Key concepts

- Quantum threat to RSA/ECC (Shor's algorithm)
- NIST PQC standards (ML-KEM, ML-DSA, SLH-DSA)
- "Harvest now, decrypt later" risk
- Crypto-agility and hybrid deployments
- Migration planning for long-lived data

## See also

- [[confidential-computing]]
- [[iam-and-secrets-management]]
- [[zero-trust-architecture]]
- [[compliance-and-regulation]]

## Sources

- _Stub — no sources ingested yet._
