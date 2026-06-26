---
title: API Gateways and Service Mesh
aliases: [API gateway, service mesh, ingress, sidecar, Istio, Envoy, Linkerd, Kong]
type: concept
domain: integration
status: mature
tags: [integration, api-gateway, service-mesh, networking, istio, envoy, linkerd, mtls, ambient-mesh]
updated: 2026-06-20
sources:
  - "https://dev.to/mechcloud_academy/kubernetes-gateway-api-in-2026-the-definitive-guide-to-envoy-gateway-istio-cilium-and-kong-2bkl"
  - "https://www.cncf.io/blog/2025/08/26/use-envoy-gateway-as-the-unified-ingress-gateway-and-waypoint-proxy-for-ambient-mesh/"
  - "https://jimmysong.io/blog/envoy-gateway-introduction/"
  - "https://medium.com/@rajkundalia/api-gateway-vs-service-mesh-beyond-the-north-south-east-west-myth-c67406984a46"
  - "https://dasroot.net/posts/2026/04/api-gateway-vs-service-mesh-when-to-use/"
  - "https://lucaberton.com/blog/kong-vs-envoy-vs-traefik-api-gateway-2026/"
---

# API Gateways and Service Mesh

> [!summary]
> API gateways and service meshes are infrastructure layers that manage traffic at different axes and layers. Gateways handle north-south traffic (external clients to services): authentication, rate limiting, routing, and API composition at the edge. Service meshes handle east-west traffic (service to service): mTLS, retries, circuit breaking, traffic shaping, and observability injected by the infrastructure without application code changes. In 2026, the boundary is dissolving — the Kubernetes Gateway API provides a unified standard for both, and sidecar-less ambient mesh reduces the operational cost of meshes significantly.

**Domain:** [[tier-2-solid|Integration & API Architecture]]

## What it is

Two separate concerns that are often confused because their capabilities overlap:

**API Gateway:** a reverse proxy at the edge of the system. External clients (browsers, mobile apps, partner APIs) connect to the gateway, which handles cross-cutting concerns (auth, rate limiting, SSL termination, routing) before forwarding requests to internal services. Replaces each service implementing these concerns independently.

**Service Mesh:** a data plane layer deployed alongside services (traditionally as sidecar proxies) that intercepts all service-to-service traffic. Provides mTLS, retry policies, circuit breaking, traffic shaping, and distributed tracing without any application code changes — the mesh handles it at the infrastructure level.

They are complementary: a gateway handles what comes in from outside; a mesh handles how services talk to each other inside. Many production systems use both.

## Why it matters

Without a gateway, every service must implement authentication, rate limiting, and SSL handling independently — duplicated logic, inconsistent behavior, scattered security policy. Without a mesh, every service must implement mTLS, retries, and circuit breaking independently — the same duplication problem for internal traffic.

Both patterns centralize cross-cutting concerns in the infrastructure layer, letting application code focus on business logic. For [[zero-trust-architecture]], the mesh provides the mTLS layer that encrypts and authenticates all east-west traffic without requiring developers to manage certificates.

## Key concepts / building blocks

### API Gateway responsibilities

The gateway is the single entry point for external traffic:

| Concern | What the gateway does |
|---|---|
| **Authentication** | Verify JWTs, OAuth tokens, API keys before forwarding |
| **Rate limiting** | Enforce per-client, per-endpoint request quotas |
| **SSL/TLS termination** | Accept HTTPS externally; forward HTTP or mTLS internally |
| **Routing** | Path-based (`/api/v1/orders` → order service), header-based, weight-based |
| **Request/response transformation** | Rewrite headers, transform payloads, aggregate responses |
| **Caching** | Cache responses for read-heavy endpoints |
| **Observability** | Centralize access logs, metrics, distributed trace injection |

**Gateway products (2026):**
- **Kong** — the most widely deployed; plugin ecosystem; supports DB-less declarative mode; Konnect (managed)
- **AWS API Gateway** — fully managed; deep AWS integration; HTTP API (v2) for low-latency workloads
- **Azure API Management (APIM)** — managed; strong enterprise and developer portal features
- **Google Cloud API Gateway / Apigee** — managed; Apigee for full lifecycle management
- **Traefik** — Kubernetes-native; CRD-based config; popular in dev/SMB contexts
- **Envoy Gateway** — the emerging cloud-native standard; implements the Kubernetes Gateway API spec; CNCF project

### Kubernetes Gateway API (the standard)

The **Kubernetes Gateway API** (GA in Kubernetes 1.28) replaces the older Ingress API with a richer, role-oriented model:

- **GatewayClass** — cluster-level, owned by infrastructure team; defines which controller implements the gateway
- **Gateway** — cluster or namespace-level; defines the listener (port, protocol, TLS)
- **HTTPRoute / GRPCRoute / TCPRoute** — namespace-level, owned by app teams; defines routing rules to backend services

The Gateway API is now implemented by Kong, Envoy Gateway, Istio, Cilium, Traefik, NGINX, and others — it is the convergence point for both ingress and service mesh traffic management.

### Service mesh architecture

**The sidecar model (traditional):** a proxy sidecar container (almost always Envoy) is injected into every pod. All inbound and outbound traffic from the application container flows through the sidecar, which enforces mTLS, applies retry/circuit-breaker policies, and emits telemetry. The control plane (Istiod for Istio) distributes certificates and policy configuration to all sidecars.

**Service mesh capabilities:**
- **mTLS** — mutual TLS between all services; both sides present certificates; traffic is encrypted and both endpoints are authenticated
- **Traffic management** — weighted routing (canary: 5% to new version), header-based routing, fault injection for testing
- **Retries and circuit breaking** — configured in mesh policy, not application code; consistent behavior across all services
- **Distributed tracing** — sidecars automatically propagate `traceparent` headers and emit spans
- **Authorization policy** — L7 allow/deny rules ("service A may call service B on GET /api/resource only")

### Service mesh landscape

| Mesh | Proxy | Architecture | Standout |
|---|---|---|---|
| **Istio** | Envoy | Sidecar + Ambient (sidecarless) | Most features; Ambient mode GA in 2024 removes sidecar overhead |
| **Linkerd** | Rust micro-proxy | Sidecar | Lightweight; lowest latency overhead; only non-Envoy major mesh |
| **Cilium Service Mesh** | eBPF (no sidecar) | Sidecarless | Best L4 performance; eBPF in kernel, no proxy process |
| **Consul Connect** | Envoy | Sidecar | HashiCorp ecosystem; multi-platform (VMs + K8s) |

**Istio Ambient mode** (GA 2024) is the most significant architectural shift: it removes per-pod sidecars and replaces them with:
- **ztunnel** (per-node, not per-pod): handles L4 mTLS for all pods on the node; ultra-low overhead
- **Waypoint proxy** (per-namespace/service): handles L7 policy for services that need it; deployed only where needed

This reduces memory overhead by ~50% vs. sidecar model and eliminates the sidecar injection operational burden.

**Envoy Gateway** as the unified layer: CNCF's Envoy Gateway can serve as both the ingress gateway (north-south) and the waypoint proxy in Istio Ambient (east-west) — one Envoy-based data plane for both traffic axes.

### Gateway vs. mesh: when to use each

| Scenario | Solution |
|---|---|
| Authenticate external API consumers | API gateway (centralized auth) |
| Rate-limit by API key | API gateway |
| Expose multiple services under one domain | API gateway (routing) |
| Encrypt all service-to-service traffic (mTLS) | Service mesh |
| Canary deployment between internal services | Service mesh (traffic weight) |
| Circuit breaking between internal services | Service mesh |
| Zero-trust east-west policy (deny by default) | Service mesh (auth policy) |
| Distributed tracing across all services | Service mesh (automatic) |
| Public API lifecycle management (versioning, dev portal) | API gateway (full lifecycle) |

### The convergence trend

The north-south / east-west boundary is dissolving. Istio's Gateway API support means the same `HTTPRoute` resource configures both external ingress and internal mesh routing. Envoy Gateway uses the same Gateway API for both. Cilium handles both ingress and east-west L4 enforcement via eBPF.

The practical implication: teams that adopt the Kubernetes Gateway API for ingress get a migration path to service mesh east-west management using the same API constructs, reducing the learning cliff of adopting a mesh.

## Design decisions & trade-offs

**Sidecar mesh vs. ambient/sidecarless:**
Sidecars give per-pod isolation (a misbehaving sidecar only affects its pod) but add memory overhead (~50MB/pod), increase pod startup time, and complicate operations (injection, upgrades). Ambient mode (Istio) and Cilium eBPF eliminate the sidecar cost but are newer and have fewer production case studies. For greenfield Kubernetes deployments in 2026: evaluate Istio Ambient or Cilium; for existing sidecar deployments: the migration path is available but not urgent.

**Do you need both a gateway and a mesh?**
Not always. If all services are in Kubernetes with Istio Ambient, the mesh handles mTLS, traffic management, and some auth. A separate gateway is still valuable for: external consumer auth (API keys, OAuth), rate limiting by consumer, developer portal, and legacy non-Kubernetes services. For internal-only systems with no external consumers, a mesh alone may be sufficient.

**Self-managed vs. managed mesh:**
Istio is operationally complex (control plane upgrades, certificate rotation, sidecar injection). Managed options: GKE with Traffic Director, AWS App Mesh (Envoy-based), Linkerd Buoyant Enterprise. For teams without mesh expertise, managed reduces operational burden significantly.

## State of the art

The Kubernetes Gateway API is the convergence point replacing Ingress, and both API gateway vendors (Kong, Traefik) and service mesh projects (Istio, Linkerd, Cilium) now implement it. Istio Ambient mode reaching GA in 2024 removed the primary operational objection to meshes (sidecar overhead). Cilium's eBPF-based approach gives the best L4 performance with no proxy process overhead.

For AI inference workloads: gateways are increasingly used as the routing layer for LLM API traffic (rate limiting per user, routing between model versions, cost attribution) — an emerging use case that standard API gateway plugins are beginning to address.

## Pitfalls & anti-patterns

**Using a mesh when you just need mTLS.** A full service mesh for mutual TLS between services is overkill if traffic management, retries, and L7 policy are not needed. Cilium's built-in encryption or cert-manager + application-level TLS may be simpler.

**Bypassing the gateway for "internal" services.** Services that are "internal" today become external-facing when the business model changes. Build auth and rate-limiting into the gateway from the start; adding it later is expensive.

**Ingress without the Gateway API.** The legacy Kubernetes Ingress resource lacks expressiveness (no traffic weights, no header routing). New deployments should use the Gateway API which supports these natively.

**Mesh without observability integration.** A mesh generates rich telemetry but requires aggregation (Prometheus, Jaeger/Tempo) to be useful. Deploy the observability stack before or alongside the mesh, not after incidents reveal the gap.

## See also

- [[api-styles-and-protocols]]
- [[api-security]]
- [[observability-fundamentals]]
- [[zero-trust-architecture]]
- [[kubernetes-at-design-level]]
- [[distributed-systems-reliability]]
- [[coupling-and-versioning-discipline]]

## Sources

- MechCloud Academy. (2026). Kubernetes Gateway API in 2026: The Definitive Guide to Envoy Gateway, Istio, Cilium and Kong. https://dev.to/mechcloud_academy/kubernetes-gateway-api-in-2026-the-definitive-guide-to-envoy-gateway-istio-cilium-and-kong-2bkl
- CNCF. (2025). Use Envoy Gateway as the Unified Ingress Gateway and Waypoint Proxy for Ambient Mesh. https://www.cncf.io/blog/2025/08/26/use-envoy-gateway-as-the-unified-ingress-gateway-and-waypoint-proxy-for-ambient-mesh/
- Song, J. (2026). Envoy Gateway Overview: Modern Kubernetes Ingress with the Gateway API. https://jimmysong.io/blog/envoy-gateway-introduction/
- Kundalia, R. (2026). API Gateway vs Service Mesh: Beyond the North-South/East-West Myth. https://medium.com/@rajkundalia/api-gateway-vs-service-mesh-beyond-the-north-south-east-west-myth-c67406984a46
- DasRoot. (2026). API Gateway vs Service Mesh: When to Use Each. https://dasroot.net/posts/2026/04/api-gateway-vs-service-mesh-when-to-use/
- Berton, L. (2026). Kong vs Envoy vs Traefik 2026: API Gateway Benchmark. https://lucaberton.com/blog/kong-vs-envoy-vs-traefik-api-gateway-2026/
