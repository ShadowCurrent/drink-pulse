---
created: 2026-11-14T20:30:00.000Z
title: Fix accessibility audit findings (311 open from Phase 11)
area: general
severity: major
files:
  - drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift
  - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
  - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
---

## Problem

The Phase 11 automated accessibility audit (`performAccessibilityAudit(for: .all)`, 16 methods over Home, Insights, History, Settings, Add Drink and Onboarding) found 311 distinct open issues (385 reports) on the iOS 27.2 simulator: contrast 144, dynamicType 73, textClipped 57, sufficientElementDescription 21, hitRegion 16. By owner decision D11-22 (2026-11-14) they are recorded as open VER-03 findings; none is fixed or allow-listed in Phase 11.

The findings are grouped by probable root cause in `A11Y-AUDIT-G01` to `A11Y-AUDIT-G09` (ledger section "Accessibility audit allow-list (filled by plan 11-03)" in `.planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md`). The counts, the per-screen table and the digests of the out-of-git result files are in `11-EVIDENCE.md`, section "Accessibility audit (exploratory run, D11-22)". The group assignment is a hypothesis from element names, not a diagnosis.

## Solution

Work group by group. Each fix needs an owner D-09 brief first (accessibility is a D-09 trigger); do not start a fix without one. Consult Apple documentation and Xcode MCP first. Suggested order by user impact: G01 (Add Drink tiles, 111 keys), G03 and G04 (Home and Insights cards), G05 (chart marks: accessibility labels and the chart descriptor), then G06, G07, G02. G08 is probably an artifact of the test-only `dp_health_sample_count` overlay and may need a test-side change only; G09 first needs the unlabelled element located.

Rerun the audit to check a fix: set `TEST_RUNNER_DP_RUN_A11Y_AUDIT=1` in the test runner environment (the class skips by default, same pattern as `DP_RUN_FLASH_HARNESS`) and run `drinkpulseUITests/AccessibilityAuditUITests` through Xcode MCP `RunSomeTests`. With the flag set every reported issue fails its method; there is no allow-list. Remove the gate when all findings are fixed or explicitly accepted by the owner. The audit does not cover Increase Contrast or Reduce Motion (human-only) and covers only the launch viewport of each screen.
