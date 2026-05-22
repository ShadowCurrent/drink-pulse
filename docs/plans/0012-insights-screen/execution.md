# 0012 Execution Journal

Append-only. Newest entry at the bottom.

---

## 2026-05-22 — Implementation complete

**Decisions made before coding (plan open questions):**
- Q1 Heatmap first weekday: **Locale-aware** (`Calendar.current.firstWeekday`) — owner chose B.
- Q2 Binge threshold: **Per-guideline** (60 g WHO/DE, 56 g UK, 70 g US) — owner chose B.
- Q3 Heatmap empty state: **Greyed cells** (always render 4×7 grid) — owner chose A.
- Q4 Charts library: Swift Charts confirmed (already planned).

**Files created:**
- `InsightsPeriod.swift` — enum + value types (ChartPoint, WeekdayBar, HeatmapCell, GuidelineComparison)
- `InsightsViewModel.swift` — core aggregations: seriesData, weekdayAverages, sevenDayGrams, monthCaloriesKcal, monthSpend, guidelineComparisons
- `InsightsViewModel+Heatmap.swift` — heatmapCells (4×7 locale-aware), bingeEpisodesThisMonth
- `InsightsView.swift` — replaced placeholder; @Query wires events + profile into VM
- `Components/PeriodPicker.swift` — segmented Picker for week/month/year
- `Components/AlcoholAreaChart.swift` — AreaMark + LineMark, `.monotone`, period-adaptive axis labels
- `Components/WeekdayBarChart.swift` — BarMark per weekday, risk-coloured
- `Components/ActivityHeatmap.swift` — 4×7 LazyVGrid, opacity-scaled cells, locale-aware column headers, legend
- `Components/HealthMetricRow.swift` + `HealthMetricsCard` — icon + title + value rows; binge/spend show only when > 0
- `Components/GuidelineComparisonCard.swift` — progress bars for WHO/NHS/DHS vs rolling 7-day intake
- `drinkpulseTests/InsightsViewModelTests.swift` — 27 tests covering all VM computed properties

**Deviations from plan:**
- `InsightsPeriod.swift` doubles as the types file for ChartPoint/WeekdayBar/HeatmapCell/GuidelineComparison — no separate types file needed.
- `formattedSpend(_:)` added to `InsightsViewModel` (mirrors DashboardViewModel) for currency-aware formatting.
- `cal`, `sex`, `guidelineChoice` changed from `private` to `internal` in the main VM to allow access from `+Heatmap.swift` extension.
- `chartYScale(domain: 0...)` replaced with `.chartYScale(domain: .automatic(includesZero: true))` — Swift Charts API.

**Test results:** 167 tests (27 new), all passing. 140 existing tests unaffected.
