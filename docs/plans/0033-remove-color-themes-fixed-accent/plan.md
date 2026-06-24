# Plan 0033 — Remove color themes; fixed ember accent; selection-driven tab symbol fill

Status: in-progress
Frozen: 2026-06-24
Size: medium
Owner: Dawid
Created: 2026-06-24

## Problem

The app ships a 3-colour theme system (Ember / Forest / Iris, plan-0008).
It adds configuration surface and code (enum, environment value, `@AppStorage`
key, Settings swatch row, tests, strings) for little product value. We want a
single fixed brand accent (Ember orange) everywhere and to drop the picker.

Separately, the tab bar hardcodes filled SF Symbols (`house.fill`, …), so every
tab icon is always filled. On iOS 26 the selected tab sits under the Liquid
Glass "pile" slider; we want the icon to read as **outline normally and filled
only under the pile** (i.e. when selected), driven by `symbolVariants`.

## Decisions (confirmed with user)

1. **Remove the 3-colour theme picker.** Replace `DPTheme` with one fixed brand
   accent = Ember orange `#FA5D36`.
2. **Keep** the Light / Dark / System mode picker in Settings → Appearance.
3. **Orange everywhere**: app-wide `.tint(.dpAccent)` (not just Add-Drink).
4. **Tab icons**: base symbol variant `.none` (outline); `.fill` only for the
   selected tab, via `.environment(\.symbolVariants, selected ? .fill : .none)`
   on each `Tab` label.

## Scope / file-by-file

### Remove theme system
- DELETE `DesignSystem/DPTheme.swift` (enum + gradients + displayName).
- DELETE `DesignSystem/DPTheme+Environment.swift` (`@Entry var dpTheme`).
- NEW `DesignSystem/DPBrand.swift`:
  ```swift
  import SwiftUI
  extension Color {
      /// App-wide brand accent (Ember). Drives `.tint` and tinted backgrounds.
      static let dpAccent = Color(red: 0.980, green: 0.365, blue: 0.212) // #FA5D36
  }
  ```
- EDIT `DesignSystem/AppStorageKeys.swift`: remove `theme` key. Keep
  `onboardingDone`, `colorScheme`.

### Wire the fixed accent
- EDIT `drinkpulseApp.swift`:
  - remove `@AppStorage(...theme)` and `.environment(\.dpTheme, theme)`.
  - `.tint(theme.primary)` → `.tint(.dpAccent)`.
  - keep `colorScheme` / `preferredColorScheme` untouched.
- EDIT `Features/Shell/Components/AddDrinkButton.swift`: drop
  `@Environment(\.dpTheme)`; `.tint(theme.primary)` → `.tint(.dpAccent)`.

### Tab bar: outline-normal, fill-under-pile
- EDIT `Features/Shell/RootShellView.swift`:
  - drop `@Environment(\.dpTheme)`; background
    `theme.primary.opacity(0.04)` → `Color.dpAccent.opacity(0.04)`.
  - rewrite each `Tab(title, systemImage: "x.fill", value:)` into the label
    closure form using base (non-`.fill`) symbols and the variant toggle:
    ```swift
    Tab(value: AppTab.home) {
        NavigationStack { DashboardView().toolbar { … AddDrinkButton … } }
    } label: {
        Label(String(localized: "tab.home"), systemImage: "house")
            .environment(\.symbolVariants, selectedTab == .home ? .fill : .none)
    }
    ```
    Symbols: home `house`, insights `chart.bar`, history `clock`,
    settings `gearshape`. Keep `value:`, `selection:`, the per-tab
    `AddDrinkButton` toolbar item, the sheet, sensoryFeedback, and the
    `onChange(profiles.isEmpty)` reset exactly as-is.

### Settings
- EDIT `Features/Settings/Components/AppearanceCard.swift`:
  - remove `@AppStorage(...theme)`, the `settings.appearance.theme`
    `SettingsRow`, and the entire `ThemeSwatch` struct.
  - keep the `settings.appearance.mode` picker (System/Light/Dark) unchanged.
  - keep the section (`settings.section.appearance`) — it still holds the mode
    picker.

### Tests
- DELETE `drinkpulseTests/DPThemeTests.swift` **and** remove its entry from the
  `drinkpulseTests` Sources build phase in `project.pbxproj` (that target is a
  plain PBXGroup, not FS-synced — orphaned ref breaks the build).
- EDIT `drinkpulseUITests/SettingsUITests.swift`:
  - delete `test_themeSwitch_selectsTappedSwatch` and its doc bullet.
  - keep `test_appearanceMode_reflectsSelectedOption` (mode picker stays).
- No new unit test for `Color.dpAccent` (a constant, no logic).
- Tab symbol-variant is view-layer presentation (excluded from unit coverage;
  XCUITest cannot read SF Symbol variant). It is preview-verified. The existing
  tab-navigation UI tests still prove the tabs switch.

### Strings (`Localizable.xcstrings`)
- REMOVE keys: `theme.ember`, `theme.forest`, `theme.iris`,
  `settings.appearance.theme`.
- KEEP: `settings.section.appearance`, `settings.appearance.mode`,
  `settings.appearance.mode.system|light|dark`.

### Living docs
- `docs/product.md` L59–60: drop "Theme palettes" from shipped list (or note
  removed in 0033); reminders line stays.
- `docs/roadmap.md`: move theme palettes to a removed/superseded note
  referencing plan-0033; keep light/dark mode as shipped.
- `.claude/context/current-focus.md`: update focus to this change.
- `README.md`: only if it lists themes as a feature (verify; update if so).
- DEVLOG entry; INDEX.md row; retrospective.md on completion.
- Memory `reference_claude_design_handoff` / design notes: optional note that
  multi-theme palette was dropped.

## Out of scope
- Light/Dark/System mode (kept).
- Add-Drink button shape/placement (unchanged; only colour source changes).
- Any gradient reintroduction (FAB uses solid tint already).

## Verification
- `xcodebuild build` clean, zero warnings.
- `xcodebuild test` green (unit + UI). Confirm removed UI test no longer runs
  and `test_appearanceMode_reflectsSelectedOption` still passes.
- Coverage ≥90% overall / per-layer (no testable logic added; domain unaffected).
- File-size find: no file >300 lines.
- Manual/preview: Settings shows only the mode picker; tab icons outline when
  unselected, filled when selected; Add-Drink + controls are ember orange.

## Rollback
Pure UI/config removal, additive-reversible: restore `DPTheme*` files,
`theme` AppStorage key, swatch row, strings, and the `.fill` tab symbols.
No schema change, no data migration.
