# Changelog

## [1.2.0] - 2026-07-14

### Added

- Documented the `feat/<feature-name>` branch convention in the git fallback; default `<branch>-worktree` is not recognized as a feature worktree by authoring-feature-spec (REVIEW.md F9)

## [1.1.1] - 2026-07-14

### Changed

- Step 0 exception reworded: a calling skill may request a branch name or worktree location, but only when not already in a linked worktree. Nested worktree creation is forbidden; the calling skill must delegate creation to this skill and never run `git worktree add` directly
- Quick Reference and Red Flags updated to forbid nested worktrees

## [1.1.0] - 2026-07-11

### Changed

- Step 0: Added feature-spec override exception (calling skill may instruct new worktree creation even from existing worktree)
- Step 2: Changed from hardcoded setup to "ask user or let agent figure it out" pattern

## [1.0.0] - 2026-07-09

### Added

- Initial release of using-git-worktrees skill
- Added `executing-skills` as required dependency in frontmatter
- Added prerequisite alert after "When To Use" referencing executing-skills

### Added

- Initial release of using-git-worktrees skill
- Added `executing-skills` as required dependency in frontmatter
- Added prerequisite alert after "When To Use" referencing executing-skills
