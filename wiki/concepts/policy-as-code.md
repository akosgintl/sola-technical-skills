---
title: Policy as Code
aliases: [PaC, policy-as-code, OPA, Rego, Kyverno, Gatekeeper]
type: concept
domain: platform
status: mature
tags: [platform, policy, governance, security, opa, rego, kyverno, sentinel, conftest]
updated: 2026-06-20
sources:
  - "https://platformengineering.org/blog/policy-as-code"
  - "https://calmops.com/devops/policy-as-code-opa-kyverno-admission-controller/"
  - "https://oneuptime.com/blog/post/2026-02-09-policy-as-code-kyverno-opa/view"
  - "https://www.red-team.sh/posts/policy-as-code-opa-kyverno-eks-security/"
  - "https://araji.medium.com/kubernetes-policy-as-code-kyverno-vs-opa-e44e0d613d8a"
  - "https://rutagon.com/insights/compliance-as-code-opa-rego-federal/"
---

# Policy as Code

> [!summary]
> Policy as Code (PaC) encodes organizational governance, security, and compliance rules as version-controlled, testable code that is automatically evaluated at CI/CD time and at Kubernetes admission time. Instead of manual review checklists and post-deployment audits, PaC makes compliance a gate: non-compliant infrastructure is rejected before it reaches production. The two dominant tools are OPA/Gatekeeper (general-purpose Rego-based, CNCF-graduated) and Kyverno (Kubernetes-native YAML policies with built-in mutation). Together they are the automated control plane for cloud governance.

**Domain:** [[tier-2-solid|Platform Engineering & IaC]]

## What it is

Policy as Code applies software engineering practices — version control, testing, peer review, CI/CD — to compliance rules. Instead of a PDF document that says "all S3 buckets must be encrypted" and relies on quarterly audits to verify, PaC expresses that rule as executable code evaluated on every deployment.

The key shift: **compliance left**. Violations are caught in the developer's pull request, not discovered in a production audit. The result is:
- **Consistent enforcement:** the same policy applies to every deployment, every environment, every team
- **Auditable:** every policy change is a commit with a diff, author, and timestamp
- **Testable:** policies have unit tests; regressions are caught before deployment
- **Scalable:** automated enforcement scales to 100 teams without adding auditors

## Why it matters

Manual compliance reviews are the bottleneck between engineering velocity and security assurance. At scale (dozens of teams, hundreds of deployments per day), manual review is not possible — it becomes theater. PaC replaces theater with automation.

The [[ai-generated-iac-reviewer]] pattern makes PaC even more important: when AI generates infrastructure code, policy gates are the automated reviewer that catches security misconfigurations the AI may produce.

## Key concepts / building blocks

### Open Policy Agent (OPA) and Rego

**OPA** is the CNCF-graduated general-purpose policy engine. It evaluates policies expressed in **Rego**, a declarative query language purpose-built for policy decisions. OPA is not Kubernetes-specific — it can enforce policies against any structured data (JSON, YAML, HCL, HTTP requests, API responses).

**How Rego works:** a Rego policy is a set of rules that query structured input data and produce a decision (allow/deny, plus contextual data for violation messages). Example:

```rego
package kubernetes.admission

deny[msg] {
    input.request.kind.kind == "Pod"
    container := input.request.object.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container %v must not run as privileged", [container.name])
}
```

**OPA Gatekeeper** is the Kubernetes admission webhook built on OPA. It enforces Rego policies via Kubernetes `ConstraintTemplate` (defines the policy schema) and `Constraint` (instantiates and configures it). As of Gatekeeper v3.22 (February 2026), it aligns with the upstream Kubernetes `ValidatingAdmissionPolicy` API while retaining Rego's expressive power for complex logic.

**Conftest** is the CI/CD companion to OPA: a CLI tool that evaluates Rego policies against configuration files (Terraform plans, Kubernetes YAML, Dockerfile, Helm charts) in CI pipelines before anything is applied to the cluster. The standard pattern: Conftest runs on the Terraform plan JSON in CI; Gatekeeper enforces the same policies at Kubernetes admission time.

### Kyverno

Kyverno is the Kubernetes-native alternative — policies are expressed as Kubernetes YAML resources, not a specialized language. Lower barrier to entry for teams already fluent in Kubernetes manifests.

**What Kyverno does beyond validation:**
- **Mutation:** automatically add labels, annotations, resource limits, or security contexts to resources that are missing them — instead of just rejecting
- **Generation:** automatically create companion resources (NetworkPolicy, LimitRange, ResourceQuota) when a namespace is created
- **Verification:** verify container image signatures (Sigstore/Cosign integration)

**Kyverno policy example (validation):**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  rules:
  - name: check-team-label
    match:
      resources:
        kinds: [Deployment]
    validate:
      message: "Deployment must have a 'team' label."
      pattern:
        metadata:
          labels:
            team: "?*"
```

### OPA vs. Kyverno decision

| Dimension | OPA/Gatekeeper | Kyverno |
|---|---|---|
| Policy language | Rego (specialized, powerful) | Kubernetes YAML (familiar, limited) |
| Learning curve | Higher (Rego is a new language) | Lower (YAML + pattern matching) |
| Complex logic | Excellent (loops, data joins, external data) | Limited (pattern-based) |
| Mutation | Requires separate mutating webhook | Built-in, first-class |
| Image signature verification | Via external integration | Built-in Cosign/Sigstore |
| Scope | General-purpose (Kubernetes + IaC + APIs) | Kubernetes-only |
| Kubernetes alignment | ValidatingAdmissionPolicy (v3.22+) | Native CRD-based |
| Best fit | Complex policies, multi-system enforcement | Kubernetes-native, simpler policies |

**Practical recommendation:** use Kyverno for Kubernetes-native policy (mutation, generation, simpler validation); use OPA/Conftest for IaC policy enforcement in CI (Terraform, CloudFormation) and complex cross-system logic. The tools are complementary, not mutually exclusive.

### HashiCorp Sentinel

Sentinel is the policy-as-code framework for the HashiCorp ecosystem (Terraform Cloud/Enterprise, Vault, Consul, Nomad). It enforces policies at the Terraform plan phase — before `apply` — in managed Terraform workflows.

Use when the organization is already invested in HCP Terraform/Terraform Enterprise and wants a managed policy gate without building custom CI checks.

### Enforcement modes: advisory vs. mandatory

Every PaC tool supports a spectrum of enforcement:

| Mode | Behavior | When to use |
|---|---|---|
| **Audit / warn** | Violation is logged, resource is allowed | Rollout phase; don't block teams while policies are being finalized |
| **Advisory (dry-run)** | Violation reported in PR/CI but not blocking | Policy development; visibility before enforcement |
| **Mandatory (enforce)** | Violation blocks deployment | Stable, well-understood policies; production |

**The rollout pattern:** start in audit mode to discover the scale of existing violations → fix existing resources → switch to warn to verify CI integration → switch to enforce. Never jump straight to enforcing a new policy — it will block your own deployments.

### What policies to encode

Common policy categories:

**Security:**
- No privileged containers; no `hostNetwork`/`hostPID`; no `runAsRoot`
- Required security contexts (read-only root filesystem, drop ALL capabilities)
- No `latest` image tags in production
- Required image signature verification (Cosign)
- No exposed Secrets in env vars (detect by key name patterns)

**Operational:**
- Required labels (`team`, `app`, `env`, `cost-center`)
- Required resource requests and limits on all containers
- Namespace quotas and LimitRanges must exist before workloads can deploy
- No directly-managed Pods (must use Deployment/StatefulSet)

**Compliance:**
- Allowed container registries (only internal registry; no `docker.io` in prod)
- Allowed cloud regions (data residency)
- Required encryption annotations on PersistentVolumeClaims
- Network policy must exist before pod can receive traffic

**Cost:**
- Maximum resource request thresholds (prevent resource hogs)
- Required cost-center labels for chargeback
- GPU workloads require justification annotation

## Design decisions & trade-offs

**Where to enforce: CI or admission controller (or both)?**
The standard answer: **both, with the same policies**. CI (Conftest) catches violations in PRs before code merges — fastest feedback, lowest cost. Admission controller (Gatekeeper/Kyverno) is the final safety net that catches anything that bypasses CI (direct kubectl applies, CD pipelines, operator-created resources). CI without admission control has gaps; admission control without CI has late feedback. Use both.

**Starting policy scope:**
Begin with a small set of high-signal, low-false-positive policies (required labels, no privileged containers, no latest tags). Expand after the team has confidence in the enforcement mechanics. A policy that blocks legitimate workloads on day one kills adoption.

**Handling legacy resources:**
Existing resources that violate new policies cannot be remediated before enforcement begins. Use Kyverno mutation to auto-remediate where possible (add missing labels); use audit mode with a defined remediation window before switching to enforce.

## State of the art

PaC has crossed from specialist practice to expected baseline in cloud-native organizations. Kyverno reached CNCF graduation in 2023 and is now the most widely adopted Kubernetes-native policy engine. OPA Gatekeeper aligns with the upstream Kubernetes `ValidatingAdmissionPolicy` API in v3.22 (2026), enabling native Kubernetes CEL-based policies to coexist with Rego policies.

**AI-generated IaC + PaC:** as AI code assistants generate Terraform and Kubernetes YAML, PaC gates are the automated reviewer. The pattern: AI generates IaC → Conftest validates against policy in CI → Gatekeeper/Kyverno validates at admission. See [[ai-generated-iac-reviewer]].

## Pitfalls & anti-patterns

**Jumping straight to enforce.** New policies in enforce mode block existing workloads. Always start in audit → warn → enforce with a remediation window.

**Policies without tests.** A Rego policy or Kyverno rule with no unit test will silently stop matching on the next refactor. Every policy must have test cases covering allow and deny paths.

**Overlapping OPA + Kyverno policies on the same resource.** Two engines enforcing conflicting policies on the same resource produces unpredictable behavior and hard-to-debug rejections. Define clear ownership: Kyverno for K8s mutation/generation, OPA for complex validation and IaC.

**Treating policy exceptions as permanent.** Every policy exception is a security debt. Use time-bounded exemptions with a required renewal date, not permanent carve-outs.

## See also

- [[ai-generated-iac-reviewer]]
- [[infrastructure-as-code]]
- [[cicd-pipeline-architecture]]
- [[cloud-governance-at-scale]]
- [[software-supply-chain-security]]
- [[zero-trust-architecture]]

## Sources

- Platform Engineering. (2026). Policy as Code: The Platform Engineer's Guide to Automated Governance. https://platformengineering.org/blog/policy-as-code
- CalmOps. (2026). Policy as Code: Automating Security and Compliance with OPA and Kyverno. https://calmops.com/devops/policy-as-code-opa-kyverno-admission-controller/
- OneUptime. (2026). How to Build Policy as Code Frameworks for Kubernetes. https://oneuptime.com/blog/post/2026-02-09-policy-as-code-kyverno-opa/view
- Red-Team.sh. (2026). Policy-as-Code on AWS: OPA and Kyverno for Kubernetes Security. https://www.red-team.sh/posts/policy-as-code-opa-kyverno-eks-security/
- Raji, A. (2026). Kubernetes Policy-as-Code: Kyverno vs. OPA. https://araji.medium.com/kubernetes-policy-as-code-kyverno-vs-opa-e44e0d613d8a
- Rutagon. (2026). Compliance as Code: OPA and Rego for Federal CI/CD. https://rutagon.com/insights/compliance-as-code-opa-rego-federal/
