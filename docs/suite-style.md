# Halo suite style guide (Calculator, Clock, Calendar, Notes, Contacts, Reminders, Weather)

Reference look: **Files / Gallery** and the Settings app. Anyone (human or Beam) adding or changing a suite app follows this; run `python3 scripts/suite-lint.py` before shipping.

## Rules
1. Window = `SuiteWindow` (`apps/suite/`). Never a bare `FloatingWindow`/`AppWindow` in suite apps. It gives: 64 px title row (round back + close pills, `actions: [ ... ]` on the right) and ONE rounded content panel (radius 32, `AppTheme.low`, 8 px inset). Keep >= 16 px between your content and the panel edge (rounded corners).
2. Colours only from `AppTheme` (`bg low card cardHigh accent accentSoft accentInk text dim line hover danger`, `AppTheme.tint(a)`). No hex, no `"white"`, no `Qt.rgba(1,1,1,..)`. Every `Text` sets `color` (default is black).
3. Icons only from `common/Ic.qml` via `Ico { name: ... }` or `icon:` props. No emoji, no unicode glyph icons (no `✕ ✓ ‹ 🗑 ⌫`). A missing icon: add a path to `Ic.qml` (48 grid, rounded stroke 2.6) and look at it before shipping.
4. Shapes: controls are pills (height 44, radius = height / 2); rows and cards radius 22; big cards / editor surfaces radius 28-32. Never radius < 10.
5. Touch: every tappable thing >= 44 px; list rows >= 68 px; spacing 8 between rows, 12 between groups.
6. Motion: press = `scale 0.94..0.98` with `NumberAnimation { duration: 140; easing.type: Easing.OutBack }`; colour changes 90-120 ms. Nothing slower than 200 ms.
7. Type: title 24 DemiBold, row title 17, subtitle 13 `dim`, section label 13 DemiBold `dim` (`Sect`), big numbers Light (`font.weight: Font.Light`).
8. States: every list has an empty state (`Empty { icon; text }`, `anchors.centerIn: parent`); loading and error use the same component.
9. Narrow windows (< 720 px, tablet split): two-pane apps show one pane and use `canBack` / `onBackClicked` (see `notes.qml`).
10. Light theme works automatically through `AppTheme` (reads `~/.config/halo/scheme.json`). Do not special-case it.
11. QML gotchas: no anchors on children of `Row/Column/Grid/Flow` (wrap in an `Item`); `anchors { ... };` is illegal; method names start lowercase; ids are file-global; a `Flow` instead of a `Row` when pills can wrap.

## Components (`apps/suite/`, import `qs.suite`; `Pill`, `Ico`, `AppTheme` come from `qs.common`)
| Component | Use |
|---|---|
| `SuiteWindow` | window shell: `title`, `heading`, `canBack`, `actions`, default content |
| `ListRow` | list row: `title subtitle icon letter selected tappable titleSize dimTitle strike subtitleColor`, `lead: [ item ]`, children = trailing controls |
| `Badge` | round accent badge with icon or letter (`diameter`) |
| `Seg` | segmented tabs `model: [{label, value}]`, `current`, `onPicked: value => ...` |
| `Field` | single-line input (`icon`, `placeholder`, `text`, `onAccepted`) |
| `Check` / `Tog` | round check (reminders) / iOS switch |
| `Sect` | small section label |
| `Empty` | empty/loading state |
| `Sheet` | modal dialog (`open`, `title`, `onClosed`, children stack vertically, scrolls) |
| `Ring` | circular progress (timer), children go in the middle |
| `AnalogClock` | clock face (`time`) |
| `Center` | centres a row of pills; `JsonStore` persists JSON |

## Checklist before shipping a suite change
- [ ] `python3 scripts/suite-lint.py` prints OK
- [ ] looked at it dark AND light (`Settings > Wallpaper & style`)
- [ ] window at 560 px wide and at ~1000 px wide, with keyboard up (596 px tall)
- [ ] empty list, one item, many items
- [ ] touch-only: nothing needs hover or right click
