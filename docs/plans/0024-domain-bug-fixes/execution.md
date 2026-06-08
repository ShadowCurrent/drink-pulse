# 0024 — Execution journal

## 2026-06-06 — Plan frozen, implementation start

Confirmed approach with user: implement the `effectiveLimits` domain resolver
and fix both bugs.

### Decisions
- Resolver lives in `GuidelineChoice+Limits.swift` (existing domain file) as
  `effectiveLimits(weeklyGoalGrams:for:)`. The raw `limits(for:)` keeps its
  sentinel-zero behaviour for `.custom` (still tested by
  `GuidelineLimitsTests.customReturnsZeroSentinel`) — the resolver layers the
  custom-goal handling on top, so existing call sites that want raw thresholds
  are unaffected.
- Added `GuidelineLimits.effectiveDailyGrams` computed property to centralise
  the `dailyGrams > 0 ? dailyGrams : weeklyGrams / 7` UK fallback.
- `contentSignature`: dropped deprecated `name`; added `customName`,
  `category.rawValue`, `icon`.

## 2026-06-06 — Implemented and verified

### Changes
- `Domain/GuidelineLimits.swift`: added `effectiveDailyGrams` computed property.
- `Domain/GuidelineChoice+Limits.swift`: added `effectiveLimits(weeklyGoalGrams:for:)`.
- `Domain/DataTransfer/DataExporter.swift`: `contentSignature` now hashes
  `customName` / `category.rawValue` / `icon`; dropped deprecated `name`.
- `Features/Dashboard/DashboardViewModel.swift`: `limits` and
  `effectiveDailyLimitGrams` routed through the resolver.
- `Features/Insights/InsightsViewModel.swift`: `limits(for:)`,
  `effectiveDailyLimitGrams`, `effectiveDailyLimit(for:)` routed through the
  resolver. Preserved `?? 100` default weekly goal for no-profile custom.
- `Features/History/Components/HistoryCalendarView.swift`: `dailyLimit` routed
  through the resolver — **the actual Bug 2 fix**.

### Tests added
- `GuidelineLimitsTests`: effectiveDailyGrams (daily + UK fallback);
  effectiveLimits (non-custom == raw, custom uses goal & non-zero daily,
  zero-goal clamp).
- `DataExportImportTests`: signature changes on customName / category / icon edit.

### Verification
- `xcodebuild build` clean, zero warnings.
- `xcodebuild test`: 319 passed, 0 failed.
- Coverage: Domain files 100% (`GuidelineChoice+Limits`, `GuidelineLimits`,
  `DataExporter`); DashboardVM 98.5%, InsightsVM 95.3%. HistoryCalendarView is a
  SwiftUI view (excluded from denominator); its logic now lives in the
  100%-covered resolver.
- File-size gate: no file > 300 lines.

### Deviation from plan
- None material. Also corrected a stale UK-weekly value (112 → 110.46) in
  `docs/domain.md` found during the living-docs audit, and documented the two
  resolvers there. Noted (did not fix) a separate stale roadmap line about
  0.8 g/ml density — flagged to user.

Status → completed.
