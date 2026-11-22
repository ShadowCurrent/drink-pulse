---
created: 2026-11-22T10:06:11.763Z
title: Localize element-less contrast and History audit findings
area: testing
severity: major
files:
  - drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift
  - drinkpulseUITests/Features/Insights/InsightsAccessibilityAuditUITests.swift
  - drinkpulseUITests/Features/History/HistoryAccessibilityAuditUITests.swift
---

## Problem

Audit findings are ignored or unexplained:
- Element-less `contrast` on Insights (standard 4, dark 1) and Today dark over limit (1), ignored
  under D11-31 (`ignoreTabBarElementlessContrast`); bisection in plan 0046 Task 7 did not
  localize them. The exemption now covers two more screens than before (R17).
- History (plan 0045): `test_historyCalendar_standard_hasNoAuditIssues` `dynamicType` on the
  calendar mode's day header / row texts (suspected `UICalendarView` relayout artifact);
  `test_historySearch_active_ax5_hasNoAuditIssues` `contrast` on "Check the spelling or try a new
  search." (suspected keyboard overlap).

## Solution

Accessibility Inspector on device / simulator for each; fix at the source if real, else an
owner decision with an id. Narrow D11-31 back if the cause is found. Source: open-questions
"Plan 0046 open items", "History audit findings after the port (plan 0045)".
