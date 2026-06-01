# 0013 — Retrospective

**Completed**: 2026-06-01
**Size**: medium (actual effort matched estimate)

## What went well

- Pre-verification of code state (HistoryView had no toolbar `+`, EventRow was private) meant
  no surprises during extraction.
- Dynamic `@Query` pattern with `fetchLimit = 1` for the earliest-event bound worked cleanly
  in `HistoryView.init` without needing a separate wrapper view.
- Performance well within budget: `monthCells` averages ~5ms per call even with 2000 events.
- `PBXFileSystemSynchronizedRootGroup` for the app target meant all new source files were
  picked up automatically; only the test target needed manual project.pbxproj edits.

## What could be improved

- xcstrings rejects mixed `%@`/`%f` format specifiers (even with positional notation). Discovered
  at build time. For future plans: accessibility strings with numeric values → build in code, not
  xcstrings format strings.
- test target uses old-style PBXGroup (no synchronized group) → new test files require manual
  project.pbxproj edits. Worth noting for future contributors.

## Decisions

- Navigation arrows (←/→) placed in `HistoryView.calendarNavHeader`, not in `HistoryCalendarView`,
  since `canGoPrev`/`canGoNext` are computed in `HistoryView` (where the earliest-event @Query lives).
- `DayCell.position` used as `Identifiable.id` (stable within a month render) rather than UUID
  (re-created each render) or date (nil for padding cells).
- Empty state (`ContentUnavailableView`) shown only for the list segment; calendar always renders
  (empty grid is informative for new users).
