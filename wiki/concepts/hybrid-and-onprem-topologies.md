---
title: Hybrid and On-Prem Topologies
aliases: [hybrid cloud, on-premises architecture, hybrid topology]
type: concept
domain: cloud
status: mature
tags: [cloud, hybrid, edge, sovereignty, data-gravity, connectivity]
updated: 2026-06-22
sources:
  - https://docs.aws.amazon.com/directconnect/latest/UserGuide/Welcome.html
  - https://docs.microsoft.com/en-us/azure/azure-arc/overview
  - https://cloud.google.com/distributed-cloud/hosted/docs/latest/gdch/overview
  - https://docs.aws.amazon.com/outposts/latest/userguide/what-is-outposts.html
  - https://docs.aws.amazon.com/eks/latest/userguide/eks-anywhere.html
  - https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
---

# Hybrid and On-Prem Topologies

> [!summary]
> Hybrid and on-prem topologies blend public cloud elasticity with infrastructure that stays on owned or leased hardware, driven by data gravity, latency requirements, regulatory sovereignty, and existing investment. The design challenge is keeping identity, networking, operations, and security coherent across a boundary that the public cloud provider does not fully control.

**Domain:** [[tier-1-edge|Cloud Architecture]]

## What it is

A purely cloud-native architecture assumes all infrastructure is API-addressable, elastically scalable, and operated by the cloud provider. Many organisations cannot or should not start there: they hold petabytes of historical data on-premises that would cost more to move than to leave; operate factories or retail locations that need sub-millisecond response times regardless of WAN health; must satisfy data residency regulations that restrict where data may be processed; or carry decade-old hardware commitments that remain economically rational for steady-state workloads.

Hybrid topology is not a compromise position on the way to full cloud migration — for a large class of organisations it is the permanent target state. The design challenge is avoiding the worst outcome: two separate operating models that share nothing, creating a *hybrid mess* rather than a hybrid cloud.

## Why it matters

**Data gravity.** The cost and latency of moving large datasets to the cloud frequently makes cloud-side processing impractical. A petabyte data warehouse on-premises costs roughly $0.05/GB to egress to cloud object storage once; reprocessing it in Spark on-premises and syncing only results costs orders of magnitude less. Data gravity is a physics constraint, not a legacy problem.

**Edge latency requirements.** Manufacturing process control, autonomous vehicle decision loops, and real-time video analytics all have response-time requirements that a round-trip to a cloud region cannot satisfy. Even if the nearest cloud region is 10 ms away, 10 ms is too slow for a servo controller. Processing must happen at or near the physical system.

**Regulatory sovereignty.** Financial regulators in the EU, India, China, and others impose strict requirements on where data about their citizens may be processed and stored. Some sectors (classified government, defence) require air-gapped environments with no connectivity to public cloud. Sovereignty requirements are tightening, not relaxing.

**Existing investment.** Hardware purchased 3 years ago and fully depreciated in 2 years represents a real economic argument for continued on-premises operation. Cloud migration ROI depends heavily on when the existing hardware costs zero.

## Key concepts

### Topology patterns

**Cloud-connected on-premises.** On-premises infrastructure connects to public cloud via dedicated private connectivity (AWS Direct Connect, Azure ExpressRoute, GCP Cloud Interconnect). The on-premises environment remains self-managed but gains access to cloud services (object storage, AI APIs, managed databases) over the private link. This is the most common pattern: on-premises stays on-premises; cloud services are consumed as utilities. Identity is federated; operations remain heterogeneous.

**Cloud-managed on-premises.** The cloud provider extends their managed control plane onto customer-owned hardware:
- **AWS Outposts:** rack-mounted hardware running AWS APIs (EC2, EKS, RDS, S3 on Outposts) in the customer's datacenter. Management plane is AWS cloud; compute and data stays on-prem. Native AWS APIs on-prem: same Terraform providers, same IAM, same monitoring.
- **Azure Stack HCI / Azure Arc:** Arc extends Azure management (Azure Policy, Azure Monitor, Azure Defender) to any infrastructure — on-prem servers, other clouds, edge devices. Arc-enabled Kubernetes manages K8s clusters anywhere from the Azure plane.
- **Google Distributed Cloud (GDC):** rack-level hardware for fully disconnected (air-gapped) operation or customer-hosted rack connected to GCP. Same Google Kubernetes Engine and Vertex AI APIs.

Cloud-managed on-prem provides the highest operational coherence (single control plane) at the highest cost (hardware + cloud management fee). The trade-off: premium pricing for the convenience of not managing two different operating models.

**Edge computing topologies.** Ultra-low-latency processing at network edges — telecom PoPs, retail locations, factory floors, camera systems:
- **Telco edge:** AWS Wavelength (compute at carrier 5G PoPs, single-digit millisecond latency), Azure Edge Zones, GCP Mobile Edge Cloud.
- **Industrial edge:** purpose-built hardware (AWS Panorama for computer vision, Azure IoT Edge for ML inference on constrained devices, Siemens/Rockwell industrial PCs running containerised workloads).
- **Micro-datacenters:** standard servers at remote locations (retail stores, branch offices) running Kubernetes with a lightweight distribution (K3s, MicroK8s).
- [[wasm-at-the-edge]] covers the runtime patterns for ultra-constrained edge nodes.

**Disconnected / air-gapped.** No connectivity to public cloud during operation. Used in classified government, defence, remote industrial, and regulated financial environments:
- Periodic sync when connectivity is restored (sync-on-reconnect patterns with CRDTs or event-sourcing-based reconciliation)
- AWS Snow Family (Snowball Edge, Snowcone) for offline compute and storage at remote locations
- Azure Stack HCI / Google Distributed Cloud in fully air-gapped mode
- GitOps with pull-based deployment: clusters pull from an internal registry rather than cloud-hosted registries

### Connectivity options

| Method | Bandwidth | Latency | Cost | Use case |
|---|---|---|---|---|
| Dedicated connection (Direct Connect / ExpressRoute / Cloud Interconnect) | 1–100 Gbps | Predictable, sub-10 ms | Higher fixed cost | Production workloads, large data transfer, steady-state hybrid |
| Site-to-site VPN | Up to 1.25 Gbps | Variable (internet-dependent) | Low | Dev/test, lower-criticality workloads, backup connectivity |
| SD-WAN overlay | Varies | Optimised multi-path | Medium | Branch offices, multi-site retail, managed quality |
| Private Link / VPC endpoints | Cloud-speed | Cloud-region latency | Per-endpoint charge | Service-specific connectivity without full network connectivity |

For hybrid AI workloads, a dedicated connection is the right default: training data egress from on-premises is high-bandwidth, and inference traffic from cloud to on-prem model endpoints needs predictable latency.

### Identity across the boundary

The most common failure in hybrid deployments is two identity domains that never merge: Active Directory on-prem; Entra ID (Azure AD) or Okta in cloud. Users have two identities, admins manage two IAM systems, and zero-trust cannot be enforced coherently.

The mature pattern: **single identity, dual presence**.
- **Microsoft environments:** Entra Connect (formerly AD Connect) syncs on-prem AD to Entra ID. Applications on both sides use Entra ID tokens; cloud SSO extends to on-prem apps via Application Proxy.
- **Non-Microsoft:** OIDC/SAML federation from an on-prem IdP (Okta, Ping, SailPoint) to cloud IAM. Cloud workloads trust the on-prem IdP's tokens.
- **Workload identity across the boundary:** [[agent-identity-and-access]] covers workload identity federation — cloud workloads can assume on-premises service accounts via OIDC exchange without long-lived keys.
- **Zero-trust across hybrid:** [[zero-trust-architecture]] principles apply regardless of location. Device and identity posture, not network perimeter, determines access. Enforce the same policy engine for on-prem and cloud access.

### Kubernetes across hybrid

Kubernetes is the most practical unifying runtime abstraction for hybrid topologies. The same workloads (containerised applications) run on-premises and in cloud with the same deployment model:

| Product | Approach | On-prem runtime |
|---|---|---|
| EKS Anywhere | AWS-managed EKS control plane for on-prem clusters | VMware, bare metal |
| Azure Arc-enabled Kubernetes | Azure management of any K8s cluster | Any K8s distribution |
| GKE Anthos / GDC | Google-managed GKE for on-prem | VMware, bare metal |
| Cluster API (CAPI) | Declarative cluster lifecycle management | Any infrastructure provider |

GitOps (Flux, ArgoCD) targeting both cloud and on-prem clusters from the same repository is the standard operational model. A single git repository with environment-specific overlays (Kustomize) or values files (Helm) drives deployments to both environments without per-environment tooling.

### Data topology in hybrid

**Keep compute close to data.** Data gravity means large datasets should stay where they are; compute should move to data rather than the reverse. Spark or Flink processing on on-premises clusters, results and aggregates synced to cloud analytics.

**Tiered storage across the boundary.** Hot (latency-sensitive) data on-prem with fast local storage; warm and cold data in cloud object storage (S3, GCS, ADLS). Delta Lake or Apache Iceberg as the open table format spanning both sides.

**Hybrid AI.** GPU on-premises for sensitive-data model inference (the model never leaves controlled infrastructure); cloud GPU for burst training when datasets are too large for on-prem capacity. Fine-tuning can be done on-prem; base model serving can be in cloud (or vice versa depending on sensitivity). See [[encryption-and-key-management]] for model weight and checkpoint encryption requirements.

**Active-passive and active-active DR.** On-prem as primary with cloud as DR target (common for cost reasons); active-active is more expensive but eliminates failover downtime and keeps cloud infrastructure warm. RPO/RTO requirements drive the choice.

## Design decisions and trade-offs

**Cloud-managed vs. cloud-connected.** Cloud-managed on-prem (Outposts, Arc, GDC) gives a single operating model at a premium. Cloud-connected on-prem (Direct Connect + self-managed hardware) is cheaper and more flexible but requires the team to maintain two toolchains. The decision depends on the team's operational maturity and the cost of heterogeneity: if the team already runs complex multi-cloud tooling, the additional cost of Outposts is hard to justify; if operational coherence is worth paying for, Outposts/Arc is the right choice.

**Lift-and-shift vs. hybrid-native.** Treating on-prem as "another region" in a cloud-native architecture (same APIs, same IaC, same deployment patterns) is hybrid-native design. Treating on-prem as a legacy environment that connects to cloud is the more common path, but it produces operational debt. Hybrid-native requires upfront investment in tooling coherence.

**Connectivity redundancy.** A single Direct Connect circuit is a single point of failure. For production workloads, the standard pattern is primary Direct Connect + backup VPN. This is almost always worth the VPN cost; a WAN outage that takes down production is expensive.

**Edge autonomy vs. central management.** Edge nodes that require central connectivity to function are fragile — if the WAN link fails, the edge stops. Design edge workloads for local autonomy: the core function (inference, control, data capture) must work disconnected; sync with central happens opportunistically.

## State of the art

**Azure Arc** is the most widely adopted hybrid management layer as of mid-2026, driven by Microsoft's enterprise customer base and the breadth of Arc's coverage (Kubernetes, servers, data services, application services, ML). Arc-enabled Kubernetes manages 4+ million clusters across on-prem and other clouds.

**AWS Outposts** dominates in environments that are standardised on AWS and want cloud-native API parity on-premises. AWS re:Invent 2025 announced Outposts rack support for AI-optimised instances (Inferentia3 and Trainium2), enabling on-prem AI inference with the same SageMaker APIs used in cloud.

**Google Distributed Cloud** (GDC) is Google's answer for regulated and sovereign deployments, with sovereign instances operated by local partners (T-Systems in Europe, NEC in Japan). GDC Hosted (customer-owned rack, Google-managed) and GDC Air-Gapped (fully disconnected) address the most restrictive regulatory environments.

**Sovereign cloud.** EU regulators have accelerated sovereign cloud requirements post-Schrems II. The Microsoft EU Data Boundary and Google Cloud Sovereign Controls define where customer data is processed and stored. These are relevant for any organisation subject to GDPR's cross-border transfer restrictions.

> [!tip]
> The most common hybrid failure is building cloud connectivity without building cloud-coherent operations. Connecting your on-prem data centre to AWS does not give you hybrid cloud — it gives you two separate environments with a private network between them. Hybrid cloud requires unified identity, unified GitOps deployment, unified observability, and unified policy enforcement. Build those capabilities before claiming the architecture is hybrid.

## Pitfalls and anti-patterns

- **Treating hybrid as temporary.** "We're moving to cloud, so we'll just connect this temporarily" produces years of connection that never goes away, with no investment in making it coherent.
- **Two identity domains.** Two separate identity systems that are never federated mean two sets of credentials to manage, audit, and rotate. The security risk of the uncorrelated shadow identity is the most common hybrid vulnerability.
- **Data in transit without encryption.** On-prem to cloud connectivity carries production data. Direct Connect and VPN provide network-level isolation but not encryption by default. Encrypt data in transit with TLS at the application layer regardless of network-level controls.
- **Edge nodes that cannot operate disconnected.** An edge node whose core function requires cloud connectivity is an availability risk for every WAN hiccup. Design for autonomy first; treat cloud connectivity as an enhancement.
- **Neglecting cross-boundary observability.** A trace that starts on-prem and continues in cloud, or vice versa, requires distributed tracing that spans both environments. Without it, the hybrid boundary becomes a diagnostic black hole. See [[ai-agent-observability]].
- **Assuming egress is free between on-prem and cloud.** Direct Connect reduces per-GB egress rates but does not eliminate them. Large data movements still incur significant costs. Model the cost of data movement before designing hybrid data flows. See [[cloud-cost-modeling]].

## See also

- [[multi-cloud-architecture]] — multi-provider strategy, which often coexists with hybrid topologies
- [[cloud-governance-at-scale]] — landing zones and guardrails that extend to hybrid accounts
- [[zero-trust-architecture]] — consistent identity and access policy across the hybrid boundary
- [[network-segmentation]] — segmentation patterns applicable to hybrid network topologies
- [[confidential-computing]] — hardware-level encryption for sensitive workloads at the edge or on-prem
- [[wasm-at-the-edge]] — lightweight runtime for ultra-constrained edge nodes
- [[encryption-and-key-management]] — key management across on-prem and cloud boundaries

## Sources

- AWS (2024). *AWS Direct Connect User Guide.* https://docs.aws.amazon.com/directconnect/latest/UserGuide/Welcome.html
- Microsoft (2025). *Azure Arc Overview.* https://docs.microsoft.com/en-us/azure/azure-arc/overview
- Google (2025). *Google Distributed Cloud Hosted Overview.* https://cloud.google.com/distributed-cloud/hosted/docs/latest/gdch/overview
- AWS (2024). *AWS Outposts — What Is AWS Outposts.* https://docs.aws.amazon.com/outposts/latest/userguide/what-is-outposts.html
- AWS (2024). *Amazon EKS Anywhere.* https://docs.aws.amazon.com/eks/latest/userguide/eks-anywhere.html
- Microsoft (2025). *Azure Landing Zone — Cloud Adoption Framework.* https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/landing-zone/
