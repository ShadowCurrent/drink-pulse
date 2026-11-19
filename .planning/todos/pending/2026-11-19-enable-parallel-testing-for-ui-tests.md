---
created: 2026-11-19T10:44:31.502Z
title: Enable parallel testing for UI tests
area: testing
severity: minor
files:
  - drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme:44-66
  - drinkpulse/UITestSeed.swift:76
  - drinkpulseUITests/
---

## Problem

The full test suite takes ~25 min, and UI tests are most of that time. Every UI
test relaunches the app. That is correct and must stay: each relaunch gives a
fresh in-memory store under `-dp_uitest` (`UITestSeed.swift:76`), applies
per-test launch args, and keeps tests independent of order. But 158 tests run
serially, with ~2–4 s per launch.

Current scheme state: no parallelism anywhere. `drinkpulseTests` has an explicit
`parallelizable = "NO"`. `drinkpulseUITests` has no attribute, so it defaults to
NO. There is no test plan (`shouldAutocreateTestPlan = "YES"`).

Note: the many `timeout: 5` values are `waitForExistence` upper bounds, not
sleeps. Lowering them does not speed up green runs. It only adds flakiness.

## Solution

Enable XCTest parallel testing (simulator clones) for `drinkpulseUITests` only.
Keep unit tests serial: the gain there is small, and the existing NO may be
intentional.

- No test rewrite needed. Tests are already isolated.
- XCTest distributes work across clones per class, not per method. There are
  59 UI test files.
- Machine has 8 cores and 16 GB RAM. Cap at 2–3 clones. Expect ~1.8–2.5x on the
  UI portion.

Steps:
1. Measure a baseline: full UI suite wall time today.
2. Set `parallelizable` for `drinkpulseUITests` only and cap the worker count.
   Candidate flags are `-parallel-testing-worker-count` and
   `-maximum-concurrent-test-simulator-destinations`, or the equivalent test plan
   setting. Verify the flags in the local `man xcodebuild`: Apple
   DocumentationSearch did not return the XCTest parallel-clone page, only the
   Swift Testing in-process parallelization docs. The config must live in the
   project (scheme or test plan), not only as a CLI flag, because Xcode MCP
   `RunAllTests` / `RunSomeTests` use the scheme or test plan.
3. Run the full suite 2–3 times. Compare wall time and flakes.
4. Keep the change only if it stays green. Log it in DEVLOG.

Risks:
- Tight timeouts may flake under load: 8x `timeout: 2`, 5 negative
  `XCTAssertFalse(x.waitForExistence(...))` asserts, and `usleep` polling loops.
  Some timeouts may need raising.
- The longest class bounds wall time. Large classes (for example the
  accessibility audits) may need splitting.
- Hidden order or simulator-state dependencies may surface: notification and
  Health permissions, and the PL system locale.
- Logs and xcresult are split across clones, which makes debugging harder.

Related quick win (independent): 15x `if !x.waitForExistence(timeout: 3/5) { swipeUp() }`
and 5 negative asserts always wait the full timeout on the passing path
(~30–60 s total). Candidates are `ExportUITests.swift:52`,
`GuidelinePickerUITests.swift:89`, `ReminderSettingsUITests.swift:39`,
`EditDeleteConfirmationUITests.swift:139` and `EditVolumeIntegrityUITests.swift:42`.
Shortening a negative assert weakens the regression check, so do it carefully.
