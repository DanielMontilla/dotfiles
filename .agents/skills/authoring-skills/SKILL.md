---
name: authoring-skills
description: Guides the creation, formatting, and refinement of Skills. Use when the user wants to write a new Skill, convert documentation into a Skill, or audit an existing Skill.
author: Daniel Montilla
version: 1.1.1
license: MIT
dependencies:
  - executing-skills
  - caveman-compression
groups:
  - skills
---

# When To Use

Use when the user asks to create a new Skill, convert documentation or instructions into a Skill, or audit/improve an existing Skill.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline. It governs how skills are loaded, executed, and verified.

# Pipeline

## 1. Gather Requirements

Check what the user already provided. Only ask for what's missing:

- [ ] **Author**: Who maintains this skill?
- [ ] **Skill name**: Lowercase with hyphens, matches directory name. Must be 1–64 chars, lowercase alphanumeric + hyphens, no leading/trailing hyphens, no consecutive `--`. Examples: `git-release`, `code-review`, `finding-skills`
- [ ] **Purpose**: What task or workflow should this skill help with?
- [ ] **Triggers**: When should the agent automatically apply this skill?
- [ ] **Domain knowledge**: What specialized info does the agent need?
- [ ] **Output format**: Any templates, formats, or styles required?
- [ ] **License**: Defaults to MIT if unspecified, but confirm

If anything is still unclear, **ask the user** before proceeding.

## 2. Scaffold

### Create Directory

Create `.agents/skills/<skill-name>/`. If `.agents/skills/` doesn't exist, ask the user whether to create it or choose a different location.

### Draft SKILL.md Frontmatter

All generated skills MUST list `executing-skills` as a dependency — it governs skill execution.

Write the YAML frontmatter. All fields below are required:

| Field         | Rules                                                                                                                  | Purpose                          |
| ------------- | ---------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `name`        | 1–64 chars, lowercase alphanumeric + single hyphens only. Must match directory name. Regex: `^[a-z0-9]+(-[a-z0-9]+)*$` | Unique identifier                |
| `description` | 1–1024 chars, third person, include when to use                                                                        | Helps agent decide when to apply |
| `author`      | Name of person or team maintaining the skill                                                                           | Attribution and ownership        |
| `version`     | [SemVer](https://semver.org) string, starting at `1.0.0`                                                               | Track changes over time          |

Optional fields: `license` (license name), `groups` (array of categories — see taxonomy below), `dependencies` (array of skill names required to exist before running).

Write descriptions in **third person** including both **WHAT** and **WHEN**:

```yaml
# Good
description: Extracts text and tables from PDF files, fills forms, merges documents. Use when working with PDF files.

# Vague
description: Helps with documents
```

Include trigger terms users would naturally say.

```yaml
---
name: skill-name
description: What this skill does and when to use it
author: Your Name
version: 1.0.0
---
```

### Create CHANGELOG.md

Initialize with a `## [1.0.0]` entry describing the initial release. See the changelog template in [templates/CHANGELOG.md](templates/CHANGELOG.md).

## 3. Plan Content

Before writing, decide:

- **Does this skill need a Prerequisites section?** Only if specific info or setup is required before starting.
- **Does this skill need GATES.md?** Gates are strongly recommended for any skill with complex or quality-critical output. They define end-of-process validation checks that **must** all pass before the skill is complete. If unsure, default to **yes** and create GATES.md.

  **Gates validate the skill's WORK OUTPUT**, not the skill's own files.
  - ✅ Good: "All extracted methods have unique callers", "Test suite passes after refactor"
  - ❌ Bad: "SKILL.md exists", "Frontmatter is valid", "Content has no fluff"

  Those meta-checks are the responsibility of authoring-skills, not something each skill should duplicate.
- **Does this skill need a `documentation/` directory?** For detailed reference material the agent can search through. If unsure, **ask the user**.

These decisions shape how you write the content below.

## 4. Write Content

Structure SKILL.md with these top-level sections:

### When To Use

A concise description of when this skill applies. What user requests or situations trigger it? Apply [caveman-compression](../caveman-compression/SKILL.md) principles — remove fluff, keep meaning.

After the "When To Use" section, add a prerequisite alert loading [executing-skills](../executing-skills/SKILL.md), matching the pattern in the template.

### Pipeline

The step-by-step process to complete the task. Use `##` for major steps and `###` for sub-steps. This is the core of the skill.

### Reference

Links to files within this skill directory containing detailed information the agent can look up on demand. Tag critical references with **(MUST READ)**.

### Documentation (if using `documentation/`)

Index of files in `documentation/` with brief descriptions so the agent can browse and search them:

- **[documentation/SETUP.md](documentation/SETUP.md)**: Brief description of contents

## 5. Supporting Files

### Create GATES.md (if decided)

> **Reminder**: Gates validate the skill's **WORK OUTPUT**, not the skill's own files (see Step 3). Don't include meta-checks like "SKILL.md exists" or "Frontmatter is valid."

Gates are **end-of-process validation checklists**, not steps in the pipeline. They verify the skill's **work product** (refactored code, generated files, extracted utilities, etc.) is correct before declaring done.

**NEVER include checks about the skill's own files:**
- ❌ "SKILL.md exists"
- ❌ "Frontmatter is valid"
- ❌ "Content has no fluff"
- ❌ "Cross-references resolve within skill directory"

These are meta-checks handled by authoring-skills itself. Gates should only validate what the skill *produced or changed* during execution.

✅ Good gate examples:
- "All identified duplicate blocks are extracted into shared utilities"
- "Test suite passes after refactoring"
- "External API unchanged after changes"
- "No unused imports remain in modified files"

Phases run **sequentially** (e.g., verify extraction before checking API compatibility), checks within a phase can be evaluated in **parallel**. If any check fails, **stop and fix the issue** before continuing. See [templates/GATES.md](templates/GATES.md) for the format.

### Add Optional Files

- `documentation/` — Detailed reference files the agent can search through. Add a **Documentation** section in SKILL.md indexing each file with a brief description.
- `examples/` — Example skills or usage patterns
- `templates/` — Reusable templates (see [templates/](templates/))
- `SCRIPTS/` — Executables referenced by the skill. Place scripts here and reference them:
  ```markdown
  Run: `SCRIPTS/deploy.sh <environment>`
  ```
  Scripts should be self-contained with clear error messages.

## 6. Execute All Gates — Mandatory

> **IMPORTANT**: This step is **REQUIRED**, not optional. If GATES.md exists, you **MUST** execute every check in every phase before declaring the skill complete.

Evaluate GATES.md as a final quality gate — not a to-do list. Run each phase **sequentially**, completing **all** checks in a phase before advancing. Checks within a phase can be run in parallel. If **any** check fails, **stop and fix the issue** before continuing. Do not skip, defer, or mark any check as "will fix later" — all gates must pass.

If GATES.md does not exist, verify the output carefully before finishing.

# Reference

- **Templates**: See [templates/](templates/) (MUST READ)
- **Gates**: See [GATES.md](GATES.md) (MUST READ if using gates)
- **Changelog**: See [CHANGELOG.md](CHANGELOG.md)
- **Agent Skills spec**: https://agentskills.io

## Writing Descriptions

Write in **third person**. Describe triggers.

- **Bad**: "I can help you analyze data."
- **Good**: "Analyzes CSV datasets and generates statistical summaries. Use when the user provides raw data files."

## Progressive Disclosure

**Pattern 1: High-level guide** — Keep the main file simple. Link to ONE level of depth.

```markdown
For error codes, see [ERRORS.md](ERRORS.md).
```

**Pattern 2: Domain-specific** — Organize by topic to avoid loading irrelevant tokens.

```markdown
**Sales Data**: See [SALES.md](SALES.md)
**Finance Data**: See [FINANCE.md](FINANCE.md)
```

## Directory Structure

```
.agents/skills/
├── my-skill-name/
│   ├── SKILL.md           # Required
│   ├── CHANGELOG.md       # Required
│   ├── GATES.md           # Optional – validation phases
│   ├── documentation/     # Optional – detailed reference files
│   ├── templates/         # Optional – reusable templates
│   ├── REFERENCE.md       # Optional – detailed docs
│   └── SCRIPTS/           # Optional – executables
└── another-skill/
    └── SKILL.md
```

## Groups

The `groups` field in frontmatter categorizes skills for discovery. Each skill should belong to at least one group. Use the taxonomy below.

| Group | Purpose | Example Skills |
|---|---|---|
| `planning` | Design-phase activities: scoping, spec writing, plan review | creating-feature-spec, scoping-features, grilling |
| `scaffolding` | Code generation and project/package/module setup | setup-typescript-package, creating-typescript-modules |
| `refactoring` | Code improvement, restructuring, and cleanup | applying-solid, detecting-duplication, simplifying-code |
| `documentation` | Doc/rule/schema authoring | writting-jsdoc, authoring-rules |
| `workflow` | Process-oriented git and vendor operations | planning-git-commits, using-git-worktrees, adding-vendor |
| `skills` | Meta-skills about the skill system itself | authoring-skills, finding-skills, executing-skills |
| `feature-spec` | Skills within the feature spec subsystem | creating-feature-spec, executing-feature-spec |
| `typescript` | TypeScript-specific | typescript-conventions, creating-typescript-modules |
| `javascript` | JavaScript-specific | simplifying-code, detecting-duplication |
| `conventions` | Code style and convention enforcement | leaving-it-cleaner, favoring-composition |
| `testing` | Testing infrastructure and review | unit-testing, setup-typescript-tests-with-effect |
| `git` | Git operations | planning-git-commits, adding-vendor |
| `vendors` | Vendor code management | finding-vendors, adding-vendor |
| `effect` | Effect TS ecosystem | setup-typescript-tests-with-effect |
