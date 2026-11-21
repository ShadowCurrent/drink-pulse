# 0046 — Retrospective

**Completed**: 2026-11-21 · **Branch**: `port/0046-today-insights` → `ui-revamp` (`--no-ff`)

## What shipped
- Today: mesh hero with risk-tinted arc and cut-out status glyph (today's level), tiles,
  Guideline Limits gauges, This Week chart with a daily-limit rule, Over Weekly Limit card,
  title "Today" with a `date · guideline` subtitle. No glass on content.
- Insights: period picker (menu at AX sizes), navigator with bordered circle buttons, toolbar
  "Today", hero total + neutral trend + slot-identity area chart with native scrubbing,
  Health Impact grid, weekday chart (no scrubbing), guideline comparison gauges, empty state,
  VoiceOver period announcement.
- Shared: `MetricTile`, `TilePair`, `LimitGaugeRow`, `NoDrinksYetView`, `RiskLevel+Status`,
  `numbersCountDown`. `VOICE.md` copy for both screens; "Home" → "Today" in 22 UI test files.
- No calculation, Domain, persistence or schema change.

## What went well
- Pure helpers first (status, slots, announcement) kept the view work presentation-only.
- Owner calls during the run (Settings has no `+`) were settled in minutes.
- Bisection with single-test audit runs found the real `dynamicType` cause quickly.

## What went wrong / surprises
- The accessibility audit flags every text inside `ViewThatFits` and a lazy adaptive grid as
  `dynamicType`. The prototype relied on both; the port uses Dynamic Type branches instead
  (now a design-system rule).
- Element-less `contrast` findings on Insights could not be localized; handled under D11-31.
- Xcode's test index kept reporting deleted tests as "Passed".
- `RunSomeTests` blocks the simulator; RED for Task 5 had to be shown structurally.

## Follow-ups
- Owner device pass and the percent rounding question (open-questions "Plan 0046 open items").
- Coverage not measured (MCP has no report; CLI needs owner approval).
- Full suite at port step 8 (plan 0040).
