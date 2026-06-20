---
title: Network Segmentation & Micro-segmentation
aliases: [network segmentation, micro-segmentation, east-west traffic control, network isolation]
type: concept
domain: security
status: stub
tags: [network, segmentation, micro-segmentation, zero-trust, firewall, vpc, nsg]
updated: 2026-06-20
sources: []
---

# Network Segmentation & Micro-segmentation

> [!summary]
> Network segmentation divides infrastructure into isolated zones so that a breach in one zone cannot freely reach others. Traditional segmentation drew perimeters at the network edge (north-south traffic); micro-segmentation extends controls to east-west traffic between workloads within the same zone — enforcing per-workload or per-service policies. In zero-trust architectures, micro-segmentation is the network enforcement layer: no workload is implicitly trusted by virtue of being "inside."

**Domain:** [[tier-1-edge|Security & Compliance]]

## What it is

Traditional segmentation uses VPCs, subnets, security groups, and network ACLs to isolate tiers (web, app, data) and environments (prod, staging). Micro-segmentation goes further: it enforces identity-based policies between individual workloads, containers, or VMs — typically via a service mesh, host-based firewalls, or software-defined networking (SDN). Each workload has an identity; communication is only permitted by explicit policy.

## Why it matters

- ...

## Key concepts / building blocks

- **VPC / Virtual Network** — cloud-native isolation boundary; the coarsest segmentation unit
- **Security groups / NSGs** — stateful rules at the instance/NIC level; east-west within a VPC
- **Network ACLs** — stateless subnet-level rules; typically coarser than security groups
- **Service mesh (mTLS + policy)** — per-service identity and encrypted east-west enforcement (Istio, Linkerd, Cilium)
- **eBPF-based enforcement** — kernel-level network policy without sidecar overhead (Cilium, Tetragon)
- **Network Policy (Kubernetes)** — namespace/pod-level ingress/egress rules; default-deny baseline
- **Microsegmentation platforms** — Illumio, Guardicore, AWS Network Firewall for cross-VPC enforcement

## Design decisions & trade-offs

> [!todo] verify

## State of the art

> [!todo] verify

## Pitfalls & anti-patterns

- Relying solely on perimeter firewalls; assuming east-west traffic is safe
- Overly permissive security groups (0.0.0.0/0 inbound, all-port allow within VPC)
- No default-deny baseline in Kubernetes — all pods can reach all pods by default
- Segmentation rules that exist on paper but are never tested (no validation tooling)
- Flat network for AI workloads — GPU inference nodes with unrestricted egress are a data-exfiltration risk

## See also

- [[zero-trust-architecture]]
- [[iam-and-secrets-management]]
- [[encryption-and-key-management]]
- [[kubernetes-at-design-level]]
- [[api-gateways-and-service-mesh]]
- [[ai-specific-security]]

## Sources

