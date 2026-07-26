---
created: 2026-07-26T21:04:43.147Z
title: Scrub Insights charts to reveal per-point values
area: ui
severity: minor
files:
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
  - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift
  - drinkpulse/Features/Insights/InsightsViewModel+Charts.swift
  - drinkpulse/Features/Insights/InsightsChartModels.swift
---

## Problem

The Insights charts are read-only. Dragging a finger across
`AlcoholAreaChart` (and `WeekdayBarChart`) does nothing — neither file
contains any `chartXSelection`, `chartOverlay`, or gesture handling, so a
user can see the shape of their consumption trend but cannot read the
actual value at a given day/week/point.

The user wants: drag across the chart → the value at the touched point is
shown. Explicit requirement — it must feel **native iOS 26**, i.e. built
on the first-party Swift Charts selection API and system interaction
feel, not a hand-rolled `DragGesture` + custom hit-testing hack.

## Solution

Use the native Swift Charts selection API:

- `.chartXSelection(value: $selectedDate)` (and/or
  `.chartXSelection(range:)` where a range readout makes sense) bound to
  `@State` in the chart view — this is the system-provided scrub
  interaction, including haptics/animation behaviour.
- Render the readout as a `RuleMark`/`PointMark` annotation at the
  selected x plus a value callout, styled with existing DesignSystem
  tokens (Liquid Glass surface, not a bespoke bubble).
- Format the displayed value through the existing formatting layer
  (`InsightsViewModel+Formatting`) so it respects the user's
  `AlcoholUnit` — never format inline in the view.
- Apply to both `AlcoholAreaChart` and `WeekdayBarChart` for consistency;
  decide whether the hero card headline value should follow the selection
  or stay on the period total (probably: follow selection while
  scrubbing, revert on release).

Constraints to honor:

- Accessibility: selection must not be the only path to the values —
  keep/extend `accessibilityChartDescriptor` so VoiceOver users get the
  per-point values too (CLAUDE.md accessibility rules).
- Honor `reduceMotion` for the selection animation.
- Requires a `drinkpulseUITests` UI test (user-facing behaviour change):
  drive the real Insights screen, scrub the chart, assert the readout
  shows the expected value.
