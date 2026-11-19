# Execution log — plan-0039

## 2026-11-19

- Plan frozen (status `in-progress`, `Frozen: 2026-11-19`); `INDEX.md` updated
  (row 0039 → in-progress, next number → 0040).
- Executor: inline (superpowers:executing-plans) on branch
  `plan-0039-history-search` in the main checkout, so Xcode MCP builds and
  tests the branch directly.
- Ruling: Named/Unnamed treat `customName == ""` as unnamed (plan Review
  Focus 1), although the spec text says `customName != nil` / `== nil`. The
  spec's intent is "has a name to match"; an imported empty string has none.

### Task 1 — `HistorySearchScope` + `HistorySearchFilter`

- Apple sources (Xcode MCP `DocumentationSearch`):
  - `StringProtocol.localizedStandardContains(_:)` (Swift) — "locale-aware,
    case and diacritic insensitive"; the recommended method for user-level
    string search.
  - `PredicateExpressions.StringLocalizedStandardContains` (Foundation) —
    the predicate expression `#Predicate` lowers the call to, so it is
    supported inside a `Predicate`.
- Predicate shape that works on iOS 27.2 (in-memory SwiftData store):
  `event.customName?.localizedStandardContains(query) == true`. One
  `#Predicate` literal per `(scope, query.isEmpty)` case; no runtime
  composition.
- RED: build failed with "Cannot find type 'HistorySearchScope' in scope".
  GREEN: `HistorySearchFilterTests` 12/12 (MCP `RunSomeTests`), zero warnings.
- Ruling: added a 12th test, `test_predicate_all_noText_matchesEverything`,
  beyond the plan's 11. The `(.all, empty)` branch had no test, and Task 5
  requires 100% line coverage of `HistorySearchFilter.swift`.
- Scope label keys added to `Localizable.xcstrings` by text insertion, so
  Xcode's own key order and formatting are untouched.

### Task 2 — shared row chrome and day header

- Moved `HistoryDayHeaderRow` to `Components/HistoryDayHeaderRow.swift`
  (with `#Preview`) and `historyListRowChrome(insets:)` plus
  `HistoryListInsets.event` / `.header` to
  `Components/HistoryListRowChrome.swift`. No behavior change.
- MCP `BuildProject`: success, zero warnings.
- MCP `RunSomeTests` `HistoryInteractionUITests`: 13/15 passed. The 2
  failures (`test_editCustomNameAndNotes_persist`,
  `test_editCategoryChange_persists`) are the known iOS 27.2 failures
  waived in `.claude/context/open-questions.md`; unrelated to this move.

### Task 3 — search views wired into `HistoryView`

- Apple sources (Xcode MCP `DocumentationSearch`, SwiftUI):
  - `View.searchable(text:isPresented:placement:prompt:)` (StringProtocol
    prompt overload) — "Marks this view as searchable with programmatic
    presentation of the search field"; `isPresented` controls presented state.
  - `SearchFieldPlacement.navigationBarDrawer(displayMode:)` — field appears
    below the navigation bar title; `.always` keeps it visible on scroll.
  - `View.searchScopes(_:activation:_:)` + `SearchScopeActivation
    .onSearchPresentation` — default iOS behavior shows scopes on text entry
    and hides them on cancel; `.onSearchPresentation` shows them as soon as
    search is presented. Scope tag type must match the binding type.
  - `ContentUnavailableView.search(text:)` — built-in search empty state.
  - Article "Managing search interface activation" (`isSearching`,
    `isPresented`).
- `HistorySearchableList` owns `searchText`, `scope`, `isSearchPresented`;
  on `isSearchPresented == false` it resets `scope = .all`.
- Ruling: `HistorySearchResultsQueryView` refreshes rows on
  `events.map(\.uuid)` (initial) and `events.map(\.modifiedDate)`, plus
  `.NSCalendarDayChanged`. The plan named only `modifiedDate`; a filter change
  can swap the result set while the `modifiedDate` array happens to stay equal,
  and the "Today" header must roll over at midnight like the main list.
- Ruling: `HistorySearchPreviewData` (uses `try!`) and the previews sit inside
  `#if DEBUG`, so no `try!` reaches Release code.
- MCP `BuildProject`: success, zero warnings. MCP `RenderPreview`: results for
  "guin" (one Guinness row under TODAY), Unnamed + text (explanatory empty
  state), searchable list (drawer field "Search by name", full list).
- File size check: no Swift file over 300 lines.

### HALT — owner rejected the search placement (2026-11-19)

- Owner feedback after Task 3: the search field sits at the very top, above
  the List/Calendar segmented picker, and the picker jumps when the segment
  changes. Execution stopped during Task 4 (seed + `HistorySearchUITests`
  written, 5/5 green, NOT committed; regression run cancelled).
- Cause: the segmented `Picker` is a hand-placed row inside the content
  `VStack` (`segmentPickerRow`, `.background(.bar)`), while
  `.searchable(placement: .navigationBarDrawer)` puts the field in the
  navigation bar, above that row. `.searchable` exists only on the List
  branch, so switching to Calendar removes the drawer, the bar shrinks and
  the picker moves.
- Next step pending owner decision: move the picker into the navigation bar
  (`ToolbarItemPlacement.principal`) or another native layout.

### Layout rework after owner review (2026-11-19)

Iterations, each checked on the iPhone 18 Pro iOS 27.2 simulator:
1. Picker in `ToolbarItemPlacement.principal`: replaced the "History" title,
   unlike the other tabs. Rejected by owner.
2. Picker in `ToolbarItemPlacement.subtitle`: picker on a different line than
   the Add button, the search drawer overlapped it, the title moved, and the
   bar reset on Calendar → List. Rejected by owner.
3. Picker as a row above the content, styled like the Insights period
   picker (owner: "use the Insights pattern"). Kept.
4. Search placement probes with `searchable`:
   - default placement → navigation bar drawer (top, above the picker);
   - `DefaultToolbarItem(kind: .search, placement: .bottomBar)` → field
     rendered underneath the tab bar (hidden);
   - `DefaultToolbarItem(kind: .search, placement: .topBarTrailing)` → no
     search element rendered at all.
   None works in this `TabView` layout.
5. Ruling (owner choice): inline search row under the picker, List segment
   only — HIG Search fields: "Place search as an inline field when … you need
   to filter or search within a single view". SwiftUI has no inline
   `searchable` on iOS, so `Components/HistorySearchField.swift` builds it from
   standard controls: `TextField` + magnifier, clear button, Cancel while
   focused, segmented scope picker while focused or while a filter is active.
   Cancel clears the text, resets the scope to All and drops focus.
   `.searchable` / `.searchScopes` are no longer used.
- Apple sources for this step (MCP `DocumentationSearch`):
  `ToolbarItemPlacement.principal`, `.subtitle`,
  `DefaultToolbarItem.init(kind:placement:)`, `ToolbarDefaultItemKind.search`
  ("can be placed in the bottomBar … On iOS, it can also be placed in the top
  bar"), `SearchFieldPlacement.automatic`. HIG: Search fields, Segmented
  controls.
- Owner asked to verify the look on the UI first; UI tests are updated after
  the look is approved. `HistorySearchUITests` currently target the old
  `searchFields` element and must be rewritten.

### Task 4 — UI tests + seed, after owner approval of the look

- Owner approved the inline layout ("looks ok") and asked to finish the plan.
- Seed: `-dp_uitest_dataset search` (`UITestSeed.seedSearchFixture`,
  `seedSearchEvents`): Guinness today 500 ml, Tyskie 200 days ago 500 ml,
  unnamed beer today 330 ml. RED first: `test_search_findsEntryOlderThanListWindow`
  failed before the seed existed (only the default beer was seeded).
- `HistorySearchUITests` rewritten for the inline field: 7 tests (the plan's 5,
  plus `test_returnKey_dismissesKeyboard_andKeepsQuery` and
  `test_segmentSwitch_keepsPickerInPlace_andHidesSearchInCalendar`, which pins
  the owner-reported picker jump). Controls are matched by identifier
  (`history.search.field`, `history.search.clear`) or app English text.
- Regression found by `HistoryAccessibilityAuditUITests`: 3 failures,
  `textClipped` on `history.search.field` (standard, dark, AX5).
  - Hypothesis 1 (22 pt field height): `.frame(minHeight: 36)` — still failed.
    Reverted.
  - Hypothesis 2 (single-line `UITextField` backing): `TextField(…, axis:
    .vertical)` + `.lineLimit(1...3)` — audit passes. Kept.
  - Ruling: the vertical field inserts a newline on Return; `onChange(of:
    text)` strips newlines and drops focus, so Return acts as "search".
    No new audit exemption was added.
- Results (MCP `RunSomeTests`): `HistorySearchUITests` 7/7,
  `HistoryAccessibilityAuditUITests` 5/5, `HistoryDynamicTypeUITests` 1/1.
  Earlier run on the same layout before the axis change:
  `HistoryInteractionUITests` 13/15 (the 2 waived iOS 27.2 edit failures),
  `ReduceMotionHistoryUITests` 2/2, `HistoryUnitDisplayUITests` 1/1,
  `HistoryViewModelTests`, `HistoryViewTests`, `HistorySearchFilterTests` all
  green.
