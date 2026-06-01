# 0020 — Execution Journal

## 2026-06-01

Implemented per plan with no deviations.

**Changes made:**
- `DashboardViewModel.swift`: removed `weekStartsOnMonday: Bool = true` and the
  `private var cal: Calendar` computed property; replaced with `var calendar: Calendar = .current`.
  Renamed all internal `cal.` references to `calendar.` (mechanical — ~15 call sites; all
  compile errors would surface a missed rename, none did).
- `DashboardViewModelTests+Metrics.swift`: added private helpers `calendar(firstWeekday:)`
  and `eventOnDate(_:grams:in:)`; added two new regression tests
  `weeklyGrams_includesPrecedingSunday_whenWeekStartsSunday` and
  `weeklyGrams_excludesPrecedingSunday_whenWeekStartsMonday`. Updated comment on existing
  `weeklyGrams_sumsCurrentCalendarWeekOnly` to note it is now calendar-agnostic.

**Verification:**
- `xcodebuild build` → BUILD SUCCEEDED, zero warnings (SourceKit false-positives due to
  indexing lag, not compilation errors).
- `xcodebuild test` → all 3 weeklyGrams tests pass. 2 pre-existing InsightsViewModelTests
  failures (`monthSpend_sumsAllPricesInActivePeriod`, `bingeEpisodes_twoDaysAboveThreshold_countsBoth`)
  confirmed present on main before this change — not introduced here.

**Living docs:** `domain.md` has no mention of week-start rules; no update needed.
