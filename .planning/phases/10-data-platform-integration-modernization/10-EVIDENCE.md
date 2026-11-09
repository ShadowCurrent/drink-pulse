# Phase 10 Evidence

Evidence for plan 10-11 (MOD-03, DATA-01 shipped-schema guard, INT-02 CloudKit-off). Captured on 2026-11-09 at base commit `5044cfd` (Phase 10 code complete through plan 10-10).

## Toolchain and destination

- **Xcode:** 27.2, build version 27B52. **Swift:** 6.4.2 (`swiftlang-6.4.2.1.9`), language mode `SWIFT_VERSION = 6.0` for the app and test targets. **SDK:** iphonesimulator 27.2.
- **Destination:** iPhone 17 simulator, iOS 27.2 runtime (`com.apple.CoreSimulator.SimRuntime.iOS-27-2`), booted before every run. The simulator identifier is machine-specific and is deliberately not recorded as a general destination.
- **Simulator isolation:** the orchestrator ran this plan as the only executor and supplied one pre-existing iOS 27.2 simulator, so no clone was created and none needs deleting; the plan's `LOCAL_IOS_27_UDID_P10_11` variable pointed at that supplied simulator.
- **Apple tooling route:** `xcodebuild` and `simctl` CLI fallback for every step. The Xcode MCP server acts on the main workspace rather than this worktree and the `DocumentationSearch` tool is not exposed to this executor, so the CLI was the only route that builds and tests the worktree and produces the logs the gates read.
- **Official source for the sanitizer flag:** the `xcodebuild -help` output shipped with Xcode 27.2 lists `-enableThreadSanitizer YES|NO  turn the thread sanitizer on or off`. Apple online documentation was not re-read in this session.
- **Commands:** the exact command lines are in the sections below. Derived data paths are `build/p10-11-tsan`, `build/p10-gate` and `build/p10-full` (all gitignored).

## Thread Sanitizer

### Canary (activation proof, D-10 trigger 2, research assumption A6)

- **Command:** a temporary `drinkpulseTests/Services/TSanCanaryTests.swift` containing one `nonisolated` Swift Testing test that increments a `nonisolated(unsafe)` file-scope integer from `DispatchQueue.concurrentPerform(iterations: 4000)` was written, then run with `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=<udid>" -derivedDataPath build/p10-11-tsan -enableThreadSanitizer YES -only-testing:drinkpulseTests/TSanCanaryTests`, log `build/p10-11-canary.log`, exit status `build/p10-11-canary.exit`. The file was deleted by the same script immediately after the run.
- **Result:** the fresh log contains `WARNING: ThreadSanitizer: Swift access race` with the location `global 'drinkpulseTests.tsanCanaryCounter : Swift.Int'` and a `SUMMARY: ThreadSanitizer: Swift access race` line, and the run ended `** TEST FAILED **`. The recorded exit status is 65. Activation of the sanitizer under `-enableThreadSanitizer YES` is therefore proven in this run, on this toolchain.
- **Pattern correction:** the plan's gate pattern was `ThreadSanitizer: data race|Data race detected`. The Swift report string is `Swift access race`, so that pattern did not match the first canary check and would also have made the later no-race check vacuous (it could never fire on a Swift race). Both checks in this run use the broader pattern `ThreadSanitizer`, which matches every sanitizer report line.
- **Cleanup:** `drinkpulseTests/Services/TSanCanaryTests.swift` does not exist on disk and was never tracked or committed (`git status --short` clean after the run).

### Scoped pass over the final Phase 10 code

- **Command:** `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=<udid>" -derivedDataPath build/p10-11-tsan -enableThreadSanitizer YES` plus one `-only-testing:drinkpulseTests/<Suite>` word per suite; log `build/p10-11-tsan.log`.
- **Suites (21):** HealthServiceTests, HealthServiceRemoveSampleTests, HealthServiceConcurrencyTests, HealthServiceOrderingTests, HealthWriteHooksTests, ReminderServiceTests, ReminderServiceCancellationTests, WeeklySummaryServiceTests, WeeklySummaryServiceScheduleTests, WeeklySummaryServiceCancellationTests, WeeklySummaryCompletedWeekTests, WeeklySummaryCopyTests, NotificationOptOutTests, NotificationActionHandlerTests, MigrationTests, MigrationChainV1Tests, MigrationChainV2V3Tests, MigrationSweepTests, StoreBootstrapTests, RecordDeduplicatorTests, SanitizedBackupFixtureTests.
- **Result:** exit 0, `** TEST SUCCEEDED **`, `Test run with 144 tests in 21 suites passed after 2.934 seconds`. The only line in the log that mentions `ThreadSanitizer` is the echoed command line containing the flag; there is no sanitizer report. Because activation was proven by the canary above, this counts as retain evidence for C010, C011 and C012.

## Zero-warning build

Recorded in Task 3.

## Shipped schema and CloudKit guards

Recorded in Task 3.

## File size

Recorded in Task 3.

## Scoped Phase 10 suites

Recorded in Task 3.

## Full suite

Recorded in Task 3.

## Coverage

Recorded in Task 3.

## C008 disposition

Recorded in Task 2.

## C009 disposition

Recorded in Task 2.
