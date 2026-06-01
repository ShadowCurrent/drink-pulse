# 0013 — Execution Journal

## 2026-06-01

Implemented per plan with no deviations.

**Files created:**
- `Components/EventRow.swift` — extracted from `HistoryView.swift`, changed from `private` to `internal`
- `HistorySegment.swift` — `enum HistorySegment { case list, calendar }`
- `HistoryViewModel.swift` — stateless `@Observable` with `DayCell` struct; methods: `groupedByDay`, `gramsByDay`, `monthCells`, `riskColor`
- `HistoryListQueryView.swift` — windowed `@Query` (90-day window, load-more sentinel)
- `HistoryCalendarQueryView.swift` — month-range `@Query` wrapper
- `Components/HistoryCalendarDayCell.swift` — rounded-square day button; risk-colored fill; today indicator; future dimmed + disabled
- `Components/HistoryCalendarDayDetail.swift` — inline detail panel: date header, total grams, EventRow list, sober-day placeholder
- `Components/HistoryCalendarView.swift` — weekday header + LazyVGrid 7-col + detail; wrapped in `.dpGlassCard()`
- `HistoryViewModelTests.swift` — 14 functional Swift Testing tests + 4 XCTestCase perf tests

**Files modified:**
- `HistoryView.swift` — full refactor: segment picker in toolbar, listWindowStart/monthShown/@State, canGoPrev/canGoNext, earliest-event `@Query` with `fetchLimit: 1`, delegates to list/calendar sub-views
- `Localizable.xcstrings` — added 7 history.calendar.* and history.segment.* keys (en + pl)
- `project.pbxproj` — manually added HistoryViewModelTests.swift to test target

**Build / tests:**
- `xcodebuild build` → BUILD SUCCEEDED, zero Swift warnings
- `xcodebuild test` → 268/268 passed

**Performance (simulator):**
- `gramsByDay` 2000 events: ~6ms avg ✓ (budget: <10ms)
- `gramsByDay` 10000 events: ~30ms avg ✓ (budget: <50ms)
- `groupedByDay` 2000 events: ~8ms avg ✓ (budget: <10ms)
- `monthCells` 36 months × 2000 events: ~5ms per call ✓ (budget: <10ms)

**Decision — format specifiers in xcstrings:**
xcstrings rejects mixed positional/non-positional format specifiers. Accessibility labels that
include grams values are built entirely in Swift code; xcstrings keys for those strings are
simple (non-format) suffixes ("sober day", "future").
