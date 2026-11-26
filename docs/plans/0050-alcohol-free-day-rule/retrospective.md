# 0050 — Retrospective

**Completed**: 2026-11-26 (one session, inline, superpowers `executing-plans`).

## What shipped
- `AlcoholFreeDayRule` + `AlcoholFreeDayStatus` in `Domain/`: one rule for every alcohol-free
  and heavy-day number (start on the first log day, today only with alcohol, no future days,
  heavy ≥ 60 g display-unit grams).
- Insights "Alcohol-Free Days", "Longest Alcohol-Free Streak", "Heavy Days" and Today
  "Alcohol-Free Streak", "Alcohol-Free This Month" delegate to it; "–" when a period has no
  counted day. Rule documented in `docs/domain.md`.
- Tests: 17 Domain tests (7 spec examples), updated Insights / Dashboard VM tests, two new UI
  test classes with the `alcoholfreetoday` dataset.

## What went well
- The spec's hand-verification table was precise enough that every example passed on the first
  correct implementation; no owner stop was needed.
- Passing grams in as a closure kept density with the callers, so the rule stayed unit-agnostic
  and the change touched no calculation code.
- The fresh reviewer found a real DST-at-midnight bug in the streak walk-back that no spec
  example exercised.

## What went badly
- `RunAllTests` was started although it includes the slow UI tests; the owner stopped it. The
  full-suite gate in the plan (and the AGENTS.md Domain escalation) did not account for the
  owner's tolerance for run time.

## Lessons
- Ask before a full run that includes UI tests; offer a unit-only run instead.
- Any loop that walks days with `date(byAdding:)` must `startOfDay` every step, not only the
  first.
