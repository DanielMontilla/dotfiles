# Changelog

## [1.1.0] - 2026-07-13

### Added

- `windows` mode: `.windows` marker, dotbot-based linking with `~/AppData/...` destinations, Python 3.7+ / dotbot prerequisite check (pip install) in `scripts/install`, `python -m dotbot` fallback in `scripts/link`.
- Reference windows profile `profiles/koppai/` (`.windows`, `dotbot.yaml`, Windows-adjusted `zed/`, `README.md`).
- Gotchas: Git Bash as the shell, Python 3.7+ prerequisite, Developer Mode for symlinks, existing-regular-file blocks, same-drive requirement for relative links, no `clean` on Windows, NixOS-isms in shared configs.

## [1.0.0] - 2026-07-12

### Added

- Initial release of creating-dotfiles-profiles
- Documents nixos vs nix-profile modes and marker-file selection
- Canonical `flake.nix` and `dotbot.yaml` templates for nix-profile profiles
- Gotchas: entry-name vs profile-name mismatch, ANSI color stripping, conflicting existing profile, dotbot dependency, install-before-link ordering
