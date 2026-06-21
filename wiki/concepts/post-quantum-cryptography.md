---
title: Post-Quantum Cryptography
aliases: [PQC, post-quantum cryptography, quantum-safe crypto, quantum-resistant cryptography]
type: concept
domain: emerging
status: mature
tags: [emerging, security, cryptography, quantum, nist-pqc, ml-kem, crypto-agility]
updated: 2026-06-21
sources:
  - https://csrc.nist.gov/pubs/fips/203/final
  - https://csrc.nist.gov/pubs/fips/204/final
  - https://csrc.nist.gov/pubs/fips/205/final
  - https://media.defense.gov/2022/Sep/07/2003071834/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF
  - https://blog.cloudflare.com/pq-2024/
  - https://nvlpubs.nist.gov/nistpubs/ir/2024/NIST.IR.8547.ipd.pdf
---

# Post-Quantum Cryptography

> [!summary]
> Post-quantum cryptography replaces the public-key algorithms (RSA, ECDSA, ECDH) that a large-scale quantum computer could break, with algorithms designed to remain secure against both classical and quantum attacks. Migration planning is urgent for long-retention sensitive data — the "harvest now, decrypt later" threat is already underway regardless of when quantum computers arrive.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

Today's asymmetric cryptography relies on mathematical problems — integer factorisation (RSA) and elliptic curve discrete logarithm (ECDSA, ECDH) — that are computationally infeasible for classical computers to solve at the key sizes in use. Peter Shor's 1994 algorithm demonstrated that a sufficiently large quantum computer could solve both problems in polynomial time, rendering RSA-2048 and ECDSA-256 insecure. Symmetric ciphers (AES) and hash functions (SHA-2/3) are weakened but not broken by quantum — Grover's algorithm provides a quadratic speedup for brute-force search, effectively halving the security level (AES-128 → 64-bit security), which is addressed by moving to 256-bit keys.

Post-quantum cryptography (PQC) is the field of designing and standardising cryptographic algorithms based on mathematical problems believed to be hard for both classical and quantum computers — primarily lattice problems, hash functions, and error-correcting code problems. NIST completed its first PQC standardisation round in August 2024 with three published standards, ending an 8-year process that began in 2016.

## Why it matters

**The harvest now, decrypt later (HNDL) threat is already active.** Nation-state adversaries are assumed to be collecting encrypted network traffic today — TLS sessions, VPN tunnels, encrypted email — with the intent of decrypting it once a cryptographically relevant quantum computer (CRQC) is available. Any data that must remain confidential for more than the expected CRQC timeline is already at risk. "Store now, decrypt later" has been named by the NSA, CISA, and GCHQ as a current operational threat.

**CRQC timeline estimates.** No expert consensus exists. Estimates range from 10 to 30+ years for a CRQC capable of breaking RSA-2048. The NSA's CNSA Suite 2.0 (September 2022) set 2030 as the target date to begin requiring PQC for National Security Systems, and 2033 as the mandate deadline. NIST IR 8547 (2024) notes that migration timelines for large organisations typically require 5–10 years. The implication: planning should begin now regardless of the CRQC timeline, because the migration itself takes years.

**Regulatory momentum.** US OMB M-23-02 directs federal agencies to inventory their cryptographic dependencies and begin PQC migration planning. CNSA Suite 2.0 mandates PQC for NSS software and systems. The EU's ENISA has published PQC guidance and expects member state critical infrastructure to begin migration. PCI DSS v4's roadmap will include PQC requirements in a future revision.

## Key concepts

### What quantum breaks and what it doesn't

| Algorithm class | Specific algorithms | Quantum impact |
|---|---|---|
| Asymmetric encryption / KEM | RSA-2048/4096, ECDH (P-256, P-384), X25519 | Broken by Shor's algorithm |
| Digital signatures | ECDSA (P-256, P-384), RSA-PSS, EdDSA (Ed25519) | Broken by Shor's algorithm |
| Symmetric encryption | AES-128, AES-256 | Weakened by Grover's (halved security); AES-256 → 128-bit effective |
| Hash functions | SHA-256, SHA-384, SHA-512, SHA-3 | Weakened by Grover's; SHA-384/SHA-512 remain adequate |
| Key derivation | HKDF, PBKDF2, bcrypt | Generally survive at ≥256-bit output |

**What to replace:** all RSA and elliptic curve key exchange and signature schemes. **What to keep (with key size uplift):** AES-256, SHA-384 / SHA-512. **What to do now:** for symmetric systems, transition from AES-128 to AES-256 and from SHA-256 to SHA-384 as a near-term low-cost migration; this addresses the Grover weakening without waiting for CRQC.

### NIST PQC standards (August 2024)

**FIPS 203 — ML-KEM** (Module Lattice Key Encapsulation Mechanism, based on CRYSTALS-Kyber):
- Replaces ECDH and RSA for key encapsulation / key exchange
- Three parameter sets: ML-KEM-512 (NIST Level 1, ~128-bit classical), ML-KEM-768 (Level 3, ~192-bit), ML-KEM-1024 (Level 5, ~256-bit)
- TLS 1.3 integration: ML-KEM-768 (X25519MLKEM768) is the recommended hybrid for TLS; standardised via IETF RFC drafts
- Performance: fast key generation and encapsulation; ciphertext size ~1 KB (vs. ~32 bytes for X25519)

**FIPS 204 — ML-DSA** (Module Lattice Digital Signature Algorithm, based on CRYSTALS-Dilithium):
- Replaces ECDSA, EdDSA, RSA-PSS for signatures
- Three parameter sets: ML-DSA-44 (Level 2), ML-DSA-65 (Level 3), ML-DSA-87 (Level 5)
- Signature size: 2.4–4.6 KB (vs. 64 bytes for Ed25519) — larger but acceptable for certificate chains
- Used for code signing, TLS certificates, document signing

**FIPS 205 — SLH-DSA** (Stateless Hash-Based DSA, based on SPHINCS+):
- Alternative signature scheme based on hash functions rather than lattices
- Security relies only on hash function security — no lattice assumptions needed
- Larger signatures (8–50 KB) and slower; intended as a conservative fallback if lattice security is weakened
- Suitable for long-lived signatures (software releases, legal documents, certificate authorities)

**Backup standards in progress:** HQC (code-based KEM, NIST round 4 finalist), BIKE (code-based), Classic McEliece (code-based, very mature but very large keys ~260 KB public key).

### Hybrid deployment

Hybrid cryptography combines a classical algorithm and a PQC algorithm, providing security if either one holds. If PQC algorithms have undiscovered weaknesses (as SIKE/SIDH was broken in 2022), the classical component maintains security. If quantum computers arrive sooner than expected, the PQC component maintains security.

Standard hybrid patterns:
- **TLS key exchange:** X25519 + ML-KEM-768 combined via HKDF. Implemented as `X25519MLKEM768` in IETF drafts. Cloudflare, AWS, and Google deployed this in 2024.
- **Certificate signatures:** during transition, certificates may be signed with both ECDSA and ML-DSA (dual-certificate pattern), with clients selecting the algorithm they support.

Hybrid adds modest overhead: one additional key encapsulation operation per TLS handshake, approximately 1 KB of additional data. Acceptable for most applications.

### Crypto-agility

Crypto-agility is the design property of a system where the cryptographic algorithm can be updated without architectural change. Systems that hardcode a specific algorithm (RSA-2048 key size, specific curve) require code changes and redeployments for every algorithm migration. Crypto-agile systems parameterise the algorithm choice and can adopt new algorithms by configuration.

Design patterns for crypto-agility:
- **Algorithm negotiation:** TLS already does this for cipher suites. The client advertises supported algorithms; the server selects the best common option.
- **Key type abstraction:** key management systems (AWS KMS, Vault) abstract the key type from the consuming application. Migrating to ML-KEM keys in KMS should not require application code changes.
- **Certificate authority agility:** if the PKI infrastructure can issue both ECDSA and ML-DSA certificates, clients can be migrated algorithmically without infrastructure replacement.

The NIST SP 800-57 recommendation: design new systems with crypto-agility from day one; audit existing systems for algorithm hardcoding as part of the migration inventory.

### Migration priority matrix

Not all systems need to migrate at the same pace. Priority is determined by two factors: how long must the data remain confidential (sensitivity window), and how long until migration is complete (lead time).

| Data sensitivity window | Examples | Priority |
|---|---|---|
| > 20 years | Medical records, financial history, classified government data, intellectual property | **Immediate** — HNDL risk is active |
| 10–20 years | Business strategy documents, personal data, legal records | **High** — begin within 12 months |
| 5–10 years | Session tokens, short-lived credentials, transient communications | **Medium** — migrate in next major cycle |
| < 5 years | Ephemeral session data, cached tokens | **Low** — migrate with TLS update |

For key exchange (TLS), the priority is uniformly high: a session encrypted today with X25519 only is vulnerable to HNDL attack regardless of what the data contains, because the adversary stores the entire session and the data may be sensitive in ways not visible at collection time.

For signatures (certificates, code signing), the priority is tied to the validity period: a certificate valid for 1 year needs migration within 1 year; a root CA certificate valid for 30 years needs migration now.

## Design decisions and trade-offs

**When to deploy hybrid vs. pure PQC.** Hybrid provides defence against PQC algorithm weaknesses; pure PQC eliminates the classical algorithm's quantum vulnerability. For TLS (short sessions), hybrid is the right default now — it provides quantum resistance while retaining classical security during the transition. For long-term certificates and data at rest, moving to pure PQC (or dual-signed certificates) as soon as software support permits is appropriate for high-sensitivity data.

**ML-KEM-768 vs. ML-KEM-1024.** ML-KEM-768 provides NIST security level 3 (~AES-192 equivalent); ML-KEM-1024 provides level 5 (~AES-256). For TLS, ML-KEM-768 is the recommended default — the overhead of ML-KEM-1024 is not justified by the incremental security benefit for typical web traffic. High-assurance government and financial systems may specify ML-KEM-1024.

**Signature algorithm choice: ML-DSA vs. SLH-DSA.** ML-DSA is faster with smaller signatures; SLH-DSA has more conservative security assumptions (relies only on hash functions). For new deployments, ML-DSA-65 is the pragmatic choice. SLH-DSA is appropriate for long-lived high-assurance signatures (CA root certificates, software release signing) where conservative security matters more than performance.

**Migration completeness vs. urgency.** Prioritising the highest-risk data (long retention + sensitive) for immediate migration, while scheduling general migration over 3–5 years, is the rational approach. Full migration in parallel creates integration and testing risk with no proportionate security benefit.

## State of the art

**TLS hybrid deployment (2024–2026).** Cloudflare began deploying X25519MLKEM768 hybrid TLS in 2024; Google Chrome and Firefox added support; AWS CloudFront and AWS IoT Core followed. As of mid-2026, most major CDNs and cloud providers support hybrid TLS on their frontends. End-to-end ML-KEM TLS between services requires library support (OpenSSL 3.5+, BoringSSL, rustls).

**Certificate ecosystem.** Let's Encrypt and AWS ACM have begun testing ML-DSA certificate issuance. Browser root programmes (Mozilla, Apple, Google, Microsoft) are in the process of accepting ML-DSA root CAs. The transition for the web PKI is expected 2026–2028.

**OpenSSH 9.0+** (2022) added CRYSTALS-Kyber (pre-standardisation) hybrid key exchange; post-standardisation ML-KEM support is in active development. SSH key authentication using ML-DSA is expected in OpenSSH 9.x releases.

**cert-manager** (Kubernetes) added experimental ML-DSA certificate issuance support in 2025, enabling PQC certificates in service mesh PKI chains.

**NIST IR 8547 ipd (2024):** transition timeline guidance — NIST recommends that organisations plan for ML-KEM and ML-DSA deployment to be complete by 2030 for most applications, with RSA and ECDH deprecated in FIPS contexts by 2030 and disallowed by 2035.

> [!warning]
> SIKE/SIDH (isogeny-based KEM) was broken by a classical attack in 2022 — a reminder that PQC candidate algorithms can fall. This is the primary argument for hybrid deployment during the transition: do not replace classical algorithms with PQC until the PQC algorithm has been standardised and has years of public cryptanalysis without successful attack. ML-KEM, ML-DSA, and SLH-DSA have all been through 8 years of NIST's process; they are the appropriate choices.

## Pitfalls and anti-patterns

- **"We'll migrate when quantum computers arrive."** HNDL attacks collect encrypted data now; the threat is present regardless of when a CRQC is built. Long-retention sensitive data is at risk today.
- **Treating PQC as a future project.** Migration from RSA/ECDH to ML-KEM requires software library updates, protocol changes, certificate re-issuance, and testing. In large organisations, this is a 3–5 year programme. Starting in 2028 means finishing in 2031–2033 — within the CNSA Suite 2.0 mandate window, but without any margin.
- **Migrating without crypto-agility.** A migration that hardcodes ML-KEM-768 will require a code change when ML-KEM-768 is eventually succeeded. Crypto-agile design is the investment that makes every future migration cheaper.
- **Ignoring the classical algorithms alongside PQC.** Deploying ML-KEM in TLS does not remove the RSA or ECDSA signature on the server certificate. A complete migration addresses both key exchange and signatures.
- **Adopting non-standardised PQC algorithms.** Several vendors offer "quantum-resistant" solutions based on algorithms not in the NIST process. Without public cryptanalysis of the quality that NIST's process provides, these algorithms may not survive. Use only FIPS 203/204/205 for production deployments.
- **Performance assumption.** ML-KEM key exchange is fast (comparable to X25519); ML-DSA signatures are larger (4× ECDSA) but acceptable. The performance concern should be measured, not assumed: in most TLS handshakes, the bandwidth overhead of ML-KEM is a fraction of the handshake's other data.

## See also

- [[encryption-and-key-management]] — key hierarchy, KMS, and current symmetric/TLS standards with PQC integration notes
- [[confidential-computing]] — hardware-level encryption complementing PQC for data in use
- [[zero-trust-architecture]] — ZTA depends on PKI; PQC migration updates the cryptographic foundation of ZTA
- [[compliance-and-regulation]] — NSA CNSA Suite 2.0 and NIST migration timeline as regulatory requirements
- [[iam-and-secrets-management]] — credential management systems that will need PQC key type support

## Sources

- NIST (2024). *FIPS 203 — ML-KEM Standard.* https://csrc.nist.gov/pubs/fips/203/final
- NIST (2024). *FIPS 204 — ML-DSA Standard.* https://csrc.nist.gov/pubs/fips/204/final
- NIST (2024). *FIPS 205 — SLH-DSA Standard.* https://csrc.nist.gov/pubs/fips/205/final
- NSA (2022). *CNSA Suite 2.0 — Commercial National Security Algorithm Suite.* https://media.defense.gov/2022/Sep/07/2003071834/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF
- Cloudflare (2024). *The Post-Quantum Age is Here.* https://blog.cloudflare.com/pq-2024/
- NIST (2024). *NIST IR 8547 ipd — Transition to Post-Quantum Cryptography Standards.* https://nvlpubs.nist.gov/nistpubs/ir/2024/NIST.IR.8547.ipd.pdf
