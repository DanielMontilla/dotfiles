---
name: planning-git-commits
description: Creates a commit plan with conventional commits based on file paths. Use when the user wants to push or commit changes to git.
author: Daniel Montilla
version: 1.0.1
license: MIT
dependencies:
  - executing-skills
groups:
  - git
  - workflow
---

# When To Use

Use when the user asks to commit, push, or stage changes to git.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline. It governs how skills are loaded, executed, and verified.

# Pipeline

## 1. Identify Files

If the user didn't specify which files to commit, ask which files should be included. Accept file paths, directories, or patterns.

## 2. Create Plan

Analyze the specified files and group them by:
- Package or app they belong to (for conventional commit scope)
- Logical grouping of related changes

### Commit Message Format

Use conventional commits with scope in parentheses derived from file paths:

| Type | Format | Example |
|------|--------|---------|
| Feature | `feat(scope): message` | `feat(web): add new component` |
| Fix | `fix(scope): message` | `fix(api): resolve endpoint error` |
| Chore | `chore(scope): message` | `chore(db): add migration` |
| Docs | `docs(scope): message` | `docs: update README` |
| Refactor | `refactor(scope): message` | `refactor(core): extract helper` |
| Test | `test(scope): message` | `test(api): add unit tests` |
| Style | `style(scope): message` | `style(web): format code` |
| Perf | `perf(scope): message` | `perf(db): optimize query` |
| CI | `ci(scope): message` | `ci: update workflow` |

Derive scope from file paths (e.g., `apps/web/`, `packages/api/`). Omit scope for files outside recognized patterns.

## 3. Present Plan

Show the plan in this format:

```
## Commit Plan

### Commit 1: <commit message>
Files: <list of files>
### Commit 2: <commit message>
Files: <list of files>
```

Then ask for confirmation.

## 4. Execute After Confirmation

Wait for explicit user approval ("yes", "go ahead", "execute", "do it") before running git commands to stage and commit.

# Rules

- NEVER commit without explicit user confirmation
- NEVER amend pushed commits
- NEVER use `--author` flag or `Co-authored-by` trailers
- Group files logically with descriptive messages
- Always use conventional commit format with appropriate scope
