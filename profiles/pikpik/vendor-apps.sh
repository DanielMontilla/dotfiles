#!/usr/bin/env bash
#
# Per-profile imperative steps, run by scripts/install after the Nix/darwin
# step. Zed, Ghostty, and Tailscale are Homebrew casks now (declared in
# nixos/configuration.nix), so there is nothing to install here — only the
# shadow checks below, which catch leftovers from the old profile and the old
# curl installers.

set -u

# A previous curl install in ~/.local/bin can shadow the cask or the Nix binary.
# fish puts ~/.local/bin first, so this is not theoretical.
for app in zed ghostty codex claude herdr; do
    if [ -x "$HOME/.local/bin/$app" ]; then
        printf '  warning: %s exists and may shadow the managed %s\n' \
            "$HOME/.local/bin/$app" "$app" >&2
    fi
done

# nix-darwin puts $HOME/.nix-profile first in PATH. Before the migration pikpik
# installed its packages there, so a non-empty profile shadows the system ones
# (fish, git, codex, claude, herdr, ...). Removing it is destructive, so only
# point at the cleanup steps.
if [ -d "$HOME/.nix-profile/bin" ] && [ -n "$(ls -A "$HOME/.nix-profile/bin" 2>/dev/null)" ]; then
    printf '  note: %s still has packages that take precedence over the system ones\n' \
        "$HOME/.nix-profile" >&2
    printf '        remove them with: nix profile remove --all   (README §12)\n' >&2
fi

exit 0
