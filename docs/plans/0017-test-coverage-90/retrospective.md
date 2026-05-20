# 0017 — Retrospective

**Completed**: 2026-05-20

## What went well

- All 6 bugs confirmed and reproduced by failing tests before fixes were applied.
- SB-1 was even more broken than expected: the test runner used Polish locale,
  making "WHO" vs "WHO (globalna)" visibly wrong — concrete proof of the bug.
- `DashboardViewModel` jumped from 70.7% to 98% in a single pass.
- The split of `DashboardViewModelTests.swift` (324 lines → 3 files, all under 200)
  went smoothly using `extension` on the `@MainActor struct`.
- `xcodebuild CODE_SIGNING_ALLOWED=NO` resolved the resource-fork codesign issue
  that had blocked coverage runs. Documented in execution log.

## What went wrong / surprises

- `GuidelineChoiceDisplayTests` required `@MainActor` because `displayName` is
  inferred as main-actor-isolated (its file imports SwiftUI). Not obvious from
  the property definition. All other test structs touching display properties
  should also be `@MainActor`.
- `UserProfile.init` argument order: `guidelineChoice` must precede `alcoholUnit`.
  Caused one compile error caught at build-check time.
- `BiologicalSex` does not conform to `CaseIterable` — had to iterate manually
  `[.male, .female]` in tests that loop over sexes.
- `DrinkTemplate` raw coverage shows 31% (not 100%) because xccov counts preview
  static getters that are correctly excluded from the testable denominator. Worth
  noting so future audits don't misread this file as undertested.

## Decisions made during execution

- Inline `1.0` literal for the SB-2 clamp (vs named constant). The constant
  would add boilerplate without adding clarity at the only call site.
- `DashboardViewModelTests` split: main file keeps streaks/risk/bar chart;
  `+Metrics.swift` has counts/spend/limits; `+Formatting.swift` has display/greeting.
- `DrinkTypePreset.preset(for:)` changed to exhaustive `switch` — future `DrinkCategory`
  additions will produce a compile error rather than silently falling back to `.custom`.

## Leftover open questions

- `DrinkTemplate` preview statics show 0% coverage in xccov (raw 31%). These are
  test helpers and correctly excluded. A future audit should note this pattern.
- `ConsumptionEvent` preview statics: same — raw 50%, testable 100%.
- `drinkpulseApp.swift` has one uncovered branch (fatal error in ModelContainer init);
  this is expected — integration concern, not unit concern.
