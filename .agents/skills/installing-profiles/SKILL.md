---
name: installing-profiles
description: User-facing guide for installing a dotfiles profile via scripts/install. This skill describes the install workflow and gotchas; the agent must NOT run these steps itself (they require the user's sudo/tty access).
author: Daniel Montilla
version: 1.0.0
license: MIT
groups:
  - workflow
---

# When To Use

Use this skill as a reference when the user wants to install a profile on a
machine (e.g. "install loui", "how do I set up this machine"). It documents the
`scripts/install <profile>` workflow and its gotchas.

> **CRITICAL — the agent CANNOT run this.**
> `scripts/install` requires the user's `sudo`/tty access and interactive
> approval (`sudo nixos-rebuild`, `nix profile` store writes). The agent must
> only hand the user the commands and explain any errors. Never execute
> `scripts/install` or `scripts/link` on the user's behalf unless they
> explicitly ask.

# Install Workflow (for the user)

1. Ensure the profile exists:
   - `nixos` mode → `profiles/<name>/.nixos` marker + `nixos/hosts/<name>/`.
   - `nix-profile` mode → `profiles/<name>/.nix-profile` marker + flake.
2. From the repo root, run:

   ```bash
   ./scripts/install <name>
   ```

3. Then link config files (needs `dotbot`, provided by the profile install):

   ```bash
   ./scripts/link <name>
   ```

# Gotchas (MUST READ)

- **The flake is a git input.** Nix flakes only see git-tracked files. A freshly
  generated `nixos/hosts/<name>/hardware-configuration.nix` is untracked until
  `git add`ed, so `nixos-rebuild` aborts with
  `error: Path '.../hardware-configuration.nix' ... is not tracked by Git`.
  Before install on a new machine, run:

  ```bash
  git add nixos/hosts/<name>/
  ```

  A commit is **not** required — staging is enough for the flake to see it.

- **Entry name ≠ profile name (nix-profile mode).** `nix profile add
  path:profiles/<name>/nixos` names the entry `nixos` (last path component),
  not `<name>`. Re-run install upgrades by entry name automatically.

- **Order matters:** install (packages) before link (config), because link
  needs the `dotbot` binary from the profile.

- **Preserve machine-specific values** in shared configs (e.g. GitHub CLI
  `credential.helper`). Back up originals and merge back after linking.

# Reference

- **Install script**: `scripts/install` (mode detection by marker)
- **Link script**: `scripts/link` (invokes `dotbot` against the profile yaml)
- **Profile creation**: [creating-dotfiles-profiles](../creating-dotfiles-profiles/SKILL.md)
