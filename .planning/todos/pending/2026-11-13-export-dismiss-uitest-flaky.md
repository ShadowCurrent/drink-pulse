---
created: 2026-11-13T18:50:00.000Z
title: Stabilize flaky Export dismiss UI test (save panel did not present)
area: testing
severity: minor
files:
  - drinkpulseUITests/Features/Settings/ExportUITests.swift
audit_acknowledged:
  milestone: v1.4
  at: 2026-11-18
---

## Problem

`ExportUITests/test_export_dismissWithoutSaving_showsNoFailureAlert` failed in the Phase 09
closing full-suite run (Xcode MCP RunAllTests, 2026-11-13 19:04, 821/826 passed):

```
ExportUITests.swift:47 XCTAssertTrue failed - Save panel should present before dismissal
```

Phase 10 already recorded it as a single-run flake that passed on re-run
(`10-VERIFICATION.md`, `10-13-SUMMARY.md`, `10-14-SUMMARY.md`). The test waits on the system
save panel, a separate system process whose presentation time varies on the simulator.

## Owner decision

2026-11-13: record as a known flake in this todo without a re-run ("Od razu todo").

## Suggested approach

Check how the test waits for the save panel (timeout and the element it queries). Match the
panel by a stable identifier or element type, never by a localized label (the simulator system
locale is Polish). Raise the wait if needed, then confirm stability with several consecutive runs.
