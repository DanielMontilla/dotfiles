---
name: caveman-compression
description: Aggressively removes stop words and grammatical scaffolding while preserving meaning. Use when user asks to compress, shorten, simplify, or caveman-style reduce text.
---

## What I do

Remove all unnecessary words while keeping semantic meaning. Think caveman: raw, direct, essential only.

## Core Strategy

1. **Remove articles**: a, an, the
2. **Remove auxiliary verbs**: is, are, was, were, am, be, been, being, have, has, had, do, does, did
3. **Remove redundant prepositions**: of, for, to, in, on, at (when meaning stays clear)
4. **Remove pronouns when clear**: it, this, that, these, those
5. **Remove intensifiers**: very, quite, rather, somewhat, really, extremely

## Always Keep

- All nouns (people, places, things, concepts)
- All main verbs (actions, not auxiliaries)
- All adjectives that add meaning
- All numbers and quantifiers (at least, approximately, more than, 15, many)
- Uncertainty qualifiers (what sounded like, appears to be, seems, might)
- Critical prepositions that change meaning (from, with, without, stuck to)
- Time/frequency words (every Tuesday, weekly, daily, always, never)
- Names, titles (Dr., Mr., Senator)
- Technical terms and domain-specific language
- Negations (not, no, never, without)

## Be Smart

- **Keep prepositions** that define relationships: "made from wood" (keep from), "system for processing" (remove for)
- **Keep "in/on/at"** when they specify location/position
- **Remove "is/are/was/were"** unless part of important passive voice

## Output

Output ONLY the compressed text, nothing else.

## Examples

"Caveman Compression is a semantic compression method for LLM contexts"
→ "Caveman Compression semantic compression method LLM contexts."

"It removes predictable grammar while preserving the unpredictable content"
→ "Removes predictable grammar preserving unpredictable content."

"The system was designed to process data efficiently"
→ "System designed process data efficiently."

"There were at least 20 people"
→ "At least 20 people."

"Made from wood and metal"
→ "Made from wood and metal."