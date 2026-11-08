# Phase 10: Data & Platform Integration Modernization - Context

**Gathered:** 2026-11-08
**Status:** Ready for planning (amended 2026-11-08: D-20 coverage-scope waiver added by the owner)

<domain>
## Phase Boundary

Phase 10 proves, and only where evidence demands it changes, the domain, persistence, service and concurrency layers on iOS 27. Existing data and system behavior must be preserved. It covers MOD-03, DATA-01, INT-01 and INT-02.

The approved Phase 08 scope (C008–C012) is narrow. The data model, migration plan and backup format do not change without a concrete business reason. Concurrency fixes happen only where diagnostics prove a problem. Most of the phase is verification evidence and focused regression tests, not rewrites. CloudKit remains disabled.

</domain>

<decisions>
## Implementation Decisions

### Legacy-store and current-store proof (DATA-01, C008)
- **D-01:** Keep the programmatic in-test seeding of legacy stores used by today's `MigrationTests`, and extend it with full-path chained migrations: V1→V4, V2→V4 and V3→V4, each opened under `MigrationPlan`. No committed binary `.store`/`.sqlite` fixtures.
- **D-02:** After migration, assert every stored property of every entity: `ConsumptionEvent`, `DrinkTemplate` and `UserProfile`. This includes `uuid`, `modifiedDate`, creation dates, volume/quantity/ABV inputs, price/currency, notes, names and `healthKitUUID`. Asserting counts or calculation inputs alone is not enough.
- **D-03:** Migration tests must fail if `StoreBootstrap` took its recovery branch (store moved aside) or produced a `StartupError`. A silent move-aside must never pass as a successful migration.
- **D-04:** Run `RecordDeduplicator.sweep` against each migrated legacy store in tests. Assert that no legitimate migrated record is merged or dropped, because the sweep runs on every launch.
- **D-05:** The "existing current store" proof is the owner's real on-device store, checked by a documented human step. Before upgrading, export a JSON backup from Settings and keep it locally (never uploaded). Then install the iOS 27 build over the existing install without deleting the app. Confirm that events, templates and profile are intact and that no recovery or startup error appeared.
- **D-06:** If any proof exposes a real migration or persistence defect, stop that fix and write an owner decision brief (Phase 08 D-09–D-11) before planning it. Any fix that touches the model shape must add a new `SchemaV5` plus a new `MigrationStage`. Shipped `SchemaV1`–`SchemaV4` are never edited. — **Reversibility:** one-way — a new schema version and migration stage installed on a device cannot be undone without another migration.

### Backup/export compatibility (C009)
- **D-07:** Add a sanitized real export as a test fixture: the owner's pre-upgrade export from D-05, scrubbed of every personal value. Scrubbed values include notes, custom names, prices, body metrics, DOB, exact timestamps tied to the person and any free text. Keep the structure, the format version and representative field shapes. The owner must review the scrubbed file before it is committed. Unscrubbed health data must never enter the repo. — **Reversibility:** one-way — anything committed to git history persists, so a scrubbing miss cannot be cleanly retracted.
- **D-08:** The device check includes an import round-trip: import the pre-upgrade export into the upgraded app and confirm unchanged counts, with no duplicates (an LWW upsert no-op).
- **D-09:** Existing round-trip, upsert, edge-case and DrinkControl importer tests are re-run on iOS 27. The export format, v1/v2 decode rules and importer behavior stay unchanged (C009 retain).

### Concurrency audit (MOD-03, C010–C012)
- **D-10:** A concurrency change is allowed only when at least one of these exists: a Swift 6.4 / Xcode 27 data-race diagnostic, a Thread Sanitizer report from a scoped test run, or a failing interruption/parallel-operation test. Without that, the code is retained.
- **D-11:** When the audit finds no problem, Phase 10 still leaves two things. First, a per-candidate retain record (C010, C011, C012) naming the evidence checked. Second, focused tests that pin the guarantees: HealthKit per-event serial write/update/delete ordering (`runSerial`), cancel-on-opt-out for reminders and the weekly summary, and no work continuing after user intent.
- **D-12:** The existing `@unchecked Sendable` sites stay unless proven unnecessary: the notification center conformance, `NotificationActionHandler` and the HealthKit adapters. Re-verify each inline justification against the iOS 27 SDK annotations. Remove one only if the SDK now makes it Sendable, the build stays warning-free, and behavior is unchanged. Any isolation or lifecycle change goes through a brief first.
- **D-13:** Every applied concurrency change records its isolation/lifecycle reasoning, the official source and the regression evidence (MOD-03).

### Notifications (INT-01)
- **D-14:** Add an automated UI test for the warm-launch notification tap. The app is running/backgrounded, a tap is delivered through the existing `UITestNotificationCenter` / `pendingOpenInsights` seam, and the app foregrounds onto the Insights tab. This ends the v1.1 "warm path untested" accepted non-goal. Also document a real-device warm tap check.
- **D-15:** Daily and weekly opt-in, scheduling, completed-week comparison and cold-tap routing are covered by the existing tests, re-run on iOS 27. Gaps found during the audit get focused tests.
- **D-16:** Change the weekly summary notification copy so every variant names both compared periods. For example: "Last week you drank %d%% less alcohol than the week before." Change the "down" message (`weeklySummary.notification.body.down`) and apply the same clarity to `body.up`, `body.same`, `body.directionOnlyUp` and `body.directionOnlySame`. Keep the existing placeholders. English only. `WeeklySummaryCalculator` logic and the ±5% band stay unchanged. Verify that the wording matches the periods the calculator compares.
- **D-17:** Close the cold-launch todo with a real-device measurement. Launch from the Home Screen with no debugger attached and record the `ViewLoadLogger` "Dashboard appeared" and `RecordDeduplicator.sweep` timings. If launch time is near container-load time, close the todo as "not an app-code bug" and keep the shipped lazy-center fixes. Otherwise, write an owner brief before any further startup change (startup/lifecycle is a D-09 trigger).

### HealthKit (INT-02)
- **D-18:** Keep the automated coverage on `FakeHealthStore` / `UITestHealthStore`. Add a documented real-device check on the owner's iPhone covering:
  - the permission prompt and the opt-in flow (off by default)
  - write on log, update on edit, and delete
  - confirmation in the Health app that there is exactly one sample per `dp_event_uuid` (no duplicates)
  - delete still non-blocking

  `healthKitUUID` stays device-local and is not exported.
- **D-19:** CloudKit stays disabled. No change may enable it or weaken the CloudKit-safe model shape (ADR-0010).

### Coverage scope (owner waiver, amended after planning)
- **D-20:** (Owner decision, 2026-11-08, recorded via the plan-phase max-iterations gate.) Phase 10 gates the AGENTS.md Domain 100% coverage target only on the non-Persistence Domain files that Phase 10 itself changes, computed from `git diff` against the phase base commit `fbd37fa`. The pre-existing Domain coverage gap stays out of this phase's gate: it is tracked in `.planning/WINDOWS.md` row 7 (Domain layer 89.39% at Phase 07, 15 of 32 files below 100%; row 1 holds the older file-level subset) and is left open there for a separate gap-closure task. Phase 10 records the Domain aggregate as information and cites WINDOWS.md row 7 and this decision; it does not gate on it, does not remediate that gap, and does not close or waive the WINDOWS.md rows. The overall 90% and Services 85% targets are unchanged and stay gated. — **Reversibility:** reversible — a coverage-gate scope decision with no stored-data or contract effect; the WINDOWS.md rows stay open.

### Claude's Discretion
- Exact test file layout, following the mirror-the-source-tree rule.
- How the recovery-not-fired assertion is exposed (a test seam on `StoreBootstrap` vs inspecting the store directory).
- The scrubbing method for the sanitized export fixture, subject to D-07 owner review.
- Whether TSan runs per test class or as one scoped Services/Persistence pass.

### Folded Todos
- **Defer `UNUserNotificationCenter.current()` out of RootShellView cold-launch path** (`.planning/todos/pending/2026-08-01-defer-unusernotificationcenter-current-out-of-rootshellview-cold-launch.md`). The lazy-center and delegate fixes already shipped. Phase 10 does the pending debugger-detached device re-measurement and closes or escalates the todo per D-17.
- **Clarify weekly alcohol summary comparison** (`.planning/todos/pending/2026-09-15-clarify-weekly-alcohol-summary-comparison.md`). This is a copy-only change per D-16. The Polish wording in the todo does not apply, because the app is English-only.
- **Migrate project to iOS 27 and modernize codebase** (`.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md`). Phase 10 delivers its data/persistence/services/concurrency slice.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Scope and owner rules
- `.planning/ROADMAP.md`: Phase 10 goal and the 5 success criteria.
- `.planning/REQUIREMENTS.md`: MOD-03, DATA-01, INT-01, INT-02.
- `.planning/PROJECT.md`: privacy invariants, the official-Apple-docs rule and the owner-brief rule for substantial discoveries.
- `AGENTS.md` (via `CLAUDE.md`): the schema immutability rule (never amend a shipped `VersionedSchema`), CloudKit/HealthKit forward-compat, logging/PII rules, the Services coverage target and the scoped-test gate.
- `.planning/WINDOWS.md`: row 7 (pre-existing Domain coverage gap, left open per D-20) and row 1 (older file-level subset of the same gap).

### Phase 08 handoff and approved scope
- `.planning/phases/08-ios-27-baseline-api-inventory/08-CONTEXT.md`: milestone decisions D-01–D-13 (brief gate D-09–D-11).
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-REGISTER.md`: the authoritative approved scope for C008–C012.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C008.md`: VersionedSchema/MigrationPlan boundary.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C009.md`: export/import boundary.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C010.md`: notification concurrency audit.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C011.md`: HealthKit concurrency audit and invariants (`dp_event_uuid`, local cache, delete ordering).
- `.planning/phases/08-ios-27-baseline-api-inventory/08-DECISION-C012.md`: async cleanup and cancellation audit.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-INVENTORY-DATA.md`: rows D-01–D-05, S-01–S-03, N-D01–N-D06 with exact locations and official sources.
- `.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md`: iOS 27 toolchain, simulator and command baseline.

### ADRs
- `docs/decisions/0008-services-layer.md`: Services protocol/DI pattern.
- `docs/decisions/0009-versioned-schema-and-migration-plan.md`: schema versioning and migration stages.
- `docs/decisions/0010-cloudkit-ready-identity-and-lww.md`: UUID/LWW identity and the CloudKit-safe shape.
- `docs/decisions/0011-health-write-back-and-device-local-sample-identity.md`: Health write-back and device-local sample identity.
- `docs/domain.md`: calculations, units and the export format.

### Folded todos
- `.planning/todos/pending/2026-08-01-defer-unusernotificationcenter-current-out-of-rootshellview-cold-launch.md`
- `.planning/todos/pending/2026-09-15-clarify-weekly-alcohol-summary-comparison.md`
- `.planning/todos/pending/2026-09-15-migrate-project-to-ios-27-and-modernize-codebase.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `drinkpulseTests/Domain/Persistence/MigrationTests.swift`: seeds V1/V2/V3 stores on disk with `Schema(versionedSchema:)` and checks single-step migrations. Extend it for chained, every-field and dedup-sweep checks.
- `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift`, `RecordDeduplicatorTests.swift`: existing seams for recovery and dedup.
- `drinkpulseTests/Domain/DataTransfer/*`: round-trip/upsert/edge/DrinkControl importer suites. The sanitized fixture plugs in here.
- `drinkpulseTests/Services/FakeHealthStore.swift`, `HealthService*Tests`, `HealthWriteHooksTests`, `ReminderServiceTests`, `WeeklySummaryService*Tests`: fakes for the serial-ordering and cancellation pin tests.
- `drinkpulse/Services/UITestNotificationCenter.swift`, `UITestHealthStore.swift`: UI-test seams. `drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift` covers cold launch only; the warm test goes next to it.
- `drinkpulse/Diagnostics/ViewLoadLogger.swift`: startup timing for D-17.

### Established Patterns
- Schemas `SchemaV1`–`SchemaV4` in `drinkpulse/Domain/Persistence/Schemas/` are frozen snapshots. `MigrationPlan.swift` chains the stages.
- Services are `@MainActor` behind protocols (`NotificationScheduling`, `HealthWriting`) with injected fakes. HealthKit uses `runSerial` per event UUID.
- Strings go through `Localizable.xcstrings` / `String(localized:)`, English only.

### Integration Points
- `drinkpulse/Domain/Persistence/StoreBootstrap.swift`: recovery branch (D-03).
- `drinkpulse/Domain/Persistence/RecordDeduplicator.swift`: launch sweep (D-04).
- `drinkpulse/Services/WeeklySummaryService.swift` + `drinkpulse/Localizable.xcstrings` (`weeklySummary.notification.body.*`): copy change (D-16).
- `drinkpulse/Services/NotificationScheduling.swift`, `NotificationActionHandler.swift`, `HealthKitAdapter.swift`: `@unchecked Sendable` sites (D-12).

</code_context>

<specifics>
## Specific Ideas

- Order of the device session: (1) export a backup, (2) install the iOS 27 build over the existing install, (3) verify the data, (4) import the backup and check for no duplicates, (5) do the HealthKit and notification device checks, (6) do the debugger-detached launch measurement.
- Example copy: "Last week you drank %d%% less alcohol than the week before."

</specifics>

<deferred>
## Deferred Ideas

None. The discussion stayed within phase scope.

</deferred>

---

*Phase: 10-data-platform-integration-modernization*
*Context gathered: 2026-11-08*
