# 0004 — Dashboard View Split

**Status**: in-progress
**Size**: small
**Created**: 2026-05-18
**Frozen**: 2026-05-18

## Summary

`DashboardView.swift` has grown to 502 lines, exceeding the ~200-line soft limit
and the 300-line audit threshold in CLAUDE.md. Extract private sub-views into a
`Components/` subfolder following the project's established feature layout.

## Scope

Pure structural refactor — no semantic changes, no API changes, no logic changes.

### In

- Split `DashboardView.swift` into 5 files:
  1. `DashboardView.swift` — root view + `RiskBadge` (~180 lines)
  2. `Components/DashboardMetricCards.swift` — `MetricCard`, `StreakCard`, `GuidelineAlertCard` (~100 lines)
  3. `Components/ConsumptionOverviewCard.swift` — `ConsumptionOverviewCard` + `IntakePeriodRow` (~130 lines)
  4. `Components/ThisWeekCard.swift` — `ThisWeekCard` with chart logic (~55 lines)
  5. `DashboardView+Previews.swift` — 3 preview macros (~55 lines)

### Out

- No changes to `DashboardViewModel.swift`
- No changes to tests
- No changes to any other feature

## Visibility change

Extracted types are currently `private struct` (file-private). Moving them to
separate files promotes them to `internal`. They are still not exposed beyond
the module; nothing outside `Features/Dashboard/` references them.

## Verification

```bash
xcodebuild -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" \
  | xargs wc -l | sort -rn | awk '$1 > 300 {print}'
```

Expected: build clean, 60/60 tests green, no files over 300 lines.
