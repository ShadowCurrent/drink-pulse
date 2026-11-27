# 0051 — Retrospective

**Completed**: 2026-11-26 (one session, inline, superpowers `executing-plans`).

## What shipped
- Deleted `DPGlass.swift`, `DPColors.swift`, `DPLargeTitle.swift`; `dpSecondaryText` doc now
  describes the Frost tint.
- Deleted 10 unused members (Insights aliases and `comparisonLabel`, Dashboard `todaySpend` /
  `formattedSpend`, `canContinueProfile`, three preview templates); alias tests retargeted.
- Deleted 21 unused string-catalog keys (297 → 276).
- `Calendar.days(in:)` moved to `Domain/` with new `CalendarDaysTests`.
- Plan 0050 minors 1, 3, 5: exact streak test (3), one streak read on Today, `heavyDayCount`
  date contract.
- Living docs after the port (README, architecture, PROJECT).

## What went well
- The plan's grep evidence held: only one count mismatch (6 vs 5 binge tests), and it was a
  miscount, not a new use.
- A mutation check proved the new streak assertion reads exactly 3, not just "passes".
- Line-based catalog editing kept Xcode's format; the diff is pure deletions.

## What went badly
- `StringCatalogEdit` cannot delete keys; the plan anticipated this, but the fallback still
  needed a round-trip check because `json.dumps` does not match Xcode's format.
- The `RunSomeTests` JSON summary lists deleted / renamed tests as "Passed" (stale test index).
  Counts had to come from the `.xcresult` bundle.

## Lessons
- For MCP test runs that follow deletions or renames, read the `.xcresult` summary, not the MCP
  result list.
- Plans that count tests should give the grep, not only the number.

## Deferred
- Reviewer minors 1–3 (see `execution.md`); the DST-at-midnight gap in `Calendar.days(in:)`
  (D0051-5, open-questions); the D0051-4 items at the `ui-revamp` → `main` checkpoint.
