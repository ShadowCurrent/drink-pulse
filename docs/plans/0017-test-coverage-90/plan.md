# 0017 — Test coverage to ≥90% + 6 confirmed bug fixes

**Status**: in-progress
**Frozen**: 2026-05-20
**Size**: medium
**Created**: 2026-05-20

## Summary

Bring testable code coverage from ~70% to ≥90% overall (Domain → 100%,
ViewModels → ≥90%), while fixing 6 bugs identified in the Phase 1 audit.
Each bug fix follows the mandatory sequence: failing test first, then fix.
Coverage additions come after bug fixes are green.

## Context

Phase 1 audit (2026-05-20) measured ~70% testable coverage against a new
≥90% target added to CLAUDE.md. Six bugs were confirmed by the user. The
`xcodebuild` invocation requires `CODE_SIGNING_ALLOWED=NO` to run on the
simulator (resource-fork codesign issue with the current machine config).

## Scope

### In
- Fix all 6 confirmed bugs (SB-1 through SB-6).
- Add unit tests to reach ≥90% testable coverage overall.
- Domain layer: 100% testable coverage.
- ViewModels: ≥90% testable coverage.
- `DrinkTypePreset`: ≥90% testable coverage.
- Split any test file that exceeds 300 lines.

### Out
- No UI tests / snapshot tests.
- No coverage of pure SwiftUI view bodies, `@main`, or preview helpers
  (these remain excluded per CLAUDE.md).
- View logic embedded in `ThisWeekCard` and `ConsumptionOverviewCard`
  — covered indirectly through `DashboardViewModel` tests; no dedicated
  view-struct instantiation in unit tests.
- No changes to `SettingsView`, `HistoryView`, `EditEventView`, or any
  other view file except SB-3 one-liner in `GuidelineStep.swift`.
- No schema migrations.

## Bug fixes

### SB-1 — `guidelineDisplayName` hardcodes English
**File**: `Features/Dashboard/DashboardViewModel.swift:193–201`
**Fix**: Replace the switch with `guidelineChoice.displayName` (which uses
`String(localized:)` from `GuidelineChoice+Display.swift`).

### SB-2 — `.custom` guideline + zero `weeklyGoalGrams` silently shows "safe"
**File**: `Features/Dashboard/DashboardViewModel.swift:37–38`
**Fix**: In the `limits` computed property, clamp `weeklyGoalGrams` to
a minimum of 1.0 when building the custom `GuidelineLimits`, preventing
a zero denominator that makes `weeklyPct = 0` and `riskLevel = .safe`
regardless of consumption.
```swift
if p.guidelineChoice == .custom {
    let weekly = max(p.weeklyGoalGrams, 1.0)
    return GuidelineLimits(dailyGrams: weekly / 7, weeklyGrams: weekly)
}
```

### SB-3 — `GuidelineStep.onboardingName` hardcodes "WHO" for `.who` case
**File**: `Features/Onboarding/Components/GuidelineStep.swift:78`
**Fix**: Change `case .who: return "WHO"` to
`case .who: return String(localized: "settings.guideline.who")`.
No unit test possible (private extension inside a View file); the fix is
a one-liner verified by inspection and existing Previews.

### SB-4 — Unreachable `?? .custom` branch in `DrinkTypePreset.preset(for:)`
**File**: `Features/AddDrink/DrinkTypePreset.swift:36–38`
**Fix**: Replace the `all.first { } ?? .custom` with an exhaustive
`switch` over `DrinkCategory`. Adding a new category without a matching
preset will then be a compile error instead of a silent fallback.

### SB-5 — `formattedAlcohol` / `formattedNumber` / `formattedSpend` untested
**File**: `Features/Dashboard/DashboardViewModel.swift:203–218`
**Fix**: No production code change. Add tests covering each method with
representative inputs (grams, units, standard drinks; with and without a
profile; spend with and without a matching currency).

### SB-6 — `todaySpend` nil-price behaviour untested
**File**: `Features/Dashboard/DashboardViewModel.swift:65–69`
**Fix**: No production code change. Add tests for: all events have nil
price → returns nil; mix of nil and non-nil → sums only non-nil;
events outside today → excluded.

## Implementation steps

### Phase A — Bug fixes (failing test → fix, one commit per bug)

1. **[SB-1]** Write failing test `guidelineDisplayName_matchesLocalized_forAllCases()`
   in `DashboardViewModelTests.swift`. Confirm red. Fix `guidelineDisplayName` to
   delegate to `guidelineChoice.displayName`. Green.

2. **[SB-2]** Write failing test
   `limits_customGuidelineZeroGoal_doesNotReturnZeroLimits()` and
   `riskLevel_notSafe_whenDrinking_customGuidelineZeroGoal()`.
   Confirm red. Apply the `max(weeklyGoalGrams, 1.0)` clamp. Green.

3. **[SB-3]** Apply one-liner fix to `GuidelineStep.swift`. No new test
   (private view extension). Verify build stays green.

4. **[SB-4]** Write test `preset_returnsNonCustom_forEveryKnownCategory()`
   in `DrinkTypePresetTests.swift`. Confirm it passes today (no regression).
   Replace `first { } ?? .custom` with exhaustive `switch`. Green.
   (The test value here is compile-time exhaustiveness going forward, not
   catching a current failure — this is acceptable for a code-quality fix.)

5. **[SB-5 + SB-6]** Write tests for `formattedAlcohol`, `formattedNumber`,
   `formattedSpend`, `todayDrinkCount`, and `todaySpend` in
   `DashboardViewModelTests.swift`. These are coverage-filling tests for
   confirmed-untested paths; no production fix needed.

### Phase B — Domain layer to 100%

6. **`GuidelineChoice+Display`** — new file
   `drinkpulseTests/GuidelineChoiceDisplayTests.swift`:
   - `displayName_returnsExpectedValue_forAllCases()` — 5 assertions
   - `thresholdSummary_withDailyGrams_includesBothValues()` (WHO male)
   - `thresholdSummary_noDailyGrams_weeklyOnly()` (UK — dailyGrams == 0)

7. **`AlcoholUnit.unitLabel` + `AlcoholUnit.displayName`** — new file
   `drinkpulseTests/AlcoholUnitTests.swift`:
   - `unitLabel_grams_containsGSuffix()`
   - `unitLabel_units_returnsExpected()`
   - `unitLabel_standardDrinks_returnsExpected()`
   - `displayName_allCases_nonEmpty()`

8. **`DrinkTemplate.init`** — new file
   `drinkpulseTests/DrinkTemplateTests.swift`:
   - `init_storesAllFields()` — create via in-memory container, verify
     name/category/abv/icon/colorHex/isFavorite/isArchived round-trip.
   - `init_defaultsFavoriteAndArchivedToFalse()`

### Phase C — DashboardViewModel to ≥90%

9. **Uncovered branches in `DashboardViewModel`** — add to
   `DashboardViewModelTests.swift` (or a split file if the total exceeds
   300 lines — see Files section):
   - `todayDrinkCount_zeroWithNoEventsToday()`
   - `todayDrinkCount_countsOnlyTodayEvents()`
   - `todaySpend_nilWhenAllPricesNil()`
   - `todaySpend_sumsNonNilPricesOnly()`
   - `todaySpend_excludesYesterdayEvents()`
   - `weeklyGrams_sumsCurrentCalendarWeekOnly()`
   - `thirtyDayLimitGrams_isWeeklyTimesThirtyOverSeven()`
   - `limits_customGuideline_usesWeeklyGoal()`
   - `greetingText_morningBeforeNoon()`
   - `greetingText_afternoonBetweenNoonAnd6()`
   - `greetingText_eveningAfter6()`
   - `alcoholUnit_fallsBackToUnits_whenNoProfile()`
   - `guidelineChoice_fallsBackToWHO_whenNoProfile()`
   - `formattedAlcohol_gramsUnit_appendsLabel()`
   - `formattedAlcohol_standardDrinks_whoGuideline()`
   - `formattedNumber_returnsValueOnly_noLabel()`
   - `formattedSpend_USD_formatsCorrectly()`
   - `formattedSpend_unknownCurrency_fallsBack()`

### Phase D — Remaining gaps

10. **`OnboardingViewModel.skipStep`** — add to `OnboardingViewModelTests.swift`:
    - `skipStep_advancesStep()`

11. **`DrinkTypePreset` Hashable** — add to `DrinkTypePresetTests.swift`:
    - `preset_idEqualsCategory()`
    - `preset_equalityByCategory()`
    - `preset_canBeInsertedIntoSet()`

### Phase E — File size check + final coverage run

12. Check file sizes. If `DashboardViewModelTests.swift` exceeds 300 lines,
    split by concern into:
    - `DashboardViewModelTests+Metrics.swift` (today/7-day/30-day)
    - `DashboardViewModelTests+Formatting.swift` (formattedAlcohol, spend)
    - Keep streaks, risk, bar chart in the main file.

13. Run full coverage report. Verify:
    - Domain testable ≥ 100%
    - DashboardViewModel ≥ 90%
    - OnboardingViewModel = 100%
    - DrinkTypePreset ≥ 90%
    - Overall testable ≥ 90%
    If any target is missed, add the missing tests before declaring done.

14. Run end-of-task checklist (docs, roadmap, devlog, open-questions).

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Dashboard/DashboardViewModel.swift` | Modify (SB-1, SB-2) |
| `drinkpulse/Features/Onboarding/Components/GuidelineStep.swift` | Modify (SB-3 one-liner) |
| `drinkpulse/Features/AddDrink/DrinkTypePreset.swift` | Modify (SB-4) |
| `drinkpulseTests/DashboardViewModelTests.swift` | Modify (many additions; may split) |
| `drinkpulseTests/DashboardViewModelTests+Formatting.swift` | Create if split needed |
| `drinkpulseTests/OnboardingViewModelTests.swift` | Modify (skipStep) |
| `drinkpulseTests/DrinkTypePresetTests.swift` | Modify (Hashable, all-categories) |
| `drinkpulseTests/GuidelineChoiceDisplayTests.swift` | Create |
| `drinkpulseTests/AlcoholUnitTests.swift` | Create |
| `drinkpulseTests/DrinkTemplateTests.swift` | Create |

## Open questions

- [ ] SB-2 clamp value: `max(weeklyGoalGrams, 1.0)` (1 g/week) is effectively
  a no-limit sentinel. Should it be a named constant (e.g. `minimumCustomGoalGrams`)
  or is the inline literal acceptable? (Options: inline literal / named constant)

## Tests required

All listed in the implementation steps above. Summary count:
- New test functions: ~35
- New test files: 3 (`GuidelineChoiceDisplayTests`, `AlcoholUnitTests`,
  `DrinkTemplateTests`)
- Modified test files: 3 (`DashboardViewModelTests`, `OnboardingViewModelTests`,
  `DrinkTypePresetTests`)

All new tests use Swift Testing (`@Test`, `#expect`) per CLAUDE.md.
Existing files already using XCTest keep their style.
