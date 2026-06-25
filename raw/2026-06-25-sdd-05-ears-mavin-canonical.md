---
title: "EARS — Easy Approach to Requirements Syntax (Alistair Mavin, canonical)"
aliases: [EARS, EARS notation, Easy Approach to Requirements Syntax]
type: source
domain: emerging
status: seed
tags: [source, emerging, ears, requirements, specification]
updated: 2026-06-25
source_url: https://alistairmavin.com/ears/
source_type: docs
ingested: 2026-06-25
feeds: [ears-notation, spec-driven-development]
---

# EARS — Easy Approach to Requirements Syntax (canonical)

> [!info] Source metadata
> **Author:** Alistair Mavin et al., Rolls-Royce PLC · **URL:** https://alistairmavin.com/ears/

## Key takeaways

- EARS is "a mechanism to gently constrain textual requirements." Emerged from analyzing airworthiness regulations for jet-engine control systems at Rolls-Royce. Lightweight, minimal training, no tools required, readable.
- **Five core patterns** (each = a fixed template with a keyword):
  1. **Ubiquitous** (no keyword, always active): `The <system> shall <response>`
  2. **State-driven** — **WHILE**: `While <precondition>, the <system> shall <response>`
  3. **Event-driven** — **WHEN**: `When <trigger>, the <system> shall <response>`
  4. **Optional feature** — **WHERE**: `Where <feature is included>, the <system> shall <response>`
  5. **Unwanted behaviour** — **IF/THEN**: `If <trigger>, then the <system> shall <response>`
- **Complex** requirements combine keywords: `While <precondition>, when <trigger>, the <system> shall <response>`. Example: "While the aircraft is on ground, when reverse thrust is commanded, the engine control system shall enable reverse thrust."
- `shall` is the single normative verb; one requirement = one `shall`.

## Notable claims (with location)

- Examples: "While there is no card in the ATM, the ATM shall display 'insert card to begin'." / "When 'mute' is selected, the laptop shall suppress all audio output." / "If an invalid credit card number is entered, then the website shall display 'please re-enter credit card details'."
- Adopted globally: Airbus, Bosch, Dyson, Honeywell, Intel, NASA, Rolls-Royce, Siemens; benefits non-native English speakers.

## Feeds these wiki pages

- [[ears-notation]]
- [[spec-driven-development]]

---
*Raw source. Immutable — do not edit the captured content below this line; add analysis above.*
