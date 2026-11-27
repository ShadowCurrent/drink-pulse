---
created: 2026-11-22T10:06:11.763Z
title: Decide limit percent rounding and comparison wording
area: ui
severity: major
files:
  - drinkpulse/DesignSystem/DPArcProgress.swift:52
  - drinkpulse/DesignSystem/LimitGaugeRow.swift:27
  - drinkpulse/Features/Insights/Components/GuidelineComparisonCard.swift
---

## Problem

Owner decisions left by plan 0046 (final review 2026-11-21, R7 and R13).
- The Today hero arc rounds its percent (`DPArcProgress.percentText`), the gauge rows truncate
  (`Int(fraction * 100)`): the same day shows 114 % and 113 %. It differs whenever the fractional
  percent is >= 0.5; the weekly alert also rounds.
- Guideline Comparison rows use the shared `LimitGaugeRow` wording ("x of y unit, n percent")
  instead of the "n% of limit" that D0046-12 said to keep. `InsightsViewModel.comparisonLabel`
  is now dead (tests only).

## Solution

Owner picks rounding or truncation; then one shared percent formatter for the arc, gauge rows,
This Week captions and the alert (display only, not a calculation change). Owner acks or rejects
R13. Decide before port step 9 (copy), so strings are written once. Source: plan 0046
execution.md "Final code review"; open-questions "Plan 0046 open items".
