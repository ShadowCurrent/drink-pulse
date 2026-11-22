---
created: 2026-11-22T10:06:11.763Z
title: Tidy Insights chart scrub cost and AX weekday initials
area: ui
severity: cosmetic
files:
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift
  - drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift
  - drinkpulse/Features/Insights/Components/WeekdayBarChart.swift
---

## Problem

- `vm.seriesData` is recomputed several times per frame while scrubbing (hero and chart each
  look up the selected point); pattern predates step 6, not measured.
- Weekday chart at AX sizes shows ambiguous narrow initials ("T"/"T", "S"/"S"); each bar's
  accessibility label carries the full name.

## Solution

Measure with Instruments first; cache the series per render if it shows. Consider short
weekday symbols at AX sizes. After the revamp.
