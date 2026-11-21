# 0045 — Port step 5: History

**Status**: in-progress
**Size**: medium-large
**Created**: 2026-11-21
**Frozen**: 2026-11-21
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 5
**Branch**: `port/0045-history` (from `ui-revamp` at `699c9d6`; `main` has not moved, `c1b4bec`
is already merged)

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** History becomes a system screen: an inset-grouped `List` with one `Section` per day
and the day total in the header, native swipe and context-menu row actions, native
`.searchable` with scopes, and a `UICalendarView` calendar with risk decorations, all on the
Frost tint.

**Architecture:** `HistoryView` keeps its role (owns the mode, the list window, the edit sheet)
but moves the List/Calendar picker into the navigation bar (`.principal`). The list views stop
flattening days into pseudo-rows: they render `DaySection`s as `Section`s, one row per event.
All new logic (day totals, window alignment, calendar marks) lives in pure, tested helpers in
`Features/History/`; views stay layout. Rows share one row view with the actions, used by the
paginated list, the search results and the calendar day. No Domain calculation, persistence,
service or schema change.

**Tech stack:** SwiftUI `List` (`.insetGrouped`), `Section(content:header:)`,
`listSectionSpacing(.compact)`, `swipeActions(edge:allowsFullSwipe:content:)`, `contextMenu`,
`confirmationDialog`, `searchable(text:placement:prompt:)` with
`.navigationBarDrawer(displayMode: .always)`, `searchScopes(_:activation:_:)`,
`EnvironmentValues.isSearching`, `ContentUnavailableView`, `scrollEdgeEffectStyle(_:for:)`,
`ViewThatFits`; UIKit `UICalendarView`, `UICalendarSelectionSingleDate`,
`UICalendarView.Decoration`, `UIViewRepresentable`; Swift Testing; XCUITest.

**Spec:** plan 0040 ("Decisions carried into the port" History, Visual design, Charts and
motion; step 5 edge cases; "Contradictions" 0038 / 0039 lines; "Accessibility audit policy");
prototype `~/Developer/drinkpulse-native-proto/DrinkPulseNativeProto/DrinkPulseNativeProto/History/`
(`HistoryView.swift`, `HistoryListView.swift`, `HistoryCalendarView.swift`,
`DecoratedCalendar.swift`); FINDINGS "What replaced what" (History, `HistorySearchField`
rows), "Honest trade-offs" 2, 5, 7, rounds 3 / 3b (edge effect), 6 / 6b (row actions, dense
list), 7 (calendar), 9 (tint), 14 (calendar motion), 16 (risk palette, calendar marks
placeholder), 17 (empty state), 21 (bar controls); `VOICE.md` rows for `history.*` and
`action.duplicate`.

## Summary

History today is a `VStack` with a hand-placed segmented picker, a plain `List` with cleared
backgrounds, flattened day-header pseudo-rows, hand-drawn card corners and dividers, plain
`Button` rows with a manual context menu and manual accessibility actions, an inline
`HistorySearchField`, and a hand-built calendar grid inside a glass card. The prototype
replaced all of that with system containers. This step ports it, keeps the app's real data
paths (paginated `@Query`, unpaginated search `@Query`, month `@Query`), and fixes the two data
edge cases plan 0040 names: the partial oldest day and the unconfirmed full-swipe delete.

## Context

- Current files (read 2026-11-21 via Xcode MCP): `HistoryView.swift` (269 lines; `VStack` +
  segmented picker, directional slide transition, `HistorySearchableList`, calendar
  `ScrollView` with chevron month header, `.sheet(item: $editingEvent)`, DEBUG
  `extendListWindow` logger), `HistorySearchableList.swift`, `HistoryListQueryView.swift`
  (plain `List`, `HistoryFlatRow` rows, `LoadMoreSentinel`, `EndOfListFooter`, three-trigger
  row refresh: `modifiedDate`, `scenePhase`, `NSCalendarDayChanged`),
  `HistorySearchResultsQueryView.swift` (app-owned no-results copy because the system
  `ContentUnavailableView.search` failed the audit inside a `List` overlay),
  `HistoryCalendarQueryView.swift`, `Components/HistoryCalendarView.swift` (grid,
  `dpGlassCard`), `HistoryCalendarDayCell.swift`, `HistoryCalendarDayDetail.swift`,
  `HistoryEventCardRow.swift`, `HistoryFlatRow.swift`, `HistoryListRowChrome.swift`,
  `HistoryDayHeaderRow.swift`, `EventRowButton.swift`, `EventRow.swift` (keeps its
  `isAccessibilitySize` layout, plan 0040: Apple-documented switches stay),
  `EventRowStrings.swift`, `EventContextMenu.swift` (Duplicate + confirmed Delete, manual
  `accessibilityActions`, `withMotion`, `drinkLogged`, Health sample removal),
  `HistorySearchField.swift`, `HistorySearchFilter.swift` (customName-only predicate, kept),
  `HistorySearchScope.swift`, `HistorySegment.swift`, `HistoryViewModel.swift`.
- `HistoryViewModel.initialWindowStart` = now − 7 days (not a day boundary): the oldest loaded
  day is partial, so a header total for it would be wrong (plan 0040 step 5 edge case).
- `RiskLevel.from(pct:)`: `< 0.5` safe, `<= 1.0` caution, `> 1` exceeded; `RiskLevel.tone`
  (plan 0042) is the one risk palette. The prototype's 75 % / 100 % marks are placeholders.
- Daily limit for marks today: `HistoryCalendarView.dailyLimit` (profile
  `effectiveLimits(...).effectiveDailyGrams`, 20 g without a profile); grams use the
  display-unit density (`RowUnitContext.density`), compared to physical-gram limits
  (AGENTS.md "Calculations").
- `HistoryViewModel.monthCells`, `DayCell`, `riskColor` are used only by the old grid.
- UI tests on History (all must keep running): `HistoryInteractionUITests` (+ `HitTarget`,
  `DirectionalTransition`, `Pagination`, `LoadingState`, `Helpers`), `HistorySearchUITests`,
  `WrongRowContextMenuTargetUITests`, `ContextMenuDeleteConfirmationUITests`,
  `DuplicateEditPersistenceUITests`, `EditDeleteConfirmationUITests`,
  `EditVolumeIntegrityUITests`, `HistoryDynamicTypeUITests`, `HistoryUnitDisplayUITests`,
  `ReduceMotionHistoryUITests`, `HistoryAccessibilityAuditUITests`,
  `HistorySearchAccessibilityAuditUITests`. Helpers locate the segment by label and calendar
  cells by the custom grid; both change.
- Unit tests touched: `HistoryViewTests` (tests `edge(forEntering:)` / `shouldAnimate`),
  `HistoryViewModelTests` (+ `Pagination`, `DayRollover`), `HistorySearchFilterTests`,
  `EventRowStringsTests`, `RowUnitContextTests`.
- `docs/architecture.md` Navigation section still says History keeps the picker in content and
  search is an inline row "not `.searchable`" (plan 0039). Plan 0040 reverses that (prototype
  round 3); this step rewrites the paragraph.
- Open-questions entries this step closes or updates: "History native swipe-to-delete",
  "Swift 6 isolation warnings in HistorySearchUITests", the History lines of "Accessibility
  audit failures on the old UI", plan 0040 "measure the `List` row-build cost" (device).
- Apple docs checked while drafting (Xcode MCP `DocumentationSearch`, 2026-11-21):
  `swipeActions(edge:allowsFullSwipe:content:)` (first action performs on full swipe; `.tint`
  per button; destructive role red; no statement about VoiceOver custom actions);
  `swipeActionsContainer()` ("`List` provides this coordination automatically");
  `searchScopes(_:activation:_:)` (`.onSearchPresentation`; scopes disappear on cancel);
  "Managing search interface activation" (`isSearching` only readable inside the searchable
  view's hierarchy; `dismissSearch` clears the text); `UICalendarView` ("Display decorations",
  `reloadDecorations(forDateComponents:animated:)`, `setVisibleDateComponents(_:animated:)`
  must stay inside `availableDateRange`, `calendarView(_:didChangeVisibleDateComponentsFrom:)`,
  custom decoration views "may not have any interactions").

## Decisions (this plan)

- **D0045-1 — Picker in the bar, no slide.** `ToolbarItem(placement: .principal)` holds the
  segmented `Picker` (`history.segment.picker`, `.fixedSize()`), title inline, `+` stays
  (`AddDrinkToolbarItem`). The mode switch is a plain state change (prototype): the directional
  slide transition, `HistoryView.edge(forEntering:)`, `shouldAnimate(reduceMotion:)` and their
  unit tests are removed; the `DirectionalTransition` UI tests keep their end-state assertions
  through the new helper. Bar control → `AuditBarControls` key if the AX5 audit flags it
  (round 21).
- **D0045-2 — One `Section` per day, total in the header.** `HistoryDayHeader` shows the day
  title leading and "N drinks · total" trailing in a `ViewThatFits` (`HStack` → `VStack`), no
  footer, `.listSectionSpacing(.compact)`. Title: keep "Today" / "Yesterday"; other days
  `.weekday(.wide).day().month(.abbreviated)`, plus `.year()` when the day is not in the
  current year (prototype dropped the year; History spans years — owner accepted 2026-11-21). N =
  sum of `quantity` (portions), inflected (`^[\(n) drink](inflect: true)`); total = mode-mass
  in the user's alcohol unit (`AlcoholUnit.formattedValue` + `unitLabel`, as the calendar day
  detail does today). Header ink `Color.dpSecondaryText` (open question "Contrast-safe
  secondary ink": the system grey fails on the tint).
- **D0045-3 — The list window starts on a day boundary.** `initialWindowStart` = start of day
  of (now − 7 days); `extendedWindowStart` steps 7 days from a start of day. Every loaded day is
  then complete, so no header total is partial. Rejected: loading the oldest day separately
  (a second query for one header).
- **D0045-4 — Row actions (round 6).** One row view `HistoryEventRow` for list, search and
  calendar: `Button` that opens the edit sheet, label `EventRow`; leading swipe "Log Again"
  (`repeat`, `Brand.accent` tint, `allowsFullSwipe: false`); trailing swipe "Delete"
  (`role: .destructive`, full swipe, no confirmation); context menu "Log Again", then Delete in
  its own `Section` (confirmed, existing dialog and `confirmContextDeleteButton` identifier).
  All mutations through `withMotion`; Log Again calls `drinkLogged` (plan 0044). Delete always
  removes the Apple Health sample (`HealthWriteHooks.remove`, plan 0036). The manual
  `accessibilityActions` stay unless a VoiceOver check on the simulator shows the swipe
  actions as custom actions (docs are silent); never both sets.
- **D0045-5 — No undo on full-swipe delete (owner accepted 2026-11-21).** Mail / Notes
  pattern, as the prototype. An undo would have to re-create the Health sample (new sample id,
  plan 0036 "write fresh"), so the store and Health could diverge if the undo itself fails.
  Alternative if the owner wants a safety net: `allowsFullSwipe: false` on Delete (two taps,
  still no dialog).
- **D0045-6 — Edit stays a sheet in this step (owner accepted 2026-11-21).** The prototype pushes Edit with
  `NavigationLink(value:)`; that changes Edit's toolbar roles and belongs to step 7 (Add / Edit
  Drink). Rows therefore stay `Button`s; label colour reset with `.foregroundStyle(.primary)`
  on the label (Step 0 docs check on `Button` in `List`), no `.buttonStyle(.plain)` /
  `contentShape` workaround.
- **D0045-7 — Native search on the list mode only.** `.searchable(text:placement:
  .navigationBarDrawer(displayMode: .always), prompt:)` + `.searchScopes($scope, activation:
  .onSearchPresentation)` on the list container; the calendar mode has no search (as today).
  `HistorySearchFilter` and its customName-only predicate stay (plan 0039 behaviour; the
  prototype also matched notes — not ported). A child view reads `isSearching` and resets
  `scope` to `.all` when search ends. Empty search: system `ContentUnavailableView.search(text:)`
  first; if the audit flags it, keep the existing app-owned copy (record which in
  `execution.md`). `HistorySearchField` is deleted.
- **D0045-8 — Calendar = `DecoratedCalendar` (round 7).** `UIViewRepresentable` over
  `UICalendarView`, single-date selection, future days not selectable, `availableDateRange` =
  start of the earliest event's month (or this month) … now, two-way `visibleMonth`. Marks use
  the app's `RiskLevel` (not 75 / 100 %): safe → `.default(color: tone, size: .small)`,
  caution → `.default(color: tone, size: .medium)`, exceeded →
  `.image(UIImage(systemName: "exclamationmark.circle.fill"), color: tone, size: .large)`
  (shape + size + colour, HIG Inclusive color); no drinks → no mark. Colours from
  `RiskLevel.tone` via `UIColor(_:)` (asset colours, no main-actor provider). The month query
  follows `visibleMonth`. Below it a `Section` for the selected day with the same
  `HistoryDayHeader` and `HistoryEventRow`s; empty day → `Label` "Alcohol-free day"
  (`moon.stars`). "Today" button (`.topBarLeading`) only when off today. Day change animates
  with `.snappy` unless Reduce Motion (`DPMotion`). The chevron header and the custom grid are
  deleted.
- **D0045-9 — Tint and edge effect.** Both modes use `brandListBackground()` +
  `brandRowBackground()` (plan 0043 helpers) and `.scrollEdgeEffectStyle(.soft, for: .top)`
  (`.hard` leaves a band on iOS 27.2, round 3b). Removes `.background(systemGroupedBackground)`
  and `historyListRowChrome`.
- **D0045-10 — Empty History.** `ContentUnavailableView` "No Drinks Yet" / "Drinks you log
  appear here." with a bordered "Log a Drink" button calling `\.addDrink` (round 17). Owner
  accepted folding the copy into this step (2026-11-21). History
  copy rows of `VOICE.md` that this step's screens show are applied here (folded copy pass,
  plan 0040 step 9): `history.emptyTitle`, `history.emptyDescription`, new `history.logADrink`,
  `action.duplicate` → value "Log Again" (key kept), `history.calendar.soberDayPlaceholder` →
  "Alcohol-free day", `history.calendar.soberSuffix` → "alcohol-free day".
- **D0045-11 — Pagination kept, DEBUG logger removed.** `LoadMoreSentinel` and the end-of-list
  footer move into a last `Section` with no header (row background clear); the 7-day page
  stays; the DEBUG `extendListWindow` `Logger` is removed (plan 0038 step 8). Row-build cost is
  a device check (plan 0038 step 7), not a gate.

## Scope

### In
- `HistoryView` bar picker, list / search / calendar containers, `HistoryDayHeader`,
  `HistoryDayTotal`, `HistoryEventRow`, `DecoratedCalendar`, `HistoryCalendarMarks`, window
  alignment, empty state, tint, edge effect, History copy rows, deletions listed per task.
- UI tests for every changed flow; audit classes for History and History search green on the
  new UI except named exemptions; `docs/architecture.md` Navigation + History container.
- Full suite at the end (plan 0040: steps 5, 8, 11).

### Out
- Edit as a pushed screen, Edit "Log Again", sheet tint (step 7); Today / Insights (step 6);
  remaining copy (step 9); deleting `dpSecondaryText` (step 11).
- Search in notes (not in the app today).

## Global constraints

- **Xcode MCP for everything it covers** (main checkout, no worktree; memory "Xcode MCP
  first"). Session start: `XcodeListWorkspaces` → entry whose `workspacePath` ends with
  `drinkpulse.xcodeproj` → pass its `workspaceIdentifier` to every call that accepts it;
  `XcodeListRunDestinations` before every test call (iPhone 18 Pro, iOS 27.2 simulator; never
  the physical device).
  - Build: `BuildProject`, then `GetBuildLog` — zero warnings.
  - Tests: `RunSomeTests` with named classes, at most about 10 classes per call (plan 0044's
    22-class call returned an incomplete bundle); `GetTestList` to confirm new tests exist and
    ran. `RunAllTests` only in Task 7.
  - Code: `XcodeRead`, `XcodeGrep`, `XcodeGlob`, `XcodeUpdate` / `XcodeWrite`, `XcodeRM`,
    `XcodeRefreshCodeIssuesInFile` after each edited file. Visual: `RenderPreview` (Light,
    Dark, AX5). Simulator probing: `DeviceInteraction*`.
  - **No CLI `xcodebuild` / `xcrun` without the owner's approval**, even for a named MCP gap.
    Known gap: no coverage report in MCP → ask the owner (Task 7).
- **Apple docs first:** `DocumentationSearch` (API and HIG) before each API use or design
  call; developer.apple.com only if MCP lacks the page. Record query, symbol and availability
  in `execution.md`. Each task's Step 0 lists its lookups.
- Swift 6 strict concurrency, zero warnings; files under 300 lines; previews for every view
  (Light, Dark, AX5, empty) with in-memory data.
- No schema change. If one appears, stop (new schema version, AGENTS.md).
- No PII in logs: save failures log the error category only (`Logger` subsystem
  `com.drinkpulse.app`); no `try?` without a comment.
- New unit tests: Swift Testing, `drinkpulseTests/Features/History/`. UI tests in
  `drinkpulseUITests/Features/History/`; system UI (search Cancel, calendar cells) never
  matched by a localized label (simulator locale is Polish) — use identifiers, element types
  or position.

## Review focus

1. **Oldest loaded day is partial** — header total must equal the whole day. Pinned in Task 1
   (window alignment tests) and Task 2 (UI test on the `paginationstress` dataset: the oldest
   visible day's header count matches its seeded count, 3).
2. **Full-swipe Delete of a drink written to Apple Health** — sample removed, no dialog, row
   gone. Pinned in Task 3 (`HealthWriteHooksUITests`-style UI test or the existing hook test
   extended).
3. **Swipe on a row while search is active** — same actions on the results; the deleted row
   leaves the results. Pinned in Task 4.
4. **Calendar on a month with no drinks / paging past the earliest month** — no marks, no
   crash, `setVisibleDateComponents` stays inside `availableDateRange` ("Today" from an old
   month). Pinned in Task 5 (marks unit test for an empty month; UI test pages back and taps
   "Today").
5. **Midnight rollover with History open** — "Today" / "Yesterday" titles and totals refresh
   (existing `NSCalendarDayChanged` trigger kept). Pinned by `HistoryViewModelTests+DayRollover`
   staying green in Task 1 and the trigger kept in Task 2.

---

### Task 1: Day totals, window alignment, marks (pure logic)

**Files:**
- Create: `drinkpulse/Features/History/HistoryDayTotal.swift`,
  `drinkpulse/Features/History/HistoryCalendarMarks.swift`
- Modify: `drinkpulse/Features/History/HistoryViewModel.swift` (window functions; delete
  `monthCells`, `DayCell`, `riskColor` once Task 5 removes their last caller — do it there)
- Test: `drinkpulseTests/Features/History/HistoryDayTotalTests.swift`,
  `HistoryCalendarMarksTests.swift`; update `HistoryViewModelTests+Pagination.swift`

**Interfaces:**
- Produces:
  - `struct HistoryDayTotal: Equatable { let drinkCount: Int; let massGrams: Double;
    init(events: [ConsumptionEvent], density: Double) }` — `drinkCount` = Σ `quantity`,
    `massGrams` = Σ `alcoholGrams(density:)`.
  - `enum HistoryCalendarMarks { static func levels(events: [ConsumptionEvent],
    dailyLimitGrams: Double, density: Double, calendar: Calendar) -> [Date: RiskLevel] }` —
    key = start of day; days with 0 g absent; `dailyLimitGrams <= 0` → empty.
  - `HistoryViewModel.initialWindowStart(from:calendar:)` and
    `extendedWindowStart(from:calendar:)` return start-of-day dates (D0045-3); signatures
    unchanged.

- [ ] **Step 0: Docs** — `DocumentationSearch`: `Calendar.startOfDay(for:)`,
  `Calendar.date(byAdding:value:to:wrappingComponents:)` (DST behaviour).
- [ ] **Step 1: Write the failing tests**
  - `test_dayTotal_countsPortions_notLogs` (one event `quantity` 2 + one `quantity` 1 → 3)
  - `test_dayTotal_usesGivenDensity` (500 ml × 5 % at 0.8 → 20.0 g; at 0.789 → 19.725 g)
  - `test_dayTotal_isZero_forNoEvents`
  - `test_marks_mapLevels_atBoundaries` (limit 20 g, density 0.789: 9.9 g safe, 10 g caution
    (pct 0.5), 20 g caution (pct 1.0), 20.1 g exceeded)
  - `test_marks_omitDaysWithoutAlcohol` and `test_marks_emptyMonth_isEmpty`
  - `test_marks_zeroLimit_isEmpty`
  - `test_marks_sumEventsOfOneDay` (two events same day → one key)
  - Pagination: `test_initialWindowStart_isStartOfDay`,
    `test_extendedWindowStart_isStartOfDay_sevenDaysEarlier`,
    `test_windowStart_acrossDSTChange_isStartOfDay` (Europe/Warsaw, last Sunday of March)
- [ ] **Step 2: Run** `HistoryDayTotalTests`, `HistoryCalendarMarksTests`,
  `HistoryViewModelTests` via `RunSomeTests` — FAIL (undefined / old window).
- [ ] **Step 3: Implement**; fix any existing pagination test that encoded the old
  "now − 7 days" value (note each in `execution.md`).
- [ ] **Step 4: Run** the same classes — PASS (Review focus 5: `DayRollover` green).
- [ ] **Step 5: Commit** `[plan-0045] day totals, day-aligned list window, calendar marks`.

### Task 2: List of day sections, bar picker, tint

**Files:**
- Create: `drinkpulse/Features/History/Components/HistoryDayHeader.swift`,
  `drinkpulse/Features/History/Components/HistoryEventRow.swift` (tap → edit only; actions in
  Task 3), `drinkpulse/Features/History/Components/HistoryEmptyView.swift`
- Modify: `HistoryView.swift` (toolbar `.principal` picker, no `VStack` / transition, no DEBUG
  logger, empty state), `HistoryListQueryView.swift` (`List(.insetGrouped)` of `Section`s,
  `DaySection` state instead of `HistoryFlatRow`, refresh triggers kept, sentinel section),
  `Localizable.xcstrings` (D0045-10 keys), `HistoryViewModel.swift` (`sectionTitle` per
  D0045-2)
- Delete (`XcodeRM`): `HistoryFlatRow.swift`, `HistoryEventCardRow.swift`,
  `HistoryListRowChrome.swift`, `HistoryDayHeaderRow.swift`, `EventRowButton.swift`
- Tests: delete the two `edge` / two `shouldAnimate` tests in `HistoryViewTests` (file removed
  if empty); `HistoryViewModelTests` title tests for the new format;
  `HistoryInteractionUITests+Helpers.swift` (`tapSegment` via
  `app.navigationBars.segmentedControls.buttons[label]` — app-owned labels "List" /
  "Calendar"); new `drinkpulseUITests/Features/History/HistoryDaySectionsUITests.swift`

**Interfaces:**
- Consumes: `HistoryDayTotal` (Task 1), `RowUnitContext`, `withMotion`, `AddDrinkAction`.
- Produces:
  - `struct HistoryDayHeader: View { let title: String; let total: HistoryDayTotal;
    let unitContext: RowUnitContext }` — `accessibilityElement(children: .combine)`,
    identifier `history.dayHeader`.
  - `struct HistoryEventRow: View { let event: ConsumptionEvent; let unitContext:
    RowUnitContext; let onEdit: (ConsumptionEvent) -> Void }` — keeps
    `history.row.editHint`.
  - `HistoryViewModel.sectionTitle(for:todayStart:yesterdayStart:calendar:)` (internal,
    tested).

- [ ] **Step 0: Docs** — `DocumentationSearch`: `List` + `InsetGroupedListStyle`,
  `Section(content:header:)`, `listSectionSpacing(_:)`, `ViewThatFits`, `Button` inside `List`
  (label styling, D0045-6), `ToolbarItemPlacement.principal`, `navigationBarTitleDisplayMode`,
  `ContentUnavailableView(label:description:actions:)`, `ButtonStyle.bordered`,
  `scrollContentBackground(_:)`, `containerBackground(_:for:)`, `listRowBackground(_:)`,
  `scrollEdgeEffectStyle(_:for:)`, `Text` inflection (`inflect: true`); HIG Lists and tables,
  Segmented controls ("in a toolbar"), Search fields.
- [ ] **Step 1: Write the failing UI tests** (`HistoryDaySectionsUITests`, dataset
  `paginationstress` unless noted)
  - `test_dayHeader_showsDrinkCountAndTotal` — today's header contains "3 drinks".
  - `test_oldestLoadedDay_headerCountsWholeDay` — scroll to the last day before the sentinel;
    its header contains "3 drinks" (Review focus 1).
  - `test_segmentPicker_isInNavigationBar` — `navigationBars["History"].segmentedControls`
    exists with "List" and "Calendar".
  - `test_emptyHistory_logADrink_opensAddDrink` (no dataset, empty store hook) — "No Drinks
    Yet" shown; tap "Log a Drink" → `navigationBars["Add Drink"]`.
- [ ] **Step 2: Run** `HistoryDaySectionsUITests` — FAIL.
- [ ] **Step 3: Implement**; `XcodeGrep` `HistoryFlatRow|historyListRowChrome|EventRowButton|
  flattenedForHistoryList` → no hits; `BuildProject` clean; `RenderPreview` HistoryView
  (Light, Dark, AX5, empty): sections, header on one line at default size, stacked at AX5.
- [ ] **Step 4: Run** (`RunSomeTests`) `HistoryDaySectionsUITests`, `HistoryInteractionUITests`
  (all extensions), `HistoryUnitDisplayUITests`, `HistoryDynamicTypeUITests`,
  `WrongRowContextMenuTargetUITests`, `HistoryViewModelTests` — PASS. The two edit tests with
  their own open-questions entry are reported as such if they fail, not waived silently.
- [ ] **Step 5: Commit** `[plan-0045] History list as day sections with totals`.

### Task 3: Row actions

**Files:**
- Modify: `Components/HistoryEventRow.swift` (swipe actions, context menu),
  `Components/EventContextMenu.swift` (becomes the shared action set: Log Again + confirmed
  Delete for the menu, plus `logAgain()` / `delete()` used by the swipes; or split into
  `HistoryRowActions.swift` if over 150 lines)
- Tests: update `HistoryInteractionUITests` (`test_contextMenuDuplicate_addsEvent` →
  `test_contextMenuLogAgain_addsEvent`, menu label "Log Again"),
  `WrongRowContextMenuTargetUITests`, `DuplicateEditPersistenceUITests` (label);
  new `drinkpulseUITests/Features/History/HistorySwipeActionsUITests.swift`

**Interfaces:**
- Consumes: `withMotion(reduceMotion:_:)`, `DrinkLoggedAction`, `HealthWriteHooks.remove`,
  `RecordDeduplicator.ensureUniqueIdentity`, `ConsumptionEvent.duplicated()`.
- Produces: swipe buttons with identifiers `history.row.logAgain`, `history.row.delete`
  (stable keys for tests).

- [ ] **Step 0: Docs** — `DocumentationSearch`: `swipeActions(edge:allowsFullSwipe:content:)`,
  `ButtonRole.destructive`, `tint(_:)`, `contextMenu(menuItems:)`, `confirmationDialog`,
  `accessibilityActions(_:)`; HIG Context menus, Lists and tables (swipe), Playing haptics.
  VoiceOver probe on the simulator (`DeviceInteraction*` or Accessibility Inspector via MCP if
  available): are swipe actions custom actions? Record the answer; apply D0045-4.
- [ ] **Step 1: Write the failing UI tests** (`HistorySwipeActionsUITests`)
  - `test_leadingSwipe_logAgain_addsRowNow` — swipe right on the 500 ml row, tap
    `history.row.logAgain` → today's header count +1.
  - `test_leadingFullSwipe_doesNotLogAgain` — long swipe right → count unchanged.
  - `test_trailingFullSwipe_deletesWithoutDialog` — long swipe left → row gone, no
    `confirmContextDeleteButton`.
  - `test_trailingSwipe_deleteRemovesHealthSample` — reuse the `HealthWriteHooksUITests`
    fake-service launch arguments; delete by swipe → the fake reports one removal (Review
    focus 2).
  - `test_contextMenuDelete_stillAsksForConfirmation` (keeps the 0040 rule).
- [ ] **Step 2: Run** `HistorySwipeActionsUITests` — FAIL.
- [ ] **Step 3: Implement** (D0045-4, D0045-5 as decided by the owner).
- [ ] **Step 4: Run** (`RunSomeTests`) `HistorySwipeActionsUITests`, `HistoryInteractionUITests`,
  `WrongRowContextMenuTargetUITests`, `ContextMenuDeleteConfirmationUITests`,
  `DuplicateEditPersistenceUITests`, `ReduceMotionHistoryUITests`, `HealthWriteHooksUITests`,
  `LogFeedbackTests` — PASS.
- [ ] **Step 5: Commit** `[plan-0045] native swipe and context-menu row actions`.

### Task 4: Native search

**Files:**
- Modify: `HistorySearchableList.swift` (`.searchable` + `.searchScopes` on the list container,
  child view reading `isSearching`), `HistorySearchResultsQueryView.swift` (`Section`s with
  `HistoryDayHeader` + `HistoryEventRow`; empty state per D0045-7),
  `HistorySearchScope.swift` (labels), `Localizable.xcstrings` (`history.search.prompt` value
  "Search by Name" if the current one names the inline field)
- Delete: `Components/HistorySearchField.swift`
- Tests: rewrite `HistorySearchUITests` (`@MainActor` class — closes the Swift 6 warning
  entry): field = `app.searchFields.firstMatch`; scopes =
  `app.segmentedControls` under the field by position; Cancel by element type / position,
  never by label. Keep the seven behaviours (`filtersListToMatchingName`,
  `findsEntryOlderThanListWindow`, `returnKey_dismissesKeyboard_andKeepsQuery`,
  `clearButton_restoresFullList`, `unnamedScope_withText_showsExplanation`,
  `cancel_resetsScopeAndShowsFullList`, `segmentSwitch_…_hidesSearchInCalendar`), add
  `test_swipeDelete_onSearchResult_removesIt` (Review focus 3).

**Interfaces:**
- Consumes: `HistorySearchFilter` (unchanged), `HistoryEventRow`, `HistoryDayHeader`,
  `HistoryDayTotal`.

- [ ] **Step 0: Docs** — `DocumentationSearch`: `searchable(text:placement:prompt:)`,
  `SearchFieldPlacement.navigationBarDrawer(displayMode:)`, `searchScopes(_:activation:_:)`,
  `SearchScopeActivation.onSearchPresentation`, `EnvironmentValues.isSearching`,
  `ContentUnavailableView.search(text:)`; HIG Search fields (scope bar, "inline field above
  the list").
- [ ] **Step 1: Rewrite the UI tests** — run `HistorySearchUITests` — FAIL (no search field).
- [ ] **Step 2: Implement**; `XcodeGrep` `HistorySearchField` → no hits; `BuildProject` clean;
  `RenderPreview` idle and active search (Light, Dark, AX5).
- [ ] **Step 3: Run** (`RunSomeTests`) `HistorySearchUITests`, `HistorySearchFilterTests`,
  `HistorySearchAccessibilityAuditUITests` — PASS, or only bar-control findings (the native
  scope bar, round 21 case 1) which go to `AuditBarControls` with their element keys and an
  `execution.md` line.
- [ ] **Step 4: Commit** `[plan-0045] native searchable History with scopes`.

### Task 5: `UICalendarView` calendar

**Files:**
- Create: `drinkpulse/Features/History/Components/DecoratedCalendar.swift`
  (`UIViewRepresentable` + `Coordinator`), `drinkpulse/Features/History/HistoryCalendarList.swift`
  (the calendar mode `List`: calendar section + day section, "Today" toolbar item)
- Modify: `HistoryCalendarQueryView.swift` (query by `visibleMonth`, pass marks),
  `HistoryView.swift` (calendar mode, `visibleMonth` / `selectedDay` state, drop
  `monthShown` navigation), `HistoryViewModel.swift` (delete `monthCells`, `DayCell`,
  `riskColor` and their tests)
- Delete: `Components/HistoryCalendarView.swift`, `HistoryCalendarDayCell.swift`,
  `HistoryCalendarDayDetail.swift`
- Tests: `HistoryInteractionUITests` calendar tests and `+Helpers` (`calendarDayCell` inside
  the element with identifier `history.calendar`, matched by day number text / position —
  probe the tree first, Step 1); new `test_calendar_todayButton_returnsFromEarlierMonth`
  (Review focus 4).

**Interfaces:**
- Consumes: `HistoryCalendarMarks.levels` (Task 1), `RiskLevel.tone`, `HistoryEventRow`,
  `HistoryDayHeader`, `DPMotion.animation(_:reduceMotion:)`.
- Produces: `struct DecoratedCalendar: UIViewRepresentable { @Binding var selection: Date;
  @Binding var visibleMonth: Date; let marks: [Date: RiskLevel]; let availableRange:
  DateInterval }` — `.accessibilityIdentifier("history.calendar")`; reloads only changed days.

- [ ] **Step 0: Docs** — `DocumentationSearch`: `UICalendarView` (calendar / locale setup,
  `availableDateRange`, `visibleDateComponents`, `setVisibleDateComponents(_:animated:)`,
  `wantsDateDecorations`, `tintColor`), `UICalendarViewDelegate` (`decorationFor`,
  `didChangeVisibleDateComponentsFrom`), `UICalendarSelectionSingleDate` +
  `canSelectDate`, `UICalendarView.Decoration` (`default`, `image`),
  `UIViewRepresentable.sizeThatFits(_:uiView:context:)`, `UIColor(_:)` from `Color`,
  `UIView.systemLayoutSizeFitting`; HIG Color › Inclusive color.
- [ ] **Step 1: Probe** — build a first `DecoratedCalendar` in the calendar mode, run one UI
  test that prints `app.debugDescription` for the `history.calendar` element; record in
  `execution.md` how day cells, selection and month paging appear (types, labels, values) and
  whether decorations are spoken. Write the helpers from that, locale-independent.
- [ ] **Step 2: Update the failing UI tests** — `test_tapCalendarDay_revealsDayDetail`,
  `test_calendar_selectsTodayInitially_andNeverDeselects`,
  `test_segmentSwitch_togglesListAndCalendar`, new Today-button test — run — FAIL where the
  behaviour is missing.
- [ ] **Step 3: Implement** D0045-8; `XcodeGrep` `monthCells|DayCell|riskColor|
  HistoryCalendarDayCell` → no hits; `BuildProject` clean; `RenderPreview` calendar (Light,
  Dark, AX5, off today, empty month).
- [ ] **Step 4: Run** (`RunSomeTests`) `HistoryInteractionUITests`, `HistoryCalendarMarksTests`,
  `HistoryViewModelTests`, `ReduceMotionHistoryUITests` — PASS.
- [ ] **Step 5: Commit** `[plan-0045] UICalendarView calendar with risk decorations`.

### Task 6: Audit classes on the new UI

**Files:**
- Modify: `drinkpulseUITests/Features/History/HistoryAccessibilityAuditUITests.swift`,
  `HistorySearchAccessibilityAuditUITests.swift`, `Features/Shell/AccessibilityAuditBarControls.swift`
  (new keys only if reported), `AccessibilityAuditUITests` history calls if they still use
  old-UI helpers

- [ ] **Step 0: Docs** — XCTest `performAccessibilityAudit(for:_:)`,
  `XCUIAccessibilityAuditType`; UIKit `UILargeContentViewerInteraction`.
- [ ] **Step 1: Run** both audit classes (all variants) plus a calendar-mode variant added to
  `HistoryAccessibilityAuditUITests` (`test_historyCalendar_standard_hasNoAuditIssues`,
  `_ax5_`). Record every finding in `execution.md`.
- [ ] **Step 2: Fix** content findings at the source (contrast → `dpSecondaryText` or
  `Brand` ink; Dynamic Type → layout); exempt only bar controls (picker, scope bar, Today,
  `+`) per round 21, by identifier where one exists. A content finding is never exempted.
- [ ] **Step 3: Run** again — green. Remove the History lines from open-questions "Accessibility
  audit failures on the old UI".
- [ ] **Step 4: Commit** `[plan-0045] History audit classes green on the native UI`.

### Task 7: Gates, docs, close

**Files:**
- Modify: `docs/architecture.md` (Navigation: picker in the bar, native `.searchable` drawer,
  edit sheet until step 7; History container: inset-grouped sections, day-aligned window,
  row actions, `DecoratedCalendar` as the allowed UIKit wrapper), `README.md` only if it
  describes History (`XcodeGrep` first), `docs/plans/0045-history/execution.md`,
  `retrospective.md`, `docs/plans/INDEX.md`, `docs/DEVLOG.md`,
  `.claude/context/current-focus.md`, `.claude/context/open-questions.md`

- [ ] **Step 1: Build** zero warnings (`BuildProject`, `GetBuildLog`).
- [ ] **Step 2: Full suite** — `RunAllTests` (plan 0040: end of step 5). If MCP returns an
  incomplete bundle, re-run in batches of about 10 classes with `RunSomeTests`; record which.
  Expected: green except open-questions entries named by test (record each).
- [ ] **Step 3: Coverage** — new History helpers 100 %, view models ≥ 90 %. MCP has no coverage
  report: ask the owner before the AGENTS.md CLI coverage command; record the answer.
- [ ] **Step 4: File size + privacy** — AGENTS.md `find` command; no new network, no PII in logs.
- [ ] **Step 5: Docs close-out** — execution.md (doc sources per task), retrospective, INDEX
  (completed), DEVLOG, current-focus (next: step 6 Today / Insights, plan 0046),
  open-questions (close "History native swipe-to-delete", "Swift 6 isolation warnings in
  HistorySearchUITests", History audit lines; add device checks below and any new item);
  commit `[plan-0045] docs: close plan`.
- [ ] **Step 6:** `git switch ui-revamp && git merge --no-ff port/0045-history`; ask the owner
  about push.

## Device check (owner)

- Swipe Log Again / Delete feel, full-swipe Delete, context menu Log Again (one haptic) and
  Delete dialog; VoiceOver: row actions (swipe as custom actions or the manual ones, never
  doubled), day headers read date and total.
- Calendar: tapping days, month paging, "Today", decorations in Light / Dark, VoiceOver on
  decorated days (docs silent), Reduce Motion on day change.
- Search: drawer under the picker, scopes on focus, `.soft` edge effect while scrolled and at
  rest.
- Row-build cost: scroll through many loaded pages on the device; note hitches (plan 0038
  step 7, plan 0040 open question).

## Open questions

- [x] D0045-2 (owner, 2026-11-21): year only for days outside the current year.
- [x] D0045-5 (owner, 2026-11-21): full-swipe Delete, no undo.
- [x] D0045-6 (owner, 2026-11-21): Edit stays a sheet until step 7.
- [x] D0045-10 (owner, 2026-11-21): History copy rows of `VOICE.md` applied in this step.

## Tests required

New: `HistoryDayTotalTests`, `HistoryCalendarMarksTests`, window-alignment tests (Swift
Testing); `HistoryDaySectionsUITests`, `HistorySwipeActionsUITests`, calendar Today-button and
search swipe tests. Updated: History interaction, search, context-menu, duplicate, unit
display, dynamic type, reduce motion UI tests; History and History search audit classes plus a
calendar-mode audit. Removed with their code: `HistoryView.edge` / `shouldAnimate` tests,
`monthCells` / `riskColor` tests. Gate: full suite at the end of this step.
