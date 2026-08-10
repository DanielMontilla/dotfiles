---
name: installing-profiles
description: User-facing guide for installing a dotfiles profile via scripts/install and scripts/link. This skill describes the install workflow and gotchas; the agent must NOT run these steps itself (they require the user's sudo/tty access or a Windows host).
author: Daniel Montilla
version: 1.0.0
license: MIT
groups:
  - workflow
---

# When To Use

Use this skill as a reference when the user wants to install a profile on a
machine (e.g. "install louie", "how do I set up this machine"). It documents the
`scripts/install <profile>` / `scripts/link <profile>` workflow and its gotchas.

> **CRITICAL — the agent CANNOT run this.**
> `scripts/install` requires the user's `sudo`/tty access and interactive
> approval (`sudo nixos-rebuild`, `nix profile` store writes). `scripts/link`
> shells out to `dotbot`, which on a windows profile touches the user's
> `%APPDATA%`-style dirs on the Windows machine. The agent must only hand the
> user the commands and explain any errors. Never execute these scripts on the
> user's behalf unless they explicitly ask.

# Install Workflow (for the user)

1. Ensure the profile exists:
   - `nixos` mode → `profiles/<name>/.nixos` marker + `nixos/hosts/<name>/`.
   - `nix-profile` mode → `profiles/<name>/.nix-profile` marker + flake.
   - `windows` mode (no nix) → `profiles/<name>/.windows` marker + `dotbot.yaml`.
2. From the repo root, run:

   ```bash
   ./scripts/install <name>
   ```

   For `windows` profiles this checks Python 3.7+ and dotbot (pip-installing
   dotbot if missing) instead of installing packages.

3. Then link config files:

   ```bash
   ./scripts/link <name>
   ```

   Runs dotbot for every mode. On Windows you need Git Bash (Git for Windows),
   Python 3.7+, and Developer Mode for symlinks — see
   `profiles/koppai/README.md`.

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
  needs the `dotbot` binary from the profile (nix modes only).

- **Windows profiles never run nix.** `scripts/install koppai` only checks
  Python 3.7+ and dotbot (`python -m pip install --user dotbot` if missing).
  Linking is plain dotbot against `~/AppData/Roaming/...` destinations;
  symlinks require Developer Mode (Settings → Privacy & security → For
  developers) or an elevated shell. If dotbot's binary isn't on PATH,
  `scripts/link` falls back to `python -m dotbot`.

- **Preserve machine-specific values** in shared configs (e.g. GitHub CLI
  `credential.helper`). Back up originals and merge back after linking.

# Reference

- **Install script**: `scripts/install` (mode detection by marker)
- **Link script**: `scripts/link` (invokes `dotbot` against the profile yaml)
- **Profile creation**: [creating-dotfiles-profiles](../creating-dotfiles-profiles/SKILL.md)
