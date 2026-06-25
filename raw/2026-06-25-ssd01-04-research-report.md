# Spec-Driven Development in 2025–2026: The State of the Practice

## TL;DR
- **Spec-Driven Development (SDD) is the leading structured alternative to "vibe coding" that emerged in 2025**: instead of prompting an AI agent ad hoc, you write a structured, versioned specification first, and the agent generates, tests, and validates code against it — making the spec, not the code or the prompt, the primary "source of truth."
- **The tooling exploded in under a year**: GitHub's open-source Spec Kit (Sept 2025; 111K stars and 9.8K forks as of June 11, 2026, up from 71K in February), AWS's Kiro IDE (preview July 2025, GA Nov 17 2025; 250,000+ developers in its first three months), Tessl ($125M-funded, spec-as-source), OpenSpec (lightweight, brownfield-first), and BMAD-METHOD (49,603 stars as of June 24, 2026) now all implement variants of a Specify → Plan → Tasks → Implement workflow.
- **It is genuinely contested, not settled**: Thoughtworks rates SDD "Assess" (not "Adopt"), critics call it "waterfall in Markdown," and reputable practitioner reviews report being "around ten times faster" without it on small tasks. The consensus is that SDD pays off for complex, multi-team, production, or brownfield work above a complexity threshold — and is overkill for small fixes and exploration.

## Key Findings

1. **SDD is a 2025-vintage term with deep roots.** The principle (write the spec, then build) goes back to 1960s NASA test-first practices and formal academic work (Ostroff, Makalsky & Paige, XP 2004). What changed in 2025 is that LLMs collapsed the cost of writing and maintaining specs, making the discipline viable at modern velocity. No single person coined the modern term; it crystallized across 2025.

2. **The intellectual spark is widely credited to Sean Grove (OpenAI), "The New Code," at the AI Engineer World's Fair 2025.** His thesis: prompts are transient (developers keep generated code and throw the prompt away — "like shredding the source and version-controlling the binary"), so the durable, versioned specification should be the real artifact. His exhibit was OpenAI's own Model Spec. His provocation: "the person who communicates most effectively is the most valuable programmer."

3. **A clean taxonomy from Thoughtworks' Birgitta Böckeler (Oct 15, 2025, on martinfowler.com) is now the field's working vocabulary**: spec-first (write spec, build, spec may not outlive the feature), spec-anchored (spec is maintained alongside code), and spec-as-source (humans only edit the spec; code is generated output).

4. **The big tooling players cluster at different rungs**: Spec Kit and Kiro are mostly spec-first/spec-anchored; Tessl explicitly aspires to spec-as-source.

5. **SDD is positioned as the cure for the "vibe coding hangover."** Vibe coding (coined by Andrej Karpathy, Feb 2, 2025) democratized code generation but produced unmaintainable, insecure output at scale. SDD reintroduces engineering discipline while keeping the speed.

6. **Adoption is real but the evidence base is thin and contested.** First-party and case-study numbers are encouraging but mostly anecdotal or vendor-aligned; controlled efficacy data specific to SDD barely exists, and several reputable reviews are openly skeptical.

## Details

### Definition and core concepts

Spec-Driven Development is, in Böckeler's framing, "writing a 'spec' before writing code with AI ('documentation first'). The spec becomes the source of truth for the human and the AI." GitHub frames it as: "In this new world, maintaining software means evolving specifications. […] The lingua franca of development moves to a higher level, and code is the last-mile approach." Tessl's definition is the most radical: "A development approach where specs — not code — are the primary artifact. Specs describe intent in structured, testable language, and agents generate code to match them."

A spec is generally understood as a structured, behavior-oriented artifact (or set of artifacts) written in natural language (often Markdown) that expresses software functionality and guides AI coding agents. It is distinct from the broader "memory bank" of context files (AGENTS.md, CLAUDE.md, rules files, product/architecture overviews) that apply across all coding sessions; specs apply to the tasks that create or change specific functionality.

**How SDD differs from adjacent approaches:**
- **vs. TDD/BDD**: In TDD, tests serve as the behavioral spec; SDD extends this upstream — the natural-language spec drives tests, code, and docs. BDD's Given/When/Then acceptance criteria are frequently embedded inside SDD specs (Kiro uses exactly this format).
- **vs. documentation-driven development**: SDD specs are intended to be living/executable inputs to agents, not after-the-fact docs.
- **vs. model-driven development (MDD)**: Böckeler notes the strong parallel — MDD used formal models (UML/DSLs) plus hand-built code generators, and "never took off for business applications" because of overhead. LLMs remove the requirement for a parseable spec language and bespoke generators, giving the old idea "new hope."
- **vs. waterfall**: The most persistent criticism. The key defenses: SDD specs are lean and iterative not comprehensive and frozen; the implement loop is hours not quarters; and the spec's consumer is an agent that genuinely executes it.

The deepest definitional debate is whether spec or code is the ultimate maintained artifact. The "radical wing" (Tessl, Grove) argues code becomes a disposable byproduct; pragmatists (including Thoughtworks' Birgitta Böckeler and Martin Fowler's circle) argue executable code remains the source of truth and specs merely drive generation, as in TDD.

### Current tooling and frameworks

**GitHub Spec Kit** — Open-sourced Sept 2, 2025 (launch post by Den Delimarsky, Principal Product Manager at GitHub; born from John Lam's research). It's an MIT-licensed CLI (`specify`) plus templates and slash commands. The core workflow: `/speckit.constitution` → `/speckit.specify` → `/speckit.plan` → `/speckit.tasks` → `/speckit.implement`, with `/speckit.analyze` for cross-artifact consistency and a "constitution" file of non-negotiable project principles. Each phase produces a Markdown artifact consumed by the next, with human review gates. By mid-2026 it had 111K GitHub stars and 9.8K forks (June 11, 2026, up from 71K in February), 30+ agent integrations (Copilot, Claude Code, Cursor, Gemini CLI, Codex, Windsurf, Zed, Kiro), and 55+ releases since late February. v0.10 (v0.10.2, June 2026) replaced legacy `--ai` flags with an `--integration` system plus extensions, presets, and an agent-skills install mode. GitHub explicitly frames it as "an experiment designed to test how well the methodologies behind Spec-Driven Development actually work," not a finished product. Delimarsky's positioning quote: "We treat coding agents like search engines when we should be treating them more like literal-minded pair programmers. They excel at pattern recognition but still need unambiguous instructions."

**AWS Kiro** — An agentic IDE (fork of Code OSS / VS Code) launched in public preview July 14–15, 2025 at the AWS NYC Summit, reaching general availability Nov 17, 2025. Workflow: Requirements → Design → Tasks, materialized as three Markdown files (`requirements.md` with EARS-notation user stories, `design.md`, `tasks.md`), plus "steering" files (product.md, tech.md, structure.md) and event-triggered "agent hooks." Kiro uses Claude models (Sonnet 3.7/4.0 at launch; later Opus). It adds property-based testing (to verify code against spec invariants, not just examples), checkpointing, a CLI, and (Dec 2025) an autonomous "frontier agent." Pricing: free tier (50 credits), Pro $20/mo, Pro+ $40/mo, Power $200/mo. Notably, AWS positions Kiro as the successor to Amazon Q Developer. More than 250,000 developers used Kiro in its first three months, and Amazon stated it "handled more than 300 million requests and processed trillions of tokens" during preview (GeekWire, Nov 17, 2025). Kiro's early pricing rollout was rocky — caps, a waitlist, and a pricing-bug episode that The Register called "a wallet-wrecking tragedy."

**Tessl** — Founded by Guy Podjarny (ex-Snyk founder, ex-Akamai CTO). Raised $125M ($25M seed + $100M Series A led by Index Ventures) at a ~$750M valuation, announced Nov 14, 2024 — notably before shipping a product. Tessl is the most ambitious on the spectrum, explicitly pursuing spec-as-source: specs are `.spec.md` Markdown files with YAML frontmatter, and generated code can carry `// GENERATED FROM SPEC - DO NOT EDIT`. Products: the Spec Registry (open beta) and Tessl Framework (beta), plus a "tiles" package-manager concept with skills/docs/rules and built-in evals. Podjarny's thesis: software moves from "code-centric" to "spec-centric." Tessl also runs the AI Native Dev podcast/community (Simon Maple is Founding Developer Advocate).

**OpenSpec** (Fission-AI, by @0xTab) — A lightweight, open-source, tool-agnostic SDD framework (works with 20+ assistants via slash commands; no API keys/MCP required). Its differentiators: brownfield-first, "delta specs" (ADDED/MODIFIED/REMOVED markers describing changes rather than restating the whole spec), and a single "source-of-truth" spec. Workflow artifacts: proposal.md, specs/, design.md, tasks.md. It explicitly positions as lighter than Spec Kit ("no Python, 5-minute setup") and less locked-in than Kiro. Thoughtworks placed OpenSpec on its Technology Radar.

**BMAD-METHOD** (Breakthrough Method for Agile AI-Driven Development) — An open-source (MIT) multi-agent framework, 49,603 GitHub stars and 5,733 forks as of June 24, 2026 (up from 37K in February), now at v6.8.0 (released May 25, 2026). Rather than a linear spec workflow, it uses specialized agent personas (Analyst, PM, Architect, Developer, QA, etc.) that hand off artifacts (project brief → PRD → architecture → sharded "story files" with focused context) mirroring an agile team. Installs via `npx bmad-method install`; works with Claude Code, Cursor, Copilot.

**Anthropic / Claude Code, Cursor, Codex, Windsurf** — These are the agent "harnesses" SDD tools target rather than SDD frameworks themselves. The adjacent standard is context/agent files: CLAUDE.md (Anthropic) and the cross-tool AGENTS.md standard (originated by Sourcegraph/OpenAI/Google/Cursor/Factory in 2025, donated to the Linux Foundation's Agentic AI Foundation in Dec 2025 alongside MCP). Anthropic's Agent Skills (Oct 2025, open standard Dec 18 2025) — composable folders of instructions/scripts loaded on demand — are increasingly the portable substrate, and Spec Kit's v0.10 "skills mode" aligns with this. Thoughtworks' internal IT also developed "Structured Prompt-Driven Development" (SPDD), treating prompts as versioned first-class artifacts.

**Other emerging tools**: Augment Code's Cosmos (organizational-scale orchestration, launched May 2026), Google's Antigravity (late-2025 agent-first IDE), and numerous smaller projects. Tessl's AI Native Dev landscape tracks 450+ tools overall.

### The AI coding connection: specs as context engineering

The core technical argument: LLM agents are non-deterministic and "literal-minded," and the bottleneck is no longer code generation but precise intent transfer. Specs bound the agent's context, supply acceptance criteria and constraints, and prevent the "intent-to-code chasm." This is squarely a context-engineering problem: large context windows (200K+ tokens) make comprehensive specs feasible, but bigger windows don't guarantee the model attends to everything (the "lost in the middle" problem). Practitioner guidance therefore stresses lean, layered, progressively-disclosed context — there's a practical upper bound (cited as roughly 150–200 standing instructions, a rule of thumb) before reliability degrades, and ETH research reportedly found auto-generated context files can *reduce* task success while raising cost ~20%.

The "specs as the new source code / new source of truth" framing (Grove, GitHub, Tessl) is the philosophical center. Grove's analogy: just as you keep source and discard the compiled binary, you should keep the spec and treat the code as a regenerable build artifact. The counter-position (well represented on Hacker News): "If your application crashes at 3am, you'll still be debugging the actual code, not the Markdown document."

### Key thought leaders and companies

- **Sean Grove (OpenAI)** — "The New Code" talk; "the person who communicates most effectively is the most valuable programmer."
- **Birgitta Böckeler (Thoughtworks, Distinguished Engineer)** — the definitive taxonomy and skeptical-but-curious analysis on martinfowler.com.
- **Guy Podjarny ("Guypo," Tessl)** — most aggressive spec-as-source vision; AI Native Dev movement.
- **Den Delimarsky (GitHub)** — public face of Spec Kit.
- **Andrej Karpathy** — coined "vibe coding" (the foil), and by 2026 reportedly described the shift to "agentic engineering — orchestrating agents against detailed specifications with human oversight."
- **Martin Fowler / Thoughtworks** — pragmatist counterweight; emphasis on feedback loops over up-front specs.
- **Companies**: GitHub/Microsoft, AWS/Amazon, OpenAI, Tessl, Fission-AI, Augment Code, Red Hat, JetBrains (DeepLearning.AI course "Spec-Driven Development with Coding Agents").

### Methodologies and workflows

The canonical flow is remarkably consistent across tools: **Constitution/Steering (durable principles) → Specify (the what/why) → Plan (the how, tech stack, architecture) → Tasks (atomic, reviewable, dependency-ordered units, often [P]-marked for parallelism) → Implement (agent executes; human verifies at gates)**. Best practices that have emerged:
- Start with one well-understood feature, not the whole app.
- Include tests in specs from day one ("tests are intent too").
- Version specs in Git; treat specs as code.
- Use EARS (Easy Approach to Requirements Syntax — "WHEN [trigger] the system SHALL [response]") for unambiguous, testable acceptance criteria; nearly every major tool uses EARS or a near-clone.
- Use a separate agent to verify the implementer's work (an underused pattern).
- Keep the spec lean — over-specification (specs that become pseudo-code) defeats the purpose.

A typical spec contains: a goal statement (outcome, not implementation), functional requirements (declarative, input/output/conditions), non-functional requirements, integration contracts (schemas, error/retry modes — agents fabricate API shapes otherwise), and edge cases/failure modes.

### Adoption trends and industry reception

**The enabling context**: 90% of developers use AI tools (GitHub Octoverse 2025). The Stack Overflow 2025 Developer Survey (n=49,000+ across 177 countries) found 84% use or plan to use AI (up from 76% in 2024), but trust is falling — only 29% of developers trust AI outputs to be accurate in 2026 (down from 40% in 2024), with 46% actively distrusting accuracy, and 66% citing "AI solutions that are almost right, but not quite" as their top frustration. Y Combinator reported 25% of its Winter 2025 batch had codebases that were ~95% AI-generated; as YC managing partner Jared Friedman put it, "A year ago, they would have built their product from scratch — but now 95% of it is built by an AI" (TechCrunch, March 6, 2025). This "almost right" failure mode is precisely what SDD targets. JetBrains' January 2026 AI Pulse survey (10,000+ professional developers, localized into 8 languages) found 90% of developers regularly used at least one AI tool at work, with 74% having adopted a specialized AI coding tool rather than a general LLM chat — but only a small minority use AI across the entire SDLC, leaving huge headroom that structured workflows aim to fill.

**Enterprise traction**: Delta Air Lines (presented at AWS re:Invent 2025, session DVT209) reported using Kiro's spec-driven approach to turn backlog grooming into design sessions; its presenter stated "94% of the pilot participants reported a satisfaction score of 4 or greater out of 5," alongside "1,948% growth in Q Developer adoption within six months." Rackspace reported large modernization gains using Kiro — its CTO Brian Lichtle cited "85% efficiency gains across 800 developers, saving over 8 FTE years in four months" (re:Invent 2025 / GeekWire). AWS itself standardized internally on Kiro. Regulatory pressure (EU AI Act high-risk obligations from Aug 2, 2026) and the fact that only ~1 in 5 companies has mature AI-agent governance (Deloitte State of AI 2026) are pushing the spec-anchored, audit-trail end of the spectrum.

**Skeptical takes (substantial and credible)**:
- Thoughtworks Technology Radar (Vol 33, 2025) places SDD in **"Assess," not "Adopt,"** warning of an antipattern: "a bias toward heavy up-front specification and big-bang releases."
- Scott Logic CTO Colin Eberhardt's hands-on review "Putting Spec Kit Through Its Paces: Radical Idea or Reinvented Waterfall?" (Nov 26, 2025) concluded: "The simple fact is I am a lot more productive without SDD, around ten times faster." He watched the constitution agent run for 4 minutes to produce a 189-line Markdown file, and summary coverage noted one plan phase generating over 2,000 lines of Markdown (including a 406-line research doc he found duplicative): "Ultimately a lot of time spent reviewing markdown or waiting for the agent to churn out more markdown. I didn't see any qualitative benefit to justify the overhead."
- Marmelab's François Zaninotto ("Spec-Driven Development: The Waterfall Strikes Back," Nov 12, 2025) documented a Spec Kit example where a developer "wanted to display the current date on a time-tracking app, resulting in 8 files and 1,300 lines of text," and listed failure modes including "Markdown Madness," "Double Code Review" (review time doubles), and "for large existing codebases, SDD is mostly unusable."
- Hacker News threads titled "The Waterfall Strikes Back" and "Spec driven development doesn't work if you're too confused to write the spec."
- A common refrain: the agent often *still* ignores the spec, so review never goes away.

### Historical context

Roots span: 1950s (McCracken's checkout-before-coding), 1960s NASA test-first on Mercury, formal methods (1970s), contract programming, model-driven engineering (2000s), and contract-style specs that have long been spec-first (OpenAPI, Protobuf, AsyncAPI, JSON Schema). The XP 2004 "Agile Specification-Driven Development" paper (Ostroff et al.) is a direct academic ancestor. The resurgence is driven by LLMs collapsing spec-authoring cost and by the need to govern non-deterministic agents.

### Future outlook

Where the field is heading (with appropriate caution — these are projections, not facts):
- **Toward spec-anchored as the enterprise default**, with governance, audit trails, and "Constitutional SDD" (embedding security constraints with CWE mappings) for regulated domains.
- **Spec evals** — metrics for spec completeness/testability/maintainability — are widely predicted but largely don't yet exist.
- **Fleet-scale governance** of specs (versions, owners, gates, traceability of which spec produced which deployed behavior) is the named open problem.
- **Open challenges**: LLM non-determinism (same spec → different code); spec rot/drift; over-specification; the unresolved spec-vs-code source-of-truth question; and whether the overhead-to-payoff ratio improves enough to convert skeptics — or whether the market settles on lighter-weight conventions like AGENTS.md for everyday work.

## Recommendations

**For individual developers / small teams (start here):**
1. Adopt **spec-first** on a single, well-scoped feature using a lightweight tool — OpenSpec (no Python, brownfield-friendly) or Spec Kit if you're already in Copilot/Claude Code. Don't spec your whole app.
2. Write a one-page "constitution"/AGENTS.md codifying your stack and conventions (a ~1-hour agent-interview exercise). Keep it lean (<300 lines).
3. **Threshold rule**: if the change is a small fix or exploratory, skip the ceremony and prompt iteratively — multiple credible reviews find plain prompting faster for small tasks.

**For engineering organizations:**
4. Use Böckeler's ladder deliberately: match the rung to the risk. Throwaway internal tool → spec-first; revenue-bearing multi-team API → spec-anchored (keep specs in CI, wire up contract tests); regulated/safety-critical → consider spec-as-source where deterministic generation is already proven (OpenAPI stubs, Simulink/embedded).
5. For brownfield: don't retro-spec the whole system. Reconstruct existing behavior first, then spec only the area of change (specs should be "most granular near the area of change").
6. Pick tooling by need: AWS shop/compliance → Kiro; tool-agnostic/no lock-in → OpenSpec or Spec Kit; multi-agent agile simulation → BMAD; spec-as-source bet → Tessl.

**Benchmarks/thresholds that should change your approach:**
- If review time *doubles* (reviewing both spec and code) without fewer defects, you're over-specifying — pull back.
- If the agent repeatedly ignores spec constraints, invest in a separate verifier agent and property-based tests rather than longer specs.
- If specs drift from code, you need enforcement (failing CI tests on divergence) before claiming spec-anchored benefits.

## Caveats
- **The efficacy evidence is weak.** The most-cited positive number — a "75% reduction in cycle time for API changes" — comes from an anonymized financial-services case study in an arXiv practitioner guide ("Spec-Driven Development: From Code to Contract in the Age of AI Coding Assistants," arXiv:2602.00180), not a controlled study, and closely tracks vendor marketing for contract-testing tooling (Specmatic). A separate "Constitutional SDD" arXiv paper reports a 73% reduction in security defects, but only via secondary coverage. Treat first-party and case-study metrics (including Delta's and Rackspace's) as illustrative, not proof.
- **Counter-evidence exists and is from named, reputable sources**: Scott Logic's reviewer reported being "around ten times faster" without SDD on small tasks, and Marmelab documented specs ballooning to 1,300 lines / 8 files for a trivial date-display feature.
- **The term is still fluid.** "Spec" ranges from a more elaborate prompt to 50 Markdown files; tools labeled "SDD" implement materially different things. Treat any single definition with caution.
- **Fast-moving facts**: star counts, version numbers, model names, and pricing cited here are mid-2026 snapshots and change rapidly (Spec Kit gained ~40K stars between February and June 2026).
- Some sourced figures (developer-sentiment percentages, vulnerability rates, productivity studies) describe AI-assisted coding broadly, not SDD specifically; they motivate SDD but don't validate it.