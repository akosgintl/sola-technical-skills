---
title: T-Shaped Depth
aliases: [T-shaped skills, breadth and depth, pi-shaped, staff engineer skills]
type: concept
domain: meta
status: mature
tags: [meta, skills, career, breadth, depth, staff-engineer]
updated: 2026-06-21
sources:
  - https://teamtopologies.com/book
  - https://staffeng.com/book
  - https://hbr.org/2010/07/t-shaped-managers-knowledge-ma
  - https://www.goodreads.com/book/show/4099.The_Pragmatic_Programmer
  - https://www.mckinsey.com/capabilities/mckinsey-design/our-insights/the-business-value-of-design
---

# T-Shaped Depth

> [!summary]
> T-shaped depth describes a skill profile combining wide horizontal breadth across many domains — enough to reason about a whole system and connect its parts — with genuine vertical depth in a focused few. Breadth enables integration and systems thinking; depth produces the hard-won judgment that earns credibility and enables effective delegation.

**Domain:** [[meta-skills|Meta-Skills]]

## What it is

The "T" is a spatial metaphor: the horizontal bar represents breadth — fluency across many domains sufficient to understand interactions, evaluate proposals, and notice when something is wrong; the vertical bar represents depth — genuine expertise in a small number of areas, acquired through sustained practice and hard problems, producing the intuition and judgment that breadth alone cannot.

Both dimensions matter and neither suffices alone. An architect with breadth and no depth can describe a system but not evaluate it critically. One with depth and no breadth produces technically excellent components that don't compose into working systems. The T-shape is the minimum viable profile for a practising architect; the pi-shape (two deep verticals) is the target by mid-career; and the comb-shape (multiple deep verticals) describes senior staff and principal engineers with long tenure.

## Why it matters

The case for breadth is obvious in architecture: you cannot design a system you cannot reason about as a whole. The case for depth is less often made explicitly and is the more important half.

Depth does three things breadth cannot. First, it produces **judgment**: the ability to make a call when the data is ambiguous, the trade-offs are close, and reasonable people disagree. Judgment is learned from the inside — from making decisions, seeing their consequences, and adjusting. Reading about database replication does not produce the same judgment as having debugged a replication lag incident at 2 AM.

Second, depth produces **credibility**: the authority that comes from having done the work. A team building a streaming data platform will accept architectural guidance from someone who has built one. They will not accept the same guidance from someone who has read about it. Credibility earned in one domain transfers partially to adjacent domains — earned trust generalises to some degree — but it must be grounded in genuine depth somewhere.

Third, depth produces the **capacity to review AI output correctly**. As AI generates more code, architecture, and analysis, the value of being able to evaluate whether the output is correct shifts to those with domain depth. Breadth allows you to know what questions to ask; depth allows you to evaluate the answers.

## Key concepts

### The horizontal bar: breadth thresholds

Architectural breadth is not the ability to implement in every domain — it is the ability to:
- Ask the right questions of a domain expert
- Evaluate whether a proposal is coherent and complete
- Notice when a design choice in one domain creates a problem in another
- Understand the failure modes of components you are integrating

The breadth threshold is lower than expert-level but higher than reading the Wikipedia summary. A useful calibration: can you, given a solution, identify its top two failure modes and its main trade-off? If yes, you have working breadth in that domain. The domains in this knowledge base — cloud, security, data, platform, integration, finops, observability, ai-agentic — define the breadth surface for a solution architect at this level.

### The vertical bar: what counts as depth

Depth is not years of exposure. It is the acquisition of non-obvious knowledge: the kind that comes from encountering the exceptions, the edge cases, and the failures that simple descriptions don't cover. Signs of depth in a domain:

- You know which documentation is wrong
- You have a model of why the system behaves the way it does, not just how to operate it
- You can predict failure modes before they occur, not just recognise them after
- You can distinguish an expert proposal from a plausible-sounding wrong one

Depth is earned through: building systems that go to production and fail; debugging hard problems without a reference answer; reading primary sources (papers, RFCs, source code) rather than summaries; and teaching — which forces clarity about what you actually understand.

For a solution architect, depth in 2–3 domains is achievable and sufficient. The right domains to go deep in are a function of: (a) what the architect finds genuinely interesting (sustainable), (b) where the market has durable demand (employable), and (c) where the team or organisation has a gap (impactful). Maximising only market demand produces burnout; maximising only interest produces a skill set that doesn't connect to work; the overlap is the target.

### Profile evolution

| Career stage | Typical profile | What to invest in |
|---|---|---|
| Early career | I-shaped (one depth, no breadth) | Expand breadth; learn adjacent domains by doing |
| Mid-career | T-shaped (breadth + one depth) | Deepen the primary vertical; start a second |
| Senior / Staff | Pi-shaped (breadth + two depths) | Connect depth verticals; develop influence without authority |
| Principal / Distinguished | Comb-shaped (breadth + multiple depths) | Set direction; build organisational capability |

The transition from I to T is the first critical shift — acquiring breadth from a narrow depth base. The transition from T to pi is the second — developing a second genuine depth without losing the first. Both transitions require deliberate investment; neither happens by accumulating years in one role.

### The AI-changed T: where depth goes now

AI tools alter the economics of the T significantly. For breadth:
- AI can generate working code in a domain the architect is not expert in
- AI can summarise a domain's major patterns and failure modes in minutes
- AI can produce first-pass architecture proposals across any domain

This means breadth has become easier to access on demand and therefore less differentiating as a standalone skill. The horizontal bar is now partly provided by AI, lowering the individual investment required to maintain functional breadth.

For depth, the effect is opposite:
- AI output in a deep domain requires a domain expert to evaluate correctly
- The judgment needed to distinguish good AI-generated architecture from plausible-but-wrong architecture requires genuine depth
- Depth becomes the scarcer and more differentiating asset as breadth becomes more accessible

The implication: the T does not flatten — it becomes more important to have genuine verticals, because that is where the value that AI does not provide lives. The architect who outsources their vertical to AI has nothing left that AI cannot replicate.

### Team Topologies and the T-shape

Skelton & Pais identify three collaboration modes between teams: *collaboration* (deep, temporary, two teams working together), *X-as-a-Service* (low-touch, one team consumes from another), and *facilitating* (a platform team removes friction for stream-aligned teams). Each mode requires different depth and breadth combinations. Architects facilitating a platform team need depth in platform engineering; architects enabling cross-team integration need breadth in both the integrating domains and in integration patterns. The T-shape is not fixed across roles — it configures to the interaction mode.

## Design decisions and trade-offs

**Where to invest in depth.** The depth decision is one of the highest-leverage choices an architect makes about their own time. Competing criteria: interest (intrinsic motivation makes depth sustainable), market signal (what domains are persistently underserved by deep expertise), organisational need (what gap creates the most leverage for the team). The worst choice is to follow market signal alone and acquire depth in a domain that is trending because it is trending, without genuine interest. That produces shallow expertise dressed as depth.

**Breadth maintenance.** Breadth decays. A domain you were fluent in three years ago has changed: new tools, new failure modes, new regulatory requirements. The breadth maintenance cost is lower than depth acquisition but non-zero. A rough budget: spend 10–15 % of learning time on breadth maintenance (following primary sources, reading architecture decision records from adjacent domains) and the remainder on depth development.

**Depth at the cost of breadth.** In periods of intense depth development — a new project, a difficult problem, a deep learning investment — breadth maintenance may temporarily slip. This is appropriate. The risk is that temporary narrowing becomes permanent. Deliberate breadth refresh (an unfamiliar project, a cross-domain review) after a depth period is the counterweight.

## State of the art

Will Larson's *Staff Engineer* (2021) describes the scope expansion that distinguishes staff-level architects: from depth-first (personal technical output) through T-shaped (technical leadership across a team) to setting direction for multiple teams. The pi-shape is the practical profile of most staff engineers: two genuine verticals that create the credibility to lead work across a portfolio of systems.

**IDEO and the T-shape origin (Tim Brown, 2010):** the T-shaped designer metaphor emerged in product design — an individual contributor needs enough breadth to collaborate with researchers, engineers, and business stakeholders, and enough depth in their own craft to contribute original work. The architecture profession adopted the metaphor because the same structure applies: the architect collaborates across all disciplines but brings irreplaceable craft somewhere.

**The pi-shape as practitioner target.** The comb-shape (many verticals) is often invoked but rarely achieved, and rarely necessary. Two well-chosen verticals that complement each other (e.g., AI/agentic + security; cloud + data; platform + observability) create more leverage than three shallow ones. The pairing allows cross-domain judgment that neither vertical produces alone: the AI/security architect sees attack surfaces that pure security architects miss; the cloud/data architect sees cost and scale implications that pure data architects don't weigh.

> [!tip]
> When choosing where to go deep, pick the domain where you most want to know what the experts know — the one where every new piece of understanding changes how you see the rest of the system. That signal distinguishes genuine depth acquisition from résumé optimisation.

## Pitfalls and anti-patterns

- **I-shaped over-specialisation.** Deep expertise that produces no horizontal fluency makes collaboration expensive — every cross-team interaction requires translation. The I-shaped engineer is a productivity bottleneck at the interfaces.
- **Dash-shaped (breadth only).** Functional across every domain but not expert in any. Can describe a system; cannot evaluate it critically; cannot mentor engineers building it; cannot distinguish expert proposals from plausible-sounding weak ones.
- **Depth in adjacent domains only.** Acquiring two verticals in closely related areas (e.g., two cloud platforms) creates depth that doesn't compound. Non-adjacent verticals (cloud + security, AI + data) produce cross-domain judgment that each vertical alone does not.
- **Confusing exposure with depth.** Having used a technology in three projects is exposure. Knowing why it makes the design choices it does, where it breaks, and what the original designers got wrong is depth. Exposure accumulates automatically; depth requires deliberate effort.
- **Outsourcing depth to AI.** Using AI to generate answers in a domain where you have no depth, then presenting those answers as your judgment, is depth substitution. It works until someone asks a follow-up question. And it produces no capacity to review the AI's output correctly.
- **Depth without breadth means missing integration failures.** A database expert who designs a perfect schema in isolation but doesn't understand the event-driven system it integrates with will create a component that is excellent locally and harmful globally.

## See also

- [[systems-thinking-over-syntax]] — breadth in service of reasoning about whole systems
- [[trade-off-judgment]] — the judgment that depth enables
- [[delegate-review-own]] — the capacity depth provides for evaluating delegated output
- [[accountable-human-layer]] — the role depth plays in credible human oversight
- [[ai-evaluation-and-quality]] — depth is required to evaluate AI output in any domain correctly

## Sources

- Skelton, M. & Pais, M. (2019). *Team Topologies.* IT Revolution. https://teamtopologies.com/book
- Larson, W. (2021). *Staff Engineer: Leadership Beyond the Management Track.* Stripe Press. https://staffeng.com/book
- Brown, T. (2010). *T-Shaped Stars: The Backbone of IDEO's Collaborative Culture.* Chief Executive. https://hbr.org/2010/07/t-shaped-managers-knowledge-ma
- Hunt, A. & Thomas, D. (1999). *The Pragmatic Programmer.* Addison-Wesley. https://www.goodreads.com/book/show/4099.The_Pragmatic_Programmer
- McKinsey Design (2018). *The Business Value of Design.* https://www.mckinsey.com/capabilities/mckinsey-design/our-insights/the-business-value-of-design
