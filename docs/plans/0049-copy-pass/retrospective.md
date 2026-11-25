# 0049 — Retrospective

**Completed**: 2026-11-25 (one session, inline, superpowers `executing-plans`).

## What shipped
- Settings labels in Title Case per `VOICE.md`: "Export All Data", "Delete All Data", "Daily
  Reminder", "Volume Unit", "Alcohol Unit", "Strength Step"; section header "Health Guideline"
  with the picker row and pushed list still "Guideline".
- "Weekly check-in" is "Weekly Summary" on Settings and onboarding (and in the denied message).
- The weekly notification body is one neutral line, "Your weekly summary is ready."; the
  comparison stays in `WeeklySummaryService.summaryContent(in:now:calendar:)` and only decides
  whether a notification is scheduled.

## What went well
- A catalog audit before planning showed steps 2–8 had already moved most `VOICE.md` rows, so the
  plan stayed small.
- A format-keeping script (byte-identical no-op round trip) made catalog edits safe without the
  translation-gated `StringCatalogEdit`.

## What went badly
- The guideline footer was planned without knowing that a `Form` footer in the audited launch
  viewport triggers a `dynamicType` audit issue; it cost one test round and an owner question.
- Writing Task 3 tests early broke the unit target build for the UI runs of Tasks 1–2; a stash
  fixed it.

## Surprises (iOS 27.2)
- `SettingsAccessibilityAuditUITests` reports `dynamicType` on a plain `Text` in a `Form`
  section footer at the default size (standard and dark), with or without `.font(.footnote)`;
  AX5 passes. Other Settings footers sit outside the audited viewport.

## Follow-ups
- Owner: Title Case outside the `VOICE.md` table (D0049-4) and the weekly hint wording
  (D0049-6), both in open-questions "Plan 0049 follow-ups".
- Unused catalog keys go to step 11 cleanup (D0049-7).
- Next: port step 10 (streak calculation) per plan 0040.
