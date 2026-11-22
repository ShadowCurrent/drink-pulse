---
created: 2026-11-22T10:06:11.763Z
title: Remove dead Today / Insights code and keys
area: general
severity: cosmetic
files:
  - drinkpulse/Features/Insights/InsightsViewModel.swift
  - drinkpulse/Localizable.xcstrings
  - drinkpulse/Features/Dashboard/Components/TodayHeroCard.swift
  - docs/domain.md
---

## Problem

Plan 0046 final review M6 and a docs mismatch:
- `InsightsViewModel.comparisonLabel` has no production caller after R13.
- `today.status` identifier cannot be queried (inside the hero's combined element, R5).
- `insights.metric.risk.*` keys unused (D0046-15 says remove when unused).
- `docs/domain.md` / AGENTS.md describe an `AlcoholUnit.units` case; the enum has only `grams`
  and `standardDrinks`.

## Solution

Delete after the R13 decision; fix the domain doc (living doc). Fits port step 11 (cleanup).
