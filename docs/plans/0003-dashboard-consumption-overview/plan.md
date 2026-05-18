# 0003 — Dashboard: Consumption Overview Progress Bars

**Status**: in-progress
**Size**: small
**Created**: 2026-05-18
**Frozen**: 2026-05-18

## Summary

Add a stacked progress-bar "Consumption Overview" card (Today / 7 Days / 30 Days)
below the today metrics grid. Add a "Dziś" section header above the metrics.
Replace `WeeklyGoalCard` (ring + chart) with a leaner `ThisWeekCard` (bar chart
only — the ring is made redundant by the 7 Days progress bar). All values respect
the user's alcohol unit preference.

## Context

The existing dashboard shows a weekly ring + bar chart (`WeeklyGoalCard`) that
covers only 7 days. Users have no at-a-glance view of their 30-day standing, and
the ring duplicates the information from the new progress bars. The Figma sketch
(Option B — stacked bars) is the agreed layout. The "Dziś" section label removes
the need to repeat "Today" inside each metric card.

## UX decisions

- Consumption overview goes **below** the today metrics: header badge already
  signals risk immediately; today cards are the primary action area; the overview
  is supporting context.
- `WeeklyGoalCard` ring removed (duplicates "7 Days" bar); the Mon–Sun bar chart
  moves to a standalone `ThisWeekCard`.
- All gram values converted to `alcoholUnit` (grams / UK units / standard drinks)
  via the existing `AlcoholUnit.formattedValue` helper.

## Scope

### In
- `DashboardViewModel` — `thirtyDayGrams`, `thirtyDayLimitGrams`,
  `effectiveDailyLimitGrams`, `formattedNumber(_:)` helper
- `DashboardView` — "Dziś" section label; `ConsumptionOverviewCard`
  (3 × `IntakePeriodRow`); `ThisWeekCard` (bar chart only); remove `WeeklyGoalCard`
- `Localizable.xcstrings` — 6 new keys (en / de / pl)
- `DashboardViewModelTests` — tests for `thirtyDayGrams` and `effectiveDailyLimitGrams`

### Out
- Any design changes to metric cards themselves
- Streak / alert sections (unchanged)
- iCloud / HealthKit integration

## Implementation steps

1. **`DashboardViewModel.swift`**
   - `thirtyDayGrams` — rolling 30 days from `now`
   - `thirtyDayLimitGrams` — `weeklyLimitGrams × 30 / 7`
   - `effectiveDailyLimitGrams` — `dailyLimitGrams > 0 ? dailyLimitGrams : weeklyLimitGrams / 7`
     (UK guideline has no daily limit; fallback keeps Today bar meaningful)
   - `formattedNumber(_ grams: Double) -> String` — number only, no unit label

2. **`DashboardView.swift`**
   - Add `Text(localized: "dashboard.section.today")` label + `metricsGrid`
   - Add `ConsumptionOverviewCard(vm:)` after metricsGrid
   - Replace `WeeklyGoalCard(vm:)` with `ThisWeekCard(vm:)`
   - Delete `WeeklyGoalCard` private struct
   - Add `ConsumptionOverviewCard` + `IntakePeriodRow` + `ThisWeekCard` private structs

3. **`Localizable.xcstrings`** — add 6 keys (see below)

4. **Build + test** — existing 52 tests + new VM tests must stay green

## New localization keys

| Key | EN | DE | PL |
|-----|----|----|-----|
| `dashboard.section.today` | Today | Heute | Dziś |
| `dashboard.section.thisWeek` | This Week | Diese Woche | Ten tydzień |
| `dashboard.overview.title` | Overview | Überblick | Spożycie |
| `dashboard.overview.days7` | 7 Days | 7 Tage | 7 dni |
| `dashboard.overview.days30` | 30 Days | 30 Tage | 30 dni |
| `dashboard.overview.overLimit` | +%@ over limit | +%@ über Limit | +%@ powyżej normy |

(`dashboard.section.today` doubles as the "Today" row label in the overview.)

## Files

| File | Action |
|------|--------|
| `Features/Dashboard/DashboardViewModel.swift` | Modify |
| `Features/Dashboard/DashboardView.swift` | Modify |
| `drinkpulse/Localizable.xcstrings` | Modify |
| `drinkpulseTests/DashboardViewModelTests.swift` | Modify |
| `docs/plans/INDEX.md` | Add 0003 |
| `docs/DEVLOG.md` | Append |
