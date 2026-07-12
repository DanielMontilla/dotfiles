## Phase 1: File Structure

- [ ] Directory `.agents/skills/<name>/` exists
- [ ] `SKILL.md` exists — follows [templates/SKILL.md](templates/SKILL.md) structure
- [ ] `CHANGELOG.md` exists — follows [templates/CHANGELOG.md](templates/CHANGELOG.md) format
- [ ] File references in SKILL.md point to existing files
- [ ] All referenced paths use forward slashes
- [ ] All file references are UPPERCASE
- [ ] No non-standard files/dirs present — only `SKILL.md`, `CHANGELOG.md`, `GATES.md`, `documentation/`, `templates/`, `REFERENCE.md`, `SCRIPTS/` allowed

## Phase 2: Frontmatter

- [ ] YAML frontmatter is valid and parses correctly — see [templates/SKILL.md](templates/SKILL.md) for reference
- [ ] `name` matches the directory name
- [ ] `name` follows the pattern: lowercase alphanumeric + single hyphens, 1–64 chars
- [ ] `description` is third person and includes when to use
- [ ] `author` is present
- [ ] `version` is present, starts at `1.0.0`, follows SemVer
- [ ] No unknown or extra fields in frontmatter

## Phase 3: Content Quality

- [ ] `# When To Use` section exists and describes triggers — see [templates/SKILL.md](templates/SKILL.md)
- [ ] `# Pipeline` section exists with step-by-step process
- [ ] No educational fluff (explanations of concepts the agent already knows)
- [ ] No agent-specific references (OpenCode, Claude, etc.)
- [ ] Terminology is consistent throughout
- [ ] Writing follows [caveman-compression](../caveman-compression/SKILL.md) principles — concise, no wasted words
- [ ] No contradictory instructions
- [ ] The skill follows its own structural rules (same top-level sections it prescribes)

## Phase 4: Integration

- [ ] Skill is listed in `.agents/AGENTS.md` (or equivalent index file)
- [ ] All cross-references within the skill resolve correctly
- [ ] Any referenced scripts in `SCRIPTS/` exist and are executable
