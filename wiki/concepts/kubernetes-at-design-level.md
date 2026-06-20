---
title: Kubernetes at the Design Level
aliases: [Kubernetes, K8s, container orchestration]
type: concept
domain: cloud
status: mature
tags: [cloud, kubernetes, containers, orchestration, operators, multi-tenancy, eks, aks, gke]
updated: 2026-06-20
sources:
  - "https://devopscube.com/kubernetes-architecture-explained/"
  - "https://www.cloudoptimo.com/blog/inside-kubernetes-the-2026-architecture-breakdown/"
  - "https://www.cloudoptimo.com/blog/kubernetes-kubernetes-ai-infrastructure-in-2026-gpu-scheduling-and-production-realities/"
  - "https://d2iq.com/blog/best-practices-to-simplify-the-management-of-multi-tenant-eks-aks-or-gke-clusters"
  - "https://www.cloudoptimo.com/blog/eks-vs-gke-vs-aks-best-managed-kubernetes-service-in-2026/"
  - "https://www.informationweek.com/it-infrastructure/4-trends-that-will-transform-kubernetes-in-2026"
---

# Kubernetes at the Design Level

> [!summary]
> Kubernetes is a declarative system for running containerized workloads: you describe the desired state, and the control plane continuously reconciles reality to match it. At the design level, the architect decides cluster topology, multi-tenancy strategy, networking model, operator use for stateful applications, and whether managed Kubernetes (EKS/AKS/GKE) or self-managed fits the operational model. 82% of container users run Kubernetes in production (CNCF 2025). The design question is not whether to use it but how to structure and extend it correctly for the workload.

**Domain:** [[tier-1-edge|Cloud Architecture]]

## What it is

Kubernetes provides a set of abstractions for packaging, deploying, scaling, and networking containerized applications on a cluster of nodes. Its architecture separates a **control plane** (maintains desired state) from **worker nodes** (run workloads). The defining property is **declarative desired-state reconciliation**: instead of issuing imperative commands ("start this container on that machine"), you declare the end state ("I want 3 replicas of this pod running") and the control plane figures out how to get there and keeps it there.

## Why it matters

Kubernetes became the default compute substrate for cloud-native applications because it solves the hard problems of distributed systems at the platform level: scheduling, health checking, self-healing, rolling updates, service discovery, and configuration management. For architects, understanding its extension model (operators, CRDs) and its multi-tenancy boundaries is more important than knowing `kubectl` commands.

## Key concepts / building blocks

### Core abstractions

| Abstraction | What it is |
|---|---|
| **Pod** | The smallest deployable unit; one or more containers sharing network and storage. Ephemeral — never manage pods directly. |
| **Deployment** | Manages a ReplicaSet; declares desired replica count, update strategy (RollingUpdate / Recreate), and rollback. |
| **StatefulSet** | Like a Deployment but with stable network identifiers and ordered, persistent storage per Pod. For databases and stateful services. |
| **DaemonSet** | Ensures one Pod per node (or subset). For node-level agents: log collectors, monitoring, network plugins. |
| **Job / CronJob** | Runs Pods to completion (Job) or on a schedule (CronJob). For batch workloads. |
| **Service** | Stable virtual IP + DNS for a set of Pods. Types: ClusterIP (internal), NodePort, LoadBalancer, ExternalName. |
| **Ingress** | HTTP/HTTPS routing rules + TLS termination. Requires an Ingress controller (NGINX, Traefik, AWS ALB, Istio). |
| **ConfigMap / Secret** | Configuration and sensitive values injected into Pods as env vars or volume mounts. Secrets should be externally backed (Vault, AWS Secrets Manager) in production. |
| **PersistentVolume / PVC** | Abstracts storage; PVCs claim storage from provider-provisioned PVs (EBS, Azure Disk, GCE PD). |
| **Namespace** | Logical isolation boundary within a cluster. Foundation of soft multi-tenancy. |

### Control plane

The control plane manages cluster state and is typically managed by the cloud provider in production:

- **API server** — the single entry point for all state changes; validates and stores objects in etcd
- **etcd** — the strongly consistent distributed key-value store that holds all cluster state
- **Scheduler** — assigns unscheduled Pods to nodes based on resource requirements, affinity, taints, and tolerations
- **Controller manager** — runs the core reconciliation loops (deployment controller, replication controller, endpoint controller, etc.)

In managed Kubernetes (EKS/AKS/GKE), the provider owns and operates the control plane. In self-managed clusters, the control plane becomes an operational burden — one of the primary reasons to choose managed.

### Operator pattern

The **Operator** is Kubernetes's mechanism for encoding operational knowledge about a stateful application as code. An Operator is a Custom Resource Definition (CRD) + a dedicated controller that implements a **reconcile loop** specific to that application.

How it works:
1. Define a CRD (e.g., `KafkaCluster`) extending the Kubernetes API
2. Write a controller that watches `KafkaCluster` objects and reconciles the cluster state (creates/scales/upgrades Kafka brokers, manages TLS certs, handles rolling restarts)
3. Deploy the operator; users create `KafkaCluster` objects declaratively

Mature Operators exist for: PostgreSQL (CloudNative PG), Kafka (Strimzi), Redis, Elasticsearch, Prometheus, cert-manager, and hundreds more via OperatorHub.io. Before building a custom Operator, check whether one already exists.

**When to write a custom Operator:** when managing a stateful workload with complex lifecycle semantics that cannot be expressed with Deployments + init containers + Helm alone.

### Multi-tenancy

Kubernetes multi-tenancy ranges from **soft** (namespace isolation, shared control plane) to **hard** (separate clusters per tenant).

**Namespace-based isolation (soft):**
- Namespaces provide naming isolation and the boundary for RBAC, NetworkPolicy, and ResourceQuota
- Not a security boundary — a compromised Pod in namespace A can still reach the API server or nodes in ways that affect namespace B
- Appropriate for: internal teams with mutual trust, dev/staging/prod separation within one cluster

**Multi-tenancy controls within a shared cluster:**
- **RBAC** — namespace-scoped roles restrict which resources each team can create/read/modify
- **NetworkPolicy** — L3/L4 rules restricting Pod-to-Pod communication (requires a CNI that enforces them: Calico, Cilium, Weave)
- **ResourceQuota + LimitRange** — prevent tenant resource exhaustion
- **Pod Security Admission / OPA Gatekeeper / Kyverno** — enforce security baselines (no privileged containers, no hostPath mounts, etc.)

**Hard multi-tenancy (separate clusters):**
- Each tenant gets their own cluster with complete isolation (control plane, nodes, networking)
- Operationally expensive; recommended for: external customers, regulatory isolation, untrusted workloads
- **vCluster** — virtual clusters running inside a shared physical cluster; provide hard-tenant-like isolation at lower cost

**Provider-specific hard isolation:**
- **GKE Autopilot + GKE Sandbox (gVisor)** — pods run in kernel-level sandboxes; closest to hard multi-tenancy on a shared cluster
- **EKS + Fargate** — serverless node per pod; no node sharing; strong workload isolation

### Managed Kubernetes providers

| Provider | Strength | Notable |
|---|---|---|
| **GKE (Google)** | Most mature; best Autopilot; native Workload Identity; GKE Sandbox (gVisor) | Anthos for multi-cloud; GKE Enterprise for fleet management |
| **EKS (AWS)** | Deepest AWS integration; IAM Roles for Service Accounts (IRSA); Fargate integration | EKS Anywhere for hybrid; Karpenter for node autoscaling |
| **AKS (Azure)** | Entra ID (AAD) integration; strong Windows container support; AKS Automatic (Autopilot-like) | Azure Arc for multi-cloud; KEDA for event-driven autoscaling |

For new greenfield clusters: GKE Autopilot removes the most node management overhead while maintaining full K8s semantics. EKS with Karpenter is the strongest choice for AWS-native teams who need flexible node provisioning.

### Networking model

Kubernetes networking follows four invariants: every Pod gets a unique IP; every Pod can reach every other Pod without NAT; nodes can reach Pods without NAT; a Pod's self-reported IP is the same IP others use to reach it.

The CNI (Container Network Interface) plugin implements the network: Cilium (eBPF-based, best performance + security, replacing kube-proxy), Calico (CNCF standard, strong NetworkPolicy), Flannel (simple, limited policy).

**Cilium with eBPF** is the 2026 default for performance-sensitive deployments: implements networking at the kernel level without per-packet user-space overhead, removing kube-proxy from the data path entirely. Also provides Layer 7 network policy and transparent encryption.

### GPU scheduling for AI workloads (2026)

AI inference and training on Kubernetes require:
- **NVIDIA device plugin** — exposes GPU resources as schedulable Kubernetes resources (`nvidia.com/gpu: 1`)
- **Node selectors / taints + tolerations** — isolate GPU workloads to GPU nodes
- **MIG (Multi-Instance GPU)** — partition H100 GPUs into smaller slices for inference; expose as separate schedulable resources
- **Time-slicing** — share a single GPU across multiple Pods for lighter workloads
- **Volcano / Run:AI schedulers** — gang scheduling (allocate all resources simultaneously) for distributed training jobs that need all GPUs at once

## Design decisions & trade-offs

**Managed vs. self-managed Kubernetes:**

| Dimension | Managed (EKS/AKS/GKE) | Self-managed |
|---|---|---|
| Control plane ops | Provider responsibility | Your responsibility (etcd HA, upgrades) |
| Cost | Cluster fee ($0.10/hr EKS) + nodes | Nodes only, but control plane infra added |
| Customization | Limited; provider-specific constraints | Full; but you own all failure modes |
| Recommendation | Default for almost all production use cases | Only when strict compliance or specific hardware requires it |

**When NOT to use Kubernetes:**
- Single-container web app with predictable load → Cloud Run / App Service / Elastic Beanstalk
- Event-driven async processing → serverless functions (see [[serverless-architecture]])
- Batch ML training jobs without long-running services → managed ML platforms (SageMaker, Vertex AI)
- Small team, no existing K8s expertise → operational burden exceeds benefit until team size justifies it

The architect's honest question: "What does Kubernetes give me that a managed container service (Cloud Run, Fargate) doesn't?" If the answer is "not much for this workload," prefer the simpler option.

**Cluster topology — one large cluster vs. many small:**

| Approach | Advantage | Risk |
|---|---|---|
| One large shared cluster | Simpler ops; higher utilization | Blast radius; noisy-neighbor; harder isolation |
| Many small clusters | Strong isolation; blast radius contained | Fleet management overhead; cluster sprawl |
| Hub-and-spoke (fleet) | Central management (Anthos, Arc) + per-workload clusters | Complexity of fleet tooling |

## State of the art

CNCF's 2025 Annual Survey: 82% of container users run Kubernetes in production. The trend in 2026 is toward **less cluster management** via managed offerings and toward **more intelligent scheduling** via Karpenter and Volcano for AI workloads.

Four architectural shifts transforming Kubernetes in 2026:
1. **AI/GPU workloads as first-class citizens** — MIG, time-slicing, gang scheduling becoming standard
2. **eBPF replacing kube-proxy** — Cilium adoption accelerating; significant latency and observability improvements
3. **Autoscaling maturing** — Karpenter (AWS) and GKE Autopilot node auto-provisioning reduce manual node group management
4. **vCluster and virtual tenancy** — providing hard-tenant-like isolation at shared-cluster cost

## Pitfalls & anti-patterns

**Managing pods directly.** Never create bare Pods; always use Deployments, StatefulSets, or Jobs. Bare Pods are not rescheduled on node failure.

**Ignoring resource requests and limits.** Without requests, the scheduler cannot make sound placement decisions; without limits, a single runaway container exhausts the node. Set both for every container.

**Cluster-admin everywhere.** Granting `cluster-admin` to service accounts for convenience defeats RBAC. Follow least-privilege; use namespace-scoped roles.

**Stateful applications on Deployments.** Databases need StatefulSets (stable identity, ordered startup/shutdown) and PersistentVolumeClaims. Using a Deployment for a database produces data loss on rescheduling.

**No NetworkPolicy.** The default Kubernetes network model allows all-to-all Pod communication. Without NetworkPolicy (+ a CNI that enforces it), east-west traffic is unrestricted — a security gap.

**Treating namespaces as security boundaries.** A compromised Pod in a namespace can still reach the API server and other namespaces in ways that violate isolation expectations. For hard multi-tenancy, use separate clusters or vCluster.

## See also

- [[cloud-native-patterns]]
- [[serverless-architecture]]
- [[infrastructure-as-code]]
- [[cloud-governance-at-scale]]
- [[network-segmentation]]
- [[policy-as-code]]
- [[ai-gpu-economics]]

## Sources

- DevOpsCube. (2026). Kubernetes Architecture Explained. https://devopscube.com/kubernetes-architecture-explained/
- CloudOptimo. (2026). Inside Kubernetes: The 2026 Architecture Breakdown. https://www.cloudoptimo.com/blog/inside-kubernetes-the-2026-architecture-breakdown/
- CloudOptimo. (2026). Kubernetes AI Infrastructure in 2026: GPU Scheduling & Production Realities. https://www.cloudoptimo.com/blog/kubernetes-ai-infrastructure-in-2026-gpu-scheduling-and-production-realities/
- D2iQ. (n.d.). Best Practices to Simplify Multi-Tenant EKS, AKS, or GKE Clusters. https://d2iq.com/blog/best-practices-to-simplify-the-management-of-multi-tenant-eks-aks-or-gke-clusters
- CloudOptimo. (2026). EKS vs GKE vs AKS: Best Managed Kubernetes Service in 2026. https://www.cloudoptimo.com/blog/eks-vs-gke-vs-aks-best-managed-kubernetes-service-in-2026/
- InformationWeek. (2026). 4 Trends That Will Transform Kubernetes in 2026. https://www.informationweek.com/it-infrastructure/4-trends-that-will-transform-kubernetes-in-2026
