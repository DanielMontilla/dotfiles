#!/usr/bin/env bash
#
# Per-profile imperative steps, run by scripts/install after the Nix/darwin
# step. Zed, Ghostty, and Tailscale are Homebrew casks now (declared in
# nixos/configuration.nix), so there is nothing to install here — only the
# shadow check below, which catches leftovers from the old curl installers.

set -u

# A previous curl install in ~/.local/bin can shadow the cask or the Nix binary.
# fish puts ~/.local/bin first, so this is not theoretical.
for app in zed ghostty codex claude herdr; do
    if [ -x "$HOME/.local/bin/$app" ]; then
        printf '  warning: %s exists and may shadow the managed %s\n' \
            "$HOME/.local/bin/$app" "$app" >&2
    fi
done

exit 0
