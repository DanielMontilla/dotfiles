#!/usr/bin/env bash
#
# Imperative installers for apps that are NOT packaged in nixpkgs/Nix.
# `scripts/install <profile>` runs this after the mode-specific package step.
#
# Declare one line per app:
#
#   vendor_app <name> <check> <install command...>
#
# `check` is evaluated first. If it succeeds, the installer is skipped, so
# re-running install is idempotent. Prefer a real Nix package when one exists;
# these installs happen outside Nix's reproducibility/uninstall guarantees.
#
# Examples:
#
#   vendor_app "mytool" \
#       "[ -x \"$HOME/.local/bin/mytool\" ] || command -v mytool" \
#       sh -c 'curl -fsSL https://example.com/install.sh | sh'
#
#   vendor_app "another" \
#       "command -v another" \
#       sh -c 'curl -fsSL https://another.dev/install | bash'
#
# Note: if you already installed one of the Nix-packaged apps with curl, its
# binary in ~/.local/bin may shadow the Nix one. Remove the old binary/symlink
# (or add the app here instead of profilePackages) before relying on it.

set -euo pipefail

vendor_app() {
    local name="$1" check="$2"
    shift 2

    if eval "$check" >/dev/null 2>&1; then
        printf '  %-14s already installed — skipping\n' "$name"
        return 0
    fi

    printf '  %-14s installing...\n' "$name"
    "$@"
}

# Add profile-specific curl installers below. Currently every app pikpik needs
# (zed, codex, claude) is packaged in nixos/flake.nix, so there is nothing to
# do here. Uncomment and adapt when you add something nixpkgs does not have.

# vendor_app "mytool" \
#     "[ -x \"$HOME/.local/bin/mytool\" ] || command -v mytool" \
#     sh -c 'curl -fsSL https://example.com/install.sh | sh'

# A previous curl install in ~/.local/bin can shadow the Nix-managed binary.
for app in zed codex claude; do
    if [ -x "$HOME/.local/bin/$app" ]; then
        printf '  warning: %s exists and may shadow ~/.nix-profile/bin/%s\n' \
            "$HOME/.local/bin/$app" "$app" >&2
    fi
done

exit 0
