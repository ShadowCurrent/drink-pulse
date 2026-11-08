# Phase 10: Data & Platform Integration Modernization - Research

**Researched:** 2026-11-08
**Domain:** SwiftData migration proof, Swift 6 concurrency audit, UserNotifications, HealthKit (iOS 27, Xcode 27.2, Swift 6.4 compiler in Swift 6.0 language mode)
**Confidence:** HIGH for repo-derived facts and probe results; MEDIUM for device-only behaviors (cannot be run here)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Legacy-store and current-store proof (DATA-01, C008)**
- **D-01:** Keep the programmatic in-test seeding of legacy stores used by today's `MigrationTests`, and extend it with full-path chained migrations: V1→V4, V2→V4 and V3→V4, each opened under `MigrationPlan`. No committed binary `.store`/`.sqlite` fixtures.
- **D-02:** After migration, assert every stored property of every entity: `ConsumptionEvent`, `DrinkTemplate` and `UserProfile`. This includes `uuid`, `modifiedDate`, creation dates, volume/quantity/ABV inputs, price/currency, notes, names and `healthKitUUID`. Asserting counts or calculation inputs alone is not enough.
- **D-03:** Migration tests must fail if `StoreBootstrap` took its recovery branch (store moved aside) or produced a `StartupError`. A silent move-aside must never pass as a successful migration.
- **D-04:** Run `RecordDeduplicator.sweep` against each migrated legacy store in tests. Assert that no legitimate migrated record is merged or dropped, because the sweep runs on every launch.
- **D-05:** The "existing current store" proof is the owner's real on-device store, checked by a documented human step. Before upgrading, export a JSON backup from Settings and keep it locally (never uploaded). Then install the iOS 27 build over the existing install without deleting the app. Confirm that events, templates and profile are intact and that no recovery or startup error appeared.
- **D-06:** If any proof exposes a real migration or persistence defect, stop that fix and write an owner decision brief (Phase 08 D-09–D-11) before planning it. Any fix that touches the model shape must add a new `SchemaV5` plus a new `MigrationStage`. Shipped `SchemaV1`–`SchemaV4` are never edited. — **Reversibility:** one-way — a new schema version and migration stage installed on a device cannot be undone without another migration.

**Backup/export compatibility (C009)**
- **D-07:** Add a sanitized real export as a test fixture: the owner's pre-upgrade export from D-05, scrubbed of every personal value. Scrubbed values include notes, custom names, prices, body metrics, DOB, exact timestamps tied to the person and any free text. Keep the structure, the format version and representative field shapes. The owner must review the scrubbed file before it is committed. Unscrubbed health data must never enter the repo. — **Reversibility:** one-way — anything committed to git history persists, so a scrubbing miss cannot be cleanly retracted.
- **D-08:** The device check includes an import round-trip: import the pre-upgrade export into the upgraded app and confirm unchanged counts, with no duplicates (an LWW upsert no-op).
- **D-09:** Existing round-trip, upsert, edge-case and DrinkControl importer tests are re-run on iOS 27. The export format, v1/v2 decode rules and importer behavior stay unchanged (C009 retain).

**Concurrency audit (MOD-03, C010–C012)**
- **D-10:** A concurrency change is allowed only when at least one of these exists: a Swift 6.4 / Xcode 27 data-race diagnostic, a Thread Sanitizer report from a scoped test run, or a failing interruption/parallel-operation test. Without that, the code is retained.
- **D-11:** When the audit finds no problem, Phase 10 still leaves two things. First, a per-candidate retain record (C010, C011, C012) naming the evidence checked. Second, focused tests that pin the guarantees: HealthKit per-event serial write/update/delete ordering (`runSerial`), cancel-on-opt-out for reminders and the weekly summary, and no work continuing after user intent.
- **D-12:** The existing `@unchecked Sendable` sites stay unless proven unnecessary: the notification center conformance, `NotificationActionHandler` and the HealthKit adapters. Re-verify each inline justification against the iOS 27 SDK annotations. Remove one only if the SDK now makes it Sendable, the build stays warning-free, and behavior is unchanged. Any isolation or lifecycle change goes through a brief first.
- **D-13:** Every applied concurrency change records its isolation/lifecycle reasoning, the official source and the regression evidence (MOD-03).

**Notifications (INT-01)**
- **D-14:** Add an automated UI test for the warm-launch notification tap. The app is running/backgrounded, a tap is delivered through the existing `UITestNotificationCenter` / `pendingOpenInsights` seam, and the app foregrounds onto the Insights tab. This ends the v1.1 "warm path untested" accepted non-goal. Also document a real-device warm tap check.
- **D-15:** Daily and weekly opt-in, scheduling, completed-week comparison and cold-tap routing are covered by the existing tests, re-run on iOS 27. Gaps found during the audit get focused tests.
- **D-16:** Change the weekly summary notification copy so every variant names both compared periods. For example: "Last week you drank %d%% less alcohol than the week before." Change the "down" message (`weeklySummary.notification.body.down`) and apply the same clarity to `body.up`, `body.same`, `body.directionOnlyUp` and `body.directionOnlySame`. Keep the existing placeholders. English only. `WeeklySummaryCalculator` logic and the ±5% band stay unchanged. Verify that the wording matches the periods the calculator compares.
- **D-17:** Close the cold-launch todo with a real-device measurement. Launch from the Home Screen with no debugger attached and record the `ViewLoadLogger` "Dashboard appeared" and `RecordDeduplicator.sweep` timings. If launch time is near container-load time, close the todo as "not an app-code bug" and keep the shipped lazy-center fixes. Otherwise, write an owner brief before any further startup change (startup/lifecycle is a D-09 trigger).

**HealthKit (INT-02)**
- **D-18:** Keep the automated coverage on `FakeHealthStore` / `UITestHealthStore`. Add a documented real-device check on the owner's iPhone covering: the permission prompt and the opt-in flow (off by default); write on log, update on edit, and delete; confirmation in the Health app that there is exactly one sample per `dp_event_uuid` (no duplicates); delete still non-blocking. `healthKitUUID` stays device-local and is not exported.
- **D-19:** CloudKit stays disabled. No change may enable it or weaken the CloudKit-safe model shape (ADR-0010).

### Claude's Discretion
- Exact test file layout, following the mirror-the-source-tree rule.
- How the recovery-not-fired assertion is exposed (a test seam on `StoreBootstrap` vs inspecting the store directory).
- The scrubbing method for the sanitized export fixture, subject to D-07 owner review.
- Whether TSan runs per test class or as one scoped Services/Persistence pass.

### Deferred Ideas (OUT OF SCOPE)
None. The discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOD-03 | Approved modernization of domain, persistence, service and concurrency implementations is applied with documented isolation/lifecycle reasoning and regression evidence. | Concurrency audit results (probes, TSan, SDK annotation check), Sendable disposition table, retain-record content, brief-gating rules |
| DATA-01 | Existing stores retain events, templates, profile, identities and stored values; legacy fixtures and a current-store upgrade pass without reset; shipped schemas immutable. | V1/V2/V3→V4 chain probe, per-version field-determinism table, recovery-not-fired seam, sweep test, device procedure, fixture traps |
| INT-01 | Daily and weekly notifications preserve opt-in, scheduling, completed-week calculations and cold/warm tap routing on iOS 27. | Existing test inventory, warm-tap seam design (`route(identifier:)`), weekly-content staleness finding, delegate-timing risk, copy-change test plan |
| INT-02 | HealthKit preserves permission handling, opt-in, write/delete and UUID dedup on iOS 27; CloudKit remains disabled. | Edit-then-delete orphan probe, HealthKitAdapter Sendable finding, device checklist, CloudKit-off grep gate |
</phase_requirements>

## Summary

Phase 10 is mostly proof, not rewrite. Research ran the real toolchain on this machine (Xcode 27.2, iOS 27.2 simulator) and found that the current tree builds, passes 74 scoped tests, and a chained V1→V4 migration opens in a single `MigrationPlan` open with data intact. The honest expectation from CONTEXT ("most of the phase is verification evidence") holds for persistence, export/import and the CloudKit-off boundary.

The audit is NOT going to be clean for concurrency. Two throwaway probe tests (run in a scratch copy of the repo, nothing changed in this repo) produced real failures that satisfy D-10's third trigger ("a failing interruption/parallel-operation test"): (1) a HealthKit edit followed quickly by delete leaves an orphan sample in Health, because `HealthWriteHooks.remove` captures a stale `healthKitUUID`; (2) cancelling a reminder while `schedule` is suspended inside `center.add` leaves a stale pending request. Both change system-integration semantics, so per Phase 08 D-09 each needs an owner decision brief before any fix is planned. Plans must pin current behavior with `withKnownIssue` tests, write the brief, then fix only after approval.

A third finding affects D-16 directly. The weekly notification body is computed at app-foreground time from "last week vs the week before" and then delivered as a repeating weekly trigger with static content. At delivery time that content is normally one week stale. The D-16 example copy ("Last week you drank ... than the week before") would therefore be factually wrong in the common case, and the D-16 rule "keep the existing placeholders" prevents naming concrete dates. This needs an owner decision before the copy task is planned (Open Question 1).

**Primary recommendation:** Plan four tracks: (A) migration/backup proof tests with a recovery-reporting seam, (B) concurrency pin tests plus two owner briefs (Health orphan, reminder cancel race) and one `@unchecked Sendable` removal (`HealthKitAdapter`), (C) notification warm-tap seam plus weekly-copy brief, (D) a documented single device session. Gate every behavior-changing fix behind a brief.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Schema versions, migration stages, store open/recovery | Domain/Persistence (`StoreBootstrap`, `MigrationPlan`, `SchemaV1-V4`) | SwiftData / SQLite | Stage logic is app code; physical migration is SwiftData |
| Launch dedup sweep | Domain/Persistence (`RecordDeduplicator`) | App entry (`drinkpulseApp` `.onAppear`) | Runs on every launch on MainActor |
| Backup export/import | Domain/DataTransfer | Settings views (UI trigger only) | Format and LWW upsert rules live in Domain |
| Notification scheduling, cancel | Services (`ReminderService`, `WeeklySummaryService`) behind `NotificationScheduling` | UserNotifications daemon | Protocol-injected, `@MainActor` |
| Notification tap routing | Services (`NotificationActionHandler`) | Shell view (`RootShellView`) consumes flag/notification | Delegate posts; shell navigates |
| Opt-in toggle intent | Settings section views (`ReminderSection`, `WeeklySummarySection`, `HealthSection`) | Services | Views own `enabled` state and the cancel-on-off call |
| Health write/update/delete ordering | Services (`HealthService.runSerial`) | `HealthKitAdapter` -> HealthKit | Per-event serialization is service state |
| Weekly comparison math | Domain (`WeeklySummaryCalculator`, pure) | `WeeklySummaryService` supplies ranges | Calculator is unchanged per D-16 |
| Cold-launch timing evidence | Diagnostics (`ViewLoadLogger`, DEBUG only) + `startupLog` | Real device | Cannot be proven in simulator |

## Standard Stack

No new external packages. This phase uses only the existing toolchain and frameworks.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SwiftData (`VersionedSchema`, `SchemaMigrationPlan`, `MigrationStage`) | iOS 27 SDK | Existing migration infrastructure | Retained per C008; `VersionedSchema` available since iOS 17, no deprecation stated [CITED: developer.apple.com/documentation/swiftdata/versionedschema] |
| Swift Testing (`@Test`, `#expect`, `withKnownIssue`) | Xcode 27.2 | New unit tests | Project rule: Swift Testing for new tests [CITED: AGENTS.md "Test quality rules"] |
| XCTest/XCUITest | Xcode 27.2 | UI test for warm tap | Existing UI tests use XCTest [VERIFIED: drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift:1] |
| UserNotifications, HealthKit | iOS 27.2 SDK | Existing integrations | Retained |
| Thread Sanitizer via `xcodebuild -enableThreadSanitizer YES` | Xcode 27.2 | D-10 trigger 2 evidence | Flag listed in `xcodebuild -help` [VERIFIED: local run `xcodebuild -help`] |

### Supporting
| Tool | Purpose | When to Use |
|------|---------|-------------|
| `xcrun devicectl` | Install/launch on the paired iPhone without a debugger | Device session D-17 (`devicectl list devices` showed a paired "iPhone" iPhone 15 Pro) [VERIFIED: local run] |
| Console.app | Read `com.drinkpulse.app` logs from a detached device launch | D-17 timings |
| `xcodebuild -only-testing:drinkpulseTests/<ClassName>` | Scoped runs | Every task; this form was verified to run (74 tests) [VERIFIED: local run] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Programmatic legacy seeding (D-01) | Committed `.sqlite` fixtures | Rejected by D-01 |
| `StoreBootstrap` recovery seam | Inspect `RecoveredStores` directory | Directory is shared Application Support state mutated by other tests in the same host (see Pitfall 4); flaky |

**Installation:** none.

**Version verification:** `xcodebuild -version` reports Xcode 27.2 build 27B52 [VERIFIED: local run]. Installed simulators include iOS 27.0 and iOS 27.2 runtimes [VERIFIED: `xcrun simctl list devices available`]. Phase 08 baseline used iOS 27.0 / Xcode 27.0 (`08-BASELINE.md`); this research ran on iOS 27.2 (iPhone 18 Pro, `B4A1A1F8-A0E2-4186-BAFD-1A02679DD4EC`). Record the destination actually used in every evidence file; the UDID is machine-specific.

## Package Legitimacy Audit

No external packages are installed or recommended in this phase (project rule: no third-party SDKs). Audit table not applicable.

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

## Architecture Patterns

### System Architecture Diagram

```
LAUNCH PATH
 drinkpulseApp.init
   |-- Task.detached --> UNUserNotificationCenter.current() --> MainActor: center.delegate = NotificationActionHandler
   v
 .task loadContainerIfNeeded
   |-- UITestSeed.isActive? --> in-memory container + MigrationPlan (never real migration)
   '-- production --> StoreBootstrap.makeContainer
          |-- ModelContainer(migrationPlan: MigrationPlan)  --success--> ready
          '-- throws --> recoverStore (move files to RecoveredStores) --> retry --> ready | StartupError
   v
 RootShellView.onAppear --> RecordDeduplicator.sweep (events, templates, profile)
                        --> openAddDrinkIfPending / openInsightsIfPending (cold-tap flags)
   v
 scenePhase == .active --> ReminderService.scheduleIfEnabled / WeeklySummaryService.scheduleIfEnabled

NOTIFICATION TAP (system -> app)
 tap --> NotificationActionHandler.didReceive(identifier)
          |-- set UserDefaults pending flag        (cold launch: RootShellView.onAppear reads it)
          '-- MainActor: NotificationCenter.post   (warm: RootShellView .task stream reads it)
                --> selectedTab = .insights | showAddDrink = true

OPT-IN / OPT-OUT (Settings view -> service -> OS)
 toggle ON  --> requestAuthorization --> enabled=true --> schedule: remove, await add
 toggle OFF --> enabled=false --> cancel: remove          <-- can run while a schedule is suspended in add (Finding F3)

HEALTH (view/hook -> service -> adapter -> HealthKit)
 HealthWriteHooks.write/update/remove --> Task --> HealthService.runSerial(event.uuid)
     write : sampleUUID(dp_event_uuid) relink-or-save
     update: delete cached sample, then write fresh
     remove: delete by CAPTURED healthKitUUID, else query by dp_event_uuid   <-- captured value can be stale (Finding F2)
```

### Recommended Project Structure (new/changed files only; tests mirror source tree)
```
drinkpulse/
├── Domain/Persistence/StoreBootstrap.swift          # add recovery-reporting seam (test seam only; production signature unchanged)
├── Services/NotificationActionHandler.swift         # extract static route(identifier:) so tests can drive it
├── Services/HealthKitAdapter.swift                  # @unchecked Sendable -> Sendable (F5)
├── Localizable.xcstrings                            # D-16 copy (after brief)
drinkpulseTests/
├── Domain/Persistence/MigrationChainTests.swift     # V1/V2/V3 -> V4, every field (new)
├── Domain/Persistence/MigrationFixtures.swift       # shared seeding helpers (new)
├── Domain/Persistence/MigrationSweepTests.swift     # D-04 (new)
├── Domain/DataTransfer/SanitizedBackupFixtureTests.swift
├── Domain/DataTransfer/Fixtures/sanitized-export-v2.json   # NOT named drinkpulse-backup-*.json (Pitfall 1)
├── Services/HealthServiceConcurrencyTests.swift     # runSerial pins + edit-then-delete (known issue until fix)
├── Services/ReminderServiceCancellationTests.swift
├── Services/WeeklySummaryServiceCancellationTests.swift
├── Services/NotificationActionHandlerTests.swift
└── Services/WeeklySummaryCopyTests.swift
drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift   # add warm-launch test next to the cold one
```

### Pattern 1: Chained-migration proof opened under the plan, failing on recovery
**What:** Seed an old store with `Schema(versionedSchema: SchemaVn.self)` and a plain `ModelContainer`, close it, reopen the same URL with the live `Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])` under `MigrationPlan`.
**When to use:** Every D-01 test.
**Example (verified to pass in a scratch probe; adapt, do not copy blindly):**
```swift
// Source: scratch probe run 2026-11-08, mirrors drinkpulseTests/Domain/Persistence/MigrationTests.swift:114-134
let s = Schema(versionedSchema: SchemaV1.self)
let c = try ModelContainer(for: s, configurations: [ModelConfiguration(schema: s, url: u)])
// insert SchemaV1.DrinkTemplate / SchemaV1.ConsumptionEvent(template:) / SchemaV1.UserProfile, save, drop container
let live = Schema([DrinkTemplate.self, ConsumptionEvent.self, UserProfile.self])
let migrated = try ModelContainer(for: live, migrationPlan: MigrationPlan.self,
                                  configurations: [ModelConfiguration(schema: live, url: u)])
```
Opening directly with `ModelContainer(... migrationPlan:)` throws on any failure and never recovers, so it satisfies D-03 for the migration itself. To also exercise `StoreBootstrap` (the D-03 wording), add the recovery-reporting seam (Pattern 2).

### Pattern 2: Recovery-reporting seam (Claude's Discretion item)
**What:** Add an internal variant, e.g. `StoreBootstrap.makeContainerReportingRecovery(schema:configuration:) throws -> (container: ModelContainer, didRecover: Bool)`, and make `makeContainer` call it and return `.container`. Production behavior and signature unchanged.
**Why not inspect the directory:** `RecoveredStores` is `Application Support/RecoveredStores` of the shared test host and is written/cleared by `StoreBootstrapTests` (`recoverStore_keepsAtMostMaxSnapshots`, `clearRecoveredStores_removesFolder`) [VERIFIED: drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift:49-120]. Swift Testing runs tests in parallel by default, so a directory assertion is racy.
**Belt and braces:** also assert the original store URL still exists and the post-open fetch returns the seeded rows.

### Pattern 3: Pin current-but-wrong behavior with `withKnownIssue`
Failing probes must not turn the suite red before the owner decides. Wrap the failing expectation in `withKnownIssue("<finding id>: <one line>") { #expect(...) }`. When the approved fix lands, remove the wrapper in the same commit (the test then becomes the regression test). [ASSUMED: `withKnownIssue` semantics from training knowledge; confirm with DocumentationSearch/Xcode before use.]

### Pattern 4: Warm-tap seam
`UNNotificationResponse` and `UNNotification` have `init` marked `NS_UNAVAILABLE` [VERIFIED: iPhoneOS27.2.sdk UserNotifications/UNNotificationResponse.h:29, UNNotification.h:23], so neither tests nor UI tests can fabricate a tap. Extract the body of `didReceive` into `NotificationActionHandler.route(identifier:defaults:)` (static; sets the pending flag, then posts `didTapReminder` / `didTapWeeklySummary` on MainActor). `didReceive` calls it. Then:
- Unit tests call `route` with `ReminderService.reminderIdentifier` and `WeeklySummaryService.weeklySummaryIdentifier` using an injected `UserDefaults` suite and observe the posted notification.
- The warm UI test needs an in-app trigger gated on a launch argument (existing pattern: `-dp_uitest`, `-dp_uitest_pending_open_insights`, defined in `drinkpulse/UITestSeed.swift:24-30`). Recommended: a new launch argument that arms a one-shot "on next return from background, call `route(identifier: weeklySummaryIdentifier)`" hook in `RootShellView`'s existing `onChange(of: scenePhase)`. Test flow: launch, assert Home tab is selected, `XCUIDevice.shared.press(.home)`, assert `app.state == .runningBackground`, `app.activate()`, assert `app.navigationBars["Insights"]` exists (same assertion style as `WeeklySummaryTapUITests.swift:16`). Do not drive the system notification banner (AGENTS.md forbids matching system UI by localized label).

### Anti-Patterns to Avoid
- **Editing `SchemaV1`-`SchemaV4`:** forbidden by AGENTS.md; amending a shipped schema changes its hash and sends devices into recovery.
- **Asserting `uuid`/`modifiedDate` equality across a V1 migration:** V1 has no `uuid`; the V1→V2 stage assigns fresh UUIDs and `.now` (see Migration Determinism table).
- **Putting the fix before the brief:** a behavior fix in Health or notification semantics is a D-09 trigger regardless of size.
- **Rewriting `runSerial` or actor structure:** C010-C012 authorize only point fixes backed by a failing test.

## Migration Determinism (what D-02 can and cannot assert)

Verified by reading `MigrationPlan.swift:16-61`, `SchemaV1.swift`, `SchemaV2.swift`, `SchemaV3.swift`, `SchemaV4.swift`, and by a probe that opened a V1 store under `MigrationPlan`.

| Path | Stage behavior | Assertable after migration | NOT assertable as equal to pre-migration |
|------|----------------|----------------------------|------------------------------------------|
| V1→V4 | `v1ToV2` custom: events `uuid = UUID()`, `modifiedDate = event.timestamp`; templates `uuid = UUID()`, `modifiedDate = .now`; profiles `modifiedDate = .now`. `v2ToV3`: `creationDate = consumptionDate`. `v3ToV4` lightweight (adds `healthKitUUID`, nil). | volumeMl, abv, quantity, enteredUnit, category, icon, customName, notes, price, priceCurrency, template relationship, consumptionDate; event `modifiedDate == consumptionDate`; `creationDate == consumptionDate`; `healthKitUUID == nil`; all UUIDs non-nil and pairwise unique; template/profile `modifiedDate` within the test's time window and not the epoch sentinel; profile all stored fields | event/template `uuid` (V1 had none); V1 `ConsumptionEvent.name` (dropped in V2 by design, ADR-0010 "remove the deprecated `ConsumptionEvent.name`") |
| V2→V4 | `v2ToV3` then lightweight | `uuid` preserved exactly; `modifiedDate` preserved; `creationDate == consumptionDate`; everything else exact | none beyond `creationDate` which is derived |
| V3→V4 | lightweight only | everything exact incl. `uuid`, `modifiedDate`, `creationDate`; `healthKitUUID == nil` | none |

Probe output (scratch copy, V1 store with template, one event linked to the template, one profile, opened via `ModelContainer(for:migrationPlan:configurations:)`): one event, one template, one profile; event `customName` "Pint", `quantity` 2, `enteredUnit` imperial, `price` 5.4, `template` "Lager", `healthKitUUID` nil, `modifiedDate == consumptionDate` true, `creationDate == consumptionDate` true; template `isFavorite` true, `events.count` 1, fresh uuid; profile `id` "singleton", `bodyWeightKg` 82.5, `alcoholUnit` grams [VERIFIED: scratch probe run 2026-11-08]. The `name` removal is documented in ADR-0010 [VERIFIED: docs/decisions/0010-cloudkit-ready-identity-and-lww.md, Decision 1].

For D-04: V1→V2 gives every row a fresh unique UUID, so the sweep cannot merge anything from a V1 store; the meaningful sweep checks are on V2/V3 seeds with distinct explicit UUIDs, plus a V1 seed with several events sharing identical field values (identical `name`/volume/abv at different timestamps) to prove field equality is not used as identity. `RecordDeduplicator.sweep` groups strictly by `uuid` [VERIFIED: drinkpulse/Domain/Persistence/RecordDeduplicator.swift:25-41]; it also calls `UserProfileStore.deduplicated`, so seed exactly one profile.

## Concurrency Audit Evidence (D-10 triggers)

| Trigger | Result | Evidence |
|---------|--------|----------|
| 1. Swift 6.4 / Xcode 27 data-race diagnostic | NOT met. `build-for-testing` for the whole project on iOS 27.2 simulator succeeded; the only warning in the log was `drinkpulseTests/Services/HealthWriteHooksTests.swift:116:9` "no calls to throwing functions occur within 'try' expression". No production-code warnings or Sendable diagnostics. | [VERIFIED: local build log 2026-11-08] |
| 2. Thread Sanitizer report | NOT met in the runs performed. `-enableThreadSanitizer YES` over HealthService*, HealthWriteHooks, ReminderService, WeeklySummaryService*, MigrationTests, StoreBootstrapTests, RecordDeduplicatorTests: 79 tests passed, no TSan report. Caveat: the xcodebuild log did not echo the sanitizer compile flag, so confirm sanitizer activation in the plan (check the `.xcresult` or run a deliberate racy canary once). | [VERIFIED: local run; activation MEDIUM] |
| 3. Failing interruption/parallel-operation test | MET twice (F2, F3 below). | [VERIFIED: scratch probes] |

Because these services are `@MainActor`, TSan finds nothing: both defects are logical races across `await` suspension points (actor reentrancy), not data races. TSan and the compiler cannot find them; only parallel-operation tests can. Put the TSan pass in the plan as one scoped Services+Persistence run (Claude's Discretion item) and treat "no report" as retain evidence.

### F2 — Health: edit then quick delete leaves an orphan sample (INT-02, C011)
Code: `HealthWriteHooks.remove` captures `event.healthKitUUID` synchronously at call time (`HealthWriteHooks.swift:31`), then calls `removeSample(healthKitUUID:eventUUID:)`. `performRemoveSample` deletes the captured UUID when non-nil and only queries by `dp_event_uuid` when it is nil (`HealthService.swift:128-134`). `performUpdate` deletes the old sample and writes a new one with a new UUID (`HealthService.swift:107-118`). If remove is queued behind an in-flight update, remove deletes the already-deleted old sample and the freshly written one survives.
Probe: `write(event)` -> `t1 = Task { update(event) }`, `t2 = Task { removeSample(healthKitUUID: oldUUID, eventUUID:) }`, await both. Result: `fake.samplesByEvent[event.uuid]` was still non-nil (expected nil) [VERIFIED: scratch probe 2026-11-08]. Real-device impact: a deleted drink remains in Apple Health.
Existing coverage gap: `HealthServiceTests.writeThenRemove_serialized_leavesConsistentState` only awaits write then remove sequentially [VERIFIED: drinkpulseTests/Services/HealthServiceTests.swift:280-292].
Likely minimal fix direction (for the brief, not a decision): in the serialized remove, resolve by `dp_event_uuid` query first (the metadata key is the source of truth per ADR-0011 Decision 2) and fall back to the captured UUID. Preserves `dp_event_uuid`, device-local cache, non-blocking, and per-event ordering.

### F3 — Reminder (and weekly) cancel during in-flight schedule leaves a stale pending request (INT-01, C010/C012)
Code: `ReminderService.schedule` does `removePendingRequests` then `await center.add(...)` (`ReminderService.swift:51-54`); `cancel` only calls `removePendingRequests` (`:56-58`). On `@MainActor`, `cancel` can run while `schedule` is suspended at `add`; the request then lands after the cancel. `WeeklySummaryService.scheduleIfEnabled` has the same remove-then-await-add shape (`WeeklySummaryService.swift:84-89`) and no re-check of the opt-in flag after `add`.
Probe: a fake center whose `add` suspends until released; `Task { schedule }`, wait until `add` entered, `await cancel()`, release `add`, await. Result: pending contained `dp.daily.log.reminder` after the cancel [VERIFIED: scratch probe 2026-11-08; identifier quoted from ReminderService.swift:7 `static let reminderIdentifier = "dp.daily.log.reminder"`]. The weekly service was not probed; same shape, mark as [ASSUMED] until a test is written.
Related asymmetry: `WeeklySummarySection` already guards the enable path with `toggleGeneration` so a toggle-off during the authorization await wins [VERIFIED: drinkpulse/Features/Settings/Components/WeeklySummarySection.swift:5-9, 51-95]; `ReminderSection.enable()` has no such guard, so toggling off while `requestAuthorization` is pending is overwritten by `enabled = true` and a schedule [VERIFIED: drinkpulse/Features/Settings/Components/ReminderSection.swift:61-70, 93-109]. Practical likelihood is low (the system permission alert is modal), but it is the same user-intent class (C012 "no work continuing after user intent").
Likely minimal fix direction (for the brief): re-check the opt-in flag after `add` returns and remove the request if opted out (service-level, testable with a fake), and mirror the generation guard in `ReminderSection`. No actor or cancellation rewrite.

### F5 — `@unchecked Sendable` dispositions (D-12), checked against the iOS 27.2 SDK
| Site | SDK evidence | Probe | Disposition |
|------|--------------|-------|-------------|
| `extension UNUserNotificationCenter: @retroactive @unchecked Sendable` (`NotificationScheduling.swift:11`) | `UNUserNotificationCenter` interface in `UNUserNotificationCenter.h:39` carries no `NS_SWIFT_SENDABLE`, and `UserNotifications.apinotes` has no Sendable entry [VERIFIED: SDK headers] | n/a | RETAIN. Inline justification still valid. |
| `HealthKitAdapter: HealthWriting, @unchecked Sendable` (`HealthKitAdapter.swift:4`) | `HKHealthStore` is `NS_SWIFT_SENDABLE` (`HKHealthStore.h:36-38`); `HKObjectType` is `NS_SWIFT_SENDABLE` (`HKObjectType.h:36-39`); remaining stored property is a `Double` constant [VERIFIED: SDK headers + HealthKitAdapter.swift:5-8] | Changing to plain `Sendable` compiled and tests ran with no new warning in the scratch copy | ELIGIBLE for removal under D-12 (SDK now makes the stored state Sendable, warning-free, behavior unchanged). One-line change; record the SDK source and the build evidence. |
| `NotificationActionHandler: NSObject, ..., @unchecked Sendable` (`NotificationActionHandler.swift:4`) | No SDK annotation involved; the class has no instance state | Plain `Sendable` also compiled warning-free in the scratch copy | RETAIN by the literal D-12 rule (the removal condition is an SDK change). Record that a compile probe shows plain `Sendable` would also compile; offer it to the owner as optional in the same brief as F2/F3. Do not change isolation. |
| `UITestNotificationCenter`, `UITestHealthStore` (`@unchecked Sendable`, mutable dictionaries/arrays) | Mutable state | n/a | RETAIN. Test-only seams, accessed from one actor in practice. |
| `FakeNotificationCenter`, `FakeHealthStore` (tests) | Mutable state | n/a | RETAIN. |

Project setting that explains why this is subtle: the app target uses `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES` [VERIFIED: drinkpulse.xcodeproj/project.pbxproj:436-437, 465-466] with `SWIFT_VERSION = 6.0` [VERIFIED: project.pbxproj:440]. Do not change these settings in this phase.

### F6 — Delegate assignment timing vs documented requirement (INT-01, lifecycle)
`drinkpulseApp.assignNotificationDelegate` sets `center.delegate` from a `Task.detached` hop to MainActor (`drinkpulseApp.swift:35-41`). Apple documentation says the delegate must be assigned before the app finishes launching and that assigning it later might cause missed notifications [CITED: developer.apple.com/documentation/usernotifications/unusernotificationcenterdelegate]. The SDK header says the same for `didReceiveNotificationResponse` [VERIFIED: UNUserNotificationCenter.h:99-101 comment "The delegate must be set before the application returns from application:didFinishLaunchingWithOptions:"]. Cold-tap routing was device-verified in v1.1 and the hop was introduced to remove a launch stall (todo update 2026-08-01), so do NOT change it in this phase without a brief (startup/lifecycle is a D-09 trigger). Instead make the D-14 cold-tap device check repeat several times (kill app fully, tap delivered notification, observe Insights) and record the result; if any miss occurs, write the brief.

### F4 — Weekly summary content is computed for the wrong week at delivery time (INT-01, D-16)
Code: `scheduleIfEnabled` takes `now = Date.now`, compares `dateRange(offset: -1)` against `dateRange(offset: -2)`, bakes the result into `UNNotificationRequest.content.body` and schedules a repeating calendar trigger on `calendar.firstWeekday` at 09:00 [VERIFIED: WeeklySummaryService.swift:34-53, 59-90; InsightsPeriod.swift:37-48]. The request is rebuilt on each scene-active, but if the app was last foregrounded at any time during week W (other than before 09:00 on the first weekday of W+1), the notification delivered at the start of W+1 describes W-1 vs W-2, while "last week" at delivery time is W. Week W cannot be summarized at schedule time because it is not complete yet.
Consequence: copy that says "Last week you drank X% less than the week before" is wrong in the common case. The existing copy has the same issue but is vague enough to hide it. The current strings are [VERIFIED: drinkpulse/Localizable.xcstrings:2853-2905]: `directionOnlySame` "No alcohol logged again this week."; `directionOnlyUp` "You logged a drink this week — none last week."; `down` "You drank %d%% less than last week."; `same` "About the same as last week."; `up` "You drank %d%% more than last week.".
This conflicts with D-16 only in that D-16 asks to "verify that the wording matches the periods the calculator compares"; verification fails for delivery-time semantics. See Open Question 1 for options. The calculator and ±5% band stay unchanged in every option.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Legacy store fixtures | Binary `.sqlite` files, SQL surgery | `Schema(versionedSchema: SchemaVn.self)` + `ModelContainer` seeding (D-01) | Frozen snapshots already exist and are immutable |
| Recovery detection | Directory-diffing of `RecoveredStores` | `StoreBootstrap` reporting seam | Shared global directory, parallel tests |
| Fabricating a notification tap | Constructing `UNNotificationResponse` | `route(identifier:)` extraction | Initializers are `NS_UNAVAILABLE` |
| Driving the system notification banner in UI tests | XCUITest against SpringBoard | Launch-argument-gated in-app trigger | AGENTS.md: never match system UI by localized label |
| Sendability of Apple classes | New wrappers/actors | Retain existing `@retroactive @unchecked Sendable` | Header lacks `NS_SWIFT_SENDABLE` |
| Scrubbing personal export by hand-editing | Manual search/replace | A small owner-run script (jq/python) kept OUTSIDE the repo, plus owner review | D-07 one-way risk |

**Key insight:** every "modernization" here is either a compile-time annotation change or a behavior fix proven by a failing test. Nothing justifies replacing the migration, export or actor structure.

## Runtime State Inventory

This is not a rename phase, but it modifies persisted-state assumptions. Categories answered explicitly:

| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Owner's real on-device SwiftData store (schema V4 expected) and a JSON export; gitignored real files exist in the working directory root: `drinkpulse-backup-2026-06-12.json` and `drinkcontrol.csv`, both matched by `.gitignore` lines 126 and 128 [VERIFIED: `git check-ignore -v`] | No code migration. Never read these into plans or fixtures; the sanitized fixture must come from the new pre-upgrade export (D-05/D-07) |
| Live service config | Pending local notification requests `dp.daily.log.reminder` and `dp.weekly.summary` live in the OS notification daemon, not in git; Health samples keyed by metadata `dp_event_uuid` live in Apple Health [VERIFIED: ReminderService.swift:7, WeeklySummaryService.swift:8, HealthWriting.swift:10] | Device checks only (D-14, D-18). A copy change alters body text only when the next reschedule runs (scene-active); stale pending bodies persist until then |
| OS-registered state | UNUserNotificationCenter authorization, HealthKit authorization, app entitlement `com.apple.developer.healthkit` [VERIFIED: drinkpulse/drinkpulse.entitlements] | None; preserve |
| Secrets / env vars | None | None |
| Build artifacts | `build/` and DerivedData are gitignored [VERIFIED: .gitignore:21,54] | Use a scratch `-derivedDataPath`; no artifact commits |

## Common Pitfalls

### Pitfall 1: The fixture file name is gitignored
**What goes wrong:** `.gitignore` line 128 ignores `drinkpulse-backup-*.json`; a fixture named like an export is silently not committed, and the test passes locally then fails in a clean checkout [VERIFIED: `git check-ignore -v` output above].
**How to avoid:** Name it `sanitized-export-v2.json` under `drinkpulseTests/Domain/DataTransfer/Fixtures/`, and verify with `git check-ignore` plus `git ls-files` after staging.
**Warning signs:** `git status` does not list the new file.

### Pitfall 2: Fixture bundling is assumed, not proven
Test targets are `PBXFileSystemSynchronizedRootGroup` [VERIFIED: project.pbxproj:52-60] and no non-Swift resource exists in the test tree today [VERIFIED: `find drinkpulseTests -type f ! -name "*.swift"` returned only `.DS_Store`]. Whether a JSON in a synchronized folder lands in Copy Bundle Resources is [ASSUMED]. Wave 0 task: add a one-line probe test that loads the resource via `Bundle(for:)`; if absent, fall back to embedding the JSON as a Swift string literal in a `.swift` file (no bundling question). Also keep `.DS_Store` out of commits.

### Pitfall 3: Scrubbing leaks via shape
Timestamps shifted by a constant still fingerprint behavior; free-text, `customName`, `notes`, prices and currency can identify a person; profile weight/DOB/sex are health data. Method: owner-run script outside the repo; replace text with `note-N`/`name-N`; round prices to a few constants; shift all dates by one constant offset and quantize to the minute; regenerate UUIDs with a deterministic mapping; cap at roughly a dozen records that keep one example of every shape (uuid present/absent, optional keys present/absent, each category/unit). Owner reviews the diff before `git add`. `ExportBundle`/`ExportRecord` key set to preserve: `version`, `exportedAt`, `events[]` (`uuid`, `timestamp`, `creationDate`, `volumeMl`, `abv`, `quantity`, `enteredUnit`, `category`, `icon`, `customName`, `notes`, `price`, `priceCurrency`, `modifiedDate`), `templates[]`, `profile` [VERIFIED: drinkpulse/Domain/DataTransfer/ExportBundle.swift:3-17, ExportRecord.swift:3-31, TemplateRecord.swift, ProfileRecord.swift]. `healthKitUUID` is not in the export and must not appear [VERIFIED: ExportRecord.swift CodingKeys].

### Pitfall 4: Shared global state in existing persistence tests
`StoreBootstrapTests` mutate `Application Support/RecoveredStores` of the test host (create, trim, clear) and one test chmods a store to 000 [VERIFIED: StoreBootstrapTests.swift:28-45, 77-120]. New migration tests must not read that directory and must use unique temp URLs (`FileManager.default.temporaryDirectory/<UUID>.sqlite` + `-wal`/`-shm` cleanup, as `MigrationTests.swift:9-13, 27-33` does).

### Pitfall 5: `scheduleIfEnabled` is not time-injectable
`WeeklySummaryService.scheduleIfEnabled(context:)` reads `Date.now` and `Calendar.current` internally (`WeeklySummaryService.swift:62-64`), so "completed-week" tests compute ranges from `Date.now` (existing tests do this) and cannot pin a fixed Monday/Sunday boundary. For D-15/D-16 boundary tests add `now:` and `calendar:` default parameters (test seam only; callers unchanged). Locale first-weekday varies; the simulator system locale may not be English (AGENTS.md "Locale independence").

### Pitfall 6: `ViewLoadLogger` exists only in DEBUG
`ViewLoadLogger` is wrapped in `#if DEBUG` [VERIFIED: drinkpulse/Diagnostics/ViewLoadLogger.swift:4-27]; `startupLog` lines (container load, dedupe sweep) are not [VERIFIED: drinkpulseApp.swift:72, 106]. A Release build gives no "Dashboard appeared" line. The D-17 measurement must install a Debug build, then launch from the Home Screen (or `devicectl device process launch` without attaching), and read logs in Console.app with "Include Info Messages". The todo's own finding is that a debugger-attached run inflates launch by Xcode 26-era dylib-load overhead [CITED: developer.apple.com/forums/thread/800067 as recorded in the todo; not re-fetched]. Console log persistence of `.notice` messages is [ASSUMED]; capture live.

### Pitfall 7: Copy change requires the placeholder rule to hold
`body.up`/`body.down` are `String(format:)` with a single `%d` and `Int((abs(fraction) * 100).rounded())` [VERIFIED: WeeklySummaryService.swift:126-128]; a wrong specifier count crashes or garbles at runtime. Tests must format every percentage variant. Existing copy tests compare against `String(localized:)` of the same key, so they will not catch wording regressions; add explicit wording assertions after the owner approves the text [VERIFIED: WeeklySummaryServiceScheduleTests.swift:114].

### Pitfall 8: Default CloudKit mode is dormant only because of the entitlement
`StoreBootstrap.productionConfiguration` builds `ModelConfiguration(schema:isStoredInMemoryOnly:)` with no explicit CloudKit setting [VERIFIED: StoreBootstrap.swift:13-16], and the default is `.automatic`, which uses the app's primary iCloud container from the entitlements [CITED: developer.apple.com/documentation/swiftdata/modelconfiguration/cloudkitdatabase-swift.struct/automatic]. The entitlements file contains only `com.apple.developer.healthkit` and `com.apple.developer.healthkit.access` [VERIFIED: drinkpulse/drinkpulse.entitlements], and no source line references `cloudKitDatabase` [VERIFIED: `grep -rn cloudKitDatabase drinkpulse` empty]. D-19 gate: a shell check that the entitlements file has no `icloud` key and no source references `cloudKitDatabase`. Do not harden the configuration to `.none` in this phase without owner approval (persistence configuration change).

## Code Examples

### Parallel-operation probe (Health) — keep as the basis of a `withKnownIssue` test
```swift
// Source: scratch probe 2026-11-08 (HealthService/FakeHealthStore from drinkpulseTests/Services)
let fake = FakeHealthStore()
let service = HealthService(store: fake)
let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
await service.write(event)
let old = try #require(event.healthKitUUID)
let t1 = Task { await service.update(event) }
let t2 = Task { await service.removeSample(healthKitUUID: old, eventUUID: event.uuid) }
await t1.value; await t2.value
// expected nil; currently non-nil (orphan)
```

### Suspending fake for cancel-during-schedule
```swift
// Source: scratch probe 2026-11-08
final class SlowCenter: NotificationScheduling, @unchecked Sendable {
    var pending: [String] = []; var addEntered = false
    var cont: CheckedContinuation<Void, Never>?
    func add(_ request: UNNotificationRequest) async throws {
        addEntered = true
        await withCheckedContinuation { cont = $0 }
        pending.append(request.identifier)
    }
    // requestAuthorization / pendingRequestIdentifiers / removePendingRequests as in FakeNotificationCenter
    func release() { cont?.resume(); cont = nil }
}
```
Drive: `Task { try await svc.schedule(hour: 9, minute: 0) }`, `while !center.addEntered { await Task.yield() }`, `await svc.cancel()`, `center.release()`.

### Scoped run and TSan run (reuse Phase 09 story)
```bash
export LOCAL_IOS_27_UDID='<local iOS 27 simulator udid>'   # machine-specific
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" \
  -only-testing:drinkpulseTests/MigrationChainTests
# Thread Sanitizer, one scoped Services+Persistence pass
xcodebuild test ... -enableThreadSanitizer YES \
  -only-testing:drinkpulseTests/HealthServiceTests -only-testing:drinkpulseTests/ReminderServiceTests \
  -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/MigrationChainTests
```
Use the class-name form `-only-testing:drinkpulseTests/<ClassName>`; the folder-path form in `09-VALIDATION.md` was not re-verified.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `@unchecked Sendable` on HealthKit adapter | `HKHealthStore` and `HKObjectType` are `NS_SWIFT_SENDABLE` in the iOS 27.2 SDK | Present in this SDK | Adapter's unchecked marker is no longer needed |
| Notification center unchecked retroactive Sendable | Still unannotated in iOS 27.2 SDK | Unchanged | Keep |
| Swift 6.4 async `defer` / `withTaskCancellationShield` | Cleanup tools, not migrations [CITED: swift.org/blog/swift-6.4-released via 08-DECISION-C012.md] | Swift 6.4 | Retain current lifetimes (C012); no failing test needs shielding |

**Deprecated/outdated:** none claimed for `VersionedSchema`, `Transferable`, `UNUserNotificationCenter`, `HKHealthStore` (Phase 08 decision records C008-C011 and the `VersionedSchema` doc page report no deprecation).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `withKnownIssue` Swift Testing API behavior as described | Pattern 3 | Wrong wrapper form; fix at compile time, low risk |
| A2 | JSON files in a synchronized test folder are copied into the test bundle | Pitfall 2 | Fixture load fails; mitigated by Wave 0 probe and Swift-literal fallback |
| A3 | `.notice` os_log lines from a detached device run are visible in Console.app live | Pitfall 6 | D-17 measurement procedure needs adjustment |
| A4 | `WeeklySummaryService` shares the F3 cancel-race (same code shape, not probed) | F3 | Overstates scope of fix; resolve with a test in Wave 1 |
| A5 | Real HealthKit `deleteObjects` of an already-deleted UUID does not throw (so F2 is silent on device) | F2 | If it throws, the error is logged and swallowed either way; orphan outcome unchanged |
| A6 | TSan was actually active in the scoped run | Audit table | A silent no-sanitizer run gives false "no report"; plan must confirm |
| A7 | Edit-then-delete within the Health async window is realistic often enough to matter | F2 | Severity only; the defect is real regardless |
| A8 | Xcode MCP `DocumentationSearch` was not available to this researcher; Apple docs were read via developer.apple.com JSON endpoints and SDK headers | Sources | AGENTS.md prefers DocumentationSearch; executor should re-confirm API availability before citing it in change records |

## Open Questions (RESOLVED)

1. **Weekly copy vs delivery-time staleness (blocks the D-16 task)** (RESOLVED: plan 10-04 Task 3 owner `checkpoint:decision`, applied by plan 10-10)
   - What we know: body is built from last-week vs week-before at foreground time and delivered a week boundary later with static text (F4).
   - What was unclear: whether the owner accepts "Last week..." wording knowing it describes one week earlier in the common case.
   - Options considered for the brief: (a) keep D-16 text and accept inaccuracy (not recommended); (b) name concrete dates, e.g. "Week of Nov 2-8: %d%% less than the week before", which needs a date placeholder; (c) neutral wording that names both periods relative to the data, e.g. "Your latest completed week was %d%% lower than the week before it."; (d) change scheduling so content refreshes closer to delivery (logic change, out of C-scope).
   - Resolution: locked D-16 requires a copy change that names both periods using the existing placeholders, so (b) (new date placeholder) and a keep-current-copy outcome are excluded and not offered; (d) stays out of scope. Plan 10-04 Task 2 writes the brief with a D-16 compliance check and offers only as-of-last-visit (recommended; names both periods relative to the last visit, true at delivery) and d16-as-written (the D-16 example, flagged as failing D-16's own matches-the-calculator-periods check). Task 3 records the owner's choice; plan 10-10 applies it. Choosing an excluded option requires the owner to amend D-16 in `10-CONTEXT.md` first.
2. **Fix approvals for F2 and F3** (RESOLVED: plan 10-05 Task 3 for F2 and plan 10-06 Task 3 for F3, each a `checkpoint:decision` between the pin tests and the fix tasks; fixes applied by plans 10-08 and 10-09 only after the recorded outcome)
   - Owner approves, retains, or defers each; the decision records live in `10-DECISION-F2.md` and `10-DECISION-F3.md`.
3. **`NotificationActionHandler` plain `Sendable`** (RESOLVED: retain by the literal D-12 rule; offered as optional item O1 in `10-DECISION-F3.md` at the plan 10-06 Task 3 checkpoint, applied by plan 10-09 only if the owner appends `+handler-sendable`; disposition recorded in `10-CONCURRENCY-RECORD.md` by plans 10-07 and 10-11)
   - Default retain.
4. **Does the owner's device run iOS 27 already, and is the existing install a build that predates this milestone?** (RESOLVED: plan 10-12 Task 1 Preflight section of `10-DEVICE-SESSION.md` and the plan 10-12 Task 2 human-action reply; a device that cannot run iOS 27 yet is reported as a blocker and the device session is rescheduled)
   - D-05 depends on installing over an existing install; the Preflight step confirms it before any device step runs.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / xcodebuild | Build, tests, TSan | yes | 27.2 (27B52) | none needed |
| iOS 27 simulators | Unit and UI tests | yes | iOS 27.0 and 27.2 runtimes (iPhone 18 Pro etc.) | none needed |
| Paired physical iPhone | D-05, D-14 warm tap, D-17, D-18 | yes (listed, state "available (paired)") | iPhone 15 Pro | none: device checks are mandatory for D-05/D-17/D-18 and need the owner |
| `xcrun devicectl` | Install/launch without debugger | yes | bundled with Xcode 27.2 | Xcode Run then Stop, launch from Home Screen |
| Console.app | Read device logs | assumed on this Mac | — | Xcode device console (attached; not valid for D-17) |
| Apple Health on device | D-18 verification | owner's device | — | none |
| Xcode MCP `DocumentationSearch` | AGENTS.md doc rule | not available to this researcher | — | developer.apple.com JSON endpoints + SDK headers (used) |

**Missing dependencies with no fallback:** the owner's presence for the device session.
**Missing dependencies with fallback:** DocumentationSearch (executor may have it).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing for new unit tests; XCTest/XCUITest for UI tests (existing mix) |
| Config file | `drinkpulse.xcodeproj/project.pbxproj` (file-system-synchronized targets; no registration needed for placed Swift files) |
| Quick run command | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -only-testing:drinkpulseTests/<Class>` |
| Full suite command | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID"` (about 25 min; required at the phase gate because 3+ test classes and Domain-adjacent persistence are touched, per AGENTS.md quality gates) |

Baseline recorded 2026-11-08: scoped run of MigrationTests, StoreBootstrapTests, RecordDeduplicatorTests, HealthServiceTests, HealthWriteHooksTests, ReminderServiceTests, WeeklySummaryServiceTests, WeeklySummaryServiceScheduleTests: 74 tests in 8 suites passed in about 3.3 s test time [VERIFIED: local run]. Note `HealthServiceRemoveSampleTests` was not in that run but was in the TSan run (79 tests).

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| DATA-01 | V1→V4, V2→V4, V3→V4 open under `MigrationPlan`, every stored property intact (per determinism table), no recovery, no `StartupError` | unit | `-only-testing:drinkpulseTests/MigrationChainTests` | Wave 0 |
| DATA-01 | `RecordDeduplicator.sweep` on migrated stores merges/drops nothing | unit | `-only-testing:drinkpulseTests/MigrationSweepTests` | Wave 0 |
| DATA-01 | Existing single-step migrations and recovery tests still pass on iOS 27 | unit | `-only-testing:drinkpulseTests/MigrationTests -only-testing:drinkpulseTests/StoreBootstrapTests -only-testing:drinkpulseTests/RecordDeduplicatorTests` | yes |
| DATA-01 | Owner's real store upgrades in place, no recovery, data intact | manual device (D-05) | documented checklist | Wave 0 doc |
| DATA-01 | Shipped schemas unmodified | shell | `git diff --stat main -- drinkpulse/Domain/Persistence/Schemas/` empty unless a brief-approved `SchemaV5` is added | n/a |
| INT-01 (C009) | Sanitized real export decodes, imports, re-imports as a no-op, exports without `healthKitUUID` | unit | `-only-testing:drinkpulseTests/SanitizedBackupFixtureTests` plus existing DataTransfer classes | Wave 0 |
| INT-01 | Daily/weekly opt-in, scheduling, completed-week calc | unit | `-only-testing:drinkpulseTests/ReminderServiceTests -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryServiceScheduleTests` | yes |
| INT-01 | Route function sets flag and posts for both identifiers | unit | `-only-testing:drinkpulseTests/NotificationActionHandlerTests` | Wave 0 |
| INT-01 | Cold tap routing | UI | `-only-testing:drinkpulseUITests/WeeklySummaryTapUITests` | yes |
| INT-01 | Warm tap routing (background then foreground onto Insights) | UI | same class, new test | Wave 0 |
| INT-01 | Copy names both periods in all five variants, placeholders format cleanly | unit | `-only-testing:drinkpulseTests/WeeklySummaryCopyTests` | Wave 0, after owner approves text |
| INT-01 | Cancel-on-opt-out including in-flight schedule (reminder and weekly) | unit | `-only-testing:drinkpulseTests/ReminderServiceCancellationTests -only-testing:drinkpulseTests/WeeklySummaryServiceCancellationTests` | Wave 0 (known-issue pin until fix) |
| INT-01 | Real-device cold and warm taps | manual device | checklist | Wave 0 doc |
| INT-02 | Auth gating, write/update/delete, dedup relink, errors swallowed | unit | `-only-testing:drinkpulseTests/HealthServiceTests -only-testing:drinkpulseTests/HealthServiceRemoveSampleTests -only-testing:drinkpulseTests/HealthWriteHooksTests` | yes |
| INT-02 | Per-event serial ordering; edit-then-delete leaves no sample | unit | `-only-testing:drinkpulseTests/HealthServiceConcurrencyTests` | Wave 0 (known-issue pin until fix) |
| INT-02 | Opt-in flow in UI (off by default, counts) | UI | `-only-testing:drinkpulseUITests/HealthSettingsUITests -only-testing:drinkpulseUITests/HealthWriteHooksUITests` | yes |
| INT-02 | Real HealthKit: prompt, write/update/delete, one sample per `dp_event_uuid`, non-blocking delete | manual device (D-18) | checklist | Wave 0 doc |
| INT-02 / D-19 | CloudKit disabled | shell | `! grep -qi icloud drinkpulse/drinkpulse.entitlements && ! grep -rn cloudKitDatabase drinkpulse` | n/a |
| MOD-03 | No data-race diagnostics; zero warnings | build | `xcodebuild build ...` zero warnings (fix `HealthWriteHooksTests.swift:116` test warning) | yes |
| MOD-03 | TSan clean on scoped Services+Persistence pass | unit + TSan | command above with `-enableThreadSanitizer YES` | yes |
| MOD-03 | Per-candidate retain/applied records C010-C012 | doc | `10-CONCURRENCY-RECORD.md` (name suggestion) naming evidence, official source, isolation reasoning | Wave 0 doc |
| D-17 | Cold-launch todo closed or escalated | manual device | measurement log | Wave 0 doc |

### Sampling Rate
- **Per task commit:** scoped `-only-testing:` run for the touched class(es).
- **Per wave merge:** all Phase 10 classes together plus a clean `build` with zero warnings.
- **Phase gate:** full `xcodebuild test` green (AGENTS.md escalation rule), plus the device checklist signed off by the owner, plus the file-size check (`find drinkpulse -name "*.swift" ... | awk '$1 > 300'`).

### Wave 0 Gaps
- [ ] `drinkpulseTests/Domain/Persistence/MigrationFixtures.swift`, `MigrationChainTests.swift`, `MigrationSweepTests.swift`
- [ ] `StoreBootstrap` recovery-reporting seam (production change, test-seam only)
- [ ] Fixture bundling probe, then `Fixtures/sanitized-export-v2.json` after owner scrub and review (owner-gated)
- [ ] `NotificationActionHandler.route(identifier:defaults:)` extraction + `NotificationActionHandlerTests`
- [ ] Time/calendar injection on `WeeklySummaryService.scheduleIfEnabled` for deterministic completed-week tests
- [ ] Warm-tap launch-argument hook in `UITestSeed`/`RootShellView` and the warm UI test
- [ ] `HealthServiceConcurrencyTests`, `ReminderServiceCancellationTests`, `WeeklySummaryServiceCancellationTests` with `withKnownIssue` pins
- [ ] Fix test-target warning `HealthWriteHooksTests.swift:116`
- [ ] Device-session checklist document (order from CONTEXT specifics: export, install over existing, verify, import round trip, Health and notification checks, detached launch measurement)
- [ ] Owner briefs per Phase 08 D-10 format: F2, F3, F4/D-16 copy (and optional handler Sendable)
- [ ] Confirm TSan activation once

## Security Domain

### Applicable ASVS Categories (config: `security_enforcement: true`, ASVS level 1)

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No accounts (project rule) |
| V3 Session Management | no | None |
| V4 Access Control | no | On-device only; iOS file protection defaults (AGENTS.md) |
| V5 Input Validation | yes | `DataImporter` decodes with `Codable`, rejects unsupported versions and unknown categories (`DataImporter.swift:4-60`); keep malformed-import tests |
| V6 Cryptography | no | None; do not add any |
| V8 Data Protection / V9 Communications (privacy) | yes | No logging of PII/health values, no network; export and fixtures are sensitive |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Personal health data committed to git via fixture | Information disclosure | Owner-run scrub script outside the repo, owner review, deterministic placeholders, gitignore awareness (Pitfall 1, 3); one-way per D-07 |
| Health data in logs from new tests/diagnostics | Information disclosure | Log identifiers, counts, enum cases only; `.private` for user data (AGENTS.md); D-17 logs contain only ms timings and counts |
| Stale notification content disclosing wrong health summary | Integrity (user-facing misinformation) | F4 owner decision |
| Orphan Health sample after delete | Integrity / privacy expectation | F2 fix after brief |
| Silent store move-aside masking data loss | Tampering/availability | D-03 seam + tests; recovery is move-aside, not delete (`StoreBootstrap.swift:36-61`) |
| Accidental CloudKit enablement | Information disclosure | D-19 shell gate; no entitlement, no `cloudKitDatabase` |
| Fabricated test hooks shipping in production | Elevation | Gate every new test hook on `UITestSeed.isActive` launch argument; no PII seed; add no code path reachable without `-dp_uitest` |

## Sources

### Primary (HIGH confidence)
- Repo source and tests read this session: `drinkpulse/Domain/Persistence/*`, `Schemas/SchemaV1-V4.swift`, `Domain/ConsumptionEvent.swift`, `DrinkTemplate.swift`, `UserProfile.swift`, `Domain/DataTransfer/*`, `Services/*`, `Features/Settings/Components/{Reminder,WeeklySummary,Health}Section.swift`, `Features/Shell/RootShellView.swift`, `drinkpulseApp.swift`, `UITestSeed.swift`, `Diagnostics/ViewLoadLogger.swift`, `drinkpulseTests/**` named above, `drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift`, `drinkpulse.entitlements`, `Info.plist`, `project.pbxproj` settings.
- iPhoneOS27.2 SDK headers: `UserNotifications/UNUserNotificationCenter.h`, `UNNotificationResponse.h`, `UNNotification.h`, `UserNotifications.apinotes`; `HealthKit/HKHealthStore.h`, `HKObjectType.h`.
- Local tool runs 2026-11-08: Xcode 27.2 `build-for-testing` (success), scoped test run (74 pass), TSan scoped run (79 pass), scratch probes (3 tests: 1 pass, 2 expected-failing findings).
- `.planning/phases/08-*/08-DECISION-C008..C012.md`, `08-CONTEXT.md` D-09 to D-11, `08-BASELINE.md`, ADR-0009/0010/0011.

### Secondary (MEDIUM confidence)
- developer.apple.com documentation JSON for `VersionedSchema`, `UNUserNotificationCenterDelegate`, `ModelConfiguration.CloudKitDatabase.automatic` (fetched via WebFetch, summarized by a small model; Xcode MCP DocumentationSearch was not available).

### Tertiary (LOW confidence)
- Console log persistence behavior, `withKnownIssue` details, fixture bundling in synchronized groups (tagged [ASSUMED]).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH, nothing new, all tools run locally.
- Architecture: HIGH for persistence and services (code read plus probes); MEDIUM for the warm-tap seam (design not yet built).
- Pitfalls: HIGH for repo-verified ones; MEDIUM for the assumed ones listed in the Assumptions Log.
- Device-only behavior (cold/warm tap, Health app contents, launch timing): LOW until the owner runs the session.

**Research date:** 2026-11-08
**Valid until:** 2026-12-08 (stable APIs; re-verify if Xcode/iOS point release changes the SDK annotations)
