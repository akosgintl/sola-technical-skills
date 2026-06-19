---
title: Confidential Computing
aliases: [confidential computing, TEE, trusted execution environment, PET]
type: concept
domain: emerging
priority: P3
roadmap_ref: "9.4"
status: stub
tags: [emerging, security, privacy, tee]
updated: 2026-06-19
sources: []
---

# Confidential Computing

> [!summary]
> Protecting data while it is being processed by running computation inside hardware-based trusted execution environments that shield it from the host and operator.

**Priority:** 🟢 P3 · **Domain:** [[tier-3-watch|Emerging & Adjacent]] · **Roadmap:** §9.4

## What it is

Confidential computing closes the "data in use" gap left by encryption at rest and in transit. Using hardware Trusted Execution Environments (TEEs) — secure enclaves — code and data are isolated and encrypted in memory even from the cloud provider, with remote attestation proving the environment's integrity. It is a key privacy-enhancing technology for regulated and multi-party workloads.

## Key concepts

- Trusted Execution Environments (Intel SGX/TDX, AMD SEV, Arm CCA)
- Data-in-use protection and memory encryption
- Remote attestation
- Confidential VMs and containers
- Privacy-enhancing technologies (PETs)

## See also

- [[post-quantum-cryptography]]
- [[zero-trust-architecture]]
- [[iam-and-secrets-management]]
- [[compliance-and-regulation]]

## Sources

- _Stub — no sources ingested yet._
