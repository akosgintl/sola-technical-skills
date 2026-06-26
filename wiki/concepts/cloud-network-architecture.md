---
title: Cloud Network Architecture
aliases: [cloud networking, VPC design, VPC, VNet, hub-and-spoke, transit gateway, PrivateLink, landing zone network, CIDR planning, egress]
type: concept
domain: cloud
status: mature
tags: [cloud, networking, vpc, hub-and-spoke, transit-gateway, privatelink, dns]
updated: 2026-06-26
sources:
  - "https://cloud.google.com/architecture/best-practices-vpc-design"
  - "https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/welcome.html"
  - "https://cloud.google.com/architecture/deploy-hub-spoke-vpc-network-topology"
  - "https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke"
  - "https://docs.cloud.google.com/architecture/landing-zones/decide-network-design"
---

# Cloud Network Architecture

> [!summary]
> Cloud network architecture is the design of how cloud networks are laid out and connected:
> IP/CIDR planning, VPC/VNet topology (typically **hub-and-spoke** via a transit gateway),
> private service connectivity (**PrivateLink**/private endpoints), controlled **egress**, DNS
> architecture, and global load balancing. It is the substrate every workload runs on — and the
> decisions are made early and are slow and expensive to unwind (overlapping CIDRs and flat
> topologies haunt a platform for years). It is distinct from its neighbors:
> [[network-segmentation]] is the *security/isolation* lens (stopping lateral movement) and
> [[hybrid-and-onprem-topologies]] is *on-prem↔cloud connectivity* — this page is the cloud network
> *topology and connectivity design* itself.

**Domain:** [[tier-1-edge|Cloud Architecture]]

## What it is

The building blocks are consistent across providers (names differ): a **VPC/VNet** (an isolated
virtual network), **subnets** (public/private, spread across availability zones), **route tables**,
**gateways** (internet, NAT, transit), **peering** and **private endpoints**, **DNS**, and **load
balancers**. The architect's job is to assemble these into a topology that scales across accounts,
regions, and teams without painting the organization into a corner — usually as part of the
**landing-zone** network foundation (see [[cloud-governance-at-scale]]).

## Why it matters

Networking is a **foundational, hard-to-reverse** layer. Get the IP plan or topology wrong and the
costs surface later as blocked peering (overlapping CIDRs), uncontrolled egress bills, blast-radius
sprawl, and painful migrations once hundreds of workloads already depend on the addressing. The
topology determines what can talk to what, how isolation and inspection are enforced, how egress is
controlled and costed, and how multi-account/multi-region growth scales. Because it is set early and
constrains everything above it, it is squarely an architect's call — a classic
[[trade-off-judgment|one-way-door]] decision.

## Key concepts / building blocks

### IP / CIDR planning

The most consequential early decision: allocate **non-overlapping** RFC 1918 address space across
every account, region, and the on-prem estate. Overlapping CIDRs permanently block VPC peering and
transit routing and force ugly NAT/PrivateLink workarounds. Plan generously and centrally before the
first workload lands.

### VPC/VNet and subnet design

Public vs. private subnets, spread across availability zones for resilience, often tiered
(web/app/data). Private subnets reach the internet (if at all) only through a controlled egress path.

### Hub-and-spoke and the transit gateway

Full-mesh VPC peering is non-transitive and scales O(N²); it collapses past a handful of networks.
The standard enterprise pattern is **hub-and-spoke**: a central hub hosts shared connectivity and
inspection, and **spoke** VPCs attach to it through a **transit gateway** (AWS Transit Gateway,
Azure Virtual WAN / hub VNet, GCP Network Connectivity Center), giving transitive routing at O(N)
attachments. The hub typically holds the egress firewall, VPN/ExpressRoute/Direct Connect gateways,
and shared services.

### Private connectivity: peering vs. PrivateLink

- **VPC peering** — network-level: the whole peer VPC is routable; requires non-overlapping CIDRs and
  is non-transitive.
- **PrivateLink / Private Service Connect / Private Endpoints** — service-level: expose *one* service
  privately, unidirectionally, **without** CIDR coordination — ideal across orgs or overlapping
  address spaces. Endpoints are often **centralized** in the hub and shared by spokes via the transit
  gateway to avoid duplicating (and paying for) an endpoint per VPC.

### Egress control

Outbound traffic via **NAT gateways** or, increasingly, a **centralized egress firewall** in the hub
that inspects and allow-lists destinations. Egress is both a **cost** lever (NAT and cross-AZ/region
data transfer are common surprise bills) and a **security** control (a path for
[[data-privacy-engineering|data exfiltration]] — see also [[ai-specific-security]]).

### DNS architecture

Private hosted zones, split-horizon resolution, and resolver/forwarding rules to and from on-prem.
Private DNS that maps public service names to private endpoint IPs (e.g. Route 53 private hosted
zones for VPC endpoints) is what makes PrivateLink transparent to applications. DNS is a frequent,
under-planned source of hybrid connectivity failures.

### Load balancing and global traffic

L4/L7 load balancers in front of services; **global** load balancing / anycast (Cloud Load
Balancing, Azure Front Door, Cloudflare) for latency- or geo-based routing and multi-region
failover — tying into [[multi-cloud-architecture]] and [[disaster-recovery-and-continuity]].

## Design decisions & trade-offs

- **Hub-and-spoke vs. full-mesh peering.** Hub centralizes egress inspection, shared services, and
  scales to many networks (O(N)) — at the cost of a transit dependency, a potential chokepoint, and
  transit-gateway data-processing charges. Full-mesh is simplest at small scale but O(N²) and
  uncontrolled. Default to hub-and-spoke past a few VPCs.
- **Peering vs. PrivateLink.** Peering when you need broad network reachability and control both
  sides' addressing; PrivateLink when exposing a *service* (especially across orgs or with
  overlapping CIDRs) — narrower surface, no CIDR coordination.
- **Centralized vs. distributed egress.** A central hub firewall gives inspection and allow-listing
  (and consolidated cost) but is a chokepoint and a single point to keep available; per-VPC NAT is
  simpler but offers no central control and duplicates cost.
- **Plan CIDRs up front vs. retrofit.** Generous, non-overlapping allocation early is cheap;
  retrofitting around overlap later is expensive and constrains the design permanently.
- **Few large VPCs vs. many small VPCs/accounts.** Account/VPC-per-team maximizes isolation and
  blast-radius control (and aligns with [[cloud-governance-at-scale|landing zones]]) but multiplies
  connectivity complexity — which is exactly what hub-and-spoke exists to manage.
- **Provider topology equivalencies.** AWS Transit Gateway ≈ Azure Virtual WAN / hub-spoke ≈ GCP
  Shared VPC + Network Connectivity Center; the patterns map but the limits and pricing differ — part
  of [[multi-cloud-architecture|multi-cloud fluency]].

## State of the art

- **Hub-and-spoke with a transit gateway / Virtual WAN is the default enterprise landing-zone
  network**, with centralized egress inspection and centralized PrivateLink endpoints.
- **PrivateLink/Private Service Connect** are the standard for private, CIDR-independent service
  access — including private access to managed and AI/model service endpoints.
- **Cloud backbone / WAN services** (Cloud WAN, Virtual WAN) increasingly replace self-managed transit
  VPC/VPN meshes for global connectivity.
- **Networking is defined as code** ([[infrastructure-as-code]]) and reviewed like any other
  infrastructure; **global anycast load balancing and edge** front multi-region designs.
- **AI workloads** drive multi-tenant hub-and-spoke patterns (a shared GenAI hub, tenant spokes) and
  private endpoints to inference services.

## Pitfalls & anti-patterns

- **Overlapping CIDRs.** The cardinal sin — permanently blocks peering/transit and forces NAT/
  PrivateLink workarounds. Plan address space centrally before anything is built.
- **Flat single VPC.** No room for tiering, isolation, or a segmentation-ready topology; everything
  shares a blast radius.
- **Full-mesh peering at scale.** O(N²) and non-transitive — unmanageable past a few VPCs. Use a hub.
- **Uncontrolled egress.** No central inspection or allow-listing → surprise data-transfer bills and
  an open exfiltration path.
- **Public-by-default subnets.** Unintended internet exposure of workloads that should be private.
- **DNS as an afterthought.** Split-horizon and resolver gaps that break service discovery, especially
  across the hybrid boundary.
- **Per-VPC duplicated endpoints/NAT.** Paying for an interface endpoint and NAT in every spoke
  instead of centralizing them in the hub.
- **Treating networking as retrofittable.** It is foundational and set early; bolt-on redesigns after
  workloads land are costly and risky.

## See also

- [[network-segmentation]]
- [[hybrid-and-onprem-topologies]]
- [[multi-cloud-architecture]]
- [[cloud-governance-at-scale]]
- [[zero-trust-architecture]]
- [[infrastructure-as-code]]
- [[disaster-recovery-and-continuity]]

## Sources

- [Google Cloud — Best practices and reference architectures for VPC design](https://cloud.google.com/architecture/best-practices-vpc-design)
- [AWS — Building a Scalable and Secure Multi-VPC Network Infrastructure (whitepaper)](https://docs.aws.amazon.com/whitepapers/latest/building-scalable-secure-multi-vpc-network-infrastructure/welcome.html)
- [Google Cloud — Hub-and-spoke VPC network topology](https://cloud.google.com/architecture/deploy-hub-spoke-vpc-network-topology)
- [Microsoft Learn — Hub-spoke network topology in Azure](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke)
- [Google Cloud — Decide the network design for your landing zone](https://docs.cloud.google.com/architecture/landing-zones/decide-network-design)
