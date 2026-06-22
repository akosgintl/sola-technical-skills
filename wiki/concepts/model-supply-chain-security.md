---
title: Model Supply Chain Security
aliases: [AI supply chain, model provenance, AI-BOM, model artifact security]
type: concept
domain: security
status: mature
tags: [security, ai-security, supply-chain, provenance, ml-security, owasp-llm]
updated: 2026-06-22
sources:
  - https://owasp.org/www-project-top-10-for-large-language-model-applications/
  - https://huggingface.co/docs/safetensors/index
  - https://github.com/protectai/modelscan
  - https://cyclonedx.org/capabilities/mlbom/
  - https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-4.pdf
  - https://slsa.dev/
---

# Model Supply Chain Security

> [!summary]
> Model supply chain security extends software supply chain principles to AI artifacts: base model weights, fine-tuned adapters, training and evaluation datasets, and the Python/ML library dependencies that load and run them. Each layer is a distinct attack surface — deserialization exploits, training data poisoning, backdoor injection, and dependency confusion — requiring defences that software SBOM practices alone do not cover.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

In conventional software supply chain security, the concern is integrity: ensuring that the code, packages, and containers that make up a deployed system have not been tampered with between their authoring and their execution. SLSA levels, Sigstore signatures, and SBOMs address this.

AI systems add a second, deeper concern: **behavioural integrity**. A model's weights encode the behaviour of the system. Those weights can be manipulated — during training (data poisoning, backdoor injection), during serialisation (embedding executable code), or in transit (weight tampering) — in ways that produce outputs indistinguishable from benign behaviour until a trigger condition is met. This is not a bug in the model's software; it is a weaponisation of the model's learned parameters.

Model supply chain security addresses both concerns: the same integrity guarantees that SLSA provides for source code, plus the additional provenance, scanning, and isolation controls needed for AI-specific attack vectors.

## Why it matters

**The attack surface has expanded silently.** Most organisations track their software dependencies via `requirements.txt` or `package.json` and scan them for CVEs. Few have equivalent visibility into which model weights, LoRA adapters, or embedding models are loaded at inference time, where they came from, and whether they have been verified. A PyPI package with a known CVE generates a Dependabot alert; a Hugging Face model with backdoored weights generates nothing.

**Deserialization attacks are exploitable today.** The predominant model serialisation format until recently was Python pickle (PyTorch `.pt` / `.pth` files). Pickle is an arbitrary code execution primitive: a file crafted to execute system commands will do so when `torch.load()` is called, with no user warning. Proof-of-concept exploits embedding reverse shells in `.pt` files have been publicly demonstrated. This is not a theoretical risk.

**Community model hubs are an uncontrolled registry.** Hugging Face Hub hosts hundreds of thousands of models, contributed by the general public. Any user can upload a model. Malicious models — pickled with payloads, or fine-tuned to produce harmful outputs — have been found on the hub. The default trust posture of `AutoModel.from_pretrained("user/model")` with no verification is equivalent to `pip install` from an anonymous PyPI package with no CVE scan.

**OWASP LLM Top 10.** LLM03 (Training Data Poisoning) and the supply chain vector within LLM05 (Improper Output Handling) are explicitly in the OWASP LLM Top 10 for Large Language Model Applications. Regulators and auditors are increasingly expecting AI systems to have supply chain controls aligned with this standard.

## Key concepts

### Threat taxonomy

| Threat | Attack vector | Detection | Mitigation |
|---|---|---|---|
| **Unsafe deserialisation** | Malicious `.pt` / `.pkl` file executes code on `torch.load()` | ModelScan static scan | Use safetensors format; never load untrusted pickled models |
| **Training data poisoning** | Malicious examples injected into training set cause targeted misbehaviours | Dataset provenance audit; anomaly detection in training distributions | Source-vetted datasets; data lineage tracking; anomaly detection |
| **Backdoor injection** | Trigger phrase causes specific harmful output (BadNets pattern) | Red-teaming; neural cleanse; activation clustering analysis | Source-vetted models; red-team evaluation before production |
| **Weight tampering** | Model weights modified in storage or transit to alter behaviour | Signed checksum on weights; hash verification at load time | Cryptographic weight signing (Sigstore / custom KMS-signed hash) |
| **Dependency confusion** | Malicious PyPI/conda package named to shadow a private registry package | `pip audit`; private package mirror | Internal registry mirror; pip index URL pinned to internal mirror |
| **Hallucinated package names** | AI-generated code suggests a package name that doesn't exist; attacker registers it | Human code review; `pip install` dry-run before execution | Review AI-generated `import` statements before installing dependencies |

### Serialisation formats: pickle vs. safetensors

**Python pickle** is the legacy serialisation format for PyTorch model weights. It supports arbitrary Python objects — including code objects and functions. The `torch.load()` function evaluates the pickle stream, which can execute arbitrary Python at load time. This is by design: pickle was built for general Python serialisation, not for safe model distribution.

**Safetensors** (Hugging Face, 2022) is a purpose-built tensor serialisation format. It stores only tensor data (dtype, shape, raw bytes) — no Python objects, no code, no callables. Loading a safetensors file cannot execute code. It is also memory-safe (zero-copy mmap), portable across frameworks, and faster to load than pickle for large models.

Migration path:
1. Convert any existing pickled models to safetensors: `safetensors.torch.save_model(model, "model.safetensors")`
2. When loading from Hugging Face: prefer `AutoModel.from_pretrained(name, use_safetensors=True)` — falls back to pickle if safetensors file is absent
3. Enforce in CI: fail pipelines that reference `.pt` or `.pth` files without explicit justification

**ModelScan** (Protect AI) is the primary static analysis tool for ML model files. It scans PyTorch, TensorFlow, Keras, and scikit-learn model files for embedded code execution and reports suspicious operators before the model is loaded. Add ModelScan as a pre-load gate in any pipeline that ingests external model files.

### AI Bill of Materials (AI-BOM)

An AI-BOM extends the Software Bill of Materials (SBOM) concept to AI artifacts. For each AI system, the AI-BOM records:

- **Base model:** name, version, source registry URL, cryptographic hash of weights, licence
- **Fine-tuned adapters:** LoRA / adapter checkpoint name and hash, training dataset reference, date trained
- **Training and evaluation datasets:** name, version, source URL, hash, licence, data governance classification
- **ML library dependencies:** framework versions (PyTorch, transformers, PEFT), pinned versions with known-CVE status
- **Inference environment:** container image digest, base OS, CUDA version
- **Accountability:** named model owner (see [[accountable-human-layer]]), review date

**CycloneDX ML-BOM** (v1.5+) is the leading standard for AI-BOM structure. It extends CycloneDX's SBOM format with `mlModel` and `dataset` component types, including fields for training data, model parameters, and hyperparameters. Generate ML-BOMs as part of the model release pipeline; store them alongside the weights in a version-controlled artifact registry.

**SPDX AI Profile** (v3.0, 2024) adds an `ai` element to the SPDX standard covering model provenance, training data, and safety assessment. Both CycloneDX ML-BOM and SPDX AI Profile are evolving rapidly — check current specification versions.

### Model signing and provenance

Signing model weights provides the same guarantee that Sigstore provides for container images: the recipient can verify that the weights were produced by the expected party and have not been modified since signing.

Implementation approaches:
- **KMS-signed hash:** compute `SHA-256` of the serialised weights; sign the hash with a KMS-managed asymmetric key (AWS KMS, Azure Key Vault, Google Cloud KMS); store the signature alongside the weights. Verify at load time before deserialising.
- **Sigstore for ML:** the Sigstore project is extending its transparency log approach to ML model artifacts. The model producer signs the weight file; the signature is recorded in a transparency log; consumers verify against the log. Early-stage as of mid-2026 but tracking toward adoption.
- **Hugging Face model signing** (2024): Hugging Face introduced `huggingface_hub.sign_model()` / `verify_model()` for repository-level signing using developer SSH keys. Adds a `model.safetensors.sig` file; CI verification can check signatures before loading.

For internal model development pipelines, the minimum practice is: compute and store the weight hash at training time (as part of the model release artifact); verify the hash at load time in production; treat a hash mismatch as a security incident.

### Training data provenance and poisoning

Data poisoning introduces malicious training examples that cause a model to misbehave in targeted ways. For fine-tuned models, the attack surface is the instruction-tuning or RLHF dataset. For embedding models, poisoning can cause specific queries to retrieve attacker-controlled content.

**Defences:**
- **Source-vetting:** use only training data from trusted, auditable sources. Document provenance in the AI-BOM.
- **Data lineage tracking:** maintain an immutable record of every training example's source, using a data lineage platform (Apache Atlas, Marquez, or dbt lineage) or hash-based provenance chains.
- **Anomaly detection in training data:** tools such as Cleanlab can identify low-quality or anomalous examples that may indicate injection. For instruction tuning, review samples of synthetic data before inclusion.
- **Differential privacy:** training with differential privacy (DP-SGD) limits the influence any single training example can have on model weights — reducing (not eliminating) poisoning impact and protecting training data membership inference.
- **Evaluation datasets as canaries:** maintain a held-out evaluation set that tests for known poisoning signatures and expected behaviours; run it after every fine-tuning run.

### Registry controls and dependency vetting

**Hugging Face Hub controls:**
- Use only **verified organisations** (blue checkmark) or **gated models** that require explicit request approval for high-stakes deployments
- Enable Hugging Face's **malware scanning** (safe files API) — Hub scans uploaded models for known malicious patterns; verify the `is_safe` flag via the API before loading
- For internal use, run a private **model registry** (JFrog ML, MLflow Registry, or a simple object store with access controls) that contains only models that have passed organisational review; prohibit loading from public Hub in production environments

**Python dependency controls:**
- Pin all ML library versions in `requirements.txt` with hashes (`pip install --require-hashes`)
- Scan every `pip install` against CVE databases via `pip audit`, Safety CLI, or Snyk
- Mirror dependencies to a private package index (Artifactory, AWS CodeArtifact) to eliminate dependency confusion attacks
- Review AI-generated code that introduces `import` statements or `pip install` calls before executing them (see [[vibe-coding-governance]])

## Design decisions and trade-offs

**Safetensors migration vs. pickle compatibility.** Safetensors is the right default for new models. For legacy models that exist only as pickled checkpoints, the migration cost is a one-time conversion — worth the investment to eliminate the deserialization attack surface. Do not accept "we need pickle for compatibility" without verifying that the specific framework version actually requires it.

**Public Hub vs. private registry.** Loading models directly from a public registry in production offers convenience at the cost of provenance control. The right trade-off depends on risk classification: for internal tooling with low-stakes outputs, Hub with malware scan verification may be acceptable; for high-risk AI systems (EU AI Act Article 6 high-risk categories), a private registry with organisational review is the appropriate control.

**Signed weights vs. hash verification.** Full cryptographic signing with a public-key scheme provides non-repudiation (the producer cannot deny signing) and transparency log support; hash verification (compute and compare SHA-256) provides integrity without non-repudiation. For internal pipelines, hash verification is the minimum viable control and can be implemented in an afternoon. Reserve full signing for externally distributed models or high-assurance internal deployments.

**Differential privacy vs. model utility.** DP training reduces the influence of individual training examples but degrades model utility (lower accuracy, especially for minority-class examples). The right calibration is dataset-specific; DP is most valuable when training data includes sensitive personal information (a separate governance driver) and the poisoning risk is from a small number of adversarially injected examples.

## State of the art

**Safetensors adoption** has become the Hugging Face Hub default for all new model uploads as of 2024. The `transformers` library version 4.37+ preferentially loads safetensors if present; older pickled checkpoints coexist but generate deprecation warnings.

**ModelScan** is the most widely adopted model file scanner, integrated into CI pipelines at several large ML-ops platforms. The ProtectAI `guardian` project extends it to a continuous monitoring service for model registries.

**CycloneDX ML-BOM v1.6** (2025) added support for agentic AI artifacts, including tool definitions, agent capability declarations, and multi-agent workflow descriptions. This makes it the most complete standard for AI-BOM in agentic systems.

**NIST AI 100-4** (Adversarial Machine Learning, 2024) is the authoritative taxonomy for AI attack types including data poisoning, model evasion, and model extraction. It is the reference standard for threat modelling AI systems and maps attack types to mitigation families.

**EU AI Act Article 9** (quality management for high-risk AI) and Article 10 (data and data governance requirements) mandate training data provenance documentation and quality assurance processes — effectively requiring AI-BOM capabilities for high-risk AI systems in scope. These requirements are enforceable from August 2026.

> [!warning]
> Never call `torch.load()` on a model file from an untrusted or unverified source. The pickle format allows arbitrary code execution at load time. Always use `weights_only=True` at minimum (`torch.load(path, weights_only=True)`), or convert to safetensors before loading. ModelScan on the file before loading is the belt-and-suspenders approach.

## Pitfalls and anti-patterns

- **Treating `from_pretrained()` as safe by default.** The Hugging Face `from_pretrained()` convenience method loads whatever is in the repository. Without `use_safetensors=True` and prior ModelScan verification, it may execute arbitrary code from an untrusted pickle file.
- **No model registry in production.** Loading models directly from public Hub at inference time means your production behaviour depends on an external, uncontrolled party. If Hugging Face changes the model, your production system changes. Pin to a specific commit hash and load from an internal registry.
- **SBOM without AI-BOM.** An SBOM that tracks Python library dependencies but not the model weights, datasets, or adapters has a significant gap. The weights are often the largest attack surface.
- **One-time provenance check.** A model that passes provenance review at deployment may drift if retraining data sources are added or if the base model is updated without re-triggering the review. Provenance checks should be triggered by every model update, not just initial deployment.
- **Ignoring LoRA adapters.** Base model provenance is often carefully tracked; the LoRA adapters layered on top are sometimes loaded without equivalent scrutiny. An adapter can modify model behaviour as significantly as retraining.
- **Conflating model vulnerability scanning with code vulnerability scanning.** Snyk and Dependabot scan Python packages; they do not scan model weight files for embedded code or behavioural backdoors. Both types of scanning are needed.

## See also

- [[ai-specific-security]] — broader AI security including prompt injection and inference attacks
- [[software-supply-chain-security]] — SLSA, Sigstore, SBOM, and dependency controls for code artifacts
- [[prompt-injection]] — attack pattern that exploits the model's instruction-following at runtime
- [[ai-governance-frameworks]] — EU AI Act Article 9/10 data governance requirements for high-risk AI
- [[vibe-coding-governance]] — AI-generated code dependencies as a related supply chain risk
- [[accountable-human-layer]] — model owner in the AI-BOM accountability field

## Sources

- OWASP (2025). *OWASP Top 10 for Large Language Model Applications — LLM03 Training Data Poisoning.* https://owasp.org/www-project-top-10-for-large-language-model-applications/
- Hugging Face (2024). *safetensors — Safe and Fast Model Serialisation.* https://huggingface.co/docs/safetensors/index
- Protect AI (2024). *ModelScan — Security Scanner for ML Models.* https://github.com/protectai/modelscan
- CycloneDX (2025). *CycloneDX ML-BOM — AI/ML Bill of Materials Standard.* https://cyclonedx.org/capabilities/mlbom/
- NIST (2024). *AI 100-4 — Adversarial Machine Learning: A Taxonomy and Terminology.* https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-4.pdf
- OpenSSF / SLSA (2024). *SLSA Framework — Supply-chain Levels for Software Artifacts.* https://slsa.dev/
