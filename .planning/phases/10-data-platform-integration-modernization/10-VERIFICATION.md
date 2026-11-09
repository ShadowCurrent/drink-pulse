---
phase: 10-data-platform-integration-modernization
verified: 2026-11-09T14:14:23Z
status: gaps_found
score: 8/10 must-haves verified
covered_files:
  - ".planning/phases/10-data-platform-integration-modernization/10-01-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-01-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-02-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-02-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-03-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-03-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-04-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-04-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-05-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-05-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-06-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-06-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-07-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-07-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-08-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-08-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-09-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-09-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-10-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-10-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-11-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-11-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-12-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-12-SUMMARY.md"
  - "drinkpulse/Domain/Persistence/StoreBootstrap.swift"
  - "drinkpulse/Features/Shell/RootShellView.swift"
  - "drinkpulse/Localizable.xcstrings"
  - "drinkpulse/Services/HealthKitAdapter.swift"
  - "drinkpulse/Services/HealthService.swift"
  - "drinkpulse/Services/NotificationActionHandler.swift"
  - "drinkpulse/Services/ReminderService.swift"
  - "drinkpulse/Services/UITestNotificationCenter.swift"
  - "drinkpulse/Services/WeeklySummaryService.swift"
  - "drinkpulse/UITestSeed.swift"
  - "drinkpulse/drinkpulseApp.swift"
  - "drinkpulseTests/Domain/DataTransfer/BackupFixtureLoader.swift"
  - "drinkpulseTests/Domain/DataTransfer/Fixtures/probe-export-v2.json"
  - "drinkpulseTests/Domain/DataTransfer/Fixtures/sanitized-export-v2.json"
  - "drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift"
  - "drinkpulseTests/Domain/Persistence/MigrationChainV1Tests.swift"
  - "drinkpulseTests/Domain/Persistence/MigrationChainV2V3Tests.swift"
  - "drinkpulseTests/Domain/Persistence/MigrationFixtureValues.swift"
  - "drinkpulseTests/Domain/Persistence/MigrationFixtures+LegacyV2V3.swift"
  - "drinkpulseTests/Domain/Persistence/MigrationFixtures.swift"
  - "drinkpulseTests/Domain/Persistence/MigrationSweepTests.swift"
  - "drinkpulseTests/Services/HealthServiceConcurrencyTests.swift"
  - "drinkpulseTests/Services/HealthServiceOrderingTests.swift"
  - "drinkpulseTests/Services/HealthServiceRemoveSampleTests.swift"
  - "drinkpulseTests/Services/HealthWriteHooksTests.swift"
  - "drinkpulseTests/Services/NotificationActionHandlerTests.swift"
  - "drinkpulseTests/Services/NotificationOptOutTests.swift"
  - "drinkpulseTests/Services/ReminderServiceCancellationTests.swift"
  - "drinkpulseTests/Services/SlowNotificationCenter.swift"
  - "drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift"
  - "drinkpulseTests/Services/WeeklySummaryCopyTests.swift"
  - "drinkpulseTests/Services/WeeklySummaryServiceCancellationTests.swift"
  - "drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift"
  - "drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift"
covered_digest: "v4:sha256:26be0821efa334be43b128f436e6cc7010ae5c0145d5fece9ed9dbcb34f0c040"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "A killed-app (cold launch) daily-reminder tap opens the Add Drink sheet on iOS 27 (INT-01; roadmap success criterion 3)"
    status: failed
    reason: "Owner device session 2026-11-09, Step 6: killed-app tap 1, correct 0; the app opened on Dashboard instead of Add Drink. The stop rule ended the session after the first cold tap, so the three or more cold taps required by plan 10-12 and research F6 were not recorded. Backgrounded tap PASS (1 of 1). Root-cause hypothesis, not confirmed by a device trace: drinkpulseApp.init() assigns UNUserNotificationCenter.current().delegate inside Task.detached (assignNotificationDelegate). The assignment therefore runs after init() returns. The installed SDK header UNUserNotificationCenter.h:99 states the delegate must be set before the application returns from application:didFinishLaunchingWithOptions:. On a cold launch from a notification the response callback is then not routed, so neither pendingAddDrink nor the tap notification fires and the app lands on Dashboard. The hop was added by commit ba4b326 on 2026-08-01, before fbd37fa (the phase baseline) and after the v1.1 and v1.3 tags; Phase 10 did not change drinkpulseApp.swift. The cold-tap UI test drives the UITestNotificationCenter seam and cannot observe system delivery timing, so the automated suite does not catch this."
    artifacts:
      - path: "drinkpulse/drinkpulseApp.swift"
        issue: "assignNotificationDelegate(_:) wraps the delegate assignment in Task.detached(priority: .userInitiated) with a MainActor.run hop, so the delegate is set asynchronously after init() returns."
      - path: "drinkpulse/Services/NotificationActionHandler.swift"
        issue: "The didReceive callback has no log line, so the next device run cannot prove the callback fired on a cold tap. Owner scope adds a log-only line (category and identifier kind only)."
    missing:
      - "Owner decision 10-DECISION-DEVICE-FINDING.md, outcome sync-assign, decided 2026-11-09: in drinkpulseApp.init(), assign UNUserNotificationCenter.current().delegate synchronously (remove the Task.detached hop)."
      - "Add one log-only line in the NotificationActionHandler didReceive callback recording category and identifier kind only, never user data."
      - "Keep the lazy-center behavior in ReminderService and WeeklySummaryService as shipped. Do not change RootShellView, the pending-flag and tap-notification design, NotificationActionHandler routing, schemas, the export format or CloudKit (the owner scope excludes them)."
      - "Device re-test on the iPhone, recorded as counts and PASS or FAIL only: at least three killed-app daily-reminder taps, each landing on the Add Drink sheet; one backgrounded tap; three detached Home Screen cold-launch timings confirming D-17 stays near (no debugger attached). Do not delete or reinstall the app (10-DEVICE-SESSION.md stop rule)."
      - "If a cold weekly-summary notification can be delivered, one cold weekly tap routed to Insights (see warning W-1)."
      - "Automated coverage cannot prove system delivery timing. The gap-closure plan should state that the device re-test is the verification source for this fix."
deferred: []
---

# Phase 10: Data & Platform Integration Modernization Verification Report

**Phase Goal:** Modernize domain, persistence, services and concurrency where justified while preserving existing data and system behavior.
**Requirements:** MOD-03, DATA-01, INT-01, INT-02
**Verified:** 2026-11-09T14:14:23Z
**Status:** gaps_found
**Re-verification:** No (initial verification; no prior 10-VERIFICATION.md)

## Summary

The phase delivered what it set out to deliver in code and in the automated suite, and the owner's device session confirmed data safety (DATA-01), HealthKit behavior (INT-02) and warm notification taps. One must-have fails on the device: a killed-app notification tap does not open Add Drink (INT-01, cold-tap routing). The owner decided on 2026-11-09 to fix it in a Phase 10 gap-closure plan (sync-assign). That fix is not in the code: `drinkpulseApp.swift` still assigns the delegate inside `Task.detached`. INT-01 is therefore not complete and the phase must not advance to Phase 11 until the gap closes and the device re-test passes.

## Goal Achievement

### Observable Truths

| #   | Truth (source) | Status | Evidence |
| --- | -------------- | ------ | -------- |
| 1 | Phase 08 candidates have documented dispositions with focused regression evidence; actor isolation and lifecycle changes are justified; substantial rewrites have an owner decision brief before planning (roadmap SC1) | VERIFIED | `10-CONCURRENCY-RECORD.md` (D-12 table; C010 applied, C011 applied, C012 retained). `10-EVIDENCE.md` (C008 retain, C009 retain). Decision briefs `10-DECISION-F2.md`, `10-DECISION-F3.md`, `10-DECISION-F4.md` each carry an Outcome and a decision date of 2026-11-09. Plans 10-08, 10-09 and 10-10 read these Outcomes in their preconditions and applied them afterwards. Code confirms the applied changes (truth 9). |
| 2 | Legacy schema fixtures and the current store open on iOS 27 with events, templates, profile and UUID identity intact, with no reset (DATA-01; roadmap SC2) | VERIFIED | Automated: `MigrationChainV1Tests` (4 tests), `MigrationChainV2V3Tests` (3 tests, including `corruptedStore_reportsRecoveryAndOpensFresh`), `MigrationSweepTests` (5 tests), `StoreBootstrapTests`, `RecordDeduplicatorTests`, all in the 678-test unit run at commit 5044cfd (orchestrator-cited; `10-EVIDENCE.md` Full suite). Device (`10-DEVICE-SESSION.md`): Steps 1 to 3 PASS, 214 events and 0 templates and profile present before and after the in-place install, no recovery or startup error, both recovery log lines absent. |
| 3 | Any necessary model-shape change adds a new versioned schema and migration stage, with shipped schemas immutable (DATA-01; roadmap SC5) | VERIFIED | No model-shape change was needed in Phase 10. `git diff --quiet fbd37fa -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` exits 0. `MigrationPlan` lists `SchemaV1` to `SchemaV4` with stages `v1ToV2`, `v2ToV3` (custom) and `v3ToV4` (lightweight). No `SchemaV5` exists. |
| 4 | Daily and weekly notification opt-in, scheduling and completed-week comparison pass tests (INT-01; roadmap SC3, first part) | VERIFIED | Automated: `ReminderServiceTests`, `ReminderServiceCancellationTests`, `NotificationOptOutTests`, `WeeklySummaryCompletedWeekTests`, `WeeklySummaryServiceScheduleTests` in the 678-test unit run at 5044cfd. Device Step 6: the daily reminder was scheduled and delivered on the iPhone. Weekly delivery was not observed on the device (see W-1). |
| 5 | Warm (backgrounded) notification tap routes to Add Drink (INT-01; roadmap SC3, second part) | VERIFIED | Device Step 6 backgrounded tap: PASS (1 of 1, Add Drink sheet opened). Automated: `NotificationActionHandlerTests` drive `NotificationActionHandler.route(identifier:defaults:)`, and `WeeklySummaryTapUITests` and `LaunchHandoffUITests` run in the 93-test UI suite. |
| 6 | Killed-app (cold) notification tap routes to Add Drink (INT-01; roadmap SC3, third part) | FAILED (BLOCKER) | Device Step 6 killed-app tap: taps 1, correct 0; app opened on Dashboard. The cause is not fixed in code: `drinkpulseApp.swift` `assignNotificationDelegate(_:)` still wraps the delegate assignment in `Task.detached` (unchanged since fbd37fa). Full detail in `gaps`. |
| 7 | Weekly summary cold tap routes to Insights (INT-01) | UNCERTAIN (WARNING W-1) | Not observed on the device (no natural weekly delivery; `10-DEVICE-SESSION.md` Step 6 item 5 recorded N/A). Automated routing only (`WeeklySummaryTapUITests`, `NotificationActionHandlerTests`). The weekly path uses the same delegate and `route(identifier:)` as the daily path, so it likely shares the truth 6 cause. Human decision requested: confirm whether the gap-closure device re-test should force a cold weekly tap, or accept automated coverage for the weekly path. |
| 8 | HealthKit permission, opt-in, write, delete and UUID-based deduplication behave correctly; CloudKit stays disabled (INT-02; roadmap SC4) | VERIFIED | Device Step 5, all PASS: off by default; prompt and opt-in work; samples 1 after log, 1 after edit, 0 after delete; delete returns the UI without blocking; `healthKitUUID` absent from export (0 occurrences). Automated: `HealthServiceTests`, `HealthServiceRemoveSampleTests`, `HealthServiceOrderingTests`, `HealthServiceConcurrencyTests`, `HealthWriteHooksTests`. CloudKit: `drinkpulse.entitlements` holds only `com.apple.developer.healthkit` and `com.apple.developer.healthkit.access`; zero `cloudKitDatabase` references in Swift sources; the production `ModelConfiguration` is `isStoredInMemoryOnly: false` with no CloudKit option. |
| 9 | Approved modernization of domain, persistence, service and concurrency is applied with isolation and lifecycle reasoning and regression evidence (MOD-03) | VERIFIED | Code checked: `HealthService.performRemoveSample` queries `sampleUUID(forEventUUID:)` before `delete(uuid:)` (F2 `fix-query-first`). `ReminderService` and `WeeklySummaryService` carry `lifecycleEpoch` and `cancelEpoch` (F3 S1 and S2 applied; S3 not applied, as the F3 record states). `NotificationActionHandler` is plain `Sendable` (F3 O1). The `HealthKitAdapter` unchecked qualifier is removed (10-07, D-12). Regression evidence: the F2 and F3 behavior tests in `HealthServiceRemoveSampleTests`, `ReminderServiceCancellationTests` and `WeeklySummaryServiceCancellationTests` ran in the full unit run; the F2 UI test is in `HealthWriteHooksUITests`. Thread Sanitizer activation was proven by a canary (`10-EVIDENCE.md`); the 21 Phase 10 suites (144 tests) ran clean under it. No code file changed after commit 5044cfd (`git diff 5044cfd..HEAD` over the app and test targets is empty), so the full-suite run covers the final code. |
| 10 | Weekly summary notification body carries the owner-approved wording for all five variants (roadmap SC3 copy and `10-DECISION-F4.md`) | VERIFIED | `drinkpulse/Localizable.xcstrings` contains the five approved `weeklySummary.notification.body.*` values ("As of your last visit, ..."). `WeeklySummaryCopyTests` asserts the literal strings. The calculator and the plus or minus 5 percent band are unchanged. |

**Score:** 8/10 truths verified. 1 FAILED (BLOCKER). 1 UNCERTAIN (WARNING W-1).

### Deferred Items

None. The cold-tap failure belongs to this phase and is a gap for `/gsd-plan-phase 10 --gaps`, not an item for a later phase.

### Required Artifacts

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `drinkpulse/Domain/Persistence/MigrationPlan.swift` and `Schemas/SchemaV1` to `SchemaV4` | Shipped schemas immutable; migration stages | VERIFIED | Unchanged vs fbd37fa; four schemas and three stages present. |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | Recovery reporting seam only; no `ModelConfiguration` change | VERIFIED | Changed only by the recovery-reporting seam per `10-EVIDENCE.md`; production `ModelConfiguration` is `isStoredInMemoryOnly: false`. |
| `drinkpulse/Services/HealthService.swift` | F2 query-first remove | VERIFIED | `performRemoveSample` resolves the current sample by `dp_event_uuid` first and uses the captured UUID only as fallback. |
| `drinkpulse/Services/ReminderService.swift` | F3 lifecycle epoch | VERIFIED | `lifecycleEpoch` and `cancelEpoch` guard a superseded schedule. |
| `drinkpulse/Services/WeeklySummaryService.swift` | F3 lifecycle epoch | VERIFIED | Same epoch pattern as ReminderService. |
| `drinkpulse/Services/NotificationActionHandler.swift` | Plain `Sendable`; `route(identifier:defaults:)` seam | VERIFIED (artifact) / gap (log line missing) | Sendable applied (F3 O1). The owner-approved log-only line for the `didReceive` callback is not yet present; it is part of the gap closure. |
| `drinkpulse/drinkpulseApp.swift` | Synchronous delegate assignment in `init()` | FAILED (wiring) | Delegate assigned inside `Task.detached` after `init()` returns. This is the cold-tap defect; see gap. |
| `drinkpulse/Localizable.xcstrings` | Five approved weekly body strings | VERIFIED | All five present; placeholders as approved. |
| `drinkpulseTests/Services/WeeklySummaryCopyTests.swift` | Literal-string copy guard | VERIFIED | Present and passing in the full run. |
| `.planning/todos/pending/2026-11-08-refresh-weekly-summary-closer-to-delivery.md` | Follow-up todo, only under outcome `d16-then-refresh` | VERIFIED (correctly absent) | Plan 10-10 lists it as an artifact, but the recorded F4 outcome is `as-of-last-visit`, so the todo must not exist. The plan's own automated check agrees. Not a gap. |
| `.planning/todos/completed/2026-09-15-clarify-weekly-alcohol-summary-comparison.md` | Closed copy todo | VERIFIED | Present in `completed/`. |
| `10-DEVICE-SESSION.md` and `10-DECISION-DEVICE-FINDING.md` | Device results, finding brief | VERIFIED | Results contain counts, PASS or FAIL and milliseconds only; no personal values; the sign-off residual risks R-01 and R-02 are marked `acknowledged`. |

### Key Link Verification

Plan-declared key links were checked with `gsd_run query verify.key-links` for all 12 plans: every link reports `verified: true`.

| From | To | Via | Status | Details |
| ---- | -- | --- | ------ | ------- |
| `drinkpulseApp.init()` | `UNUserNotificationCenter.delegate` | synchronous assignment before launch finishes | NOT_WIRED (cold path) | Assignment is in `Task.detached`; the SDK requires the delegate before `didFinishLaunching` returns. Not caught by the verifier's link check because the link check confirms the pattern exists, not its timing. Device-confirmed failure. |
| `NotificationActionHandler.didReceive` | `route(identifier:)` | delegate call | WIRED in code | The callback calls the static route function. Delivery on a cold launch is the failing part. |
| `route(identifier:)` | `RootShellView` | `pendingAddDrink` flag and tap notification | WIRED | `RootShellView` reads `pendingAddDrink` and `pendingOpenInsights`, and listens for the tap notifications. Warm path verified on device. |
| `HealthService.performRemoveSample` | `HealthWriting.sampleUUID(forEventUUID:)` | query before delete | WIRED | Confirmed in code (F2). |
| `ReminderService.schedule` and `cancel` | `NotificationScheduling` | epoch-guarded `removePendingRequests` | WIRED | Confirmed in code (F3). |
| `WeeklySummaryCopyTests` | `WeeklySummaryService.makeRequest` | literal body assertions | WIRED | Tests read `request.content.body`. |

### Data-Flow Trace (Level 4)

Not applicable to a rendered-data artifact in this phase. The notification route carries a flag, not data, from `NotificationActionHandler` to `RootShellView` through `UserDefaults` (`dp_pending_add_drink`, `dp_pending_open_insights`). The write path is wired; the cold-launch delivery of the response that writes it is the failing link (truth 6).

### Behavioral Spot-Checks

Step 7b: SKIPPED for new runs. The app has no CLI or server entry point that can be exercised in under 10 seconds without a simulator, and the full suite is not re-run per the orchestrator scope. Behavioral evidence relies on the owner device session (`10-DEVICE-SESSION.md`) and the full-suite results cited in `10-EVIDENCE.md` at commit 5044cfd. No code changed after 5044cfd.

| Behavior | Command | Result | Status |
| -------- | ------- | ------ | ------ |
| Cold-tap routing on the device | Owner device session Step 6 | 1 tap, 0 correct | FAIL |
| Warm-tap routing on the device | Owner device session Step 6 | 1 tap, 1 correct | PASS |
| Store upgrade and import round trip | Owner device session Steps 1 to 4 | counts unchanged, no recovery | PASS |
| HealthKit write, edit and delete | Owner device session Step 5 | 1, 1, 0 samples | PASS |
| Detached cold-launch timing | Owner device session Step 7 | 6 ms container, 104 to 118 ms Dashboard, verdict near | PASS |

### Probe Execution

Step 7c: no probes declared. No `scripts/*/tests/probe-*.sh` exists, and no PLAN or SUMMARY in this phase declares one. Skipped.

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
| ----------- | -------------- | ----------- | ------ | -------- |
| MOD-03 | 10-05, 10-06, 10-07, 10-08, 10-09, 10-11 | Approved modernization of domain, persistence, service and concurrency applied with isolation and lifecycle reasoning and regression evidence | SATISFIED | Truth 9. Concurrency record, F2/F3/F4 applied and verified in code, full suite and Thread Sanitizer evidence. |
| DATA-01 | 10-01, 10-03, 10-11, 10-12 | Existing stores keep events, templates, profile, identities and stored values; migration path with no reset; shipped schemas immutable | SATISFIED | Truths 2 and 3. Migration chain tests and device Steps 1 to 4 PASS. |
| INT-01 | 10-02, 10-04, 10-06, 10-07, 10-09, 10-10, 10-11, 10-12 | Daily and weekly notifications preserve opt-in, scheduling, completed-week calculations and cold and warm tap routing on iOS 27 | BLOCKED | Truths 4, 5, 10 satisfied. Truth 6 (cold tap) FAILED on device; truth 7 (weekly cold tap) UNCERTAIN. 10-12 `requirements-completed` correctly omits INT-01. |
| INT-02 | 10-05, 10-07, 10-08, 10-11, 10-12 | HealthKit preserves permission, opt-in, write, delete and UUID dedup on iOS 27; CloudKit remains disabled | SATISFIED | Truth 8. Device Step 5 PASS, CloudKit-off checks pass. |

**Orphan check:** `REQUIREMENTS.md` maps exactly MOD-03, DATA-01, INT-01 and INT-02 to Phase 10. The plan frontmatter declares exactly those four. No orphaned requirements.

**Requirements checkboxes in `REQUIREMENTS.md`:** all four Phase 10 IDs are still unchecked. This verification does not edit `REQUIREMENTS.md`. MOD-03, DATA-01 and INT-02 have evidence; INT-01 must stay open until the gap closes.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| `drinkpulse/**`, `drinkpulseTests/**`, `drinkpulseUITests/**` (changed files) | - | Debt markers `TBD`, `FIXME`, `XXX` | none | Grep across all 33 changed implementation and test files: no matches. Debt-marker gate passes. |
| `drinkpulse/drinkpulseApp.swift` | `assignNotificationDelegate` | Async delegate assignment on the launch path | BLOCKER | Root cause of truth 6 (see gap). |
| `drinkpulse/Services/UITestNotificationCenter.swift`, `UITestHealthStore.swift` | declaration | `@unchecked Sendable` | info | Retained by the D-12 disposition: test-only seams used only when `UITestSeed.isActive`. |
| `drinkpulseTests/Services/SlowNotificationCenter.swift` and cold-tap UI tests | - | Cold-tap coverage through the `UITestNotificationCenter` seam | warning | Automated cold-tap tests cannot observe system delivery timing, so they did not catch truth 6. Recorded so the gap-closure plan does not treat them as proof of the cold path. |
| `drinkpulse/drinkpulseApp.swift` | struct body | `@State` declarations placed between methods | info | Style only; not related to the gap. |

No stub implementations found in the phase's changed files. No placeholder UI or hardcoded empty data flows to rendering.

## Human Verification Required

Not required for status determination (status is `gaps_found`). The device re-test that the gap closure needs is listed under `gaps[0].missing`. The optional weekly cold-tap check is warning W-1.

## Warnings

- **W-1 (UNCERTAIN, human decision requested):** weekly-summary cold tap to Insights has no device evidence. Decide whether the gap-closure device re-test must include a cold weekly tap (only possible if a weekly notification is delivered naturally) or whether automated coverage is accepted for the weekly path.
- **W-2 (process):** Step 6 of the device session stopped after one cold tap per the stop rule. The plan requires three or more cold taps. The gap-closure re-test covers this, so no separate action is needed beyond the re-test.

## Gaps Summary

**Gap 1 (BLOCKER): killed-app notification tap does not route to Add Drink (INT-01).**

- Observed: owner device, 2026-11-09. Killed-app tap 1, correct 0, app opened on Dashboard. Backgrounded tap PASS.
- Code state: `drinkpulseApp.swift` `assignNotificationDelegate` still uses `Task.detached`. Phase 10 did not change this file.
- Root-cause hypothesis (not confirmed by a device trace): the delegate is assigned after `init()` returns. The SDK header `UNUserNotificationCenter.h:99` requires it before `didFinishLaunching` returns. A cold launch from a notification therefore drops or misses the response callback.
- Provenance: commit `ba4b326` (2026-08-01) added the hop, before the phase baseline `fbd37fa` and after the v1.1 and v1.3 tags, where cold-tap routing was device-verified.
- Secondary candidate (weaker, per the decision brief): a race between the tap notification and the `.task` listener. The pending flag set before `RootShellView.onAppear` covers it, so it does not explain the miss alone.
- Owner-decided scope (`10-DECISION-DEVICE-FINDING.md`, outcome `sync-assign`, 2026-11-09): synchronous delegate assignment in `drinkpulseApp.init()`; one log-only line in the `didReceive` callback; no other startup or lifecycle change; no change to `RootShellView`, pending flags, `NotificationActionHandler` routing, schemas, export format or CloudKit.
- Required re-test (device, counts and PASS or FAIL only, no debugger, do not delete the app): at least three killed-app daily-reminder taps landing on Add Drink; one backgrounded tap; three detached cold-launch timings confirming D-17 stays near; a cold weekly tap to Insights if deliverable (W-1).
- Group: this single root cause covers truth 6 and the weekly cold path in W-1.

**Phase 10 status:** gaps_found. The phase must not be marked complete and must not advance to Phase 11 until Gap 1 closes and its device re-test passes. The ROADMAP Phase 10 entry shows all twelve plans executed; that reflects plan execution, not goal achievement.

**Next step:** `/gsd-plan-phase 10 --gaps` to plan the sync-assign fix from the `gaps` frontmatter above.

---

_Verified: 2026-11-09T14:14:23Z_
_Verifier: Claude (gsd-verifier)_
