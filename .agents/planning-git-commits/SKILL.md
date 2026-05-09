---
name: planning-git-commits
description: Creates a commit plan with conventional commits based on file paths. Use when user wants to push changes to git.
---

## What I do

1. Ask user which files should be considered for commit (if not specified)
2. Analyze file paths and create a commit plan with conventional commits
3. Present the plan with staged files and commit messages for each step
4. Wait for user confirmation before executing

## When to use me

Use when user asks to commit, push, or stage changes to git.

## Commit Message Format

Use conventional commits with the package/lib/app as scope in parentheses. Determine the scope from the path of the staged files (e.g., `apps/web/`, `packages/api/`, `packages/common/`).

Examples:
- `feat(web): add new component`
- `fix(api): resolve endpoint error`
- `chore(database): add migration script`

For files outside these patterns, omit the scope:
- `feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`, `style:`, `perf:`, `ci:`

## Workflow

### Step 1: Identify Files

If user didn't specify which files to commit, ask:
> Which files would you like to include in this commit? You can specify individual files, directories, or patterns (e.g., "all web changes", "api and database packages").

### Step 2: Create Plan

Analyze the specified files and create a commit plan. Group files by:
- Package/app they belong to (for conventional commit prefix)
- Logical grouping (related changes together)

For each commit, specify:
- **Files to stage**: List of file paths
- **Commit message**: Conventional commit with descriptive summary and body

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

Then ask for confirmation:
> Does this plan look correct? Please confirm or provide feedback (e.g., "yes", "combine first two commits", "split into more granular commits").

### Step 4: Execute Only After Confirmation

Wait for explicit user approval (words like "yes", "go ahead", "execute", "do it"). Only then run git commands to stage and commit.

## Important

- NEVER commit without explicit user confirmation
- NEVER amend pushed commits
- Group files logically and use descriptive commit messages
- Always use conventional commit format with appropriate scope