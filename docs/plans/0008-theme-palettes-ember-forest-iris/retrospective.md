# 0008 — Retrospective

**Completed**: 2026-05-20
**Status**: completed

## What was built

`DPTheme` enum (Ember / Forest / Iris) with pre-converted sRGB constants for
`primary`, `gradientStart`, `gradientEnd`, and a computed `gradient:
LinearGradient`. Environment key (`@Entry var dpTheme`) for prop-drill-free
access. Root injection in `drinkpulseApp.swift` via `@AppStorage` for
persistence and `.tint(theme.primary)` for system-wide propagation. Settings
Appearance section: 3-swatch gradient theme picker + system/light/dark mode
picker.

## What changed vs the plan

**Scope narrowed during planning (correct call):** original idea included
tinting card backgrounds; scoped out before freeze because it fights iOS 26
Liquid Glass. System `.tint()` propagation handles all glass surfaces
automatically — explicit surface tinting would break the native look.

**SettingsRow extracted:** `SettingsView.swift` would have crossed 300 lines
with the Appearance section added. `SettingsRow` (previously `private`) was
moved to `Features/Settings/Components/SettingsRow.swift` so `AppearanceCard`
could reuse it without coupling.

## What worked well

- **oklch → sRGB conversion once at design time.** Storing inline Swift
  constants means zero runtime colour-space overhead and dead-simple testing.
- **Root `.tint()` propagation.** One call at `WindowGroup` level tints every
  iOS 26 glass surface, nav bar, control — no per-view work needed.
- **`@Entry` syntax** (Swift 5.10) is cleaner than the old `EnvironmentKey`
  boilerplate and requires no separate default-value struct.

## What could be better

- oklch conversion was done manually via a Python script — could build a
  small `oklch_to_srgb.py` utility in `tools/` for future palette additions.
- Gradient direction (topLeading → bottomTrailing) was guessed from the
  design HTML rather than explicitly specified. Looks correct but is an
  assumption worth confirming if the design gets iterated.

## Tests

6 tests in `DPThemeTests.swift`: primary distinct per case, gradient endpoints
distinct per case, rawValue round-trip, invalid rawValue → nil, displayName
non-empty, allCases count == 3. All 127 project tests pass.
