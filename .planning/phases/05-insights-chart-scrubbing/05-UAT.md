---
status: testing
phase: 05-insights-chart-scrubbing
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md]
started: 2026-07-30T18:21:04Z
updated: 2026-07-31T00:00:00Z
---

## Current Test

[testing complete — user re-tested the 05-03 fix live and reported 2 new issues; awaiting diagnosis]

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

### 7. Scrub marker tracks the data value's Y height
expected: The vertical guide/marker at the touched point visually indicates the curve's actual value at that X position, not a fixed/arbitrary height regardless of data.
result: issue
reported: "jest lepiej poniewaz nie ma teraz tego niedzialajacego chipu glass, jednak kiedy sa 2 problemu, pop pierwsze punkt jest polozony zwwsze na tej samej wysokosci w plaszczysnie Y (a nie na wysokosci maksymalnej wartosci Y w punkcie X)"
severity: major

### 8. Scrub callout shows the X-axis value (date/day/month)
expected: While scrubbing, the callout/label shows the X-axis value (date, or at least day/month) alongside the Y value — the user must be able to clearly read both the Y value and which X point it belongs to.
result: issue
reported: "kiedy przesuwam palcem po wykresie zeby sprawdzic wartosci w punkcie X to nie pokazuje nigdzie wartosci punktu X (czyli nie pokazuje daty lub chociaz dzien/miesiac), ten problem jest najmocniej wydoczny w zakladce Month ale dotyczy on wszystkich wykresow tak naprawde"
severity: major

## Summary

total: 8
passed: 1
issues: 4
pending: 0
skipped: 3

## Gaps

- gap_id: G-05-2
  truth: "Dragging a finger across AlcoholAreaChart shows a date+value glass-chip callout tracking the touch, clamped so it never renders outside the chart's bounds (CHART-01, D-01, D-02, D-03)."
  status: resolved
  resolved_by: 05-03-PLAN.md
  resolved_at: 2026-07-31
  note: "User confirmed live on-device re-test: 'jest lepiej poniewaz nie ma teraz tego niedzialajacego chipu glass' (better now, the broken glass chip is gone). Original flicker/clip symptom closed; see G-05-4 and G-05-5 for newly-surfaced issues found during this same re-test."
  reason: "User reported: kiedy przesuwam palcem po wykresie w widoku insights to ta labelka co sie pokazuje, migocze, nie jest w pelni widoczna, tak jakby byla przykryta przez wykres czesciowo, ogolnie wyglada to zle, nie wyglada to natywnie"
  severity: major
  test: 2
  root_cause: "Two compounding mechanisms: (1) AlcoholAreaChart's .frame(height: 100) doesn't leave vertical clearance for a .top-positioned annotation above near-max-value points, so overflowResolution: y: .fit(to: .chart) squeezes the callout down into the AreaMark's own fill — confirmed on-device via a stationary long-press at the chart's peak. (2) The annotation's SwiftUI content is governed by a chart-wide .animation(value: selectedKey) that desyncs from the natively-rendered RuleMark during continuous chartXSelection updates — confirmed on-device via a drag ending at a different point still showing a stray callout near an earlier peak, and the callout outliving the RuleMark's disappearance on release. Both were flagged as a risk (but not fully anticipated) in 05-RESEARCH.md Pitfall 2."
  artifacts:
    - path: "drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift"
      issue: "RuleMark+.annotation(position: .top, overflowResolution:) inside a too-short .frame(height: 100); chart-wide .animation(value: selectedKey) desyncs annotation from RuleMark during continuous drag updates"
    - path: "drinkpulse/DesignSystem/DPGlass.swift"
      issue: "dpGlassCard(.chip) glassEffect has low contrast against AreaMark's saturated gradient, secondary contributor to 'not fully visible' perception"
  missing:
    - "Scope .animation(value: selectedKey) down to just the RuleMark/annotation subtree instead of the whole Chart"
    - "Give AlcoholAreaChart's 100pt frame more vertical clearance (or change overflowResolution/anchor) so near-peak selections don't get squeezed into the chart's own fill"
  debug_session: .planning/debug/insights-chart-scrub-callout-flicker-clip.md

- gap_id: G-05-3
  truth: "WeekdayBarChart gets the identical RuleMark + glass-chip callout drag-to-scrub treatment as AlcoholAreaChart, weekday+value only, no risk-level text (D-04, D-05)."
  status: resolved
  resolved_by: 05-03-PLAN.md
  resolved_at: 2026-07-31
  note: "Same fix as G-05-2, same shared root cause. User's live re-test confirmed the flicker/clip symptom is gone."
  reason: "User reported: kiedy przesuwam palcem po wykresie w widoku insights to ta labelka co sie pokazuje, migocze, nie jest w pelni widoczna, tak jakby byla przykryta przez wykres czesciowo, ogolnie wyglada to zle, nie wyglada to natywnie, jest problem z tym chipem, dotyczy to wykresu week, month, year i all. Same symptom as G-05-2 (AlcoholAreaChart) — likely shared root cause, and confirmed across all period scopes (week/month/year/all)."
  severity: major
  test: 3
  root_cause: "Same shared root cause as G-05-2 — WeekdayBarChart uses the byte-for-byte identical RuleMark/.annotation/chart-wide-.animation pattern (confirmed via source comparison). Less severe overflow-clamping than AlcoholAreaChart (160pt frame vs 100pt) but the same annotation/RuleMark desync during continuous chartXSelection updates applies identically."
  artifacts:
    - path: "drinkpulse/Features/Insights/Components/WeekdayBarChart.swift"
      issue: "RuleMark+.annotation(position: .top, overflowResolution:) with the same chart-wide .animation(value: selectedLabel) desync as AlcoholAreaChart"
  missing:
    - "Apply the same fix as G-05-2 (scoped animation, overflow/anchor adjustment) to WeekdayBarChart's identical pattern"
  debug_session: .planning/debug/insights-chart-scrub-callout-flicker-clip.md

- gap_id: G-05-4
  truth: "The vertical guide/marker at the touched point visually indicates the curve's actual value at that X position, not a fixed/arbitrary height regardless of data."
  status: failed
  reason: "User reported: jest lepiej poniewaz nie ma teraz tego niedzialajacego chipu glass, jednak kiedy sa 2 problemu, po pierwsze punkt jest polozony zawsze na tej samej wysokosci w plaszczyznie Y (a nie na wysokosci maksymalnej wartosci Y w punkcie X)"
  severity: major
  test: 7
  artifacts: []
  missing: []

- gap_id: G-05-5
  truth: "While scrubbing, the callout/label shows the X-axis value (date, or at least day/month) alongside the Y value."
  status: failed
  reason: "User reported: kiedy przesuwam palcem po wykresie zeby sprawdzic wartosci w punkcie X to nie pokazuje nigdzie wartosci punktu X (czyli nie pokazuje daty lub chociaz dzien/miesiac), ten problem jest najmocniej widoczny w zakladce Month ale dotyczy on wszystkich wykresow tak naprawde. User wants clear, unambiguous display of both the Y value and X value together."
  severity: major
  test: 8
  artifacts: []
  missing: []
