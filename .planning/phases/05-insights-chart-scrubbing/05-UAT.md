---
status: complete
phase: 05-insights-chart-scrubbing
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md]
started: 2026-07-30T18:21:04Z
updated: 2026-07-30T18:35:00Z
---

## Current Test

[testing complete — user chose to stop and fix the reported bug rather than finish the checklist]

## Tests

### 1. Insights hero card follows scrub selection
expected: InsightsHeroCard headline follows the AlcoholAreaChart scrub selection and reverts to the period total on release or period switch (CHART-02, D-06).
result: pass
source: automated
coverage_id: D2

### 2. AlcoholAreaChart drag-to-scrub callout
expected: Dragging a finger across AlcoholAreaChart shows a date+value glass-chip callout tracking the touch, clamped so it never renders outside the chart's bounds (CHART-01, D-01, D-02, D-03).
result: issue
reported: "kiedy przesuwam palcem po wykresie w widoku insights to ta labelka co sie pokazuje, migocze, nie jest w pelni widoczna, tak jakby byla przykryta przez wykres czesciowo, ogolnie wyglada to zle, nie wyglada to natywnie"
severity: major

### 3. WeekdayBarChart drag-to-scrub callout
expected: WeekdayBarChart gets the identical RuleMark + glass-chip callout drag-to-scrub treatment as AlcoholAreaChart, weekday+value only, no risk-level text (D-04, D-05).
result: issue
reported: "kiedy przesuwam palcem po wykresie w widoku insights to ta labelka co sie pokazuje, migocze, nie jest w pelni widoczna, tak jakby byla przykryta przez wykres czesciowo, ogolnie wyglada to zle, nie wyglada to natywnie, jest problem z tym chipem, dotyczy to wykresu week, month, year i all"
severity: major

### 4. Reduce Motion gates both charts' scrub animation
expected: Reduce Motion suppresses both charts' callout appear/disappear transition AND the selection-state animation together, never just one (CHART-04).
result: skipped
reason: "User chose to stop the checklist and go straight to fixing the reported callout bug (G-05-2/G-05-3); this Reduce Motion check depends on the same callout rendering code and should be re-verified after the fix lands."

### 5. AlcoholAreaChart VoiceOver Audio Graph
expected: VoiceOver's Rotor > Audio Graph action surfaces every AlcoholAreaChart data point's date + value, independent of the drag gesture (CHART-03, D-08).
result: skipped
reason: "User chose to stop the checklist and go straight to fixing the reported callout bug (G-05-2/G-05-3)."

### 6. WeekdayBarChart VoiceOver Audio Graph
expected: VoiceOver's Rotor > Audio Graph action surfaces every WeekdayBarChart data point's weekday + value, additive to the existing per-bar label (CHART-03, D-09).
result: skipped
reason: "User chose to stop the checklist and go straight to fixing the reported callout bug (G-05-2/G-05-3)."

## Summary

total: 6
passed: 1
issues: 2
pending: 0
skipped: 3

## Gaps

- gap_id: G-05-2
  truth: "Dragging a finger across AlcoholAreaChart shows a date+value glass-chip callout tracking the touch, clamped so it never renders outside the chart's bounds (CHART-01, D-01, D-02, D-03)."
  status: failed
  reason: "User reported: kiedy przesuwam palcem po wykresie w widoku insights to ta labelka co sie pokazuje, migocze, nie jest w pelni widoczna, tak jakby byla przykryta przez wykres czesciowo, ogolnie wyglada to zle, nie wyglada to natywnie"
  severity: major
  test: 2
  artifacts: []
  missing: []

- gap_id: G-05-3
  truth: "WeekdayBarChart gets the identical RuleMark + glass-chip callout drag-to-scrub treatment as AlcoholAreaChart, weekday+value only, no risk-level text (D-04, D-05)."
  status: failed
  reason: "User reported: kiedy przesuwam palcem po wykresie w widoku insights to ta labelka co sie pokazuje, migocze, nie jest w pelni widoczna, tak jakby byla przykryta przez wykres czesciowo, ogolnie wyglada to zle, nie wyglada to natywnie, jest problem z tym chipem, dotyczy to wykresu week, month, year i all. Same symptom as G-05-2 (AlcoholAreaChart) — likely shared root cause, and confirmed across all period scopes (week/month/year/all)."
  severity: major
  test: 3
  artifacts: []
  missing: []
