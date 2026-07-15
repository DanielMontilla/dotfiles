#!/usr/bin/env bash
set -uo pipefail

# Guard against accumulating copies across niri restarts: only one instance may
# run. Kill any prior instance tied to this script before proceeding, otherwise
# each `niri` relaunch leaves a leaked poll loop that permanently spins on the
# bus and repeatedly restarts the portals (causing escalating launch lag).
for pid in $(pgrep -f "screencast-restart.sh" || true); do
    if [ "$pid" != "$$" ]; then
        kill "$pid" 2>/dev/null || true
    fi
done

# Activate the graphical session target since niri runs from TTY,
# not the systemd service. This is required for xdg-desktop-portal-gnome.
systemctl --user start graphical-session.target || true

# Export Wayland session to D-Bus so portal backends can find it
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri || true

# Poll (bounded) until niri's ScreenCast D-Bus interface is ready,
# then restart xdg-desktop-portal-gnome so it picks it up.
# Bounded to ~30s so a missing interface can never wedge the session.
for _ in $(seq 1 150); do
    if busctl --user status org.gnome.Mutter.ScreenCast &>/dev/null; then
        systemctl --user restart xdg-desktop-portal-gnome.service || true
        exit 0
    fi
    sleep 0.2
done

# Timed out: screencast interface never appeared (e.g. niri launched nested).
# Leave the portals alone rather than blocking or looping forever.
exit 0
