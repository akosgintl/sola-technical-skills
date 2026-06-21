---
title: Delegate, Review, Own
aliases: [delegate review own, DRO, AI collaboration discipline]
type: concept
domain: meta
status: mature
tags: [meta, ai-collaboration, judgment, accountability, delegation, review]
updated: 2026-06-21
sources:
  - https://www.anthropic.com/research/building-effective-agents
  - https://lethain.com/elegant-puzzle/
  - https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf
  - https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689
  - https://www.jstor.org/stable/3665619
---

# Delegate, Review, Own

> [!summary]
> "Delegate, review, own" is the operating discipline for working with AI, agents, and teams: assign execution to the delegate, critically evaluate the output rather than rubber-stamping it, and retain full accountability for the result regardless of who produced it.

**Domain:** [[meta-skills|Meta-Skills]]

## What it is

The three verbs describe a discipline, not a workflow. They apply equally when delegating to a junior engineer, a contractor, a model, or an autonomous agent. The principle is the same in all cases: the person who delegates does not transfer accountability. They retain responsibility for the outcome and must therefore maintain the critical capacity to evaluate whether the output is good enough to accept.

This matters most when the delegate is fast and confident. An autonomous agent that produces a complete, coherent, well-formatted answer in seconds creates strong pressure to accept it without rigorous review. The discipline counters that pressure: the quality and confidence of the output do not change the reviewer's obligation to verify it.

## Why it matters

Principal-agent theory (Jensen & Meckling, 1976) describes the fundamental tension: the agent (who does the work) has different information and interests than the principal (who is accountable for the outcome). The principal cannot observe all of the agent's actions or verify all of the agent's claims. Delegation without review is trust without verification — it transfers the principal's accountability while giving them no information about whether that trust was warranted.

With human delegates, review quality degrades predictably under time pressure, social dynamics (reluctance to challenge a confident peer), and fatigue. With AI delegates, the same dynamics apply in sharper form: the output is produced faster, sounds more authoritative, and often contains no visible signal of uncertainty. Research on AI-assisted decision-making consistently finds that human reviewers rate AI outputs higher when presented as AI-generated (automation bias) and lower when they are told to review critically (but only if explicitly instructed to).

The EU AI Act Article 22 establishes a legal floor: individuals have the right not to be subject to solely automated decisions in high-stakes contexts. Article 14 mandates human oversight for high-risk AI systems, with "appropriate human-machine interface tools" enabling intervention. These are not aspirational principles — they are compliance requirements enforced from August 2026. The personal practice of "delegate, review, own" is the individual-level expression of these systemic requirements.

## Key concepts

### Delegation: what to assign and what to keep

Delegation is appropriate for:
- **Execution of a well-specified task** — writing the code for a defined function, drafting a document to a defined outline, running a repeatable analysis.
- **First-pass research and synthesis** — gathering options, summarising a domain, identifying relevant sources.
- **Applying a known pattern** — generating a Terraform resource matching an established module convention, translating a known design into a new language.

Delegation is not appropriate for:
- **Judgment calls that require context the delegate lacks** — trade-offs that depend on team history, regulatory nuance, or organisational politics.
- **Accountability** — the decision about whether to ship, sign, or commit is always the principal's.
- **Verification of the delegate's own output** — asking an agent to review its own work introduces the same self-evaluation bias that makes LLM-as-judge unreliable when the judge is the same model as the author.

### Review: what good review looks like

The obligation of review is to assess whether the output is correct and complete enough to accept, not to re-do the work. Three questions structure it:

1. **Is it correct?** Does the output do what was asked? Are the facts right? Does the code run? Does the argument hold?
2. **Is it complete?** Does the output address the full scope? What was the delegate likely to omit or underweight?
3. **Is it safe to accept?** Are there downstream consequences of accepting this output that weren't apparent from the task specification?

The depth of review should be proportional to the stakes, not the confidence of the output. A confident, polished output in a high-stakes domain requires exactly as much scrutiny as an uncertain, rough one — because the polish is independent of correctness. [[trade-off-judgment|Trade-off judgment]] applies here: what is the cost of accepting an error in this output vs. the cost of reviewing it in full?

**Minimum viable review for AI output:** read for what is *missing*, not just for what is *wrong*. LLMs are better at producing plausible content than at knowing the boundaries of their competence. The most dangerous errors are omissions and confident wrong assumptions, not obvious errors the model itself would flag.

### Trust calibration

Trust in a delegate is earned through a track record, not assumed from the delegate's apparent capability. The calibration process:

1. **Start with high oversight.** Review the first N outputs of a new delegate (person, model, or agent) fully, regardless of apparent quality.
2. **Sample, not zero.** After establishing a track record, reduce review intensity to a structured sample — but never to zero.
3. **Adjust on failure.** Any discovered error resets the trust level for that task class to higher oversight until the failure mode is understood and mitigated.
4. **Distinguish task classes.** Trust earned in one domain does not transfer to another. An agent trusted for code generation is not automatically trusted for security assessments.

The calibration for AI agents is more conservative than for humans because the failure modes are different: an agent can be confidently wrong in ways a human expert would not be, and the same agent can produce excellent output on 99 % of tasks while failing catastrophically on the 1 % where it encounters an edge case it was not designed for.

### Ownership: accountability does not transfer

The principal's accountability is not diminished by delegating to a more capable or faster delegate. "The model said to" is not a defence — not ethically, not legally, not organisationally. Ownership means: if the output causes harm, the principal answers for it.

This is not a statement about blame allocation — it is a statement about the discipline required to review properly. If the reviewer knows they are accountable for the outcome, they review with appropriate rigour. If they believe they can transfer accountability to the delegate, they review superficially.

In regulated domains, ownership is explicit: EU AI Act Article 28 specifies deployer obligations — including monitoring, human oversight, and incident reporting — that sit with the organisation deploying an AI system, regardless of whether the system was built externally.

## Design decisions and trade-offs

**Review depth vs. throughput.** Thorough review of every AI output at scale is not economically feasible. The trade-off is managed by: (a) concentrating review on high-stakes outputs, (b) sampling lower-stakes outputs statistically, (c) automating review of properties that are mechanically verifiable (does the code compile? does the JSON parse? do the tests pass?), and reserving human judgment for properties that are not (is the reasoning sound? are the trade-offs appropriate?).

**Synchronous vs. asynchronous review.** For agentic workflows, review can be synchronous (the agent pauses at a gate, human approves before continuing — see [[human-in-the-loop-design]]) or asynchronous (the agent completes the task, the human reviews before the output takes effect). The choice depends on whether errors are more costly during execution (synchronous gate) or after completion (asynchronous review).

**Explicit brief vs. implicit scope.** The quality of delegation is largely determined by the quality of the brief. A vague task specification transfers to the delegate the responsibility of interpreting scope, which may not match what the principal intended. Specificity in the brief reduces review burden by narrowing the space of acceptable outputs. Investing time in the brief is not administrative overhead — it is the highest-leverage part of the delegation.

## State of the art

The practice of delegation and review has always existed in engineering; what has changed is the speed and fluency of AI delegates. The throughput advantage of AI creates an incentive to reduce review intensity — and the historical record of AI-assisted work suggests this incentive is often acted on, leading to errors that would have been caught by normal review.

Anthropic's *Building Effective Agents* (2024) recommends for agentic AI: human review at "natural checkpoints" before irreversible actions, with review depth matched to the reversibility and blast radius of the action. This is the same principle applied at the system level.

**The NIST AI RMF** GOVERN function assigns ownership: organisations deploying AI are accountable for its outputs and must maintain human oversight sufficient to detect and correct errors. The personal "delegate, review, own" discipline is the individual-level instantiation of this organisational requirement.

**Reviewability as a design property.** AI systems and agentic workflows should be designed to make review tractable: structured output, explicit reasoning traces, action logs, and human-readable summaries of what the agent did and why. An agent that produces only a final output without a trace of its reasoning is harder to review correctly than one that externalises its chain of thought. This makes reviewability a first-class design requirement alongside correctness.

> [!tip]
> The most reliable check against rubber-stamping AI output is to write the review before reading the output. Define what a good output looks like — what it must contain, what failure modes to look for, what assumptions must be verified — before seeing the result. Then evaluate against that pre-defined standard rather than against the output's own framing.

## Pitfalls and anti-patterns

- **Rubber-stamping.** Approving output without genuine evaluation. The most common failure mode; driven by time pressure, confidence in the delegate, and absence of a defined review standard.
- **Delegation without brief.** Assigning a task without specifying success criteria. The delegate interprets scope; the principal discovers the interpretation only in review, after rework is expensive.
- **Assuming AI confidence = correctness.** Fluent, confident-sounding output is the default output mode of an LLM. Confidence does not correlate with accuracy on novel or out-of-distribution inputs.
- **Single-reviewer on high-stakes output.** One reviewer has one blind spot. For outputs with large downstream consequences, independent review by a second reviewer (or a review checklist that forces attention to specific failure modes) reduces the risk.
- **Reviewing the form, not the substance.** Checking whether the document is well-formatted or the code is syntactically correct while not checking whether the reasoning is sound or the trade-offs are appropriate is review theatre.
- **Delegating accountability.** "The vendor recommended it" or "the model suggested it" as the full justification for a decision. The principal chose to accept the recommendation — that choice requires a justification.

## See also

- [[human-in-the-loop-design]] — the system-level pattern for human oversight gates in agentic workflows
- [[accountable-human-layer]] — the broader principle of retained human accountability in AI systems
- [[trade-off-judgment]] — the judgment capacity the reviewer applies
- [[ai-evaluation-and-quality]] — defining review criteria as measurable eval standards
- [[guardrails-and-output-validation]] — automated review of AI output properties
- [[agent-governance-and-policy]] — organisational accountability structures

## Sources

- Anthropic (2024). *Building Effective Agents.* Anthropic Research Blog. https://www.anthropic.com/research/building-effective-agents
- Larson, W. (2019). *An Elegant Puzzle: Systems of Engineering Management.* Stripe Press. https://lethain.com/elegant-puzzle/
- NIST (2023). *AI Risk Management Framework (AI RMF 1.0).* NIST AI 100-1. https://nvlpubs.nist.gov/nistpubs/ai/NIST.AI.100-1.pdf
- European Parliament (2024). *EU AI Act — Regulation (EU) 2024/1689.* Articles 14, 22, 28. https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32024R1689
- Jensen, M. C. & Meckling, W. H. (1976). *Theory of the Firm: Managerial Behavior, Agency Costs and Ownership Structure.* Journal of Financial Economics, 3(4), 305–360. https://www.jstor.org/stable/3665619
