# Gates

Validate a created/modified profile before declaring done. Run phases sequentially; within a phase, checks may run in parallel. Stop and fix on any failure.

## Phase 1 — Structure

- [ ] `profiles/<name>/` exists and contains exactly one mode marker (`.nixos` XOR `.nix-profile` XOR `.windows`).
- [ ] nix-profile mode: `profiles/<name>/nixos/flake.nix` exists and `dotbot` is listed in BOTH `packages.${system}.default` paths and `devShells.${system}.default`.
- [ ] nixos mode: `nixos/hosts/<name>/` exists with the required NixOS modules and `dotbot` is in `environment.systemPackages`.
- [ ] windows mode: `profiles/<name>/dotbot.yaml` exists (dotbot runs on Windows too) and `scripts/install` will find a Python 3.7+ interpreter.

## Phase 2 — Config Validity

- [ ] `profiles/<name>/dotbot.yaml` exists and is parseable by dotbot.
- [ ] Every `link` source path referenced in `dotbot.yaml` exists under the repo (relative to repo root); windows destinations use `~/...` (expanded by dotbot to the user profile dir).

## Phase 3 — Execution

- [ ] `./scripts/install <name>` succeeds (installs/upgrades for nix modes; verifies Python 3.7+ and dotbot, pip-installing dotbot if missing, for windows mode).
- [ ] `./scripts/link <name>` succeeds and creates the expected symlinks in `~/.config/` and `~` (nix modes) or `~/AppData/Roaming/...` (windows mode).
- [ ] windows mode: document Developer Mode / elevated-shell requirement (symlinks) in the profile README.
