---
title: AI-Generated IaC Reviewer
aliases: [AI reviewer problem, AI IaC review, generated-config verification, AI-generated infrastructure review, platform as reviewer]
type: concept
domain: platform
priority: P0
roadmap_ref: "4.2"
status: mature
tags: [iac, policy-as-code, admission-control, ai-generated-code, supply-chain, platform-engineering, governance]
updated: 2026-06-19
sources:
  - "https://arxiv.org/abs/2406.10279"
  - "https://socket.dev/blog/slopsquatting-how-ai-hallucinations-are-fueling-a-new-class-of-supply-chain-attacks"
  - "https://nesbitt.io/2025/12/10/slopsquatting-meets-dependency-confusion.html"
  - "https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/"
  - "https://www.cncf.io/blog/2025/08/30/announcing-kyverno-release-1-15/"
  - "https://www.env0.com/blog/best-iac-scan-tool-comparing-checkov-vs-tfsec-vs-terrascan"
  - "https://spacelift.io/blog/policy-as-code-tools"
  - "https://controlmonkey.io/blog/2026-iac-predictions/"
---

# AI-Generated IaC Reviewer

> [!summary]
> When LLMs and coding agents author your Terraform, Kubernetes manifests, and Helm
> charts, the bottleneck moves from *writing* infrastructure code to *verifying* it.
> The "AI reviewer" problem is the architect's mandate to make the **platform itself the
> primary reviewer and auto-remediator** of generated config — a defense-in-depth chain
> of automated gates (schema/lint → policy-as-code → `plan`/dry-run → admission control →
> drift/runtime) that catches *plausible-but-wrong* output before it reaches production.
> Generated IaC fails differently from human IaC: it invents Kubernetes API fields and
> Terraform arguments that look idiomatic, pass linting and `terraform plan`, and only
> blow up at apply or at runtime. Non-deterministic generation demands deterministic
> verification.

**Priority:** 🔴 P0 · **Domain:** [[tier-2-solid|Platform Engineering & IaC]] · **Roadmap:** §4.2

## What it is

The AI-generated IaC reviewer is not a single product but an **architectural posture**:
treat every piece of AI-authored infrastructure config as untrusted input and run it
through an automated verification pipeline that a human *audits* rather than *performs*.
It is the platform-engineering response to two facts of 2026:

1. A large and growing share of IaC is now generated — by IDE copilots, agentic SWE
   tools, and "describe the infra, get the Terraform" platforms.
2. Generative models are **confidently wrong** in ways that defeat the cheap, syntactic
   checks teams have historically relied on.

The reviewer's job is to convert a non-deterministic author into a deterministic,
policy-bounded outcome: a change either passes every gate (and may be auto-merged or
auto-remediated) or it is rejected with a machine-readable reason. This is the
operational embodiment of [[delegate-review-own|delegate, review, own]] and
[[vibe-coding-governance]] applied to infrastructure.

## Why it matters (2026, senior architect lens)

The failure mode that makes this a P0 is **plausibility**. Generated config is fluent:
it mirrors the shape of real manifests, so it sails past human eyeballs and naive
linters. The hard cases:

- **Hallucinated API fields / arguments.** A model emits a Kubernetes field
  (`spec.template.spec.containers[].resourcePolicy`) or a Terraform argument that does
  not exist in the installed CRD/provider version. Strict-typed servers reject it, but
  `terraform plan` against a stale schema, a permissive `kubectl apply`, or a Helm
  template render may *not* — the error surfaces at apply or first reconcile.
- **Silently-wrong-but-valid config.** A `0.0.0.0/0` security-group ingress, a public
  S3 ACL, a missing `resources.limits`, a privileged container — all syntactically
  perfect, all `plan`-clean, all production incidents.
- **Package / module hallucination ("slopsquatting").** A landmark study across 576,000
  code samples from 16 LLMs found **19.7% of suggested packages were hallucinations** —
  205,474 unique fake names, and **43% recurred consistently** across repeated prompts
  ([Spracklen et al., arXiv 2406.10279](https://arxiv.org/abs/2406.10279)). Attackers
  now pre-register those predictable names — *slopsquatting* — so an agent that pulls a
  hallucinated Terraform module, provider, or Helm chart can import attacker-controlled
  code that passes `init` cleanly. By late 2025 this had merged with classic dependency
  confusion ([Nesbitt, 2025](https://nesbitt.io/2025/12/10/slopsquatting-meets-dependency-confusion.html)).

The architect's reframing: **human review effort shifts from writing to verifying**, and
verification at AI-generation throughput cannot be a manual PR read. Most pipelines were
built for human-paced change, not AI-amplified change ([tfir.io, 2026](https://tfir.io/ai-code-quality-2026-guardrails/));
the quality gates have to scale with the generator. Policy-as-code becomes "the
enforcement layer that makes velocity safe" ([ControlMonkey 2026 IaC predictions](https://controlmonkey.io/blog/2026-iac-predictions/)).

## Key concepts / building blocks

**Defense-in-depth gate chain** — each gate catches a class the previous one cannot,
ordered cheapest/earliest first (shift-left):

| Gate | Catches | 2026 tooling |
|---|---|---|
| **Schema / lint / type-check** | Hallucinated fields, malformed structure | `kubeconform`, `terraform validate`, `tflint`, OpenAPI/CRD schema, JSON-Schema |
| **Static policy-as-code** | Insecure-but-valid config, org standards | Checkov, Trivy (IaC), [[policy-as-code\|OPA/Conftest, Kyverno, Sentinel]] |
| **Plan / dry-run diff** | Unexpected blast radius, deletions, drift | `terraform plan`, `kubectl --dry-run=server`, `helm template` |
| **Admission control** | Anything that slips through to the cluster API | ValidatingAdmissionPolicy (CEL), Gatekeeper, Kyverno |
| **Drift detection / runtime** | Post-deploy divergence, out-of-band change | Continuous reconciliation, drift scanners, runtime PaC |

- **Server-side / strict validation.** `--dry-run=server` and `kubeconform` against the
  *actual* API/CRD schemas are the cheapest hallucinated-field detector — they fail on
  invented fields that a client-side render accepts.
- **Policy-as-code as the guardrail.** The deterministic ruleset that encodes "what good
  looks like." See [[policy-as-code]] for the full treatment of OPA/Rego, Kyverno, and
  Sentinel.
- **Admission control as the last line.** Even if config is hand-applied or bypasses
  CI, the cluster rejects non-compliant resources at the API boundary.
- **Pre-merge gates.** Policy runs in CI as a required status check, so non-compliant
  generated config never merges. Part of [[cicd-pipeline-architecture]].
- **Auto-remediation.** The reviewer doesn't only block — it can mutate (Kyverno/MAP add
  missing labels, inject `securityContext`) or open a fix PR, closing the loop without a
  human round-trip.
- **Provenance / allow-listing.** Pin and verify modules, providers, and base images
  against a curated registry to neutralize slopsquatting — overlaps
  [[software-supply-chain-security]].

## Design decisions & trade-offs

- **Block vs. warn vs. auto-fix.** Hard-fail on security invariants
  (`enforce`/`deny`); warn-then-track on style; auto-mutate on safe, deterministic
  fixes. Over-blocking trains engineers to bypass the gate; under-blocking defeats it.
  Match enforcement to the cost of the failure.
- **Where to put the gate: CI vs. admission vs. both.** CI gives fast, contextual
  feedback at PR time but can be skipped (`--force`, direct `kubectl`). Admission control
  is unbypassable but late and context-poor. **Run both** — CEL-based
  [[policy-as-code|ValidatingAdmissionPolicy]] now lets you author one CEL policy and
  reuse it in CI (Gatekeeper/Kyverno can render to VAP) so the *same* rule guards both
  ends. Single-source-of-truth policy beats two drifting rulesets.
- **Trust calibration for auto-merge.** The prize is letting clean generated changes
  flow without a human. Gate it: require green across the *full* chain, restrict
  auto-merge to low-blast-radius resource types, and keep an [[accountable-human-layer]]
  for anything touching IAM, networking, or data.
- **Schema currency is load-bearing.** A hallucinated-field check is only as good as the
  schema it validates against. Pin and refresh CRD/provider schemas; stale schemas make
  `plan` a false-negative machine.
- **Policy engine selection.** Don't relitigate per-page; the short version:
  **Kyverno** (YAML-native, no Rego, CNCF-graduated March 2026) for Kubernetes-first
  shops; **OPA/Gatekeeper** (Rego) when you need cross-domain policy beyond K8s;
  **Sentinel** when you live in HCP Terraform/Enterprise and want plan/apply-phase
  governance. Full comparison in [[policy-as-code]].
- **Speed vs. coverage.** Every gate adds PR latency. Order them cheap-to-expensive,
  parallelize, and cache, so the 95% clean path stays fast and only suspect changes pay
  the full cost.

## State of the art (2026)

- **CEL-based admission is the new default.** Kubernetes **ValidatingAdmissionPolicy**
  (CEL, no webhook) went GA in **1.30** and is the in-tree way to enforce policy at the
  API server without an external admission webhook
  ([k8s docs](https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/)).
  **MutatingAdmissionPolicy** extends the same CEL model to defaulting/auto-remediation.
- **Kyverno graduated.** Kyverno reached CNCF **Graduated** status (March 2026); since
  v1.17 CEL is its primary expression language, and 1.15+ added CEL-based policy types
  including `MutatingPolicy` that compile down to native K8s VAP/MAP
  ([CNCF, Aug 2025](https://www.cncf.io/blog/2025/08/30/announcing-kyverno-release-1-15/)).
  Per CNCF survey data, **67% of Kubernetes orgs now run policy-as-code for admission**,
  up from 28% in 2021 ([Spacelift PaC tools, 2026](https://spacelift.io/blog/policy-as-code-tools)).
- **IaC scanner consolidation.** The field thinned out: **Terrascan** was archived by
  Tenable (Nov 2025) and **tfsec** folded into **Trivy**, which absorbed its entire
  check library. The maintained open-source options in 2026 are **Checkov** (Palo Alto,
  1,000+ policies across Terraform/CFN/K8s/ARM/Helm) and **Trivy** (Aqua); **KICS**
  persists for Rego-unified shops
  ([env0, 2026](https://www.env0.com/blog/best-iac-scan-tool-comparing-checkov-vs-tfsec-vs-terrascan)).
- **Supply chain is part of the reviewer's remit.** Slopsquatting moved from research to
  in-the-wild threat ([Socket, 2025](https://socket.dev/blog/slopsquatting-how-ai-hallucinations-are-fueling-a-new-class-of-supply-chain-attacks)),
  and even scanner infrastructure is a target — Trivy's release pipeline was compromised
  in March 2026 (hijacked GitHub Actions tags, fake releases). The reviewer must verify
  *its own tools'* provenance, not just the code under review.
- **Self-validating, agentic pipelines.** The emerging pattern: an agent generates IaC
  from intent, a self-validating pipeline runs the gate chain, policy-as-code enforces
  compliance continuously, and remediation is increasingly autonomous
  ([ControlMonkey 2026](https://controlmonkey.io/blog/2026-iac-predictions/)) — the
  human moves to exception-handling and policy authorship. See
  [[guardrails-and-output-validation]] for the generation-side controls that pair with
  this verification-side chain.

## Pitfalls & anti-patterns

- **Trusting `terraform plan` / client-side render as validation.** They run against
  cached or local schemas and happily accept hallucinated fields that the real API
  rejects. Use **server-side** dry-run and schema validation.
- **Linting-only gates.** "It passed Checkov" catches insecure config but not a
  hallucinated provider argument or a nonexistent CRD field — and vice-versa. You need
  *both* schema and policy layers; neither subsumes the other.
- **Single chokepoint.** Relying on CI alone (bypassable) or admission alone (too late,
  no PR context). Defense-in-depth means both, ideally from one policy source.
- **Unpinned, unverified modules/providers/charts.** The open door for slopsquatting.
  Allow-list and verify provenance; never let an agent resolve dependencies from an open
  registry unchecked.
- **Policy sprawl and drift.** Hand-maintained, divergent rulesets in CI vs. cluster
  produce contradictory verdicts and erode trust. Single-source policy, version it,
  test it.
- **Auto-merging on a partial-green.** Letting generated changes merge on lint-pass
  alone, before the full chain is green, reintroduces every risk the chain exists to
  remove.
- **Over-blocking → shadow IT.** Gates that fail too aggressively on style push
  engineers to `--force` and out-of-band `kubectl`, moving change *outside* the
  reviewer entirely.

## See also

- [[policy-as-code]]
- [[infrastructure-as-code]]
- [[cicd-pipeline-architecture]]
- [[kubernetes-at-design-level]]
- [[software-supply-chain-security]]
- [[vibe-coding-governance]]
- [[guardrails-and-output-validation]]
- [[delegate-review-own]]

## Sources

- Spracklen et al., *We Have a Package for You! A Comprehensive Analysis of Package Hallucinations by Code Generating LLMs* — https://arxiv.org/abs/2406.10279
- Socket, *The Rise of Slopsquatting: How AI Hallucinations Are Fueling a New Class of Supply Chain Attacks* (2025) — https://socket.dev/blog/slopsquatting-how-ai-hallucinations-are-fueling-a-new-class-of-supply-chain-attacks
- A. Nesbitt, *Slopsquatting meets Dependency Confusion* (Dec 2025) — https://nesbitt.io/2025/12/10/slopsquatting-meets-dependency-confusion.html
- Kubernetes docs, *Validating Admission Policy* (CEL, GA 1.30) — https://kubernetes.io/docs/reference/access-authn-authz/validating-admission-policy/
- CNCF, *Announcing Kyverno Release 1.15* (CEL policy types; graduation context) — https://www.cncf.io/blog/2025/08/30/announcing-kyverno-release-1-15/
- env0, *Checkov vs Trivy in 2026: IaC Scanning After tfsec and Terrascan* — https://www.env0.com/blog/best-iac-scan-tool-comparing-checkov-vs-tfsec-vs-terrascan
- Spacelift, *Top 12 Policy as Code (PaC) Tools in 2026* — https://spacelift.io/blog/policy-as-code-tools
- ControlMonkey, *2026 IaC Predictions: The Year Infrastructure Finally Grows Up* — https://controlmonkey.io/blog/2026-iac-predictions/
- tfir.io, *AI Code Quality in 2026: Guardrails for AI-Generated Code* — https://tfir.io/ai-code-quality-2026-guardrails/
