---
name: authoring-skills
description: Guides users through creating effective Agent Skills that work across OpenCode, Claude Code, Codex, and Cursor. Use when you want to create, write, or author a new skill, or when asked about skill structure, best practices, SKILL.md format, or cross-platform agent compatibility.
license: MIT
compatibility: opencode, claudcode, codex, cursor
metadata:
  audience: developers
  standard: agentskills.io
---

# Creating Cross-Platform Agent Skills

This skill guides you through creating Agent Skills that work across **OpenCode**, **Claude Code**, **Codex**, and **Cursor**. Skills follow the [Agent Skills open standard](https://agentskills.io).

---

## Before You Begin

Gather from the user:

1. **Purpose**: What task or workflow should this skill help with?
2. **Scope**: Personal (all projects) or project (this repo only)?
3. **Triggers**: When should the agent automatically apply this skill?
4. **Domain knowledge**: What specialized info does the agent need?
5. **Output format**: Any templates, formats, or styles required?

---

## Skill File Structure

### Directory Layout

```
skill-name/
├── SKILL.md           # Required – main instructions + frontmatter
├── reference.md       # Optional – detailed docs (load on demand)
├── examples.md        # Optional – usage examples
├── scripts/           # Optional – executable code
│   └── helper.sh
└── assets/            # Optional – templates, resources
```

### Required: SKILL.md with Frontmatter

Every skill must start with YAML frontmatter between `---` markers:

```yaml
---
name: skill-name
description: What this skill does and when to use it
---
```

---

## Storage Location

Place skills in `.agents/skills/<name>/SKILL.md`.

---

## Frontmatter Reference

### Universal Fields (All Platforms)

| Field         | Required | Rules                                                                                                                  | Purpose                          |
| ------------- | -------- | ---------------------------------------------------------------------------------------------------------------------- | -------------------------------- |
| `name`        | Yes      | 1–64 chars, lowercase alphanumeric + single hyphens only. Must match directory name. Regex: `^[a-z0-9]+(-[a-z0-9]+)*$` | Unique identifier                |
| `description` | Yes      | 1–1024 chars                                                                                                           | Helps agent decide when to apply |

### Optional Universal Fields

| Field           | Purpose                   |
| --------------- | ------------------------- |
| `license`       | License name or reference |
| `compatibility` | Environment requirements  |
| `metadata`      | Arbitrary key-value map   |

### Platform-Specific Fields (Other Tools Ignore Unknown Fields)

| Field                      | Platform       | Purpose                                       |
| -------------------------- | -------------- | --------------------------------------------- |
| `disable-model-invocation` | Claude, Cursor | `true` = only user can invoke (no auto-apply) |
| `user-invocable`           | Claude         | `false` = only agent can invoke               |
| `allowed-tools`            | Claude         | Tools agent can use without asking            |
| `argument-hint`            | Claude         | Hint for autocomplete (e.g. `[filename]`)     |
| `context`                  | Claude         | `fork` = run in subagent                      |
| `agent`                    | Claude         | Subagent type when `context: fork`            |

---

## Name Validation

Skill names must:

- Be 1–64 characters
- Use lowercase letters and numbers only
- Use single hyphens as separators
- Not start or end with `-`
- Not contain consecutive `--`
- Match the parent directory name

Examples: `git-release`, `code-review`, `deploy-app`

---

## Writing Effective Descriptions

The description drives discovery. Write in **third person** and include both **WHAT** and **WHEN**:

```yaml
# Good
description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.

# Vague
description: Helps with documents
```

Include trigger terms users would naturally say.

---

## Skill Content Guidelines

### Keep SKILL.md Under 500 Lines

Use progressive disclosure. Put essentials in SKILL.md; move detailed reference to separate files:

```markdown
## Additional resources

- For complete API details, see [reference.md](reference.md)
- For usage examples, see [examples.md](examples.md)
```

### Core Principles

1. **Concise**: Only add context the agent doesn't already have.
2. **Specific**: Prefer one default approach with an escape hatch over many options.
3. **Actionable**: Use imperative steps, clear inputs/outputs.
4. **Consistent**: Choose one term and use it throughout.

### Argument Substitution (Claude-Specific)

Claude supports placeholders; other tools may append arguments:

| Placeholder             | Meaning                            |
| ----------------------- | ---------------------------------- |
| `$ARGUMENTS`            | All arguments passed when invoking |
| `$ARGUMENTS[N]` or `$N` | Argument by 0-based index          |
| `${CLAUDE_SESSION_ID}`  | Current session ID (Claude)        |

---

## Common Patterns

### Reference Content (Background Knowledge)

```yaml
---
name: api-conventions
description: API design patterns for this codebase
---
When writing API endpoints:
  - Use RESTful naming conventions
  - Return consistent error formats
  - Include request validation
```

### Task Content (Explicit Workflow)

```yaml
---
name: deploy
description: Deploy the application to production
disable-model-invocation: true
---

Deploy $ARGUMENTS:
1. Run the test suite
2. Build the application
3. Push to the deployment target
4. Verify the deployment
```

### Workflow Pattern

```markdown
## Workflow

1. **Step 1**: [Instructions]
2. **Step 2**: [Instructions]
3. **Validate**: Run `scripts/validate.sh`
4. **Only proceed when validation passes**
```

---

## Including Scripts

Place executables in `scripts/`. Reference them from SKILL.md:

```markdown
## Usage

Run: `scripts/deploy.sh <environment>`

Where `<environment>` is `staging` or `production`.
```

Scripts should be self-contained with clear error messages.

---

## Skill Creation Workflow

1. **Discovery**: Gather purpose, scope, triggers, requirements.
2. **Design**: Draft name, description, outline. Identify supporting files.
3. **Implementation**: Create directory, SKILL.md, supporting files, scripts.
4. **Verification**: Check name format, description quality, file references, length.
5. **Registration**: Update the [finding-skills](../finding-skills/SKILL.md) index table.

---

## Registering New Skills

After creating a new skill, add a row to the **Skills** table in `AGENTS.md` at the repo root to make it discoverable.

---

## Minimal Working Example

```markdown
---
name: git-release
description: Create consistent releases and changelogs. Use when preparing a tagged release or when the user asks about releases.
license: MIT
---

## What I do

- Draft release notes from merged PRs
- Propose a version bump
- Provide a copy-pasteable `gh release create` command

## When to use me

Use when preparing a tagged release. Ask clarifying questions if the target versioning scheme is unclear.
```

---

## Troubleshooting

| Issue                    | Check                                                                                          |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| Skill not discovered     | `SKILL.md` spelled with caps; frontmatter has `name` and `description`; name matches directory |
| Skill triggers too often | Make description more specific; add `disable-model-invocation: true` if manual-only            |
| Wrong path               | Ensure skill is in `.agents/skills/<name>/SKILL.md`                                            |
| Duplicate names          | Skill names must be unique across all loaded locations                                         |
