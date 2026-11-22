---
created: 2026-11-22T10:06:11.763Z
title: Localize gauge VoiceOver value and guideline marker
area: ui
severity: minor
files:
  - drinkpulse/DesignSystem/LimitGaugeRow.swift:86
  - drinkpulse/Features/Insights/Components/GuidelineComparisonCard.swift:13
---

## Problem

Plan 0046 final review M3, M4.
- M3 `LimitGaugeRow` builds its accessibility value `"%@ of %@ %@, %d percent"` without
  `String(localized:)` (AGENTS.md: all user-facing strings via the catalog); shared on two screens.
- M4 the user's guideline is marked with " ✓" in the row title; VoiceOver reads "check mark", not
  that it is the user's guideline.

## Solution

Catalog key for the gauge value; spoken label such as "WHO, your guideline" with the visual
check kept. Fits port step 9 (copy). Depends on the R13 wording decision.
