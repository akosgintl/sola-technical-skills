---
title: CI/CD Pipeline Architecture
aliases: [CI/CD, continuous integration, continuous delivery, progressive delivery, GitOps, DORA]
type: concept
domain: platform
status: mature
tags: [platform, cicd, delivery, deployment, gitops, progressive-delivery, canary, blue-green, dora]
updated: 2026-06-20
sources:
  - "https://cloudnativenow.com/contributed-content/implementing-ci-cd-for-cloud-native-applications-the-right-way/"
  - "https://www.digitalapplied.com/blog/ci-cd-pipeline-design-2026-engineering-reference"
  - "https://dev.to/safdarwahid/progressive-delivery-for-cicd-pipelines-3mlm"
  - "https://middleware.io/blog/what-is-a-ci-cd-pipeline/"
  - "https://www.ceiba.com.co/en/ceiba-blog-tech/ceiba-blog/ci-cd-pipeline-optimization-in-2026/"
  - "https://arxiv.org/pdf/2508.11867"
---

# CI/CD Pipeline Architecture

> [!summary]
> CI/CD pipeline architecture governs how code changes flow from commit to production with speed, safety, and auditability. Modern practice combines trunk-based development (short-lived branches, frequent integration), progressive delivery (canary, blue-green, feature flags to limit blast radius), and GitOps (Git as the single source of truth for deployed state). DORA metrics (deployment frequency, lead time, change failure rate, MTTR) measure whether the pipeline is actually delivering value. Teams adopting these practices deploy 208× more frequently with 3× lower change failure rates.

**Domain:** [[tier-2-solid|Platform Engineering & IaC]]

## What it is

CI/CD stands for two overlapping disciplines:

**Continuous Integration (CI):** every developer integrates their changes to the main branch frequently (ideally multiple times per day). Each integration triggers automated build, test, and static analysis. The goal: catch integration failures in minutes, not in a quarterly merge window.

**Continuous Delivery (CD):** the artifact produced by CI is always in a deployable state. Every passing build could be released to production. The deployment is a decision, not a technical event.

**Continuous Deployment:** every passing build is automatically deployed to production without human approval. Not always appropriate (regulated industries, customer-facing features needing controlled rollout) but is the ceiling of delivery velocity.

The practical meaning in 2026: CI/CD is a pipeline of automated gates (build → test → scan → publish → deploy) that moves code changes through environments with increasing confidence, ending in production. The design question is which gates to apply at which stage, how to limit blast radius on deployment, and how to roll back when something goes wrong.

## Why it matters

Manual deployment processes are the bottleneck between engineering productivity and delivered value. Slow, error-prone releases create negative feedback loops: fear of deploying leads to bigger batches, bigger batches mean longer feedback cycles, longer cycles increase the blast radius of each failure, larger blast radius increases fear of deploying. CI/CD breaks this cycle.

DORA's State of DevOps research (2025) demonstrates that elite-performing teams deploy 208× more frequently, have 106× shorter lead times, 7× lower change failure rates, and 2,604× faster MTTR than low performers. These are not marginal improvements — they are order-of-magnitude differences enabled by CI/CD discipline.

## Key concepts / building blocks

### CI pipeline stages

A CI pipeline runs on every commit or pull request:

**1. Build:** compile the application, build the container image, produce a deployable artifact with an immutable version tag (Git SHA or semantic version). The artifact should be built once and promoted through environments — never rebuilt per environment.

**2. Unit and integration tests:** fast tests (unit: <1 min, integration: <5 min) that verify correctness. Gate: fail the pipeline on any test failure.

**3. Static analysis:** lint, type checking, code style. Catches obvious errors without running the code.

**4. Security scanning:**
- **SAST (Static Application Security Testing)** — scan source code for vulnerabilities (Semgrep, CodeQL)
- **SCA (Software Composition Analysis)** — scan dependencies for known CVEs (Dependabot, Snyk, OWASP Dependency-Check)
- **Container image scanning** — scan the built image for OS and application vulnerabilities (Trivy, Grype)
- **IaC scanning** — check infrastructure changes for misconfigurations (Checkov, tfsec)

**5. Artifact publish:** push the tested image to a container registry. Tag immutably; never use `latest` in production deployments.

**6. Policy gates:** automated policy checks via OPA/Conftest on the deployment manifest or Terraform plan. Block deploys that violate security or cost policy. See [[policy-as-code]].

**Pipeline platforms:** GitHub Actions (dominant for open-source and SaaS teams), GitLab CI (strong for self-hosted), Jenkins (legacy; powerful but operationally heavy), Tekton (Kubernetes-native), CircleCI, Buildkite.

### CD and environment promotion

CD moves the validated artifact from dev → staging → (optional) pre-prod → production. Each stage applies the same artifact with environment-specific configuration (feature flags, connection strings, resource sizes).

**Environment promotion principles:**
- The artifact (container image) is immutable; only configuration varies per environment
- Staging should mirror production topology as closely as cost allows — divergence means staging misses bugs that production catches
- Production deploys require an explicit trigger (manual approval for CD, automated for continuous deployment)
- Rollback is a deployment of the previous artifact — not a code revert

### GitOps

GitOps extends CD by treating Git as the single source of truth for the deployed state of every environment. A GitOps controller (Argo CD, Flux) watches a Git repository and continuously reconciles the cluster state to match what is declared in Git.

**Pull-based model (the GitOps way):** the CI pipeline pushes a new image tag to Git; the GitOps controller pulls the change and applies it to the cluster. The controller runs inside the cluster — it does not need inbound network access from the CI system. This is more secure than push-based (CI pipeline with cluster credentials).

**Argo CD:** the dominant GitOps tool for Kubernetes. Supports Application CRDs, multi-cluster deployment, sync waves (ordering), and health assessment per resource type. Provides a UI showing the live diff between Git and cluster state.

**Flux:** alternative GitOps tool; more lightweight; native Helm and Kustomize support; better for automation-first orgs.

**GitOps for infrastructure:** same model applied to Terraform/OpenTofu via Atlantis or Terraform Cloud agent — any merge to the infrastructure repo triggers a plan; an approval triggers apply.

### Progressive delivery

Progressive delivery decouples deployment (the artifact is running in production) from release (users see the new behavior). This limits blast radius to a controlled percentage of traffic while verifying the new version.

**Canary deployment:**
- Route a small percentage of traffic (1%, 5%, 10%) to the new version
- Monitor error rate, latency, and business metrics for the canary
- If metrics are healthy, progressively increase traffic; if not, roll back immediately
- Automated canary analysis: Argo Rollouts + Prometheus metrics, or Flagger (progressive delivery operator)

**Blue-green deployment:**
- Two identical production environments (blue = current, green = new)
- Deploy and validate the new version on green with zero user traffic
- Switch the load balancer to green; blue becomes the rollback target
- Simple to reason about; requires double the production infrastructure during the cutover

**Feature flags:**
- Code changes are deployed to production but activated/deactivated by a runtime flag
- Enables dark launches (code deployed but inactive), percentage rollouts, and A/B tests
- Decouples deployment from business release decisions
- Platforms: LaunchDarkly, Flagsmith, OpenFeature (vendor-neutral standard), GrowthBook
- Anti-pattern: feature flags that accumulate without cleanup become permanent technical debt; every flag should have a removal date

**Ring-based deployment:** route traffic progressively across rings (canary → early adopters → general availability → full production). Used by Microsoft Windows Update, Azure, and others for large user bases.

### DORA metrics

DORA (DevOps Research and Assessment) defines four metrics that predict organizational delivery performance:

| Metric | What it measures | Elite threshold |
|---|---|---|
| **Deployment frequency** | How often code is deployed to production | Multiple times per day |
| **Lead time for changes** | Time from commit to running in production | <1 hour |
| **Change failure rate** | % of deployments causing production incident | <5% |
| **Time to restore (MTTR)** | Time to recover from a production failure | <1 hour |

These are outcome metrics, not process metrics. They measure the result of CI/CD investment, not whether you have Jenkins installed.

The 2025 DORA model restructuring added **reliability** as a fifth domain: SLO performance as an organizational metric alongside the four delivery metrics.

### Supply chain security integration

Every build artifact should have a verifiable provenance chain:
- **SBOM (Software Bill of Materials)** — a machine-readable inventory of all dependencies (SPDX or CycloneDX format); generated at build time; required by US Executive Order 14028 and EU Cyber Resilience Act
- **Image signing** — sign container images (Cosign/Sigstore) so the CD system verifies signatures before deploying
- **SLSA (Supply Chain Levels for Software Artifacts)** — a framework for hardening the build pipeline against tampering; SLSA Level 2 requires hosted build systems and provenance attestations

See [[software-supply-chain-security]] for the full treatment.

## Design decisions & trade-offs

**Trunk-based development vs. long-lived feature branches:**
Trunk-based development (all changes integrate to main within hours or days) is the CI prerequisite. Long-lived feature branches accumulate merge debt and defeat the purpose of continuous integration. Use feature flags to ship incomplete features safely; keep branches short. The exception: open-source projects where external contributors need longer-lived branches for review workflows.

**Canary vs. blue-green:**

| Criteria | Canary | Blue-green |
|---|---|---|
| Infrastructure cost | Low (small % of traffic on new version) | High (double production during cutover) |
| Rollback speed | Requires shifting traffic back (seconds) | Instant (flip load balancer) |
| Risk exposure | Configurable (1% → 100%) | Binary (0% or 100%) |
| Complexity | Higher (metrics + automated analysis) | Lower |
| Best for | High-traffic services needing fine-grained rollout | Lower-traffic services, databases, stateful changes |

**When to use feature flags vs. canary:**
Feature flags are for product decisions (who sees this feature, A/B testing, kill switch). Canary is for deployment risk management (is this version stable?). Use both: canary to validate stability, feature flags to control product release.

**Monorepo vs. polyrepo CI/CD:**
Monorepo: one pipeline, one CI definition, simpler cross-service dependency management; challenge is build performance (only rebuild what changed). Polyrepo: independent pipelines per service, simpler blast radius; challenge is coordinating cross-service changes. Affected-path CI (Turborepo, Nx, Bazel) solves monorepo build performance.

## State of the art

GitOps adoption in enterprises has accelerated in 2025-2026; pushing Docker images to Kubernetes via Argo CD or Flux is now the default deploy pattern for K8s-based services. AI-augmented CI/CD (arXiv:2508.11867) is emerging — models that automatically diagnose pipeline failures, suggest fixes, and propose rollback decisions. Still early but directionally significant.

**Security gates becoming mandatory:** SBOM generation, image signing (Sigstore/Cosign), and supply chain verification are moving from optional to required in enterprise pipeline standards, driven by US EO 14028 and EU CRA compliance.

**Pipeline observability:** applying the same observability principles as application services to the CI/CD pipeline itself — metrics on pipeline duration, failure rates, queue times — enables data-driven pipeline optimization.

## Pitfalls & anti-patterns

**Deploying to production on Fridays.** Not a technical anti-pattern but an operational one. Production deploys before the weekend leave incidents without full team availability for recovery. Encode deploy blackout windows in the pipeline.

**Manual production deploys.** Any deploy that requires a human clicking buttons is not repeatable, not auditable, and not scalable. All production deploys must be automated, gated by tests and approvals, and logged.

**`latest` image tags.** Deploying `myapp:latest` means the running version is unknown and rollback to "the previous version" is impossible. Tag every image immutably with Git SHA.

**Untested rollback.** Rollback procedures that have never been exercised will fail during incidents. Practice rollbacks in staging regularly; measure rollback time against your MTTR target.

**Feature flag debt.** Flags that were never removed. Every active flag is a code path that must be maintained, tested, and tracked. Set a TTL for every flag at creation; review quarterly.

**No DORA metrics.** Optimizing pipeline speed without measuring outcomes. Deploy frequency going up while MTTR and change failure rate also increase means you're shipping problems faster. Measure all four.

## See also

- [[software-supply-chain-security]]
- [[infrastructure-as-code]]
- [[policy-as-code]]
- [[developer-experience]]
- [[distributed-systems-reliability]]
- [[kubernetes-at-design-level]]

## Sources

- Cloud Native Now. (2026). Implementing CI/CD for Cloud-Native Applications the Right Way. https://cloudnativenow.com/contributed-content/implementing-ci-cd-for-cloud-native-applications-the-right-way/
- Digital Applied. (2026). CI/CD Pipeline Design in 2026: Engineering Reference. https://www.digitalapplied.com/blog/ci-cd-pipeline-design-2026-engineering-reference
- Dev.to / Safdar Wahid. (2026). Progressive Delivery for CI/CD Pipelines. https://dev.to/safdarwahid/progressive-delivery-for-cicd-pipelines-3mlm
- Middleware.io. (2026). What Is a CI/CD Pipeline? Complete Guide to Faster, Safer Software Delivery. https://middleware.io/blog/what-is-a-ci-cd-pipeline/
- Ceiba Software. (2026). Everything You Need to Know About CI/CD Pipeline Optimization in 2026. https://www.ceiba.com.co/en/ceiba-blog-tech/ceiba-blog/ci-cd-pipeline-optimization-in-2026/
- Liu, Y. et al. (2025). AI-Augmented CI/CD Pipelines: From Code Commit to Production with Autonomous Decisions. arXiv:2508.11867. https://arxiv.org/pdf/2508.11867
