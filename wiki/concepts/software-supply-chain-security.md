---
title: Software Supply Chain Security
aliases: [supply chain security, SBOM, SLSA, artifact signing]
type: concept
domain: platform
priority: P1
roadmap_ref: "4.4.2"
status: stub
tags: [platform, security, supply-chain, sbom]
updated: 2026-06-19
sources: []
---

# Software Supply Chain Security

> [!summary]
> Securing the integrity of everything that goes into a release — dependencies, build systems, and artifacts — through inventory, signing, and verifiable provenance.

**Priority:** 🟠 P1 · **Domain:** [[tier-2-solid|Platform Engineering & IaC]] · **Roadmap:** §4.4.2

## What it is

Software supply chain security defends against tampering between source and deployment. It combines dependency inventory (SBOMs), cryptographic signing of artifacts, and attestation of how artifacts were built so consumers can verify provenance. Frameworks like SLSA define maturity levels for build integrity.

## Key concepts

- SBOM (Software Bill of Materials) — CycloneDX, SPDX
- Artifact signing — Sigstore / cosign
- Build provenance and attestation; SLSA framework
- Dependency and vulnerability scanning
- Trusted builders and hermetic builds

## See also

- [[cicd-pipeline-architecture]]
- [[policy-as-code]]
- [[model-supply-chain-security]]
- [[infrastructure-as-code]]

## Sources

- _Stub — no sources ingested yet._
