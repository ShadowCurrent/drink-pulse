# Codebase Concerns

**Analysis Date:** 2026-07-18

## Tech Debt

**Migration plan discipline dependency:**
- Issue: [ADR-0009](../docs/decisions/0009-versioned-schema-and-migration-plan.md) uses a "reference-now" design where `SchemaV1` references live `@Model` classes. When the first divergent schema is added (plan-0023), the then-current shape must be manually copied into a frozen `SchemaV1` snapshot before editing the live classes. Skipping this step silently corrupts the migration.
- Files: `Domain/Persistence/Schemas/SchemaV1.swift`, `Domain/Persistence/MigrationPlan.swift`, `Domain/Persistence/StoreBootstrap.swift`
- Impact: A missed snapshot step will make the migration definition describe a no-op, causing store version mismatches and data loss on upgraded devices.
- Fix approach: Enforce the snapshot-on-divergence rule as a mandatory pre-commit gate when any `@Model` property changes. Document the step explicitly in the commit workflow. Consider adding a schema-hash validator that fails the build if a version's schema hash changes without a new version being created.

**RecordDeduplicator UUID uniqueness check performance:**
- Issue: `RecordDeduplicator.ensureUniqueIdentity()` fetches all records of a type every time it is called to check for UUID collisions. This is O(n) per record insertion.
- Files: `Domain/Persistence/RecordDeduplicator.swift` (lines 64–69)
- Impact: Negligible in practice (UUID collisions are astronomically unlikely; this is a belt-and-suspenders guard). Becomes observable only at very large datasets (100k+ events). The current implementation is acceptable as a one-time check per record.
- Fix approach: If dataset size grows significantly (unlikely before 2027), add a set-based cache of UUIDs instead of re-fetching all records.

## Known Bugs (Fixed)

**Apple Health write-back stale auth status (FIXED 2026-06-30):**
- Symptom: With Health write-back enabled, newly logged drinks did not appear in Apple Health until the user toggled the setting off/on.
- Root cause: `HealthService` gated writes on `authorizationStatus() == .authorized`, but on a fresh app process the status could stale-report `.notDetermined` even though the user had enabled Health write-back in a prior session.
- Files: `Services/HealthService.swift`, `Services/HealthWriteHooks.swift`
- Fix applied: Added `isAuthorizedForWrite()` that self-heals a stale `.notDetermined` by re-requesting auth once before giving up. Denials are never re-requested.
- Status: Closed (commit on 2026-06-30).

**Imperial beer preset defaulted to 500 ml instead of 1 pint (FIXED 2026-06-23):**
- Symptom: When users with imperial unit system opened the Add Drink screen for beer, the default serving was a 500 ml bottle instead of the culturally-native 1 pint (568 ml).
- Root cause: `DrinkTypePreset` had a single `defaultVolumeMl: 500` used across all unit systems.
- Files: `Features/AddDrink/DrinkTypePreset.swift`, `Features/AddDrink/DrinkDetailInputView.swift`
- Fix applied: Added `regionDefaults: [UnitSystem: Double]` to `DrinkTypePreset`. Beer now specifies `.imperial: 568`. The `defaultVolumeMl(for:)` method prefers region-specific defaults.
- Status: Closed (commit on 2026-06-23).

**UserDefaults pollution across UI test runs (FIXED 2026-06-27):**
- Symptom: `ReminderSettingsUITests.test_reminderToggle_revealsAndHidesTimeRow` was flaky; the reminder was already on at launch even on a freshly installed app.
- Root cause: The iOS simulator persists app-domain `UserDefaults` across reinstalls. A prior test run that toggled the reminder on left the key `dp_reminder_enabled = true`, polluting the next run's baseline.
- Files: `UITestSeed.swift`, `drinkpulseApp.swift`
- Fix applied: Added `UITestSeed.resetTransientDefaults()` (launch-arg-gated, inert in production) to remove `UserDefaults` keys for reminder + health write-back enable flags at app start. Called from `drinkpulseApp.init()` before any view reads the values.
- Status: Closed (commit on 2026-06-27). Note: the same pattern may apply to other `@AppStorage` keys if they interact with features not yet gated by reset logic.

## Known UI Test Flakiness

**Full-suite timing flakiness:**
- Issue: When running the complete UI test suite together, some tests fail intermittently due to timing/layout settling in earlier tests affecting later ones. Single tests pass reliably.
- Files: Multiple UI test files in `drinkpulseUITests/`; noted in `docs/plans/0016-log-reminder-notifications/retrospective.md` and `docs/plans/0032-ui-test-coverage-completion/execution.md`
- Cause: SwiftUI view layout and assertion timing. Some tests need the form to finish laying out before assertions can pass (e.g., Settings sex/guideline rows); others race glassEffect rerenders.
- Mitigation: Several patterns documented in execution notes — assert rows in a specific order to let ScrollView settle; wait for key elements before asserting dependent ones.
- Fix approach: Add deterministic delays or wait-for-element predicates in brittle tests. Document timing expectations in test comments.

## Security Considerations

**Best-effort Health write-back (non-blocking design):**
- Risk: All Apple Health operations (authorization denied, revoked, network failure) are caught, logged by category, and silently swallowed (best-effort). Users are not alerted if a Health write fails.
- Files: `Services/HealthWriteHooks.swift`, `Services/HealthService.swift`
- Current mitigation: Failures are logged (category only, no PII). If auth is denied on first enable, the UI shows an inline message + "Open Settings" link. Subsequent failures are silent.
- Recommendations: Consider adding a small badge or note (e.g., "⚠ Health sync unavailable") in Settings when Health write-back is enabled but no longer authorized. Document the non-blocking design prominently in the Help/Info screen.

**Device-local Health sample identity not portable:**
- Risk: `ConsumptionEvent.healthKitUUID` is intentionally device-local (never exported, never synced). If the app is deleted and reinstalled, or if a user restores to a different device, the cached sample UUID becomes stale and Health samples can duplicate on the new install.
- Files: `Services/HealthService.swift`, `Domain/ConsumptionEvent.swift`
- Current mitigation: The metadata key `dp_event_uuid` (stored in the Health sample itself) is the source of truth and is queried to relink existing samples on the same device. On restore-to-new-device or CloudKit multi-device, the Health sample is re-queried using the metadata key (requires read auth, which is granted for write-back).
- Recommendations: This design is sound. Document in the Health section of the Settings screen that Health samples are device-scoped and will not sync across devices (when multi-device sync is eventually enabled).

**No third-party SDKs or network calls:**
- Status: No external analytics, crash reporters, ad/attribution, or login SDKs. CloudKit sync lives in SwiftData without custom backend. This is a strength, not a concern — the privacy-first promise is upheld.

## Performance Bottlenecks

**Calendar view computation on large event sets:**
- Observed: Switching Insights view to "Year" loaded slower than "All Time" in early versions. Investigation showed it was not a SwiftData query issue but calendar computation overhead.
- Files: `Features/Insights/InsightsViewModel.swift`, `Features/History/HistoryCalendarView.swift`
- Cause: Month-cell computation (grouping events by day, filtering by month) runs ~13k expensive operations on a full-year view.
- Mitigation: Performance tests enforce < 10 ms per iteration for 2,000 events; < 50 ms for 10,000 events ([plan-0013](docs/plans/0013-history-calendar-clickable-days/plan.md)).
- Current status: Passes performance gates; no user-facing slowness reported. Monitor if event count grows significantly (unlikely before end of 2026).

## Fragile Areas

**CloudKit Phase B blocked on provisioning:**
- Files: `docs/plans/0023-cloudkit-sync/` (plan status: in-progress), `docs/architecture.md`
- Why fragile: [plan-0023](docs/plans/0023-cloudkit-sync/) Phase A (identity + dedup + migration) is complete. Phase B (enable CloudKit sync, add entitlements, provision container) is blocked: it requires a paid Apple Developer account and explicit one-way approval to enable `cloudKitDatabase`. The architecture is ready, but the external permission gate is the single point of failure.
- Safe modification: No code changes should be made until the iCloud container is provisioned. Once provisioned, follow the Phase B plan strictly — CloudKit sync is irreversible on real devices.
- Test coverage: No integration tests with real CloudKit (it is disabled). Sync logic is tested via the `RecordDeduplicator` unit tests and the multi-device dedup invariants in [ADR-0010](docs/decisions/0010-cloudkit-ready-identity-and-lww.md).

**Health write-back integration with concurrent edit/delete:**
- Files: `Services/HealthService.swift` (uses `.serialized` actor isolation), `Services/HealthWriteHooks.swift`
- Why fragile: Rapid edit→delete of the same event could theoretically race two Health operations if the app crashes between them (e.g., delete removes the sample, but a background task is still writing). The current design serializes per `event.uuid`, so updates and deletes are linearized on the same device.
- Safe modification: Do not add async batch operations on Health samples without first adding a transaction log or idempotency key. The current best-effort design accepts lossy writes (if Health fails silently, the app continues); changing to "sync must succeed" would require a more complex conflict-resolution layer.
- Test coverage: `HealthWriteHooksUITests.test_healthEnabled_logDrink_writesHealthSample` verifies a sample is actually written on add.

**Schema migration on app upgrade:**
- Files: `Domain/Persistence/Schemas/`, `Domain/Persistence/MigrationPlan.swift`
- Why fragile: The versioned schema design is new ([plan-0035](docs/plans/0035-swiftdata-migration-foundation/) 2026-06-28). It has been tested locally but not on real devices across an App Store update. The first production upgrade will be the true test of the migration plan.
- Safe modification: Do not edit any shipped `VersionedSchema` snapshot; always add a new version. Test schema changes in the simulator with real device data exports before shipping.
- Test coverage: Round-trip export/import tests verify data survives a schema change locally. No production device migration has been observed yet.

## Scaling Limits

**Very large event logs (100k+ events):**
- Current capacity: App is tested and performant up to 10,000 events (3 years at ~2 drinks/day). Calendar rendering, de-dup sweeps, and export/import all meet performance gates.
- Limit: Beyond 100,000 events, fetch queries and de-dup sweeps (O(n) in-memory operations) could become observable. SwiftData compound indexes (`.#Index` macro on `(timestamp, category)`) are listed in the roadmap as a future optimization.
- Scaling path: Add compound index on `ConsumptionEvent` for `(consumptionDate, category)` to speed date-range queries. Move de-dup to a background task with progress reporting. Consider a date-range filter UI to avoid loading the entire history at once.

**CloudKit sync at scale (after Phase B enables it):**
- Current: CloudKit sync is disabled. Phase A identity + dedup is designed for multi-device sync but not yet active.
- Limit: Unknown. SwiftData's built-in CloudKit integration does not tune for custom dedup logic. The app-level `RecordDeduplicator.sweep()` runs on launch (Phase A) and post-sync (Phase B, when enabled); its performance at 100k+ records is untested.
- Scaling path: When Phase B enables CloudKit, monitor sync latency on devices with large event counts. Use Instruments to profile `RecordDeduplicator` sweeps. Migrate to a background task with progress reporting if needed.

## Dependencies at Risk

**No external SDKs — low risk:**
- Status: The codebase has zero third-party Swift Package dependencies beyond Apple frameworks. All critical logic (SwiftData, Health, Notifications, Charts) uses official Apple SDKs.
- Risk: None. Apple SDKs are versioned with iOS and cannot be downgraded independently. If a breaking change lands in a future iOS version, the entire app must target that version (or drop the feature).
- Mitigation: Stay current with iOS updates and test on beta versions before they ship.

**iOS 26 deployment target (raised 2026-06-23):**
- Adoption data at decision time: 66% iOS 26 · 24% iOS 18 · 10% Earlier.
- Risk: 34% of potential users may not be on iOS 26. Users on iOS 18–25 cannot install the app.
- Mitigation: Deliberately chosen to avoid backward-compat branches and ship a cleaner codebase (no `#available` checks for Liquid Glass). Re-evaluate if user adoption lags.

## Missing Critical Features

**BAC (blood alcohol content) implementation:**
- Problem: Roadmap lists "BAC estimate (Widmark — needs design approval before implementation)" as 🗓 planned.
- Blocks: Users cannot see estimated blood alcohol levels; this is a roadmap feature but not a blocker for MVP.
- Status: Not started. Requires design approval + owner hand-verification of the Widmark formula before implementation (per CLAUDE.md "Constraint").
- Dependencies: None; BAC logic uses the same physical density (0.789) as calories, so no calculation module refactor needed.

**Apple Watch companion (plan-0037):**
- Problem: Plan-0037 is in `draft` status (not `in-progress` or `completed`). Watch is listed in the roadmap under "Future / Ideas" as 💡 scope-confirmed.
- Blocks: Users cannot log drinks from their Apple Watch.
- Status: Plan exists but not executed. Scope: iOS app extension (not standalone watchOS), today summary + quick-log glance.
- Dependencies: Requires Watch Connectivity data transport (phone is source of truth) and iCloud sync (plan-0023 Phase B) to be in place first.

**Widget / Lock Screen widget:**
- Problem: Roadmap lists "Widget / Lock Screen widget (today's units)" as 🗓 planned.
- Blocks: Users cannot see today's consumption summary on the home screen or lock screen.
- Status: Not started.
- Dependencies: None; would display data from the already-available `UserProfile` + today's events.

**PDF export of Insights:**
- Problem: User memory note lists "user said 'looks nice, could be exported as PDF with some nice formatting'". Roadmap lists as 💡 Idea, not 🗓 planned.
- Blocks: Users cannot generate a print-friendly report of their Insights.
- Status: Not started.
- Dependencies: Depends on plan-0012 (Insights screen) — already completed.

## Test Coverage Gaps

**No integration tests with real CloudKit:**
- What's not tested: Multi-device sync, conflict resolution, network failures, resumption after network loss.
- Files: `Domain/Persistence/` tests use in-memory stores; `Services/HealthService` mocks HealthKit entirely.
- Risk: CloudKit sync logic (when Phase B enables it) will be untested until devices sync in the wild. The first production bug will likely be a sync edge case.
- Priority: **High.** Before shipping Phase B, add at least two integration tests: (1) simulate a sync conflict (two devices edit the same event at nearly the same time) and verify the LWW (last-write-wins) dedup logic keeps the newer one; (2) simulate a duplicate arrival (same event delivered twice) and verify `RecordDeduplicator` collapses it to one.

**No Health HealthKit integration tests:**
- What's not tested: Real HealthKit sample storage, retrieval, deletion; handling of denied/revoked permission; multi-device Health sync behavior.
- Files: `Services/HealthKitAdapter.swift` is deliberately excluded from coverage as a framework adapter. Tests use `UITestHealthStore` stub.
- Risk: Health write-back works in tests but could fail on real devices due to entitlement issues, permission state changes, or Health store database corruption.
- Priority: **Medium.** Add manual smoke tests on a real device running the app with Health enabled: log a drink, verify it appears in Apple Health; edit it, verify the Health sample updates; delete it, verify the Health sample is removed. Repeat on a fresh install after deleting and reinstalling the app to verify the `dp_event_uuid` metadata key dedup works.

**No UI test for multi-currency spend edge case:**
- What's not tested: Dashboard "Today's Spend" card when events have mixed currencies (currently undefined behavior per open-questions.md).
- Files: `Features/Dashboard/`, `Features/Insights/`
- Risk: Spend display is partial/incomplete; multi-currency data could silently break on the spend card until a fix is deployed.
- Priority: **Low.** Document the current behavior (spend shown only when all events share one currency, or hidden otherwise — option A per open-questions.md) in a comment and add a UI test pinning that behavior once the design is decided.

## Unresolved Design Decisions

**Multi-currency spend aggregation (open-questions.md):**
- Question: When drinks in different currencies exist, how should "Today's Spend" be aggregated on the Dashboard?
- Options: (A) Show spend only when all of today's priced drinks share one currency; otherwise hide card. (B) Show spend with a warning label ("Mixed currencies"). (C) Convert to a base currency (requires exchange rates — out of scope).
- Current state: `priceCurrency` field exists per event; spend is not displayed anywhere yet (plan-0034 was entry-only).
- To resolve: Owner picks option A, B, or C before any display logic is implemented.

**Guideline alert card tap action (open-questions.md):**
- Question: What happens when the user taps the red `GuidelineAlertCard` on the Dashboard?
- Options: (A) Switch to Settings tab. (B) Open guideline picker sheet directly. (C) No action (non-tappable).
- Current state: Card is rendered non-tappable (option C by default).
- To resolve: Owner picks option before implementing tap action.

**Apple Watch data transport architecture (open-questions.md):**
- Question: Does the watch app read directly from the shared CloudKit store, or does it use Watch Connectivity to relay events to the iPhone for persistence?
- Current state: Not started. Depends on iCloud sync (plan-0023) being in place first.
- To resolve: Architect data flow before the watchOS target is added. Blocked on plan-0023 Phase B completion.

---

*Concerns audit: 2026-07-18*
