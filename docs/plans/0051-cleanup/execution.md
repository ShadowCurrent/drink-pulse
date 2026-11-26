# 0051 — Execution journal

## 2026-11-26 — Execution (inline, superpowers `executing-plans`)

Branch `port/0051-cleanup` from `ui-revamp` at `0cfa7e6`. Xcode MCP workspace
`drinkpulse.xcodeproj` (identifier resolved via `XcodeListWorkspaces`); active destination
iPhone 18 Pro simulator, iOS 27.2. All tests via MCP `RunSomeTests` within the D0051-7 scope;
no `RunAllTests`, no coverage. Every `BuildProject` was clean (0 errors, 0 warnings via
`GetBuildLog` severity `warning`).

**Test-count note:** the `RunSomeTests` JSON summary also lists tests that no longer exist
(deleted or renamed ones still in Xcode's test index), shown as "Passed". The counts below are
from the `.xcresult` bundle (`xcresulttool get test-results summary`), which lists only tests
that ran.

### Task 1 — Delete dead design-system files
- `XcodeGrep` for the nine symbols: matches only inside `DPGlass.swift`, `DPColors.swift`,
  `DPLargeTitle.swift`. Deleted all three with `XcodeRM`.
- `dpSecondaryText` doc comment now describes the Frost tint (List / Form screens and cards),
  keeps the 3.2–3.4:1 vs 4.96:1 reason and the plan 11-17 / 0043 references.
- `DPSemanticColorsTests` 3/3.

### Task 2 — Delete test-only view-model members (D0051-1)
- Grep matched the plan's evidence table, with one difference: there are **6**
  `bingeEpisodes_*` tests reading `bingeEpisodesThisMonth`, not 5 (lines 204–261; file
  unchanged since `6d12cb1`, so a plan miscount, not a new use). All 6 retargeted to
  `bingeEpisodes` with unchanged fixtures and expected values.
- `monthCaloriesKcal_*` → `periodCaloriesKcal_*` (2), `monthSpend_*` → `periodSpend_*` (3),
  MARK lines updated. Deleted `comparisonLabel_*` (2), `todaySpend_*` (3), Dashboard
  `formattedSpend_*` (2), `canContinueProfile_falseUntilSexChosen`, and the `_ = vm.todaySpend`
  line in `ScreenComputePerformanceTests`.
- Deleted the D0051-1 members; Insights `formattedSpend` kept. Re-grep: no reference left.
- Insights / Dashboard / Onboarding / DrinkTemplate / ScreenComputePerformance VM tests:
  xcresult 169/169.

### Task 3 — Delete 21 unused string-catalog keys (D0051-2)
- Each key: 0 matches as `"key"` in Swift sources, 0 in `Info.plist`. Dynamic lookups
  (`settings.abvPrecision.*`, `settings.version.*`, notification / Health hint–denied pairs,
  `history.search.noResults.title`, inflection strings) use none of them.
- **`StringCatalogEdit` tool description** (read before use): "Inserts a translation for a given
  locale into a String Catalog." It cannot delete keys. **Fallback:** removed each
  `    "key" : {` block line by line from the original text, in Xcode's own format.
  `json.dumps` was rejected because it does not round-trip the file (Xcode writes empty
  dictionaries as `{` + blank line + `}`).
- Check (`python3 -I`): 276 keys, none of the 21, valid JSON, the other 276 entries identical
  to before; diff is 231 pure deletions. After the build: 0 stale keys.
- `DashboardUITests`, `InsightsUITests`, `HistorySearchUITests`: 22/22.

### Task 4 — Move `Calendar.days(in:)` to Domain
- New `drinkpulseTests/Domain/CalendarDaysTests.swift` (3 tests, Europe/Warsaw, 2026): PASS
  before the move (pins existing behaviour, as planned).
- `XcodeMV` to `drinkpulse/Domain/Calendar+Days.swift`; git records a 100 % rename.
- `CalendarDaysTests`, `InsightsPeriodTests`, `InsightsViewModelTests`,
  `DashboardViewModelTests`: xcresult 175/175.

### Task 5 — Plan 0050 minors 1, 3, 5
- `longestSoberStreak_reducedWhenHasDrinkingDay`: month, `now = july18Noon`, 0 g event 5 days
  ago, 30 g event 2 days ago, `#expect(... == 3)`. PASS. Mutation check: changed to `== 4`, the
  test failed with `vm.longestSoberStreak → 3`; restored to `== 3`. Value is exactly 3 as the
  plan derives.
- `DashboardView.streakTiles`: `let streak = vm.currentStreakDays` once, explicit
  `return TilePair { … }`; copy, identifiers and layout unchanged.
- `AlcoholFreeDayRule.heavyDayCount(in:grams:)`: doc comment on the unnormalised date contract,
  pointing to D0051-5.
- `AlcoholFreeDayRuleTests`, `DashboardViewModelTests`, the streak test, `DashboardUITests`,
  `DashboardAlcoholFreeUITests`: xcresult 96/96.

### Task 6 — Living docs
- README Dashboard `Components/` comment lists the real files.
- `docs/architecture.md`: design-system intro says every screen is ported; `AppLockState`
  example dropped (no app-wide `@Observable` environment type exists); `Domain/` line names
  `Calendar+Days.swift`. DesignSystem test and component lists checked against
  `drinkpulse/DesignSystem/` — still accurate.
- `.planning/PROJECT.md`: "Native UI port" paragraph in Current State; "fully native Liquid
  Glass" corrected.
- Identifier re-check: the remaining backticked names not in code are historical (`SchemaV5`,
  the `ObservableObject` ban, "gone / replaced" notes, phase history).

### Task 7 — Review and close
- File-size check: no output. `print(` in `drinkpulse/`: none.
- Final review: one fresh reviewer (Opus) over `0cfa7e6..HEAD`: 0 Critical, 0 Important,
  3 Minor (deferred):
  1. The DST-at-midnight gap also affects Today "Alcohol-Free This Month"
     (`soberDaysThisMonthDates`) — added to the open-questions entry.
  2. `CalendarDaysTests` spring-forward case uses a 02:00 transition, so it does not cover
     midnight-skip zones — a clarifying comment is left for the D0051-5 fix.
  3. PROJECT.md / architecture.md call 0051 done before the merge — true after the merge.
- ROADMAP.md does not list the port; no change.
