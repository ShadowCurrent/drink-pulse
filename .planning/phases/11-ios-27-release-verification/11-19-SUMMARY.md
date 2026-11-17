---
phase: 11-ios-27-release-verification
plan: 19
subsystem: accessibility
tags: [accessibility-audit, swift-charts, contrast, hit-region, xcuitest, gap-closure, insights]
status: complete
requires: [11-18]
provides:
  - ungated Insights audit class InsightsAccessibilityAuditUITests (standard light, dark, AX5 light; all audit types; launch viewport) plus a mark-label test, green on two consecutive runs
  - area-chart day marks labelled with the formatted date and valued with the formatted value (one Plot element per day), no raw timestamp exposed
  - x-axis label fix for the area chart in every period and text size (DL-O18)
  - owner decision D11-30 and its shared, opt-in mechanism AuditChartDayMarks (hitRegion on labelled chart day marks only)
affects: [11-20, 11-21, 11-22, 11-23]
tech-stack:
  added: []
  patterns:
    - "Marks that draw the same data point (AreaMark plus LineMark) are wrapped in a Plot that carries the accessibility label and value, so Swift Charts exposes one element per point"
    - "On a categorical Swift Charts axis, choose the labelled subset inside the AxisMarks content closure; the values list alone does not limit the labels"
    - "Audit exemptions are explicit per-call opt-ins decided at audit time from the real element tree, each ignored issue logged as a warning-severity XCTIssue with type, key and frame"
key-files:
  created:
    - drinkpulseUITests/Features/Insights/InsightsAccessibilityAuditUITests.swift
    - drinkpulseUITests/Features/Shell/AccessibilityAuditChartMarks.swift
    - drinkpulse/Features/Insights/Components/AlcoholAreaChart+Previews.swift
  modified:
    - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
    - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift
    - drinkpulse/Features/Insights/Components/InsightsScopeNavigator.swift
    - drinkpulse/Features/Insights/Components/HealthMetricsCard.swift
    - drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift
    - .planning/phases/11-ios-27-release-verification/11-CONTEXT.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
key-decisions:
  - "D11-30 (owner, 2026-11-17, option A at the 11-19 hit-region checkpoint): the labelled per-day chart mark elements stay accessible; the Insights audit class exempts only hitRegion issues on those marks, matched at audit time by label and frame against the chart's direct children, each logged as a warning and counted per variant; G05 hitRegion stays open with exemption"
  - "Area and line marks of a day grouped in a Plot instead of hiding the redundant AreaMark from accessibility (both cleared the raw-key elements; Plot hides nothing)"
metrics:
  duration: "about 4 h 10 min wall clock on 2026-11-17 (11:35Z to 15:45Z), including a rate-limit pause and the owner checkpoint"
  completed: 2026-11-17
actuals:
  tokens: 7300
  tasks: 2
  commits: 2
plan_head_before: 13f5dc8d87ded4c43c104f40b44a1707e7839b8f
plan_head_after: def977dd02d41eaa6e636212aa0da2b21340900b
requirements-completed: []
---

# Phase 11 Plan 19: Insights accessibility audit findings Summary

Insights has no failing audit finding at the default size, in dark appearance and at AX5, on two consecutive runs of the new ungated all-types audit class. The area-chart day marks now carry a readable date and value instead of a raw timestamp, and the chart's x-axis labels no longer overlap in any period or text size (DL-O18). Two owner-approved exemptions are still in force, and every issue they skip is logged. D11-30 covers the hit regions of the chart day marks, which Swift Charts cannot enlarge. D11-29 covers the second Health Impact row, which sits under the tab bar.

## Outcome

- Tasks: 2 of 2 done. Requirements VER-03 and VER-01 stay open, because other screens, G-2 and DL-O19 are still open. No requirement was marked complete.
- Runner: Xcode MCP only (BuildProject, GetBuildLog, RunSomeTests, RenderPreview, XcodeRefreshCodeIssuesInFile, DocumentationSearch). No CLI xcodebuild was used, and the scheme was not edited.
- Owner checkpoint: Task 1 hit the plan's hit-region stop rule. The owner chose option A (keep the finding, with a narrow exemption), recorded as D11-30 in `11-CONTEXT.md`. The CONTEXT entry also notes that plan 11-23 must use the next free id (D11-31 or later).

### Audit key counts (distinct keys, `LC_ALL=C sort -u`, variant+type+element; light mode re-measured with `-dp_color_scheme system`)

| Variant | Red (`ins-t1-red`) | After Task 1 (`ins-t1-after`) | Task 2 run 1 / run 2 (failing) | Ignored per run |
| --- | --- | --- | --- | --- |
| standard (light) | 20: contrast 13, sufficientElementDescription 7 | 20: contrast 13, hitRegion 7 | 0 / 0 | D11-30: 7 (hitRegion, day marks); D11-29: 4 (contrast) |
| dark | 25: contrast 11, hitRegion 7, sufficientElementDescription 7 | 18: contrast 11, hitRegion 7 | 0 / 0 | D11-30: 7; D11-29: 3 (contrast) |
| ax5 (light) | 4: contrast 4 | 4: contrast 4 | 0 / 0 | D11-30: 0 (chartFound=true); D11-29 not opted in |
| total | 49 | 42 | 0 / 0 | |

- The 11-13 light-mode Insights keys were dark-mode measurements (11-17 deviation 1). The red column above is the re-measured light baseline.
- Task 1 target keys (`ins-t1-target-keys.txt`, 14 lines): 7 `sufficientElementDescription` and 7 `hitRegion` keys named by raw timestamps (`816476400.0` … `816994800.0`). All 14 are in the red file and none are in the after file.
- D11-30 ignored issues, identical in both green runs:
  - standard and dark: `hitRegion` on `Mon 16. Nov` … `Sun 22. Nov`
  - each frame is about 7 x 132 pt, for example `53,367,7,132`
  - chartFound=true in every variant
- D11-29 ignored issues, identical in both green runs; the tab bar frame was `0,791,402,83`:
  - standard: `contrast` on `Drink-Free Days` (44,804,117,19), `0/2` (44,832,32,24), `Longest Streak` (217,804,109,19) and `0 d` (217,832,30,24)
  - dark: the same issues without `Drink-Free Days`
  - All of them lie fully inside the tab bar frame. They are the second row of the Health Impact card at the launch scroll position.

### Root cause of the raw-timestamp marks (found with a temporary diagnostic test, deleted and never committed)

| Experiment | Result |
| --- | --- |
| baseline (AreaMark + LineMark per day, x = timestamp string key) | 7 merged elements, label `816476400.0`, value `total 30` (twice the day's 15 g), about 48 pt wide |
| `.accessibilityLabel` / `.accessibilityValue` on both marks | no change: Swift Charts merged the two marks per category and ignored the mark labels |
| AreaMark `stacking: .unstacked` | value became `average 15`, label still the raw key |
| AreaMark `.accessibilityHidden(true)`, LineMark labelled | raw keys gone (rejected: hides a mark) |
| `Plot { AreaMark; LineMark }` with label and value (kept) | 7 elements, label `Mon 16. Nov`, value `1.5 std`, nothing hidden |

## Findings fixed per view

| View | Fix |
| ---- | --- |
| `AlcoholAreaChart` | Area and line of a day are wrapped in a `Plot` with `.accessibilityLabel(date.formatted(markDateFormat))` and `.accessibilityValue(formattedValue(grams))`. `markDateFormat` is the callout format plus the parts the callout leaves to context: day and month in Week, the year in Year. The x axis applies the label subset inside the `AxisMarks` closure and uses evenly spaced keys, `AxisValueLabel(centered: false, collisionResolution: .greedy)`, and three segment-centred labels at accessibility sizes. |
| `InsightsHeroCard` | `TOTAL` and `vs prev.` use `Color.dpSecondaryText`. The trend badge text uses `RiskLevel.safe/exceeded.textColor` (`dpSecondaryText` when unchanged). The badge fill is unchanged. |
| `InsightsScopeNavigator` | The current period's label and range are plain text, not a disabled button: a disabled button dims its label below the contrast minimum. Other periods keep the jump-to-now button with its label and hint. The range text uses `dpSecondaryText`. The NOW pill text is `.primary` on its unchanged tint fill. |
| `HealthMetricsCard` (`MetricCell`) | Title and subtitle use `dpSecondaryText`. |

- Shared color tokens: none changed. `DPColors`, `DPSemanticColors`, `RiskLevel+Color` and the asset catalog are untouched; the existing 11-17 tokens are reused. The token regression set was still run, because the verify condition is true through the 11-17 token changes since fc506f4.
- `Localizable.xcstrings`: unchanged. The new accessibility text is formatted dates and the existing value formatter.
- `accessibilityHidden`: none added. Nothing was muted, no audit type was excluded, and no text size was capped.
- Chart descriptors: `AlcoholAreaChart+Accessibility.swift` and `WeekdayBarChart+Accessibility.swift` are unchanged against fc506f4, and each chart still has exactly one `accessibilityChartDescriptor` call. OBS-A, CHK-01 and CHK-02 are untouched.
- `WeekdayBarChart`: not changed. Its bars already carry an explicit label, and the audit raised no finding on them.

## Regular-size visual changes (owner-visible)

- **Area chart x-axis (every period):** the labels sit under their own data point instead of half a step to the right. Month shows 5 readable dates (for example `19. Oct … 17. Nov`) instead of 30 overlapping ones. Year and All show 6 months, and Week shows all 7 days. This is the DL-O18 fix.
- **NOW pill:** the text is now black or white (primary) instead of accent orange. The orange tint background stays.
- **Trend badge (`↓ 100%`):** the text is the darker green or red text token in light mode (lighter in dark mode). The tinted capsule is unchanged.
- **Secondary text** (`TOTAL`, `vs prev. week …`, the date range under the period name, metric titles and subtitles): slightly darker in light mode and lighter in dark mode (`dpSecondaryText`, the same token Home uses since 11-17).
- **Current period name** (`This week`): full primary contrast instead of the dimmed disabled look.
- At accessibility sizes only: the area chart shows three segment-centred date labels, and greedy collision resolution may drop the middle one.

## DL-O18 outcome (row stays open)

- **Fixed, not closed.** The ledger row records the evidence, and its Status stays "open" until the owner re-observes CHK-07. The plan forbids closing ledger rows.
- **Apple APIs consulted:** see the Apple API record. They are `AxisMarks(values:content:)`, `AxisValueLabel(centered:anchor:…collisionResolution:…)`, `AxisValueLabelCollisionResolution.greedy(priority:minimumSpacing:)` and "Customizing axes in Swift Charts".
- **Evidence (RenderPreview of the per-period previews in `AlcoholAreaChart+Previews.swift`):**
  - before the fix, Month at default size: every day labelled, unreadable
  - after the fix, default size: Week 7, Month 5, Year 6, All 6 labels
  - after the fix, AX5: Week `Thu Sat Mon`, Month `24. Oct`/`13. Nov`, Year `Feb Jun Oct`, All `Nov 24`/`Jul 26`
  - no overlap and no clipping in any combination
- **UI assertion: not feasible.** Axis labels are not accessibility elements, as the `InsightsDynamicTypeUITests` header already notes.
- **Rejected along the way:** inward `anchor` values for the edge labels gave inconsistent placement, so they were replaced by segment-centred keys at accessibility sizes.
- **RenderPreview caveat:** previews selected with `previewDefinitionIndexInFile` or variant overrides were often stale or wrong. All AX5 and Week default were confirmed through a single-preview temporary file, deleted and never committed.

## DL-T01 note

`InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` failed in the regression run and again when re-run alone: Week chart y=327.0, All chart y=321.33, tolerance 1.0. The same values appear in the 11-17 and 11-18 token regression files, before this plan, so plan 11-19 did not change them. The ledger's original record (y 323 vs 320) dates from 2026-11-09, before plan 11-16, so 11-16 did not introduce the failure; only the measured offsets moved. `InsightsUITests` is not in this plan's file scope. The test is left as it is, and the row stays open.

## OBS-A observation (not a fix, not a claim)

Before this plan, each area-chart day was exposed as one merged element. Its label was the raw category key (a timestamp such as `816476400.0`), and its value was `total N`, twice the day's grams and unformatted. That fits the owner's OBS-A report of "a very large number" when focusing a chart point. After this plan the element reads, for example, `Mon 16. Nov`, value `1.5 std`. Nothing was checked with VoiceOver: the simulator cannot exercise the rotor or the Audio Graph (CHK-00). OBS-A, CHK-01 and CHK-02 stay open.

## Owner notes recorded

- The owner reviewed and approved the 11-18 change from the toolbar "Cancel" to the system close "×" glyph ("super, dobry pomysł", 2026-11-17).
- D11-30: option A, recorded in `11-CONTEXT.md`.

## Tests

| Run | File | Result |
| --- | --- | --- |
| Insights audit, Task 1 red | `ins-t1-red.result.txt` | 0/3 passed (49 distinct keys) |
| Insights audit, Task 1 after (Plot labels) | `ins-t1-after.result.txt` | 1/4 passed (mark-label test green; 42 keys, none raw) |
| InsightsScrubUITests 2, InsightsDynamicTypeUITests 2 (after Task 1) | `ins-t1-scrub-dyntype.result.txt` | 4/4 passed |
| Insights audit run 1 (final code) | `ins-t2-run1.result.txt` | 4/4 passed, 0 failed, 0 skipped |
| Insights audit run 2 (final code) | `ins-t2-run2.result.txt` | 4/4 passed, 0 failed, 0 skipped |
| Regression: InsightsDynamicType 2, InsightsScrub 2, InsightsStreak 1, InsightsDrinkFreeDays 1, InsightsUITests 7, DashboardAccessibilityAudit 3, AddDrinkAccessibilityAudit 2, AlcoholAreaChartAXDescriptorTests 4, WeekdayBarChartAXDescriptorTests 4, InsightsViewModelTests 63 | `ins-t2-regression.result.txt` | 88 passed, 1 failed: only the known-list DL-T01 |
| DL-T01 re-run alone | `ins-t2-dlt01-alone.result.txt` | failed again, same values (known list, tolerated) |
| Token regression: HistoryAccessibilityAudit 2, HistoryDynamicType 1, DashboardDynamicType 2, AddDrinkDynamicType 2, SettingsDynamicType 2, OnboardingDynamicType 4 | `ins-t2-tokens.result.txt` | 13/13 passed |

- Home audit (D11-29) in the regression run is still green, and the Add Drink audit is still green; the helper change is backward compatible because the new parameter defaults to nil.
- Build: Xcode MCP `BuildProject` (buildForTesting) succeeded. `GetBuildLog` at warning severity returned 0 entries. `XcodeRefreshCodeIssuesInFile` found 0 issues on AlcoholAreaChart, AlcoholAreaChart+Previews, InsightsHeroCard, InsightsScopeNavigator, HealthMetricsCard, AccessibilityAuditChartMarks and the Insights audit test.
- Guards: both Task verify commands printed `ok`. They cover the allowed production-file set, the descriptor files against fc506f4, the schema guard against fbd37fa and the 300-line limit. The largest touched production file is AlcoholAreaChart.swift at 200 lines; AccessibilityAuditSupport.swift is at 298.
- Previews: RenderPreview of the per-period chart previews (default and AX5) and of InsightsView (light, default size) rendered.

Evidence digests (stamp directory `20261114T121519Z`, out of git), sha256:
- `ins-t1-red.result.txt` `702e04962f97f9a23eedb6d1971e98e29afe1a00a8851f60e9b03183f9c3976b`
- `ins-t1-target-keys.txt` `210a3f3a4ecba9155a26595e9099b4b310db12cb2f230cd9ebdd08a37fe426bf`
- `ins-t1-after.result.txt` `702d9b3403885009f9522197e01fc0aca74c134bbb21bbc3f2c72714a76a70bf`
- `ins-t1-scrub-dyntype.result.txt` `98ea9accebec16453ebdf361cbb24790046f1f99d4d78ea514cc629ead96bbc2`
- `ins-t2-run1.result.txt` `5448db2aca232a2a3b718858179589e9f79bc47283a15e12e24f557a7eb59708`
- `ins-t2-run2.result.txt` `cac3dec7f17de478d35965921db11f70c46db835d55f7bac8fda1624a2cec1ee`
- `ins-t2-regression.result.txt` `7fcca5f82124e573313c34692ff2b1b7b5b5f827eea5734c0224d2036440e48d`
- `ins-t2-dlt01-alone.result.txt` `f6e776f07fb6bfb09b9d144894708ad4e8e9e8d201630b0e9677fae8d1c40818`
- `ins-t2-tokens.result.txt` `c663ad991dc9d8cfec9496b441619624d991c11ba6c1cd2402fa2c478e76b319`

## Deviations from Plan

**1. [Owner checkpoint] Hit-region stop rule, resolved as D11-30**
- After the marks were labelled, all 7 day marks reported `hitRegion` in standard and dark. There is no Swift Charts API to enlarge a mark element.
- I stopped and returned a checkpoint. The owner chose option A, and the exemption was built as the opt-in `exemptChartDayMarkHitRegionsOf` in the new `AccessibilityAuditChartMarks.swift`.
- The exemption reads the chart's children lazily, at the first `hitRegion` issue. A snapshot taken before the audit gave frames that did not match in light mode, probably because the marks were still animating in.

**2. [Rule 1 - Bug] DL-O18 cause was in the axis code, not the label count**
- The categorical axis ignored the `values:` list, so the old `labelKeys` stride never took effect.
- Fixed within this plan's allowed file (`AlcoholAreaChart.swift`), as the carry-over asked.

**3. [Technique] `Plot` grouping instead of per-mark labels**
- The plan expected labels on each mark. Swift Charts merges marks that share a category into one element, so the labels went on a `Plot` that wraps both marks. Nothing is hidden.

**4. [Test design] The mark-label test compares the mark value with the scrubbed hero total, not the callout**
- The scrub callout (a chart annotation) is not in the accessibility tree; a diagnostic sample during the hold found no element containing "—".
- The test therefore asserts one element per day, a non-numeric label and a non-empty value for each mark. It also asserts that some mark's value equals the hero total shown while scrubbing (the same `formattedValue`), and that no element anywhere exposes a 6-digit-plus numeric identifier or label.

**5. [D11-29 used] Second Health Impact row**
- After the token fixes, the only remaining findings were `contrast` on the second metric row, fully inside the tab bar frame (verified from the logged frames).
- The class opts in to D11-29 for standard and dark only. AX5 does not need it.

**6. [Observation, not fixed] Pre-existing test weakness**
- `InsightsScrubUITests.test_scrubbingWeekdayChart_showsCallout` looks for an element whose label is exactly a weekday name. The callout is not an accessibility element, so the test may pass without seeing the callout.
- It is out of this plan's scope and was not changed. Flagged for a later plan.

## Apple API record

| API | Source consulted (Xcode MCP DocumentationSearch) | Availability | Rationale |
| --- | --- | --- | --- |
| `ChartContent.accessibilityLabel(_:)`, `accessibilityValue(_:)` | Charts, "ChartContent: Configuring accessibility": "Adds a label to the chart content that describes its contents" / "Adds a description of the value that the chart content contains" | Swift Charts (iOS 16+; project minimum iOS 27) | Readable date and value per day mark |
| `ChartContent.accessibilityHidden(_:)` | same page | Swift Charts | Tried in an experiment only; not kept |
| `Plot` | Charts, "Plot": "A mechanism for grouping chart contents into a single entity" | Swift Charts | Area and line of one day become one labelled element |
| `AreaMark` stacking (`MarkStackingMethod`) | Charts, "AreaMark: Add detail with a stacked area chart" | Swift Charts | Tried `.unstacked` in an experiment; not kept |
| `AxisMarks(preset:position:values:content:)` | Charts, "AxisMarks" initializers; "Customizing axes in Swift Charts: Specify axis values" | Swift Charts | Kept the values list and added the subset check in the closure, because the categorical axis labelled every category |
| `AxisValueLabel(centered:anchor:multiLabelAlignment:collisionResolution:offsetsMarks:orientation:horizontalSpacing:verticalSpacing:content:)` | Charts: "centered — If nil, default to true for discrete data"; "collisionResolution — How labels that collide with others are resolved" | Swift Charts | `centered: false` puts each label under its point; `anchor` was tried and not kept |
| `AxisValueLabelCollisionResolution.greedy(priority:minimumSpacing:)` | Charts: "Use a greedy algorithm. Display a label if it's not overlapping with other labels" | Swift Charts | Safety net against overlap at large text sizes |
| `AxisMarkValues.automatic(desiredCount:…)`, `.stride(by:…)` | Charts, "AxisMarkValues"; "Customizing axes" | Swift Charts | Read; not applicable to a String categorical axis |
| `accessibilityChartDescriptor(_:)`, `AXChartDescriptor` | read only (files unchanged) | SwiftUI / Accessibility | OBS-A boundary |
| `Color(_:bundle:)` asset tokens `dpSecondaryText`, `RiskLevel.textColor` | as recorded in 11-17 | SwiftUI | Reused; no token change |
| `XCUIApplication.performAccessibilityAudit(for:_:)`, `XCUIAccessibilityAuditType.all`, `XCUIAccessibilityAuditIssue.element` | as recorded in 11-17 | XCUIAutomation | Shared helper; D11-30 opt-in added |
| `XCUIElement.snapshot()`, `XCUIElementSnapshot.children/label/frame` | as recorded in 11-17 (`AuditTabBarOcclusion`) | XCUIAutomation | Day-mark matching at audit time |
| `XCUIDevice.appearance` | as recorded in 11-17 (`pinAppearance`) | iOS | Light and dark pinned per test |

## Known Stubs

None. A scan of the diff against 13f5dc8 for TODO, FIXME, placeholder, `print(`, Logger and URLSession found 0 matches.

## Threat Flags

None. No network, file, auth or schema surface was added.
- T-11-60: the mark values are the same `formattedValue` the hero total shows, asserted by the mark-label test.
- T-11-61: nothing is hidden, and the descriptor files are unchanged against fc506f4.
- T-11-62: two consecutive green runs, both saved, with identical ignored issues.

## Notes for later plans

- 11-22 (final gated re-run): the gated `AccessibilityAuditUITests` Insights methods do not opt in to D11-29 or D11-30. They will still report the 7 day-mark `hitRegion` issues and, in standard and dark, the tab-bar-occluded second metric row. Use the same opt-ins there, or record the difference.
- 11-23 must use D11-31 or later.
- DL-O19 (Add Drink step 2 placeholders) is still open and not in this plan's area.

## Self-Check: PASSED

- Files exist: `InsightsAccessibilityAuditUITests.swift`, `AccessibilityAuditChartMarks.swift`, `AlcoholAreaChart+Previews.swift`.
- Commits 3a885ba and def977d are ancestors of HEAD.
- The temporary diagnostic test (`TempInsightsDiag`) and the temporary preview file (`TempAllAX5Preview`) were deleted and never committed.
