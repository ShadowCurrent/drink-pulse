# History list search by drink name — design (short)

**Date**: 2026-11-19
**Size**: small change
**Status**: awaiting owner approval

## Intent

In the History tab, List segment, the owner wants a native search field that
filters the list to entries matching a drink name (e.g. a beer brand). While a
query is active, the list shows only matching entries. The field must have a
way to clear the filter. The owner also wants to narrow results to entries
that have a custom name or entries that do not.

## Goals

- Native `.searchable` field, with the system clear button and Cancel.
- Text matches `ConsumptionEvent.customName` only: case-insensitive and
  locale-aware, across the **whole** history (not only the loaded 90-day window).
- Search scopes: **All**, **Named** (`customName != nil`), **Unnamed**
  (`customName == nil`).
- When nothing matches, show `ContentUnavailableView.search`. For
  Unnamed + non-empty text, the empty state explains that unnamed drinks have
  no name to match (owner choice "(a)").
- Results keep today's look: day headers and card rows via
  `HistoryViewModel.daySections` and `flattenedForHistoryList()`.
- Editing works from results: tapping a row opens `EditEventView` as today.

## Non-goals

- No matching on category ("Beer") or on the derived serving name ("Pint").
  Owner rejected it: it needs an enum comparison in `#Predicate`, which the
  owner judged too risky.
- No search in the Calendar segment.
- No search suggestions, no tokens, no persistent filter outside search mode.

## Anti-goals

- No SwiftData schema change, so no migration.
- No regression of the paginated non-search list (window, load-more, footer).

## Constraints

- iOS 27.0 deployment target, verified on iOS 27.2. SwiftUI only, Swift 6
  strict concurrency, files under 300 lines.
- All strings via `String(localized:)`, English only.
- A UI test is mandatory, as is unit coverage of any new non-view logic.

## Approaches

1. **(Picked) SwiftData query filter.** `.searchable` on `HistoryView`.
   While search is active, the List segment swaps `HistoryListQueryView` for a
   search-results query view. That view uses a `@Query` over all events with a
   `#Predicate` built from the text and the scope, and has no window or
   pagination. Only matches are fetched.
2. **In-memory filter on the display name.** This would also match "Beer" and
   serving names. Rejected: it fetches the whole history on every search, and
   the owner chose customName-only.
3. **Filter only the loaded window.** Rejected: it misses older entries.

## Decided how (owner)

- Approach 1. Scopes All / Named / Unnamed with
  `searchScopes(_:activation: .onSearchPresentation)`, so the picker shows as
  soon as the field is tapped.
- Unnamed + text gives an empty result with an explanatory empty state.
- Cancelling search resets the scope to All and returns the full paginated list.

## Proposed by Claude (correct if wrong)

- Placement `.navigationBarDrawer(displayMode: .always)`, only while the List
  segment is selected. Prompt: "Search by name".
- The query text is trimmed of whitespace. A whitespace-only query counts as
  empty, and the scope alone filters.
- The text and scope to predicate mapping lives in a small testable type
  (e.g. `HistorySearchFilter`) in `Features/History/`. It is unit-tested
  against an in-memory store, which also proves `localizedStandardContains`
  on optional `customName` works in `#Predicate` on iOS 27.

## Left to the builder

- Exact predicate shape for optional `customName`. Verify by test, not by
  assumption.
- Accessibility identifiers for the UI test. The test seeds named and unnamed
  events through the existing launch-argument hooks.

## Apple sources consulted (Xcode MCP DocumentationSearch, SwiftUI)

- `searchable(text:placement:prompt:)`;
  `SearchFieldPlacement.navigationBarDrawer(displayMode:)`.
- `searchScopes(_:activation:_:)` and `SearchScopeActivation.onSearchPresentation`:
  on iOS, scopes show on text entry by default and disappear on cancel.
- Articles "Performing a search operation", "Scoping a search operation" and
  "Managing search interface activation" (`isSearching`, `isPresented`).

## Doc note

Plan 0038 (`in-progress`) describes replacing the History `List` with
`ScrollView` + `LazyVStack`, but the current code uses `List`. That status is
stale. This design builds on the code as it is (`List`).
