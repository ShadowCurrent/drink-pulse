---
created: 2026-11-14T20:30:00.000Z
title: Fix accessibility audit findings (385 reports, 311 byte-wise distinct keys, exploratory record corrected)
area: general
severity: major
files:
  - drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift
  - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
  - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
---

## Problem

The Phase 11 automated accessibility audit (`performAccessibilityAudit(for: .all)`, 16 methods over Home, Insights, History, Settings, Add Drink and Onboarding) found 385 reports, 311 byte-wise distinct keys (exploratory record, corrected) on the iOS 27.2 simulator (9 of the 16 rows ran in dark appearance and are unreliable; a refreshed baseline follows in plan 11-13): contrast 144, dynamicType 73, textClipped 57, sufficientElementDescription 21, hitRegion 16. By owner decision D11-22 (2026-11-14) they are recorded as open VER-03 findings; none is fixed or allow-listed in Phase 11.

The findings are grouped by probable root cause in `A11Y-AUDIT-G01` to `A11Y-AUDIT-G09` (ledger section "Accessibility audit allow-list (filled by plan 11-03)" in `.planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md`). The counts, the per-screen table and the digests of the out-of-git result files are in `11-EVIDENCE.md`, section "Accessibility audit (exploratory run, D11-22)". The group assignment is a hypothesis from element names, not a diagnosis.

## Review follow-through

Code review findings WR-01 (the harness kept auditing after a failed navigation) and WR-02 (appearance was pinned only for the dark variant, so one failed restore leaked dark into later rows) are fixed by plan 11-12: the harness now stops when navigation to the screen fails and pins the simulator appearance for every variant with a teardown registered first. Unlabeled elements now carry their element type and rounded frame in the key (`none#type=<type>@x,y,w,h`), so group G09 can be located.

## Decisions

D11-25 (owner decision 2026-11-16): all groups A11Y-AUDIT-G01 to G09 are to be fixed, split by screen, each user-facing fix with a UI test. D11-26 (owner decision 2026-11-16): the audit runs through the Xcode scheme Test-action environment variable `DP_RUN_A11Y_AUDIT=1` with Xcode MCP `RunSomeTests`, not the CLI.

## Solution

Work group by group. Each fix needs an owner D-09 brief first (accessibility is a D-09 trigger); do not start a fix without one. Consult Apple documentation and Xcode MCP first. Suggested order by user impact: G01 (Add Drink tiles, 111 keys), G03 and G04 (Home and Insights cards), G05 (chart marks: accessibility labels and the chart descriptor), then G06, G07, G02. G08 is probably an artifact of the test-only `dp_health_sample_count` overlay and may need a test-side change only; G09 first needs the unlabelled element located.

Rerun the audit to check a fix: set `TEST_RUNNER_DP_RUN_A11Y_AUDIT=1` in the test runner environment (the class skips by default, same pattern as `DP_RUN_FLASH_HARNESS`) and run `drinkpulseUITests/AccessibilityAuditUITests` through Xcode MCP `RunSomeTests`. With the flag set every reported issue fails its method; there is no allow-list. Remove the gate when all findings are fixed or explicitly accepted by the owner. The audit does not cover Increase Contrast or Reduce Motion (human-only) and covers only the launch viewport of each screen.

## Resolution (2026-11-18, plan 11-24)

Closed: the gated audit class `AccessibilityAuditUITests` passed 16 of 16 (plan 11-22). Groups A11Y-AUDIT-G01 to G09 were fixed by plans 11-14 to 11-21 under owner decisions D11-25 to D11-31 (Add Drink G01 and G02 in plan 11-18, Home G03 in 11-17, Insights G04 and G05 in 11-19, Settings G06 and G09 in 11-20, Onboarding G07 and History G09 in 11-21, the test hook G08 in 11-15); no allow-list was used. Residuals that stay open and are tracked elsewhere: the Insights day-mark hit-region part of G05 (narrow exemption D11-30), the Add Drink step 2 Form controls at AX5 (D11-28, DL-O17) and the placeholders DL-O19. Evidence: `11-EVIDENCE.md`, sections "Accessibility audit (final gated re-run, plan 11-22)" and "Gap closure (plans 11-12 to 11-24)".
