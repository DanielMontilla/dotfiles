---
name: creating-dotfiles-profiles
description: Creates a new machine/user profile in this dotfiles repository (nixos or nix-profile mode), wiring up packages via Nix and symlinking config files via dotbot. Use when adding a host, creating a profile, or setting up dotfiles for a new machine.
author: Daniel Montilla
version: 1.0.0
license: MIT
dependencies:
  - executing-skills
groups:
  - scaffolding
  - workflow
---

# When To Use

Use when the user wants to:
- Add a new profile/host to this dotfiles repo (e.g. "create a profile for my new laptop").
- Set up the packages and config symlinks for a machine.
- Understand how `scripts/install` and `scripts/link` work for a profile.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline. It governs how skills are loaded, executed, and verified.

# Background

The repo has two layouts living side by side:

- **profiles/**: one directory per profile (`framework`, `homelab`, `olimar`, `shared`).
- **nixos/hosts/<profile>/**: NixOS system config used only by `nixos` mode.
- **scripts/install** and **scripts/link**: the two entrypoints.

Every profile is one of two **modes**, chosen by a marker file in `profiles/<name>/`:

| Marker | Mode | What it installs |
|--------|------|------------------|
| `.nixos` | nixos | Full system via `sudo nixos-rebuild switch --flake ".#<profile>"` |
| `.nix-profile` | nix-profile | User packages via `nix profile add path:profiles/<name>/nixos` |

`scripts/install <profile>` reads the marker to pick the mode. `scripts/link <profile>` always runs `dotbot` against `profiles/<profile>/dotbot.yaml` (this step is mode-independent).

# Pipeline

## 1. Decide the Mode

Ask the user (or infer from the machine type):
- **nixos** → bare-metal NixOS machine that owns the whole system (bootloader, networking, etc.).
- **nix-profile** → a user-level environment on an existing system (WSL, another distro, or a non-root setup).

Create the profile directory: `profiles/<name>/`.

## 2. Create Mode Layout

### nixos mode
1. Add marker: `touch profiles/<name>/.nixos`.
2. Create `nixos/hosts/<name>/` and add the standard NixOS modules. Mirror an existing host:
   - `bootloader.nix`, `configuration.nix`, `hardware-configuration.nix`, `networking.nix`, `packages.nix`, `user.nix` (see `nixos/hosts/framework/`).
3. Declare packages inside `environment.systemPackages` in `packages.nix` (use `with pkgs; [ ... ]`). Include `dotbot` here so `scripts/link` works after `nixos-rebuild`. See `nixos/hosts/framework/packages.nix:84`.

### nix-profile mode
1. Add marker: `touch profiles/<name>/.nix-profile`.
2. Create `profiles/<name>/nixos/flake.nix`. Use a `pkgs.buildEnv` named after the profile and a matching `devShells.default`. **Both** the `paths` list and the devShell must include every package the profile needs.
3. **Critically include `dotbot`** in the flake paths so `scripts/link` has the `dotbot` CLI available. (This is the part that was missed for `olimar` — `dotbot` must be a Nix package in the profile, not assumed present.)

See [templates/flake.nix](templates/flake.nix) for the canonical nix-profile flake.

## 3. Write the dotbot Config

Create `profiles/<name>/dotbot.yaml`. It symlinks config files into the user home from `profiles/shared/<app>/`. Use these defaults:

```yaml
- defaults:
    link:
      relink: true
      create: true
      glob: true
      relative: true

- clean:
    "~/.config/fish/":
      force: true
    "~/.config/nvim/":
      force: true

- link:
    ~/.gitconfig: profiles/shared/git/gitconfig
    ~/.config/fish/:
      path: profiles/shared/fish/*
    ~/.config/nvim/:
      path: profiles/shared/neovim/lazy/*
```

Reusable shared configs live under `profiles/shared/` (alacritty, fish, git, neovim, starship, etc.). Reference them by relative path from repo root.

See [templates/dotbot.yaml](templates/dotbot.yaml) for the full template.

## 4. Install

```bash
./scripts/install <name>
```

- nixos mode runs `sudo nixos-rebuild switch --flake ".#<name>"`.
- nix-profile mode runs `nix profile add path:profiles/<name>/nixos` (first time) or `nix profile upgrade <entry>` (subsequent runs). The script auto-detects an existing install by matching the flake URL, then upgrades by the **entry name** (see Gotchas).

> **Do NOT run these scripts yourself.** `scripts/install` and `scripts/link` require the user's sudo/tty access and interactive approval (e.g. `sudo nixos-rebuild`, `nix profile` store writes, dotbot overwriting files in their home). Generate or edit the profile files, then hand the commands to the user to run. Only execute them directly if the user explicitly asks.

## 5. Link

```bash
./scripts/link <name>
```

Runs `dotbot -d <repo> -c profiles/<name>/dotbot.yaml`. Requires `dotbot` to be installed (covered by step 2). As above, let the user run this — don't execute it on their behalf.

# Gotchas (MUST READ)

- **Entry name ≠ profile name in nix-profile mode.** `nix profile add path:profiles/olimar/nixos` creates a profile entry literally named `nixos` (the last path component), *not* `olimar`. `nix profile list` shows `Name: nixos`. The `install` script detects the existing install by the flake URL substring and upgrades by that entry name. Don't try to `nix profile upgrade olimar` — it won't match.
- **Color codes in parsing.** `nix profile list` emits ANSI bold codes when stdout is a TTY. Any script parsing its output must strip `\033\[[0-9;]*m` before using the name, or `nix profile upgrade` receives a garbage name and warns "Package name '...' does not match any packages".
- **Conflicting existing profile.** If a prior generic `nix-profile` (e.g. from `~/.config/nix-profile`) already provides `git`/`neovim`/etc., adding a new profile fails with "An existing package already provides the following file". Remove the old one first: `nix profile remove nix-profile`, then re-run install.
- **dotbot is mandatory for link.** `scripts/link` shells out to `dotbot`. On nix-profile machines it must be in the flake `paths`; on nixos machines it must be in `environment.systemPackages`.
- **Existing regular files block links.** `relink: true` only replaces existing *symlinks*. If the target (`~/.gitconfig`, etc.) already exists as a regular file, dotbot aborts with "already exists but is a regular file or directory". Fix: set `force: true` on that specific link entry (not globally) and back up the old file first (e.g. `cp ~/.gitconfig ~/.gitconfig.bak`). Re-running link then overwrites it.
- **Preserve machine-specific values.** The shared config may drop user-specific settings (e.g. a GitHub CLI `credential.helper`). Back up the original and merge any needed lines back into the shared file or a local `[include]` after linking.
- **Order matters:** install (packages) before link (config), because link needs the `dotbot` binary from the profile.
- **`nix profile add` updates the manifest, not always the live symlink.** If `nix profile list` shows the profile but `~/.nix-profile/bin/<tool>` is missing (e.g. `nvim` — note neovim's binary is `nvim`, not `neovim`), the profile symlink is stale. Fix with a clean `nix profile remove <entry>` + `nix profile add path:profiles/<name>/nixos`, or delete `~/.nix-profile` and `~/.local/state/nix/profiles` entirely and reinstall. If nix errors with "reading symbolic link ... Invalid argument", the symlink is corrupt — nuke and reinstall.
- **Profile location:** the `nix profile` default lives at `~/.local/state/nix/profiles/profile`; `~/.nix-profile` is a symlink to it. Keep PATH relying on `~/.nix-profile/bin` so it always tracks the current generation.

# Reference

- **Install script**: `scripts/install` (mode detection by marker, upgrade by entry name)
- **Link script**: `scripts/link` (invokes `dotbot` with the profile's yaml)
- **nix-profile flake template**: [templates/flake.nix](templates/flake.nix) (MUST READ)
- **dotbot yaml template**: [templates/dotbot.yaml](templates/dotbot.yaml) (MUST READ)
- **Existing nix-profile example**: `profiles/olimar/` (`.nix-profile`, `nixos/flake.nix`, `dotbot.yaml`)
- **Existing nixos example**: `nixos/hosts/framework/` + `.nixos` marker
- **Shared configs**: `profiles/shared/` (reusable app configs to symlink)
