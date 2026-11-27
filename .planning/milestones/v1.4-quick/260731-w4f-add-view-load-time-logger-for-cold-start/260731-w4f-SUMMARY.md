---
status: complete
task: 260731-w4f-add-view-load-time-logger-for-cold-start
completed: 2026-07-31
commits:
  - dd3ace1 Add ViewLoadLogger diagnostics helper for view-load timing
  - d863b17 Wire view-load-time marks into cold start and tab switches
---

# Summary: Add view-load-time logger for cold start and tab switches

## What was built

A dev-diagnostics view-load-time logger, so that running the app from Xcode
(physical device or simulator) shows how long each top-level tab view
(Dashboard, Insights, History, Settings) takes to become visible — both on
cold launch and on every subsequent tab switch. Previously there was zero
timing visibility into view loads.

### Task 1 — `ViewLoadLogger` diagnostics helper + unit test

- `drinkpulse/Diagnostics/ViewLoadLogger.swift` (new `Diagnostics/` folder,
  sibling to `Domain/`, `Services/`, `DesignSystem/`):
  - `@MainActor enum ViewLoadLogger` (entirely `#if DEBUG`-gated): an
    `os.Logger` (subsystem `com.drinkpulse.app`, category `performance`) +
    an `OSSignposter` for Instruments' Points of Interest track.
    `markNavigationRequested()` records a start timestamp + begins a
    signpost interval (ending any unconsumed prior one first, so a rapid
    double-navigation never leaks an interval). `logAppear(_ viewName:)`
    ends the signpost interval, computes elapsed milliseconds, logs
    `"View '<name>' appeared in <ms> ms"`, and clears the pending mark.
  - `nonisolated static func milliseconds(_ duration: Duration) -> Int64`:
    the pure whole-millisecond truncation helper, kept `nonisolated` so it
    is callable from a plain (non-actor) test context.
  - Always-compiled thin surface: `enum ViewLoadNavigation` (`markRequested()`,
    `@MainActor`-isolated, a true no-op outside DEBUG) and
    `View.dp_logViewLoad(_:)` (returns `self` unmodified in Release).
  - `drinkpulseTests/Diagnostics/ViewLoadLoggerTests.swift`: 4 Swift Testing
    cases for `milliseconds` — whole second → 1000, whole milliseconds →
    exact count, zero → 0, sub-millisecond truncates down to 0. Confirmed
    the test failed to compile before the type existed (TDD), then passed
    after implementation.

### Task 2 — Wired the two reference points + the four call sites

- `drinkpulse/drinkpulseApp.swift`: `ViewLoadNavigation.markRequested()`
  added immediately after both `containerState = .ready(...)` assignments
  in `loadContainerIfNeeded()` (the `UITestSeed.isActive` branch and the
  production branch) — never in the `catch` branches.
- `drinkpulse/Features/Shell/RootShellView.swift`: new
  `.onChange(of: selectedTab) { _, _ in ViewLoadNavigation.markRequested() }`,
  kept as its own modifier (not merged with `.onChange(of: scenePhase)`).
- `.dp_logViewLoad("<Name>")` appended as the trailing modifier on each of
  the four top-level views: `DashboardView`, `InsightsView`, `HistoryView`,
  `SettingsView` (outer struct, not the inner `SettingsForm`).

## Verification

- `xcodebuild build` (Debug, iPhone 17 Pro simulator): clean, zero warnings.
- `xcodebuild build -configuration Release` (iPhone 17 Pro simulator):
  succeeds, confirming the `#if DEBUG` gate compiles out cleanly with no
  reachable `Logger`/`OSSignposter` call for this feature.
- Full `xcodebuild test` suite: **TEST SUCCEEDED**, 0 failures (unit suite +
  75 UI tests, including the 4 new `ViewLoadLoggerTests` cases).
- File size: both new files (80 + 28 lines) and all six modified files
  (117–264 lines) stay well under the 300-line ceiling.
- No PII/health data logged — only the four static view-name strings and
  integer millisecond durations.
- Cold-launch/tab-switch runtime behavior was verified by code-inspection
  of the call-site ordering (container-ready → mark → `RootShellView`/
  `DashboardView` construction; `selectedTab` change → mark → destination
  tab's `.onAppear`); no physical-device/simulator Console capture was
  performed in this session (per the plan's own fallback note).

## Deviations from plan

- The plan's sketch for `ViewLoadNavigation.markRequested()` and
  `View.dp_logViewLoad(_:)` showed a plain (non-isolated) wrapper calling
  into the `@MainActor`-isolated `ViewLoadLogger` directly. Under Swift 6
  strict concurrency this doesn't compile (a nonisolated function cannot
  synchronously call a MainActor-isolated one). Fixed by marking
  `ViewLoadNavigation.markRequested()` itself `@MainActor` — every call site
  (`.onAppear`, `.onChange`, the `containerState` mutation) already runs on
  the main actor, so this adds no new isolation requirement and — critically
  — keeps the mark synchronous rather than deferring it via `Task`, which
  would have reintroduced the very ordering race (child `.onAppear` firing
  before the mark is set) the plan's design was built to avoid.
- `ViewLoadLogger.milliseconds(_:)` is `nonisolated` (plan said "internal, not
  private" but didn't specify isolation) so the test target can call it
  without hopping to the main actor — it touches no actor-isolated state.

## Non-goals honored

No UI screen/toggle for viewing the logs (Console/Instruments only), no
instrumentation beyond the four top-level tab views, no BAC/guideline/sync
logic touched, no SwiftData schema change, no UI test (no user-visible
screen or control — this feature is dev-diagnostics only).

## Docs

`docs/DEVLOG.md` and `docs/architecture.md` (new `Diagnostics/` folder
listed in the folder-layout diagram) were updated but left **uncommitted**
in the working tree — per the quick-task contract, docs commits are handled
by the orchestrator, not bundled into the code commits above.
