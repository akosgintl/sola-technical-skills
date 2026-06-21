---
title: Cost Optimization Practice
aliases: [cost optimization, right-sizing, showback, chargeback, FinOps practice]
type: concept
domain: finops
status: mature
tags: [finops, optimization, right-sizing, accountability, spot, karpenter, commitment]
updated: 2026-06-21
sources:
  - https://www.finops.org/introduction/what-is-finops/
  - https://docs.aws.amazon.com/compute-optimizer/latest/ug/what-is-compute-optimizer.html
  - https://karpenter.sh/docs/
  - https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html
  - https://cloud.google.com/recommender/docs/overview
  - https://azure.microsoft.com/en-us/products/cost-management
---

# Cost Optimization Practice

> [!summary]
> Cost optimization practice is the ongoing operational discipline of eliminating cloud waste and aligning spend with value — through right-sizing, commitment management, storage tiering, and cost accountability — after the architecture is running. It is the run-phase complement to cost modeling: the model identifies the opportunity; this practice captures it.

**Domain:** [[tier-2-solid|FinOps & Cost Architecture]]

## What it is

Cloud cost optimization is not a one-time event. The infrastructure that was correctly sized at launch drifts: workload patterns change, experiments are never decommissioned, reserved instances expire and revert to on-demand, and new services are provisioned without lifecycle policies. Optimization practice is the set of recurring activities that detect and correct this drift.

The FinOps Foundation classifies cloud waste into four categories: idle and unattached resources (unused EC2 instances, unattached EBS volumes, orphaned load balancers), oversized resources (instances provisioned for peak load running at 10 % average CPU), pricing model mismatch (on-demand pricing for workloads that have been running continuously for months), and storage inefficiency (all data in hot tier regardless of access frequency). The 2025 State of FinOps report found that 32 % of cloud spend across surveyed organisations falls into one of these categories — and that the majority of it is recoverable without architectural change.

## Why it matters

Waste accumulates invisibly. A cloud account without active optimization reviews will, within 12 months, contain decommissioned development environments left running, EBS volumes orphaned when their instances were terminated, on-demand instances that have been running continuously for a year, and S3 buckets where all objects are in the Standard tier regardless of whether they have been accessed since creation. These costs compound: a $5,000/month waste item that goes unaddressed for 12 months costs $60,000 — more than the engineering time to fix it.

Beyond waste elimination, optimization practice drives the commitment purchasing decisions that produce the largest single-line savings: a workload shifted from on-demand to a 1-year Compute Savings Plan saves 30–50 % immediately, with no architectural change required. The bottleneck is the organisational process to identify which workloads are stable enough to commit, purchase the commitment, and track coverage over time.

## Key concepts

### Right-sizing

Right-sizing matches instance type and size to the actual resource utilisation of the workload. The default behaviour without right-sizing: instances are provisioned for expected peak load, peak load is over-estimated, and average CPU/memory utilisation is 15–30 %.

**AWS Compute Optimizer** analyses 14 days of CloudWatch metrics (CPU, memory, network, disk) and produces recommendations per instance, Auto Scaling Group, ECS service, Lambda function, and EBS volume. Recommendations are categorised as over-provisioned, under-provisioned, or optimised, with a projected monthly savings for each change. Compute Optimizer requires the CloudWatch agent for memory metrics (not collected by default).

**Azure Advisor** and **GCP Recommender** provide equivalent services with similar methodology.

**Kubernetes right-sizing** is more complex because pod requests and limits are set at deployment time and rarely revisited. Two tools:
- **Vertical Pod Autoscaler (VPA)** in `Off` mode produces resource recommendations without applying them — use as an advisory signal before adjusting requests/limits.
- **Goldilocks** (Fairwinds) provides a dashboard over VPA recommendations across all namespaces, surfacing the pods with the highest savings potential.
- **Karpenter** (AWS, CNCF Sandbox) provisions nodes on demand to fit the actual pod requests, selecting the cheapest instance type that fits. Compared to Cluster Autoscaler, Karpenter achieves better bin-packing and automatically considers Spot instance availability, reducing effective compute cost 30–50 % on mixed Spot/on-demand clusters.

**Right-sizing cadence:** monthly review using Compute Optimizer / Advisor output. Right-sizing changes to production instances should be treated as deployments — tested in staging, applied during a maintenance window, monitored for regression. Not every recommendation should be accepted: the cost saving must be weighed against the risk of hitting a utilisation ceiling on the new, smaller instance.

### Idle resource elimination

Idle resources generate cost with zero business value. Common categories:

| Resource type | Detection | Typical action |
|---|---|---|
| Unattached EBS volumes | CloudWatch `VolumeQueueDepth = 0` for >7 days | Snapshot and delete |
| Unused Elastic IPs | AWS Cost Explorer: EIP not associated with running instance | Release |
| Idle load balancers | ALB/NLB `RequestCount = 0` for >7 days | Delete if not needed |
| Orphaned snapshots | Snapshots whose source volume no longer exists | Delete after age threshold |
| Stopped EC2 instances | `InstanceState = stopped` for >7 days | Terminate (snapshot root volume first) |
| Empty/idle S3 buckets | Zero GET requests, zero PUT requests for >30 days | Review and delete |
| Dev/staging environments running nights/weekends | Schedule-based | AWS Instance Scheduler or Lambda + EventBridge |

Non-production environment scheduling is the highest-ratio intervention: shutting down development and staging instances from 7 PM to 7 AM and on weekends reduces non-production compute costs by 50–60 % with no functional impact.

**Tagging-gated lifecycle policies:** tag resources with `lifecycle: ephemeral` and `expires: YYYY-MM-DD` at creation. A Lambda function running nightly checks for resources past their expiry date and generates alerts (or auto-terminates, if the team accepts the automation risk).

### Commitment management

**Purchase process.** Commitments (RIs, Savings Plans, CUDs) should be purchased against the stable baseline of compute — not the peak. The process:
1. Export 90 days of hourly on-demand instance usage from Cost Explorer.
2. Identify the minimum sustained usage (the floor, not average or peak).
3. Purchase commitments to cover 60–70 % of that floor.
4. Leave 30–40 % on-demand to absorb variance and growth.
5. Repeat the review quarterly; purchase additional commitments if the floor has grown.

**Savings Plans vs. Reserved Instances.** Compute Savings Plans are more flexible (apply across EC2 families, sizes, OS, and Fargate/Lambda) and require less analysis than RIs. Use Compute Savings Plans as the default; EC2 Instance Savings Plans or RIs only when the workload is locked to a specific instance family and size for the full commitment term.

**RI marketplace.** AWS allows Reserved Instances to be resold on the RI Marketplace. If an RI becomes over-committed due to workload reduction, the remaining term can be partially recovered by listing it for sale. Azure and GCP do not have equivalent marketplaces — cancellation or exchange options are more limited.

**Commitment utilisation tracking.** A purchased commitment generates savings only if actual usage covers it. Monitor RI/Savings Plan utilisation in Cost Explorer: target >95 % utilisation. A utilisation below 80 % means commitments were over-purchased — adjust the next purchasing cycle.

### Storage optimisation

**S3 Intelligent-Tiering** monitors access patterns per object and moves objects automatically between access tiers (Frequent, Infrequent, Archive Instant Access, Archive) at a monitoring cost of $0.0025 per 1,000 objects. For any S3 bucket containing objects that have unpredictable or mixed access patterns, Intelligent-Tiering typically saves 30–50 % of storage costs with no retrieval latency penalty for the Frequent and Infrequent tiers.

**S3 lifecycle policies** for predictable access patterns: transition objects to Infrequent Access after 30 days, to Glacier Instant after 90 days, expire (delete) after the retention period. The lifecycle policy is effectively free; the savings on cold data are significant.

**EBS gp3 migration.** gp3 volumes provide 3,000 IOPS and 125 MB/s baseline throughput at $0.08/GB-month, 20 % cheaper than gp2 at $0.10/GB-month. The migration from gp2 to gp3 is non-disruptive and available via the console, CLI, or IaC. Existing provisioned IOPS (io1/io2) volumes should be audited: many are provisioned for IOPS that are never reached.

**Snapshot lifecycle.** Manual snapshots accumulate without automated cleanup. AWS Data Lifecycle Manager creates and expires EBS snapshots on a schedule. Monthly review of snapshot inventory to delete orphaned and expired snapshots is standard FinOps hygiene.

### Cost accountability

**Showback** reports cloud costs to consuming teams — usually as a monthly report broken down by service, environment, and team. It creates visibility without transferring budget responsibility. Sufficient to drive significant cost-aware behaviour in most engineering organisations, and far easier to implement than chargeback.

**Chargeback** transfers actual cloud costs to the consuming team's budget. Stronger behavioural incentive; requires a budget structure where team leads own cloud spend, and an internal billing process to move the costs. Appropriate for large organisations or business units where cloud is a significant cost driver.

**Budget alerts.** AWS Budgets, Azure Budgets, and GCP Budget Alerts send notifications (and optionally trigger automation) when spend reaches a percentage of a defined budget. Set monthly budgets per environment and per team; alert at 80 % and 100 % of budget; investigate anomalies before the month closes.

**Cost anomaly detection.** AWS Cost Anomaly Detection uses ML to identify spend increases that are inconsistent with historical patterns, alerting within hours. Useful for catching runaway workloads, misconfigured autoscaling, or accidental large-scale data operations before they appear on the monthly bill.

### FinOps review cadence

| Frequency | Activity |
|---|---|
| Daily | Cost anomaly detection review; alert triage |
| Weekly | Top-10 cost variance review; new idle resource identification |
| Monthly | Right-sizing recommendations review; commitment utilisation review; team showback reports |
| Quarterly | Commitment purchasing review; architecture cost review; storage tier audit |
| Annually | RI/Savings Plan renewal decisions; FinOps maturity assessment |

## Design decisions and trade-offs

**Automation vs. human approval for cost actions.** Fully automated right-sizing and idle resource termination maximises savings velocity but carries risk: an instance identified as "stopped for 7 days" may be stopped intentionally. A human-approval step on terminations (automation identifies, human approves) avoids false-positive deletions while still capturing most of the saving. Fully automated safe-delete (snapshot first, then delete) is appropriate for storage cleanup.

**Showback vs. chargeback.** Showback is the right starting point: it provides the visibility needed to drive behaviour without the organisational complexity of internal billing. Implement chargeback only when showback has been running long enough to establish credibility and team-level budget ownership is already a cultural norm.

**Optimisation frequency vs. engineering distraction.** Monthly right-sizing reviews produce diminishing returns if the environment is stable. Quarterly reviews with monthly anomaly monitoring is the right steady-state for most teams. Daily cost-chasing is a distraction; it signals a FinOps process that lacks prioritisation.

## State of the art

**Karpenter** (CNCF Sandbox, widely adopted on EKS) is the current best practice for Kubernetes compute cost optimisation: it provisions the cheapest instance that fits the pending pod's requests, considers Spot availability and interruption rates, and consolidates nodes when underutilised. Karpenter replaces the Cluster Autoscaler + manual instance type selection pattern.

**AWS Compute Optimizer** added ECS on Fargate right-sizing recommendations in 2024, extending coverage beyond EC2 to serverless container workloads.

**GCP Recommender** provides cross-service recommendations (Compute, BigQuery, Cloud Storage, Kubernetes) with projected monthly savings per recommendation, and can auto-apply low-risk recommendations via GCP's automated optimization flags.

**FOCUS** (FinOps Open Cost and Usage Specification, v1.0, FinOps Foundation 2024): a vendor-neutral schema for cloud cost data, enabling cross-provider cost analysis with consistent field names. AWS, Azure, and GCP all publish FOCUS-compliant exports.

> [!tip]
> The three highest-ROI interventions in order: (1) purchase Compute Savings Plans at 60 % of stable baseline — saves 30–50 % of that compute with a single decision; (2) enable S3 Intelligent-Tiering on all buckets — saves 30–50 % of storage with zero operational overhead; (3) schedule non-production environment shutdown — saves 50–60 % of dev/staging compute. All three are reversible, low-risk, and require no architectural change.

## Pitfalls and anti-patterns

- **Optimising without tagging.** Cost optimisation requires knowing which resources belong to which team or workload. Without a tagging standard, you can identify waste but not assign it for action.
- **Right-sizing production without staging validation.** Applying a Compute Optimizer recommendation directly to a production instance without first validating on staging risks a performance regression at the worst possible time.
- **Purchasing commitments at peak, not floor.** Commitments purchased to cover peak load will be underutilised as soon as the peak passes. Always commit to the floor; let on-demand cover the variance.
- **Treating Spot as cost reduction without reliability design.** Spot saves 60–90 % but requires interruption handling. Running stateful workloads or critical services on Spot without checkpoint/restart logic turns a cost optimisation into a reliability incident.
- **No anomaly detection.** A misconfigured autoscaling group or an accidentally left-running batch job can double a month's cloud bill. Cost Anomaly Detection catches these within hours; discovering them on the monthly bill is weeks too late.
- **Ignoring non-production costs.** Development and staging often account for 30–50 % of cloud spend. The lowest-effort cost optimisation in most organisations is scheduling non-production environments to shut down at night and on weekends.
- **One-time optimisation sprint.** Cloud cost optimisation done once and not revisited drifts back toward waste within 6 months as new resources are provisioned without discipline. Optimisation must be a recurring practice, not a project.

## See also

- [[cloud-cost-modeling]] — the cost model that identifies where spend is and what the unit economics should be
- [[ai-gpu-economics]] — GPU and inference cost structures with specific optimisation techniques
- [[cloud-governance-at-scale]] — organisational governance that enforces cost policies across accounts
- [[observability-fundamentals]] — the metrics infrastructure that cost optimisation tools read
- [[policy-as-code]] — cost policy enforcement in IaC pipelines (Infracost + OPA)
- [[serverless-architecture]] — scale-to-zero as a cost optimisation architecture pattern

## Sources

- FinOps Foundation (2025). *What is FinOps? State of FinOps 2025.* https://www.finops.org/introduction/what-is-finops/
- AWS (2024). *AWS Compute Optimizer User Guide.* https://docs.aws.amazon.com/compute-optimizer/latest/ug/what-is-compute-optimizer.html
- Karpenter Project (2025). *Karpenter Documentation.* https://karpenter.sh/docs/
- AWS (2024). *Well-Architected Framework — Cost Optimization Pillar.* https://docs.aws.amazon.com/wellarchitected/latest/cost-optimization-pillar/welcome.html
- Google Cloud (2024). *Cloud Recommender Overview.* https://cloud.google.com/recommender/docs/overview
- Microsoft (2024). *Azure Cost Management + Billing.* https://azure.microsoft.com/en-us/products/cost-management
