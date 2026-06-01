# 0020 — Week start: locale-aware across Dashboard and Insights

**Status**: in-progress
**Frozen**: 2026-06-01
**Size**: small
**Created**: 2026-05-31

## Summary

`DashboardViewModel` has `weekStartsOnMonday: Bool = true` hardcoded, which
forces `firstWeekday = 2` (Monday) regardless of the user's iOS locale.

Fix: remove `weekStartsOnMonday`, derive the calendar from
`Calendar.current` (whose `firstWeekday` mirrors the iOS setting at
Settings → General → Language & Region → First Day of Week).
`InsightsViewModel` already uses `Calendar.current` and is correct.

### Precise impact (verified against the code, 2026-05-31)

Most of `DashboardViewModel`'s aggregates use `startOfDay` and day-offset
arithmetic, which are **independent of `firstWeekday`**. Only the
**calendar-week interval** changes behaviour. Concretely:

| Property | Depends on `firstWeekday`? | UI consumer |
|----------|---------------------------|-------------|
| `weekInterval` (private) | **Yes** | feeds the two below |
| `weeklyGrams` (Mon–Sun total) | **Yes** | **none** — only referenced by the existing unit test |
| `weekBarData` (7-bar chart) | **Yes** | `ThisWeekCard` — the real user-visible change |
| `weeklyPct` / `riskLevel` | No — use `sevenDayGrams` (rolling 7-day) | `GuidelineAlertCard`, `DashboardMetricCards` |
| "7 Days" progress bar | No — uses `sevenDayGrams` | `ConsumptionOverviewCard` |
| `todayGrams`, `thirtyDayGrams`, streaks, sober days, greeting | No — `startOfDay`/offsets | various |

**Therefore the only user-visible effect of this fix is that the
`ThisWeekCard` bar chart starts its 7 bars on the locale's first weekday
and spans the correct calendar week.** `weeklyGrams` changes too, but it
has no view consumer today — keep it for the bar-chart total and tests.
The earlier draft's claim that "weekly percentage" was affected was wrong:
`weeklyPct` is computed from the rolling `sevenDayGrams`.

## Context

Surfaced during plan-0013 design review: calendar grid in History uses
`Calendar.current.firstWeekday` (locale-aware), but Dashboard's
weekly aggregation does not — creating an inconsistency where the same
"week" can start on different days depending on which screen the user
is looking at.

`UserProfile` has no `firstWeekday` field and should not gain one;
the system calendar is the canonical source, consistent with [[plan-0013]].

## Root cause

```swift
// DashboardViewModel.swift line 23 — current broken state
var weekStartsOnMonday: Bool = true

private var cal: Calendar {
    var c = Calendar.current
    c.firstWeekday = weekStartsOnMonday ? 2 : 1  // ignores system setting
    return c
}
```

The comment in the source already acknowledged this: *"Drive from
UserProfile when first-day-of-week setting is added."*  No UserProfile
field is needed — the system locale is enough.

## What is correct vs broken

| Location | Current state | After fix |
|----------|--------------|-----------|
| `DashboardViewModel.cal` | Hardcoded `firstWeekday = 2` (Mon) | injectable `var calendar = .current` |
| `InsightsViewModel.cal` | `Calendar.current` ✓ | No change |
| `InsightsPeriod.dateRange` | Receives `calendar` param from InsightsVM ✓ | No change |
| `InsightsViewModel+Heatmap` | Uses `cal` → `Calendar.current` ✓ | No change |
| `InsightsViewModel+Charts` | Uses `cal.firstWeekday` ✓ | No change |

### Internal `cal` references to rename to `calendar`

`cal` is read in many places in `DashboardViewModel.swift`; **all** must be
updated when the property is renamed (a missed one will not compile, which
is the safety net). At time of writing the references are in: `limits`
(no), `todayGrams`, `todayDrinkCount`, `todaySpend`, `thirtyDayGrams`,
`sevenDayGrams`, `weekInterval`, `weekBarData`, `currentStreakDays`,
`soberDaysThisMonthDates`, `greetingText`. Rename is mechanical; behaviour
only changes where `firstWeekday` matters (the `weekInterval` cases above).

## Scope

### In
- `DashboardViewModel.swift`: remove `weekStartsOnMonday`, change `cal`
  to return `Calendar.current`.
- To keep the change injectable for tests: replace the private `cal`
  computed property with `var calendar: Calendar = .current` (public,
  settable in tests). Remove the computed wrapper.
- `DashboardViewModelTests+Metrics.swift`: add two regression tests —
  one with a Sunday-first calendar, one with a Monday-first calendar —
  verifying that `weeklyGrams` counts only events within the correct
  calendar week boundary.

### Out
- Adding a per-user "first day of week" override in `UserProfile` or
  Settings UI — explicit out. System calendar is sufficient.
- Any change to `InsightsViewModel` — already correct.

## Implementation steps

1. In `DashboardViewModel.swift`:
   - Delete `var weekStartsOnMonday: Bool = true`.
   - Delete the `private var cal: Calendar { ... }` computed property.
   - Add `var calendar: Calendar = .current` (replaces both).
   - Update all internal uses of `cal` to `calendar`.

2. In `DashboardViewModelTests+Metrics.swift` — design the tests around a
   **fixed `now` and a fixed event date** so the result actually flips with
   `firstWeekday` (a "Saturday" event is in the same week under both Mon-
   and Sun-first calendars, so it proves nothing). Use a date whose week
   membership differs between the two calendars:

   - Helper `calendar(firstWeekday: Int) -> Calendar` returning
     `Calendar.current` with `firstWeekday` overridden (1 = Sun, 2 = Mon).
   - Pin `vm.now` to **Wednesday 2026-05-27** and place the event on the
     preceding **Sunday 2026-05-24**. Then:
     - **Sunday-first** (`firstWeekday = 1`): the week is Sun 05-24 … Sat
       05-30, so the Sunday event **is** in the current week →
       `weeklyGrams` includes it.
     - **Monday-first** (`firstWeekday = 2`): the week is Mon 05-25 … Sun
       05-31, so the Sunday 05-24 event falls in the **previous** week →
       `weeklyGrams` excludes it.
   - Add `test_weeklyGrams_includesPrecedingSunday_whenWeekStartsSunday`.
   - Add `test_weeklyGrams_excludesPrecedingSunday_whenWeekStartsMonday`.
   - Build both events through the existing `event(daysAgo:grams:in:)`
     helper is **not** suitable here (it is relative to `.now`); add a
     `event(on date: Date, grams:in:)` overload, or construct the
     `ConsumptionEvent` with an explicit `timestamp` from
     `DateComponents(year: 2026, month: 5, day: 24)`.
   - Keep the existing `weeklyGrams_sumsCurrentCalendarWeekOnly` green; its
     "8 days ago" event is in a previous week under any `firstWeekday`, so
     it remains valid. Add a one-line comment noting it no longer assumes a
     hardcoded Monday start.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Dashboard/DashboardViewModel.swift` | Modify — remove `weekStartsOnMonday`, add `var calendar` |
| `drinkpulseTests/DashboardViewModelTests+Metrics.swift` | Modify — add locale-aware week regression tests |

## Tests required

- `test_weeklyGrams_includesPrecedingSunday_whenWeekStartsSunday`
- `test_weeklyGrams_excludesPrecedingSunday_whenWeekStartsMonday`
- Existing `weeklyGrams_sumsCurrentCalendarWeekOnly` must stay green.

## Risk

Low. The behavioural change is confined to `weekInterval` and its two
consumers (`weeklyGrams`, `weekBarData`); the only user-visible surface is
the `ThisWeekCard` bar chart. No persistence, no migration. The change
affects only users whose iOS locale starts the week on a day other than
Monday.

### Living-docs check

- `domain.md` / `architecture.md`: confirm neither states "week starts
  Monday" as a rule. If `domain.md` documents the weekly aggregation, update
  it to say the week boundary follows the system locale's first weekday.
- No ADR needed — this aligns the Dashboard with the already-documented
  locale-aware behaviour in Insights and [[plan-0013]]; it introduces no new
  pattern.
