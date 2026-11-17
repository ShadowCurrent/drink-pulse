---
phase: 11-ios-27-release-verification
plan: 21
subsystem: accessibility
tags: [accessibility-audit, contrast, hitRegion, xcuitest, gap-closure, onboarding, history, decorative-emoji]
status: partial
requires: [11-20]
provides:
  - ungated Onboarding welcome audit class OnboardingAccessibilityAuditUITests (standard and AX5, all audit types, light), green on two consecutive runs
  - Onboarding step indicator as one localized accessibility element (G07)
  - History all-types audit tests (standard, dark, AX5) added to HistoryAccessibilityAuditUITests; History findings reduced from 22+1 / 3+1 / 3 to 1 / 1 / 1 element-less contrast issues
affects: [11-22]
tech-stack:
  added: []
  patterns:
    - "A multicolour emoji shown as a decorative image (DecorativeEmoji, now with baseSize and a text style) instead of a hidden Text clears the nil-element contrast and textClipped issues (also used for the History row icon and the welcome heart)"
    - "A temporary tab-bar-hiding experiment proves an element-less issue is app content under the tab bar"
key-files:
  created:
    - drinkpulseUITests/Features/Onboarding/OnboardingAccessibilityAuditUITests.swift
  modified:
    - drinkpulse/Features/Onboarding/OnboardingView.swift
    - drinkpulse/Features/Onboarding/Components/WelcomeStep.swift
    - drinkpulse/Features/AddDrink/Components/DecorativeEmoji.swift
    - drinkpulse/Features/History/Components/EventRow.swift
    - drinkpulse/Features/History/HistoryListQueryView.swift
    - drinkpulse/Localizable.xcstrings
    - drinkpulseUITests/Features/History/HistoryAccessibilityAuditUITests.swift
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
key-decisions:
  - "No new decision id was used; D11-31 stays free. DL-O21 asks the owner to choose how to close the one History residue."
  - "DecorativeEmoji (AddDrink component, plan 11-18) gained baseSize and relativeTo parameters instead of a second component; DrinkTypeTile behaviour is unchanged (defaults 34 pt, .largeTitle)"
metrics:
  duration: "about 40 min wall clock on 2026-11-17 (16:35Z to 17:15Z)"
  completed: 2026-11-17
actuals:
  tokens: 6500
  tasks: 3
  commits: 2
plan_head_before: dd2b1bb9643e78f5cc2b3f2687021550d8d5ba69
plan_head_after: ca180811aee289d83ee7f7216e43c7a9240976d6
requirements-completed: []
---

# Phase 11 Plan 21: Onboarding and History accessibility audit findings Summary

The Onboarding welcome step now passes the all-types audit at the default size and at AX5 (two consecutive green runs). History is down to one element-less contrast issue per variant, which the owner cost limit stopped me from removing; it is recorded as DL-O21 and needs an owner decision. Plan status is partial: Task 1 done, Task 2 and Task 3 not green on one residue.

## Outcome

- Task 1 (Onboarding, G07): done. Red 3 failing (standard: hitRegion `Step 1 of 4`, contrast and textClipped `none#type=nil`) and 1 failing (AX5: hitRegion `Step 1 of 4`); after the fix 2 of 2 passed, twice.
- Task 2 (History, G09 share): not done. The 3 new all-types tests fail with 1 issue each (`type=contrast element=none#type=nil`). The 2 dynamicType tests from plan 11-15 pass.
- Task 3 (cumulative regression): audit run 37 of 40 passed, the 3 failures are exactly the History residue; flow run 96 of 96 passed.
- Requirements VER-03 and VER-01 stay open. No `requirements mark-complete` was run. G-2 stays open.
- Runner: Xcode MCP only (BuildProject, GetBuildLog, RunSomeTests, RenderPreview, XcodeRefreshCodeIssuesInFile, DocumentationSearch). No CLI xcodebuild, scheme untouched.
- Cost limit: Onboarding needed one fix attempt. History used 3 attempts on the cluster in total: emoji (22 to 16), then captions (16 to 1), both worked; the last residue got one fix attempt (`.ignore` plus D11-29 opt-in, no effect, reverted) plus one locating experiment (tab bar hidden). No further attempt was made.

## Audit key counts (distinct keys, `LC_ALL=C sort -u`, variant+type+element; light with `-dp_color_scheme system`)

| Screen / variant | Red | After fixes (final) |
| --- | --- | --- |
| Onboarding standard | 3: hitRegion `Step 1 of 4`, contrast `none#type=nil`, textClipped `none#type=nil` | 0 (2 consecutive runs) |
| Onboarding AX5 | 1: hitRegion `Step 1 of 4` | 0 (2 consecutive runs) |
| History standard | 2 distinct keys, 23 reports: contrast `none#type=nil` x22, textClipped `none#type=nil` x1 | 1 distinct key, 1 report: contrast `none#type=nil` |
| History dark | 2 distinct keys, 4 reports: contrast x3, textClipped x1 (`none#type=nil`) | 1 report: contrast `none#type=nil` |
| History AX5 | 1 distinct key, 3 reports: contrast `none#type=nil` x3 | 1 report: contrast `none#type=nil` |

Intermediate History results (stamp directory files): after emoji fix standard 16, dark 1, AX5 1 (`his-t2-attempt1`); after caption tokens standard 1, dark 1, AX5 1 (`his-t2-attempt2`).

## Findings fixed per view

| View | Fix |
| --- | --- |
| `OnboardingView` (step dots) | One accessibility element (`.accessibilityElement(children: .ignore)`) with a 44 pt minimum frame and `contentShape(Rectangle())`, localized label `onboarding.progress.label` ("Setup progress") and a localized value `onboarding.progress.value` ("Step %1$lld of %2$lld", via `String(format:)` like other format keys). The interpolated English literal is gone. |
| `WelcomeStep` | Heart emoji drawn by `DecorativeEmoji(emoji: "🫀", baseSize: 72)` instead of a hidden `Text`; subtitle on `Color.dpSecondaryText`. |
| `DecorativeEmoji` (AddDrink) | New `init(emoji:baseSize:relativeTo:)`; defaults keep the drink tile at 34 pt scaled like `.largeTitle`. |
| `EventRow` (History row) | Icon is `DecorativeEmoji(baseSize: 22, relativeTo: .title2)`; subtitle and unit label on `dpSecondaryText`. |
| `HistoryListQueryView` | Day header and end-of-list footer on `dpSecondaryText`. |
| `Localizable.xcstrings` | Added `onboarding.progress.label`, `onboarding.progress.value`; removed the stale auto key `Step %lld of %lld`, no longer referenced. |

- **Shared color tokens:** none changed; `dpSecondaryText` (plan 11-17) is reused. `DPColors`, `DPSemanticColors`, `RiskLevel+Color` and the asset catalog are untouched.
- **`accessibilityHidden`:** the two `accessibilityHidden(true)` modifiers on emoji `Text` were removed with the `Text`. None added. Nothing was muted, no audit type excluded, no text size capped.
- **G09 History location:** the element-less issues sat on the combined `EventRow` content: the emoji `Text` (contrast and textClipped) and `.secondary` captions (contrast). The one remaining issue per variant belongs to a History row under the tab bar: with the tab bar hidden in a temporary, never-committed experiment, all three variants passed (`his-t2-diag-tabbar-hidden.result.txt`). The issue carries no element, so D11-29 cannot ignore it (it needs an element frame that meets the tab bar). The frame and the exact row are not known.

## Regular-size visual changes (owner-visible)

- **Onboarding welcome:** subtitle text slightly darker grey in light mode, slightly lighter in dark mode (`dpSecondaryText`). The heart looks the same (checked by RenderPreview).
- **Onboarding step dots:** the 8 pt dots look the same; the touch/accessibility frame is now 44 pt tall.
- **History:** row captions (subtitle, unit label), day headers and the end-of-list footer use the same shade as Home and Insights (`dpSecondaryText`). Row emoji look the same (RenderPreview of `EventRow`), drawn as images.

## Tests

| Run | File | Result |
| --- | --- | --- |
| Onboarding audit red | `onb-t1-red.result.txt` | 0/2 passed (4 audit reports) |
| Onboarding audit run 1 / run 2 | `onb-t1-run1/run2.result.txt` | 2/2 passed, 0 failed, 0 skipped each |
| Task 1 regression: OnboardingDynamicType 4, Flow 3, HealthStep 1, LocaleDefault 2, WeeklySummary 1, Authority 1, AddDrinkAccessibilityAudit 2 | `onb-t1-regression.result.txt` | 14/14 passed |
| History audit red | `his-t2-red.result.txt` | 2/5 passed; 3 new all-types tests failed |
| History after attempt 1 / attempt 2 | `his-t2-attempt1/attempt2.result.txt` | 2/5 passed (residue 16+1+1, then 1+1+1) |
| History diagnostic, tab bar hidden (temporary, reverted) | `his-t2-diag-tabbar-hidden.result.txt` | 3/3 all-types tests passed |
| History attempt 3 (`.ignore` + D11-29 opt-in, reverted) | `his-t2-attempt3-ignore-d1129.result.txt` | 2/5 passed, residue unchanged |
| History flow regression: HistoryDynamicType 1, HistoryUnitDisplay 1, 3 HistoryInteraction calendar tests | `his-t2-regression.result.txt` | 5/5 passed |
| Cumulative audit (Home, Add Drink, Insights, Settings, Onboarding, History audit classes, Probe, 5 AX5 classes, 2 Reduce Motion classes) | `cum-t3-audit.result.txt` | 37/40 passed; 3 failed = History all-types residue (DL-O21) |
| Cumulative flows (DashboardUITests, SettingsUITests, OnboardingFlowUITests, HistoryUnitDisplayUITests, DashboardViewModelTests, DPMotionTests) | `cum-t3-flows.result.txt` | 96/96 passed |

- Reduce Motion classes ran and passed (no skipped negative control).
- Build: Xcode MCP `BuildProject` (buildForTesting) succeeded; `GetBuildLog` at warning severity returned 0 entries; `XcodeRefreshCodeIssuesInFile` found 0 issues on `OnboardingView`.
- Guards: production files changed since fc506f4 are all in the allowed set (the AddDrink `DecorativeEmoji` change is covered by `Features/AddDrink/*`); the schema guard against fbd37fa passed; no production Swift file is over 300 lines.
- The plan's Task 2 and Task 3 verify commands do not print `ok`: Task 2 needs two runs with 5 passed (the 3 all-types tests fail), Task 3 needs `"failed":0` in `cum-t3-audit`. This is the DL-O21 residue, not a harness fault.

Evidence digests (stamp directory `20261114T121519Z`, out of git), sha256:
- `onb-t1-red.result.txt` `4d67cf28b499640eaa4e9464504fa929c00cba21a5078265aa7eb5a596969d3e`
- `onb-t1-run1.result.txt` `413678647c1d6ca0e3a7d2233131819559211db3b09fd0574ca3027e198d8a20`
- `onb-t1-run2.result.txt` `0b9dfb11e1d87eeb1f9c333404ecbcde6c794ef6c95296ebc059c91e5855bd07`
- `onb-t1-regression.result.txt` `a1159c2f43056351e4742dfced1ec6ba24fd1b321e35e1f6af278cd857eb5f9d`
- `his-t2-red.result.txt` `8e15ea14fb78f55fce37c74a6a3edecda37a2fbbfdbe4ec4369af2ec137c2414`
- `his-t2-attempt2.result.txt` `aa4e6b2652d461463396408de8ae590abaa887df6b4d39cf21a8124a3be3509c`
- `his-t2-diag-tabbar-hidden.result.txt` `7750496f31aef26cf0c24ba76dca7315c231f48c9529931c95a883167bf37da9`
- `his-t2-attempt3-ignore-d1129.result.txt` `aa158d31b5e8864574286f7ef3df559497af7bd858d26139c0297a72abbaf84a`
- `his-t2-regression.result.txt` `ea46f31c39ecdac70528e31c4b89b00a631cb1f2f46c67a761d760a454edf97e`
- `cum-t3-audit.result.txt` `aea1e5a69d0bfa895372cecdedd49e27f3991ebe29d9ab802ce1983727466d9e`
- `cum-t3-flows.result.txt` `7c9da8a2049440ea79a27162610a589f6291cb85c58df0aa44c2bdd1a131274c`

## Deviations from Plan

**1. [Not done, owner cost limit] History residue (DL-O21)**
- Task 2 asks for two green runs with 5 passed; I could not reach it. One element-less contrast issue per variant remains.
- Recorded in `11-DEBT-LEDGER.md` as DL-O21, with the G07 and G09 rows updated by a note (their Status is unchanged; no row closed).
- The 3 new History all-types tests are committed as they are (failing, one key each) so the finding stays visible and nothing is muted. Task 3 therefore cannot show `failed:0` for the audit run.

**2. [Rule 2 - consistency] Welcome subtitle on `dpSecondaryText`**
- The ledger row G07 lists the subtitle as a contrast finding (measured in dark mode in 11-13); the light run did not report it. I switched it to the shared token without a separate run; the cumulative run (Onboarding audit class, standard and AX5, green) covers it. Dark appearance is not part of the plan's Onboarding class.

**3. [Order] Diagnostic temporary edits**
- `.toolbar(.hidden, for: .tabBar)` in `HistoryView` (temporary, marked, reverted before the commit; `HistoryView.swift` is unchanged against HEAD~1), and the `.ignore` plus D11-29 opt-in try (reverted). Neither was committed.

**4. [Scope] `DecorativeEmoji` extension**
- Edited a file outside the plan's `files_modified` (`drinkpulse/Features/AddDrink/Components/DecorativeEmoji.swift`) and History row files not named in the plan: `EventRow.swift` and `HistoryListQueryView.swift` (both on the plan's conditional list or in the allowed production set).

## Apple API record

| API | Source consulted | Availability | Rationale |
| --- | --- | --- | --- |
| `accessibilityElement(children:)` with `.ignore` | Xcode MCP DocumentationSearch: SwiftUI "accessibilityElement(children:)", "ignore" ("Use this behavior when you want a view represented by a single accessibility element ... you will need to use other accessibility modifiers, such as accessibilityLabel(_:)") | SwiftUI, project minimum iOS 27 | Step dots as one progress element |
| `accessibilityLabel(_:)`, `accessibilityValue(_:)` | Xcode MCP DocumentationSearch: "accessibilityValue(_:)" ("describe the value represented by a view, but only if that is different than the view's label") | SwiftUI | Label "Setup progress", value "Step N of M" |
| `frame(minWidth:minHeight:)`, `contentShape(_:)` | Used as in plans 11-15 to 11-20; not re-searched | SwiftUI | 44 pt hit region |
| `Image(decorative:scale:)`, `ImageRenderer`, `ScaledMetric(wrappedValue:relativeTo:)` | Consulted in plan 11-18 (DecorativeEmoji) | SwiftUI | Extended with `baseSize` and a text style |
| `Color.dpSecondaryText` token | as in 11-17 | project | Reused for captions and headers |
| `View.toolbar(_:for:)` with `.hidden`, `.tabBar` | as in 11-20 | SwiftUI | Temporary diagnostic only, not shipped |
| `XCUIApplication.performAccessibilityAudit(for:_:)`, `XCUIAccessibilityAuditType.all`, `XCUIDevice.appearance` | as in 11-17 and 11-20 | XCUIAutomation | Onboarding and History audit classes |

## Known Stubs

None. No TODO, FIXME, placeholder or `print(` in the diff.

## Threat Flags

None. No network, file, auth or schema surface was added. T-11-71: the History element was located (emoji, captions, then tab-bar occlusion by experiment), not hidden. T-11-72: two consecutive green runs exist for Onboarding only; History has no green run.

## Notes for later plans

- 11-22: the gated `AccessibilityAuditUITests` does not use D11-29 or D11-30 and will also see the History row under the tab bar. DL-O21 needs the owner's choice first: (a) extend D11-29 to element-less contrast issues when the tab bar is present, (b) add a bottom content margin to the History list, a visual change, (c) accept the finding as a system-glass artifact.
- Onboarding dark appearance was not audited; the 11-13 dark-mode G07 keys are not re-measured.
- Next free decision id: D11-31.

## Self-Check: PASSED

- Files exist: `OnboardingAccessibilityAuditUITests.swift`, `HistoryAccessibilityAuditUITests.swift`, `DecorativeEmoji.swift`, `EventRow.swift`.
- Commits 32a191a and ca18081 are ancestors of HEAD. `HistoryView.swift` and the test hooks carry no temporary edit (`git status` clean apart from planning files).
- The self-check records that the plan's own acceptance criteria for Task 2 and the audit half of Task 3 are NOT met (DL-O21); this is stated above, not hidden.
