---
phase: 11-ios-27-release-verification
reviewed: 2026-11-18T00:00:00Z
depth: standard
files_reviewed: 68
files_reviewed_list:
  - drinkpulse/DesignSystem/DPAdaptiveStack.swift
  - drinkpulse/DesignSystem/DPArcProgress.swift
  - drinkpulse/DesignSystem/DPMotion.swift
  - drinkpulse/DesignSystem/DPMotionProbe.swift
  - drinkpulse/DesignSystem/DPSemanticColors.swift
  - drinkpulse/DesignSystem/RiskLevel+Color.swift
  - drinkpulse/Features/AddDrink/Components/DecorativeEmoji.swift
  - drinkpulse/Features/AddDrink/Components/DrinkTypeTile.swift
  - drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
  - drinkpulse/Features/AddDrink/DrinkTypeGrid.swift
  - drinkpulse/Features/AddDrink/DrinkTypeGridView.swift
  - drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift
  - drinkpulse/Features/Dashboard/Components/DPChip.swift
  - drinkpulse/Features/Dashboard/Components/DashboardChipRow.swift
  - drinkpulse/Features/Dashboard/Components/DashboardHeroCard.swift
  - drinkpulse/Features/Dashboard/Components/GuidelineAlertCard.swift
  - drinkpulse/Features/Dashboard/Components/StreakCard.swift
  - drinkpulse/Features/Dashboard/Components/ThisWeekCard.swift
  - drinkpulse/Features/Dashboard/DashboardView+Previews.swift
  - drinkpulse/Features/Dashboard/DashboardView.swift
  - drinkpulse/Features/History/Components/CustomNameSuggestionSection.swift
  - drinkpulse/Features/History/Components/EventRow.swift
  - drinkpulse/Features/History/Components/HistoryCalendarView.swift
  - drinkpulse/Features/History/Components/PriceCurrencySection.swift
  - drinkpulse/Features/History/HistoryListQueryView.swift
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart+Previews.swift
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
  - drinkpulse/Features/Insights/Components/GuidelineComparisonCard.swift
  - drinkpulse/Features/Insights/Components/HealthMetricsCard.swift
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift
  - drinkpulse/Features/Insights/Components/InsightsScopeNavigator.swift
  - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift
  - drinkpulse/Features/Onboarding/Components/GuidelineStep.swift
  - drinkpulse/Features/Onboarding/Components/HealthStep.swift
  - drinkpulse/Features/Onboarding/Components/OnboardingStepLayout.swift
  - drinkpulse/Features/Onboarding/Components/ProfileStep.swift
  - drinkpulse/Features/Onboarding/Components/WelcomeStep.swift
  - drinkpulse/Features/Onboarding/OnboardingView.swift
  - drinkpulse/Features/Settings/Components/AppVersionFooter.swift
  - drinkpulse/Features/Settings/Components/AppearanceModeRow.swift
  - drinkpulse/Features/Settings/Components/HealthSection.swift
  - drinkpulse/Features/Settings/Components/ReminderSection.swift
  - drinkpulse/Features/Settings/Components/SettingsRow.swift
  - drinkpulse/Features/Settings/Components/SettingsSection.swift
  - drinkpulse/Features/Settings/Components/WeeklySummarySection.swift
  - drinkpulse/Features/Settings/SettingsView.swift
  - drinkpulse/Features/Shell/RootShellView.swift
  - drinkpulse/UITestSeed.swift
  - drinkpulseTests/DesignSystem/DPMotionTests.swift
  - drinkpulseUITests/Features/AddDrink/AddDrinkAccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/AddDrink/AddDrinkDynamicTypeUITests.swift
  - drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift
  - drinkpulseUITests/Features/Dashboard/DashboardAccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/Dashboard/DashboardDynamicTypeUITests.swift
  - drinkpulseUITests/Features/Dashboard/ReduceMotionDashboardUITests.swift
  - drinkpulseUITests/Features/History/HistoryAccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/History/ReduceMotionHistoryUITests.swift
  - drinkpulseUITests/Features/Insights/InsightsAccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/Insights/InsightsDynamicTypeUITests.swift
  - drinkpulseUITests/Features/Onboarding/OnboardingAccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/Onboarding/OnboardingDynamicTypeUITests.swift
  - drinkpulseUITests/Features/Settings/SettingsAccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/Settings/SettingsDynamicTypeUITests.swift
  - drinkpulseUITests/Features/Shell/AccessibilityAuditChartMarks.swift
  - drinkpulseUITests/Features/Shell/AccessibilityAuditOcclusion.swift
  - drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift
  - drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/Shell/ProbeAccessibilityAuditUITests.swift
findings:
  critical: 1
  warning: 9
  info: 6
  total: 16
  necessity: 0
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-11-18
**Depth:** standard
**Files Reviewed:** 68
**Status:** issues_found

## Summary

Scope: Phase 11 gap-closure changes since `fd292d1` (`git diff fd292d1 HEAD`) for 68 files: 48 production, 1 unit test, 19 UI test files. This report replaces the earlier 2-file review. That review exists in git history at `fd292d1` (`11-REVIEW.md`); its IN-01 is carried forward below as IN-01. Its WR-01, WR-02 and IN-02 were fixed in plan 11-12, and IN-03 is documented in the class comment.

Checked and found sound:
- `DPMotion` and `DPMotionProbe` are gated on `-dp_uitest` and covered by `DPMotionTests`. Nothing renders in normal use.
- `DPAdaptiveStack`, `SettingsRow` and `EventRow` use `AnyLayout`, so subview identity is kept across the size switch.
- `OnboardingStepLayout` keeps the primary button reachable at AX sizes.
- `DecorativeEmoji` is an unlabelled `Image(decorative:)` and the tile name carries the label.
- All new localization keys (`onboarding.progress.label`, `onboarding.progress.value`, `action.cancel`) exist in `Localizable.xcstrings`.
- No file is over 300 lines (largest: `AccessibilityAuditSupport.swift`, 274). No `print`, force-unwrap or network call in production code.
- Apple API check via Xcode MCP `DocumentationSearch`: `Button(role:action:)` exists. Its doc example shows a toolbar button with an "x" symbol (see WR-04).

Main concerns:
1. One category of production contrast defect: three small-text sites still use fill colours, or red, that the same change set replaced elsewhere with text tokens.
2. Three audit exemptions (D11-28, D11-29, D11-31) are looser than their decision text or the surrounding comments say, and none caps the number of findings it lets pass.
3. A handful of accessibility and localization regressions in touched files.

Necessity (category 4) was assessed per `necessity-review.md`; no finding qualified.

## Critical Issues

### CR-01: Small risk-coloured text still uses the fill colours (about 2:1 to 3.7:1), contradicting the 4.5:1 rule the change set applies elsewhere

**File:** `drinkpulse/Features/Dashboard/DashboardView.swift:98-106,126`; `drinkpulse/Features/Dashboard/Components/ThisWeekCard.swift:32-36,56-61`; `drinkpulse/Features/Settings/Components/HealthSection.swift:29`, `ReminderSection.swift:38`, `WeeklySummarySection.swift:27`
**Issue:** Plan 11-17 added `textColor`, `dpRiskText*` and `dpSecondaryText`. The comment on `TrendBadge.textColor` says the fill colours "are under 4.5:1 for small text on the tint". Three sites still draw small text in the fill colour, or in system red.
- `RiskBadge` draws `.caption.weight(.semibold)` text in `level.color` (`dpGreen`, `dpAmber`, `dpRed`) on `color.opacity(0.15)`. Computed contrast in light mode:
  - `dpGreen` (0.22, 0.56, 0.24): about 3.7:1 on its tint.
  - `dpAmber` (1.0, 0.56, 0.0): about 2:1.
  - `dpRed` (0.90, 0.22, 0.21): about 4.1:1.
  
  `DashboardHeroCard` and `TrendBadge` were fixed for exactly this pairing. `RiskBadge` is the Home header badge, so it is also the most visible one. AGENTS.md requires 4.5:1 for body text. The audit likely passed it only because of the seeded risk level and pixel sampling.
- `ThisWeekCard` draws the percentage annotations in `barColor(for:)`, which is `RiskLevel.color` (amber is about 2.3:1 on white). These labels sit inside `.accessibilityHidden(true)`, so the audit never sees them. A passing audit proves nothing here.
- The `permissionDenied` captions in `HealthSection`, `ReminderSection` and `WeeklySummarySection` use `Color.red` (system red, about 3.5:1 on white) at `.footnote`. Only the non-denied branch was moved to `dpSecondaryText`. The denied state is not seeded in the audit, so it is unchecked.

**Fix:** Use the text token in each place:
```swift
// DashboardView.RiskBadge
.foregroundStyle(level.textColor)            // keep background(level.color.opacity(0.15))
// ThisWeekCard annotation
.foregroundStyle(entry.isFuture || entry.grams == 0 ? Color.dpSecondaryText : riskTextColor(for: entry))
// Settings captions
.foregroundStyle(permissionDenied ? RiskLevel.exceeded.textColor : Color.dpSecondaryText)
```
Add a `permissionDenied` audit variant, or a unit-level contrast check on the tokens.

## Warnings

### WR-01: D11-29 exempts any element whose frame touches the tab bar, which is wider than "content occluded by the tab bar"

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditOcclusion.swift:56-65`; scope comments in `SettingsAccessibilityAuditUITests.swift:11-14`, `InsightsAccessibilityAuditUITests.swift:11-13`
**Issue:** `occludedFrame(for:)` ignores a `contrast` or `textClipped` issue when `element.frame` intersects the tab bar frame by any positive area. It only skips elements that are tab bar chrome. A screen-spanning container (scroll view, `Form`, a tall card with only its last point under the bar) always overlaps, so any contrast or clipping finding reported on such a container passes. The class comments claim a much narrower set ("the reminder row and its caption", "the second row of the Health Impact card"), but nothing in code enforces that set. A real regression in a tall element would be downgraded to a warning, and the warning is not tied to a limit. D11-29 says "occluded", and the implementation tests "overlaps".
**Fix:** Require that the element is mostly under the bar, and bound the count:
```swift
let overlap = frame.intersection(tabBarFrame)
guard !overlap.isNull,
      overlap.height * overlap.width >= 0.5 * frame.height * frame.width,  // mostly under the bar
      !frame.contains(tabBarFrame) else { return nil }                      // not a container
```
Also add a per-variant `maxIgnored` parameter and `XCTFail` when it is exceeded, so growth in ignored findings is visible. Today the count is only recorded as a warning.

### WR-02: D11-31 exempts every element-less `contrast` issue while a tab bar exists, with no upper bound

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditOcclusion.swift:81-83`; `AccessibilityAuditSupport.swift:138-141,162-165`
**Issue:** D11-31 rests on the observation that History reports "exactly one `contrast` issue per variant" with no element. The code passes any number of `contrast` issues without an element, anywhere on screen, as long as `app.tabBars.firstMatch` exists. It does not tie the issue to the tab bar region (it has no frame) and does not check the count. A genuine new contrast defect that the audit cannot attribute passes silently on all three History variants and on the gated History test. The result is the "broad mute" that D11-31 states it avoids.
**Fix:** Enforce the decision's premise: allow at most one such issue per run, fail on the second, and record the count assertion in the existing summary:
```swift
} else if ignoreTabBarElementlessContrast, let occlusion, occlusion.isElementlessContrast(issue), elementlessIgnored < 1 {
```
An issue past the first falls through to `recordAuditIssue` and fails.

### WR-03: D11-28 exemption key `none#type=nil` passes every element-less `dynamicType`/`textClipped` issue on six scrolled pages of Add Drink step 2

**File:** `drinkpulseUITests/Features/AddDrink/AddDrinkDynamicTypeUITests.swift:14-26,79`; `AccessibilityAuditSupport.swift:152-157,190-195`
**Issue:** The exemption set is `["Volume", "Strength", "Amount", "none#type=nil"]`.
- `none#type=nil` is the key of every issue that has no element, so a new unattributed clipping or fixed-size finding anywhere on step 2 passes.
- The names are matched against identifier-else-label of any element, not only the picker rows. A clipped static text or button labelled "Volume" (for example the Volume row title) is exempt.
- The only trace is one `XCTAttachment` with a count. There is no per-issue warning and no bound, unlike D11-29/30/31. The decision text says "exactly these element keys", but the catch-all key defeats that.

**Fix:** Bound each key. Add a per-key maximum (one per picker row per page, a small total for element-less issues) and fail when it is exceeded. Record each exempted issue with `recordAuditWarning`, as the other opt-ins do. Restrict the named keys to the picker element types where possible (match `issue.element?.elementType`).

### WR-04: Toolbar Cancel became a system-labelled role button (icon in a toolbar) and no longer uses `action.cancel`

**File:** `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift:36-47`
**Issue:** The toolbar button changed from `Button(String(localized: "action.cancel")) { ... }` to `Button(role: .cancel, action: cancel)`. Apple's doc for `init(role:action:)` shows this initializer in a toolbar rendering an "x" symbol, so at regular sizes Cancel is expected to render as an icon-only button. The bottom bar at AX sizes still renders the text "Cancel" from `action.cancel`. The comment "The button labels are the same in both places" is therefore not established, and the visible form differs. It also moves a user-facing label out of `String(localized:)`, against AGENTS.md. UI tests that find `app.buttons["Cancel"]` now depend on the system-provided accessibility label rather than an app string.
**Fix:** Keep an app-owned label and the role:
```swift
ToolbarItem(placement: .cancellationAction) {
    Button(String(localized: "action.cancel"), role: .cancel, action: cancel)
}
```
If the icon form is intended, use `Button(role: .cancel, action: cancel) { Label(String(localized: "action.cancel"), systemImage: "xmark") }`, so the label is app-owned and VoiceOver reads it.

### WR-05: Insights ungated audit does not wait for the chart, and a missing chart only logs a warning

**File:** `drinkpulseUITests/Features/Insights/InsightsAccessibilityAuditUITests.swift:27-43`; `AccessibilityAuditChartMarks.swift:34-38`; `AccessibilityAuditSupport.swift:126,166-169`
**Issue:** The gated twin waits for the area chart before auditing, noting that an audit started before the chart is laid out reports an element-less contrast issue (`AccessibilityAuditUITests.swift:114-120`). The ungated class does not wait. `AuditChartDayMarks.current` checks `chart.exists` once, immediately. If the chart is not yet present, the D11-30 lookup is nil, the exemption is silently off (`chartFound=false` is logged as a warning only), and the hit-region findings that D11-30 covers fail the test. The result is a timing-dependent failure, and the failure message reads like a regression.
**Fix:** In `launchAndOpenInsights`, add `XCTAssertTrue(chart.waitForExistence(timeout: 10))` and return `nil` when it fails, as the gated helper does. In `assertNoAuditIssues`, `XCTFail` when `chartLabel != nil` and the chart is not found.

### WR-06: Weekday chart axis labels at accessibility sizes collapse to initials that collide (T/T, S/S)

**File:** `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift:19-21,53-56`
**Issue:** `axisLabel` returns `String(label.prefix(1))` at accessibility sizes. With the abbreviated weekday labels the model produces (Mon..Sun), Tue and Thu are both "T", and Sat and Sun are both "S". A sighted user at AX sizes cannot tell the bars apart. It also uses a locale-fragile character cut (`prefix(1)` is not a word-aware initial).
**Fix:** Use the localized narrow weekday symbol (`Calendar.current.veryShortStandaloneWeekdaySymbols`), which keeps a distinguishable form per locale, or stagger the labels (greedy collision with full abbreviations, or two rows). Do not hand-cut a string.

### WR-07: Insights period label loses its single accessibility element when the period is current

**File:** `drinkpulse/Features/Insights/Components/InsightsScopeNavigator.swift:68-103`
**Issue:** The non-current period is a `Button` with `accessibilityLabel(friendlyLabel + ", " + rangeLabel)`. The current period (the common state) is now plain `centerLabelContent`: a `VStack` of `Text`s plus `NowPill`. VoiceOver reads the title, the "Now" pill and the range as separate elements, in layout order, and there is no combined label. The previous disabled button exposed one element ("label, range"). The comment justifies the change by contrast only.
**Fix:**
```swift
if vm.isCurrentPeriod {
    centerLabelContent
        .accessibilityElement(children: .combine)
        .accessibilityLabel(vm.friendlyLabel + ", " + vm.rangeLabel)
}
```

### WR-08: Unlocalized user-facing strings in `GuidelineAlertCard` (touched file)

**File:** `drinkpulse/Features/Dashboard/Components/GuidelineAlertCard.swift:15,28-31`
**Issue:** The visible text `"%.0f%% of %@ weekly limit"` and the accessibility label format `"%@. %.0f%% of %@ guideline."` are bare format literals, not `String(localized:)`. AGENTS.md requires every user-facing string to go through `String(localized:)`. This predates the change set, but the file was edited here for the contrast token and the AX layout, so it falls inside the accessibility pass.
**Fix:** Add catalog keys such as `dashboard.alert.weeklyLimit` and `dashboard.alert.a11y`, and use `String(format: String(localized: "..."), ...)`.

### WR-09: "This Week" chart is hidden from accessibility with no summary

**File:** `drinkpulse/Features/Dashboard/Components/ThisWeekCard.swift:26-50`
**Issue:** The whole `Chart` is `.accessibilityHidden(true)`, and the card exposes only its headline. VoiceOver users get no per-day data. AGENTS.md requires `accessibilityChartDescriptor` or an equivalent summary for charts, and Insights charts have one. Hiding the chart also takes its text (see CR-01) out of the audit. This predates the change set (present at `fd292d1`) but the card was reworked here.
**Fix:** Replace the hide with `.accessibilityChartDescriptor(...)`, or add a combined label on the card such as "This week: Mon 0%, Tue 50% ..." built from `vm.weekBarData`.

## Info

### IN-01: `nonisolated static` on the gate helper is unexplained (carried forward, open in 11-REVIEW-DISPOSITION.md)

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift:52`
**Issue:** `skipUnlessAuditEnabled` only reads `ProcessInfo` and is called from `setUpWithError` of a `@MainActor` class, so `nonisolated` is not needed and the sibling gate (`SheetDismissTabSwitchUITests`) uses a plain `private func`. Still applies at HEAD.
**Fix:** Drop `nonisolated static`, or add a one-line comment saying why it is required.

### IN-02: Gated audit duplicates `pinAppearance`

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift:64-82`
**Issue:** `launchApp` re-implements `pinAppearance(_:)` (same restore logic, same teardown block) instead of calling the shared helper in `AccessibilityAuditSupport.swift:101-108`. Two copies of the restore rule will drift. `assertNoAuditIssues` (`AccessibilityAuditSupport.swift:112-170`) also has nine parameters and four exemption branches in one closure.
**Fix:** Call `pinAppearance(variant == .dark ? .dark : .light)`. Longer term, move the exemption rules into one policy value passed to the helper.

### IN-03: `SheetActionsModifier` lives in `DrinkTypeGridView.swift`

**File:** `drinkpulse/Features/AddDrink/DrinkTypeGridView.swift:19-70`
**Issue:** The shared modifier is used by `DrinkDetailInputView` too, but is defined inside the grid view file. AGENTS.md asks for one concept per file.
**Fix:** Move `SheetActionsModifier` and `View.sheetActions` to `Features/AddDrink/Components/SheetActions.swift`, with its own preview.

### IN-04: `DecorativeEmoji` rasterizes on every `body` evaluation

**File:** `drinkpulse/Features/AddDrink/Components/DecorativeEmoji.swift:21-33`
**Issue:** `rendered` builds an `ImageRenderer` and a `CGImage` each time `body` runs. `EventRow` uses it for every History row, so each scroll or update re-renders the emoji on the main actor. A nil result also draws nothing without any trace. (Performance is out of scope for v1; this is noted because the cost grows with list length and may show as hitches.)
**Fix:** Cache by `(emoji, pointSize, displayScale)` in a small `@MainActor` dictionary.

### IN-05: Onboarding at AX sizes drops swipe paging and resets step state on a text-size change

**File:** `drinkpulse/Features/Onboarding/OnboardingView.swift:18-33`
**Issue:** At accessibility sizes the `TabView` is replaced by a single step view with `.id(vm.step)`. This works around an audit result for UIKit-hosted pages (plan 11-16). The side effects are that swipe paging is unavailable for AX users (the buttons still work), and changing text size mid-onboarding recreates the step, so `@State` such as `HealthStep.weeklySummaryToggleGeneration` resets. The loss is small, and the choice is already recorded.
**Fix:** Note it in the owner checklist (CHK-07) so it is a known, accepted trade-off.

### IN-06: Vertical-axis text field at AX sizes accepts newlines

**File:** `drinkpulse/Features/History/Components/CustomNameSuggestionSection.swift:41-50`
**Issue:** At accessibility sizes the custom-name field becomes `TextField(..., axis: .vertical)`, where Return inserts a line break. A saved custom name can then contain `\n` and render as a multi-line row title elsewhere. Switching branches on a size change also recreates the field and drops focus.
**Fix:** Add `.lineLimit(1...4)` and strip newlines on change (`customName = customName.replacingOccurrences(of: "\n", with: " ")`), or trim in the save path.

---

_Reviewed: 2026-11-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
