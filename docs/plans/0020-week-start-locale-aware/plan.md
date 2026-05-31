# 0020 — Week start: locale-aware across Dashboard and Insights

**Status**: draft
**Size**: small
**Created**: 2026-05-31

## Summary

`DashboardViewModel` has `weekStartsOnMonday: Bool = true` hardcoded.
As a result the "This week" progress bar, weekly gram total, and weekly
percentage always count Mon–Sun regardless of the user's iOS locale.
`InsightsViewModel` already uses `Calendar.current` and is correct.

Fix: remove `weekStartsOnMonday`, derive the week boundary from
`Calendar.current.firstWeekday` (which mirrors the iOS setting at
Settings → General → Language & Region → First Day of Week).

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
| `DashboardViewModel.cal` | Hardcoded `firstWeekday = 2` (Mon) | `Calendar.current` |
| `InsightsViewModel.cal` | `Calendar.current` ✓ | No change |
| `InsightsPeriod.dateRange` | Receives `calendar` param from InsightsVM ✓ | No change |
| `InsightsViewModel+Heatmap` | Uses `cal` → `Calendar.current` ✓ | No change |
| `InsightsViewModel+Charts` | Uses `cal.firstWeekday` ✓ | No change |

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

2. In `DashboardViewModelTests+Metrics.swift`:
   - Add helper `sundayFirstCalendar() -> Calendar` that returns a
     `Calendar` with `firstWeekday = 1`.
   - Add `test_weeklyGrams_sundayFirstCalendar` — creates an event on a
     Saturday, sets `vm.calendar = sundayFirstCalendar()`, verifies it
     is counted in the current week.
   - Add `test_weeklyGrams_mondayFirstCalendar` — same event on a
     Saturday with `firstWeekday = 2`; Saturday is still in the current
     Mon–Sun week, so still counted. The meaningful assertion is that
     an event 8 days ago is never counted regardless of firstWeekday.
   - Extend the existing `weeklyGrams_sumsCurrentCalendarWeekOnly` test
     comment to note the Mon-first assumption it relies on, or replace
     it with two calendar-parameterised variants.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Dashboard/DashboardViewModel.swift` | Modify — remove `weekStartsOnMonday`, add `var calendar` |
| `drinkpulseTests/DashboardViewModelTests+Metrics.swift` | Modify — add locale-aware week regression tests |

## Tests required

- `test_weeklyGrams_sundayFirstCalendar_countsEventInSameWeek`
- `test_weeklyGrams_mondayFirstCalendar_excludesEventInPreviousWeek`
- Existing `weeklyGrams_sumsCurrentCalendarWeekOnly` must stay green.

## Risk

Low. `weeklyGrams` is used only on the Dashboard progress bar and the
weekly percentage. No persistence, no migration. The change affects only
users whose iOS locale has Sunday as the first day of the week.
