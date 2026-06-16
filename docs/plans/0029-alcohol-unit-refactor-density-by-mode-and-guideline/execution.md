# Execution journal — plan-0029

## 2026-06-16 — Implementation

Executed the frozen plan in full. No deviations from the target numbers.

### Domain (`Domain/UserProfile.swift`)
- `AlcoholUnit` collapsed to `case grams, standardDrinks` (`.units` removed).
- Replaced the `densityGramsPerMl` property with `density(for guideline:)`:
  `.grams` → 0.789 (all guidelines); `.standardDrinks` → 0.789 for US/CA, 0.8 for
  WHO/DE/AU/UK/custom. `physicalDensityGramsPerMl` kept at 0.789.
- `gramsPerUnit(for:)` `.standardDrinks` branch: UK 8.0, US 14, CA 13.45,
  WHO/DE/AU/custom 10.0.
- `unitLabel` is now `unitLabel(for guideline:)` (sub-decision #1): UK → "units",
  others → "standard drinks", `.grams` → "g".
- **Migration**: added `AlcoholUnit.init(from:)` that maps any persisted `"units"`
  raw (and any unknown raw) → `.standardDrinks`. Stored default and `init` default
  changed to `.standardDrinks`. This is a lightweight, additive-compatible decode
  (no store wipe) — it covers the SwiftData stored property and imported
  `ProfileRecord`s (which decode through the same enum).

### Call sites updated (every old `densityGramsPerMl` consumer and `?? .units`)
- `DashboardViewModel` — `modeDensity` → `density(for:)`; added a guideline-aware
  `unitLabel` computed property; `?? .units` → `?? .standardDrinks`.
- `ConsumptionOverviewCard` — `vm.alcoholUnit.unitLabel` → `vm.unitLabel` (×3).
- `InsightsViewModel` + `+Formatting` — `modeDensity` now passes the guideline;
  `formattedValue`/`comparisonLabel` use `unitLabel(for:)`; fallbacks → `.standardDrinks`.
- `EventRow`, `HistoryCalendarView`, `HistoryCalendarDayDetail` — `density(for:)`,
  `unitLabel(for:)`, fallbacks → `.standardDrinks`.
- `DrinkDetailInputView`, `EditEventView` — preview mass uses `density(for: guideline)`.
- `DataSection` reset → `.standardDrinks`.
- `SettingsView` picker unchanged (still `AlcoholUnit.allCases` + `displayName`,
  now 2 cases). `ProfileRecord` / `DataExporter` unchanged (decode via the new enum).

### Localization
- Retired `settings.alcoholUnit.units`. Changed `settings.alcoholUnit.standardDrinks`
  value from "Standard drinks (US)" → "Standard drinks" (it is now the generic
  non-grams option covering EU/UK/US/CA). `unit.units` kept (used for the UK label).

### Tests (domain 100%, target numbers verified)
- `AlcoholUnitFormattingTests`: `density(for:)` table (grams 0.789 all; std-drinks
  0.789 US/CA, 0.8 EU/UK); canonical drinks (EU 500 ml = 2.0, UK = 2.5, US 355 ml =
  1.0, CA 341 ml = 1.0); grams mode = 19.7 all guidelines; limits-in-std-drinks table
  incl. UK weekly = 14.0, US weekly = 14.0, CA weekly = 15.0.
- `AlcoholUnitTests`: two cases only; `unitLabel(for:)` UK = units / others = standard
  drinks; decode migration of `"units"` and unknown raw → `.standardDrinks`.
- `DataExportImportTests`: import of a legacy v2 bundle with `alcoholUnit: "units"`
  loads as `.standardDrinks`.
- `InsightsViewModelTests+Aggregates`: calories identical across grams vs std-drinks
  (0.8) modes (138 kcal for a 19.725 g beer).
- Updated existing tests that used `.units` (all WHO-guidelined → identical numerics
  under `.standardDrinks` 0.8) and the fallback/`unitLabel` assertions.

### Notes / minor deviations
- `unitLabel` became a function, so `AlcoholUnit.grams.unitLabel` test sites became
  `unitLabel(for: .who)` (grams ignores the guideline).
- The std-drinks-limit tests originally used a `keyPath:` closure helper; the Swift
  Testing `#expect` macro rejected key paths to `GuidelineLimits` properties, so the
  helpers were rewritten with direct property access. Behaviour identical.
- `GuidelineLimits` UK weekly stays 112 g (plan-0028 / ADR-0005), now rendered as
  14.0 units in std-drinks mode.

### Verification
- `xcodebuild build`: clean, zero warnings.
- `xcodebuild test`: green (the CoreData "no access to file" log noise comes from a
  pre-existing StoreBootstrap failure-path test, not a failure).
- Coverage: test target 99.53%; touched domain files — `UserProfile.swift` 92.96%
  (uncovered = `ageYears`/`preview` helpers, not the refactor logic),
  `GuidelineChoice+Limits` 100%, `ProfileRecord` 100%, `DataExporter` 100%,
  `GuidelineLimits` 100%. AlcoholUnit refactor logic fully exercised.
- File-size check: no Swift file > 300 lines.
