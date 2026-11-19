# 0039 — Retrospective

**Completed**: 2026-11-19 · **Status**: completed

## What shipped

A search row in the History tab, List segment. It filters the whole history by
`ConsumptionEvent.customName` (case- and diacritic-insensitive via
`localizedStandardContains`), with All / Named / Unnamed scopes, a clear
button, and Cancel (clears the text, resets the scope to All). An empty-string
`customName` counts as unnamed. The List/Calendar picker moved out of a
`.bar`-styled strip into a content row like the Insights period picker, and
it no longer moves when the segment changes.

Pieces: `HistorySearchScope`, `HistorySearchFilter` (pure, one `#Predicate`
per case), `HistorySearchResultsQueryView` (unpaginated `@Query`),
`HistorySearchableList`, `Components/HistorySearchField`, shared
`HistoryDayHeaderRow` / `historyListRowChrome` / `HistoryListInsets`, seed
`-dp_uitest_dataset search`. No schema change.

Commits: `5bc01f3` (freeze), `d6b67ce`, `e59f319`, `361716e`, `081e22a`,
`8cad574`, plus the close-out docs commit.

## Tests

- `HistorySearchFilterTests` 12 (unit, in-memory SwiftData).
- `HistorySearchUITests` 7, `HistorySearchAccessibilityAuditUITests` 2.
- Coverage: `HistorySearchFilter.swift` and `HistorySearchScope.swift` 100%,
  app target 94.31%.
- Full suite: 887 of 915 passed. The 8 failures are 3 known ledger items
  (DL-T02, DL-T03, DL-T04) and 5 audit failures that also fail on `main`
  (new open question).

## What went well

- The pure filter type made the risky part (predicate on an optional string)
  provable by test before any UI existed.
- The audit tests caught real accessibility defects in the new field (text
  clipping, a 17 pt tap target, ember text contrast, a system empty-state view
  that could not grow).

## What went wrong

- The plan chose `.searchable` with `navigationBarDrawer` on spec and docs
  alone, without a look at the real screen inside the app's `TabView`. On the
  first look the owner found the field above the List/Calendar picker, and
  the picker jumping. Four placement attempts followed (principal, subtitle,
  bottom bar, top-bar item); none worked in this layout.
- Lesson: for any change to a screen's header or bars, render it on the
  simulator inside the real tab shell (not a bare preview) before freezing the
  plan.

## Deferred minors (from the final review)

- Pasted multi-line text joins words and drops focus.
- No `scenePhase` refresh in `HistorySearchResultsQueryView`.
- Search text and scope are lost on List → Calendar → List.
- No Cancel when unfocused with an active filter (the scope picker stays
  visible, so All is one tap away).
- Insert/delete triggers two row refreshes (two `onChange`).
- The keyboard is not dismissed when results scroll.
