---
title: Dynamic / Surge Team-Staffing Models
aliases: [dynamic staffing, surge staffing, on-demand specialist teams, agentic team scaling]
type: concept
domain: emerging
status: mature
tags: [emerging, team-topology, staffing, agentic-workflows, org-design, cognitive-load]
updated: 2026-06-22
sources:
  - https://teamtopologies.com/key-concepts
  - https://dora.dev/research/
  - https://queue.acm.org/detail.cfm?id=3454124
  - https://www.anthropic.com/engineering/claude-code-best-practices
  - https://www.mckinsey.com/capabilities/mckinsey-digital/our-insights/the-economic-potential-of-generative-ai
  - https://lethain.com/staff-engineer-archetypes/
---

# Dynamic / Surge Team-Staffing Models

> [!summary]
> Dynamic team-staffing assembles specialist capacity on demand — rather than maintaining permanently staffed teams — by combining lean human core teams with agentic AI workflows and short-engagement human specialists. The model is enabled by AI agents that handle routine delivery at scale, allowing organisations to concentrate scarce human judgment on high-stakes decisions and bring specialists in briefly for bounded engagements. It shifts org design from headcount-centric to outcome-centric.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

The conventional software team model is the permanent, cross-functional squad: a stable group of 5–8 engineers who collectively own a product or service end-to-end. Staffing decisions are made in annual cycles; capability gaps are addressed by hiring; team size is the proxy for team capacity.

Dynamic staffing challenges these assumptions by separating three kinds of team function that permanent squads bundle together:

1. **Continuity and judgment** — deep, long-term understanding of the system, its history, its stakeholders, and its failure modes. This is the function of a lean, permanent core team.
2. **Delivery throughput** — writing features, tests, documentation, and pull requests at volume. This is increasingly a function that agentic AI handles, supervised by the core team.
3. **Specialist expertise** — depth in specific domains (security audit, ML engineering, compliance review, performance engineering) that the core team cannot maintain permanently but needs episodically. This is the function of short-engagement human specialists.

The practical outcome: a smaller permanent team with higher quality judgment, augmented by AI agents for throughput and human specialists for bounded expertise engagements. This is not "fewer engineers" — it is a different composition of what engineers do.

## Why it matters

**AI changes the marginal cost of implementation.** The cost of generating a first-cut implementation (a feature, a service skeleton, a test suite) has dropped significantly with AI coding tools. A developer with Claude Code or Copilot can produce working code faster than previously possible. The remaining scarcity is not implementation velocity — it is architectural judgment, system context, and accountability for what gets deployed.

**Throughput no longer bounds headcount linearly.** In the traditional model, doubling throughput required doubling headcount. With AI agents handling routine implementation, a team of 3 with AI augmentation can sustain the throughput of a team of 6–8 — for tasks that are implementation-heavy and relatively well-specified. This changes the ROI calculation for hiring vs. improving tooling and AI toolchains.

**Specialists are expensive to maintain permanently.** A security architect who spends 30% of their time on active security work and 70% in meetings, context-switching, and organisational maintenance is expensive. A specialist engaged for a bounded security audit — who enters with context (via the knowledge base), does the work, and exits — delivers the same expert output with a fraction of the overhead.

**Context-as-a-service enables rapid specialist onboarding.** The traditional friction with specialist engagement is knowledge transfer: weeks spent getting the specialist up to speed before they can be productive. A well-maintained knowledge base (this wiki) can compress that transfer dramatically: the specialist reads the relevant concept pages, architectural decision records, and system documentation and reaches working context in hours rather than weeks. The knowledge base is the API for specialist engagement.

## Key concepts

### The three-layer model

**Layer 1: Lean core team.** 2–5 engineers with deep, continuous knowledge of the system. They:
- Set architectural direction and make high-stakes design decisions
- Review, gate, and integrate all output (AI-generated or specialist-produced)
- Maintain the knowledge base and ADR trail
- Retain full accountability for the system (see [[delegate-review-own]] and [[accountable-human-layer]])
- Operate continuously, maintaining the context that enables everything else

**Layer 2: Agentic throughput layer.** AI agents (coding agents, test generators, documentation bots, PR reviewers) handling volume delivery tasks:
- Feature implementation from well-specified tickets
- Test generation to cover new code paths
- Documentation updates when code changes
- Dependency updates and vulnerability patching
- PR review for conformance to coding standards

The core team reviews and gates all agent output. The agent layer does not make architectural decisions and does not deploy without human approval. See [[human-in-the-loop-design]] and [[vibe-coding-governance]] for the governance design.

**Layer 3: On-demand human specialists.** Subject-matter experts engaged for bounded time and purpose:

| Role | Typical engagement | What they deliver |
|---|---|---|
| Security auditor | 2–5 days, annual or pre-launch | Threat model, penetration test findings, ADRs for mitigations |
| ML engineer | 1–4 weeks, per AI workload | Model evaluation setup, fine-tuning, [[ai-evaluation-and-quality|eval framework]] |
| Compliance reviewer | 1–3 days, per regulatory change | Gap analysis, control mapping, evidence package |
| Performance engineer | 1–2 weeks, per capacity planning cycle | Load test results, bottleneck analysis, scaling recommendations |
| Staff/principal engineer | 2–4 hours, design review | Architecture critique, anti-pattern identification, ADR input |

The engagement is outcome-defined ("produce a threat model for the payment processing service") not time-defined ("join the team for a month"). The specialist receives context from the knowledge base, does the work, captures findings in the knowledge base or ADR trail, and exits. The core team integrates the findings.

### Team Topologies integration

Skelton & Pais define four fundamental team types for product delivery organisations:
- **Stream-aligned teams:** the primary value delivery team, aligned to a flow of business work
- **Platform teams:** reduce cognitive load on stream-aligned teams by providing self-service capabilities
- **Enabling teams:** specialist teams that help stream-aligned teams adopt new practices (temporarily; they aim to make themselves unnecessary)
- **Complicated-subsystem teams:** own subsystems requiring deep specialist knowledge

Dynamic staffing extends and accelerates the **enabling team** pattern: rather than a permanent enabling team that coaches and uplifts stream-aligned teams over months, dynamic staffing brings in specialists for bounded engagements to perform a specific enabling function (security review, ML setup, compliance mapping) and exits.

The **AI agent layer** can be conceptualised as a fifth pattern: an **agentic delivery layer** that acts as a high-throughput but low-judgment implementation team. Like a platform team, it reduces the burden on the core team for specific repeatable tasks; unlike a platform team, it requires close supervision and output review rather than operating independently.

### Staff augmentation vs. dynamic staffing

These are superficially similar but fundamentally different:

| Dimension | Staff augmentation | Dynamic staffing |
|---|---|---|
| Engagement basis | Time-based (contractor for 6 months) | Outcome-based (security audit delivered) |
| Specialist role | Fills a headcount gap; works as team member | Provides specific expertise; delivers bounded output |
| Knowledge transfer direction | Specialist learns the system | Core team uses knowledge base to brief the specialist |
| Accountability | Shared with the specialist during engagement | Core team retains full accountability throughout |
| Dependency | Specialist may become critical path | Engagement ends; core team integrates and owns result |

Staff augmentation is the right model when the gap is long-term capacity that the team cannot deliver. Dynamic staffing is the right model when the gap is episodic specialist expertise that the core team cannot economically maintain permanently.

### Context discipline: the knowledge base as an enabler

Dynamic staffing only works if the knowledge base is current, accurate, and structured for rapid specialist onboarding. A specialist who spends 3 of a 5-day engagement on knowledge discovery has wasted 60% of the engagement budget on overhead.

Requirements for the knowledge base to enable dynamic staffing:
- **Architectural decisions are documented** (ADRs in the repository) with context and rationale, not just outcome
- **System design is current** (wiki pages updated as the system evolves, not after-the-fact)
- **Operational runbooks are discoverable** (indexed, not buried in person's memory or outdated Confluence pages)
- **Non-obvious design decisions are explicitly recorded** — the "why" behind choices that seem arbitrary without context

The specialist engagement should end with the knowledge base richer: findings documented, ADRs written, gaps filled. This converts a time-bounded engagement into a permanent asset.

### Accountability structure in dynamic models

The principal-agent problem ([[delegate-review-own]]) is acute in dynamic staffing: a specialist who makes a design decision during an engagement and then exits cannot be held accountable for the consequences of that decision over the following years. The core team is the accountable party throughout.

This has structural implications:
- Specialists make recommendations; core team members make decisions
- Specialist findings are reviewed and integrated, not adopted wholesale
- Core team signs off on any permanent change to architecture, security posture, or compliance approach
- The knowledge base captures the specialist's reasoning, not just their conclusion — so the core team can evaluate it and disagree if appropriate

See [[accountable-human-layer]] for the governance principle; dynamic staffing is an organisational instantiation of that principle.

## Design decisions and trade-offs

**When is dynamic staffing appropriate?** Dynamic staffing works well for: stable-core systems that need episodic specialist review; teams with high-quality knowledge management disciplines; organisations that can define bounded outcomes for specialist engagements. It works poorly for: rapidly evolving systems where context changes faster than specialists can be briefed; teams without a maintained knowledge base (specialist onboarding overhead dominates); work that requires deep continuity (on-call incident response, platform ownership, complex migration projects with evolving requirements).

**How lean can the core team be?** The core team must be large enough to review and integrate all AI agent output without that review becoming the bottleneck. If the agent throughput exceeds the core team's review capacity, either the agent throughput must be constrained (gating rules) or the core team must grow. One engineer reviewing 10 AI-generated pull requests per day is the outer limit for quality review; plan core team size around review capacity, not implementation capacity.

**Agentic agents vs. AI-assisted developers.** The throughput layer can be fully agentic (autonomous agents operating from tickets, with human review of output) or AI-assisted developers (human engineers using AI coding tools, with standard PR review). Fully agentic is higher throughput with higher review burden; AI-assisted is lower throughput with standard review processes. The right choice depends on the team's governance maturity for AI output. Most teams start AI-assisted and move toward agentic as trust and tooling matures.

**Knowledge base investment vs. specialist efficiency.** The knowledge base investment pays back in specialist efficiency: a well-maintained wiki means a 5-day security audit starts at day 1 rather than day 3. The investment also pays back in AI agent quality: agents that can read the knowledge base produce more contextually appropriate code. The knowledge base is a shared infrastructure investment that pays across both the agentic layer and the specialist engagement layer.

## State of the art

**AI coding agent throughput** is real but context-dependent. GitHub Copilot's own internal research (2024) found AI-assisted developers completed well-specified tasks 55% faster. Anthropic's Claude Code internal deployment showed similar throughput gains for implementation-heavy tasks. The gains are smaller for ambiguous tasks, design decisions, and cross-cutting concerns — precisely the work that the core team must retain.

**Principal-engineer-as-specialist.** The staff engineering community (Will Larson, Tanya Reilly, Lara Hogan) has long described the "solver" archetype: a principal engineer who embeds in a team to solve a specific hard problem and then moves on. Dynamic staffing formalises and scales this pattern, applying it to a broader range of specialist roles beyond staff engineering.

**Outcome-based contracting for AI-augmented specialists.** Several consulting firms (including McKinsey QuantumBlack, Thoughtworks, and Andreessen Horowitz a16z) have published on AI-augmented delivery models where smaller consultant teams with AI tools deliver work previously scoped for larger teams. The billing model shifts from hourly/daily rates toward outcome-based pricing — a natural fit for the dynamic staffing pattern.

**The boundary with permanent teams.** Full replacement of permanent engineering teams with dynamic staffing and AI agents is not viable for production systems in mid-2026. Systems require continuous care — security patches, dependency updates, incident response, progressive feature delivery — that cannot be scoped as bounded engagements. The dynamic model reduces the size of the permanent core required, not to zero.

> [!tip]
> The minimum viable dynamic staffing posture for a team: (1) maintain a knowledge base that a new person can use to reach working context in one day; (2) have one specialist engagement cadence defined (e.g., annual security review, quarterly architecture review) with an owner and a defined deliverable; (3) measure AI agent output quality so you know whether the review burden is growing faster than throughput benefit. These three practices set the foundation for scaling the model further.

## Pitfalls and anti-patterns

- **Treating AI agents as headcount replacements.** AI agents are implementation accelerators, not engineers. They do not carry context, attend standups, notice architectural drift, or accept accountability. Treating them as headcount replacements produces under-supervised, under-accountable systems.
- **No knowledge capture between specialist engagements.** A specialist who exits without documenting their findings in the knowledge base leaves the team with an oral tradition they cannot transfer to the next specialist. Every engagement must end with the knowledge base richer.
- **Dynamic staffing for high-continuity work.** On-call incident response, platform ownership, and evolving complex migrations require deep, continuous context. Treating these as bounded specialist engagements — rotating through different specialists — produces dangerous context fragmentation.
- **Core team too lean to review agent output.** If the core team cannot review AI-generated output at the rate it is produced, quality degrades silently. The core team bottleneck is a system constraint — address it by constraining agent throughput or growing the core team, not by reducing review quality.
- **Specialists who make decisions without core-team buy-in.** A specialist who arrives, makes architectural decisions, documents them as ADRs, and exits without engaging the core team has transferred decisions without transferring accountability. The core team must be the decision-maker; the specialist is the advisor.
- **Measuring success by headcount reduction rather than outcomes.** Dynamic staffing is justified by delivery quality and specialist depth, not by how few engineers are on headcount. Organisations that measure it primarily as a cost reduction tend to under-invest in knowledge base quality and over-reduce core team size.

## See also

- [[delegate-review-own]] — individual-level discipline for reviewing and owning AI-generated and specialist-produced work
- [[accountable-human-layer]] — the governance principle that core teams retain full accountability throughout dynamic engagements
- [[human-in-the-loop-design]] — HITL gates for AI agent output review in the dynamic staffing model
- [[vibe-coding-governance]] — governance of AI coding tools that power the agentic throughput layer
- [[agentic-system-design]] — design patterns for the AI agents in the throughput layer
- [[multi-agent-orchestration]] — orchestration of multiple agents coordinating delivery tasks
- [[developer-experience]] — platform tooling that supports lean core teams by reducing infrastructure overhead

## Sources

- Skelton, M. & Pais, M. (2019). *Team Topologies — Key Concepts.* https://teamtopologies.com/key-concepts
- DORA (2024). *State of DevOps Research — AI-Augmented Teams.* https://dora.dev/research/
- Forsgren, N. et al. (2021). *The SPACE of Developer Productivity.* ACM Queue. https://queue.acm.org/detail.cfm?id=3454124
- Anthropic (2025). *Claude Code Best Practices — Agentic Delivery Patterns.* https://www.anthropic.com/engineering/claude-code-best-practices
- McKinsey & Company (2023). *The Economic Potential of Generative AI.* https://www.mckinsey.com/capabilities/mckinsey-digital/our-insights/the-economic-potential-of-generative-ai
- Larson, W. (2023). *Staff Engineer Archetypes — The Solver.* https://lethain.com/staff-engineer-archetypes/
