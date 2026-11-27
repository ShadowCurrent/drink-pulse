---
created: 2026-11-22T10:06:11.763Z
title: Pin missing Today / Insights review tests
area: testing
severity: minor
files:
  - drinkpulseUITests/Features/Dashboard/DashboardOverLimitAccessibilityAuditUITests.swift
  - drinkpulse/Features/Insights/Components/InsightsHeroCard.swift:56-57
  - drinkpulseUITests/Features/Dashboard/DashboardUITests.swift
---

## Problem

Plan 0046 final review minors M1, M2, M8: code is right, tests are missing or weak.
- M1 Review focus 1 reverse: over the daily but under the weekly limit shows no alert;
  `DashboardOverLimitAccessibilityAuditUITests` reaches the state but never asserts
  `today.alert` is absent.
- M2 Review focus 4: selection is cleared on period change (`InsightsHeroCard.swift:56-57`); no
  test switches period after a scrub.
- M8 `DashboardUITests` drinks tile asserts `label.contains("1")` (also passes "10").

## Solution

M1: one `XCTAssertFalse(alert.exists)`. M2: UI test scrub → Month → `insights.hero.selectedDate`
gone. M8: match the exact value. Fits port step 8 (full suite).
