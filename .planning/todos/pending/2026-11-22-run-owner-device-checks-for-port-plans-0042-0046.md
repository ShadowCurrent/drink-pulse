---
created: 2026-11-22T10:06:11.763Z
title: Run owner device checks for port plans 0042–0046
area: testing
severity: major
files:
  - docs/plans/0042-design-tokens/plan.md
  - docs/plans/0043-settings-form/plan.md
  - docs/plans/0044-shell/plan.md
  - docs/plans/0045-history/plan.md
  - docs/plans/0046-today-insights/plan.md
  - drinkpulse/Features/Dashboard/Components/HeroGauge.swift:18-19
  - drinkpulse/DesignSystem/DPArcProgress.swift:36
---

## Problem

Device checks deferred to a larger test pass (each plan's "Device check (owner)" section):
- 0042: arc sweep from 0, Reduce Motion, Frost accent, risk tones.
- 0043: VoiceOver on the guideline picker and denied footers, AX5 pickers.
- 0044: logging haptic success / warning, no haptic on sheet open, `+` placement Light / Dark,
  none on Settings, Large Content Viewer on `+` at AX5, logging motion and Reduce Motion.
- 0045: swipe feel, VoiceOver row actions (never doubled), decorated days (VoiceOver reads SF
  Symbol names?), calendar paging and Today, search drawer and edge effect, row-build cost.
- 0046: Today logging (count-up, arc sweep, glyph Replace, gauges, week bar, one haptic, Reduce
  Motion); streak trophy bounce once per launch; rounded large titles and subtitle (does
  `navigationSubtitle` render with `brandNavigationTitle`?); Insights number roll, chart morph,
  period announcement once per change; Light / Dark / Increase Contrast of hero mesh, glyph and
  tint.
- Review M7: hero arc percent `numericText` may jump (no transaction reaches it).
- Review M9: arc accessibility label is "Daily limit" also for UK; check the hero's combined
  element hides it.

## Solution

One owner session on the iPhone, checklist from the plans above; record results per plan
(execution.md, append-only) and open fixes as new todos. Natural point: before or with port
step 8's full suite, at the latest after step 11.
