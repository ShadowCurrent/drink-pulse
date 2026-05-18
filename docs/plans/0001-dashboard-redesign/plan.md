# 0001 — Dashboard Redesign

**Status**: in-progress
**Size**: large
**Created**: 2026-05-18
**Frozen**: 2026-05-18

## Summary

Replace the current three-ring dashboard with a richer layout inspired by the
Figma sketch (provided as React/Tailwind). New sections: header with risk badge,
2×2 metrics grid, weekly goal card (ring + bar chart), streak/sober-days row,
and a guideline alert card. All computed logic moves to a testable
`DashboardViewModel`. Design system colour tokens introduced.

## Context

The existing dashboard shows three `IntakeRing` components (today / 7-day / 30-day)
side by side. It has no per-day breakdown, no calorie estimate, no streak tracking,
and no actionable summary card. The Figma sketch defines a card-based layout that
carries more information while staying scannable. Hydration reminder from the
sketch is **not** implemented.

Light and dark mode support is required from day one. Background colours are
TBD — adaptive system colours used as placeholders until the design is finalised.

## Scope

### In
- `DesignSystem/DPColors.swift` — semantic colour tokens (adaptive + accent palette)
- `DashboardViewModel` — all computed properties extracted from the view
- `DashboardView` full rewrite with new section layout
- Swift Charts bar chart (Mon–Sun of current week)
- `RiskBadge`, `MetricCard`, `WeeklyGoalCard`, `StreakCard`, `GuidelineAlertCard` subcomponents
- Unit tests for all non-trivial VM logic

### Out
- Hydration reminder
- Calorie tracking as a stored field (calories are a derived value: `grams × 7.1`)
- iCloud or HealthKit integration (separate plans)
- History calendar view (separate plan)
- Dashboard background colour finalisation (deferred until design sign-off)

## Implementation steps

1. **`DesignSystem/DPColors.swift`** — `Color` extension with adaptive card colours
   and fixed accent palette (`dpTeal`, `dpAmber`, `dpRed`, `dpPurple`, `dpGreen`).
   Add `Color(hex:)` initialiser if not already present.

2. **`DashboardViewModel`** — `@Observable @MainActor final class`.
   Properties: all from the table below. Receives `events: [ConsumptionEvent]`,
   `profile: UserProfile?`, `now: Date` as inputs (injected by the view, not
   fetched internally — keeps VM testable without SwiftData).

3. **`DashboardViewModelTests`** — write tests before or alongside step 2.
   Cover: `todayCaloriesKcal`, `weekBarData` (count, `isToday`, `isFuture`),
   `riskLevel` thresholds, `currentStreakDays` (0 if drank today; N otherwise),
   `soberDaysThisMonth`.

4. **Subcomponents** (private structs inside `DashboardView.swift`):
   `RiskBadge`, `MetricCard`, `WeeklyGoalCard` (ring + bar chart),
   `StreakCard`, `GuidelineAlertCard`.

5. **`DashboardView` rewrite** — wire subcomponents to VM, keep `+` toolbar button,
   keep `scenePhase` refresh of `now`. Add `import Charts`.

6. **Previews** — `#Preview("With data")` with representative events across the
   current week; `#Preview("Empty")` for zero-state; `#Preview("Over limit")`
   for the exceeded risk badge.

## DashboardViewModel — computed properties

| Property | Type | Logic |
|----------|------|-------|
| `todayGrams` | `Double` | sum `pureAlcoholGrams` for events `≥ startOfDay(now)` |
| `weeklyGrams` | `Double` | sum for events `≥ 7 days ago` |
| `todayCaloriesKcal` | `Int` | `Int(todayGrams × 7.1)` |
| `todayDrinkCount` | `Int` | count of today's events |
| `todaySpend` | `Double?` | sum of `event.price` today; `nil` if no event has a price |
| `weekBarData` | `[WeekBarEntry]` | Mon–Sun of current week (see below) |
| `currentStreakDays` | `Int` | consecutive sober days ending yesterday; 0 if drank today |
| `soberDaysThisMonth` | `Int` | days in current month with zero consumption |
| `soberDaysThisMonthDates` | `[Date]` | for subtitle "May 5, 9, 15" |
| `riskLevel` | `RiskLevel` | `weeklyPct < 0.5` → safe · `< 1.0` → caution · `≥ 1.0` → exceeded |
| `weeklyPct` | `Double` | `weeklyGrams / weeklyLimit` |
| `greetingText` | `String` | hour-based "Good morning / afternoon / evening" |

### WeekBarEntry

```swift
struct WeekBarEntry: Identifiable {
    var id: Date { day }
    let day: Date
    let label: String    // "Mon", "Tue", …  (locale-aware abbreviated weekday)
    let grams: Double
    let isToday: Bool
    let isFuture: Bool
}
```

Bar colour (computed in VM, applied via `foregroundStyle` in the chart):

| Condition | Colour |
|-----------|--------|
| `isToday` | `.dpTeal` |
| `isFuture` | `Color(.quinarySystemFill)` |
| past, `grams > dailyLimit` | `.dpAmber` |
| past, `grams ≤ dailyLimit` | `Color(.tertiarySystemFill)` |

## Metrics grid (2×2)

| Label | Value | Unit | SF Symbol | Accent |
|-------|-------|------|-----------|--------|
| Today's Alcohol | `todayGrams` formatted per `alcoholUnit` | g / units | `drop.fill` | `.dpTeal` |
| Calories | `todayCaloriesKcal` | kcal | `flame.fill` | `.dpAmber` |
| Drinks Today | `todayDrinkCount` | drinks | `bolt.fill` | `.dpPurple` |
| Today's Spend | `todaySpend` | currency (Q4) | `chart.line.uptrend.xyaxis` | `.dpGreen` |

## Files

| File | Action |
|------|--------|
| `DesignSystem/DPColors.swift` | Create |
| `Features/Dashboard/DashboardViewModel.swift` | Create |
| `Features/Dashboard/DashboardView.swift` | Full rewrite |
| `drinkpulseTests/DashboardViewModelTests.swift` | Create |
| `docs/DEVLOG.md` | Append |
| `docs/roadmap.md` | Dashboard expansion → 🔄 then ✅ |
| `docs/plans/INDEX.md` | Update status to in-progress on start, completed on finish |

No SwiftData schema changes — calories and spend are derived values.

## Open questions

- [ ] **Q1 — Greeting name**: `UserProfile` has no `name` field. Options:
  - A) No name — "Good evening" *(default if no answer)*
  - B) Add optional `var displayName: String?` to `UserProfile` (lightweight migration)

- [ ] **Q2 — Guideline card tap**: What does tapping the red alert card do?
  - A) Switch to Settings tab *(default if no answer)*
  - B) Open guideline picker sheet directly
  - C) No action for now

- [ ] **Q3 — Spend card when no prices**: If today's events have no `price`:
  - A) Hide the card *(default if no answer)*
  - B) Show "—"
  - C) Show "0.00"

- [ ] **Q4 — Currency formatting**: `UserProfile.currency` is a plain String ("USD", "EUR").
  - A) Display as prefix text: "USD 13.50" *(default if no answer)*
  - B) Format via `Locale` / `NumberFormatter` with proper symbol

## Tests required

- `todayCaloriesKcal`: 20 g → 142 kcal; 0 g → 0 kcal
- `weekBarData`: always 7 entries; exactly one `isToday == true`; future entries have `grams == 0` and `isFuture == true`
- `riskLevel`: boundary values at 0.5× and 1.0× of weekly limit
- `currentStreakDays`: 0 when events exist today; correct count when last drink was N days ago
- `soberDaysThisMonth`: correct count for a month with mixed drinking/sober days
