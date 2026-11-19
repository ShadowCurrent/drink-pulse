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
