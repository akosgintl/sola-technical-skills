---
title: Software Supply Chain Security
aliases: [supply chain security, SBOM, SLSA, artifact signing, Sigstore, Cosign]
type: concept
domain: platform
status: mature
tags: [platform, security, supply-chain, sbom, slsa, sigstore, cosign, dependency-confusion, provenance]
updated: 2026-06-20
sources:
  - "https://www.practical-devsecops.com/slsa-framework-guide-software-supply-chain-security/"
  - "https://petronellatech.com/blog/signed-sealed-delivered-verifiable-software-supply-chains-with-sboms/"
  - "https://www.trantorinc.com/blog/software-supply-chain-security-sbom-slsa-engineering-actions"
  - "https://aquilax.ai/blog/supply-chain-artifact-signing-slsa"
  - "https://appsecsanta.com/sca-tools/supply-chain-security-tools"
  - "https://faithforgelabs.com/blog_supplychain_security_2025.php"
---

# Software Supply Chain Security

> [!summary]
> Software supply chain security defends the integrity of everything that goes into a production release — open-source dependencies, build systems, CI/CD pipelines, container images, and the artifacts consumers deploy. The attack surface runs from dependency confusion and typosquatting at ingestion to build system compromise at assembly to artifact tampering at distribution. The defensive stack is now standardized: SBOMs for inventory, Sigstore/Cosign for signing, SLSA for build provenance attestation, and SCA scanning for vulnerability detection. Sonatype identified 454,600 new malicious packages in 2025 alone — supply chain is an active, high-volume threat, not a theoretical one.

**Domain:** [[tier-2-solid|Platform Engineering & IaC]]

## What it is

A software supply chain encompasses every component, tool, and process that transforms source code into a running artifact in production: third-party libraries, transitive dependencies, compilers, build scripts, CI runners, container base images, signing keys, and the distribution channels (registries, package managers, CDNs) through which artifacts travel.

Supply chain attacks compromise one node in this chain — typically a dependency or the build infrastructure — to inject malicious code into downstream consumers. The attacker reaches every organization using the compromised component without needing to attack them directly.

Historical incidents that define the threat model:
- **SolarWinds (2020):** build system compromise; malicious code injected into signed, official software updates; 18,000+ organizations affected
- **Log4Shell (2021):** critical vulnerability in an ubiquitous dependency; demonstrated transitive dependency risk
- **XZ Utils (2024):** multi-year social engineering of a maintainer to introduce a backdoor in a compression library included in many Linux distributions
- **GhostAction (March 2025):** GitHub Actions workflow files compromised; CI secrets exfiltrated from thousands of repositories
- **Shai-Hulud npm worm (September 2025):** self-replicating worm spread through npm packages

## Why it matters

Open-source dependencies are now the primary code delivery mechanism — the average enterprise application has 500+ direct and transitive dependencies. Most of that code is never audited; its security is implicitly trusted. Supply chain attacks exploit this trust at scale.

Regulatory drivers have accelerated adoption of supply chain security controls:
- **US Executive Order 14028 (2021):** mandates SBOM for software sold to the US government
- **EU Cyber Resilience Act (CRA, 2025):** requires SBOM and vulnerability disclosure for products with digital elements sold in the EU
- **NIST SSDF (Secure Software Development Framework):** guidance for verifiable build integrity

## Key concepts / building blocks

### SBOM (Software Bill of Materials)

An SBOM is a machine-readable inventory of all software components in an artifact — direct dependencies, transitive dependencies, their versions, licenses, and known vulnerabilities.

**Formats:**
- **SPDX** (Software Package Data Exchange) — Linux Foundation standard; ISO/IEC 5962:2021; preferred for compliance/regulatory use
- **CycloneDX** — OWASP standard; richer security metadata; better tooling ecosystem for security use cases

**What SBOMs enable:**
- **Vulnerability response:** when a new CVE is published, immediately identify which of your systems use the affected component and at what version
- **License compliance:** audit all licenses before shipping
- **Regulatory attestation:** demonstrate to customers/regulators what's in your software

**What SBOMs don't do:** they list components but don't verify that the build actually used those components, or that the build process was not compromised. That's where SLSA comes in.

**Generation tools:** Syft (Anchore), CycloneDX Generator, GitHub Dependency Graph, Grype (pairs with Syft for vulnerability scanning).

### SLSA (Supply-chain Levels for Software Artifacts)

SLSA (pronounced "salsa") is a framework that defines maturity levels for build integrity — verifying *how* a software artifact was produced, not just *what* it contains.

**Four levels:**

| Level | What it requires | Key guarantee |
|---|---|---|
| **SLSA 1** | Build is scripted; provenance generated (not verified) | Provenance exists; tamper-evident |
| **SLSA 2** | Hosted build service; provenance signed by build service | Build service identity is authenticated |
| **SLSA 3** | Hardened build service; non-falsifiable provenance | Build platform cannot be influenced by build scripts |
| **SLSA 4** (draft) | Two-party review; hermetic/reproducible builds | Full audit trail; reproducible |

**Provenance:** a signed attestation that records: the build system identity, the source commit, the build inputs, the build command, and the resulting artifact digest. Consumers verify provenance before using an artifact.

**SLSA GitHub Generator:** GitHub Actions workflow that produces SLSA Level 3 provenance automatically — no custom build infrastructure required. A team can achieve SLSA Level 3 in 1-2 days by adding the generator workflow.

### Sigstore / Cosign

Sigstore is the Linux Foundation project that provides keyless signing infrastructure for open-source and enterprise supply chains.

**Components:**
- **Cosign** — the signing/verification CLI tool; signs container images, OCI artifacts, and arbitrary files
- **Fulcio** — certificate authority that issues short-lived signing certificates tied to OIDC identity (GitHub Actions workflow identity, Google account, etc.); no long-lived private key management required
- **Rekor** — transparency log that records all signing events; immutable, append-only; enables detection of unauthorized signing

**Keyless signing workflow:**
1. Build system authenticates to Fulcio using its OIDC identity (e.g., GitHub Actions workload identity token)
2. Fulcio issues a short-lived certificate valid for ~10 minutes
3. Cosign signs the artifact with the ephemeral key; the signature and certificate are recorded in Rekor
4. The signing certificate expires; the Rekor entry proves the signing happened
5. Consumers verify: `cosign verify` checks the signature against the Rekor entry and the artifact digest

**Container image signing:** sign images at build time in CI; verify signatures in the deployment pipeline (Kubernetes admission controller: policy-controller) before any image is run in production.

**The chain of trust:** SBOM lists what's in the artifact → SLSA provenance attests how it was built → Cosign signature proves the artifact hasn't been tampered with since signing.

### Dependency vulnerability scanning (SCA)

SCA (Software Composition Analysis) identifies known vulnerabilities (CVEs) in dependencies:
- **Grype** (Anchore) — open-source; scans SBOMs, container images, filesystems; fast
- **Trivy** (Aqua Security) — open-source; scans images, repos, IaC; comprehensive
- **Snyk** — managed; PR comments with fix suggestions; IDE integration
- **Dependabot / Renovate** — automated dependency update PRs; addresses CVEs proactively by keeping dependencies current

**Integrate into CI/CD:** scan on every PR and block merges for critical/high CVEs with available fixes. Scan deployed images on a schedule for newly disclosed CVEs in already-deployed software.

### Dependency confusion and typosquatting

**Dependency confusion:** attackers publish a public package with the same name as your internal private package at a higher version number. Package managers that check public registries first will download the malicious public package instead of your internal one.

**Mitigations:**
- Use namespace scoping for internal packages (e.g., `@myorg/package-name`)
- Configure package managers to prefer private registries: `npm config set registry https://your-registry.company.com`
- Use dependency pinning + lock files (never `npm install` without a lockfile in production)
- Block public registry fallback for known-internal package names

**Typosquatting:** malicious packages with names similar to popular packages (`reqeusts` vs. `requests`). Mitigation: dependency review at PR time; SBOM comparison against known-good baseline.

### Build system hardening

A compromised build system is the highest-impact supply chain attack vector (SolarWinds). Defenses:

**Hermetic builds:** the build cannot access the network or external state during compilation; all dependencies are pre-fetched and pinned. Ensures reproducibility and prevents build-time injection.

**Reproducible builds:** given the same inputs, the build always produces the bit-for-bit identical output. Enables independent verification by third parties.

**Least-privilege CI:** CI pipeline tokens have only the minimum permissions needed (read-only to source, write to the specific artifact registry). Never grant `admin` or broad write access to CI service accounts.

**Separate build credentials from deployment credentials:** the token that publishes to the registry is different from the token that deploys from the registry. Compromise of the build pipeline does not automatically grant deployment authority.

**Pin GitHub Actions by commit SHA:** `uses: actions/checkout@v4` is mutable (the action author can change what `v4` points to); `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af68` is pinned to an immutable commit. GhostAction (March 2025) exploited mutable action references.

## Design decisions & trade-offs

**SLSA level to target:**
- **SLSA 1:** low effort; useful for SBOM baseline and provenance generation; achieve in hours
- **SLSA 2:** requires a hosted build service (GitHub Actions, GitLab CI qualify); achievable in days; the current practical standard for teams adopting supply chain security
- **SLSA 3:** stricter build service requirements; GitHub Actions + SLSA GitHub Generator achieves this automatically; recommended for any team shipping to regulated industries or enterprise customers
- **SLSA 4:** hermetic/reproducible builds; significant engineering investment; justified for critical infrastructure software

**Keyless vs. key-based signing:**
Keyless signing (Sigstore/Fulcio) eliminates long-lived private key management — a major operational burden and risk. The Rekor transparency log provides the audit trail. Key-based signing (traditional GPG or HSM-backed keys) is required in air-gapped environments where Sigstore's public infrastructure is unreachable. For cloud-native public-facing software: prefer keyless. For air-gapped: key-based with HSM.

**Mandatory vs. advisory policy enforcement:**
Start with advisory (log and alert on unsigned or unattested images) before making it blocking. Enforce blocking in staging first; validate that all production images are signed before flipping enforcement in production. A policy that blocks all unattested images before the signing pipeline is complete locks out all deployments.

## State of the art

Supply chain security has crossed from specialist practice to mainstream enterprise requirement in 2025-2026, driven by US EO 14028, EU CRA, and documented high-profile incidents. Sigstore and SLSA are now integrated into GitHub, GitLab, and most major CI platforms with minimal configuration.

Sonatype's 2025 data: 454,600 new malicious packages identified; cumulative malware exceeds 1.233 million packages across npm, PyPI, and Maven. The volume is accelerating.

**AI-generated code risk (2026 frontier):** AI code assistants recommend and generate dependency imports. If the model was trained on malicious packages or hallucinates non-existent package names, developers may unwittingly install malware. SBOM generation and SCA scanning catch these post-introduction; proactive controls (verify package before installing) are needed earlier.

**Model supply chain:** the same principles apply to ML model supply chains — model weight files can be backdoored, Hugging Face models have been found containing embedded code. See [[model-supply-chain-security]].

## Pitfalls & anti-patterns

**Mutable action/image references.** Using `@v4` or `latest` tags in CI pipelines. The referenced content can change without notice. Pin to immutable commit SHAs or image digests.

**SBOM as checkbox, not tooling.** Generating SBOMs at release time manually and storing them in a spreadsheet. SBOMs are useful only when they're machine-readable, stored alongside artifacts, and automatically compared against CVE feeds. Integrate generation and scanning into CI.

**No transitive dependency scanning.** Scanning only direct dependencies. The most impactful vulnerabilities (Log4Shell) are often in transitive dependencies several layers deep. Ensure the SCA tool resolves and scans the full dependency tree.

**CI with admin credentials.** GitHub Actions tokens with `permissions: write-all` or CI service accounts with organization-level admin access. A compromised CI pipeline with admin access can tamper with any repository, publish any package, or exfiltrate any secret. Apply least privilege: grant only what the specific job needs.

**Trusting build artifacts without verification.** Deploying container images to production without verifying their signature and provenance. Enable Kubernetes admission control (policy-controller, Kyverno, OPA Gatekeeper) to reject unsigned or unattested images.

## See also

- [[cicd-pipeline-architecture]]
- [[policy-as-code]]
- [[model-supply-chain-security]]
- [[infrastructure-as-code]]
- [[iam-and-secrets-management]]

## Sources

- Practical DevSecOps. (2026). SLSA Framework Guide 2026 — Secure Your Software Supply Chain. https://www.practical-devsecops.com/slsa-framework-guide-software-supply-chain-security/
- Petronella Cybersecurity. (2026). SBOMs + SLSA + Sigstore: Verify Your Supply Chain. https://petronellatech.com/blog/signed-sealed-delivered-verifiable-software-supply-chains-with-sboms/
- Trantor. (2026). Software Supply Chain Security: SBOM, SLSA & Actions. https://www.trantorinc.com/blog/software-supply-chain-security-sbom-slsa-engineering-actions
- AquilaX. (2026). Software Supply Chain Security Beyond SBOMs: Sigstore, SLSA, and Build Provenance. https://aquilax.ai/blog/supply-chain-artifact-signing-slsa
- AppSec Santa. (2026). Supply Chain Security Tools 2026. https://appsecsanta.com/sca-tools/supply-chain-security-tools
- Faith Forge Labs. (2025). Software Supply Chain Security in 2025: SBOMs, SLSA & Sigstore From Buzzwords to Baseline. https://faithforgelabs.com/blog_supplychain_security_2025.php
