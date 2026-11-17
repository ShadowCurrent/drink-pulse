---
phase: 11-ios-27-release-verification
plan: 20
subsystem: accessibility
tags: [accessibility-audit, contrast, xcuitest, gap-closure, settings, anylayout]
status: complete
requires: [11-19]
provides:
  - ungated Settings audit class SettingsAccessibilityAuditUITests (standard light, dark, AX5 light; all audit types; launch viewport), green on two consecutive runs
  - Settings section headers and captions on the dpSecondaryText token (G06)
  - Settings share of G09 located (SettingsRow label Text) and made locatable by the audit
affects: [11-21, 11-22]
tech-stack:
  added: []
  patterns:
    - "A row that switches between horizontal and vertical arrangement uses one AnyLayout, not Group { if … else … }; the conditional form left the label's accessibility node without an element in the audit"
    - "Element-less audit issues (none#type=nil) are located by elimination with temporary app edits and a temporary diagnostic test, both reverted or deleted before commit"
key-files:
  created:
    - drinkpulseUITests/Features/Settings/SettingsAccessibilityAuditUITests.swift
  modified:
    - drinkpulse/Features/Settings/Components/SettingsSection.swift
    - drinkpulse/Features/Settings/Components/ReminderSection.swift
    - drinkpulse/Features/Settings/Components/WeeklySummarySection.swift
    - drinkpulse/Features/Settings/Components/HealthSection.swift
    - drinkpulse/Features/Settings/Components/AppVersionFooter.swift
    - drinkpulse/Features/Settings/Components/SettingsRow.swift
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
key-decisions:
  - "The Settings audit class opts in to D11-29 in all three variants: the remaining findings (reminder row and caption at the default size, Preferences header and first row at AX5) were verified from their logged frames to lie under the tab bar (0,791,402,83). No new owner decision was needed; D11-31 stays free."
  - "G09 on Settings fixed at the source (SettingsRow AnyLayout) instead of extending D11-29 to element-less issues"
metrics:
  duration: "about 42 min wall clock on 2026-11-17 (15:48Z to 16:30Z)"
  completed: 2026-11-17
actuals:
  tokens: 3800
  tasks: 2
  commits: 2
plan_head_before: ab3d66028951c311d3ff7e264ce29580ff076afe
plan_head_after: 9a4b44fee856e6f03d4d75c50c61676c25106695
requirements-completed: []
---

# Phase 11 Plan 20: Settings accessibility audit findings Summary

Settings now has no failing audit finding at the default size, in dark appearance or at AX5. Two consecutive runs of the new ungated all-types audit class confirm it.

- **G06:** the section headers and the reminder caption use the shared `dpSecondaryText` token.
- **Settings share of G09:** this was the element-less contrast issue. Elimination traced it to the label `Text` of `SettingsRow`. The row now switches its layout with one `AnyLayout`, so the audit can tie the issue to its element.
- **D11-29:** the label and the caption lie under the system tab bar at the launch viewport, so D11-29 ignores them. Each ignored issue is logged.

## Outcome

- Tasks: 2 of 2 done.
- Requirements VER-03 and VER-01 stay open, because Onboarding, History (11-21), the final gated re-run (11-22), G-2 and DL-O19 are still open. No requirement was marked complete.
- Runner: Xcode MCP only (BuildProject, GetBuildLog, RunSomeTests, RenderPreview, XcodeRefreshCodeIssuesInFile, DocumentationSearch). No CLI xcodebuild was used, and the scheme was not edited.
- No owner checkpoint was hit:
  - The stop rule (finding on system chrome with no app-side fix) did not apply. Every remaining finding is app text.
  - No new decision id was used. D11-31 is still the next free id.

### Audit key counts (distinct keys, `LC_ALL=C sort -u`, variant+type+element; light re-measured with `-dp_color_scheme system`)

| Variant | Red (`set-t1-red`) | After G06 fix (`set-t1-after`, t1 run1/run2) | Task 2 run 1 / run 2 (failing) | D11-29 ignored per run |
| --- | --- | --- | --- | --- |
| standard (light) | 6: contrast `PROFILE`, `GUIDELINE`, `PREFERENCES`, `REMINDERS`, `A daily nudge to log what you drank.`, `none#type=nil` | 1: `none#type=nil` | 0 / 0 | 2: `Daily log reminder` (32,783,165,25), `A daily nudge to log what you drank.` (32,830,276,20) |
| dark | 2: contrast `A daily nudge…`, `none#type=nil` | 1: `none#type=nil` | 0 / 0 | 2: same two as standard, same frames |
| ax5 (light) | 3: contrast `GUIDELINE`, `PREFERENCES`, `none#type=nil` | 1: `none#type=nil` | 0 / 0 | 2: `PREFERENCES` (20,777,290,53), `Appearance` (32,848,273,63) |
| total | 11 | 3 | 0 / 0 | 6 per run |

- After the G06 fix, the D11-29 column held 1 per variant: the caption at standard and dark, `PREFERENCES` at AX5.
- The tab bar frame was `0,791,402,83` in every run, with tabBarFound=true. The ignored set is identical in both Task 2 runs.
- Each run reports exactly 1 contrast issue per variant. The 11-13 counts (standard 8, AX5 4, dark 8) were dark-mode measurements, and the dark row also included the G08 key that plan 11-15 fixed. The red column is the re-measured light baseline.
- Task 1 target keys (`set-t1-target-keys.txt`, 5 lines): standard `PROFILE`, `GUIDELINE`, `PREFERENCES`, `REMINDERS`, and AX5 `GUIDELINE`. All 5 are in the red file (5 matches) and none are in the after file.

### G09 location (found by elimination: temporary app edits reverted, temporary diagnostic test `TempSettingsAuditDiag` deleted, never committed)

Every element-less issue had the detailed description "Contrast failed for SwiftUI.AccessibilityNode", with no frame. The table lists the experiments; "SwiftUI.AccessibilityNode" means one element-less issue.

| Experiment | standard | dark | ax5 | Conclusion |
| --- | --- | --- | --- | --- |
| baseline after G06 fix | 1 | 1 | 1 | |
| guideline chevron removed | 1 + `WHO (Global)` | not run | 2 | not the chevron |
| Date of Birth row removed | 1 | 1 | 1 | not the DatePicker |
| Sex picker row removed | 1 | 1 | 1 | not the menu picker |
| whole Profile section removed (content up ~190 pt) | 0 | 1 | 1 | position-dependent |
| tab bar hidden (`.toolbar(.hidden, for: .tabBar)`) | 0 | 0 | 1 | at default size, tied to text under the tab bar |
| reminder Toggle replaced by `Text("X")` | 2 | 2 | not run | row texts give element-less issues |
| content shifted down 12 pt | 1 | 1 | not run | not the edge position |
| `SettingsRow` with `.accessibilityElement(children: .contain)` | 1 | 1 | 1 | a container does not help |
| reminder row label `Text` removed | 0 | 0 | not run | **the `SettingsRow` label `Text`** |
| `SettingsRow` as one `AnyLayout` (kept) | 0 failing, label named and ignored | same | 0 failing, `Appearance` named and ignored | the node now resolves to its element |

- **Owning view:** `drinkpulse/Features/Settings/Components/SettingsRow.swift`. Element type: `StaticText` (row label).
  - Default size: `Daily log reminder`, frame 32,783,165,25. It straddles the top of the tab bar.
  - AX5: `Appearance`, frame 32,848,273,63. It lies under the tab bar and runs past the screen bottom.
- **Shared with History: no.** `SettingsRow` is used only by Settings files (SettingsView, AppearanceModeRow, ReminderSection, WeeklySummarySection, HealthSection, SettingsSection previews). Plan 11-21 must locate the History share of G09 on its own.
- **Root cause, a hypothesis that fits all runs:** the label's accessibility node sat in the `Group { if … else … }` conditional. The audit could not resolve that node to an `XCUIElement`, so `issue.element` was nil, and D11-29 never ignores such issues by design. With one `AnyLayout`, the same text resolves to its element. The issue is then a normal under-tab-bar contrast finding.
- **The finding itself is not a contrast defect of the row:** the label is primary text. With the tab bar hidden, standard and dark show no issue. With the content shifted so the row is clear of the tab bar, the row shows no issue either.

## Findings fixed per view

| View | Fix |
| --- | --- |
| `SettingsSection` | Section header text uses `Color.dpSecondaryText` instead of `.secondary`. |
| `ReminderSection` | The hint caption uses `Color.dpSecondaryText`; the denied text stays `Color.red`. |
| `WeeklySummarySection`, `HealthSection` | Same caption change (below the launch viewport; same pattern as G06). |
| `AppVersionFooter` | Version text uses `Color.dpSecondaryText` (below the launch viewport). |
| `SettingsRow` | One `AnyLayout` (`HStackLayout` at regular sizes, `VStackLayout(alignment: .leading, spacing: 6)` at accessibility sizes), with `Spacer()` only in the horizontal arrangement. The row frame is `.frame(maxWidth: .infinity, alignment: .leading)` in both arrangements. |

- **Shared color tokens:** none changed. `DPColors`, `DPSemanticColors`, `RiskLevel+Color` and the asset catalog are untouched, and the existing `dpSecondaryText` (11-17) is reused. The token regression set was not needed, because no token changed.
- **`Localizable.xcstrings`:** unchanged. No new user-facing text.
- **`accessibilityHidden`:** none added. Nothing was muted, no audit type was excluded, and no text size was capped.
- **OBS-C:** `SettingsView` (the no-profile `ProgressView`) is unchanged against ab3d660.

## Regular-size visual changes (owner-visible)

- **Settings section headers** (PROFILE, GUIDELINE, PREFERENCES, REMINDERS, WEEKLY SUMMARY, APPLE HEALTH, PRIVACY & SECURITY, DATA): slightly darker grey in light mode and slightly lighter in dark mode. They use `dpSecondaryText`, the same token as Home and Insights since 11-17.
- **Captions under the reminder, weekly check-in and Apple Health toggles**, and the **version footer**: the same small shift in shade.
- **`SettingsRow` layout:** no visible change at regular size. The audit tree frames of the row labels and controls match before and after (for example `Daily log reminder` 32,783,165,25). The RenderPreview of `SettingsView` (light, default size) looks the same.
- At accessibility sizes, the row label and control now keep their identity when the text size changes (AnyLayout). There is no visible layout difference; `SettingsDynamicTypeUITests` passes.

## Tests

| Run | File | Result |
| --- | --- | --- |
| Settings audit, Task 1 red | `set-t1-red.result.txt` | 0/3 passed (11 distinct keys) |
| Settings audit, after G06 fix | `set-t1-after.result.txt` | 0/3 passed (only `none#type=nil`, 1 per variant) |
| Settings audit, Task 1 run 1 / run 2 | `set-t1-run1/run2.result.txt` | 0/3 passed each, only `none#type=nil` failing |
| Task 1 regression: SettingsDynamicType 2, SettingsUITests 5, GuidelinePicker 3, HealthSettings 2, ReminderSettings 2, WeeklySummarySettings 2, AppVersion 1 | `set-t1-regression.result.txt` | 17/17 passed |
| Settings audit, Task 2 run 1 | `set-t2-run1.result.txt` | 3/3 passed, 0 failed, 0 skipped |
| Settings audit, Task 2 run 2 | `set-t2-run2.result.txt` | 3/3 passed, 0 failed, 0 skipped |
| Task 2 regression: the 17 Settings tests above + DashboardAccessibilityAudit 3, AddDrinkAccessibilityAudit 2, InsightsAccessibilityAudit 4 | `set-t2-regression.result.txt` | 26/26 passed |

- ExportUITests was not run, as the plan says: DL-T04 is a known flake, and no export code changed. DL-T01 is not in this plan's sets.
- Build: Xcode MCP `BuildProject` (buildForTesting) succeeded. `GetBuildLog` at warning severity returned 0 entries after each code change. `XcodeRefreshCodeIssuesInFile` found 0 issues on SettingsRow and the audit test.
- Guards: the production-file set, the schema guard against fbd37fa and the 300-line limit all passed. Both verify commands printed `ok`, with the line-count adjustment described in deviation 2. The largest touched production file is DataSection.swift at 235 lines (unchanged); SettingsRow.swift is 95 lines.

Evidence digests (stamp directory `20261114T121519Z`, out of git), sha256:
- `set-t1-red.result.txt` `7a4aa7ad3ff9947f2d6364f79061d28985b08cd6b1196b3e4babe4cb523af4a0`
- `set-t1-target-keys.txt` `58e27784726fc910c1c274673cdd85aaf59a5d5a2740453e2d797c161e42f27b`
- `set-t1-after.result.txt` `2968756764e85d27fb079e14ce16b3775e79c3aca6a037ca8a80d9d1c5aed9a1`
- `set-t1-run1.result.txt` `9643a6b0d36d5f1b833245da18cfe4ac410621c8046f2759eb94bd6d38b9d9af`
- `set-t1-run2.result.txt` `ee289a564b6c68428c86f09fecaa832db51f6bfc063d219c55c32c60f326a809`
- `set-t1-regression.result.txt` `eacf76093ec88755c3459d8e5a7b10647ec945e5bacc31f75fe1617c1f0c2fbb`
- `set-t2-run1.result.txt` `702a3ac32564f423d46f1674af9ab8d6359c27ba874c85844fb59aa48b4ceccd`
- `set-t2-run2.result.txt` `843c4daf4c0df9c5d56f82440c88f3f3ad787cb63747e6f1a092f8336524d1da`
- `set-t2-regression.result.txt` `4405eb17e4d2b948fcbd67d2cc76204f939e1b1511508e328a8dbfee730ab9e2`

## Deviations from Plan

**1. [D11-29 used] Settings class opts in for all three variants**
- After the G06 fix, the caption (standard, dark) and the `PREFERENCES` header (AX5) still failed contrast with `dpSecondaryText`. The logged frames show both under the tab bar (caption fully inside it; header 777–830 against tab bar 791–874).
- With the tab bar hidden in an experiment, standard and dark showed no issue.
- The carry-over allowed the opt-in for genuine under-tab-bar app text, and it is used only for that. Ignored counts: 2 per variant per run in the final runs.

**2. [Verify adjustment] Plan grep counts include D11-29 warning lines**
- The plan was written before D11-29. Task 1 verify counts every `element=` line, and Task 2 verify counts every `screen=` line. The D11-29 warning lines contain both strings:
  - Task 1: 6 such lines over run1 and run2
  - Task 2 run2: 9 lines (6 ignored issues and 3 count lines)
- I evaluated the same checks on failure lines only (`Accessibility audit issue: screen=`). The result is 0 in both tasks.
- Every other part of both verify commands passed as written.

**3. [Format] Target keys carry the variant**
- The target keys are written as `variant=<v> type=<t> element=<k>` instead of `type=<t> element=<k>`. The unprefixed `type=contrast element=PREFERENCES` also matches the D11-29 warning for the AX5 header, which is intentionally ignored and not fixed. Each prefixed line is still a substring of the red failure line.

**4. [Rule 2 - consistency] Captions below the launch viewport**
- The weekly summary and Health captions and the version footer got the same `dpSecondaryText` change. They are the same G06 pattern below the launch viewport.
- A scrolled diagnostic audit also reported them, but that measurement is outside this plan's gate and is not claimed as proof.
- `AppVersionFooter.swift` is on the plan's conditional list.

**5. [Order] G09 fix found during Task 1**
- The `SettingsRow` change was found while locating the element-less issue in Task 1. It was held back so that the Task 1 runs (`set-t1-after`, `run1`, `run2`) show only `none#type=nil` failing.
- It was then committed as Task 2, so the commits keep the plan's task boundaries.

**Observation (not fixed, out of scope):**
- A temporary audit after scrolling Settings toward the bottom also reported contrast on `WEEKLY SUMMARY`, `DATA`, `Export all data` and `settings.appVersion`.
- Several of these lay under the navigation bar's scroll edge or under the tab bar during the scroll. The audit may also have caught a moving frame.
- The plan's gate is the launch viewport. If needed, plan 11-22 can record this for a scrolled audit.

## Apple API record

| API | Source consulted | Availability | Rationale |
| --- | --- | --- | --- |
| `AnyLayout`, `HStackLayout`, `VStackLayout(alignment:spacing:)` | Xcode MCP DocumentationSearch: SwiftUI "AnyLayout" ("Use an AnyLayout instance to enable dynamically changing the type of a layout container without destroying the state of the subviews", with a Dynamic Type example); "HStackLayout"/"VStackLayout" ("behaves like an HStack/VStack, but conforms to the Layout protocol so you can use it in the conditional layouts that you construct with AnyLayout"); "Custom layout: Transitioning between layout types" | SwiftUI, iOS 16+ (project minimum iOS 27) | Replaces `Group { if … else … }` in `SettingsRow`; keeps the label and control identity across text sizes, and the audit then resolves the label's element |
| `Color(_:bundle:)` asset token `dpSecondaryText`, `foregroundStyle(_:)` | as recorded in 11-17 | SwiftUI | Reused for headers and captions; no token change |
| `View.toolbar(_:for:)` with `.hidden`, `.tabBar` | used only in a reverted experiment | SwiftUI | Located the tab-bar dependence; not shipped |
| `accessibilityElement(children: .contain)` | used only in a reverted experiment; not separately consulted in this plan | SwiftUI | Did not make the node locatable; not shipped |
| `XCUIApplication.performAccessibilityAudit(for:_:)`, `XCUIAccessibilityAuditType.all`, `XCUIAccessibilityAuditIssue.element/detailedDescription` | as recorded in 11-17 | XCUIAutomation | Settings audit class; the detailed description ("Contrast failed for SwiftUI.AccessibilityNode") was read in the diagnostic |
| `XCUIDevice.appearance` | as recorded in 11-17 (`pinAppearance`) | iOS | Light and dark pinned per test |

## Known Stubs

None. A scan of the diff against ab3d660 for TODO, FIXME, placeholder, `print(`, Logger and URLSession found 0 matches in production code.

## Threat Flags

None. No network, file, auth or schema surface was added.
- T-11-63: the G09 element was located and made locatable, not hidden. No shared token changed.
- T-11-64: two consecutive green runs, both saved, with identical ignored sets.

## Notes for later plans

- 11-21 (History G09): the Settings share was a label inside `Group { if … else … }`. Look for the same conditional-container pattern around History texts. The technique that worked was removing one part at a time, plus hiding the tab bar in an experiment.
- 11-22 (final gated re-run): the gated `AccessibilityAuditUITests` Settings methods do not opt in to D11-29. They will still report the reminder label and caption (standard, dark) and `PREFERENCES` and `Appearance` (AX5). Use the same opt-in there, or record the difference.
- The next free decision id is D11-31.

## Self-Check: PASSED

- Files exist: `SettingsAccessibilityAuditUITests.swift`, `SettingsRow.swift`.
- Commits 89db991 and 9a4b44f are ancestors of HEAD.
- The temporary diagnostic test (`TempSettingsAuditDiag`) was deleted and never committed. Every temporary app edit was reverted; `git status` showed only the intended files before each commit.
