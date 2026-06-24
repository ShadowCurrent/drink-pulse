# Execution journal — plan 0033

## 2026-06-24 — freeze + phase 1 (code only, no tests)

Plan frozen. User chose phased execution: **code/UI changes first, build the app
target, then user reviews in Xcode canvas before any test work.** Test files
(`DPThemeTests.swift` delete + pbxproj ref, `SettingsUITests` trim) and the full
`xcodebuild test` run are deferred to a later phase after review.

Phase 1 scope handed to an Opus implementation agent:
- DELETE `DPTheme.swift`, `DPTheme+Environment.swift`; NEW `DPBrand.swift`.
- Remove `theme` AppStorage key.
- `drinkpulseApp` / `AddDrinkButton` → `.tint(.dpAccent)`, drop `dpTheme` env.
- `RootShellView` → label-closure tabs with `symbolVariants` fill-on-select,
  bg `Color.dpAccent.opacity(0.04)`.
- `AppearanceCard` → drop swatch row + `ThemeSwatch`, keep mode picker.
- Strings: remove `theme.*` + `settings.appearance.theme`.
- Build `drinkpulse` app target clean (zero warnings). Do NOT touch test
  targets, do NOT run tests.

## 2026-06-24 — fix: blue controls in canvas (empty AccentColor asset)

User review flagged Settings controls (menu-picker chevrons) rendering **blue**
in the Xcode canvas. Root cause (verified via simctl screenshots of the running
app): the **running app is correct/orange** — app-level `.tint(.dpAccent)`
colours all controls. The blue only appears in **previews/canvas**, which do not
inherit `drinkpulseApp`'s `.tint`, and the asset-catalog `AccentColor.colorset`
was **empty at HEAD** (always had been). With the theme swatches removed, the
Appearance section no longer masks the bare blue chevrons, so it became visible.

Fix: populated `Assets.xcassets/AccentColor.colorset` with ember `#FA5D36`
(srgb 0.980 / 0.365 / 0.212). Now the brand accent resolves from the asset
catalog — running app, previews/canvas, and direct `Color.accentColor`
consumers (e.g. `HistoryCalendarDayCell` `fillColor ?? Color.accentColor`
fallback, previously system-blue) all read ember. Runtime `.tint(.dpAccent)`
kept (now reinforcing, harmless). App build clean. User must refresh canvas
(Editor ▸ Canvas resume / ⌥⌘P) to rebuild previews against the new asset.

## 2026-06-24 — SwiftUI-expert nit: collapse to single accent source

Deviation from frozen plan (single source of truth for the brand accent):
- `AccentColor` asset is now the **only** definition of ember.
- `DPBrand.dpAccent` redefined as `Color.accentColor` (named alias for the
  background tint use; no second literal of `#FA5D36`).
- Dropped redundant explicit `.tint(.dpAccent)` from `drinkpulseApp` and
  `AddDrinkButton` — controls + `.borderedProminent` FAB now inherit the asset
  accent. Verified via simctl: FAB + selected tab render ember with no explicit
  tint. Build clean.
The two other review nits were no-ops by design (keep `String(localized:)` per
project convention; keep explicit `symbolVariants .none` on unselected tabs to
force the outline variant).

## 2026-06-24 — fix: Appearance row collapses into menu bubble on tap

User report: tapping the Appearance mode `.menu` picker collapsed the **whole
row/card** into the dropdown bubble. Confirmed by user it happens **only** for
Appearance, not the other menu pickers (Sex / Volume / Alcohol / ABV). Cause:
with the theme-swatch row removed, the Appearance `dpGlassCard` is now a single
row whose bounds ≈ the picker, so the iOS 26 menu-morph anchors to the card's
glass element and collapses it. Multi-row cards keep the picker as a small
sub-region, so they don't exhibit it.

Fix (scope: `AppearanceRows` only): replaced the `.menu` picker with a
`.segmented` picker (System / Light / Dark) rendered full-width in the card
(section header labels it; `accessibilityLabel` added). Segmented presents
inline — no menu, no morph. Verified via simctl: clean inline 3-segment
control, "Light" selected. Build clean.

UPDATE: user rejected the segmented look ("looks like tabs, not clean"), wants
the original `.menu` dropdown on a single row. Reverted to `.menu` +
`.labelsHidden()` and added `.fixedSize()` to pin the picker to its intrinsic
capsule (hypothesis: in the single-row card the picker's source frame stretched,
so the menu morph scaled the whole row; `.fixedSize()` constrains it). Static
layout verified via simctl — matches the other dropdown rows. Morph behaviour is
tap-only, pending user verification (no computer-use available this session).
Existing `SettingsUITests.test_appearanceMode_reflectsSelectedOption` (.menu
"Appearance, System") stays valid — no rewrite needed.

UPDATE 2: `.fixedSize()` did NOT fix the morph (it anchors to the card's glass,
not the picker frame). Per user direction, fixed structurally instead of
fighting the morph: **eliminate single-row menu cards**. Moved the mode row out
of its own section into the multi-row PREFERENCES card (now: Appearance, Volume
unit, Alcohol unit, ABV precision). A `.menu` morph in a multi-row card anchors
to the picker row, not the whole card — matching the other working pickers.
- Renamed `AppearanceRows` → `AppearanceModeRow` (single row, no longer a
  section); dropped `.fixedSize()`; updated preview.
- `SettingsView`: removed the standalone APPEARANCE `SettingsSection`; inserted
  `AppearanceModeRow()` + `Divider()` at the top of PREFERENCES.
- Per user: GUIDELINE stays a single-row card (Button→sheet, no morph). App Lock
  likewise unchanged.
Build clean; layout verified via simctl. Morph fix is tap-only — pending user
verification.
Phase-2 cleanup: `settings.section.appearance` xcstrings key is now unused →
remove it alongside the other theme strings.

## 2026-06-24 — phase 2 complete (tests + docs); plan CLOSED

- Deleted `drinkpulseTests/DPThemeTests.swift` and stripped its 4 refs from
  `project.pbxproj` (PBXBuildFile, PBXFileReference, group child, Sources phase).
- `SettingsUITests`: removed `test_themeSwitch_selectsTappedSwatch` + its doc
  bullet; `test_appearanceMode_reflectsSelectedOption` kept (.menu unchanged).
- Strings: removed `settings.section.appearance` (last theme-related key; the
  `theme.*` + `settings.appearance.theme` keys were already removed in phase 1).
- Full `xcodebuild test`: **480 tests, 0 failures, TEST SUCCEEDED.** App coverage
  93.81%; no file >300 lines; zero warnings; no residual theme refs in source.
- Living docs updated: product.md, roadmap.md (plan-0008 superseded + 0033 done),
  current-focus.md, DEVLOG.md, INDEX.md (→ completed). retrospective.md created.
- `dp_theme` orphan UserDefaults key intentionally left (harmless dead key).

Plan complete.
