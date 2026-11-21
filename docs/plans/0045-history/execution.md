# 0045 — Execution Log

Append-only. Never edit or delete previous entries.

---

## 2026-11-21 — Execution (superpowers `executing-plans`, inline)

Branch `port/0045-history`. Simulator iPhone 18 Pro, iOS 27.2 (`XcodeListRunDestinations`
active destination). Builds, tests and previews through Xcode MCP, workspace resolved with
`XcodeListWorkspaces` (entry ending in `drinkpulse.xcodeproj`). No CLI `xcodebuild` / `xcrun`.

### Task 1 — day totals, day-aligned window, calendar marks

- Docs (`DocumentationSearch`, Foundation): `Calendar.startOfDay(for:)` ("Returns the first
  moment of a given Date"); `Calendar.date(byAdding:value:to:wrappingComponents:)` (no DST
  statement; `Date.addTimeInterval(_:)` warns that calendrical arithmetic must go through
  `Calendar`, which "will take into account complexities like daylight saving time").
  Implementation: `startOfDay(for: date(byAdding: .day, -7, to:))`, so a DST change in the
  page is absorbed by `startOfDay`.
- New: `HistoryDayTotal` (Σ `quantity`, Σ `alcoholGrams(density:)`),
  `HistoryCalendarMarks.levels(events:dailyLimitGrams:density:calendar:)` (`RiskLevel.from`).
- `HistoryViewModel.initialWindowStart` / `extendedWindowStart` now return start of day.
  Existing tests that encoded "now − 7 days": `initialWindowStart_isOnePageBeforeNow`,
  `extendedWindowStart_movesBackOnePage`, `extendedWindowStart_repeatedCalls_keepMovingBack`
  — expected value now wrapped in `startOfDay`. New: `test_initialWindowStart_isStartOfDay`,
  `test_extendedWindowStart_isStartOfDay_sevenDaysEarlier`,
  `test_windowStart_acrossDSTChange_isStartOfDay` (Europe/Warsaw, 2 April → 26 March 2026).
- Marks boundary test uses density 1.0 and `volumeMl × 0.5` grams so 10 g / 20 g are exact in
  binary floating point; an extra `test_marks_useGivenDensity` checks density pass-through at
  0.789 vs 0.8.
- RED: `HistoryDayTotal` undefined (compile); then the six window assertions failed at runtime
  (e.g. `2023-11-07 22:13:20` vs `2023-11-06 23:00:00`). GREEN: 44 / 49.
- **Pre-existing failures:** 5 `HistoryViewModelTests.riskColor_*` tests expect the old
  `dpGreen` / `dpAmber` / `dpRed`; `riskColor` returns `RiskLevel.tone` since plan 0042. They
  fail at the branch base too. Deleted with `riskColor` in Task 5.
