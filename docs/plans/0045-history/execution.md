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

### Task 2 — day sections, bar picker, tint, empty state

- Docs (`DocumentationSearch`): `listSectionSpacing(_:)` (`.compact` "for a compact
  appearance between sections"; section-level spacing overrides list-level); `ViewThatFits`
  ("selects the first child whose ideal size on the constrained axes fits"; `in: .horizontal`);
  `ToolbarItemPlacement.principal` ("In iOS … the system places the principal item in the
  center of the navigation bar. This item takes precedent over a title"); 
  `ContentUnavailableView.init(label:description:actions:)`; Foundation automatic grammar
  agreement (`^[text](inflect: true)` Markdown extension, `AttributedString.LocalizationOptions.inflect`
  default `true`); `ScrollEdgeEffectStyle` (`.soft` "subtle, blurred boundary", `.hard`
  "linear, nearly opaque boundary") and `scrollEdgeEffectStyle(_:for:)` ("for scroll views
  within this hierarchy"); HIG Toolbars › Best practices ("use a ScrollEdgeEffectStyle when
  necessary to distinguish the toolbar area from the content area"; prefer standard
  components). `Calendar.isDate(_:equalTo:toGranularity:)` for the current-year check.
- New: `HistoryDayHeader` (title + `history.dayHeader.total %lld %@ %@` =
  `^[%lld drink](inflect: true) · %@ %@`, `ViewThatFits` HStack → VStack, `dpSecondaryText`,
  combined element, `.isHeader`, identifier `history.dayHeader`), `HistoryEventRow` (`Button`
  → edit sheet, label `.foregroundStyle(.primary)`, `history.row.editHint`; Task 2 keeps the
  existing `eventContextMenu` so the context-menu tests stay green until Task 3),
  `HistoryEmptyView` (`ContentUnavailableView` + bordered "Log a Drink" → `\.addDrink`).
- `HistoryListQueryView`: `List(.insetGrouped)`, one `Section` per `DaySection`,
  `brandRowBackground()` on the day sections, last header-less section with the loading row,
  `LoadMoreSentinel` / end-of-list footer (`listRowBackground(Color.clear)`),
  `.listSectionSpacing(.compact)`, `brandListBackground()`; the three refresh triggers kept.
- `HistoryView`: `ToolbarItem(.principal)` segmented picker with `.fixedSize()`; `VStack`,
  directional slide transition, `edge(forEntering:)`, `shouldAnimate(reduceMotion:)`,
  `reduceMotion` and the DEBUG `extendListWindow` logger removed; `.scrollEdgeEffectStyle(.soft,
  for: .top)` on both modes. The old calendar `ScrollView` keeps its grey background until Task 5.
- `HistoryViewModel.sectionTitle(for:todayStart:yesterdayStart:calendar:)` internal; format
  `.weekday(.wide).day().month(.abbreviated)` plus `.year()` outside the current year.
- Search results and the old calendar day detail switched to `HistoryDayHeader` /
  `HistoryEventRow` (both rebuilt in Tasks 4 / 5).
- Deleted (`XcodeRM`): `HistoryFlatRow`, `HistoryEventCardRow`, `HistoryListRowChrome`,
  `HistoryDayHeaderRow`, `EventRowButton`, `HistoryViewTests` (only the four removed
  `edge` / `shouldAnimate` tests).
- Copy (`Localizable.xcstrings`): `history.emptyTitle` "No Drinks Yet",
  `history.emptyDescription` "Drinks you log appear here.", new `history.logADrink`, new
  `history.dayHeader.total …`. `StringCatalogEdit` (MCP) requires the
  `xcode-integration:translation` skill, which is not installed here, so the catalog was edited
  as text keeping Xcode's key order (verified with `git diff`).
- Test hook: `-dp_uitest_dataset empty` (profile, no events) in `UITestSeed`.
- UI tests: new `HistoryDaySectionsUITests` (4). Helpers: `tapSegment` now
  `app.navigationBars.segmentedControls`; `todayHeader` (identifier `history.dayHeader`, label
  begins with "Today") replaces `staticTexts["Today"]`; "No drinks logged" → "No Drinks Yet".
  `daySections_todayYesterdayAndOlderDay_getDistinctTitles` and
  `daySections_clockCrossesMidnight_relabelsTheDayThatWasToday` updated to the new format.
- RED: `HistoryDaySectionsUITests` 4 / 4 failed (no header, picker not in the bar, old empty
  copy); title tests did not compile (`sectionTitle` private, no `calendar:`). GREEN:
  `HistoryDaySectionsUITests` 4 / 4.

- **Owner decision (2026-11-21, during Task 2):** "Walić fullsuite. Przetestuj tylko wprowadzone
  zmiany." The Task 7 full suite (plan 0040 checkpoint) is replaced by scoped runs of the changed
  classes only.
- Scoped run (Task 2 Step 4: `HistoryInteractionUITests` all extensions,
  `HistoryUnitDisplayUITests`, `HistoryDynamicTypeUITests`, `WrongRowContextMenuTargetUITests`,
  `HistoryViewModelTests`): 56 / 63. Failures: the 5 pre-existing `riskColor_*` (Task 1 note) and
  `HistoryInteractionUITests.test_editCustomNameAndNotes_persist` /
  `test_editCategoryChange_persists`, the two edit tests with their own open-questions entry
  ("History edit UI tests fail on their own", deterministic on 2026-11-13). Not waived; reported.
- Previews (`RenderPreview`): History "With data" Light — sections, header "Today · 2 drinks ·
  4.2 std" on one line, Frost tint, picker in the bar. Row labels rendered in the accent:
  `.foregroundStyle(.primary)` resolves to the button tint inside a List; changed to
  `Color.primary` (Dark row preview: white labels). Header AX5: title and total stack, no
  truncation. The HistoryView preview later failed to compile its design-time thunk ("ambiguous
  use of '__designTimeSelection'", preview tooling); the app target builds clean.
