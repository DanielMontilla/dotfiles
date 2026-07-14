# Agent Skills Index

Index of skills available in this repo under `.agents/skills/`. Each skill is a
self-contained directory with a `SKILL.md`. Load a skill when the user's request matches
its `description` / `groups`, or when explicitly instructed.

Skills marked with a dependency on `executing-skills` should be run via that skill's
pipeline. See `authoring-skills` for how skills are created and audited.

## Skills

### authoring-skills
- **Path**: `.agents/skills/authoring-skills/`
- **Groups**: skills
- **Description**: Guides the creation, formatting, and refinement of Skills. Use when the user wants to write a new Skill, convert documentation into a Skill, or audit an existing Skill.
- **Dependencies**: executing-skills, caveman-compression

### caveman-compression
- **Path**: `.agents/skills/caveman-compression/`
- **Groups**: skills
- **Description**: Aggressively removes stop words and grammatical scaffolding while preserving meaning. Use when user asks to compress, shorten, simplify, or caveman-style reduce text.
- **Dependencies**: executing-skills

### creating-dotfiles-profiles
- **Path**: `.agents/skills/creating-dotfiles-profiles/`
- **Groups**: scaffolding, workflow
- **Description**: Creates a new machine/user profile in this dotfiles repository (nixos or nix-profile mode), wiring up packages via Nix and symlinking config files via dotbot. Use when adding a host, creating a profile, or setting up dotfiles for a new machine.
- **Dependencies**: executing-skills

### creating-quickshell-widgets
- **Path**: `.agents/skills/creating-quickshell-widgets/`
- **Groups**: scaffolding
- **Description**: Designs and writes Quickshell QML widgets (bar components, popups, status indicators) for this dotfiles repo's louie profile, following the existing shared bar conventions. Use when the user asks to add, build, or modify a Quickshell widget, bar item, popup, or panel in profiles/*/quickshell.
- **Dependencies**: executing-skills

### executing-skills
- **Path**: `.agents/skills/executing-skills/`
- **Groups**: skills
- **Description**: Loads, executes, and verifies skills from .agents/skills/. Use when the user's request matches an existing skill's description or when instructed to use a specific skill.
- **Dependencies**: finding-skills

### finding-skills
- **Path**: `.agents/skills/finding-skills/`
- **Groups**: skills
- **Description**: Discovers and surfaces available skills matching user requests. Use when the user asks "what skills do you have", "how do I do X", or wants to find a skill for a specific task.
- **Dependencies**: executing-skills

### installing-profiles
- **Path**: `.agents/skills/installing-profiles/`
- **Groups**: workflow
- **Description**: User-facing guide for installing a dotfiles profile via scripts/install. This skill describes the install workflow and gotchas; the agent must NOT run these steps itself (they require the user's sudo/tty access).
- **Dependencies**: none

### planning-git-commits
- **Path**: `.agents/skills/planning-git-commits/`
- **Groups**: git, workflow
- **Description**: Creates a commit plan with conventional commits based on file paths. Use when the user wants to push or commit changes to git.
- **Dependencies**: executing-skills

## Skills by group

- **skills**: authoring-skills, caveman-compression, executing-skills, finding-skills
- **scaffolding**: creating-dotfiles-profiles, creating-quickshell-widgets
- **workflow**: creating-dotfiles-profiles, installing-profiles, planning-git-commits
- **git**: planning-git-commits
