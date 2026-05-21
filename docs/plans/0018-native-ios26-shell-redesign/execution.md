# Execution Journal — Plan 0018

Append-only. Dated entries only.

---

## 2026-05-21

Starting implementation. 12 files to change (11 existing + 1 new).
Order: Tab.swift → GuidelineStep → SettingsRow → AppearanceCard → SettingsView
→ DrinkTypeGridView → Dashboard cards (3 files) → AddDrinkButton (new) → RootShellView.
Build + test at the end.

All 12 changes implemented. `BuildProject` MCP: clean. `xcodebuild test`: 127/127 passed.
No files exceed 300 lines. Living docs updated. Retrospective written. Plan complete.

## 2026-05-21 (follow-up)

Post-ship polish in this session:

- **Tab icon fill experiment**: tried unfilled icons + `.environment(\.symbolVariants, .none)` +
  manual filled/unfilled switching tied to `selectedTab`. Builds and runs but icon fill only
  changes when tab is fully active — iOS 26 TabView has no public API to track glass pill
  mid-slide position. Settled on filled variants permanently for all 4 tabs.
- **`tabViewBottomAccessory` experiment**: tried moving Add Drink button to bottom accessory.
  Pill always renders even with empty content; hiding on Settings tab requires conditional
  modifier (identity change risk). Button inside pill cannot be themed like `.borderedProminent`.
  Reverted — stayed with top nav bar `AddDrinkButton`.
- **Settings row height fix**: `SettingsRow`, `guidelineRow`, and system lock button all had
  explicit `.padding(.vertical, 12)` that doubled up with List's native cell padding, making
  rows ~24pt too tall. Removed across all three.
- **Theme swatch tap bug**: `onTapGesture` inside a List cell was unreliable — List gesture
  recognizer intercepted some taps, causing the wrong theme to be applied. Replaced with
  `Button { theme = option } label: { ThemeSwatch(...) }.buttonStyle(.plain)`.
- Build clean, 127/127 tests passing.
