---
last_mapped_commit: 8f0cefeb8c0f6f0169a34fe15b31dce3c8005d57
last_mapped_at: 2026-11-18
---
# Codebase Concerns

**Analysis Date:** 2026-11-18

## Tech Debt

**Store recovery is a catch-all:**
- Issue: `StoreBootstrap.makeContainerReportingRecovery` moves the store aside on any error from `ModelContainer(for:migrationPlan:configurations:)`, not only on unreadable-store or unknown-model-version errors. Transient faults (disk full, file protection while locked, I/O error) also trigger it.
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (catch block around line 46-56), `drinkpulse/drinkpulseApp.swift` (`loadContainerIfNeeded`)
- Impact: The user can land in an empty app with no notice. Three snapshots are kept in `RecoveredStores/`, so older snapshots are trimmed.
- Fix approach: Allowlist the recovery triggers (`NSCocoaErrorDomain` 259 with underlying `NSSQLiteErrorDomain` 26, plus the unknown-model-version error). Rethrow everything else to the existing `.failed` / retry screen. Confirm the error signatures against Apple `SwiftDataError` and `CocoaError` docs via Xcode MCP. Decide on a user-facing notice. Tracked in `.claude/context/open-questions.md`.

**Destructive "Delete all data" is incomplete and silent on error:**
- Issue: `DataSection.deleteAllData()` uses `try?` on both `modelContext.delete(model:)` calls, so failures are swallowed. It does not delete HealthKit samples written by the app (`HealthService.remove` is never called). It does not cancel the pending daily reminder or weekly-summary notifications. It does not reset `healthWriteEnabled`. It resets profile fields by hand-copied defaults instead of sharing one source with onboarding. It calls `StoreBootstrap.clearRecoveredStores()`, which irreversibly deletes recovered snapshots.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift` (`deleteAllData`, around line 192-210), `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (`clearRecoveredStores`)
- Impact: Health data remains in Apple Health after the user believes everything is deleted. Notifications keep firing for deleted data. Deletion failures are invisible.
- Fix approach: Route through one domain service that (1) deletes events and templates with error propagation, (2) removes HealthKit samples per event via `HealthService`, (3) cancels reminder and weekly-summary requests, (4) resets profile defaults from the same source as onboarding. Surface errors to the user. Consider whether snapshot deletion belongs in the same confirmation.

**Duplicated profile default values:**
- Issue: Default profile values (weight 70.0, sex male, weekly goal 100.0, currency "USD", ABV precision 5 permille, standard drinks) are written inline in `DataSection` and separately in `UserProfile` and onboarding.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift`, `drinkpulse/Domain/UserProfile.swift`, `drinkpulse/Features/Onboarding/OnboardingViewModel.swift`
- Impact: Defaults drift silently when one copy changes.
- Fix approach: A single `UserProfile.defaults` value (or static factory) used by all three sites.

**Silent fallback on unknown enum raw values:**
- Issue: `AlcoholUnit.init(from:)` maps any unknown raw string to `.standardDrinks` without logging. This silently changes display semantics and density for affected records.
- Files: `drinkpulse/Domain/AlcoholUnit.swift`
- Impact: Data written by a future or different build is reinterpreted without any trace.
- Fix approach: Log the unknown raw value category (not the value itself, per logging policy) and document the fallback, or throw and let the caller decide.

**Unused tuple element in category mapping:**
- Issue: `DrinkControlImporter.mapCategory` returns `(DrinkCategory, String, String)` where the middle `String` display name is discarded at the only call site (`let (category, _, icon)`).
- Files: `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift` (`mapCategory`, `parseLine`)
- Impact: Dead data, and the English display names are a second source of truth.
- Fix approach: Return only `(DrinkCategory, String)`.

**Test files exceed the 300-line ceiling, and the lint check does not cover them:**
- Issue: The file-size check in `AGENTS.md` scans only `drinkpulse/`. Several test files exceed 300 lines: `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift` (335), `drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Metrics.swift` (327), `drinkpulseTests/Services/HealthServiceTests.swift` (302).
- Files: `drinkpulseTests/**`, `drinkpulseUITests/**`
- Impact: Ceiling silently not enforced for tests. No production file currently exceeds 300 lines (largest: `drinkpulse/Features/History/HistoryView.swift` at 263, `SettingsView.swift` and `EditEventView.swift` at 238).
- Fix approach: Extend the find command to `drinkpulseTests` and `drinkpulseUITests`, or document the test exemption. Split the three listed files by scenario.

**Preview and test helpers use `try!`:**
- Issue: Seventeen `let container = try! ModelContainer(...)` sites exist across feature files (for example `drinkpulse/Features/History/HistoryView.swift` lines 231 and 245, `drinkpulse/Features/Settings/SettingsView.swift` lines 211 and 222, `drinkpulse/Features/Insights/InsightsView.swift` line 37).
- Files: as listed above
- Impact: Allowed by policy only in previews and tests. Not every site was verified to sit inside a `#Preview` block during this analysis.
- Fix approach: Confirm each sits inside preview-only code. Move shared in-memory container factory into `drinkpulse/Diagnostics/` or a preview support file to avoid repetition.

**Architecture drift in the services layer:**
- Issue: `HealthWriteHooks` (`drinkpulse/Services/HealthWriteHooks.swift`) reads `UserDefaults.standard` directly and is a static enum that views call. That bypasses the protocol-wrapped service pattern. `NotificationActionHandler` coordinates through `NotificationCenter` posts plus `UserDefaults` pending flags, which is implicit coupling.
- Files: `drinkpulse/Services/HealthWriteHooks.swift`, `drinkpulse/Services/NotificationActionHandler.swift`, `drinkpulse/DesignSystem/AppStorageKeys.swift`
- Impact: Hard to test the toggle path in isolation. Two routing mechanisms for the same notification tap.
- Fix approach: Inject an `isEnabled` provider into `HealthService` and route tap events through a single typed channel.

**Test-only seams compiled into production:**
- Issue: `UITestSeed` (`drinkpulse/UITestSeed.swift`) and the fake stores (`UITestHealthStore`, `UITestNotificationCenter`) ship in the release binary. Their behavior switches on launch arguments such as `-dp_uitest`, and `resetTransientDefaults()` clears persisted flags when active. `DPMotionProbe` renders an accessibility probe view gated on the same flag.
- Files: `drinkpulse/UITestSeed.swift`, `drinkpulse/UITestSeed+Fixtures.swift`, `drinkpulse/Services/UITestHealthStore.swift`, `drinkpulse/Services/UITestNotificationCenter.swift`, `drinkpulse/Services/HealthService.swift` (`defaultStore`), `drinkpulse/DesignSystem/DPMotionProbe.swift`
- Impact: Gated, so risk is low for normal users, but any build can be pushed into an in-memory store or fake Health store by launch arguments. Fake data also lives in production code.
- Fix approach: Move the seam into `#if DEBUG` or a test-only target where feasible. If it must stay in release, document why and cover the gating with a test.

**Architecture doc and code naming drift:**
- Issue: `AGENTS.md` and ADR-0005 describe `AlcoholUnit` cases `.grams`, `.units` (UK) and `.standardDrinks`, and a property `densityGramsPerMl`. The code defines `.grams` and `.standardDrinks` only, `density(for:)` takes a `GuidelineChoice`, and `physicalDensityGramsPerMl` is the constant name.
- Files: `drinkpulse/Domain/AlcoholUnit.swift`, `docs/decisions/0005-*.md`, `AGENTS.md`
- Impact: Future readers and agents follow the wrong names. Calculation review is harder because the density mapping is keyed differently than the docs state.
- Fix approach: Reconcile the doc and code naming. Hand-verify the density table per the calculation-change rule before editing any doc.

**Sync described as active but not configured:**
- Issue: `AGENTS.md` lists CloudKit sync as the stack. `StoreBootstrap.cloudKitContainerID` is defined, but `productionConfiguration` creates a `ModelConfiguration` with no CloudKit database, so sync is off. The tests guard CloudKit-off.
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `AGENTS.md`
- Impact: Readers may assume sync is live. Identity and LWW fields exist but have no effect on sync today.
- Fix approach: State "sync off until enabled" explicitly in the living docs. Treat enabling CloudKit as a one-way, owner-approved change.

## Known Bugs

**Store-open errors trigger silent empty-app recovery:**
- Symptoms: After a transient store-open failure the app shows an empty history and dashboard with no notice.
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift`
- Trigger: Any `ModelContainer` init error (for example disk full or the device locked during file access).
- Workaround: None in-app. Snapshots remain in `Application Support/RecoveredStores/`.

**Insights hero card height UI test fails:**
- Symptoms: `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` fails reproducibly (Week chart y=323.0, All chart y=320.0, tolerance 1.0). It also fails on pre-Phase-10 commits.
- Files: `drinkpulseUITests/Features/Insights/InsightsUITests.swift`, `drinkpulse/Features/Insights/Components/InsightsHeroCard.swift`
- Trigger: Switch Insights scope between Week and All.
- Workaround: None. Open question in `.claude/context/open-questions.md`.

**Four known failing tests in the final Phase 11 run:**
- Symptoms: 888 tests, 866 passed, 4 failed (DL-T01 to DL-T04, documented as known).
- Files: see `.planning/phases/11-ios-27-release-verification/11-EVIDENCE.md`
- Trigger: Full suite run.
- Workaround: Documented exceptions; not resolved.

**UI test flakes in history and export:**
- Symptoms: `HistoryInteractionUITests.test_segmentSwitch_alternatingDirection_endsInCorrectState` failed once and passed on re-run. An export dismiss UI test is flaky (todo `2026-11-13-export-dismiss-uitest-flaky.md`). History edit UI tests are failing (todo `2026-11-13-history-edit-uitests-failing.md`).
- Files: `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift`, `drinkpulseUITests/Features/History/`
- Trigger: Repeated full-suite runs.
- Workaround: Re-run.

**Dashboard flash and crash after sheet dismissal:**
- Symptoms: Dashboard flashes after the add-drink sheet is dismissed. A related crash is recorded in todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`.
- Files: `drinkpulse/Features/Dashboard/DashboardView.swift`, `drinkpulse/Features/Shell/RootShellView.swift`
- Trigger: Dismiss a sheet from the shell, then return to Dashboard.
- Workaround: None recorded.

**Weekly summary body is frozen at schedule time:**
- Symptoms: The weekly notification text is computed in `WeeklySummaryService.scheduleIfEnabled` and stored in a repeating calendar request. It does not update with later data until the service reschedules (on app activity). The natural weekly delivery is still unobserved on device.
- Files: `drinkpulse/Services/WeeklySummaryService.swift`, `drinkpulse/Domain/WeeklySummaryCalculator.swift`
- Trigger: A user who does not open the app for a week receives text reflecting the last visit.
- Workaround: Reopen the app to reschedule. This is the owner-approved "as-of-last-visit" copy, so verify it is intended before treating it as a bug.

**Health sample lost on failed update:**
- Symptoms: `HealthService.performUpdate` deletes the existing HealthKit sample, then calls `performWrite`. If the save fails after the delete, the event keeps `healthKitUUID = nil` and no sample exists.
- Files: `drinkpulse/Services/HealthService.swift` (`performUpdate`, around line 93-108)
- Trigger: HealthKit save error after a successful delete.
- Workaround: None automatic. Next `write` for the event can re-create the sample, but nothing schedules it.

**Import duplicate check misses duplicates within one file:**
- Symptoms: Records without a `uuid` that appear twice in the same import file are both imported.
- Files: `drinkpulse/Domain/DataTransfer/DataImporter.swift` (`isDuplicate` checks `existing`, which is not updated with newly inserted events), `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift` (same pattern)
- Trigger: A CSV or JSON file containing repeated rows.
- Workaround: None.

## Security Considerations

**Plaintext full-history export left in the temp directory:**
- Risk: `BackupExport.writeTempFile()` writes the full JSON export (all events, notes, prices, body metrics) to `FileManager.default.temporaryDirectory` and never removes it. `AGENTS.md` requires export files to be treated as sensitive and never cached.
- Files: `drinkpulse/Domain/DataTransfer/BackupExport.swift` (`writeTempFile`), `drinkpulse/Features/Settings/Components/DataSection.swift` (`startExport`)
- Current mitigation: Written with `.atomic`; the file is handed to the system exporter. Nothing deletes the temp copy afterwards.
- Recommendations: Delete the temp file after the exporter completes or fails. Consider writing directly into the exporter's security-scoped destination. Add a test that the temp file is removed.

**No privacy manifest:**
- Risk: The repo has no `PrivacyInfo.xcprivacy`. The app uses `UserDefaults` and `@AppStorage`, which Apple lists as a required-reason API. App Store submission needs the manifest and a required-reason audit.
- Files: repo root (no `PrivacyInfo.xcprivacy` present; confirmed in `.claude/context/open-questions.md`)
- Current mitigation: None.
- Recommendations: Add the manifest with `NSPrivacyAccessedAPICategoryUserDefaults` (reason CA92.1 if applicable, confirmed against Apple docs via Xcode MCP) and audit file-timestamp use (DEBUG only). Tracked as DL-M01.

**Import reads user-supplied values without range validation:**
- Risk: `DataImporter` and `DrinkControlImporter` accept any `abv`, `volumeMl` and `quantity` from the file. A malformed file (for example ABV 50 or negative volume) produces events whose grams feed dashboard, insights, guideline percentages and any future BAC.
- Files: `drinkpulse/Domain/DataTransfer/DataImporter.swift`, `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift` (`parseLine`), `drinkpulse/Domain/ConsumptionEvent.swift` (init has no validation)
- Current mitigation: Decode and integer parse checks only (`count >= 1`).
- Recommendations: Add validators on the domain side (ABV in 0.0 to 1.0, volume > 0, quantity >= 1) that reject or flag records. Cover with domain tests (100% Domain target).

**Error messages echo file content:**
- Risk: `ImportResult.errors` includes raw category strings from the import file (`"Unknown category '\(record.category)'"`) and parser messages with field values. These appear in the UI.
- Files: `drinkpulse/Domain/DataTransfer/DataImporter.swift`, `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift`
- Current mitigation: Shown only to the user who selected the file.
- Recommendations: Low severity. Keep messages to counts and error categories where possible.

**Logging policy is largely followed:**
- Positive: No `print(` calls in production code. Logs use `os.Logger` with subsystem `com.drinkpulse.app`. Values are marked `privacy: .public` only for counts, durations, codes and enum-derived labels (for example `NotificationActionHandler.tapKind`). Notification identifiers are not logged raw.
- Residual: `drinkpulse/Features/History/HistoryView.swift` (line ~223, DEBUG only) logs `Date` values as `.public`. Low severity because the code is compiled out of release. Consider `.private`.

## Performance Bottlenecks

**Full-table fetch on the main actor at launch:**
- Problem: `RecordDeduplicator.sweep` fetches every `ConsumptionEvent` and `DrinkTemplate` on the main actor each time `RootShellView` appears.
- Files: `drinkpulse/Domain/Persistence/RecordDeduplicator.swift`, `drinkpulse/drinkpulseApp.swift` (`onAppear` sweep)
- Cause: Unbounded fetch and per-record dictionary work, scaling with total history.
- Improvement path: Run the sweep once per store version (persisted marker) or on a background `ModelContext`. Measure with signposts (`ViewLoadLogger` exists in DEBUG).

**Quadratic duplicate detection during import:**
- Problem: `DataImporter.isDuplicate` scans the full `existing` array for every incoming record. Import runs on the main actor.
- Files: `drinkpulse/Domain/DataTransfer/DataImporter.swift`, `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift`
- Cause: O(existing × incoming) comparisons. For example, 5,000 existing and 5,000 imported rows is about 25 million comparisons on the UI thread.
- Improvement path: Index existing events by rounded `consumptionDate` (for example 1-second buckets) and look up candidates in O(1). Fix the in-file duplicate gap in the same change.

**Insights rebuilds the full grams map on every change:**
- Problem: `InsightsViewModel.events` and `profile` `didSet` both call `rebuildGramsByDay()`, which iterates all events.
- Files: `drinkpulse/Features/Insights/InsightsViewModel.swift`
- Cause: Full rebuild instead of incremental update.
- Improvement path: Acceptable at current scale. Revisit if history grows to years of dense data; profile changes do not need a rebuild when only the unit label changes.

**Settings delete and export load everything into memory:**
- Problem: `startExport` fetches all events and templates and encodes the full JSON on the main actor.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift`, `drinkpulse/Domain/DataTransfer/BackupExport.swift`
- Cause: No streaming or background encoding.
- Improvement path: Encode off the main actor after snapshotting value types, consistent with the "value types for transfer" pattern already used by `ExportRecord`.

## Fragile Areas

**Per-event HealthKit serialization and epoch logic:**
- Files: `drinkpulse/Services/HealthService.swift` (`runSerial`, `performRemoveSample`), `drinkpulse/Services/HealthWriteHooks.swift`
- Why fragile: Correctness depends on reentrancy-aware chaining (`tails` dictionary) and the F2 stale-UUID resolution. `HealthWriteHooks` captures a SwiftData `ConsumptionEvent` across a `Task` and mutates `event.healthKitUUID` after `await`, even if the user has deleted the event meanwhile. `try? context.save()` swallows failures.
- Safe modification: Change only with the `HealthServiceOrderingTests` and `HealthServiceTests` suites green. Do not hold model references across `await`; pass identifiers and re-fetch.
- Test coverage: Ordering and stale-UUID paths are tested. Deleted-event-during-await and save-failure paths are not verified.

**Reminder and weekly-summary epoch logic:**
- Files: `drinkpulse/Services/ReminderService.swift`, `drinkpulse/Services/WeeklySummaryService.swift`
- Why fragile: Actor reentrancy handling uses `lifecycleEpoch` and `cancelEpoch` (F3). A subtle change can leave a stale pending request or cancel a fresh one.
- Safe modification: Keep the epoch comparison pattern. Add a test for every new await point.
- Test coverage: `ReminderServiceTests`, `WeeklySummaryServiceScheduleTests`, `WeeklySummaryCompletedWeekTests` exist. Concurrent cancel-during-add is the critical path.

**Store recovery and migrations:**
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift`, `drinkpulse/Domain/Persistence/MigrationPlan.swift`, `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` through `SchemaV4.swift`
- Why fragile: `SchemaV1` still declares `@Attribute(.unique)` on a singleton (historical, frozen). The V1→V2 stage assigns new UUIDs and modifies dates in a custom stage. Recovery relies on the same open call that migration runs in, so a migration error and a transient error look identical.
- Safe modification: Never edit a shipped `VersionedSchema` (AGENTS rule). Add a new version and stage for every model change. Keep recovery allowlist and migration tests (`drinkpulseTests/Domain/Persistence/MigrationTests.swift`) in sync.
- Test coverage: Migration and rollback tests exist (`StoreBootstrapTests+Rollback`, `MigrationFixtures+LegacyV2V3`). Recovery trigger classification is not tested because it is not implemented.

**Calculation coupling between unit mode, guideline and density:**
- Files: `drinkpulse/Domain/AlcoholUnit.swift`, `drinkpulse/Domain/GuidelineChoice+Limits.swift`, `drinkpulse/Features/Insights/InsightsViewModel.swift` (`modeDensity`)
- Why fragile: `density(for:)` and `gramsPerUnit(for:)` vary by both unit mode and guideline. The same grams value is displayed with different densities in different modes. Changes require hand verification per the project rule.
- Safe modification: Change only with an explicit calculation review. Keep `pureAlcoholGrams` on the physical density.
- Test coverage: Domain layer target is 100%, but the measured value is 90.06% (see Test Coverage Gaps).

**Dedicated data-transfer logic in a SwiftUI view:**
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift` (import handlers, `deleteAllData`, profile reset)
- Why fragile: About 235 lines of mixed view and domain logic. Import results, error alerts and destructive resets are coupled to view state.
- Safe modification: Move import and delete orchestration into a domain service and keep the view to presentation.

## Scaling Limits

**Event history fetched wholesale:**
- Current capacity: Not measured on device with large histories. Tests seed hundreds of events.
- Limit: Launch sweep, import dedupe, and export all scale linearly or quadratically with total events on the main actor.
- Scaling path: Background contexts, indexed dedupe, and windowed queries (History already uses a windowed `@Query` in `drinkpulse/Features/History/HistoryListQueryView.swift`).

**Recovered snapshot retention:**
- Current capacity: Three snapshots (`StoreBootstrap.maxRecoveredStores`).
- Limit: Repeated recovery deletes the oldest snapshot silently.
- Scaling path: Surface recovery to the user and keep snapshots until the user dismisses them.

## Dependencies at Risk

**No third-party runtime dependencies detected:**
- Risk: None identified in the Swift sources. Apple frameworks only: SwiftUI, SwiftData, HealthKit, UserNotifications, OSLog, CoreTransferable.
- Impact: Platform API changes (iOS 27 deprecations) are the main risk. Verify deprecations against Apple docs, not age alone.
- Migration plan: Not applicable. Keep the App Store privacy manifest in scope (see Security Considerations).

## Missing Critical Features

**No user-facing recovery notice:**
- Problem: Users cannot tell when their store was moved aside.
- Blocks: Trust in the data after a recovery event; diagnosing lost-history reports.

**CloudKit sync not active:**
- Problem: Sync is not configured. Multi-device data is not available.
- Blocks: Multi-device use. Enabling sync is a one-way, owner-approved change (see Architecture drift).

## Test Coverage Gaps

**Domain coverage below target:**
- What's not tested: Domain coverage measured at 90.06% against a 100% target (DL-W01, DL-W07). Coverage was not re-measured on the final Phase 11 tree; the 94.65% value is historical.
- Files: `drinkpulse/Domain/**`
- Risk: Calculation and validation edge cases unverified (for example import value ranges above).
- Priority: High

**Data-transfer validation and duplicate edge cases:**
- What's not tested: Out-of-range ABV and volume on import, in-file duplicates without `uuid`, and CSV fields containing `;` inside quotes.
- Files: `drinkpulse/Domain/DataTransfer/DataImporter.swift`, `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift`
- Risk: Silent insertion of implausible drinks; duplicate history.
- Priority: High

**Delete-all completeness:**
- What's not tested: HealthKit sample removal, notification cancellation, and error propagation during delete all.
- Files: `drinkpulse/Features/Settings/Components/DataSection.swift`
- Risk: Orphaned Health samples and notifications after the user deletes data.
- Priority: High

**Store recovery trigger classification:**
- What's not tested: Transient errors versus unreadable-store errors. Recovery currently runs on all of them.
- Files: `drinkpulse/Domain/Persistence/StoreBootstrap.swift`
- Risk: Data moved aside after a transient fault.
- Priority: Medium

**Export temp-file cleanup:**
- What's not tested: Removal of `BackupExport` temp output after export.
- Files: `drinkpulse/Domain/DataTransfer/BackupExport.swift`
- Risk: Full-history plaintext left on disk.
- Priority: Medium

**Health save-failure after delete:**
- What's not tested: The sample-loss path in `HealthService.performUpdate`.
- Files: `drinkpulse/Services/HealthService.swift`
- Risk: Health and app history diverge silently.
- Priority: Medium

**Localization gaps:**
- What's not tested: No test asserts that user-facing strings go through `String(localized:)`. Known hardcoded English user-visible strings: `drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift` (`ParseError.errorDescription`: "Not enough fields", "Invalid date:", "Invalid number in field"), `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` (line ~91 `"\(bar.label) — ..."`), `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` (line ~113 callout string), `drinkpulse/Features/Settings/Components/SettingsRow.swift` and `SettingsSection.swift` (labels "Volume unit", "ABV precision", "Mode", "Titleless", "No header"; verify whether preview-only).
- Files: as listed
- Risk: Violates the String(localized:) rule. Some strings are visible in production.
- Priority: Medium

**Accessibility of chart callouts and weekday bars:**
- What's not tested: Accessibility descriptors exist (`AlcoholAreaChart+Accessibility.swift`, `WeekdayBarChart+Accessibility.swift`) but the interpolated callout text above is not localized and was not verified at AX5 in this analysis.
- Files: `drinkpulse/Features/Insights/Components/`
- Risk: Callouts unreadable or untranslatable.
- Priority: Medium

## Open Items Tracked Elsewhere

- Debugger attach to the owner's iPhone hangs (tooling observation, not an app result).
- Natural weekly-summary delivery on a killed app not yet observed on device.
- Owner decisions pending on OBS-A and OBS-C, and a device pass for VoiceOver items (`.claude/context/current-focus.md`).
- Phase verifier re-runs for Phases 08 to 10 deferred.

---

*Concerns audit: 2026-11-18*
