---
created: 2026-11-22T10:06:11.763Z
title: Split test files over 300 lines
area: testing
severity: cosmetic
files:
  - drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift
  - drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Metrics.swift
  - drinkpulseTests/Services/HealthServiceTests.swift
---

## Problem

Three test files exceed the 300-line ceiling: `InsightsViewModelTests+Aggregates.swift` 335,
`DashboardViewModelTests+Metrics.swift` 327, `HealthServiceTests.swift` 302. The enforced find
command covers only `drinkpulse/`, so they were never flagged.

## Solution

Split by responsibility into `+Name.swift` extensions; optionally widen the find command to the
test targets. After the revamp.
