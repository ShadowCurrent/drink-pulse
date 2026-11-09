---
phase: 10-data-platform-integration-modernization
plan: "09"
subsystem: notifications
tags: [swift-concurrency, mainactor, usernotifications, tdd, sendable]
requires:
  - phase: 10-data-platform-integration-modernization
    provides: "10-06 F3 pins, SlowNotificationCenter and 10-DECISION-F3.md; 10-02/10-04 service edits; 10-07 opt-out pins"
provides:
  - "ReminderService and WeeklySummaryService lifecycle/cancel epoch (F3 fix)"
  - "Both F3 pins are plain regression tests; supersession tests added"
  - "NotificationActionHandler plain Sendable (O1)"
affects: [10-11 concurrency candidate records]
status: complete
plan_head_before: 67514a19250f8db9e8c9359a88c8f9aabd8e272a
plan_head_after: cf9ac90 (task commits only; the SUMMARY commit follows)
actuals:
  tokens: 6000
  tasks: 3
  commits: 2
tech-stack:
  added: []
  patterns: ["Private lifecycleEpoch + cancelEpoch counters on a @MainActor service; post-await check removes own request only when the latest lifecycle event is a later cancel"]
key-files:
  created: []
  modified:
    - drinkpulse/Services/ReminderService.swift
    - drinkpulse/Services/WeeklySummaryService.swift
    - drinkpulse/Services/NotificationActionHandler.swift
    - drinkpulseTests/Services/ReminderServiceCancellationTests.swift
    - drinkpulseTests/Services/WeeklySummaryServiceCancellationTests.swift
    - .planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md
key-decisions:
  - "Applied owner outcome fix-service-epoch+handler-sendable: S1, S2, O1 applied; S3 not applied"
requirements-completed: [INT-01, MOD-03]
---

# Phase 10 Plan 09: F3 cancel epoch Summary

Service-level lifecycle/cancel epoch in ReminderService and WeeklySummaryService so a cancel issued during an in-flight `add` wins, without a later schedule's request being removed.

## Owner decision applied

10-DECISION-F3.md Outcome: `fix-service-epoch+handler-sendable` (2026-11-09). S1 applied, S2 applied, S3 not applied, O1 approved. The record's exact scope matched the plan defaults; no scope difference. The record was written by the orchestrator at the owner's direction (see the dispatch note); applied as recorded.

## What changed

- **ReminderService / WeeklySummaryService:** private `lifecycleEpoch` (advanced by every schedule and cancel) and `cancelEpoch` (lifecycle value at the latest cancel). A schedule keeps its own epoch value, then after `add` returns removes its own identifier only when `cancelEpoch == lifecycleEpoch && cancelEpoch > kept`. In the weekly service the skip-content branch calls `cancel()`, so it counts as a cancel; the epoch increment sits right before remove-then-add (after the opt-in guard, content computation and skip branch). Add errors propagate (reminder) or are logged and swallowed (weekly) as before.
- **Tests:** both pin wrappers (`withKnownIssue`) removed. Reminder: added cancel-then-schedule supersession (Test 4), schedule-then-schedule supersession (Test 5), uncontested schedule leaves request pending (Test 3). Weekly: added supersession test (Test 4), twice-idempotent (Test 2), cancel-then-fresh-schedule (Test 3).
- **O1:** `NotificationActionHandler` is now `NSObject, UNUserNotificationCenterDelegate, Sendable`. No new warning; concurrency record row updated.
- **S3:** not applied. `ReminderSection.swift` untouched (no `toggleGeneration`).

## Isolation and lifecycle reasoning

Both services are `@MainActor`. Reentrancy occurs only at the `await` inside `center.add`. `cancel()` and the epoch increments run synchronously on the same actor, so the post-add comparison cannot race. A schedule superseded by a later schedule sees `cancelEpoch != lifecycleEpoch` and removes nothing, so the later call owns the identifier. With no cancel during `add`, `cancelEpoch` stays at or below the kept value and the new code is a no-op, so uncontested behavior is unchanged. An epoch advanced only by cancel would let a stale schedule remove a later schedule's request (Test 4 would fail: cancelEpoch 1 > kept 0 leads to a removal after the first add).

## Official source and availability

The source is the one recorded in 10-DECISION-F3.md: the iPhoneOS 27.2 SDK header `UNUserNotificationCenter.h` (add replaces same identifier; remove clears pending) and Swift actor reentrancy guidance (C011/C012 records). I did not independently re-run Xcode MCP DocumentationSearch; the Xcode MCP server was not used in this worktree run. All APIs used are current at the iOS 27 minimum; no deprecation claimed.

## Tooling route

CLI fallback (`xcodebuild`) for every build and test: Xcode MCP acts on the main workspace, not this worktree. Assigned simulator `B4A1A1F8-A0E2-4186-BAFD-1A02679DD4EC` was used (the plan's `LOCAL_IOS_27_UDID_P10_09` and `build/p10-09` were replaced by the orchestrator's assignment and worktree-local `build/`); it was shut down at the end.

## Regression evidence

- RED (before service change): reminder pin failed with `Expectation failed: pending.isEmpty`; weekly pin failed identically. The other new tests passed pre-change.
- Task 1 run: ReminderServiceCancellationTests + ReminderServiceTests + NotificationOptOutTests, 22 tests in 3 suites passed.
- Task 2 run: weekly cancellation/service/schedule/completed-week, reminder cancellation, opt-out, handler suites, 43 tests in 7 suites passed. No Swift warnings in changed files. `WeeklySummaryCalculator.swift` unchanged versus `fbd37fa`.
- Task 3 (UI, S3 not applied): ReminderSettingsUITests, WeeklySummarySettingsUITests, OnboardingWeeklySummaryUITests, WeeklySummaryTapUITests, 7 tests, 0 failures. `ReminderSettingsUITests.test_reminderToggle_revealsAndHidesTimeRow` passed (20.5s). Under the recorded outcome S3 does not apply, so the race S3 guards (toggle-off during the permission prompt) is not exercised; it is not reproducible in a UI test because the prompt is modal and the UI-test center answers instantly.

## Deviations from Plan

- Simulator, derived data path and worktree were the orchestrator-assigned ones, not the plan's `p10-09` clones.
- Task 3 had no edit; only the UI regression run was performed.
- Did not run the plan's python outcome-consistency check or the greps against `build/p10-09-t*.log` literally; verified equivalent state by hand (wrappers absent, epochs present, `toggleGeneration` absent, handler qualifier gone).

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

Files present: ReminderService.swift, WeeklySummaryService.swift, NotificationActionHandler.swift, both cancellation test files, 10-CONCURRENCY-RECORD.md. Commits 3e9a8b2 and cf9ac90 are on the branch.
