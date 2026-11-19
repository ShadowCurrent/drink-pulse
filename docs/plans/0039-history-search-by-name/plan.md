# 0039 — History list search by drink name

**Status**: in-progress
**Frozen**: 2026-11-19
**Size**: small
**Created**: 2026-11-19

# History Search by Name Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a native search field to the History tab, List segment. It
filters the whole history by `customName`, with All / Named / Unnamed scopes
and the system clear button.

**Architecture:** A pure value type `HistorySearchFilter` maps the search text
and scope to a SwiftData `Predicate<ConsumptionEvent>`. A new
`HistorySearchableList` view owns the search state and the `.searchable` and
`.searchScopes` modifiers. While the filter is active, it swaps the paginated
`HistoryListQueryView` for a new unpaginated `HistorySearchResultsQueryView`
that uses `@Query(filter:)`. Rows and day headers reuse the existing
components. There is no schema change.

**Tech Stack:** SwiftUI (`searchable(text:isPresented:placement:prompt:)`,
`searchScopes(_:activation:_:)`), SwiftData `#Predicate` and `@Query`, Swift
Testing, XCUITest.

**Spec:** `docs/superpowers/specs/2026-11-19-history-search-design.md`

## Global Constraints

- Deployment target iOS 27.0; verify on an iOS 27.2 simulator.
- SwiftUI only; `@Observable`, never `ObservableObject`; Swift 6 strict concurrency; zero warnings.
- Text matches `customName` only. No `category` or enum comparison in any predicate.
- No SwiftData schema change.
- All user-facing strings use `String(localized:)` with keys in `drinkpulse/Localizable.xcstrings`, English only.
- Every Swift file stays under 300 lines; no force-unwraps or `try!` outside tests and previews; no `print`.
- New unit tests use Swift Testing (`@Test`, `#expect`) and mirror the source tree.
- Build and test via Xcode MCP (`BuildProject`, `RunSomeTests`, with the
  `workspaceIdentifier` from `XcodeListWorkspaces`). In a git worktree, use
  `xcodebuild -only-testing:` instead (AGENTS.md exception).
- Record the Apple doc source for each new SwiftUI search API in `execution.md`.

## Review Focus

1. **Imported `customName == ""`.** `DataImporter` copies `record.customName` verbatim. An empty string must count as Unnamed, never as Named. (Task 1 test.)
2. **Whitespace-only query (`"   "`).** It must behave as an empty query: the scope alone filters, and All with no text shows the normal paginated list. (Task 1 test.)
3. **Match older than the 90-day list window.** A search must find it, because results ignore `windowStart`. (Task 1 test and Task 4 UI test.)
4. **Case and diacritics.** `"tysk"` must match `"Tyskie"`, and `"zyw"` must match `"Żywiec"`. Use `localizedStandardContains`, which ignores case and diacritics. (Task 1 test.)
5. **Cancel resets everything.** After Cancel, the scope returns to All and the full list is back, including the load-more footer. (Task 4 UI test.)

---

### Task 1: `HistorySearchScope` + `HistorySearchFilter` (pure logic and predicate)

**Files:**
- Create: `drinkpulse/Features/History/HistorySearchScope.swift`
- Create: `drinkpulse/Features/History/HistorySearchFilter.swift`
- Modify: `drinkpulse/Localizable.xcstrings` (scope labels)
- Test: `drinkpulseTests/Features/History/HistorySearchFilterTests.swift`

**Interfaces:**
- Produces:
  - `enum HistorySearchScope: String, CaseIterable, Identifiable, Hashable, Sendable { case all, named, unnamed; var id: Self { self }; var label: String }`. Label keys: `history.search.scope.all` "All", `history.search.scope.named` "Named", `history.search.scope.unnamed` "Unnamed".
  - `struct HistorySearchFilter: Equatable, Sendable`
    - `init(text: String, scope: HistorySearchScope)`
    - `let query: String`: the text trimmed of whitespace and newlines.
    - `let scope: HistorySearchScope`
    - `var isActive: Bool`: `!query.isEmpty || scope != .all`.
    - `var predicate: Predicate<ConsumptionEvent>`
    - `var emptyState: HistorySearchEmptyState`
  - `enum HistorySearchEmptyState: Equatable { case noMatches, unnamedHasNoName }`. The value is `.unnamedHasNoName` exactly when `scope == .unnamed && !query.isEmpty`.

- [ ] **Step 1: Write the failing tests.** Use an in-memory `ModelContainer` (same setup as `HistoryViewModelTests.makeContainer`). Insert:
  - `"Tyskie"`, 200 days ago
  - `"Żywiec"`, today
  - `"Guinness"`, today
  - `nil`, today
  - `""`, today

  Fetch with `FetchDescriptor(predicate: filter.predicate)` and compare the sorted `customName` sets.

  Each line below is one test. Every test has the prefix `test_` and continues as named.

  | Test name (after `test_`) | Text | Scope | Expected result |
  |---|---|---|---|
  | `isActive_false_forBlankTextAndAllScope` | `"   "` | `.all` | `isActive == false` |
  | `isActive_true_forScopeOnly` | `""` | `.named` | `isActive == true` |
  | `query_isTrimmed` | `"  tysk \n"` | — | `query == "tysk"` |
  | `predicate_all_matchesSubstringCaseInsensitive` | `"tysk"` | `.all` | `["Tyskie"]`, which also proves the match is outside the 90-day window |
  | `predicate_all_ignoresDiacritics` | `"zyw"` | `.all` | `["Żywiec"]` |
  | `predicate_named_noText_excludesNilAndEmpty` | `""` | `.named` | `["Guinness", "Tyskie", "Żywiec"]` |
  | `predicate_named_withText_filtersNamed` | `"guin"` | `.named` | `["Guinness"]` |
  | `predicate_unnamed_noText_returnsNilAndEmpty` | `""` | `.unnamed` | 2 events, all with nil or empty `customName` |
  | `predicate_unnamed_withText_returnsNothing` | `"a"` | `.unnamed` | `[]` |
  | `emptyState_unnamedWithText_isUnnamedHasNoName` | `"a"` | `.unnamed` | `.unnamedHasNoName` |
  | `emptyState_otherwise_isNoMatches` | `"x"` | `.all` | `.noMatches` |

- [ ] **Step 2: Run the tests and confirm they fail.** Use Xcode MCP `RunSomeTests` with `drinkpulseTests/HistorySearchFilterTests`. Expected: a build failure, because `HistorySearchFilter` is not defined.

- [ ] **Step 3: Implement both types.** Build `predicate` as one `switch` over `(scope, query.isEmpty)`, with a separate `#Predicate` literal per case. Do not compose predicates at runtime.
  - **Text matching:** use `localizedStandardContains(query)` on the unwrapped `customName`.
  - **Named:** `customName != nil && customName != ""`.
  - **Unnamed:** `customName == nil || customName == ""`.
  - **Unnamed with text:** a predicate that matches nothing.

  The text-match shape on an optional (`?.`, `flatMap`, or `if let`) is the builder's call. A shape counts only when the tests run green on iOS 27.2. Record the shape that works in `execution.md`. Before choosing, consult the Apple documentation for `Predicate` and `localizedStandardContains` via MCP `DocumentationSearch`. Add the 3 scope label keys to the string catalog.

- [ ] **Step 4: Run the tests and confirm they pass.** Run the same command as Step 2. Expected: 11 of 11 pass.

- [ ] **Step 5: Commit.** Message: `[plan-0039] add HistorySearchFilter predicate and scopes`.

---

### Task 2: Share History row chrome and the day header

**Files:**
- Create: `drinkpulse/Features/History/Components/HistoryDayHeaderRow.swift` (moved from `HistoryListQueryView.swift:96-109`)
- Create: `drinkpulse/Features/History/Components/HistoryListRowChrome.swift`. It holds `historyListRowChrome(insets:)`, moved from `HistoryListQueryView.swift:136-145` and made `internal`, plus the two inset constants as `static let` on an `enum HistoryListInsets { static let event, header }`.
- Modify: `drinkpulse/Features/History/HistoryListQueryView.swift`. Delete the moved code and use `HistoryListInsets`.

**Interfaces:**
- Produces:
  - `struct HistoryDayHeaderRow: View { let title: String }`
  - `extension View { func historyListRowChrome(insets: EdgeInsets) -> some View }`
  - `HistoryListInsets.event`, `HistoryListInsets.header`

- [ ] **Step 1: Move the code.** No behavior changes. Add a short `#Preview` to `HistoryDayHeaderRow`.
- [ ] **Step 2: Build and run the existing list tests.** Build via MCP `BuildProject`, then run `RunSomeTests` with `drinkpulseUITests/HistoryInteractionUITests`. Expected: zero warnings, and all tests pass unchanged.
- [ ] **Step 3: Commit.** Message: `[plan-0039] share History row chrome and day header`.

---

### Task 3: `HistorySearchResultsQueryView` + `HistorySearchableList`, wired into `HistoryView`

**Files:**
- Create: `drinkpulse/Features/History/HistorySearchResultsQueryView.swift`
- Create: `drinkpulse/Features/History/HistorySearchableList.swift`
- Modify: `drinkpulse/Features/History/HistoryView.swift`. In `listContent`, replace the direct `HistoryListQueryView(...)` with `HistorySearchableList(...)`, passing the same arguments.
- Modify: `drinkpulse/Localizable.xcstrings`

**Interfaces:**
- Consumes:
  - `HistorySearchFilter`, `HistorySearchScope`, `HistorySearchEmptyState` (Task 1)
  - `HistoryDayHeaderRow`, `historyListRowChrome(insets:)`, `HistoryListInsets` (Task 2)
  - `HistoryViewModel.daySections(_:)`, `[DaySection].flattenedForHistoryList()`
- Produces:
  - `HistorySearchResultsQueryView(filter: HistorySearchFilter, vm: HistoryViewModel, profile: UserProfile?, onEditEvent: (ConsumptionEvent) -> Void)`. It runs `@Query(filter: filter.predicate, sort: \.consumptionDate, order: .reverse)` and shows the same row rendering as `HistoryListQueryView`, with no load-more and no end footer.
    - **No matches, `.noMatches`:** show `ContentUnavailableView.search(text: filter.query)`.
    - **No matches, `.unnamedHasNoName`:** show a `ContentUnavailableView` with title key `history.search.unnamed.title` "No Results", description key `history.search.unnamed.description` "Unnamed drinks have no name to match. Switch to All or Named to search by name.", and `systemImage: "magnifyingglass"`.
    - **Row refresh:** recompute rows on `.onChange(of: events.map(\.modifiedDate), initial: true)`, as `HistoryListQueryView` does.
  - `HistorySearchableList`: same initializer parameters as `HistoryListQueryView`. It holds three pieces of `@State`: `searchText: String`, `scope: HistorySearchScope = .all`, `isSearchPresented: Bool`.
    - **Field:** `.searchable(text:isPresented:placement: .navigationBarDrawer(displayMode: .always), prompt:)`. Prompt key `history.search.prompt` "Search by name".
    - **Scopes:** `.searchScopes($scope, activation: .onSearchPresentation) { ForEach(HistorySearchScope.allCases) … }`.
    - **Cancel:** on `.onChange(of: isSearchPresented)` with a `false` value, set `scope = .all`.
    - **Content:** show results when `HistorySearchFilter(text:scope:).isActive`, otherwise `HistoryListQueryView`.
    - **Test hook:** `.accessibilityIdentifier("history.search.results")` on the results list.
    - **Previews:** include `#Preview`s for both views, using in-memory mock data with named and unnamed events.

Search lives only in the List segment, because `HistorySearchableList` is built only inside `listContent`. Before implementing, look up via MCP `DocumentationSearch`: `searchable(text:isPresented:placement:prompt:)`, `navigationBarDrawer(displayMode:)`, `searchScopes(_:activation:_:)`, `ContentUnavailableView.search(text:)`. Record the sources in `execution.md`.

- [ ] **Step 1: Implement both views and the `HistoryView` change, and add the 3 strings.**
- [ ] **Step 2: Build and check previews.** Build via MCP `BuildProject`: zero warnings. Then check both previews with MCP `RenderPreview`.
- [ ] **Step 3: Check file sizes.** Run the AGENTS.md find command. Expected: no output.
- [ ] **Step 4: Commit.** Message: `[plan-0039] native search with scopes in History list`.

---

### Task 4: UI test + seed dataset

**Files:**
- Modify: `drinkpulse/UITestSeed+Fixtures.swift` and `drinkpulse/UITestSeed.swift`. Add `-dp_uitest_dataset search`, following the same pattern as `seedSameDayFixture`. It seeds:
  - `"Guinness"`, today, 500 ml
  - `"Tyskie"`, 200 days ago, 500 ml
  - unnamed beer, today, 330 ml
- Test: `drinkpulseUITests/Features/History/HistorySearchUITests.swift`

**Interfaces:**
- Consumes: identifier `history.search.results`; scope labels "All", "Named", "Unnamed"; prompt "Search by name".

Locate the search field with `app.searchFields.firstMatch`. The clear button is a system element. Tap it by position within the search field (`searchField.buttons.firstMatch`), never by its localized label: the simulator system locale is Polish.

Every test below has the prefix `test_` and continues as named:

- [ ] **Step 1: Write the tests.**
  - **`search_filtersListToMatchingName`:** type `guin`. Assert that a row containing `Guinness` exists and that no row contains `330 ml`.
  - **`search_findsEntryOlderThanListWindow`:** type `tysk`. Assert that a `Tyskie` row exists.
  - **`clearButton_restoresFullList`:** type `guin`, then tap the clear button. Assert that the `330 ml` row is back.
  - **`unnamedScope_withText_showsExplanation`:** activate search, tap the `Unnamed` scope, and type `a`. Assert that the static text "Unnamed drinks have no name to match. Switch to All or Named to search by name." exists.
  - **`cancel_resetsScopeAndShowsFullList`:** tap `Named`, then cancel. Tap Cancel as the button after the search field, by position. After cancel, assert that the `330 ml` row exists and that the "No earlier entries" footer exists.
- [ ] **Step 2: Run the tests.** Run MCP `RunSomeTests` with `drinkpulseUITests/HistorySearchUITests`. Expected: 5 of 5 pass, and all 5 test names appear in the log.
- [ ] **Step 3: Run the regression check.** Run `RunSomeTests` with `drinkpulseUITests/HistoryInteractionUITests` and `drinkpulseTests/HistoryViewModelTests`. Expected: green, apart from failures already listed in `.claude/context/open-questions.md`.
- [ ] **Step 4: Commit.** Message: `[plan-0039] UI tests for History search`.

---

### Task 5: End-of-task checklist and docs

**Files:**
- Modify: `README.md` (add History search to the features list)
- Modify: `docs/plans/INDEX.md` (add row 0039)
- Create: `docs/plans/0039-history-search-by-name/execution.md`, then `retrospective.md`
- Append: `docs/DEVLOG.md`
- Modify: `.claude/context/current-focus.md` (add a note; the Phase 11 focus stays)
- Modify: `.claude/context/open-questions.md`. Add the stale plan 0038 status: it is `in-progress`, but the code still uses `List`.

- [ ] **Step 1: Run coverage.** Run tests with coverage on the History test classes. Expected: `HistorySearchFilter.swift` and `HistorySearchScope.swift` reach 100 percent line coverage.
- [ ] **Step 2: Privacy and logging check.** Confirm there is no network access, no `print`, and that the query text is never logged.
- [ ] **Step 3: Update the docs listed above.** `architecture.md` and `domain.md` do not change: no new layer and no domain rule. Confirm this in the DEVLOG entry.
- [ ] **Step 4: Commit.** Message: `[plan-0039] docs and plan close-out`.
