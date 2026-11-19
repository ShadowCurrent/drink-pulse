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
