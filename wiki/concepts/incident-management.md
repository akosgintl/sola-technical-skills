---
title: Incident Management
aliases: [incident response, incident commander, blameless postmortem, postmortem, on-call, error budget policy, SRE incident management, MTTR]
type: concept
domain: observability
status: mature
tags: [observability, reliability, sre, incident-response, postmortem, on-call, error-budget]
updated: 2026-06-26
sources:
  - "https://sre.google/sre-book/managing-incidents/"
  - "https://sre.google/sre-book/postmortem-culture/"
  - "https://sre.google/workbook/error-budget-policy/"
  - "https://incident.io/blog/incident-management-best-practices-2026"
  - "https://rootly.com/incident-response/lifecycle-process"
---

# Incident Management

> [!summary]
> Incident management is the operational discipline of **responding to, coordinating, and learning
> from** service-impacting events: classifying severity, running a structured response with defined
> roles (an **incident commander** who coordinates rather than debugs), communicating to
> stakeholders, and producing a **blameless postmortem** whose fixes are tracked to completion. It
> is the human/process counterpart to the technical reliability layers —
> [[observability-fundamentals|observability]] *detects*, [[distributed-systems-reliability|
> resilience patterns]] *absorb*, [[disaster-recovery-and-continuity|DR]] *recovers* — while
> incident management *runs the response and closes the learning loop*. Its governance lever, the
> **error-budget policy**, is what ties reliability work to feature velocity.

**Domain:** [[tier-2-solid|Observability & Reliability]]

## What it is

Incidents are inevitable; the variable is how well you respond and whether you learn. Incident
management is the process invoked when a service degrades, organized as a lifecycle:

1. **Detect** — an alert (or a human) surfaces the problem (see [[observability-fundamentals]]).
2. **Triage & declare** — assess impact, assign a **severity**, declare an incident.
3. **Respond & coordinate** — assemble roles, establish a single source of truth, communicate.
4. **Mitigate** — restore service (often before root cause is known — stop the bleeding first).
5. **Resolve** — confirm recovery.
6. **Learn** — a **blameless postmortem** with tracked action items.

It is distinct from **on-call** (the rotation that catches the page) — on-call is *who*, incident
management is the *process* that runs once an incident is declared.

## Why it matters

**MTTR (mean time to recovery) is a business number**, and unstructured response inflates it: when
everyone debugs and nobody coordinates or communicates, outages run longer, stakeholders are blind,
and trust erodes. Worse, without a blameless postmortem and tracked fixes, **the same incident
recurs** — the organization pays for the outage repeatedly. And the **error-budget policy** is the
mechanism by which an organization actually governs the reliability-vs-velocity trade-off rather
than arguing it ad hoc. For an architect, incidents are also the ultimate, unfiltered feedback on
the architecture — the design's real failure modes, revealed under load.

## Key concepts / building blocks

### Severity levels

A shared severity taxonomy (typically SEV-1…SEV-4) lets everyone speak the same language under
pressure and drives the response intensity and postmortem requirement:

| Severity | Meaning | Response |
|---|---|---|
| **SEV-1** | Critical — major outage / data loss | All-hands, immediate, exec comms |
| **SEV-2** | High — significant degradation | Urgent, dedicated responders |
| **SEV-3** | Medium — minor impact, workaround exists | Normal working hours |
| **SEV-4** | Low — cosmetic, no user impact | Backlog |

### Incident roles

Separating **coordination** from **hands-on-keyboard** is the key insight:

- **Incident Commander (IC)** — owns the response end to end: assigns roles, makes decisions, keeps
  the timeline moving. The IC **does not troubleshoot** — their job is coordination.
- **Communications Lead** — stakeholder and (if needed) public/status-page updates.
- **Operations Lead** — directs the technical investigation and mitigation.

### Blameless postmortems

Every SEV-1/SEV-2 should produce a postmortem that focuses on **contributing causes and systemic
factors**, never on indicting an individual. The reason is practical, not just cultural: **when
people feel safe they tell you what actually happened**; when they fear blame they give the
sanitized version, and sanitized versions don't prevent recurrence. A postmortem's value is its
**tracked action items** — a postmortem with no follow-through is theater.

### Error-budget policy

The error budget is **1 − SLO** (a 99.9% SLO allows a 0.1% unreliability budget). The *policy* is
the pre-agreed rule: **when the budget is exhausted, feature releases halt** (except security/P0
fixes) until the service is back within SLO. This converts the [[observability-fundamentals|SLO]]
from a number into a governance lever — an objective, pre-negotiated way to make the
[[trade-off-judgment|reliability-vs-velocity trade-off]] without re-litigating it each time.

### On-call and alert quality

Sustainable rotations, clear escalation paths, and — critically — **actionable, low-noise alerts**.
Alert fatigue (pages that aren't actionable) is the fastest route to missed real incidents and
on-call burnout. Runbooks turn tacit response knowledge into followable steps.

### AIOps

AI applied to operations: **alert correlation and noise suppression**, anomaly detection (catching
incidents before threshold alerts fire), and **automated postmortem timelines**. Reported MTTR
reductions are real (double-digit percentages), but the durable framing is **assist, not autonomy**
— automate frequent, predictable, well-understood remediations first; keep humans in command (the
[[delegate-review-own|delegate, review, own]] model). Agent-driven systems also add *new*
non-deterministic failure modes that incident response must handle — see [[ai-agent-observability]].

## Design decisions & trade-offs

- **Severity thresholds.** Too coarse and everything is a SEV-1 (fatigue, no prioritization); too
  sensitive and real incidents hide in noise. Calibrate against real impact and revisit.
- **IC separated from troubleshooting.** Under serious load you need a coordinator who is *not*
  heads-down debugging — small teams resist this as "overhead" until an uncoordinated SEV-1 teaches
  them otherwise. The separation is the point.
- **Enforcing the error-budget policy.** A policy that never actually halts a release is RTO/RPO
  theater for reliability — it needs genuine org buy-in (product + engineering) to mean anything.
- **Blameless vs. accountability.** Blameless protects *individuals* from punishment; it does *not*
  absolve the *organization* from owning and fixing the systemic causes. The distinction is what
  keeps blameless from becoming consequence-free.
- **On-call sustainability.** Follow-the-sun vs. after-hours rotations, coverage vs. burnout, alert
  volume vs. signal. Treat on-call health as a first-class [[developer-experience|DevEx]] metric.
- **AIOps automation scope.** Automate the right things first (frequent, predictable, well-understood)
  — over-automating or automating poorly understood remediations erodes trust fast.

## State of the art

- **Google SRE practices remain canonical** — incident command, blameless postmortems, and
  error-budget policy are the reference model.
- **Dedicated incident platforms** (incident.io, Rootly, PagerDuty, FireHydrant) standardize
  declaration, roles, comms, and postmortem workflows, often integrated into Slack/Teams.
- **AIOps is delivering measurable MTTR gains** via alert correlation, earlier detection, and
  **AI-drafted postmortem timelines** — the latter solving the "nobody remembers what happened three
  days later" problem.
- **Error-budget-policy enforcement** is increasingly tooled and tied to release gates.
- **A new frontier**: incidents in agentic/AI systems, whose non-deterministic failure modes
  traditional runbooks don't anticipate — coupling incident management to [[ai-agent-observability]].

## Pitfalls & anti-patterns

- **No incident commander.** Everyone debugging, nobody coordinating or communicating — the outage
  runs long and stakeholders are blind.
- **Blameful postmortems.** Fear produces sanitized accounts; the real cause stays hidden and the
  incident recurs.
- **Untracked action items.** Postmortems written and filed, fixes never done — the same outage
  returns.
- **An unenforced error-budget policy.** A reliability rule everyone ignores; reliability vs.
  velocity stays an unwinnable argument.
- **Alert fatigue.** Noisy, non-actionable alerts train responders to ignore pages — including the
  real one.
- **No severity taxonomy.** Inconsistent, improvised response intensity; no shared language under
  pressure.
- **On-call burnout.** Unsustainable rotations and noisy pages drive attrition and degrade response.
- **Treating AIOps as autonomous.** Over-automating remediation erodes trust the first time it acts
  wrongly.

## See also

- [[observability-fundamentals]]
- [[distributed-systems-reliability]]
- [[disaster-recovery-and-continuity]]
- [[ai-agent-observability]]
- [[trade-off-judgment]]
- [[delegate-review-own]]
- [[developer-experience]]

## Sources

- [Google SRE Book — Managing Incidents](https://sre.google/sre-book/managing-incidents/)
- [Google SRE Book — Postmortem Culture: Learning from Failure](https://sre.google/sre-book/postmortem-culture/)
- [Google SRE Workbook — Error Budget Policy](https://sre.google/workbook/error-budget-policy/)
- [incident.io — Incident management best practices (2026)](https://incident.io/blog/incident-management-best-practices-2026)
- [Rootly — Incident Response Process: lifecycle for SRE teams](https://rootly.com/incident-response/lifecycle-process)
