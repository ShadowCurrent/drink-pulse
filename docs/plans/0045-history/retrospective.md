# 0045 — Retrospective

**Completed**: 2026-11-21 (full suite and coverage not run, owner decision; two audit findings open)

## What went well
- History is a system screen now: inset-grouped day sections with totals, the picker in the bar,
  native swipe / context-menu actions, native `.searchable` with scopes and a `UICalendarView`
  calendar, with four pure helpers (`HistoryDayTotal`, `HistoryCalendarMarks`, the day-aligned
  window, `calendarRange`) covered by unit tests.
- The partial-oldest-day risk is closed by construction (window on a day boundary) and pinned by
  a UI test that collects every loaded header.
- Probing the calendar's accessibility tree first gave locale-independent locators (day number
  text, `DatePicker.PreviousMonth`).

## What went wrong / surprises
- `.foregroundStyle(.primary)` on a `Button` label in a `List` still rendered the accent;
  `Color.primary` was needed (seen only in a preview).
- Large `RunSomeTests` calls, mixed unit + UI calls, and any test-file edit during a run produced
  "incomplete result bundle" failures; single-class or small batches worked.
- An incremental build hid the `HistorySearchUITests` Swift 6 warnings, so a "zero warnings"
  note had to be corrected later.
- The audit reports system-owned controls (search placeholder, QuickType slots, `UICalendarView`
  day numbers) that no app change can fix; the owner chose recorded exemptions.
- `StringCatalogEdit` needs a skill not installed here; the catalog was edited as text.

## Decisions made during execution
- Owner: no full suite; test only the changed areas. Owner: exempt the three system-owned audit
  findings by key / frame, recorded.
- Manual VoiceOver actions kept (simulator cannot show whether swipe actions are exposed).
- `gramsByDay` removed with `monthCells`; performance tests moved to `HistoryCalendarMarks`.
- One query for the visible month OR the selected day.

## Follow-ups
- Two open audit findings (calendar standard `dynamicType` on own texts; search AX5 empty-state
  contrast) — open-questions.
- Device checks listed in the plan, plus VoiceOver on decorated days (decorations are exposed as
  SF Symbol images with generic labels).
- Unused strings from the removed inline search and the old day cell — step 11 cleanup.
- Full suite at the next checkpoint (step 8).
