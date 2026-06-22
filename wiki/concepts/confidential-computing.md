---
title: Confidential Computing
aliases: [confidential computing, TEE, trusted execution environment, PET, confidential VM]
type: concept
domain: emerging
status: mature
tags: [emerging, security, privacy, tee, intel-tdx, amd-sev, nitro-enclaves, attestation]
updated: 2026-06-22
sources:
  - https://confidentialcomputing.io/white-paper/
  - https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/overview.html
  - https://www.amd.com/en/developer/sev.html
  - https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave.html
  - https://learn.microsoft.com/en-us/azure/confidential-computing/overview
  - https://confidentialcontainers.org/
---

# Confidential Computing

> [!summary]
> Confidential computing closes the "data in use" gap: while encryption at rest and in transit are well-solved, data is plaintext in CPU registers and RAM during processing — visible to the hypervisor and cloud operator. Hardware Trusted Execution Environments (TEEs) isolate and encrypt data in memory even from the infrastructure provider, with cryptographic remote attestation proving the environment's integrity to a remote verifier.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

Encryption solves two of the three data-protection problems cleanly: data at rest (AES-256 in KMS-managed keys) and data in transit (TLS 1.3). The third — data in use — has historically been left unprotected. When a cloud VM decrypts a database record to process it, the plaintext exists in RAM and CPU caches, accessible to the hypervisor that manages the VM's memory, to the cloud provider's privileged system software, and to any software running at a higher privilege level than the application.

Confidential computing addresses this with **Trusted Execution Environments (TEEs)**: hardware-isolated regions where the processor itself enforces memory encryption and access control. Code and data inside the TEE are encrypted in RAM by a hardware-managed key that the CPU generates and never exposes. Even the hypervisor, host OS, and cloud operator cannot read the plaintext — only the code running inside the TEE can decrypt and access it. A **remote attestation** protocol allows a remote party to cryptographically verify that a specific piece of code is running inside a genuine TEE and has not been tampered with.

Confidential computing is primarily a **multi-party trust** and **regulatory compliance** technology: it enables computation on sensitive data in environments that the data owner does not fully control, with cryptographic proof (not just contractual assurance) of the protection.

## Why it matters

**The cloud trust gap.** Using public cloud requires trusting the cloud provider's privileged software (hypervisor, firmware, host OS) not to access customer data. For most workloads this trust is adequate; for regulated data (health records, financial transactions, PII under GDPR), classified material, or multi-party data sharing, contractual trust is insufficient. TEEs replace contractual trust with cryptographic proof.

**Regulated AI inference.** AI models trained on or used to process sensitive data — healthcare diagnostics, financial fraud scoring, legal document analysis — must protect both the input data (patient record, financial transaction) and the model weights (which may be proprietary). Running inference inside a TEE ensures that the cloud provider hosting the model cannot see either the input or (with appropriate design) the model weights. This is the path to outsourcing regulated AI workloads to public cloud.

**Multi-party computation without data sharing.** Two organisations can jointly compute a result (e.g., identify fraud patterns across both banks' transaction histories, or compute a joint credit score) without either party seeing the other's raw data. Both parties verify via attestation that the computation runs unmodified inside a TEE; neither party learns anything beyond the agreed output.

**Supply chain attestation.** Remote attestation can prove that a container or VM was launched from a specific image without modification. This extends software supply chain verification ([[model-supply-chain-security]], [[software-supply-chain-security]]) into the running environment, not just the artifact.

## Key concepts

### TEE variants

**Intel TDX (Trust Domain Extensions) — VM-level confidential computing.**
TDX is Intel's current-generation VM-level confidential computing technology (available on Intel Sapphire Rapids and later). The entire virtual machine runs inside a Trust Domain (TD): guest memory is encrypted by hardware-managed keys that the CPU never exposes to the hypervisor. The hypervisor manages the VM's scheduling and resources but cannot decrypt its memory.

TDX is available in production on:
- **Azure Confidential VMs** (DCsv5/ECsv5 series) — Azure's primary confidential computing offering
- **Google Cloud Confidential VMs** (C3 series)
- **Alibaba Cloud ECS** (select instance families)

TDX replaced Intel SGX for most new confidential computing deployments. SGX required rewriting applications for an enclave programming model with severe memory limitations (~512 MB EPC); TDX runs standard VMs unmodified.

**AMD SEV-SNP (Secure Encrypted Virtualisation — Secure Nested Paging) — VM-level.**
AMD's equivalent to TDX, available on EPYC processors (Milan/Genoa). SEV-SNP adds memory integrity protection on top of SEV-ES (which encrypted registers): the SNP extension prevents the hypervisor from remapping or aliasing guest memory pages, closing a significant class of attacks on earlier SEV versions.

Available on:
- **AWS Confidential Instances** (M6a, C6a, R6a) — AMD EPYC-based EC2
- **Google Cloud Confidential VMs** (N2D series, AMD EPYC)
- **Azure Confidential VMs** (DCasv5/ECasv5 series — AMD EPYC)

**AWS Nitro Enclaves — application-level isolation.**
Nitro Enclaves are a distinct approach: not SGX or TDX, but an isolated virtual machine running alongside a parent EC2 instance on Nitro hardware. Characteristics:
- No persistent storage; no network access (only a local vsock between the enclave and parent instance)
- No interactive login or shell
- Designed for a single purpose: process sensitive data (decrypt a private key, validate a credential, process PII) in isolation from the rest of the EC2 environment
- Attestation documents signed by the Nitro Hypervisor; documents include a measurement of the enclave's image

Nitro Enclaves are well-suited for specific sensitive processing steps within a larger application (the secrets-handling path), not for running entire applications.

**Intel SGX (Software Guard Extensions) — historical application-level.**
SGX is Intel's older per-process enclave model. Small encrypted memory regions (EPC) contain sensitive code and data; all access outside the EPC triggers encryption/decryption at the processor boundary. SGX 1.0 limited EPC to ~128 MB; Ice Lake extended this but remained constrained.

SGX is mature and has a rich tool ecosystem (Gramine library OS, Open Enclave SDK, Occlum), but side-channel attack research has repeatedly found vulnerabilities (Spectre variants, RIDL, CacheOut, Foreshadow). Intel's current direction is TDX for new deployments. SGX remains relevant for specific use cases requiring sub-VM granularity isolation.

**Arm CCA (Confidential Compute Architecture) — Realm VMs.**
Arm v9 introduces a Realm Management Extension (RME) that creates a fourth execution state (Realm) alongside Secure, Non-Secure, and EL3. Confidential VMs (Realms) are isolated from the hypervisor. Relevant for mobile devices, Arm-based servers (AWS Graviton), and edge hardware. Availability in cloud production environments is emerging.

### Remote attestation

Remote attestation is the mechanism by which a workload running inside a TEE proves its identity and integrity to a remote verifier (typically the data owner or a trust broker).

**Flow:**
1. The TEE generates an **attestation report** containing: a cryptographic hash of the code running inside (the measurement), platform identity, and a nonce from the verifier.
2. The report is signed by a hardware-rooted key — the signature chain traces to the CPU manufacturer's certificate authority (Intel PCA for TDX, AMD VCEK/ARK chain for SEV-SNP, AWS Nitro attestation service).
3. The verifier checks the signature against the manufacturer's published certificates and verifies the code measurement matches the expected value.
4. If attestation succeeds, the verifier has cryptographic assurance that the expected code is running inside a genuine TEE on genuine hardware. Only then does it release sensitive data (e.g., a decryption key) to the TEE.

**Attestation infrastructure:**
- **Intel DCAP (Data Center Attestation Primitives):** enterprise-grade Intel TDX attestation without requiring a per-quote call to Intel's network. The DCAP service caches Intel's provisioning certificates locally, enabling air-gapped or high-volume attestation.
- **AMD SEV-SNP attestation:** VCEK (Versioned Chip Endorsement Key) certificate chain from AMD KDS (Key Distribution Service) or CEVF.
- **AWS Nitro attestation:** the Nitro Hypervisor issues signed attestation documents; AWS KMS can condition key access on verified attestation.
- **Azure Attestation Service (MAA):** Microsoft-hosted attestation verification service for TDX, SEV-SNP, and SGX enclaves running on Azure.

### Confidential containers

**Kata Containers + TEE (CoCo — Confidential Containers):** the CNCF Confidential Containers project runs Kata Containers (lightweight VMs as container runtimes) inside TEEs (TDX or SEV-SNP). The container's memory is encrypted from the host; the image is decrypted only inside the TEE after attestation. The Kubernetes scheduler is unaware of the TEE; nodes are labelled and workloads are scheduled to confidential nodes via node selectors or taints.

This model extends the TEE to the Kubernetes layer: a container workload gets full TEE protection without being re-architected for enclave programming. Azure ACI (Confidential Containers) and Azure Kubernetes Service (AKS confidential node pools) support CoCo.

### Key use cases and design patterns

| Use case | TEE type | Pattern |
|---|---|---|
| Sensitive data processing (PII, health, finance) | Confidential VM (TDX/SEV-SNP) | Entire application in TEE; data decrypted inside; result encrypted before leaving |
| Private key operations | Nitro Enclave / SGX | Specific decryption/signing path isolated; parent instance never sees plaintext key |
| Multi-party analytics | Confidential VM with attestation | Both parties verify code measurement before releasing their datasets; result only leaves TEE |
| AI inference on sensitive input | Confidential VM or CoCo | Model weights and user input decrypted inside TEE; cloud provider cannot see either |
| Audit ledger | Azure Confidential Ledger | Immutable log backed by SGX enclaves; tampering detectable via attestation |
| Secret management alternative | Nitro Enclave + KMS | KMS policy requires attestation document; enclave decrypts secrets that never reach EC2 |

## Design decisions and trade-offs

**TEE granularity: VM vs. enclave.** Confidential VMs (TDX/SEV-SNP) run an entire workload inside the TEE with no application changes; application-level enclaves (SGX, Nitro) isolate a specific sensitive function. VMs are simpler to adopt; enclaves minimise the Trusted Computing Base (TCB) — less code inside the TEE means less attack surface. For new deployments, confidential VMs are the practical default; enclaves are justified when the TCB size is a specific security requirement.

**Attestation complexity vs. trustworthiness.** Attestation is what makes confidential computing verifiable rather than merely promised. Skipping attestation and relying on the TEE's implicit protection removes the cryptographic guarantee. Implement attestation for any workload where the data owner needs to verify the environment before releasing sensitive data.

**Performance overhead.** TDX and SEV-SNP add 5–15% overhead for typical server workloads. The overhead is highest for memory-intensive workloads (additional encryption/decryption of each cache miss). For most application workloads, the overhead is acceptable. Measure on a realistic workload before ruling out confidential VMs on performance grounds.

**Side-channel resilience.** TEEs protect against privileged software attacks but not all side-channel attacks. Software-based side-channels (cache-timing, DRAM row-hammer variants) may bypass TEE protections. AMD SEV-SNP includes mitigations for several attack classes; Intel TDX includes protections against hypervisor-based remapping. Applications processing extremely high-value secrets (cryptographic keys used for signing) should assume side-channel risk and apply mitigations (constant-time cryptographic implementations, cache flush policies).

**Trusted Computing Base (TCB).** The TCB is what is trusted: CPU hardware, firmware, and microcode. Vulnerabilities in the CPU firmware (e.g., Intel Management Engine) can undermine TEE guarantees. TEE attestation includes the firmware version; verifiers should check the platform's TCB version against known-good lists (TCBINFO) and set a policy that rejects attestations from platforms with known vulnerabilities.

## State of the art

**Azure Confidential VMs (TDX and SEV-SNP)** are the most widely deployed enterprise confidential computing offering. Azure Confidential Computing includes Confidential VMs, AKS confidential node pools, and Azure Confidential Ledger.

**AWS Nitro Enclaves** are widely adopted for KMS key isolation patterns — the enclave requests a decryption key from KMS with an attestation document, and the KMS key policy allows access only to verified attestation documents. This is the recommended pattern for high-assurance secret use on AWS.

**Confidential Containers (CNCF)** graduated from sandbox to incubating in 2024. The project provides containerd shims for TDX and SEV-SNP, enabling transparent TEE-based container execution in Kubernetes without application changes. Azure AKS confidential node pools use CoCo in production.

**Confidential AI.** Intel, NVIDIA (H100 Confidential Compute mode), and Microsoft are collaborating on confidential AI inference: running LLM inference inside TEEs so neither the model operator nor the cloud provider sees the user's input. NVIDIA H100 supports a CC mode where GPU memory is encrypted with hardware-managed keys — the first production GPU with confidential computing support (2024). This extends the TEE from CPU to GPU, addressing the gap that CPU-only TEEs leave for ML inference.

> [!warning]
> Confidential computing protects data from the infrastructure operator; it does not protect against vulnerabilities in the application code running inside the TEE. A buggy enclave is not a secure enclave — OWASP Top 10 vulnerabilities in enclave code are just as exploitable as in standard code, and the lack of observability inside TEEs makes them harder to debug and monitor.

## Pitfalls and anti-patterns

- **Trusting TEE without attestation.** A TEE without verified remote attestation is just a promise from the cloud provider. The attestation step is what makes the guarantee cryptographic.
- **Putting too much in the TCB.** Every library and function inside the enclave is in the trusted computing base. Large enclave TCBs are harder to audit and have more attack surface. Use the minimal code necessary inside the TEE; validate inputs at the enclave boundary.
- **Ignoring side-channel attacks.** TEE security research is active; new attack classes are discovered regularly. Stay current with Intel and AMD security advisories; update platform firmware promptly when TCB updates are available.
- **Confidential computing as a compliance checkbox.** Regulators are beginning to recognise TEE attestation in their guidance (UK ICO, German BSI), but not all regulatory frameworks have specific provisions. Check whether the specific regulatory context recognises TEE attestation as a control before treating it as a substitute for other controls.
- **Performance assumptions without measurement.** The overhead of confidential VMs is workload-dependent. Benchmark the specific workload before assuming it is prohibitive.
- **No observability inside TEEs.** Traditional logging and monitoring agents cannot run inside TEEs without being added to the TCB. Design observability into the enclave: emit metrics and logs from inside the enclave before the data leaves; use attestation to verify the log source.

## See also

- [[encryption-and-key-management]] — key hierarchy and KMS that confidential computing complements for key isolation
- [[post-quantum-cryptography]] — PQC protects keys in transit; confidential computing protects keys in use
- [[zero-trust-architecture]] — ZTA assumes hostile infrastructure; TEE attestation extends ZTA to the compute level
- [[compliance-and-regulation]] — GDPR, EU AI Act, and sector regulations driving confidential computing adoption
- [[model-supply-chain-security]] — supply chain integrity extended to the running environment via attestation
- [[network-segmentation]] — confidential VMs on isolated node pools; network controls complement TEE protections
- [[wasm-at-the-edge]] — complementary isolation technology for edge compute (lighter-weight, different threat model)

## Sources

- Confidential Computing Consortium (2023). *Confidential Computing: Hardware-Based Trusted Execution for Applications and Data.* https://confidentialcomputing.io/white-paper/
- Intel (2024). *Intel Trust Domain Extensions (Intel TDX) Overview.* https://www.intel.com/content/www/us/en/developer/tools/trust-domain-extensions/overview.html
- AMD (2024). *AMD Secure Encrypted Virtualisation (SEV).* https://www.amd.com/en/developer/sev.html
- AWS (2024). *AWS Nitro Enclaves — User Guide.* https://docs.aws.amazon.com/enclaves/latest/user/nitro-enclave.html
- Microsoft (2025). *Azure Confidential Computing Overview.* https://learn.microsoft.com/en-us/azure/confidential-computing/overview
- CNCF (2024). *Confidential Containers (CoCo) Project.* https://confidentialcontainers.org/
