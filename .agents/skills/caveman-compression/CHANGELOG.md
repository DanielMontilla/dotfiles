# Changelog

## [1.1.0] - 2026-07-14

### Added

- Warning that the skill must not be applied to structured operational documents (task frontmatter, MEMORY.md Handoff/Deviations/Requirements) where stop-word stripping can change meaning (REVIEW.md F3)

## [1.0.1] - 2026-07-09

### Added

- Added `executing-skills` as required dependency in frontmatter
- Added prerequisite alert after "When To Use" referencing executing-skills

## [1.0.0] - 2026-07-08

### Added

- Initial release of caveman-compression skill
- Compression rules: article removal, auxiliary verb removal, preposition reduction, pronoun removal, intensifier removal
- Rules for essential elements to always keep (nouns, verbs, adjectives, numbers, uncertainty qualifiers, critical prepositions, time/frequency words, names/titles, technical terms, negations)
- Smart heuristics for context-dependent decisions
- Meaning preservation verification step
- Output format: compressed text only
- Example transformations
