---
title: "You Didn't Fix the Model. You Memorized the Failure."
aliases: [eval vs patching, train-test contamination, memorizing failures]
type: source
domain: ai-agentic
status: seed
tags: [source, ai-agentic, evaluation, overfitting, contamination, ab-testing]
updated: 2026-06-30
source_url: https://theneuralmaze.substack.com/p/you-didnt-fix-the-model-you-memorized
source_type: article
ingested: 2026-06-30
feeds: [ai-evaluation-and-quality]
---

# You Didn't Fix the Model. You Memorized the Failure.

> [!info] Source metadata
> **Author/Org:** Mai (guest, AI by Mai) & Miguel Otero Pedrido (The Neural Maze) · **Date:** 2026-06-20 · **URL:** https://theneuralmaze.substack.com/p/you-didnt-fix-the-model-you-memorized

## Key takeaways

- The "just call an LLM" reflex is fine for low-stakes tasks, but hides a dangerous class of problem:
  ones where "did this get better?" has no obvious right/wrong answer and you're tuning against
  numbers you only half-trust. That is where data-science discipline still earns its keep.
- **Patching failures one at a time is not improvement.** Worked example: an IKEA "will this sofa fit
  in your car?" model trained on top-selling cars/sofas. A Volvo V60 fails → add an estate-car rule;
  a VW Polo fails → add a hatchback rule; a modular sofa fails → add a configuration check. Each fix
  is locally reasonable, but none tells you whether the model *as a whole* got better — it is
  "whack-a-mole with a model you can't see the shape of."
- **Train / validation / test, and why the order matters.** Train on chunk 1; tune (your patches)
  against chunk 2 it hasn't memorized; touch chunk 3 *once*, at the very end, to report performance.
  "The validation set is where you're allowed to fail and adjust. The test set is where failing
  means something."
- **Train-test contamination** is when test-set information leaks into training, producing accuracy
  that doesn't reflect genuinely unseen data — "a quiet failure mode because the metric goes up; it
  just stops meaning anything." Reverse-engineering a fix from the exact failing case and then
  validating on a set that includes it contaminates your own evaluation.
- This is not a toy concern: it is undermining how the *whole field* evaluates LLMs. Lexical
  obfuscation (shuffling MCQ options, synonym substitution, reversible ciphers) tries to block
  memorization, but frontier models often see through it because they trained on the obfuscated
  formats too. **MMLU, HumanEval, HellaSwag, and the original GSM8K have effectively been retired** —
  all sit in the 90s for top models and no longer produce a useful ranking signal. The response was
  harder benchmarks with cleaner splits (e.g. LiveBench), not abandoning evaluation. "Overfitting is
  the same disease wearing a different name."
- **A/B (online) testing is the same idea with real customers instead of held-out rows.** Once you
  trust the offline numbers, ship to a fraction of sessions (control vs. treatment), compare a single
  metric (e.g. rate of "fits" contradicted by returns). Resist building a whole experimentation
  platform (sequential testing, bandits, stratified sampling) before you've earned the need: "the
  simplest test you can interpret correctly beats a sophisticated one you build incorrectly."
- **Closing argument:** "Not knowing the impact of a change — not even a rough estimate — is
  functionally the same as not having made a change at all." The interface changed (the model now
  writes full sentences); the discipline required to trust its output didn't.

## Notable claims (with location)

- "MMLU, HumanEval, HellaSwag, and the original GSM8K have effectively been retired" — benchmark
  contamination, top models all in the 90s, no useful ranking signal for frontier work. (§ What a
  scientist would do)
- Adaptive/lexical-obfuscation defenses (option shuffling, synonym swaps, reversible ciphers) are
  defeated because models were trained on the obfuscated formats too. (same §)
- A commenter's sharp addendum: clean train/val/test fixes contamination but *not* ticket-shaped
  **sampling bias** — "even an honest number can be honest about the wrong region of the input space."
  (comments)

## Key visuals

> No curated visuals — every image in the post is a decorative AI-generated hero illustration
> ("disappearing model", whack-a-mole, etc.), none an explanatory diagram. Dropped per the
> keep/drop rubric.

## Feeds these wiki pages

- [[ai-evaluation-and-quality]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
