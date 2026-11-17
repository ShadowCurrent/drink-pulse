---
phase: 11-ios-27-release-verification
plan: 17
subsystem: accessibility
tags: [accessibility-audit, contrast, dynamic-type, xcuitest, gap-closure, home]
status: complete
requires: [11-16]
provides:
  - ungated Home audit class DashboardAccessibilityAuditUITests (standard, dark, AX5; all audit types), green on two consecutive runs
  - Home contrast and Dynamic Type fixes through new asset colors dpSecondaryText and dpRiskTextLow/Moderate/High plus RiskLevel.textColor
  - harness fix in AuditLaunch (-dp_color_scheme system), so a stored in-app Appearance no longer overrides the pinned simulator appearance
  - owner decision D11-29 and its shared, opt-in mechanism AuditTabBarOcclusion (audits do not evaluate app content occluded by the system tab bar)
affects: [11-18, 11-19, 11-20, 11-21, 11-22, 11-23]
tech-stack:
  added: []
  patterns:
    - "Asset-catalog color sets with separate light and dark variants for small text on glass cards (Color(_:bundle:))"
    - "Audit issue filtering only through an explicit per-call opt-in decided at runtime from the real tab bar element; every ignored issue recorded as a warning-severity XCTIssue with type, key and frame"
key-files:
  created:
    - drinkpulseUITests/Features/Dashboard/DashboardAccessibilityAuditUITests.swift
    - drinkpulseUITests/Features/Shell/AccessibilityAuditOcclusion.swift
    - drinkpulse/Assets.xcassets/SecondaryText.colorset/Contents.json
    - drinkpulse/Assets.xcassets/RiskTextLow.colorset/Contents.json
    - drinkpulse/Assets.xcassets/RiskTextModerate.colorset/Contents.json
    - drinkpulse/Assets.xcassets/RiskTextHigh.colorset/Contents.json
  modified:
    - drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift
    - drinkpulse/DesignSystem/DPSemanticColors.swift
    - drinkpulse/DesignSystem/RiskLevel+Color.swift
    - drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift
    - drinkpulse/Features/Dashboard/Components/DPChip.swift
    - drinkpulse/Features/Dashboard/Components/DashboardHeroCard.swift
    - drinkpulse/Features/Dashboard/Components/GuidelineAlertCard.swift
    - drinkpulse/Features/Dashboard/Components/StreakCard.swift
    - .planning/phases/11-ios-27-release-verification/11-CONTEXT.md
decisions:
  - "D11-29 (owner, 2026-11-17, option B): amendment of D11-25. Audits do not evaluate app content occluded by the system tab bar; the launch viewport otherwise stays the rule. Mechanism: explicit per-call opt-in ignoreTabBarOccludedContent; only contrast and textClipped issues whose element frame intersects the real tab bar frame are ignored; tab bar elements, element-less issues and every other type still fail; every ignored issue is recorded as a warning with type, key and frame"
  - "New tokens instead of changing existing ones: dpSecondaryText and dpRiskTextLow/Moderate/High (asset colors with darker light and lighter dark variants) plus RiskLevel.textColor; dpRisk fill colors and every existing token unchanged"
metrics:
  duration: "about 80 min in two sessions on 2026-11-17 (owner checkpoint between Task 2 WIP and the D11-29 resume)"
  completed: 2026-11-17
actuals:
  tokens: 8100
  tasks: 2
  commits: 3
plan_head_before: 284f26e76454ca83f1307abdd292285ed44682d9
plan_head_after: ecb7c97ef90f5a0f55d13441039ada1325ba65ee
requirements-completed: []
---

# Phase 11 Plan 17: Home accessibility audit findings Summary

Home now has no failing audit finding at the default size, in dark appearance and at AX5. Two consecutive runs of the ungated all-types audit class are green. The fixes are new contrast-safe text color assets for glass cards and the risk colors, and caption sizes on badges. The last remaining finding was app text under the system Liquid Glass tab bar. The owner moved it out of the audit's scope (D11-29), and every ignored issue stays logged and counted.

## Outcome

- Tasks: 2 of 2 done. Plan 11-17 is complete. Requirements VER-03 and VER-01 stay open, because other screens and G-2 are still open.
- Home audit class `DashboardAccessibilityAuditUITests` (standard light, dark, AX5 light; `.all` types; launch viewport):

| Run | File | Result | Audit issue lines (raw) | Distinct (`LC_ALL=C sort -u`) | Ignored (D11-29) |
| --- | ---- | ------ | ----------------------- | ----------------------------- | ---------------- |
| Task 1 red (stored dark, invalid light labels) | `home-t1-red-stored-dark.result.txt` | red | n/a (superseded) | n/a | n/a |
| Task 1 red | `home-t1-red.result.txt` | 3 failed | 36 | 35 | n/a |
| Task 1 after | `home-t1-after.result.txt` | 3 failed | 20 | 19 | n/a |
| Task 2 WIP | `home-t2-partial.result.txt` | 3 failed | 3 | 3 | n/a |
| Task 2 run 1 | `home-t2-run1.result.txt` | 3 passed, 0 failed, 0 skipped | 0 | 0 | 3 (1 per variant) |
| Task 2 run 2 | `home-t2-run2.result.txt` | 3 passed, 0 failed, 0 skipped | 0 | 0 | 3 (1 per variant) |

- Ignored issues, identical in both green runs:
  - standard: `contrast` on `This Week`, frame 16,822,370,199
  - dark: `contrast` on `This Week`, frame 16,822,370,199
  - ax5: `contrast` on `100%`, frame 75,776,133,61
  - The tab bar frame was 0,791,402,83 in each run, and `tabBarFound=true` in each run.
  - The `This Week` element is the card container. Its visible part (y 822 to 874) lies fully under the tab bar.
  - The `100%` element is the hero arc percentage at AX5. 46 of its 61 pt lie under the tab bar.
- Task 1 target cluster (`home-t1-target-keys.txt`): 7 contrast keys. These are `TODAY'S INTAKE`, `of 2.0 std daily limit`, `Calories`, `Drinks` and the three ` / N std` limit values. All 7 are gone in `home-t1-after.result.txt`.

## Findings fixed per view

| View | Finding keys fixed | Change |
| ---- | ------------------ | ------ |
| DashboardHeroCard | `TODAY'S INTAKE`, `of 2.0 std daily limit`, `100%` (contrast at standard and dark; `100%` dynamicType) | eyebrow and limit text use `dpSecondaryText`; the arc percentage and exceeded label use `RiskLevel.textColor` |
| DPChip (chip row) | `Calories`, `Drinks` | labels use `dpSecondaryText` |
| ConsumptionOverviewCard | ` / 2.0 std`, ` / 10.0 std`, ` / 42.9 std`, `2.0`, `42%`, `113%`, `+1.3 std over limit` (contrast and dynamicType) | limit values tertiary to `dpSecondaryText`; percentage badges, values and over-limit text use `RiskLevel.textColor`; badge and over-limit text `caption2` to `caption` |
| StreakCard | (secondary text, preventive with the same token) | `dpSecondaryText` |
| GuidelineAlertCard | none reported | `dpSecondaryText` on the caption; see below |
| (tab bar overlap) | `This Week` (standard, dark), `100%` (ax5) | not changed in the app; out of the audit's scope by owner decision D11-29 |

GuidelineAlertCard: no Home audit key in any run names it. Its title "Weekly limit exceeded" never appears. Either the seeded dataset does not show it in the launch viewport, or it passes. The seed was not changed. Code review against the same rules:
- the title is primary `.subheadline.bold()`;
- the caption now uses `dpSecondaryText`, the token proven on the other cards;
- the red triangle icon is not text;
- the card combines its children into one element with a label.

## Regular-size visual changes (owner-visible)

- darker secondary gray in light mode
- limit values tertiary to secondary
- risk text darker in light mode, lighter in dark mode
- caption2 to caption on badges and the over-limit line
- hero arc % in risk text colour

## Shared color tokens

No existing token changed. New tokens:
- `dpSecondaryText` (asset `SecondaryText`)
- `dpRiskTextLow`, `dpRiskTextModerate`, `dpRiskTextHigh` (assets `RiskText*`)
- `RiskLevel.textColor`

Today their only users are the Home components: ConsumptionOverviewCard, DashboardHeroCard, DPChip, GuidelineAlertCard and StreakCard. `RiskLevel.color` and `chartColor` stay the fill colors. Because files in `DesignSystem/` and the Assets catalog changed since fc506f4, the token regression ran (see Tests).

## Owner decision D11-29 and the ignored-issue mechanism

- Decision: the owner chose option B, "change what the audit measures". It is recorded in `11-CONTEXT.md` as D11-29, with one dated amendment line under D11-25. No existing line changed: the numstat against HEAD is 3 added and 0 deleted.
- Rule: an audit does not evaluate app content while the system tab bar occludes it. Otherwise the launch viewport stays the rule. The app is not changed for this finding.
- Mechanism: `drinkpulseUITests/Features/Shell/AccessibilityAuditOcclusion.swift` (`AuditTabBarOcclusion`), used by `assertNoAuditIssues` and `assertNoAuditIssuesWhileScrolling` through the explicit per-call opt-in `ignoreTabBarOccludedContent: Bool = false`:
  - At audit time it reads the real tab bar: `app.tabBars.firstMatch`, then `snapshot()`, which gives its frame plus the names and frames of all its descendants. No list of names is involved.
  - Only `contrast` and `textClipped` can be ignored. These two checks read rendered pixels, which the glass distorts. Every other type always fails, so no audit type is silenced.
  - An issue is ignored only when its element frame has a non-empty intersection with the tab bar frame.
  - An element of the tab bar itself always fails. It is matched by an identifier or label equal to a tab bar descendant, or by an equal frame within 1 pt. When in doubt the issue is treated as chrome and fails, so the plan's stop rule for system chrome still holds.
  - An issue without an element (`none#type=nil`) is never ignored.
  - Auditability: each ignored issue is recorded with `XCTIssue(severity: .warning)` as `Accessibility audit issue ignored (D11-29, under the tab bar): screen= variant= type= element= frame= tabBar=`. Each opted-in audit also records `Accessibility audit ignored count (D11-29): ... ignored=N tabBarFound=...`, including when N is 0. Both appear in the MCP result summary saved to the stamp directory and in the console log. Warnings do not fail the test.
- Only the Home audit class opts in. The History, Settings, Insights, Add Drink and Onboarding classes are unchanged. Each later plan decides per call and cites D11-29.
- The gated class `AccessibilityAuditUITests` does not use the shared helper and does not apply D11-29. Its Home methods therefore still report `This Week` and `100%`. Plan 11-22 (the final gated re-run) must either route the gated class through the helper with the opt-in or record these keys. The gated class was not changed here.
- Numbering: plan 11-23 says its Release answer becomes "D11-28". D11-28 and D11-29 are both taken, so 11-23 must use the next free id. This is noted in the D11-29 entry.

## G09 finding (`none#type=nil`)

Diagnostic: a temporary test was run once and then deleted (never committed). Result: `home-t2-g09-diag.result.txt`. It audited History (standard, dark) and Settings (standard) with `contrast` and `textClipped`.

The G09 keys are **not shown to be the tab-bar occlusion pattern, and D11-29 cannot apply to them**:
- Each G09 issue carries no element. The detailed description names only `SwiftUI.AccessibilityNode`, with no frame and no label. So nothing can tell whether such an element lies under the tab bar, and the D11-29 mechanism never ignores them by design.
- Counts in this run:
  - History standard: 22 contrast + 1 textClipped
  - History dark: 3 contrast + 1 textClipped
  - Settings standard: 1 contrast
- 22 reports on History at the default size are far more than the content that fits under an 83 pt tab bar. This suggests a different cause, for example unlabeled SwiftUI nodes in the calendar or the list. That is a hypothesis only.
- The fix plans 11-20 and 11-21 must still locate these elements another way.

Side finding for plan 11-20: on Settings standard, the reminder caption `A daily nudge to log what you drank.` (frame 32,830,276,20, ledger group G06) lies under the tab bar. The mechanism would ignore it if the Settings class opted in. The section headers `PROFILE`, `GUIDELINE`, `PREFERENCES` and `REMINDERS` are above the tab bar and would still fail. Whether Settings opts in is a decision for plan 11-20. No other screen was fixed here.

## Probe check

- `home-t2-probes.result.txt`: ProbeAccessibilityAuditUITests 2 passed, 0 failed. The Task 1 file `home-t1-probes.result.txt` also showed 2 passed.
- No Home audit key in any run names a `dp_` probe: the count of `element=dp_` across the red, after, partial, run1 and run2 files is 0.

## Tests

| Run | File | Result |
| --- | ---- | ------ |
| Home audit run 1 | `home-t2-run1.result.txt` | 3/3 passed |
| Home audit run 2 | `home-t2-run2.result.txt` | 3/3 passed |
| Regression: DashboardUITests, DashboardDynamicTypeUITests, ReduceMotionDashboardUITests, HistoryAccessibilityAuditUITests, DashboardViewModelTests, DPMotionTests | `home-t2-regression.result.txt` | 95 passed, 0 failed |
| Token regression: History/Insights/AddDrink/Settings/Onboarding DynamicType, InsightsUITests, AddDrinkFlowUITests, SettingsUITests | `home-t2-tokens.result.txt` | 28 passed, 1 failed: only the known-list DL-T01 `InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` (tolerated) |
| Probes | `home-t2-probes.result.txt` | 2 passed |

- The first token-regression attempt returned "result bundle incomplete". One retry was allowed, and the retry produced the result above.
- Build: Xcode MCP `BuildProject` (buildForTesting) succeeded, and `GetBuildLog` at warning severity returned 0 entries. `XcodeRefreshCodeIssuesInFile` found 0 issues on the three changed test files.
- Guards: the Task 2 verify command printed `ok`. The production-file allowed-set guard passed. The schema guard against fbd37fa passed. No Swift file in `drinkpulse` or `drinkpulseUITests` exceeds 300 lines; the largest touched file is `AccessibilityAuditSupport.swift` at 285.
- Runner: Xcode MCP only. No CLI xcodebuild was used, and the scheme was not edited.

Evidence digests (stamp directory, out of git):
- `home-t1-red.result.txt` sha256 `ef9a9f1b3231cdd4e159724fea8593cbe8a74ab391e27a71832a18a8556e9092`
- `home-t1-after.result.txt` sha256 `6d7bc701b2e3d5ce3aecf424459daeb1d01a9f5c10dbc7d21c1b988a8201af3b`
- `home-t2-run1.result.txt` sha256 `01fa1235874a7feef0c044fc09b74d0b5e668f61e6d97acfd79e724f895d5f33`
- `home-t2-run2.result.txt` sha256 `a11f6bcd9e1d05394e3f8d42b253604153c9c6fb9bd09730c0acac47ea8c1eec`
- `home-t2-regression.result.txt` sha256 `4b4ee9b5467e1829566ea38de271bc96b4f755e7aaa660ffcd306f006a45b5e1`
- `home-t2-tokens.result.txt` sha256 `6df3de8ee8eaf963926dc3e101f75bdb7ab9af4b4c11766d88a56604be68838d`
- `home-t2-probes.result.txt` sha256 `500d7ee7688589c69a6bc6b312b81ad5a92dc28ea426b552dc7cd497d923d385`
- `home-t2-g09-diag.result.txt` sha256 `b541d18704fdd60670ddfad2d89a545a7316e5dc6192ffec3c820817219d8c26`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Audit harness ran light-mode variants in dark appearance (key deviation)**
- **Found during:** Task 1. The first red run is saved as `home-t1-red-stored-dark.result.txt`.
- **Issue:** SettingsUITests stores the in-app Appearance setting "dark" in the app's user defaults. A stored Light or Dark overrides the simulator appearance that `pinAppearance` sets. As a result every "standard" and "ax5" audit variant ran in dark mode, and the light-mode findings of the plan 11-13 baseline were never measured.
- **Fix:** `AuditLaunch.arguments` adds `-dp_color_scheme system` to every variant. A launch argument takes precedence over the stored value.
- **Files modified:** `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift`
- **Commit:** ee60586
- **Note for plans 11-18 to 11-21:** re-measure the light-mode baseline per screen with this harness. Do not take light-mode keys or counts from 11-13: its "standard" and "ax5" rows were dark-mode measurements.

**2. [Owner decision, Rule 4 checkpoint] Text under the system tab bar (D11-29)**
- **Found during:** Task 2. The keys `This Week` (standard, dark) and `100%` (ax5) remained after the color work.
- **Issue:** the elements lie under the Liquid Glass tab bar at the launch scroll position. Darker colors did not help, and neither did `.scrollEdgeEffectStyle(.hard, for: .bottom)`, which was reverted.
- **Resolution:** at the checkpoint the owner chose option B, D11-29. The plan's prohibition "No audit issue is muted, allow-listed or filtered" is amended for these occluded issues only, by that owner decision. Nothing else is filtered, no audit type is excluded and nothing is hidden from accessibility.
- **Files modified:** `AccessibilityAuditOcclusion.swift` (new), `AccessibilityAuditSupport.swift`, `DashboardAccessibilityAuditUITests.swift`, `11-CONTEXT.md`
- **Commit:** ecb7c97

No `accessibilityHidden` was added in this plan: the diff of `drinkpulse/` against 284f26e has 0 matches.

## Apple API record

| API | Source consulted (Xcode MCP DocumentationSearch) | Availability | Rationale |
| --- | ------------------------------------------------ | ------------ | --------- |
| `XCUIApplication.performAccessibilityAudit(for:_:)` | XCUIAutomation, "XCUIApplication: Performing an accessibility audit": `func performAccessibilityAudit(for: XCUIAccessibilityAuditType, ((XCUIAccessibilityAuditIssue) throws -> Bool)?) throws` | XCUIAutomation, iOS 17+ (project minimum iOS 27) | The handler returns true once it has handled an issue; the helper records each issue itself. The documentation page has no prose, so the return-value semantics come from the existing harness convention and its observed behaviour. |
| `XCUIAccessibilityAuditIssue` `auditType`, `element: XCUIElement?`, `compactDescription`, `detailedDescription` | XCUIAutomation, "XCUIAccessibilityAuditIssue: Type and description" and "UI element" | same | The element is optional, so an issue without an element is never ignored. The descriptions were used only in the temporary G09 diagnostic. |
| `XCUIAccessibilityAuditType` `.contrast`, `.textClipped`, `.all` | XCUIAutomation, "XCUIAccessibilityAuditType: Accessibility audit types" | same | The two pixel-based types are the only ignorable ones (OptionSet `contains`). |
| `XCUIElementAttributes.frame` | XCUIAutomation, "XCUIElementAttributes: Size": "The frame of the element in the screen's coordinate space" | XCUIAutomation | The issue element and the tab bar share one coordinate space, so their intersection is meaningful. |
| `XCUIElementSnapshotProviding.snapshot()`, `XCUIElementSnapshot.children` | XCUIAutomation, "snapshot()": "Returns a snapshot of an element's attributes and descendant user interface hierarchy"; "XCUIElementSnapshot: Inspecting attributes" | XCUIAutomation, `@MainActor` | One call reads the tab bar frame and all of its descendants, which are used to recognise chrome. |
| `XCTIssue.init(type:compactDescription:detailedDescription:sourceCodeContext:associatedError:attachments:severity:)`, `XCTIssueReference.Severity.warning`, `XCTSourceCodeContext(location:)`, `XCTSourceCodeLocation(filePath:lineNumber:)` | XCTest, "XCTIssue: Initializers"; "XCTIssueReference.Severity.warning": "does not cause the test it's associated with to be marked as a failure, but is noted in the results" | XCTest | Logs each ignored issue and the per-variant count without failing the test, visibly in the result summary. |
| `Color.init(_:bundle:)` (asset color sets) | SwiftUI, "init(_:bundle:)": "The system determines which color within the set to use based on the environment at render time" | SwiftUI, all supported OS | Separate light and dark variants for the new text tokens. |
| Contrast guidance | HIG, "Dark Mode: Dark Mode colors": "make sure the contrast ratio between colors is no lower than 4.5:1 ... strive for ... 7:1, especially in small text" | n/a | The target for small text on glass cards in both appearances. |
| `XCUIDevice.appearance` | (pinAppearance, unchanged from plan 11-13) | iOS | The simulator appearance is pinned per variant; the launch argument now keeps the app following it. |

## Out of scope (noted, not fixed)

- `GuidelineAlertCard` builds its caption with `Text(String(format: "%.0f%% of %@ weekly limit", ...))`, and its accessibility label uses the format `"%@. %.0f%% of %@ guideline."`. Neither goes through `String(localized:)`, which is an AGENTS.md localisation rule. The plan did not touch it; a later plan should fix it.
- OBS-D, DL-O18 (plan 11-19), DL-O19 (plan 11-18) and DL-O20 (plans 11-22 and 11-23) were not touched.
- The D11-28 exemption was not used on Home.

## Threat Flags

None. The change adds no network endpoint, file access, auth path or schema change. The new test-only code reads accessibility snapshots and records issues inside the test runner. The threats are covered by the plan register:
- T-11-56: nothing is hidden; the token regression ran.
- T-11-57: two runs, both saved.

## Known Stubs

None. The stub scan of the diff against 284f26e (TODO, FIXME, placeholder, "coming soon", `print(`, Logger, URLSession) found 0 matches.

## Self-Check

Self-Check: PASSED
- The created files exist: DashboardAccessibilityAuditUITests.swift, AccessibilityAuditOcclusion.swift and the four colorsets.
- Commits ee60586, 9156c7f and ecb7c97 are ancestors of HEAD.
- The stamp-directory files exist: home-t2-run1, run2, regression, tokens, probes and g09-diag.
- The temporary G09 diagnostic test file was removed and never committed.
