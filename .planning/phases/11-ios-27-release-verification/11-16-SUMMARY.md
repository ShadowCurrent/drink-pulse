---
phase: 11-ios-27-release-verification
plan: 16
subsystem: accessibility
tags: [dynamic-type, ax5, layout, xcuitest, gap-closure, g-2, partial]
status: in-progress
requires: [11-15]
provides:
  - DPAdaptiveStack shared adaptive layout
  - Home, Insights, Add Drink (steps 1 and 2), Settings Preferences and Onboarding readable at AX5 with AX5 audit UI tests (all green)
  - narrow owner-approved audit exemption for system Form controls on Add Drink step 2 (D11-28)
plan_head_before: db56ae61b357d9b55a5fe71e4893495015e55d8f
plan_head_after: 1dd99a5d271edcdc4377fefd5aef40a84a5af763
commits: 7
requirements-completed: []
---

# Phase 11 Plan 16: AX5 layouts for Home, Insights, Add Drink, Settings, Onboarding (INTERIM, Tasks 5 and 6 pending)

INTERIM SUMMARY written at the Task 5 owner checkpoint. Tasks 1 to 4 are done, committed and green. Task 5 (owner re-observation of CHK-07 at AX5) is awaiting the owner. Task 6 (record the result, delete the clone) is the next continuation. The continuation rewrites this file as the final SUMMARY with `actuals` and a re-measured `commits` / `plan_head_after`.

## Done

| Task | Commit | Result |
| ---- | ------ | ------ |
| 1 Home tracer | 03faebd | `DashboardDynamicTypeUITests` 2 passed; `DashboardUITests` + `ReduceMotionDashboardUITests` 9 passed; `DPMotionTests` 7 passed |
| 2 Insights | 328d210 | `InsightsDynamicTypeUITests` 2 passed; Insights flow classes 11 passed (DL-T01 passed, no retry); unit suites 71 passed |
| 3 Add Drink steps 1 and 2 | 52040c7, 052e352 (WIP), ae4a667 (exemption + green test) | `AddDrinkDynamicTypeUITests` 2 passed (step 2 with the D11-28 exemption); seven flow classes 15 passed; `DrinkDetailInputMathTests` 14 passed |
| 4 Settings and Onboarding | 1dd99a5 | `SettingsDynamicTypeUITests` + `OnboardingDynamicTypeUITests` 6 passed (no exemption); Settings, Guideline picker, AppVersion, five Onboarding classes and `CurrencyUITests` 19 passed; History, Dashboard, Insights, AddDrink AX5 classes 7 passed; build 0 warnings; 0 diagnostics on the changed files; no file over 300 lines; 0 numeric fixed-size fonts under Dashboard, Insights/Components, AddDrink, Onboarding; schema guard exit 0 |
| (partial summary) | c2c5410 | earlier interim summary |

Evidence files (stamp directory, out of git): `ax5-t1-*`, `ax5-t2-*`, `ax5-t3-*`, `ax5-t4-ax5|flows|prior.result.txt`. They hold the MCP counts line per run.

## Deviations from Plan

### Owner-approved exception to the "no allow-list" rule (D11-28)

- **Found during:** Task 3 (Add Drink step 2)
- **Issue:** inside a SwiftUI `Form`, the Picker, Menu, Button, DatePicker and TextField internals are flagged `dynamicType` ("font sizes partially unsupported") and `textClipped` at AX5 even with only default text styles; the same text outside a Form (Home, Insights, step 1 tiles, bottom-bar buttons, Settings ScrollView) passes. Findings left on step 2: `element=Volume`, `element=Amount` (`Strength` on some runs) and `element=none#type=nil` (6 to 14 per run, no element, no frame).
- **Six approaches that did not clear them:** `.menu` picker, `.navigationLink` picker, custom `Menu` rows with explicit `.font(.body)`, `safeAreaInset` versus `safeAreaBar`, Cancel and Save as Form rows, single-line price field (removing the date picker and notes field changed the element-less count but not to zero).
- **Decision (owner, 2026-11-16, D11-28):** retain as a narrow documented exception. Implemented as an explicit per-call `exemptElementKeys` parameter on `assertNoAuditIssuesWhileScrolling` / `assertNoAuditIssues` in `AccessibilityAuditSupport.swift`, passed only by the Add Drink step 2 test with the keys `Volume`, `Strength`, `Amount`, `none#type=nil`, applied to `dynamicType` and `textClipped` only (a contrast, hit-region or description finding is never exempt). The test attaches the exempt count. Every other finding on that screen and every finding on any other screen still fails.
- **Kept app-side improvements:** Cancel and Save in a bottom `safeAreaBar` at accessibility sizes (the navigation bar does not scale its buttons), `.navigationLink` picker rows at accessibility sizes.
- **Files:** `AccessibilityAuditSupport.swift`, `AddDrinkDynamicTypeUITests.swift`; records in `11-CONTEXT.md` (D11-28), `11-DECISION-C016.md` (Exception record), `11-DEBT-LEDGER.md` (DL-O17, open known limitation).
- **Commit:** ae4a667 (decision records and tests), 1dd99a5 (outcome notes, ledger row)

### Settings did not need the exemption

Settings is a `ScrollView` with menu pickers, not a `Form`; its AX5 audit passed without any exemption. The audit does not see the real defect the owner observed (the system menu-picker button clips a value that wraps), so it was fixed app-side (`SettingsMenuPicker`, below) and the owner judges it by eye.

### Onboarding paged TabView (app-side finding, not an exemption)

Inside `TabView(.page)` the Dynamic Type audit flags every text (title, body, button) as "font sizes partially unsupported" at AX5; moving content to a ScrollView or a bottom bar did not change that, showing the current step directly did. At accessibility sizes `OnboardingView` shows the current step without the paged `TabView` (the buttons and the back button are unchanged; only swiping between pages is not offered at those sizes). At regular sizes the pages are unchanged (built with `ForEach` over the step index).

## Production changes in Task 4

- `OnboardingStepLayout` (new, `Features/Onboarding/Components`): regular sizes keep the old layout (content with its own spacers, button below); accessibility sizes use a `ScrollView` (`scrollBounceBehavior(.basedOnSize)`) and a bottom `safeAreaBar` for the primary button. Used by Welcome, Profile, Guideline (no nested scroll view at accessibility sizes) and Health steps. Welcome emoji is `ScaledMetric`. Step spacers use `minLength: 16`. Header height is `minHeight: 44`.
- `SettingsMenuPicker` (in `SettingsRow.swift`): regular sizes are the unchanged `.menu` picker with hidden label; accessibility sizes use a `Menu` whose label wraps, keeping the "Title, Value" accessibility label (used by `SettingsUITests`). Used by Appearance, Volume unit, Alcohol unit, ABV precision and Currency.
- AX5 previews added for Welcome, Profile, Guideline, Health, `OnboardingStepLayout`, Settings and `SettingsMenuPicker`.

## Visual changes at regular size (flag for the owner)

Insights hero total 40 pt fixed becomes `largeTitle` (34 pt); the Insights "NOW" pill 9 pt becomes `caption` bold; Home hero value stays `largeTitle` rounded (was 36 pt fixed), arc percentage is `callout` rounded bold. Home This Week percentages hidden at accessibility sizes; Insights weekday labels become initials at accessibility sizes; Add Drink step 2 bottom bar, `.navigationLink` rows, Onboarding bottom bar and the wrapping Settings menus appear only at accessibility sizes. Onboarding step spacers use a 16 pt minimum (no visible change when space is free).

## Lessons for the continuation (audit behavior)

- The `dynamicType` audit flags text hosted in UIKit containers that SwiftUI cannot re-scale for the audit: `TabView(.page)` pages and `Form` rows. Plain SwiftUI `ScrollView` content passes.
- The audit flagged some text styles (`.title.bold()`, `.title2.bold()`, `.caption2.bold()`) on Home and Insights while `.title3.bold()` and `.caption.weight(.bold)` passed; cause not isolated; try a neighboring text style before restructuring.
- The scrolling helper reports a finding for an element on every page after it first appears, so one issue shows as up to 6 failures.
- System menu-picker values that wrap are clipped without any audit finding: a visual check (preview or owner) is the only detector.
- Literal strings in previews can be auto-extracted into `Localizable.xcstrings`; `git status` after builds showed no catalog change so far. Previews use `Text(verbatim:)`.

## Apple API record

Read with Xcode MCP `DocumentationSearch` on 2026-11-16. Availability: all APIs are available at the iOS 27.0 deployment target; the returned extracts carry no older-availability line, so no older-version claim is made.

| Page | Facts used | Rationale |
| ---- | ---------- | --------- |
| SwiftUI `DynamicTypeSize` | `isAccessibilitySize` is the check "when you want to change a layout for those sizes without comparing sizes yourself" | layout switch in `DPAdaptiveStack` and views |
| SwiftUI `ScaledMetric` | dynamic property that scales a numeric value | icon widths, chart and wheel sizes, emoji size |
| SwiftUI `AnyLayout`, `HStackLayout`, `VStackLayout` | switch layout type without losing subview state | `DPAdaptiveStack` |
| SwiftUI `ViewThatFits` | picks the first child that fits | read, not needed |
| SwiftUI `View.lineLimit(_:)`, `fixedSize(horizontal:vertical:)` | `lineLimit(nil)` is no limit; `fixedSize` counter-proposes the ideal size | wrapping instead of truncating |
| Charts `AxisValueLabel`, `AxisValueLabelCollisionResolution` | `collisionResolution` with `.automatic`, `.disabled`, `.greedy`, `.truncate` | Home chart `.greedy` at accessibility sizes; weekday chart uses initials |
| SwiftUI `GridItem`, `GridItem.Size.adaptive/flexible` | adaptive packs as many items as fit; flexible is one column | one flexible column at accessibility sizes |
| SwiftUI `PickerStyle` family (`menu`, `navigationLink`, `inline`, `wheel`, `segmented`), `MenuPickerStyle`, `NavigationLinkPickerStyle` | `menu` presents options as a menu (a submenu when nested in a larger menu); `navigationLink` "presents the options by pushing a List-style picker view", suited to many options; picker options inside a `Menu` appear inline by default | `.navigationLink` rows on Add Drink step 2; `Menu { Picker }` in `SettingsMenuPicker` |
| SwiftUI `Menu`, "Populating SwiftUI menus with adaptive controls" | a `Picker` placed inside a `Menu` shows its options inline with the current selection marked | `SettingsMenuPicker` content |
| SwiftUI `safeAreaBar(edge:alignment:spacing:content:)` | custom bar above or below the view, insets the safe area, "similar to `safeAreaInset`" (the `safeAreaInset` page itself did not come back from search) | bottom bars at accessibility sizes (Add Drink, Onboarding) |
| SwiftUI `ScrollView`, `scrollBounceBehavior(_:axes:)`, `ScrollBounceBehavior.basedOnSize` | `basedOnSize` bounces only when content exceeds the view | Onboarding steps |
| SwiftUI `TabViewStyle.page(indexDisplayMode:)`, `PageTabViewStyle` | "paged scrolling `TabView`"; applied with `tabViewStyle(_:)` | regular-size onboarding pages unchanged; bypassed at accessibility sizes (audit finding above) |
| XCUIAutomation `XCUIAccessibilityAuditType` (`dynamicType`, `textClipped`), `XCUIAccessibilityAuditIssue` (`element`, `compactDescription`, `detailedDescription`) | `element` is optional | explains the `none#type=nil` key; the `XCUIApplication.performAccessibilityAudit` page was not returned by search (11-15 could not retrieve it either); signature follows the existing compiled use |

## Owner clone (Task 4 step 5)

Clone `dp-phase11-a11y` created from the primary iPhone 18 Pro simulator (primary shut down, as in plan 11-06), booted, reset (readback `light / disabled / large`), Debug build of HEAD (1dd99a5 production code) installed and launched seeded (`-dp_onboarding_done YES -dp_uitest YES -dp_uitest_dataset multiday -dp_uitest_unit metric`). The identifier is only in the out-of-git `clone-udid.txt` and in the checkpoint message. The primary simulator is still shut down.

## Next (continuation, Task 6)

Record the owner's per-screen result in `11-A11Y-CHECKLIST.md` (one dated re-run block under CHK-07, one `re-run result:` line, original lines untouched), add the Outcome line to `11-DECISION-C016.md` (commit hashes, five AX5 test classes, owner result per screen), delete the clone, rewrite this SUMMARY as final with `actuals` (tokens, tasks 6, measured commits) and `plan_head_after`. If any screen fails, G-2 stays open and no `requirements mark-complete` is run. Run `roadmap update-plan-progress` before the STATE updates. Ledger rows DL-O10 and DL-W06 are reconciled by plan 11-24; DL-O17 was added here by owner instruction.

## Self-Check: PARTIAL

Commits 03faebd, 328d210, 52040c7, 052e352, ae4a667, 1dd99a5 and c2c5410 exist. Plan-level guards after Task 4: schema guard exit 0, no production file over 300 lines, 0 numeric fixed point-size fonts under Dashboard, Insights/Components, AddDrink and Onboarding, chart accessibility descriptor files unchanged against fc506f4, production files changed are inside the allowed set.
