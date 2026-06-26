---
title: Disaster Recovery & Business Continuity
aliases: [disaster recovery, DR, business continuity, BCP, BCDR, backup strategy, failover, RTO, RPO]
type: concept
domain: cloud
status: mature
tags: [cloud, disaster-recovery, business-continuity, backup, rto-rpo, ransomware, resilience]
updated: 2026-06-26
sources:
  - "https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html"
  - "https://aws.amazon.com/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-i-strategies-for-recovery-in-the-cloud/"
  - "https://calmops.com/cloud/cloud-disaster-recovery-2026/"
  - "https://www.rubrik.com/insights/aws-disaster-recovery-strategy-guide"
  - "https://www.harness.io/blog/disaster-recovery-testing-a-practical-step-by-step-guide-for-2026"
  - "https://www.iso.org/standard/75106.html"
---

# Disaster Recovery & Business Continuity

> [!summary]
> Disaster recovery (DR) and business continuity planning (BCP) are the discipline of
> **recovering** a system after a failure too large or too correlated for in-system resilience
> to absorb — a region outage, ransomware, mass data corruption, an accidental deletion, or a
> provider/control-plane failure. Where [[distributed-systems-reliability|resilience patterns]]
> keep a running system *serving* under partial failure, DR is what you invoke when failure
> exceeds what graceful degradation can hide: you fail over, restore, and resume. The whole
> discipline hangs on two numbers per workload — **RTO** (how fast you must be back) and **RPO**
> (how much data you can afford to lose) — and on one hard truth: **an untested DR plan is a
> hypothesis, not a capability.**

**Domain:** [[tier-1-edge|Cloud Architecture]]

## What it is

Business continuity is the broad goal — the business keeps operating through a disruption;
disaster recovery is the technical subset — restoring IT systems and data. The practice starts
with a **business impact analysis (BIA)**: for each system, what does an outage cost per hour,
what data loss is tolerable, and what depends on it? The BIA assigns each workload a tier and,
from that, its recovery objectives:

- **RTO (Recovery Time Objective)** — maximum tolerable downtime; sets how fast failover/restore
  must complete.
- **RPO (Recovery Point Objective)** — maximum tolerable data loss; sets backup frequency and
  replication lag.

(These objectives and the underlying HA-pattern/replication-lag trade-offs are shared with
[[distributed-systems-reliability]]; this page treats them as the *inputs to a recovery
strategy* rather than re-deriving them.)

DR exists because some failures are **correlated and catastrophic**, defeating the redundancy
that resilience relies on:

- **Region / AZ outage** — a whole cloud region fails (documented for every major provider).
  Multi-AZ redundancy does not help; you need another region.
- **Ransomware / malicious deletion** — an attacker (or a bad actor with credentials) encrypts
  or deletes data *and the backups*. Replication faithfully copies the damage.
- **Data corruption / bad deploy** — a logic bug or migration corrupts data across all replicas.
  High availability replicates the corruption instantly.
- **Accidental deletion / config error** — `terraform destroy` on the wrong workspace, a fat-
  fingered bucket purge.
- **Provider / dependency failure** — a control-plane outage, an expired certificate, a SaaS
  dependency going dark.

## Why it matters

Resilience and DR are complementary, not the same: resilience absorbs the *expected* partial
failures (a slow dependency, a dead instance); DR answers the *unexpected, total* ones. Two
forces have pushed DR from a dusty binder to an active architecture concern:

- **Ransomware made backups the primary target.** Attackers now go after the backup system
  *first*, because destroying recovery points is how they force the ransom. A backup strategy
  that doesn't assume its backups will be attacked is incomplete — which is why **immutability**
  is now table stakes.
- **Regulators now demand *evidence* of testing.** ISO 22301, ISO/IEC 27001, PCI DSS, HIPAA,
  DORA (EU finance), and FFIEC increasingly expect documented, periodic DR tests with recorded
  outcomes and tracked remediation — not a written plan that has never been exercised. See
  [[compliance-and-regulation]].

## Key concepts / building blocks

### The cloud DR strategy ladder

The canonical framing (AWS Well-Architected, mirrored by Azure/GCP) is four strategies of
rising cost and falling RTO/RPO. The choice is a **cost-vs-recovery dial**, set per workload by
its BIA tier:

| Strategy | RTO | RPO | How it works | Relative cost |
|---|---|---|---|---|
| **Backup & Restore** | Hours–days | Hours | Restore data + rebuild infra in the recovery region from backups | Lowest |
| **Pilot Light** | ~10s of min | Minutes | Core data replicated live; minimal infra idle — must be *started & scaled* on failover | Low–moderate |
| **Warm Standby** | Minutes | Seconds–min | A scaled-down but **running** copy that takes traffic immediately, then scales up | Moderate–high |
| **Multi-site Active/Active** | Near-zero | Near-zero | Traffic served from 2+ regions simultaneously; any region can fail with no downtime | Highest |

The distinction that trips teams up: **pilot light is *off* and must be turned on; warm standby
is *on* at reduced capacity.** Map these onto the HA-pattern table in
[[distributed-systems-reliability]] — they are the same dial viewed from the recovery side.

### Backup strategy: 3-2-1 → 3-2-1-1-0

The classic **3-2-1** rule (3 copies, 2 media types, 1 offsite) has evolved for the ransomware
era into **3-2-1-1-0**: add **1 immutable or air-gapped copy** and **0 errors in recovery
testing**. The critical additions:

- **Immutability (WORM).** A backup that *cannot be altered or deleted* — even by an admin with
  root — for its retention period. This is what defeats ransomware, which works by abusing
  privileges to destroy backups. Cloud-native: **AWS S3 Object Lock**, **Azure Immutable Blob
  Storage**, **GCS bucket lock / retention policies**.
- **Isolation / air-gap.** Keep at least one recovery copy in a separate account, region, or
  trust domain so a compromise of the primary environment can't reach it.
- **The "0": tested restores.** A backup you've never restored is unverified. Corruption,
  missing dependencies, and broken restore tooling are discovered only by restoring.

### Replication and data movement

Cross-region replication keeps RPO low: **S3 cross-region replication**, **RDS read replicas**,
**Aurora Global Tables**, object/blob geo-replication. The async-vs-sync trade-off (sync = zero
RPO but added write latency and reduced availability) is the replication-lag decision covered in
[[distributed-systems-reliability]]. Note replication is *not* backup — it propagates deletes
and corruption; you need both.

### DR as code, and automated failover

Mature DR treats the recovery environment as reproducible **[[infrastructure-as-code|IaC]]**
(Terraform/CloudFormation/Bicep), so the recovery region is version-controlled and rebuildable
rather than a hand-maintained snowflake that has silently drifted. Failover is **automated**:
health checks (e.g. Route 53 / Traffic Manager) detect the failure, runbooks (or managed
services) shift traffic and promote replicas, and the whole path is observable. Manual,
console-driven recovery is too slow and too error-prone under incident pressure.

### Testing: the part everyone skips

> [!tip]
> Treat DR testing as a *product, not a project*. A plan that hasn't been exercised will fail in
> the ways you didn't rehearse.

A tiered cadence is the norm: **quarterly** backup-restore validation for priority systems;
**biannual** failover drills for high-tier workloads; **game days / table-top exercises** for
the human runbook. Modern practice validates *usable, clean* recovery points (granular restores,
direct backup queries) rather than only full-environment restores, and explicitly verifies a
**last-known-clean recovery point** for ransomware scenarios.

### Failover — and failback

Failover gets the attention; **failback** (returning to the primary once it recovers, without
losing data written during the failover) is harder and routinely neglected. A DR plan that can
fail over but not cleanly fail back leaves you stranded in the more expensive posture.

## Design decisions & trade-offs

- **Tier by BIA — don't apply one strategy to everything.** The central senior call: a few
  systems justify active/active; most are fine on warm standby or pilot light; some can tolerate
  backup-and-restore. Spending active/active money on a tier-3 workload is
  [[trade-off-judgment|misallocated budget]]; under-protecting a tier-0 system is an existential
  risk. The strategy ladder is a *per-workload* decision.
- **Lower RTO/RPO costs exponentially.** Each rung down the ladder multiplies infrastructure and
  operational cost and complexity. Push back on "we need zero RTO" until the BIA justifies it —
  the same "resilience theater" caution as [[distributed-systems-reliability]], applied to spend.
  Feed the number into [[cloud-cost-modeling]].
- **Backup-only is not DR for ransomware** unless the backups are immutable, isolated, *and*
  restore-tested. A mutable backup in the same account is destroyed in the same attack.
- **Multi-region: regulatory/region-loss need vs. complexity.** Multi-region buys regional-
  outage and data-residency protection at the cost of consistency headaches, doubled spend, and
  operational burden. Justify it by RTO/RPO and jurisdiction, not by default. See
  [[multi-cloud-architecture]] and [[hybrid-and-onprem-topologies]].
- **Managed DR vs. DIY.** AWS Elastic Disaster Recovery, Azure Site Recovery, and backup vendors
  (Rubrik, Veeam, Commvault) trade control and cost for less bespoke runbook code. DIY gives
  precision at the cost of ongoing engineering. Match to team capacity.
- **Recovery dependencies are part of the plan.** A failover that can't reach DNS, secrets
  ([[iam-and-secrets-management]]), KMS keys ([[encryption-and-key-management]]), the container
  registry, or the IAM control plane will stall. Map and replicate the *whole* recovery path,
  not just the application tier.

## State of the art

- **Continuous data protection + automated failover** is replacing periodic-backup-plus-manual-
  restore as the default for tier-0/1 workloads.
- **Immutability is mainstream**: 3-2-1-1-0, WORM object storage, and isolated recovery accounts
  are now baseline expectations rather than advanced practice — driven entirely by ransomware
  economics.
- **DR testing as compliance evidence**: DORA (EU financial sector, enforcement-active) and the
  ISO 22301/27001 family now expect demonstrable, recorded testing — pulling DR from optional to
  audited. See [[compliance-and-regulation]] and [[cloud-governance-at-scale]].
- **Sovereign / jurisdictional fault domains**: treating legal jurisdictions as failure
  boundaries (region-evacuation playbooks, cross-region blackholing) — the
  [[distributed-systems-reliability|sovereign fault domain]] framing applied to recovery.
- **IaC-defined recovery environments** and DR-runbook-as-code make the recovery region a
  rebuildable artifact, closing the drift gap between the primary and the DR site.

## Pitfalls & anti-patterns

- **The untested plan.** A DR runbook never exercised is a hypothesis. Drill on a schedule;
  measure actual RTO/RPO achieved (RTA/RPA) against the targets.
- **Mutable, co-located backups.** Backups in the same account/region/credentials as production
  are destroyed in the same ransomware event. Immutable + isolated, or it's not protection.
- **Never restoring.** Backups silently rot — corrupt, incomplete, or unrestorable. Only a test
  restore proves recoverability.
- **Treating multi-AZ as DR.** Availability zones protect against data-center failure, not
  regional or account-wide failure. Different problem, different control.
- **Ignoring failback.** Planning the trip out but not the trip home leaves you stuck in the
  costly posture and risks data divergence on return.
- **RTO/RPO theater.** Numbers in a document that are never validated. An untested objective is
  a wish. (Shared anti-pattern with [[distributed-systems-reliability]].)
- **Forgetting the dependency graph.** Recovering the app but not DNS, secrets, keys, identity,
  or the registry — the recovery stalls on the thing nobody mapped.
- **Replication mistaken for backup.** Replication copies corruption and deletion in real time;
  it is not a recovery point. You need point-in-time, immutable backups too.

## See also

- [[distributed-systems-reliability]]
- [[multi-cloud-architecture]]
- [[hybrid-and-onprem-topologies]]
- [[cloud-governance-at-scale]]
- [[infrastructure-as-code]]
- [[observability-fundamentals]]
- [[compliance-and-regulation]]
- [[encryption-and-key-management]]
- [[cloud-cost-modeling]]

## Sources

- [AWS — Disaster Recovery options in the cloud (Well-Architected whitepaper)](https://docs.aws.amazon.com/whitepapers/latest/disaster-recovery-workloads-on-aws/disaster-recovery-options-in-the-cloud.html)
- [AWS Architecture Blog — DR Architecture Part I: Strategies for Recovery in the Cloud](https://aws.amazon.com/blogs/architecture/disaster-recovery-dr-architecture-on-aws-part-i-strategies-for-recovery-in-the-cloud/)
- [CalmOps — Cloud Disaster Recovery 2026: Strategies, Patterns, Implementation](https://calmops.com/cloud/cloud-disaster-recovery-2026/)
- [Rubrik — AWS Disaster Recovery 2026 Strategy Guide (3-2-1-1-0, immutability)](https://www.rubrik.com/insights/aws-disaster-recovery-strategy-guide)
- [Harness — Disaster Recovery Testing: A Practical Guide (2026)](https://www.harness.io/blog/disaster-recovery-testing-a-practical-step-by-step-guide-for-2026)
- [ISO 22301 — Business continuity management systems](https://www.iso.org/standard/75106.html)
