---
title: Vibe Coding Governance
aliases: [vibe coding, AI-assisted development governance, AI code governance]
type: concept
domain: emerging
status: mature
tags: [emerging, ai, governance, development, security, supply-chain, code-review]
updated: 2026-06-21
sources:
  - https://karpathy.ai/vibe-coding.html
  - https://owasp.org/www-project-top-10-for-large-language-model-applications/
  - https://github.com/github/copilot-trust-center
  - https://arxiv.org/abs/2308.09687
  - https://semgrep.dev/docs/
  - https://www.anthropic.com/engineering/claude-code-best-practices
---

# Vibe Coding Governance

> [!summary]
> Vibe coding governance is the set of platform-level controls, review gates, and quality enforcement mechanisms that prevent AI-assisted code generation from outrunning security, compliance, and quality standards. Velocity is the point of AI coding tools; governance ensures that velocity does not convert into accumulated technical debt, security vulnerabilities, or undiscoverable liability.

**Domain:** [[tier-3-watch|Emerging & Adjacent]]

## What it is

"Vibe coding" — Andrej Karpathy's term (February 2025) for building software by steering AI generation through natural-language intent rather than writing code line by line — describes a shift in how software is produced, not just how it is assisted. In vibe coding mode, a developer accepts AI output without reading every line, using tests and observed behaviour as the primary feedback signal. Karpathy described it explicitly: "I just see stuff, say stuff, run stuff, and it mostly works."

This mode of development is fast. It also transfers quality risk from the generation step (where human attention was previously applied) to the review and test step (which is now the primary quality gate). Without deliberate governance, the risk accumulates: AI-generated code contains security vulnerabilities at measurable rates, APIs are occasionally hallucinated, dependencies suggested may be outdated or malicious, and the code may be technically correct but architecturally inconsistent with the surrounding system.

Governance does not mean slowing down. It means ensuring that the velocity advantage of AI generation is not offset by the velocity cost of security incidents, compliance failures, and architectural drift that non-governed AI output tends to produce.

## Why it matters

**Security vulnerability rate in AI-generated code.** Research on GitHub Copilot output (Pearce et al., arXiv:2308.09687) found that 40 % of Copilot-generated code completions in security-sensitive contexts contained vulnerabilities — predominantly OWASP Top 10 categories: injection (SQL, command), insecure deserialization, hardcoded credentials, missing access controls, and path traversal. The model generates these patterns because it is trained on public code that contains them at scale.

**The velocity trap.** A team adopting AI coding tools typically sees a 30–50 % throughput increase in the first month. Without governance, the code review process is informally compressed — more code arrives per review, reviewers have less time per line, and vulnerabilities pass. The vulnerability is not in the AI output; it is in the review process that was not scaled to match the generation throughput.

**Supply chain risk.** AI models suggest package names from training data. Packages may be deprecated, have known CVEs, or — in the most dangerous case — be dependency confusion targets (a real package name on a private registry shadowed by a malicious public package). An AI that suggests `npm install leftpad` is not checking CVE databases or npm audit output; the developer must.

**Architectural drift.** AI generates code that works in isolation but may not fit the architectural patterns, naming conventions, or data model decisions of the surrounding system. Without a mechanism for encoding architectural constraints into the generation context (CLAUDE.md, Copilot Instructions, Cursor rules), AI output generates entropy in the codebase.

## Key concepts

### The generation → review → gate pipeline

Effective vibe coding governance treats AI-generated code identically to human-written code in the review and gate pipeline, while adding AI-specific controls at the generation stage:

```
[Generation]                      [Review & Gate]
  ↓                                    ↓
AI tool (Copilot/Claude Code/Cursor) → PR → Human review
  + generation-time controls            + SAST / secret scan
  (CLAUDE.md, system prompt,            + dependency audit
   .cursorrules, Copilot instructions)  + policy gate (Checkov/OPA)
                                        + test coverage gate
                                        → Merge
```

**Generation-time controls** encode the project's conventions, security rules, and architectural constraints into the AI's context so generated code conforms before the reviewer sees it:
- `CLAUDE.md` (Claude Code): schema, conventions, workflow rules embedded in every session.
- `.cursorrules` (Cursor): project-level instructions applied to all Cursor completions.
- GitHub Copilot Instructions (`.github/copilot-instructions.md`): repository-level prompt additions.
- System prompts in API integrations: security rules, coding standards, output format constraints.

These controls reduce (not eliminate) the review burden by steering generation toward compliant output.

### Security gate tooling

Every AI-generated artefact should pass the same static analysis pipeline as human-written code. For vibe coding contexts, these gates are more important, not less, because manual line-by-line review is explicitly deprioritised:

| Control | Tool | What it catches |
|---|---|---|
| SAST | Semgrep, SonarQube, CodeQL | Injection, insecure patterns, OWASP Top 10 |
| Secret scanning | TruffleHog, Gitleaks, GitHub secret scanning | API keys, credentials, tokens in code |
| Dependency audit | `npm audit`, Dependabot, Snyk, OWASP Dependency-Check | Known CVEs in dependencies |
| IaC security | Checkov, tfsec, Terrascan | Misconfigured infrastructure (open security groups, unencrypted storage) |
| Licence compliance | FOSSA, licensee | Incompatible open-source licences |

Pre-commit hooks (using `pre-commit` framework or Husky) apply secret scanning and basic SAST before code is ever pushed. CI gates apply the full pipeline on every PR. Pull requests with SAST findings that are not reviewed and signed off should be blocked from merging.

### Test coverage as a quality gate

In vibe coding, tests are the primary correctness signal replacing line-by-line reading. This elevates test coverage from a nice-to-have to a governance requirement:

- **Same coverage standard for AI-generated as human-written.** A function written by AI that is not covered by tests has no quality signal.
- **AI-generated tests need human review.** AI generates tests that pass for the code it generated — which may be testing incorrect behaviour. Human review should verify that tests assert the intended behaviour, not just the implemented behaviour.
- **Property-based and adversarial testing** catch classes of error that example-based tests miss. For security-sensitive AI-generated functions, fuzzing or property-based testing (Hypothesis, fast-check) is a proportionate additional gate.

### Provenance and auditability

As AI code generation becomes the default mode, attributing code to its origin matters for:
- **Licence compliance:** GitHub Copilot's "matching public code" filter blocks suggestions that match open-source code above a similarity threshold. When it is disabled, generated code may reproduce GPL-licensed snippets.
- **Audit trail:** regulated environments (financial services, healthcare software) may require that changes can be attributed to a responsible human engineer. PR descriptions should note "generated with [tool]" where significant AI generation occurred.
- **Incident response:** when a vulnerability is discovered in AI-generated code, knowing it was AI-generated helps scope the review — similar patterns may appear elsewhere in the codebase from the same generation session.

### Architectural governance via context

The deepest form of vibe coding governance is encoding architectural intent into the generation context so the AI produces conformant code without requiring the reviewer to catch every deviation:

- **CLAUDE.md / cursor rules:** document the data model, naming conventions, error handling patterns, logging standards, and test patterns the project uses. AI tools with long-context access will apply these consistently.
- **Code examples in context:** providing canonical examples of how the project handles authentication, database access, or external API calls steers generation toward the established pattern.
- **Forbidden patterns:** explicitly naming anti-patterns ("never use `os.system()` for shell commands, use `subprocess.run()`") prevents the AI from generating the flagged pattern even when it is technically functional.

### Organisational maturity stages

| Stage | Description | Key gap |
|---|---|---|
| Ad hoc | Individual developers using AI tools without policy | No visibility; no controls; unknown risk accumulation |
| Controlled | Approved tool list; standard review process applies | No AI-specific security gates; review process not scaled to AI throughput |
| Managed | AI-specific SAST gates; test coverage requirements; provenance tracking; metrics on AI-generated defect rate | No generation-time architectural controls |
| Optimised | CLAUDE.md / cursor rules encode conventions; generation-time controls reduce review burden; AI-generated code quality at or above baseline | Ongoing calibration as tools evolve |

Most engineering organisations in mid-2026 are between Controlled and Managed. The gap between Controlled and Managed — adding the AI-specific security gates — is one sprint of platform engineering work.

## Design decisions and trade-offs

**Approve-all vs. block-on-finding SAST.** Blocking PRs on every SAST finding produces a backlog of dismissed findings that trains reviewers to dismiss everything. A better model: block on high-severity findings (injection, credential exposure); warn on medium; report low. The threshold should be calibrated against the project's actual false-positive rate.

**Generation-time filtering vs. review-time correction.** Generation-time controls (CLAUDE.md, Copilot Instructions) prevent problems at the source; review-time gates (SAST, code review) catch what slips through. Both are necessary; generation-time controls are cheaper per finding because they prevent the PR from being opened in the first place.

**AI-generated tests accepted vs. required to be human-written.** AI-generated tests are fast and cover the happy path well; they tend to undertest error paths and adversarial inputs. A balanced policy: accept AI-generated tests for routine unit tests; require human-authored tests for security-sensitive and error-handling code paths.

**Copilot/Cursor vs. agentic coding tools.** Autocomplete tools (Copilot, Cursor) generate code in response to human prompts and accept or reject each suggestion. Agentic tools (Claude Code, Codex) plan and execute multi-step code changes autonomously, potentially affecting many files in a single operation. Governance for agentic tools is higher-stakes: the blast radius of a bad generation step is larger, and the need for [[human-in-the-loop-design|HITL gates]] before applying changes to production-affecting code is correspondingly higher.

## State of the art

**GitHub Copilot Enterprise** (2024) added repository-level instructions (`.github/copilot-instructions.md`), code review in pull requests (AI-generated review comments), and workspace-level context from the full codebase. The governance control surface expanded significantly.

**Claude Code** (Anthropic, 2025–2026) with `CLAUDE.md` conventions, hooks, and permission controls represents the current frontier of agentic coding governance: the schema embedded in `CLAUDE.md` steers every session, hooks enforce pre/post-tool policies, and permission prompts gate high-risk actions. This page's own project (the sola-technical-skills knowledge base) uses this pattern.

**Semgrep** has become the de-facto SAST standard for modern engineering organisations: language-agnostic, pattern-based rules, low false-positive rate, and easy CI integration. The Semgrep Registry includes an `r/ai.generated` ruleset specifically targeting patterns common in AI-generated code.

**Research trajectory (2025–2026):** several studies have found that the AI-generated code vulnerability rate decreases significantly when the generation context includes security examples and explicit constraints. This is the empirical basis for investing in generation-time controls (CLAUDE.md, cursor rules) rather than relying solely on review-time gates.

> [!tip]
> The minimum viable vibe coding governance stack: pre-commit secret scanning (TruffleHog), CI SAST blocking on high severity (Semgrep), dependency audit on every PR (Dependabot), and a CLAUDE.md / cursor rules file that encodes the project's coding conventions. This four-control stack catches the most dangerous AI-generated vulnerabilities with minimal friction.

## Pitfalls and anti-patterns

- **"AI checked the code" as a review substitute.** AI tools can review code for style and obvious errors; they cannot reliably identify their own security blind spots. Human review of AI output for security implications is not optional.
- **Treating AI-generated code as lower-risk because it "looks clean."** AI-generated code is syntactically clean and often stylistically polished. This increases the risk of reviewers accepting it without adequate scrutiny. Polish is independent of correctness.
- **No SAST because "we use AI."** Some teams decommission SAST infrastructure when they adopt AI coding tools, reasoning that AI produces higher-quality code. The opposite should apply: AI generation warrants stronger automated gates, not weaker ones.
- **Accepting AI-suggested dependencies without audit.** `npm install` a package the AI suggested without checking the package's CVE status, download count, last publish date, and maintainer reputation is a supply-chain risk.
- **Generation-time controls that are never updated.** A CLAUDE.md or cursor rules file that describes the initial project conventions becomes stale as the project evolves. It should be version-controlled and reviewed alongside major architectural changes.
- **Agentic tools with no HITL gate.** An autonomous coding agent with write access to production configuration files, secrets management, or infrastructure code, and no human checkpoint before applying changes, is an incident waiting to happen. See [[human-in-the-loop-design]].

## See also

- [[ai-generated-iac-reviewer]] — AI-specific review for infrastructure-as-code artefacts
- [[software-supply-chain-security]] — dependency risk, SBOM, and SLSA for AI-generated dependencies
- [[policy-as-code]] — Checkov/OPA gates in the CI pipeline
- [[delegate-review-own]] — the individual-level discipline for AI-assisted work
- [[human-in-the-loop-design]] — HITL gates for agentic coding tools
- [[agent-governance-and-policy]] — governance for agentic AI systems including coding agents
- [[guardrails-and-output-validation]] — output validation patterns applicable to AI-generated code pipelines

## Sources

- Karpathy, A. (2025). *Vibe Coding.* https://karpathy.ai/vibe-coding.html
- OWASP (2025). *OWASP Top 10 for LLM Applications.* https://owasp.org/www-project-top-10-for-large-language-model-applications/
- GitHub (2024). *GitHub Copilot Trust Center.* https://github.com/github/copilot-trust-center
- Pearce, H. et al. (2023). *Examining Zero-Shot Vulnerability Repair with Large Language Models.* arXiv:2308.09687. https://arxiv.org/abs/2308.09687
- Semgrep (2025). *Semgrep Documentation.* https://semgrep.dev/docs/
- Anthropic (2025). *Claude Code Best Practices.* https://www.anthropic.com/engineering/claude-code-best-practices
