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

- **Date:** 2026-11-09. **Command:** `xcodebuild clean build-for-testing -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=<udid>" -derivedDataPath build/p10-gate`, log `build/p10-11-gate-build.log` (whole project: app, `drinkpulseTests` and `drinkpulseUITests`).
- **Result:** exit 0, `** TEST BUILD SUCCEEDED **`. The pattern `(\\.swift:[0-9]+:[0-9]+: |ld: |clang: )warning:` matches 0 lines. The only `warning:` text in the log is three `appintentsmetadataprocessor ... warning: Metadata extraction skipped, no AppIntents.framework dependency found` tool notes (the app does not use App Intents); they are not Swift, linker or compiler warnings, and the plan gate pattern excludes them. The baseline warning in `HealthWriteHooksTests.swift` is gone (removed by plan 10-07).

## Shipped schema and CloudKit guards

- `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift drinkpulse/drinkpulseApp.swift drinkpulse/Domain/WeeklySummaryCalculator.swift drinkpulse/Domain/DataTransfer` exits 0: `SchemaV1` to `SchemaV4`, `MigrationPlan`, `drinkpulseApp.swift` (delegate assignment timing), `WeeklySummaryCalculator` and the DataTransfer folder are unchanged against the phase baseline `fbd37fa`.
- `drinkpulse/drinkpulse.entitlements` holds only `com.apple.developer.healthkit` and `com.apple.developer.healthkit.access`; `grep -qi icloud` finds nothing (exit 1), so there is no cloud-container entitlement.
- `grep -rq --include='*.swift' cloudKitDatabase drinkpulse` finds nothing (exit 1), so no Swift source references the SwiftData CloudKit-database configuration option.
- The production `ModelConfiguration` in `StoreBootstrap.productionConfiguration` is `ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)`; `git diff fbd37fa` of `StoreBootstrap.swift` touches no `ModelConfiguration` construction (the only change is the recovery-reporting seam). CloudKit stays disabled (D-19, ADR-0010).

## File size

`find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" | xargs wc -l | awk '$1 > 300 && $2 != "total" {print}'` reports nothing. The largest Swift file under `drinkpulse` is `Features/History/HistoryView.swift` at 263 lines. No coverage-remediation test file was created.

## Scoped Phase 10 suites

The 21 Phase 10 Services, Persistence and DataTransfer suites ran twice: scoped under Thread Sanitizer (section Thread Sanitizer: 144 tests in 21 suites passed) and inside the unfiltered full suite below, where every one of them is included.

## Full suite

- **Date:** 2026-11-09. **Command:** `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=<udid>" -derivedDataPath build/p10-full -resultBundlePath build/p10-full.xcresult -enableCodeCoverage YES -collect-test-diagnostics never`, run as a detached background job writing `build/p10-11-full.log` and `build/p10-11-full.exit` (the destination is the iPhone 17 simulator on iOS 27.2 named in Toolchain and destination).
- **Result:** `build/p10-11-full.exit` is `0`, `** TEST SUCCEEDED **`. Unit: `Test run with 678 tests in 59 suites passed after 2.897 seconds`. UI: `Executed 93 tests, with 0 failures (0 unexpected) in 1714.111 seconds`. Result bundle `build/p10-full.xcresult` present (gitignored).

## Coverage

Source: `xcrun xccov view --report --json build/p10-full.xcresult > build/p10-11-coverage.json` (gitignored), read by a gate script that applies the plan's assertions unchanged but prints every measurement before reporting failures. Result: **GATE FAILS: none**.

1. **Overall:** `drinkpulse.app` line coverage **94.61 percent** (requirement at least 90 percent).
2. **Domain (owner waiver D-20, 2026-11-08, recorded in `10-CONTEXT.md`):** the only file under `drinkpulse/Domain` changed in this phase (`git diff --name-only fbd37fa -- drinkpulse/Domain`) is `Domain/Persistence/StoreBootstrap.swift`, which is excluded as SwiftData persistence internals (an AGENTS.md exclusion); its value is recorded: **96.1 percent**. The set of changed non-Persistence Domain files is empty, so the 100 percent changed-Domain gate is vacuous. Recorded as information, not gated: Domain aggregate (non-Persistence) **90.06 percent**; non-Persistence Domain files below 100 percent: `BackupDocument.swift` 66.7, `BackupExport.swift` 72.2, `ConsumptionEvent.swift` 82.8, `Currency.swift` 92.3, `DataImporter.swift` 94.8, `DrinkControlImporter.swift` 95.7, `DrinkTemplate.swift` 46.0, `TemplateRecord.swift` 64.1. Persistence files: `RecordDeduplicator.swift` 89.5, `UserProfileStore.swift` 96.2, `StoreBootstrap.swift` 96.1, `MigrationPlan.swift` and `SchemaV1` to `SchemaV4` 100. This pre-existing Domain gap stays open and tracked in `.planning/WINDOWS.md` row 7 (and row 1) per D-20 for a separate gap-closure task; `WINDOWS.md` was not edited and the gap is not described as closed or waived.
3. **Services (at least 85 percent):** gated changed testable Services files: `HealthService.swift` **100**, `ReminderService.swift` **100**, `WeeklySummaryService.swift` **95.1**, and `UITestNotificationCenter.swift` **93.8** (changed in this phase, measured, not excluded). Measured but unchanged: `UITestHealthStore.swift` **100**, `HealthWriteHooks.swift` **100**. `NotificationActionHandler.route(identifier:defaults:)` **100** (the function and both closures); the file as a whole is 76.0 percent because the `didReceive` and `willPresent` delegate callbacks cannot be exercised (a `UNNotificationResponse` has no public initializer), so they are excluded as thin framework adapters. **Services aggregate 98.33 percent.** No remediation test file was needed (no named Services file was below target).
4. **Excluded from the Services denominator, values recorded, not gated:** `HealthKitAdapter.swift` 20.4 percent and `NotificationScheduling.swift` 0 percent (HealthKit and UserNotifications framework wrappers, the AGENTS.md thin-framework-adapter exclusion); `HealthServiceEnvironment.swift` and `HealthWriting.swift` (an environment key and protocol declarations with no executable behavior, the AGENTS.md app-level wiring exclusion) carry no executable lines in the report.

## C008 disposition

### Candidate scope

VersionedSchema and migration-plan replacement boundary (`08-DECISION-C008.md`): the V1 to V4 `MigrationPlan` and its frozen `SchemaV1` to `SchemaV4` snapshots, where ADR-0009 requires shipped snapshots to stay immutable.

### Evidence checked

From the plan 10-01 summary: the V1, V2 and V3 to V4 every-field chain proofs (`MigrationChainV1Tests`, `MigrationChainV2V3Tests`), which open each legacy store through the new `StoreBootstrap.makeContainerReportingRecovery` seam and assert `didRecover == false` (no silent move-aside) before checking every stored property; the corrupted-store control that proves `didRecover` can report `true`; the launch dedup sweep proofs over migrated legacy stores (`MigrationSweepTests`); and the existing `MigrationTests`, `StoreBootstrapTests` and `RecordDeduplicatorTests` re-run on iOS 27. These suites also ran under the sanitizer (section Thread Sanitizer: 144 tests in 21 suites, no report) and in the full suite (section Full suite). The shipped-schema guard: `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` exits 0, so `SchemaV1` to `SchemaV4` and `MigrationPlan` are unchanged against the phase baseline (also re-run in section Shipped schema and CloudKit guards). No migration defect was found.

### Official source consulted

As recorded in the plan 10-01 summary: no new Apple API was introduced (`Schema(versionedSchema:)`, `ModelContainer(for:migrationPlan:configurations:)`, `FileHandle` and `FetchDescriptor` were already used), and behavior was verified by test runs. Xcode MCP `DocumentationSearch` was unavailable in that session and in this one, so no documentation lookup ran; ADR-0009 and ADR-0010 are the project sources. No replacement or deprecation is claimed.

### Regression evidence

`MigrationChainV1Tests` (4 tests), `MigrationChainV2V3Tests` (3 tests including `corruptedStore_reportsRecoveryAndOpensFresh`), `MigrationSweepTests` (5 tests), `MigrationTests`, `StoreBootstrapTests` and `RecordDeduplicatorTests`. Plan 10-01 recorded 34 tests in 7 suites passing.

### Device proofs

The current-store proof (D-05) and the interrupted-migration risk R-01 are device checks owned by plan 10-12 and recorded in `10-DEVICE-SESSION.md`. This disposition covers the automated evidence and stays final unless that session records a FAIL, in which case plan 10-12 writes a brief (D-06).

Disposition: retain. The migration plan and schemas are unchanged; the only production change (the recovery-reporting seam) is a behavior-preserving refactor of `makeContainer`.

## C009 disposition

### Candidate scope

Backup export and import representation boundary (`08-DECISION-C009.md`): the v2 export format and importer under `drinkpulse/Domain/DataTransfer`, kept compatible with real exports.

### Evidence checked

From the plan 10-03 summary: the `BackupFixtureLoader` mechanism, the synthetic probe `probe-export-v2.json`, and the owner-approved sanitized real-shape fixture `drinkpulseTests/Domain/DataTransfer/Fixtures/sanitized-export-v2.json` required by D-07 (14 events, profile, no `healthKitUUID`). The owner scrubbed it with the guide script outside the repo and replied `approved` on 2026-11-09, quoted in the 10-03 summary. `SanitizedBackupFixtureTests` prove the fixture decodes at version 2, imports with zero failures, re-imports as a no-op, exports without `healthKitUUID`, and passes the permanent placeholder lint (plus a negative lint test). The existing DataTransfer suites (`DataBackupExportTests`, `DataImporterRoundTripTests`, `DataImporterUpsertTests`, `DataImporterEdgeCaseTests`, `ComprehensiveRoundTripTests`, `DrinkControlImporterTests`) re-ran unchanged on iOS 27 (plan 10-03: 53 tests in 7 suites). `SanitizedBackupFixtureTests` also ran under the sanitizer with no report. The guard that the format and importer are unchanged: `git diff --quiet fbd37fa -- drinkpulse/Domain/DataTransfer` exits 0 (re-run in section Shipped schema and CloudKit guards).

### Official source consulted

As recorded in the plan 10-03 summary: no new Apple API; the loader reads only the test bundle and the importer was not touched. No Apple documentation lookup was needed or run for this boundary (no API change), and no replacement or deprecation is claimed.

### Regression evidence

`SanitizedBackupFixtureTests` (`sanitized_decodesAtVersion2_andImportsWithoutFailures`, `sanitized_reimportIsNoOp`, `sanitized_exportHasNoHealthKitUUID_andOnlyAllowedKeys`, `sanitized_lint_containsOnlyAllowedPlaceholderValues`, `lint_rejectsPersonalValues`, `probe_` tests) and the DataTransfer suites listed above.

### Device proofs

The import round trip (D-08) is a device check owned by plan 10-12 and recorded in `10-DEVICE-SESSION.md`. This disposition covers the automated evidence and stays final unless that session records a FAIL, in which case plan 10-12 writes a brief (D-06). The D-07 fixture is delivered, so no deferral exists for C009.

Disposition: retain (importer and format unchanged).
