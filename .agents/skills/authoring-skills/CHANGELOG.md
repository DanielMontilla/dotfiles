# Changelog

## [1.1.1] - 2026-07-09

### Fixed

- Updated `grill-me` table entry to `grilling` after skill rename

## [1.1.0] - 2026-07-09

### Added

- Added `executing-skills` as required dependency in frontmatter
- Added prerequisite alert after "When To Use" referencing executing-skills
- Pipeline Step 2: all generated skills MUST list `executing-skills` as a dependency
- Pipeline Step 4: added instruction to include prerequisite alert after "When To Use"
- Template SKILL.md includes `executing-skills` in default dependencies and prerequisite alert

## [1.0.0] - 2026-07-08

### Added

- Initial release of authoring-skills skill
- Standard skill structure: When To Use, Prerequisites, Pipeline, Reference
- GATES.md replaces CHECKLIST.md with phased validation (sequential phases, parallel checks)
- TEMPLATES.md with standard skeleton matching the new structure
- examples/ directory with example skills
- Standardized frontmatter with required `name`, `description`, `author`, `version` fields
- Optional frontmatter fields: `license`, `language`, `groups`, `dependencies`
- `dependencies` includes [caveman-compression](../caveman-compression/SKILL.md) as a required dependency
