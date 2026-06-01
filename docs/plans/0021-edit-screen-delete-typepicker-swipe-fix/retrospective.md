# 0021 — Retrospective

**Completed**: 2026-06-01

## What went well
- The existing `onChange(of: category)` cascade in `EditEventView` meant
  the tappable type picker only had to write `category` — icon/name/
  volume/ABV reset came for free. Minimal new logic.
- Extracting `DrinkTypeGrid(onSelect:)` let both Add and Edit share one
  tile grid with no behavioural change to the Add flow (verified by a
  clean build + unchanged tests).
- `.swipeActions` is the idiomatic replacement for `.onDelete` and fixes
  the row-height and gesture-jank issues by construction.

## What went wrong / surprises
- SourceKit's in-editor index reported dozens of false "cannot find type"
  errors for pre-existing types mid-edit. Ignored; the compiler was the
  source of truth.
- `-derivedDataPath build/` broke CodeSign because the repo is under
  iCloud-synced `~/Documents` (fileprovider xattrs). Had to use the
  default DerivedData for the coverage run.

## Decisions made during execution
- Dropped the planned grouping memoization: judged the freeze to be the
  `.onDelete` + Button interaction, not grouping cost, and memoizing via
  `@State` would add a first-render empty flash. Documented in
  execution.md.
- Added no new unit tests: no new testable pure logic was introduced
  (all view-layer); per CLAUDE.md we don't test view/framework code, and
  a groupedByDay-based "delete" test would only re-cover existing logic.

## Leftover open questions
- Q4 (highlight current type) — implemented as highlight + "Change Type"
  title (the default).
- Q5 (undo after delete) — left out of scope; possible follow-up
  (toast/undo on both list swipe and edit-screen delete).
- The swipe-hang/height fix needs on-device confirmation (UI timing,
  not unit-testable).
