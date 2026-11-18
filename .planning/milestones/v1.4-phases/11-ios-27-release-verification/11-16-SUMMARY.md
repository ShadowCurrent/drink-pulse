---
phase: 11-ios-27-release-verification
plan: 16
subsystem: accessibility
tags: [dynamic-type, ax5, layout, xcuitest, gap-closure, g-2]
status: complete
requires: [11-15]
provides:
  - DPAdaptiveStack shared adaptive layout (HStack at regular sizes, VStack at accessibility sizes)
  - Home, Insights, Add Drink (steps 1 and 2), Settings Preferences and Onboarding AX5 layouts with five AX5 audit UI test classes (all green)
  - narrow owner-approved audit exemption for system Form controls on Add Drink step 2 (D11-28)
  - owner CHK-07 AX5 re-run recorded (re-run result fail) with carried findings DL-O18, DL-O19, DL-O20
affects: [11-18, 11-19, 11-22, 11-23, 11-24]
tech-stack:
  added: []
  patterns:
    - "DynamicTypeSize.isAccessibilitySize switches layout (AnyLayout via DPAdaptiveStack, bottom safeAreaBar, wrapping Menu)"
    - "AX5 audit UI test per screen through AccessibilityAuditSupport, with an explicit per-call exemptElementKeys set only where an owner decision allows it"
key-files:
  created:
    - drinkpulse/DesignSystem/DPAdaptiveStack.swift
    - drinkpulse/Features/Onboarding/Components/OnboardingStepLayout.swift
    - drinkpulseUITests/Features/Dashboard/DashboardDynamicTypeUITests.swift
    - drinkpulseUITests/Features/Insights/InsightsDynamicTypeUITests.swift
    - drinkpulseUITests/Features/AddDrink/AddDrinkDynamicTypeUITests.swift
    - drinkpulseUITests/Features/Settings/SettingsDynamicTypeUITests.swift
    - drinkpulseUITests/Features/Onboarding/OnboardingDynamicTypeUITests.swift
  modified:
    - drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift
    - Dashboard, Insights components, AddDrink, History shared sections, Settings and Onboarding views (see Production changes)
    - .planning/phases/11-ios-27-release-verification/11-A11Y-CHECKLIST.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C016.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
    - .planning/phases/11-ios-27-release-verification/11-CONTEXT.md
decisions:
  - "D11-28 (owner, 2026-11-16): narrow documented exception for AX5 dynamicType and textClipped audit findings on system-owned Form controls on Add Drink step 2 (keys Volume, Strength, Amount, none#type=nil), implemented as an explicit exemptElementKeys set; every other finding still fails"
metrics:
  duration: "multi-session, 2026-11-16 to 2026-11-17 (owner checkpoint between Task 4 and Task 6)"
  completed: 2026-11-17
actuals:
  tokens: 22000
  tasks: 6
  commits: 9
plan_head_before: db56ae61b357d9b55a5fe71e4893495015e55d8f
plan_head_after: 764ba0b8c5f0627698f86c559fd8d59e2e0014a4
requirements-completed: []
---

# Phase 11 Plan 16: AX5 layouts for Home, Insights, Add Drink, Settings, Onboarding Summary

Five screens adapt their layout at accessibility text sizes (shared `DPAdaptiveStack`, wrapping text, bottom bars, a wrapping Settings menu, Onboarding without the paged `TabView`) and five AX5 audit UI test classes are green, but the owner's CHK-07 AX5 re-run failed on two screens (Insights chart x-axis label overlap, Add Drink step 2 placeholder truncation) and Onboarding was not checked, so gap G-2 stays open.

## Outcome

- Plan executed: all 6 tasks done. Owner check result: **fail**. Gap **G-2 stays OPEN**.
- CHK-07 `re-run result: fail` (plan 11-16, simulator, 2026-11-17). Per screen:

| Screen | Owner result | Owner note |
| ------ | ------------ | ---------- |
| Home | pass | |
| Insights | fail | The chart x-axis labels (days, months and so on) overlap in every period (Week, Month, Year, All); in Month mode always, also at the regular text size; unreadable. Everything else passes. |
| Add Drink step 1 | pass | |
| Add Drink step 2 | fail (minor) | Only the placeholders are truncated: "Optional na..." and "Price (option...". Rows and bottom bar look good. |
| Settings Preferences | pass | all rows; long values wrap |
| History | pass | list and calendar |
| Guideline picker | pass | |
| Onboarding | open | not tested by owner; not a pass |

- Carried findings (debt ledger, status open; no code fix in this plan):
  - **DL-O18**: Insights chart x-axis label overlap in all periods at AX5, and in Month mode at every text size (regular-size defect). Owner plan 11-19.
  - **DL-O19**: Add Drink step 2 placeholders "Optional name" and "Price (optional)" truncated at AX5. These are system Form text fields inside the D11-28 exception scope, so the AX5 test cannot see it; still a visible defect. Owner plan 11-18.
  - **DL-O20**: Onboarding AX5 eye check not done by the owner. Carried to the next owner checkpoint (plan 11-22 or 11-23).
- `requirements mark-complete` was not run for VER-03 or VER-01 (not every screen passed).
- DL-O10 and DL-W06 untouched (plan 11-24 reconciles them).

## Tasks

| Task | Commit | Result |
| ---- | ------ | ------ |
| 1 Home tracer | 03faebd | `DashboardDynamicTypeUITests` 2 passed; `DashboardUITests` + `ReduceMotionDashboardUITests` 9 passed; `DPMotionTests` 7 passed |
| 2 Insights | 328d210 | `InsightsDynamicTypeUITests` 2 passed; Insights flow classes 11 passed (DL-T01 passed, no retry); unit suites 71 passed |
| 3 Add Drink steps 1 and 2 | 52040c7, 052e352 (WIP), ae4a667 | `AddDrinkDynamicTypeUITests` 2 passed (step 2 with the D11-28 exemption); seven flow classes 15 passed; `DrinkDetailInputMathTests` 14 passed |
| 4 Settings and Onboarding | 1dd99a5 | `SettingsDynamicTypeUITests` + `OnboardingDynamicTypeUITests` 6 passed (no exemption); Settings, Guideline picker, AppVersion, five Onboarding classes and `CurrencyUITests` 19 passed; History, Dashboard, Insights, AddDrink AX5 classes 7 passed; build 0 warnings; 0 diagnostics on changed files; no file over 300 lines; 0 numeric fixed-size fonts under Dashboard, Insights/Components, AddDrink, Onboarding; schema guard exit 0 |
| 5 Owner CHK-07 re-run at AX5 | (checkpoint) | owner answered 2026-11-17; result above |
| 6 Record re-run, delete clone | 764ba0b | checklist re-run block, C016 Outcome, DL-O18 to DL-O20; clone deleted |
| (interim summaries) | c2c5410, 15c4a25 | partial and interim summary at context boundary and owner checkpoint |

Evidence files (stamp directory, out of git): `ax5-t1-*`, `ax5-t2-*`, `ax5-t3-*`, `ax5-t4-ax5|flows|prior.result.txt` hold the MCP counts line per run.

## Production changes

- `DPAdaptiveStack` (new, `DesignSystem/`): `AnyLayout` switch, HStack at regular sizes, VStack at accessibility sizes. Used by Home and Insights cards.
- Home (Dashboard): hero card, chip row, `DPChip`, streak, This Week, guideline alert and overview cards wrap or stack at accessibility sizes; numeric fixed point-size fonts replaced by text styles; Home chart axis labels use `.greedy` collision resolution at accessibility sizes.
- Insights: health metrics, hero, scope navigator and comparison cards adapt; `AlcoholAreaChart` height scales; weekday labels become initials at accessibility sizes.
- Add Drink: drink-type tiles wrap and the grid uses one flexible column at accessibility sizes; step 2 uses `.navigationLink` picker rows and a bottom `safeAreaBar` with Cancel and Save at accessibility sizes; shared History sections (price, custom name) wrap.
- Settings: `SettingsMenuPicker` (in `SettingsRow.swift`) keeps the `.menu` picker at regular sizes and uses a wrapping `Menu` at accessibility sizes, keeping the "Title, Value" accessibility label. Used by Appearance, Volume unit, Alcohol unit, ABV precision and Currency.
- Onboarding: `OnboardingStepLayout` (new) keeps the regular layout; at accessibility sizes a `ScrollView` (`scrollBounceBehavior(.basedOnSize)`) and a bottom `safeAreaBar` for the primary button. `OnboardingView` shows the current step directly at accessibility sizes. Welcome emoji is `ScaledMetric`.
- AX5 previews added for the changed views.

## Visual changes at regular size (flag for the owner)

- Insights hero total: 40 pt fixed becomes `largeTitle` (34 pt).
- Insights "NOW" pill: 9 pt becomes `caption` bold.
- Home hero value stays `largeTitle` rounded (was 36 pt fixed); arc percentage is `callout` rounded bold.
- Home This Week percentages are hidden at accessibility sizes.
- Insights weekday labels become initials at accessibility sizes.
- Add Drink step 2 bottom bar, `.navigationLink` rows, Onboarding bottom bar and the wrapping Settings menus appear only at accessibility sizes. Onboarding step spacers use a 16 pt minimum (no visible change when space is free).

## Deviations from Plan

### Owner-approved exception to the "no allow-list" rule (D11-28)

- **Found during:** Task 3 (Add Drink step 2).
- **Issue:** inside a SwiftUI `Form`, Picker, Menu, Button, DatePicker and TextField internals are flagged `dynamicType` and `textClipped` at AX5 even with default text styles; the same text outside a Form passes. Findings left on step 2: `element=Volume`, `element=Amount` (`Strength` on some runs) and `element=none#type=nil` (6 to 14 per run).
- **Six approaches that did not clear them:** `.menu` picker, `.navigationLink` picker, custom `Menu` rows with explicit `.font(.body)`, `safeAreaInset` versus `safeAreaBar`, Cancel and Save as Form rows, single-line price field.
- **Decision (owner, 2026-11-16, D11-28):** narrow documented exception. Explicit per-call `exemptElementKeys` on `assertNoAuditIssuesWhileScrolling` / `assertNoAuditIssues` in `AccessibilityAuditSupport.swift`, passed only by the step 2 test, applied to `dynamicType` and `textClipped` only. Contrast, hit-region and description findings are never exempt.
- **Owner eye check:** the CHK-07 re-run found the placeholder truncation inside this scope (DL-O19). The exception hides it from the test; it is carried forward as a visible defect.
- **Records:** `11-CONTEXT.md` (D11-28), `11-DECISION-C016.md` (Exception record, Outcome), `11-DEBT-LEDGER.md` (DL-O17, DL-O19). Commits ae4a667, 1dd99a5, 764ba0b.

### Settings did not need the exemption

Settings Preferences is a `ScrollView`, not a `Form`; its AX5 audit passed without exemption. The real defect (the system menu-picker button clips a wrapped value) has no audit finding, so it was fixed app-side with `SettingsMenuPicker`. The owner confirmed pass by eye.

### Onboarding paged TabView (app-side finding, not an exemption)

Inside `TabView(.page)` the Dynamic Type audit flags every text as "font sizes partially unsupported" at AX5; a ScrollView or bottom bar did not change that, showing the step directly did. At accessibility sizes `OnboardingView` shows the current step without the paged `TabView` (swiping between pages is not offered there; buttons unchanged). The owner did not check Onboarding (DL-O20).

### Files outside `files_modified`

`AccessibilityAuditSupport.swift` (exemption parameter, D11-28), `OnboardingStepLayout.swift` (new shared step layout), `DrinkTypeGridView.swift` and `DashboardView+Previews.swift` (AX5 layout and previews). `Localizable.xcstrings`, listed in the plan, did not change. All are inside the feature areas of the plan.

### Rule-based auto-fixes

None beyond the above.

## Design findings (audit behavior)

- The `dynamicType` audit flags text hosted in UIKit containers that SwiftUI cannot re-scale for the audit: `TabView(.page)` pages and `Form` rows. Plain SwiftUI `ScrollView` content passes.
- Some text styles (`.title.bold()`, `.title2.bold()`, `.caption2.bold()`) were flagged on Home and Insights while `.title3.bold()` and `.caption.weight(.bold)` passed; cause not isolated.
- The scrolling helper reports a finding on every page after the element first appears, so one issue can show as up to 6 failures.
- System menu-picker values that wrap are clipped with no audit finding; only a visual check detects it.
- Form text-field placeholders truncated at AX5 are also invisible to the test under D11-28 (DL-O19).
- The Insights x-axis label overlap (DL-O18) was not flagged by the AX5 audit and also occurs at regular size in Month mode; the AX5 test viewport and audit types do not cover axis-label collisions.

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
| SwiftUI `PickerStyle` family, `MenuPickerStyle`, `NavigationLinkPickerStyle` | `navigationLink` "presents the options by pushing a List-style picker view"; picker options inside a `Menu` appear inline by default | `.navigationLink` rows on step 2; `Menu { Picker }` in `SettingsMenuPicker` |
| SwiftUI `Menu`, "Populating SwiftUI menus with adaptive controls" | a `Picker` inside a `Menu` shows its options inline with the selection marked | `SettingsMenuPicker` |
| SwiftUI `safeAreaBar(edge:alignment:spacing:content:)` | custom bar above or below the view, insets the safe area, "similar to `safeAreaInset`" | bottom bars at accessibility sizes. The `safeAreaInset` page itself did not come back from DocumentationSearch. |
| SwiftUI `ScrollView`, `scrollBounceBehavior(_:axes:)`, `ScrollBounceBehavior.basedOnSize` | `basedOnSize` bounces only when content exceeds the view | Onboarding steps |
| SwiftUI `TabViewStyle.page(indexDisplayMode:)`, `PageTabViewStyle` | paged scrolling `TabView`, applied with `tabViewStyle(_:)` | regular-size onboarding unchanged; bypassed at accessibility sizes |
| XCUIAutomation `XCUIAccessibilityAuditType` (`dynamicType`, `textClipped`), `XCUIAccessibilityAuditIssue` (`element`, `compactDescription`, `detailedDescription`) | `element` is optional | explains the `none#type=nil` key. The `XCUIApplication.performAccessibilityAudit` page did not come back from DocumentationSearch (11-15 could not retrieve it either); the signature follows the existing compiled use. |

## Owner clone

Clone `dp-phase11-a11y` was created from the primary iPhone 18 Pro simulator for the Task 5 session. In Task 6 it was reset to the default text size (`content_size large`), shut down and deleted; `xcrun simctl list devices` no longer shows it. Its identifier was only in the out-of-git `clone-udid.txt`; no identifier is in any git-tracked file. The primary simulator is still shut down.

## Known Stubs

None. The stub scan over the changed Swift files found no TODO, FIXME or placeholder text.

## Threat Flags

None. No network, file access, persistence or schema change; the exemption parameter is test-only code.

## Notes for the orchestrator

- G-2 stays open: Insights (DL-O18) and Add Drink step 2 (DL-O19) failed; Onboarding (DL-O20) is open. A follow-up is needed; plans 11-19 and 11-18 are the named owners.
- Decision-id collision to watch: plan 11-23 Task 3 says the owner's cli-build answer is "recorded as D11-28", but D11-28 is now the Form-control exception from this plan. Plan 11-23 should use the next free D11 id.

## Self-Check: PASSED

- Files exist: `DPAdaptiveStack.swift`, `OnboardingStepLayout.swift`, the five `*DynamicTypeUITests.swift` classes.
- Commits exist on HEAD: 03faebd, 328d210, 52040c7, c2c5410, 052e352, ae4a667, 1dd99a5, 15c4a25, 764ba0b (9 commits from db56ae6 to 764ba0b; the final docs commit adds one more).
- Task 6 verify command printed `ok`: exactly one re-run block and one `re-run result:` line under CHK-07, `^result: ` count 11, C016 Outcome present, clone gone, no UUID-shaped string in the checklist, C016 or ledger.
- No production Swift file over 300 lines; schema guard exit 0 (Task 4); build 0 warnings (Task 4). No build or test was run in Task 6 (docs-only).
