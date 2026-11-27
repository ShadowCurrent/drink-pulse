---
created: 2026-11-22T10:06:11.763Z
title: Name secondary ink and add Increase Contrast variants
area: ui
severity: minor
files:
  - drinkpulse/Assets.xcassets
  - drinkpulse/DesignSystem/Brand.swift
---

## Problem

Before step 11 deletes old assets:
- `Color.dpSecondaryText` (Light #636369, 4.96:1 on the Frost tint) is the only contrast-safe
  secondary ink for headers, footers, chart axes and empty-state text; the system grey fails
  (~3.2–3.4:1). Needs a design-system name and a WCAG test (plan 0043).
- `AccentColor` and `RiskLow` / `RiskModerate` / `RiskHigh` have no Increase Contrast appearances
  (plan 0042).

## Solution

Keep the asset under a `Brand` name with a contrast test; add Increase Contrast variants after
the device check. Fits port step 11 (cleanup) or a small plan.
