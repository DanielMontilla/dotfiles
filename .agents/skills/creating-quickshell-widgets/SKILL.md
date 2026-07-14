---
name: creating-quickshell-widgets
description: Designs and writes Quickshell QML widgets (bar components, popups, status indicators) for this dotfiles repo's louie profile, following the existing shared bar conventions. Use when the user asks to add, build, or modify a Quickshell widget, bar item, popup, or panel in profiles/*/quickshell.
author: Daniel Montilla
version: 1.0.0
license: MIT
dependencies:
  - executing-skills
groups:
  - scaffolding
---

# When To Use

Use when adding or modifying a Quickshell widget for this repo: a new bar component, a
popup menu, a status indicator (volume, battery, clock, network, media, etc.), or any
QML panel piece under `profiles/*/quickshell`. The goal is louie-profile widgets that
mirror the existing framework/shared bar.

> **Prerequisite**: Load the [executing-skills](../executing-skills/SKILL.md) skill before running this pipeline.

# Pipeline

## 1. Gather requirements

Check the user's request. Only ask if missing:

- [ ] **Widget** — what does it show or do? (status readout, click action, popup menu)
- [ ] **Data source** — native service (UPower/Pipewire/Mpris/...) or a `Process`?
- [ ] **Interactivity** — static text, click toggle, slider, or popup menu?
- [ ] **Placement** — add to an existing bar `RowLayout`, or standalone window?

## 2. Read the references

Load the curated reference and the closest existing widget before writing:

- **[documentation/quickshell-reference.md](../../../documentation/quickshell-reference.md)** (MUST READ)
- Closest existing widget for pattern matching: `profiles/shared/quickshell/shared/Bar/<Name>.qml`
- `Theme.qml` for the color palette and `Bar.qml` for assembly conventions.

## 3. Write the widget

Follow these rules (detailed in the reference):

- Uppercase-first filename; self-contained `Item`/`Rectangle` root.
- `import ".." as Root`; all colors from `Root.Theme` — never hardcode hex.
- Accept `property var panelWindow` if it opens a popup.
- Use a native `Quickshell.Services.*` integration over a `Process` when one exists.
- Popups: `PopupWindow` anchored to `panelWindow`, animate `opacity`/`scale` with
  `Easing.OutCubic`, keep alive during exit via a `hideTimer`, track hover with
  `HoverHandler`, auto-close with a `Timer`.
- Buttons: 24x24 `Rectangle`, `radius: 6`, hover `Root.Theme.surfaceHover`,
  `cursorShape: Qt.PointingHandCursor`.
- Icons: SVGs from `shared/assets/`, referenced as `"../assets/<name>.svg"`.
- Per-screen-unique logic goes in a `pragma Singleton` so it isn't duplicated per
  `Variants` instance.

## 4. Wire it into the bar

Add the widget to the target `Bar.qml` `RowLayout` with `panelWindow: bar` and
`Layout.alignment: Qt.AlignRight | Qt.AlignVCenter`. For louie, place files under a
louie-specific quickshell dir or `profiles/shared/quickshell/shared/Bar/` if shared.

## 5. Verify

- [ ] QML parses (run `qs -p <path>/shell.qml` if quickshell is available; otherwise review by hand).
- [ ] Runtime validation — check logs with `qs log` to catch QML binding errors, missing imports, and service connection issues.
- [ ] No hardcoded colors; all from `Theme`.
- [ ] Popup anchors to `panelWindow`; exit animation handled by `hideTimer`.
- [ ] New widget is referenced in the bar and aligns correctly.

# Reference

- **[documentation/quickshell-reference.md](../../../documentation/quickshell-reference.md)** (MUST READ) — Quickshell concepts + repo conventions
- Shared bar examples: `profiles/shared/quickshell/shared/Bar/*.qml`
- Theme palette: `profiles/shared/quickshell/shared/Theme.qml`
- Official docs: https://quickshell.org/docs/v0.3.0/guide/introduction/

# Documentation

- **[documentation/quickshell-reference.md](../../../documentation/quickshell-reference.md)**: Curated guide — config layout, ShellRoot/Variants, window types, process running, QML essentials, repo widget conventions, available services, and a new-widget checklist.
