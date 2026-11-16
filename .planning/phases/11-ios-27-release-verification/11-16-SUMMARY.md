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
  - Add Drink AX5 layout: step 1 green; step 2 red pending owner decision (see Task 3 state)
plan_head_before: db56ae61b357d9b55a5fe71e4893495015e55d8f
commits: 4
requirements-completed: []
---

# Phase 11 Plan 16: AX5 layouts for Home, Insights, Add Drink, Settings, Onboarding (PARTIAL)

PARTIAL SUMMARY written at the declared mid-plan context boundary. Tasks 1 and 2 are done and green. Task 3 is committed as a WIP (production layout in place, AX5 UI tests red). Tasks 4 to 6 are not started. The continuation agent finishes Task 3, then runs Tasks 4 to 6, and rewrites this file as the final SUMMARY.

## Done

| Task | Commit | Result |
| ---- | ------ | ------ |
| 1 Home tracer | 03faebd | `DashboardDynamicTypeUITests` 2 passed; `DashboardUITests` + `ReduceMotionDashboardUITests` 9 passed; `DPMotionTests` 7 passed |
| 2 Insights | 328d210 | `InsightsDynamicTypeUITests` 2 passed; Insights flow classes 11 passed (DL-T01 passed, no retry needed); unit suites 71 passed |
| 3 Add Drink (WIP) | 52040c7, next WIP commit | step 1 AX5 green, step 2 AX5 red (owner decision); flows 15 passed; DrinkDetailInputMathTests 14 passed; 0 warnings |

Evidence files (stamp directory, out of git): `ax5-t1-home|dashboard|motion|unit.result.txt`, `ax5-t2-ax5|insights|unit.result.txt`. They hold the MCP counts line transcribed from each Xcode MCP RunSomeTests result.

## Task 3 state: owner decision needed (system-owned controls in a Form)

Step 1 (tiles, Cancel) passes the AX5 audit. Step 2 does not, and app-side layout changes cannot clear it. Final committed state (flows 15 passed, `DrinkDetailInputMathTests` 14 passed, build 0 warnings):

- Cancel and Save leave the navigation bar at accessibility sizes (the bar does not scale its buttons) and move to a `safeAreaBar(edge: .bottom)` with wrapping buttons (`SheetActionsModifier` in `DrinkTypeGridView.swift`). Both audit findings for Cancel and Save are gone. Trade-off: the two stacked buttons use about a third of the AX5 screen.
- Volume, Strength and Amount are stacked `.navigationLink` picker rows at accessibility sizes (wheel branch unchanged at regular sizes). The text wraps and is readable.

Remaining audit keys on `Add Drink step 2` (distinct, `LC_ALL=C sort | uniq -c`), the scrolling helper repeats each on later pages:

| Key | Type | Notes |
| --- | ---- | ----- |
| `element=Volume`, `element=Amount` (Strength on some runs) | `dynamicType` ("font sizes partially unsupported") and `textClipped` | Picker rows in the Form; reported on whichever row is partly at the viewport edge |
| `element=none#type=nil` (6 to 14 per run) | `textClipped` (and `dynamicType` in some variants) | no element, no frame: UIKit-hosted internals of the Form (candidates: compact `DatePicker`, vertical-axis notes `TextField`, currency `Menu`); not locatable from the issue |

Experiments that did not clear them (all with the same classes of finding): `.menu` picker (original), `.navigationLink`, custom `Menu` rows with explicit `.font(.body)` (then the plain `Text` inside the menu label was flagged too), `safeAreaInset` versus `safeAreaBar`, Cancel/Save as Form rows (a plain `Button` in a Form row was flagged `dynamicType` + `textClipped`), single-line price field. Removing the date picker and notes field changed the `nil` count but did not remove it. Pattern: interactive controls (Picker, Menu, Button, DatePicker, TextField internals) inside a `Form` are flagged at AX5 even with only default text styles; the same text outside a Form (Home, Insights, step 1 tiles, bottom-bar buttons) passes. Settings Preferences (Task 4, `Form` with menu pickers) and the Edit Drink sheet are expected to hit the same class.

The plan requires stopping here and reporting key, type and options to the owner; nothing was muted or allow-listed.

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

Added 2026-11-16 (Task 3 continuation):

| Page | Facts used | Rationale |
| ---- | ---------- | --------- |
| SwiftUI `GridItem`, `GridItem.Size.adaptive/flexible` | adaptive packs as many items as fit between minimum and maximum; flexible is one column | one flexible column at accessibility sizes |
| SwiftUI `PickerStyle` `wheel`, `segmented`, `menu` (`navigationLink` listed in the PickerStyle family; its own page did not come back from search) | wheel shows neighbours only; segmented suits 2 to 5 options | `.navigationLink` rows at accessibility sizes |
| SwiftUI `safeAreaBar(edge:alignment:spacing:content:)` (VerticalEdge) | custom bar above or below the view, insets the safe area and extends the scroll edge effect; "similar to `safeAreaInset(edge:alignment:spacing:content:)`" (that page did not come back directly; reached through the `safeAreaBar` page) | Cancel and Save bottom bar at accessibility sizes |
| SwiftUI `ScrollView`, `scrollBounceBehavior(_:axes:)`, `ScrollBounceBehavior.basedOnSize` | `basedOnSize` bounces only when content exceeds the view | for Onboarding steps (Task 4) |
| XCUIAutomation `XCUIAccessibilityAuditType` (`dynamicType`, `textClipped`), `XCUIAccessibilityAuditIssue` (`element`, `compactDescription`, `detailedDescription`) | `element` is optional | explains the `none#type=nil` key; `XCUIApplication.performAccessibilityAudit` page itself was not returned by search (11-15 could not retrieve it either); signature follows the existing compiled use |

## Deviations from Plan

None that change scope. The Home hero value and Insights pill fonts were adjusted after the audit rejected the first choices (see Lessons). Task 3 audit failures are the system-owned toolbar buttons case the plan anticipates ("stop and report if an app-side change cannot remove it"); see Open items.

## Self-Check: PARTIAL

Commits 03faebd, 328d210 and 52040c7 exist. Plan-level guards run so far: schema guard exit 0, no production file over 300 lines, 0 numeric fixed point-size fonts under Dashboard and Insights/Components, chart accessibility descriptor files unchanged against fc506f4.
