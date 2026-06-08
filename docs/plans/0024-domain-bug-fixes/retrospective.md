# 0024 — Retrospective

**Completed**: 2026-06-06

## What shipped
Two silent Domain bugs, fixed by consolidating limit resolution into the domain:

1. **Stale backups on edit** — `contentSignature` now hashes the live drink
   fields (`customName`, `category`, `icon`) instead of the deprecated `name`.
2. **Custom-guideline daily limit broken in History** — `HistoryCalendarView`
   now resolves limits through the shared domain helper, matching Dashboard and
   Insights. New `GuidelineChoice.effectiveLimits(weeklyGoalGrams:for:)` and
   `GuidelineLimits.effectiveDailyGrams` are the single source for the
   custom-goal and UK-no-daily fallbacks.

## What went well
- Root-causing Bug 2 to duplicated logic meant the fix removed code in three
  places rather than patching one symptom — no fourth consumer can now get it
  wrong.
- Keeping `limits(for:)`'s sentinel-zero contract intact meant zero churn to the
  existing `GuidelineLimitsTests` and the documented raw thresholds.

## What to watch
- **`.custom` is reachable only via import.** The picker filters it out, so the
  History bug was dormant in normal use but live for anyone importing a custom
  profile. If `.custom` ever becomes user-selectable, the resolver path is
  already correct.
- **Deprecated `ConsumptionEvent.name`** is now out of the backup signature but
  still stored/exported; removal stays owned by plan-0023 (needs a migration).

## Lessons
- Plan-0022's "regenerate from content, not count" was correct in intent but
  hashed a field that had since been deprecated — a reminder that change-
  detection signatures must track the *display-defining* fields, and should be
  revisited whenever the display derivation changes (it changed in plan-0014).

## Follow-ups handed off (not in this plan)
- `docs/roadmap.md` still claims density is 0.8 g/ml; code is 0.789 (b35ba30).
  Left for user confirmation before editing roadmap history.
- `RiskLevel.safe` enum case name (cosmetic; UI string already "Low Risk").
