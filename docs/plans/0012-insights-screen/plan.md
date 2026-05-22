# 0012 — Insights screen

**Status**: in-progress
**Frozen**: 2026-05-22
**Size**: large
**Created**: 2026-05-19

## Summary

Add a dedicated Insights tab that surfaces drinking patterns the Dashboard
cannot fit:

1. **Period picker** — Week / Month / Year segmented control.
2. **Area chart** — pure-alcohol grams over time for the selected period.
3. **Weekday patterns** — bar chart of average grams by day of week
   (colour-coded low/moderate/high).
4. **Activity heatmap** — last 4 weeks (Mon→Sun) with opacity-scaled
   cells (current-week label is highlighted).
5. **Health metrics** — binge episodes, risk level, alcohol calories,
   monthly spend. Each row carries a coloured icon + optional badge.
6. **Guideline comparison** — progress bars vs WHO / NHS / DHS limits using
   the *user's actual data* (not the selected guideline).

## Context

The Claude Design handoff (2026-05-19) ships an Insights mockup as the
2nd tab. The user noted that PDF export of insights is a desirable future
extension (out of scope for this plan).

Computation already exists for: weekly/30-day totals, risk level, calories.
New computations: average grams by weekday, heatmap matrix, "binge"
detection (defined as >60 g in one session in a UK/WHO context; revisit
threshold per guideline).

## Scope

### In
- `Features/Insights/InsightsView.swift` — top-level screen.
- `Features/Insights/InsightsViewModel.swift` — all logic; reads
  `[ConsumptionEvent]` + `UserProfile`.
- `Features/Insights/Components/` — `PeriodPicker`, `AlcoholAreaChart`,
  `WeekdayBarChart`, `ActivityHeatmap`, `HealthMetricRow`, `GuidelineComparisonCard`.
- Charts via **Swift Charts** (`import Charts`) — area + bar use system API;
  the heatmap is a custom `LazyVGrid` (Swift Charts has no native heatmap
  mark in iOS 18+).
- Tests for `InsightsViewModel`:
  - `weekdayAverages` returns 7 entries summed and divided by week count
    in range, not by *total* days.
  - `heatmapCells` returns 28 cells (4 × 7), oldest first.
  - `bingeEpisodesThisMonth` counts sessions where any 3-hour rolling
    window exceeds 60 g.
- Localized strings for every label/eyebrow.

### Out
- PDF export of Insights — see [[future-insights-pdf-export]] memory and
  roadmap entry.
- Comparative "vs last period" sparklines beyond the headline ±%.
- Per-drink-category breakdown chart (acceptable future addition).
- Configurable binge threshold; uses 60 g default.

## Implementation steps

1. **VM scaffolding** — `@Observable @MainActor InsightsViewModel`.
   Inputs: `events`, `profile`, `now`, `period: InsightsPeriod`.
2. **Period model** — `enum InsightsPeriod { case week, month, year }` with
   `dateRange(now:) -> ClosedRange<Date>` and `bucketSize: Calendar.Component`.
3. **`seriesData`** — `[ChartPoint]` for the area chart; bucket by day for
   week, week for month, month for year (this is what the design shows).
4. **`weekdayAverages`** — `[WeekdayBar]` of 7 entries.
5. **`heatmapMatrix`** — `[[Double]]` 4×7 starting `Mon` (locale-respecting
   first-weekday? — see Q1).
6. **Health metrics** — derived once: bingeEpisodes, currentRiskLevel,
   monthCalories, monthSpend (nil-safe).
7. **Guideline comparison** — compute usage in pure grams; render bars
   for WHO/NHS/DHS using their *weekly* limits regardless of user's
   chosen guideline (per design).
8. **Tests** — VM unit tests for each derived collection. Each test seeds
   deterministic events via `now: Date` injection.
9. **Wire into shell** — placeholder created in [[plan-0010]]; replace.
10. **Localisation** — all labels via `String(localized:)`.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Insights/InsightsView.swift` | Create |
| `drinkpulse/Features/Insights/InsightsViewModel.swift` | Create |
| `drinkpulse/Features/Insights/InsightsPeriod.swift` | Create |
| `drinkpulse/Features/Insights/Components/PeriodPicker.swift` | Create |
| `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` | Create |
| `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` | Create |
| `drinkpulse/Features/Insights/Components/ActivityHeatmap.swift` | Create |
| `drinkpulse/Features/Insights/Components/HealthMetricRow.swift` | Create |
| `drinkpulse/Features/Insights/Components/GuidelineComparisonCard.swift` | Create |
| `drinkpulseTests/InsightsViewModelTests.swift` | Create |
| `drinkpulse/Localizable.xcstrings` | Append keys |

## Open questions

- [ ] **Q1 — First weekday in heatmap**: locale-aware (`Calendar.current.firstWeekday`)
  or always Mon→Sun (matches design copy "Mon → Sun")?
  - A) Always Mon→Sun, hard-coded labels (default — matches design)
  - B) Locale-aware (more correct but design-divergent)

- [ ] **Q2 — Binge threshold**: 60 g per session is the WHO heavy-episodic-
  drinking threshold (~5+ US drinks). Use a fixed 60 g, or branch by
  guideline?
  - A) Fixed 60 g (default — simple, defensible)
  - B) Per-guideline (60 g WHO/DE, 56 g UK 7-units, 70 g US 5-drinks-NIAAA)

- [ ] **Q3 — Empty states**: what does each card show when the user has
  no events in the period? Defaults:
  - Area chart: empty illustration "No data yet — log a drink to see trends"
  - Heatmap: render greyed cells
  - Health metrics: hide cards with no data (binge / spend); keep risk
    showing "Low" (no events ⇒ no risk)
  - Guideline comparison: render bars at 0%

- [ ] **Q4 — Charts library**: Swift Charts (system) confirmed. Avoid any
  third-party charting library per CLAUDE.md.

## Tests required

- See implementation step 8.
- Snapshot of full screen in light + dark; one snapshot with empty data.

## Future links

- [[future-insights-pdf-export]] — export current view as PDF.
- [[plan-0007]] — `dpGlassCard`, `dpRiskLow/Moderate/High`.
- [[plan-0010]] — placeholder gets replaced.
- [[plan-0015]] — "Risk level" health-metric value uses the new "Low/
  Moderate/High Risk" labels.
