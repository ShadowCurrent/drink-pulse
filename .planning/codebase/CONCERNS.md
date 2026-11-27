---
last_mapped_commit: 19ce3159ee64540aaea8411fc85f24e6bea68714
last_mapped_at: 2026-11-27
---
# Codebase Concerns

**Analysis Date:** 2026-11-27

## Tech Debt

**CloudKit sync is documented but not wired:**
- Issue: `AGENTS.md` and the stack section describe CloudKit sync via SwiftData's built-in integration. The code only declares the container ID (`iCloud.com.drinkpulse.app`) as a constant. No `ModelConfiguration` sets `cloudKitDatabase`, and no entitlement or CloudKit-specific schema work was found.
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (line 16, `cloudKitContainerID`; `productionConfiguration` at line 20), `AGENTS.md`
- Impact: Living docs describe a sync feature that does not exist. The forward-compatibility rules (no unique attributes, optional or defaulted properties) are enforced for a feature that is OFF. Planners may assume sync is available.
- Fix approach: Either mark CloudKit as "planned, not enabled" in `AGENTS.md`, `docs/architecture.md`, and `README.md`, or enable it in a dedicated plan. Enabling it is a one-way step and needs explicit owner approval.

**Frozen schema still contains a unique attribute:**
- Issue: `SchemaV1` declares `@Attribute(.unique) private(set) var id: String = "singleton"` on the profile model. CloudKit does not support unique constraints. The live shape (`SchemaV4`) does not contain one, so this only matters if V1 is reachable from a migration path.
- Files: `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` (line 17), `drinkpulse/Domain/Persistence/MigrationPlan.swift`
- Impact: Blocks enabling CloudKit on the V1 migration path. Frozen versions must not be edited, so the fix belongs in a new schema version or in the migration stage.
- Fix approach: Confirm which migration stage reads V1. Plan the CloudKit enablement against V4 and record the constraint in an ADR.

**Four schema versions with mixed migration stages:**
- Issue: `MigrationPlan` has two `custom` stages (`v1ToV2`, `v2ToV3`) and one `lightweight` stage (`v3ToV4`). Custom stages carry the highest risk of data loss, and no migration test output was reviewed in this pass.
- Files: `drinkpulse/Domain/Persistence/MigrationPlan.swift`, `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` through `SchemaV4.swift`
- Impact: Any change to the migration chain can silently move user stores aside (see the next section).
- Fix approach: Keep the migration tests (`StoreBootstrapTests+Rollback` and the migration suites) in the scoped test gate for every model change.

**Duplicate-record handling is a silent sweep:**
- Issue: `RecordDeduplicator.sweep` runs on every shell start. It deletes duplicate `ConsumptionEvent`, `DrinkTemplate`, and `UserProfile` rows, keeping the one with the latest `modifiedDate`. The result is not logged to the user, and the winner depends entirely on the clock values stored on each row.
- Files: `drinkpulse/Domain/Persistence/RecordDeduplicator.swift`, `drinkpulse/Domain/Persistence/UserProfileStore.swift`, `drinkpulse/Features/Shell/ShellStartup.swift`
- Impact: Clock skew between devices or a bad `modifiedDate` can remove the record a user wanted. Deletion runs without a user-visible audit trail. A fetch failure is treated as an empty list (`try?`), so the sweep silently does nothing.
- Fix approach: Log deleted counts with identifiers only (already done for counts). Add a test that covers clock-skew and equal-timestamp cases.

**Fire-and-forget persistence tasks:**
- Issue: `HealthWriteHooks.write`, `update`, and `remove` start unstructured `Task`s that capture a `ModelContext` and call `try? context.save()`. Failures are discarded, and the tasks are not tracked or cancelled.
- Files: `drinkpulse/Services/HealthWriteHooks.swift` (lines 12 to 25)
- Impact: A failed save leaves `healthKitUUID` written to the Health store but not persisted locally, which causes duplicate HealthKit samples on the next write. Save errors give the user no signal.
- Fix approach: Replace `try?` with a logged, typed error. Make the save happen on the same actor as the mutation before the Health call returns, or make the task return a result that the caller can check.

## Known Bugs and Data-Integrity Risks

**Deleting all data leaves HealthKit samples behind:**
- Symptoms: After "Delete all data" in Settings, `dietaryAlcohol` samples written by the app remain in Apple Health. The local `healthKitUUID` links are gone with the events.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift` (`deleteAllData`, lines 206 to 221)
- Trigger: Enable Health write, log drinks, then choose Delete all data.
- Workaround: Delete the samples manually in the Health app.
- Fix approach: Before deleting local rows, call `HealthService.removeSample` for each event that has a `healthKitUUID`, or delete samples by `dp_event_uuid`. The wipe must not report success if Health cleanup fails.

**Delete-all ignores failures and destroys recovery snapshots:**
- Symptoms: `try? modelContext.delete(model:)` results are discarded, and the success path still runs. `StoreBootstrap.clearRecoveredStores()` permanently removes every `RecoveredStores` snapshot.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift` (lines 207 to 208), `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (`clearRecoveredStores`, line 116)
- Trigger: A delete fails (for example, a save conflict), or the user taps Delete all data after an automatic recovery.
- Fix approach: Use `do/catch`, surface the error, and clear snapshots only after the delete commits. Consider a second confirmation that names the recovery snapshots.

**Export can silently produce an empty backup:**
- Symptoms: `startExport` maps fetch failures to empty arrays. The export sheet then reports success for a file that has no events or templates. A user who restores that file, or deletes data afterwards, loses history.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift` (`startExport`, lines 153 to 160; `handleExportResult`, lines 162 to 170)
- Trigger: A SwiftData fetch error during export.
- Fix approach: Propagate fetch errors into `exportError`. Do not present the exporter unless both fetches succeed.

**Import read failures return without feedback:**
- Symptoms: `prepareDCImport` returns early when `String(contentsOf:)` fails, so the user sees no error and no preview.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift` (line 193)
- Fix approach: Set an import error the same way `handleDPImport` does (line 181 uses `importError` for the equivalent `Data(contentsOf:)` failure).

**Store recovery catches every open error:**
- Symptoms: `makeContainerReportingRecovery` moves the store files into `Application Support/RecoveredStores` on any `ModelContainer` init failure, including transient causes such as disk pressure or a locked file. A fresh empty store then opens and the app continues without the user's data visible.
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (lines 38 to 55)
- Trigger: Any SwiftData open failure, including a migration error on a new device.
- Workaround: Snapshots are kept (at most `maxRecoveredStores` = 3), but nothing in the UI tells the user that recovery ran.
- Fix approach: Narrow recovery to known schema-mismatch errors, and surface a recovery notice in the UI that offers to restore from the snapshot.

**Import duplicate check uses exact-match heuristics:**
- Symptoms: Records without a `uuid` are treated as duplicates when date, volume, ABV, and quantity all match an existing row. Two genuine identical drinks at the same timestamp are merged.
- Files: `drinkpulse/Domain/DataTransfer/DataImporter.swift` (lines 46 to 52)
- Fix approach: Document this rule in `docs/domain.md`, and cover it with a test for two identical legitimate entries.

## Security and Privacy Considerations

**Health data written to HealthKit is not removed on wipe:** See "Known Bugs" above. This is both a privacy and a data-integrity issue.

**Personal data files in the repository root:**
- Risk: `drinkcontrol.csv` and `drinkpulse-backup-2026-06-12.json` hold real drink history. Both are on disk with owner-only permissions and are gitignored (`.gitignore` lines 126 to 128). Neither is tracked (verified with `git ls-files`).
- Current mitigation: Gitignore rules.
- Recommendations: Move these files out of the repository into a directory outside the project. A single `git add -f` would publish health data.

**Debug UI-test hooks gated by launch arguments:**
- Risk: `UITestSeed.isActive` reads `-dp_uitest` from the launch arguments. `HealthService.defaultStore()` and `drinkpulseApp.swift` branch on it at runtime.
- Current mitigation: The real `UITestSeed` is compiled in `#if DEBUG` only, and a stub with every flag `false` covers Release (`drinkpulse/UITestSeed.swift`, lines 240 to 262).
- Recommendations: Keep the stub in sync with every new flag. Add a Release-configuration build check that fails if a new call site references a symbol outside the stub.

**Export files contain full history:**
- Risk: `BackupExport` writes every event, template, and the profile to a file the user saves anywhere. The export is intentional, but no warning is shown about the sensitivity of the file.
- Current mitigation: The file is written only on explicit user action through the system exporter.
- Recommendations: Add a one-line warning on the export screen that the file contains health data.

## Performance Bottlenecks

**Full-table fetches on every import and sweep:**
- Problem: `DataImporter.importData` loads all `ConsumptionEvent` and `DrinkTemplate` rows into memory and builds lookup dictionaries. `RecordDeduplicator.dedupe` does the same at shell start.
- Files: `drinkpulse/Domain/DataTransfer/DataImporter.swift` (line 30), `drinkpulse/Domain/Persistence/RecordDeduplicator.swift` (lines 26, 49)
- Cause: No predicate or incremental strategy. Cost grows linearly with history size.
- Improvement path: Measure with a seeded store of several thousand events before changing anything. If needed, move the sweep off the launch path or run it once per schema version.

**Chart and history composition:**
- Problem: `DashboardViewModel` and `InsightsViewModel` recompute aggregates from the full event array on each change.
- Files: `drinkpulse/Features/Dashboard/DashboardViewModel.swift`, `drinkpulse/Features/Insights/InsightsViewModel.swift` (215 lines)
- Cause: Derived values are not cached. Views pass whole arrays into view models.
- Improvement path: Profile with Instruments before optimizing. No measured regression was found in this pass.

## Fragile Areas

**Store bootstrap and move-aside logic:**
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (182 lines)
- Why fragile: Moves the main file, WAL, and SHM separately, and rolls back by hand. The rollback path has several best-effort branches that only log.
- Safe modification: Change only with the `StoreBootstrapTests` rollback suite passing. Use the injected `moveItem` seam rather than real file permissions.
- Test coverage: Rollback is pinned by tests according to the code comments. Coverage was not measured in this pass.

**Health write serialization:**
- Files: `drinkpulse/Services/HealthService.swift` (172 lines), `drinkpulse/Services/HealthWriteHooks.swift`
- Why fragile: Per-event serialization uses a hand-built chain of `Task`s (`runSerial`, `ChainBox`). Ordering depends on actor reentrancy. Comments reference decision files (F2, 10-DECISION-F2.md) that describe past races.
- Safe modification: Keep the `dp_event_uuid` lookup-first rule in `performUpdate` and `performRemoveSample`. Any change needs a test that interleaves an update and a remove for the same event.

**Settings `DataSection` holds the whole data lifecycle:**
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift` (246 lines)
- Why fragile: Export, two import paths, delete-all, and the profile reset share one view. Error handling is inconsistent (see "Known Bugs").
- Safe modification: Move data operations into a service behind a protocol, as the services layer rule requires, and cover each with a test.

**Preview containers use `try!`:**
- Files: about 13 view files, for example `drinkpulse/Features/Settings/SettingsView.swift` (lines 57, 68, 80), `drinkpulse/Features/History/EditEventView.swift` (line 231)
- Why fragile: Allowed by the project rules for previews only. A schema change that breaks an in-memory container crashes the preview canvas, not the app.
- Safe modification: Keep the preview-only scope. Do not copy this pattern into production code.

## Scaling Limits

**Single in-memory query model:**
- Current capacity: Not measured. Every feature queries the complete event table through `@Query` or full fetches.
- Limit: Not determined. Expect slower launch and import as history grows beyond a few thousand rows.
- Scaling path: Add fetch predicates by date range for Dashboard and Insights, and paginate History.

## Dependencies at Risk

**UIKit wrapper in the calendar:**
- Risk: `drinkpulse/Features/History/Components/DecoratedCalendar.swift` wraps `UICalendarView` through `UIViewRepresentable`. The project rules allow UIKit only when unavoidable.
- Impact: Dynamic Type and iOS 27 behavior changes in the wrapped view are harder to verify.
- Migration plan: Check the current official SwiftUI calendar and decoration APIs through Xcode MCP `DocumentationSearch` before changing anything. Do not replace the wrapper on the assumption that it is outdated.

## Missing Critical Features

**No user-visible recovery path:**
- Problem: A store recovery or a failed import leaves the user with less data and no explanation.
- Blocks: Trust in offline-only storage, which is the core product promise.

**No CloudKit sync:**
- Problem: Multi-device users have no sync, despite the documented plan.
- Blocks: Cross-device history and the documented sync requirements in `AGENTS.md`.

## Test Coverage Gaps

**HealthKit cleanup on delete-all:**
- What's not tested: Whether `deleteAllData` removes or leaves Health samples.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift`, `drinkpulse/Services/HealthService.swift`
- Risk: The bug in "Known Bugs" can return unnoticed.
- Priority: High

**Export failure paths:**
- What's not tested: Export when a fetch throws, which currently writes an empty file.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift`
- Risk: Silent loss of history in a backup.
- Priority: High

**Clock-skew and tie cases in deduplication:**
- What's not tested: Equal `modifiedDate` values and cross-device skew in `RecordDeduplicator` and `UserProfileStore.deduplicated`.
- Files: `drinkpulse/Domain/Persistence/RecordDeduplicator.swift`, `drinkpulse/Domain/Persistence/UserProfileStore.swift`
- Risk: The wrong record survives the sweep.
- Priority: Medium

**Coverage figures:**
- What's not tested: This analysis did not run `xcodebuild test` or `xccov`. The 90% and per-layer targets in `AGENTS.md` are unverified here.
- Files: `drinkpulseTests/`, `drinkpulseUITests/` (184 Swift test and UI-test files in total)
- Risk: Gaps in coverage are unknown.
- Priority: Medium. Run the coverage report command from `AGENTS.md` before the next milestone close.

## Process Note

- The seven `.planning/codebase/*.md` documents were deleted in the working tree before this analysis (see `git status`). This document and its siblings are regenerated by this mapping run.

---

*Concerns audit: 2026-11-27*
