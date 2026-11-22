---
created: 2026-11-22T10:06:11.763Z
title: Settle Insights trend semantics
area: ui
severity: minor
files:
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift:62-63
  - drinkpulse/Features/Insights/InsightsViewModel.swift:185-188
---

## Problem

- M5 the trend glyph is "equal" for |change| <= 1 % while the text rounds and can say "1%"
  (rule predates step 6).
- `trendFraction` returns 0 ("0 % / equal") when the previous period is empty and the current is
  not (predates step 6, old `TrendBadge`).
- The current partial period is compared with the full previous period.

## Solution

Base glyph and text on the same rounded value; decide the empty-previous copy and the partial-
period comparison with the owner. The last two are calculation semantics: propose first, do not
implement unasked (AGENTS.md). Fits port step 10 (streak / calculations) or after the revamp.
