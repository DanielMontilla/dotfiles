---
name: caveman-compression
description: Aggressively removes stop words and grammatical scaffolding while preserving meaning. Use when user asks to compress, shorten, simplify, or caveman-style reduce text.
author: Daniel Montilla
version: 1.1.0
license: MIT
dependencies:
  - executing-skills
groups:
  - skills
---

# When To Use

Use when asked to compress, shorten, simplify, or caveman-style reduce text while preserving semantic meaning.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline. It governs how skills are loaded, executed, and verified.

# Pipeline

## 1. Identify Compressible Content

Identify text passages that can be compressed — any text where brevity matters more than readability.

> **Warning:** Do NOT apply this skill to structured operational documents — task frontmatter, or MEMORY.md `Handoff`/`Deviations` sections and TASK.md `Requirements` — where removing prepositions or auxiliary verbs can change meaning. The feature-spec skills apply it only to free-form prose for this reason.

## 2. Apply Compression Rules

### Remove Scaffolding

- Remove articles: a, an, the
- Remove auxiliary verbs: is, are, was, were, am, be, been, being, have, has, had, do, does, did
- Remove redundant prepositions: of, for, to, in, on, at (when meaning stays clear)
- Remove pronouns when clear: it, this, that, these, those
- Remove intensifiers: very, quite, rather, somewhat, really, extremely

### Keep Essential Elements

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

## 3. Apply Smart Heuristics

- Keep prepositions that define relationships: "made from wood" (keep from), "system for processing" (remove for)
- Keep "in/on/at" when they specify location/position
- Remove "is/are/was/were" unless part of important passive voice

## 4. Verify Meaning Preserved

Confirm compressed output retains all semantic meaning — no loss of facts, relationships, or uncertainty.

## 5. Output

Output ONLY the compressed text, nothing else.

# Reference

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
