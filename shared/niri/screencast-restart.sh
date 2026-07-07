#!/usr/bin/env bash
set -euo pipefail

# Activate the graphical session target since niri runs from TTY,
# not the systemd service. This is required for xdg-desktop-portal-gnome.
systemctl --user start graphical-session.target

# Export Wayland session to D-Bus so portal backends can find it
dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=niri

# Poll until niri's ScreenCast D-Bus interface is ready,
# then restart xdg-desktop-portal-gnome so it picks it up
while ! busctl --user status org.gnome.Mutter.ScreenCast &>/dev/null; do
    sleep 0.2
done
systemctl --user restart xdg-desktop-portal-gnome.service
