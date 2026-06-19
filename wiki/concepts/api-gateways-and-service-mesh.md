---
title: API Gateways and Service Mesh
aliases: [API gateway, service mesh, ingress, sidecar]
type: concept
domain: integration
status: stub
tags: [integration, api-gateway, service-mesh, networking]
updated: 2026-06-19
sources: []
---

# API Gateways and Service Mesh

> [!summary]
> Infrastructure layers that manage traffic: gateways handle north-south (external) API concerns, while service meshes manage east-west (service-to-service) communication.

**Domain:** [[tier-2-solid|Integration & API Architecture]]

## What it is

API gateways sit at the edge, centralizing authentication, rate limiting, routing, and transformation for inbound traffic. Service meshes operate between services, using sidecar proxies to provide mTLS, traffic shaping, retries, and observability without changing application code. They address different traffic axes and are often used together.

## Key concepts

- North-south (gateway) vs. east-west (mesh) traffic
- Cross-cutting concerns: authn, rate limiting, routing
- Sidecar proxies (Envoy) and control planes (Istio, Linkerd)
- mTLS, traffic shaping, retries, circuit breaking
- Sidecarless / eBPF mesh trends

## See also

- [[api-styles-and-protocols]]
- [[coupling-and-versioning-discipline]]
- [[zero-trust-architecture]]
- [[observability-fundamentals]]
- [[kubernetes-at-design-level]]

## Sources

- _Stub — no sources ingested yet._
