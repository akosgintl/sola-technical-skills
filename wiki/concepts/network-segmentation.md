---
title: Network Segmentation & Micro-segmentation
aliases: [network segmentation, micro-segmentation, east-west traffic control, network isolation, ZTNA]
type: concept
domain: security
status: mature
tags: [network, segmentation, micro-segmentation, zero-trust, firewall, vpc, nsg, ebpf, cilium]
updated: 2026-06-21
sources:
  - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf
  - https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204A.pdf
  - https://cilium.io/blog/2021/05/11/cni-benchmark/
  - https://kubernetes.io/docs/concepts/services-networking/network-policies/
  - https://www.cisa.gov/sites/default/files/2023-04/zero_trust_maturity_model_v2_508.pdf
  - https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html
---

# Network Segmentation & Micro-segmentation

> [!summary]
> Network segmentation divides infrastructure into isolated zones so that a breach cannot move freely between them. Micro-segmentation extends that control to east-west traffic between individual workloads — the missing half of perimeter-focused defences — enforcing per-identity policies that stop lateral movement even inside a trusted network zone.

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Traditional segmentation draws hard boundaries at the network edge: a perimeter firewall controls north-south traffic (internet ↔ internal), and VPCs or subnets divide internal environments (production vs. staging, web tier vs. data tier). Once inside the perimeter, east-west traffic between services was historically unrestricted — the assumption being that anything inside the network boundary could be trusted.

That assumption is wrong. The majority of high-impact breaches involve lateral movement: an attacker who compromises one workload traverses the internal network to reach higher-value targets. Micro-segmentation eliminates the implicit trust: every workload has an identity, and communication between workloads requires an explicit allow policy regardless of whether they share a subnet, a VPC, or a cloud region.

The two disciplines are complementary. Perimeter segmentation (VPC, subnet, security group) reduces the attack surface reachable from outside. Micro-segmentation (service mesh mTLS, eBPF policy, Kubernetes Network Policy) constrains what an attacker can do after a perimeter breach.

## Why it matters

Lateral movement is the mechanism behind the majority of large-scale breaches. The SolarWinds attack (2020) compromised the Orion build system; lateral movement then propagated malicious updates across 18,000 customers with unrestricted internal network access. The XZ Utils backdoor (2024) was discovered before deployment but demonstrated supply-chain compromise targeting unrestricted SSH exposure. In both cases, micro-segmentation would have bounded the blast radius.

Regulatory drivers reinforce the operational case: NIST SP 800-207 (Zero Trust Architecture) names network micro-segmentation as one of five core ZTA pillars. CISA's Zero Trust Maturity Model v2 treats east-west access control as a maturity requirement for all pillars. PCI DSS 4.0 requires network controls between card data environment components, with micro-segmentation accepted as a compensating control.

For AI workloads, the risk is acute: GPU nodes running inference or training have large memory footprints, broad data access, and often elevated privileges. An unrestricted GPU node is a high-value lateral movement target.

## Key concepts

### Segmentation layers

| Layer | Mechanism | Granularity | Stateful | Best for |
|---|---|---|---|---|
| VPC / Virtual Network | Cloud provider isolation | Entire workload group | N/A | Environment isolation (prod/staging) |
| Subnet | IP address range partition | Tier (web/app/data) | N/A | Tier isolation within an environment |
| Security Group / NSG | Stateful instance/NIC rules | Per instance or group | Yes | East-west within a VPC, between tiers |
| Network ACL | Stateless subnet-level rules | Per subnet | No | Coarse subnet boundary enforcement |
| Kubernetes Network Policy | Pod-level ingress/egress rules | Per pod/namespace | Yes (CNI) | Container east-west in a cluster |
| Service mesh (mTLS) | Identity-based L7 policy | Per service | Yes | Encrypted, authenticated east-west |
| eBPF (Cilium/Tetragon) | Kernel-level policy enforcement | Per process/connection | Yes | High-throughput east-west; no sidecar |

### VPC and subnet design

**VPC** is the coarsest isolation unit: separate VPCs for production, staging, development, and shared services. VPC peering, Transit Gateway (AWS), or Virtual Network Peering (Azure) connect VPCs with controlled routing. PrivateLink / Private Service Connect enables service exposure across VPC boundaries without routing tables or peering — the accessing VPC sees only the service endpoint, not the provider's network.

**Subnet segmentation** within a VPC: web tier in public subnets (load balancers only), application tier in private subnets (no direct internet access), data tier in isolated private subnets with no outbound internet. Enforce with route tables that have no internet gateway route in the data tier subnets.

**Security groups** are the primary east-west control within a VPC: stateful, allow-only, applied per network interface. The default-deny principle: start from "no traffic allowed" and open only the ports and sources required by documented service interactions. Reference security groups by group ID, not by CIDR, to avoid coupling to IP addresses.

### Kubernetes Network Policy

By default, all pods in a Kubernetes cluster can communicate with all other pods. This is the most common misconfiguration in Kubernetes deployments. Network Policy is the mechanism to restrict it.

A default-deny baseline applies to every namespace:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
```

After the baseline, individual policies allow specific traffic by pod label selector, namespace selector, or IP block. CNI plugins enforce Network Policy; the built-in Kubernetes network does not. Calico, Cilium, and Weave Net all support Network Policy; Cilium additionally enforces L7 policies (HTTP method, gRPC service) that standard Network Policy cannot express.

> [!warning]
> Network Policy requires a CNI plugin that enforces it. Deploying NetworkPolicy objects with a non-enforcing CNI (like the default kubenet) produces objects that are accepted by the API server but have no effect. Verify enforcement with a CNI audit tool before relying on Network Policy for security.

### Service mesh and mTLS

A service mesh (Istio, Linkerd, Cilium) enforces mTLS for east-west traffic and applies L7 traffic policies (retry, circuit break, header-based routing). Security properties:

- **mTLS by default**: every service-to-service connection is authenticated and encrypted; plaintext east-west is rejected.
- **L7 policy**: access can be restricted to specific HTTP paths, gRPC services, or JWT-authenticated identities — not just IP/port.
- **Observability**: every east-west connection is traced; anomalous communication patterns are visible.

Istio's **Ambient mode** (GA 2024) eliminates per-pod sidecar proxies: a per-node `ztunnel` handles L4 mTLS; a per-namespace Waypoint proxy handles L7 policies only for services that need it. This reduces the memory and CPU overhead of mesh adoption by ~50 % and removes the sidecar injection operational burden.

**Cilium** with eBPF provides the strongest east-west performance: kernel-level policy enforcement at wire speed, with no user-space proxy overhead. Cilium's Network Policy enforcement is faster than iptables-based alternatives at high connection rates and supports L7 policy for HTTP and Kafka without a separate proxy.

### eBPF-based enforcement

eBPF (extended Berkeley Packet Filter) allows programs to run in the Linux kernel's network path without modifying kernel source. Cilium uses eBPF to:
- Replace iptables/kube-proxy (better throughput, lower latency at scale)
- Enforce per-process network policy (a process, not just a pod, is the identity unit)
- Capture network events for forensics without packet capture overhead

Tetragon (Cilium's security observability component) enables real-time detection of network policy violations, process-level syscall visibility, and kill-signal capability for in-progress malicious network activity.

### Zero Trust Network Access (ZTNA)

ZTNA replaces VPN for remote access. Where VPN grants broad network access upon authentication, ZTNA grants per-session access to a specific resource, authenticated per-request and conditioned on device posture. Products: Cloudflare Access, Zscaler Private Access, Palo Alto Prisma Access, BeyondCorp Enterprise.

CISA's Zero Trust Maturity Model v2 places ZTNA as the network pillar's "Advanced" maturity level, above traditional VPN segmentation.

### Segmentation for AI workloads

GPU nodes have unique segmentation requirements:

- **Isolated node pools**: GPU inference and training nodes in dedicated subnets or namespaces, separate from general compute.
- **Restricted egress**: model servers should not initiate outbound internet connections; egress to allowed endpoints only (model registries, telemetry sinks). Prevents exfiltration of model weights or inferred outputs.
- **Model API endpoint isolation**: inference endpoints exposed via private load balancer, not public internet, with API gateway in front for authentication and rate limiting.
- **Training network isolation**: training jobs accessing sensitive training data should be in isolated subnets with no access to the inference environment or production data stores.

## Design decisions and trade-offs

**Security groups vs. Network Policy vs. service mesh.** These are not alternatives — they operate at different layers and should all be applied. Security groups handle VPC-level ingress/egress; Network Policy handles pod-level east-west within a cluster; service mesh adds mTLS authentication on top of Network Policy rules. Choosing one as a substitute for another leaves gaps.

**Sidecar mesh vs. eBPF.** Sidecar meshes (Istio traditional, Linkerd) are mature, feature-rich, and language-agnostic. They add per-pod memory overhead (~50–100 MB per sidecar) and require injection into every workload. eBPF (Cilium) has lower overhead, no injection, and is faster — but the CNI and mesh are coupled to the same vendor. Istio Ambient mode closes the overhead gap while retaining Istio's broad adoption and ecosystem.

**Micro-segmentation scope.** Full workload-level micro-segmentation (every service has an explicit policy) provides the strongest security but the highest operational overhead. A practical phased approach: (1) default-deny at namespace level, (2) allow-list documented service-to-service traffic, (3) add L7 policy for high-sensitivity paths. Prioritise micro-segmentation for services that handle PII, financial data, or model weights.

**Complexity vs. auditability.** More granular segmentation produces more security policies. At scale, the policy set becomes the principal maintenance burden. Policy-as-code (OPA, Kyverno, Cilium Network Policy in version-controlled YAML) makes the policy set auditable and diff-reviewable. See [[policy-as-code]].

## State of the art

**Cilium 1.16 (2025)** added mutual authentication via SPIFFE/SPIRE identity framework, enabling mTLS enforcement without a separate service mesh for clusters that need identity-based east-west but not L7 traffic management.

**Istio Ambient mode (GA 2024)** is now the recommended default for new Istio deployments. Existing sidecar-mode deployments have a migration path; both modes can coexist in a cluster during transition.

**AWS Network Firewall and Azure Firewall Premium** provide deep packet inspection and FQDN-based egress filtering for north-south and VPC-to-VPC traffic, closing the gap between security group capability and traditional next-generation firewall capability.

**Kubernetes Gateway API** (GA v1.0, 2023) unified the Ingress/egress specification across CNI and service mesh vendors. Cilium and Istio both implement it, reducing lock-in to a specific mesh for L7 ingress policy.

> [!tip]
> Start with two policies: a default-deny NetworkPolicy for every namespace, and a deny-all-to-internet security group for data-tier instances. These two controls eliminate the most common lateral-movement and exfiltration vectors before adding the operational complexity of a service mesh.

## Pitfalls and anti-patterns

- **Perimeter-only segmentation.** A VPC perimeter with no east-west controls means a single compromised workload can reach every other workload in the VPC. The breach is the beginning, not the end, of the incident.
- **Overly permissive security groups.** `0.0.0.0/0` inbound or `allow all` within a VPC effectively removes the security group layer. Audit with AWS Config / Azure Policy rules that detect these configurations.
- **No default-deny in Kubernetes.** All pods can reach all pods by default. Without a default-deny NetworkPolicy, the cluster is a flat network.
- **NetworkPolicy with a non-enforcing CNI.** Objects accepted; no enforcement. A common misconfiguration in clusters that switched CNIs without auditing existing policies.
- **Segmentation rules on paper only.** Network access controls that are never tested are not network access controls — they are a list. Validate with tools like netassert, kube-hunter, or regular pen testing.
- **Flat network for AI workloads.** GPU nodes with unrestricted egress can exfiltrate model weights, inferred PII, or training data to any internet endpoint. Restrict GPU node egress at the subnet level.
- **Ignoring L7 in micro-segmentation.** IP:port policy allows a compromised service to call any endpoint on an allowed port. L7 policy (HTTP path, gRPC method) closes the gap for application-layer attacks.

## See also

- [[zero-trust-architecture]] — the broader ZTA model of which micro-segmentation is the network pillar
- [[cloud-network-architecture]] — the VPC/hub-spoke topology that segmentation is enforced within
- [[encryption-and-key-management]] — mTLS certificates and the PKI backing service-to-service authentication
- [[iam-and-secrets-management]] — identity layer above the network layer
- [[kubernetes-at-design-level]] — Kubernetes CNI, network policy, and multi-tenancy
- [[api-gateways-and-service-mesh]] — service mesh L7 traffic management and observability
- [[ai-specific-security]] — GPU node security and inference endpoint threat model
- [[policy-as-code]] — network policy as version-controlled, auditable code

## Sources

- NIST (2020). *SP 800-207 — Zero Trust Architecture.* https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf
- NIST (2022). *SP 800-204A — Building Secure Microservices-based Applications Using Service-Mesh Architecture.* https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-204A.pdf
- Cilium Project (2021). *CNI Benchmark: Understanding Cilium Network Performance.* https://cilium.io/blog/2021/05/11/cni-benchmark/
- Kubernetes (2024). *Network Policies.* https://kubernetes.io/docs/concepts/services-networking/network-policies/
- CISA (2023). *Zero Trust Maturity Model v2.0.* https://www.cisa.gov/sites/default/files/2023-04/zero_trust_maturity_model_v2_508.pdf
- AWS (2024). *VPC Network ACLs.* https://docs.aws.amazon.com/vpc/latest/userguide/vpc-network-acls.html
