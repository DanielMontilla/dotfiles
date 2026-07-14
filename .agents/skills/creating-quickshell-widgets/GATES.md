## Phase 1: Widget Structure

- [ ] New widget is a self-contained QML file with an uppercase-first name
- [ ] File root imports `import ".." as Root` (or appropriate relative import) and the needed Quickshell modules
- [ ] Widget accepts `property var panelWindow` if it renders a popup

## Phase 2: Theming & Style

- [ ] No hardcoded hex colors; every color references `Root.Theme.<color>`
- [ ] Buttons (if any) follow 24x24 `Rectangle`, `radius: 6`, hover `Root.Theme.surfaceHover`, `Qt.PointingHandCursor`
- [ ] Icons reference `../assets/<name>.svg` SVGs, not inline paths

## Phase 3: Popups (if applicable)

- [ ] `PopupWindow` anchors to `panelWindow` via `anchor { window: panelWindow; ... }`
- [ ] Exit animation handled: `popupVisible` delayed by a `hideTimer` so the close animation plays
- [ ] Popup hover tracked with `HoverHandler`; auto-close via a `Timer`
- [ ] Animations use `Easing.OutCubic`

## Phase 4: Integration

- [ ] Widget added to the target bar `RowLayout` with `panelWindow: bar` and right alignment
- [ ] Native `Quickshell.Services.*` integration used where one exists instead of a `Process`
- [ ] Per-screen state (if any) lives in a `pragma Singleton` rather than duplicated per `Variants` instance
