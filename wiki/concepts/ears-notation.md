---
title: EARS Notation
aliases: [EARS, Easy Approach to Requirements Syntax, EARS requirements]
type: concept
domain: emerging
status: mature
tags: [emerging, requirements, specification, ears, spec-driven-development]
updated: 2026-06-25
sources:
  - https://alistairmavin.com/ears/
  - https://kiro.dev/docs/specs/feature-specs/
  - https://www.se-trends.de/en/requirements-with-ears/
  - http://requirekit.ai/core-concepts/ears-notation/
  - https://visuresolutions.com/alm-guide/adopting-ears-notation/
  - https://sites.mdu.se/download/18.3f19ad5f18d548ea2e0187ba/1707230632933/An%20Experiment%20in%20Requirements%20Engineering%20and%20Testing%20using%20EARS%20Notation%20for%20PLC%20Systems.pdf
  - raw/2026-06-25-ssd01-02-research-report.md
  - raw/2026-06-25-ssd01-03-research-report.md
---

# EARS Notation

> [!summary]
> EARS — the Easy Approach to Requirements Syntax — is a lightweight set of five sentence templates that gently constrain natural-language requirements into an unambiguous, testable form. Created by Alistair Mavin and colleagues at Rolls-Royce for jet-engine control software, each pattern pairs a keyword (WHEN / WHILE / WHERE / IF-THEN / none) with a single `shall` clause. EARS needs no tools and almost no training, which is why it has become the default requirements notation inside [[spec-driven-development|spec-driven development]] workflows like Kiro.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

EARS is a constraint, not a language. As Mavin's canonical reference puts it, EARS is "a mechanism to gently constrain textual requirements" — it keeps requirements in plain English but forces each one into one of a few fixed shapes. It emerged at Rolls-Royce PLC from the practical problem of analyzing airworthiness regulations for jet-engine control systems, where ambiguous requirements are a safety hazard, and was formalized by Mavin and colleagues in a 2009 paper. A decade and a half later it found an unexpected second life as the requirements layer of [[spec-driven-development|AI-native development]] — nearly every major SDD tool uses EARS or a close variant.

The whole method is **five patterns**, each a template with a designated keyword and a single normative verb, `shall`. One requirement expresses exactly one `shall`.

| Pattern | Keyword | Template | Example |
|---|---|---|---|
| **Ubiquitous** | *(none — always active)* | `The <system> shall <response>.` | "The mobile phone shall have a mass of less than 150 grams." |
| **State-driven** | **WHILE** | `While <precondition>, the <system> shall <response>.` | "While there is no card in the ATM, the ATM shall display 'insert card to begin'." |
| **Event-driven** | **WHEN** | `When <trigger>, the <system> shall <response>.` | "When 'mute' is selected, the laptop shall suppress all audio output." |
| **Optional feature** | **WHERE** | `Where <feature is included>, the <system> shall <response>.` | "Where the car has a sunroof, the car shall have a sunroof control panel on the driver door." |
| **Unwanted behaviour** | **IF / THEN** | `If <trigger>, then the <system> shall <response>.` | "If an invalid credit card number is entered, then the website shall display 'please re-enter credit card details'." |

**Complex requirements** combine keywords in a fixed order (state before event):

```
While <precondition>, when <trigger>, the <system> shall <response>.
```

> "While the aircraft is on ground, when reverse thrust is commanded, the engine control system shall enable reverse thrust."

That is the entire method. Its power is in what it *excludes*: vague verbs ("support", "handle"), passive voice without an actor, compound requirements with multiple `shall`s, and conditions left implicit.

## Why it matters

**Ambiguity is the dominant defect in requirements.** Unconstrained natural language is imprecise and inconsistent; defects introduced at the requirements stage are the most expensive to fix because they propagate through design, code, and test. EARS attacks the problem at the cheapest point — the sentence — without imposing the cost and training overhead of a formal specification language.

**Each pattern maps to a trigger condition, so requirements become test cases.** The keyword tells you exactly what to set up and what to assert. `WHEN <trigger> ... shall <response>` is, almost verbatim, a test: arrange the trigger, assert the response. This is why EARS is load-bearing in [[spec-driven-development|SDD]]: Kiro's documentation adopts EARS precisely because the requirements are "unambiguous and easy to understand" and can be "directly translated into test cases" and tracked through implementation. The notation is the bridge from human intent to machine-checkable [[ai-evaluation-and-quality|acceptance criteria]].

**It is accessible.** EARS is lightweight, needs no specialized tools, requires minimal training, and — a point Mavin emphasizes — notably helps non-native English speakers by removing the freedom to phrase requirements in unboundedly many ways. This accessibility is why it scaled to organizations including Airbus, Bosch, Dyson, Honeywell, Intel, NASA, Rolls-Royce, and Siemens.

## Key concepts / building blocks

### Choosing the right pattern

The decision is mechanical, which is the point:

- Is it always true, unconditionally? → **Ubiquitous** (no keyword).
- Is it true only during a state that persists over time? → **WHILE** (state-driven).
- Is it a response to a discrete event or trigger? → **WHEN** (event-driven).
- Does it apply only when an optional feature/variant is present? → **WHERE** (optional feature).
- Is it the system's response to an error or undesired condition? → **IF/THEN** (unwanted behaviour).
- More than one of the above at once? → **Complex** (combine keywords, state before event).

### The `shall` discipline

`shall` is the single normative keyword denoting a binding requirement. One requirement = one `shall` = one testable obligation. A sentence with two `shall`s is two requirements wearing a trench coat and should be split — this keeps traceability (requirement → test → implementation) one-to-one.

### Why EARS fits AI-generated specs

In [[spec-driven-development|spec-driven]] tooling, requirements are increasingly drafted or refined by an LLM. EARS gives the model a small, closed set of legal output shapes, which both constrains hallucinated structure and makes the generated requirements immediately checkable — a human (or a linter) can verify each line is a well-formed EARS sentence. The pattern keyword also gives downstream task-generation and test-generation steps a reliable hook to parse against.

## Design decisions & trade-offs

**EARS vs. user stories.** Agile user stories ("As a … I want … so that …") capture *who and why*; EARS captures *what the system shall do and under which condition*. They are complementary: a story frames value and motivation, EARS pins the testable behavior. Many SDD specs carry both — stories for context, EARS for acceptance criteria.

**EARS vs. formal methods.** Formal specification languages (TLA+, Z, temporal logic) give mathematical verifiability but demand specialist skill and tooling. EARS deliberately stops short: it is *constrained* natural language, not formal logic. It removes most ambiguity at a fraction of the cost, accepting that it cannot prove properties the way a formal method can. For the overwhelming majority of business and embedded software, EARS is the right point on the cost/rigor curve.

**Granularity.** EARS does not by itself tell you how fine-grained a requirement should be. Too coarse and the `shall` hides multiple behaviors; too fine and the spec drowns in trivial lines. The `one shall, one requirement` rule sets a floor, but right-sizing remains a judgment call — the same [[trade-off-judgment|trade-off judgment]] good requirements work has always needed.

## State of the art

EARS is mature and stable as a notation; what changed in 2025–2026 is its adoption as the **default requirements layer of AI-native development**. Kiro (AWS) generates its `requirements.md` directly in EARS and runs an analysis pass for "inconsistencies, ambiguities, conflicting constraints, and gaps" before design — in Kiro's case backed by SMT (satisfiability-modulo-theories) solvers that can detect logically contradictory requirements before any code is written, which is only tractable because EARS gives the requirements a parseable structure. Tooling such as RequireKit and Visure Solutions now offer EARS authoring and linting, and EARS-aware patterns are appearing in [[spec-driven-development-tools|Spec Kit and OpenSpec]] specs. Empirical validation continues in safety-critical domains — e.g., a Mälardalen University study experimentally applied EARS to requirements engineering and testing for PLC control systems, reinforcing the requirement-to-test mapping that makes the notation attractive for SDD.

> [!tip]
> When reviewing an EARS spec, scan for the keyword first. A requirement with no WHEN/WHILE/WHERE/IF that is *not* genuinely universal is a hidden conditional — the author dropped the trigger. And any sentence with two `shall`s should be split before it reaches implementation.

## Pitfalls & anti-patterns

- **Two `shall`s in one requirement.** Compound requirements break the one-to-one traceability to tests. Split them.
- **Ubiquitous-by-omission.** Writing a requirement with no keyword because the condition was forgotten, not because it is truly universal. The missing trigger resurfaces as a defect.
- **Vague responses.** `shall handle errors gracefully` is EARS-shaped but untestable. The `<response>` must be observable and specific.
- **Forcing prose into EARS that isn't a requirement.** Background, rationale, and design notes are not requirements; cramming them into `shall` sentences pollutes the spec. Keep them separate.
- **Treating EARS as sufficient for correctness.** EARS removes *ambiguity*, not *wrongness* — a perfectly-formed EARS requirement can still specify the wrong behavior. It is a clarity tool, not a validation of intent.

## See also

- [[spec-driven-development]] — the methodology that made EARS its default requirements layer
- [[spec-driven-development-tools]] — Kiro, Spec Kit, OpenSpec and how they use EARS
- [[ai-evaluation-and-quality]] — turning EARS requirements into acceptance tests
- [[trade-off-judgment]] — right-sizing requirement granularity
- [[guardrails-and-output-validation]] — checkable constraints, the runtime cousin of testable requirements

## Sources

- Mavin, A. et al. *EARS — Easy Approach to Requirements Syntax (official guide).* https://alistairmavin.com/ears/
- Kiro (2026). *Feature Specs.* https://kiro.dev/docs/specs/feature-specs/
- Systems Engineering Trends. *Writing better requirements with EARS.* https://www.se-trends.de/en/requirements-with-ears/
- RequireKit. *EARS Notation Patterns.* http://requirekit.ai/core-concepts/ears-notation/
- Visure Solutions. *Adopting EARS Notation for Requirements Specification.* https://visuresolutions.com/alm-guide/adopting-ears-notation/
- *An Experiment in Requirements Engineering and Testing using EARS Notation for PLC Systems.* Mälardalen University. https://sites.mdu.se/
