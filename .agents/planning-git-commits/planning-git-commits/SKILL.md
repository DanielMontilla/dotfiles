---
name: planning-git-commits
description: Creates a commit plan with conventional commits based on file paths. Use when user wants to push changes to git.
---

## What I do

1. Ask files if unspecified.
2. Analyze paths; create conventional commit plan.
3. Present staged files + commit messages per step.
4. Wait user confirmation before executing.

## When to use me

Use when user asks commit, push, or stage git changes.

## Commit Message Format

Use conventional commits with package/lib/app scope from staged paths (`apps/web/`, `packages/api/`, `packages/common/`).

Examples:
- `feat(web): add new component`
- `fix(api): resolve endpoint error`
- `chore(database): add migration script`

Outside these patterns, omit scope:
- `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `style:`, `perf:`, `ci:`

## Workflow

### Step 1: Identify Files

If user did not specify files, ask:
> Which files would you like to include in this commit? You can specify individual files, directories, or patterns (e.g., "all web changes", "api and database packages").

### Step 2: Create Plan

Analyze specified files. Group by:
- Package/app for conventional commit prefix
- Logical grouping

For each commit, specify:
- **Files to stage**: file paths
- **Commit message**: conventional commit with descriptive summary + body

### Step 3: Present Plan

Show the plan in this format:

```
## Commit Plan

### Commit 1: <commit message>
Files: <list of files>
### Commit 2: <commit message>
Files: <list of files>
...
```

Ask confirmation:
> Does this plan look correct? Please confirm or provide feedback (e.g., "yes", "combine first two commits", "split into more granular commits").

### Step 4: Execute Only After Confirmation

Wait explicit approval (`yes`, `go ahead`, `execute`, `do it`). Only then run git stage/commit commands.

## Important

- NEVER commit without explicit user confirmation.
- NEVER amend pushed commits.
- Group files logically; use descriptive messages.
- Always use conventional commit format with appropriate scope.