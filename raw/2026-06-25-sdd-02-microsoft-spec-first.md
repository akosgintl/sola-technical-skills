---
title: "Spec-Driven Development: A Spec-First Approach to AI-Native Engineering"
aliases: [Microsoft SDD, spec-first AI-native]
type: source
domain: emerging
status: seed
tags: [source, emerging, spec-driven-development, ai-native, microsoft]
updated: 2026-06-25
source_url: https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering
source_type: article
ingested: 2026-06-25
feeds: [spec-driven-development]
---

# Spec-Driven Development: A Spec-First Approach to AI-Native Engineering (Microsoft)

> [!info] Source metadata
> **Org:** Microsoft Developer Blog · **URL:** https://developer.microsoft.com/blog/spec-driven-development-ai-native-engineering

## Key takeaways

- SDD is positioned as a counter to **"prompt-first workflows"**: "align first and let AI accelerate execution from a clear spec" rather than prompt the AI and reconcile later.
- **Translation loss** is the core problem: intent degrades at every handoff (stakeholder → requirements → implementation). "AI can accelerate those steps, but it cannot correct ambiguity that was never resolved." The spec is the durable artifact that preserves intent.
- **"Spec quality = output quality."** Garbage spec in, garbage code out — only faster.
- Contrast with vibe coding is explicit: prompt-first produces "fast output without a durable source of truth" → architectural drift and rework.
- Operationalized via the seven-step **GitHub Spec Kit** lifecycle: Constitution → Specify → Clarify → Plan → Tasks → Implement → Validate.

## Notable claims (with location)

- Recommendations: start with a small pilot on one misaligned feature; treat specs as **living documents**; avoid over-specification; expand only where value emerges.
- "Human accountability remains central — teams retain decision ownership even as AI accelerates execution."

## Feeds these wiki pages

- [[spec-driven-development]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
