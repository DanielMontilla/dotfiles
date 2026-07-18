---
name: modifying-skills
description: Modifies, updates, extends, or audits existing skills in .agents/skills/. Use when the user wants to edit an existing skill, add content to a skill, audit a skill for quality, or update skill metadata.
author: Daniel
version: 1.0.2
license: MIT
groups:
  - skills
dependencies:
  - executing-skills
  - grilling
---

# When To Use

Use when modifying, updating, extending, or auditing an existing skill. Includes editing SKILL.md, GATES.md, CHANGELOG.md, adding content, updating metadata, reviewing quality, or restructuring skill files.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline. It governs how skills are loaded, executed, and verified.

# Pipeline

## 1. Identify Target Skill

Confirm which skill to modify. If unspecified, ask the user. Locate the skill at `.agents/skills/<name>/`.

## 2. Load Current State

Read all relevant files in the skill directory: `SKILL.md`, `CHANGELOG.md`, `GATES.md`, and any files in `documentation/`, `templates/`, `SCRIPTS/`.

## 3. Audit (if applicable)

If the task involves quality review, assess against [authoring-skills GATES.md](../authoring-skills/GATES.md):

- File structure compliance
- Frontmatter validity
- Content quality (no fluff, consistent terminology, agent-agnostic)
- Cross-references resolve

Report findings to the user before proceeding.

## 4. Plan Changes

Outline the specific modifications needed:

- Which files change and how
- Whether CHANGELOG.md needs a new entry
- Whether GATES.md needs updating
- Whether version should increment

Present the plan to the user for confirmation before executing.

## 5. Execute Modifications

Apply changes using Edit/Write tools. Follow these conventions:

- Update `version` in frontmatter (patch for fixes, minor for additions, major for restructuring)
- Update `CHANGELOG.md` with a dated entry per [templates/CHANGELOG.md](../authoring-skills/templates/CHANGELOG.md)
- Preserve existing YAML frontmatter fields unless intentionally changing them
- Maintain consistent formatting and terminology with the rest of the skill

## 6. Verify

Run through [GATES.md](GATES.md) checks. Fix any failures.

## 7. Update AGENTS.md

If the skill's name or description changed in AGENTS.md, update the index entry.

# Reference

- **Skill audit standards**: [authoring-skills GATES.md](../authoring-skills/GATES.md)
- **Changelog template**: [authoring-skills templates/CHANGELOG.md](../authoring-skills/templates/CHANGELOG.md)
- **Skill execution**: [executing-skills](../executing-skills/SKILL.md)
- **Skill creation**: [authoring-skills](../authoring-skills/SKILL.md)
