---
name: authoring-rules
description: Creates and maintains agent rules and system prompts. Use when the user wants to create, improve, or audit agent rules, system prompts, or context files.
author: Daniel Montilla
version: 1.0.1
license: MIT
dependencies:
  - executing-skills
groups:
  - skills
  - documentation
---

# When To Use

Use when the user wants to create, edit, audit, or improve agent rules, system prompts, or context files.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline. It governs how skills are loaded, executed, and verified.

# Pipeline

## 1. Define Scope

- **Global rule** (`alwaysApply: true`): applies to all interactions
- **File-specific** (`globs: *.css`): scoped to matching files

## 2. Draft with Templates

Use [TEMPLATES.md](TEMPLATES.md) for correct metadata and structure.

## 3. Optimize

- Remove fluff
- Use positive constraints ("Do X") over negative ("Don't do Y")
- Pin tech stack versions explicitly (e.g., "Next.js 14")

## 4. Validate

Run [GATES.md](GATES.md) as final validation.

## 5. Save

Write file to `.agents/rules/<rule-name>.md`.

# Reference

- **Templates & Patterns**: [TEMPLATES.md](TEMPLATES.md) (MUST READ)
- **Quality Checks**: [GATES.md](GATES.md) (MUST READ)

## Rule Anatomy

```yaml
---
description: "Brief summary for the Agent to decide relevance"
globs: "*.ts, src/utils/*"
alwaysApply: false
---
```

## Core Strategies

- **Tech Stack Pinning**: List framework versions explicitly
- **Few-Shot Prompting**: Provide `Input -> Output` examples
- **Smart Context**: Use `description` so rule only activates when relevant
