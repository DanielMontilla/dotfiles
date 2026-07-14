# Quickshell Reference

Curated reference for writing Quickshell widgets in this dotfiles repo. Combines the
official Quickshell guide (v0.3.0) with the conventions used by the existing shared bar.

Official docs: https://quickshell.org/docs/v0.3.0/guide/introduction/
Type reference: https://quickshell.org/docs/v0.3.0/types/

## Core concepts

### Config layout

Quickshell searches `quickshell/` under XDG config dirs (usually `~/.config/quickshell`).
Each subfolder with a `shell.qml` is a config. Run a raw file with `qs -p path/to/shell.qml`.
Live-reloads on save.

This repo places configs under `profiles/shared/quickshell/`, symlinked by dotbot. The
entry point is `shell.qml`.

### Root structure

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import "./shared/Bar" as Bar

ShellRoot {
  Variants {
    model: Quickshell.screens
    Bar.Bar { modelData: modelData }
  }
}
```

- `ShellRoot` is the top-level object of `shell.qml`.
- `Variants` creates one instance of its delegate per item in `model`. Used here to
  spawn a bar per screen. The current screen is injected as `modelData`.
- A window type (`PanelWindow`) must be inside `Variants`, so each screen gets its own
  window.
- Shared/expensive state (clocks, process polling) should live outside `Variants` so it
  is not duplicated per screen. Expose it via a `Singleton` or a root property.

### Window types

- `PanelWindow` — docks to an edge and reserves space (bars, widgets, overlays). Anchor
  with `anchors { top: true; left: true; right: true }` and set `implicitHeight`.
- `FloatingWindow` — a normal desktop window that does not reserve space.
- Both accept a `screen` property (set to `modelData` from `Variants`).

### Running processes

Use `Process` + `StdioCollector` from `Quickshell.Io`:

```qml
import Quickshell.Io
Process {
  id: dateProc
  command: ["date"]
  running: true
  stdout: StdioCollector { onStreamFinished: root.time = this.text }
}
```

Re-run on an interval with `Timer { interval: 1000; running: true; repeat: true; onTriggered: dateProc.running = true }`.

Prefer native integrations over shelling out (see Services). For clock text, use
`SystemClock { id: clock; precision: SystemClock.Seconds }` and
`Qt.formatDateTime(clock.date, "format")`.

### QML essentials

- Every file with an UPPERCASE first letter is implicitly a reusable type, usable from
  neighboring files (e.g. `Clock.qml` -> `Clock { }`).
- `pragma Singleton` at the top + `Singleton { }` root makes a file a single global
  instance, accessible by name from anywhere.
- Property bindings are reactive: `width: height` re-evaluates when `height` changes.
- `required property <type> name` forces callers to set it.
- `readonly property` cannot be assigned but stays reactive.
- Signal handlers are `on<Signal>` (first letter capitalized), e.g. `onClicked`.
- Use `Connections { target: ...; function onX() {} }` to connect to signals of an
  object defined elsewhere (commonly a singleton).
- Functions: `function dub(x: int): int { return x * 2 }`. Lambdas: `n => n * 2`.

## Repo conventions (from shared bar)

The shared bar lives in `profiles/shared/quickshell/shared/`. Mirror these patterns for
new louie widgets.

### Theme singleton

`shared/Theme.qml` is a `pragma Singleton` `QtObject` exposing a Catppuccin-like palette
and `fontFamily`. Access as `Root.Theme.<color>` after `import ".." as Root` from widget
files. All colors must come from `Theme` — never hardcode hex values in widgets.

Palette: `background`, `surface`, `surfaceHover`, `overlay`, `text`, `textMuted`,
`primary`, `secondary`, `accent`, `danger`, `warning`, `success`, `fontFamily`.

### Widget file pattern

Each widget is a self-contained file in `shared/Bar/`, e.g. `Volume.qml`, `Battery.qml`.
Canonical shape for an interactive widget:

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import ".." as Root

Item {
  id: root
  property var panelWindow          // passed from Bar.qml for popup anchoring
  property bool menuOpen: false
  property bool popupVisible: false // delayed on close for exit animation
  readonly property int animDuration: 250

  implicitWidth: btn.width
  implicitHeight: btn.height

  // icon/button Rectangle with MouseArea, color from Theme.surfaceHover on hover
  // PopupWindow { anchor.window: panelWindow; ... }
}
```

Rules observed in the existing widgets:
- Icons are SVGs in `shared/assets/` referenced as `"../assets/<name>.svg"`.
- Buttons: `24x24` `Rectangle`, `radius: 6`, hover color `Root.Theme.surfaceHover`,
  `cursorShape: Qt.PointingHandCursor`.
- Popups use `PopupWindow` anchored to `panelWindow` via `anchor { window: panelWindow;
  rect.x/rect.y; edges: Edges.Top | Edges.Left }`.
- Animate with `Behavior on opacity/scale` + `NumberAnimation { duration: animDuration;
  easing.type: Easing.OutCubic }`. Use a `hideTimer` to keep the popup alive during the
  exit animation, then set `popupVisible = false`.
- Track popup hover with `HoverHandler` so it doesn't auto-close while the mouse is
  inside; auto-close with a `Timer`.
- Use `QtQuick.Controls` `Slider`/`Button` where appropriate; style their `background`
  and `handle` to Theme colors.
- Shell out with `Quickshell.execDetached(["sh", "-c", "..."])` for actions (power,
  logout). Currently bar uses `niri msg action quit` for logout — adjust per compositor.

### Bar assembly

`shared/Bar/Bar.qml` is a `PanelWindow` with a `RowLayout` of widgets aligned right.
Each widget exposes `panelWindow: bar` and `Layout.alignment: Qt.AlignRight |
Qt.AlignVCenter`. Add a leading `Item { Layout.fillWidth: true }` as a left spacer.

### Services available (Quickshell modules)

- `Quickshell.Services.UPower` — `UPower.displayDevice`, `UPowerDeviceState.Charging`,
  `percentage`, `state`. See `Battery.qml`.
- `Quickshell.Services.Pipewire` — `Pipewire.defaultAudioSink`, `PwNode`, `PwNodeAudio`
  (`volume`, `muted`), `PwObjectTracker`. See `Volume.qml`.
- `Quickshell.Services.Mpris` — `Mpris`, `MprisPlayer` for media widgets.
- `Quickshell.Services.SystemTray` — `SystemTray`, `SystemTrayItem`.
- `Quickshell.Services.Notifications` — `NotificationServer`.
- `Quickshell.Networking` — `Networking`, `WifiDevice` for wifi widgets.
- `Quickshell.Hyprland` / `Quickshell.I3` / `Quickshell.WindowManager` — workspace and
  window state (only relevant for the matching compositor; louie uses niri).
- `Quickshell.Wayland` — `WlrLayershell`, `IdleInhibitor`, `ToplevelManager`.

### Imports

Prefer `import qs.<path>` (relative to `shell.qml`) or relative `import ".." as Root`
over `root:` imports, which break the LSP and singletons.

## Checklist for a new louie widget

1. Create `<Name>.qml` in `profiles/shared/quickshell/shared/Bar/` (or a louie-specific
   dir). First letter uppercase.
2. `import ".." as Root` and pull colors from `Root.Theme`.
3. If it needs popup UI, accept `property var panelWindow` and use `PopupWindow`.
4. Prefer a native service (UPower/Pipewire/...) over a `Process` where one exists.
5. Add it to `Bar.qml`'s `RowLayout` with `panelWindow: bar` and right alignment.
6. For per-screen-unique data, put the logic in a `Singleton` so it isn't duplicated.
7. Never hardcode colors; animate with `Theme` + `Easing.OutCubic`.
