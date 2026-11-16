---
phase: 11-ios-27-release-verification
plan: 16
subsystem: accessibility
tags: [dynamic-type, ax5, layout, xcuitest, gap-closure, g-2, partial]
status: in-progress
requires: [11-15]
provides:
  - DPAdaptiveStack shared adaptive layout
  - Home and Insights readable at AX5 with AX5 audit UI tests (green)
  - Add Drink AX5 layout and AX5 UI tests (still red, see Open items)
plan_head_before: db56ae61b357d9b55a5fe71e4893495015e55d8f
commits: 3
requirements-completed: []
---

# Phase 11 Plan 16: AX5 layouts for Home, Insights, Add Drink, Settings, Onboarding (PARTIAL)

PARTIAL SUMMARY written at the declared mid-plan context boundary. Tasks 1 and 2 are done and green. Task 3 is committed as a WIP (production layout in place, AX5 UI tests red). Tasks 4 to 6 are not started. The continuation agent finishes Task 3, then runs Tasks 4 to 6, and rewrites this file as the final SUMMARY.

## Done

| Task | Commit | Result |
| ---- | ------ | ------ |
| 1 Home tracer | 03faebd | `DashboardDynamicTypeUITests` 2 passed; `DashboardUITests` + `ReduceMotionDashboardUITests` 9 passed; `DPMotionTests` 7 passed |
| 2 Insights | 328d210 | `InsightsDynamicTypeUITests` 2 passed; Insights flow classes 11 passed (DL-T01 passed, no retry needed); unit suites 71 passed |
| 3 Add Drink (WIP) | 52040c7 | builds with 0 warnings; AX5 tests red (below); flow classes NOT yet run |

Evidence files (stamp directory, out of git): `ax5-t1-home|dashboard|motion|unit.result.txt`, `ax5-t2-ax5|insights|unit.result.txt`. They hold the MCP counts line transcribed from each Xcode MCP RunSomeTests result.

## Open items for Task 3 (resume point)

Latest `AddDrinkDynamicTypeUITests` run (both tests failed). Distinct audit keys, from the MCP summary file (`LC_ALL=C sort | uniq -c`):

- Step 1 (tiles): ONLY `type=dynamicType element=Cancel` on every viewport page. The tile grid itself is clean (no textClipped, no dynamicType). 
- Step 2: `dynamicType` on `Cancel` and `Save` (every page), `dynamicType` and `textClipped` on the three serving menu pickers `Volume`, `Strength`, `Amount`, and 2 x `textClipped element=none#type=nil` on page 3 (an unlabeled element, probably the date picker or the notes/price rows; locate it by its frame in the failure text).

Analysis:
1. `Cancel` and `Save` are the sheet's navigation-bar toolbar buttons (`DrinkDetailInputView` toolbar items and the equivalent `AddDrinkView` Cancel). The nav bar does not scale their text at AX5, so an app-side font change cannot clear the finding. The C016 scope names "Add Drink steps 1 and 2 (drink-type tiles, Cancel button)", so fixing it is in scope. Intended approach (not yet tried): at `isAccessibilitySize`, move Cancel (step 1 and 2) and Save (step 2) out of the toolbar into `safeAreaInset(edge: .bottom)` buttons with Dynamic Type text, keep the same `String(localized:)` keys ("action.cancel", "action.save") so `app.buttons["Cancel"|"Save"]` queries and the flow UI tests still resolve. If that does not clear the finding, stop and report key, type and options (retain, or replace the element) to the owner per the plan; do not mute.
2. The three `.menu` pickers in the Form (accessibility branch of `DrinkDetailInputView.servingMenuPickers`) are flagged. Try a `Menu { Picker ... } label: { ... }` or `LabeledContent` with a wrapping value, or `pickerStyle(.navigationLink)`, then re-run. Keep the wheel branch untouched for regular sizes.
3. Find the `none#type=nil` element on page 3 (read frame from the full MCP summary file) before choosing a fix.

After the audit is green: run the Task 3 verify runs (`AddDrinkFlowUITests`, `AddDrinkPickerFilterUITests`, `CurrencyUITests`, `CustomNameAutocompleteUITests`, `VolumeServingUITests`, `EditVolumeIntegrityUITests`, `DuplicateEditPersistenceUITests`, `DrinkDetailInputMathTests`), save `ax5-t3-ax5|flows|unit.result.txt`, run the guards, commit.

## Lessons for the continuation (audit behavior)

- The `dynamicType` audit flagged `Text` with `.font(.title.bold())`/`.title2.bold()` (+ `.fontDesign(.rounded)`, `.minimumScaleFactor`) on the Home hero value, and `.font(.caption2.bold())` on the Insights "NOW" pill, while `.title3.bold()` and `.caption.weight(.bold)` passed in the same places. The cause was not isolated; the passing combinations are in the code. When an AX5 audit flags a text view that already uses a text style, try a neighboring text style before restructuring.
- The scrolling helper reports a finding for an element on every page after it first appears (the audit sees off-screen elements), so one issue shows up as up to 6 failures.
- Previews: literal strings in previews and accessibility modifiers can be auto-extracted into `Localizable.xcstrings`. `git status` after each build showed no catalog change so far; keep checking. `DPAdaptiveStack` preview uses `Text(verbatim:)` for that reason.
- Run output of unit-suite MCP runs is very large (71 tests); keep runs scoped.

## Design notes so far

- `DPAdaptiveStack` (new, `drinkpulse/DesignSystem/DPAdaptiveStack.swift`): `AnyLayout` of `HStackLayout` at regular sizes and `VStackLayout` at `isAccessibilitySize`; parameters `verticalAlignment`, `horizontalAlignment`, `spacing`.
- Visual changes at regular sizes (flag for the owner): Insights hero total 40 pt fixed becomes `largeTitle` (34 pt); the "NOW" pill 9 pt becomes `caption` bold; Home hero value stays `largeTitle` rounded (was 36 pt fixed), the arc percentage is `callout` rounded bold.
- Home "This Week" chart hides percentage annotations at accessibility sizes (seven bars too narrow); chart is `accessibilityHidden` and the same data is on the other cards.
- Insights weekday chart shows weekday initials at accessibility sizes; period control becomes a menu picker at accessibility sizes.
- Add Drink tiles are full-width rows at accessibility sizes and the grid is one column; serving wheels (scaled with `ScaledMetric`) become stacked menu pickers at accessibility sizes; price and custom-name fields use a vertical-axis `TextField` at accessibility sizes only.

## Apple API record (so far)

Read with Xcode MCP `DocumentationSearch` on 2026-11-16:

| Page | Facts used | Rationale |
| ---- | ---------- | --------- |
| SwiftUI `DynamicTypeSize` | "Read this value from the environment to adapt a layout"; `isAccessibilitySize` is the check "when you want to change a layout for those sizes without comparing sizes yourself" | layout switch in `DPAdaptiveStack` and views |
| SwiftUI `ScaledMetric` | dynamic property that scales a numeric value | icon widths, chart and wheel sizes |
| SwiftUI `AnyLayout`, `HStackLayout`, `VStackLayout` | switch layout type without losing subview state; example switches on Dynamic Type | `DPAdaptiveStack` |
| SwiftUI `ViewThatFits` | picks the first child that fits | read; not needed (explicit `isAccessibilitySize` branches used) |
| SwiftUI `View.lineLimit(_:)`, `fixedSize(horizontal:vertical:)` | `lineLimit(nil)` means no limit; `fixedSize` counter-proposes the ideal size | wrapping instead of truncating; wrapping labels in rounded badges |
| Charts `AxisValueLabel`, `AxisValueLabelCollisionResolution` | `collisionResolution` parameter with `.automatic`, `.disabled`, `.greedy`, `.truncate` | Home chart uses `.greedy` at accessibility sizes; weekday chart uses initials instead |

Not yet looked up (do before the screens that use them): `GridItem` (adaptive and flexible; used in Task 3 grid and Task 2 grid without a page read), Picker styles (menu, wheel, navigationLink), `ScrollView`, `safeAreaInset(edge:alignment:spacing:content:)`, `XCUIApplication.performAccessibilityAudit` (11-15 could not retrieve the page either; signature follows existing compiled use).

## Deviations from Plan

None that change scope. The Home hero value and Insights pill fonts were adjusted after the audit rejected the first choices (see Lessons). Task 3 audit failures are the system-owned toolbar buttons case the plan anticipates ("stop and report if an app-side change cannot remove it"); see Open items.

## Self-Check: PARTIAL

Commits 03faebd, 328d210 and 52040c7 exist. Plan-level guards run so far: schema guard exit 0, no production file over 300 lines, 0 numeric fixed point-size fonts under Dashboard and Insights/Components, chart accessibility descriptor files unchanged against fc506f4.
