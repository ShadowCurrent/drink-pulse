---
phase: 10-data-platform-integration-modernization
verified: 2026-11-10T19:11:50Z
status: human_needed
score: "10/10 must-haves verified (9 VERIFIED, 1 PASSED via owner-accepted override); one owner decision open: scope of the disposition-traceability expectation (UAT round 2 item 6)"
covered_files:
  - ".claude/context/open-questions.md"
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
  - ".planning/phases/10-data-platform-integration-modernization/10-13-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-13-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-14-PLAN.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-14-SUMMARY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-CONCURRENCY-RECORD.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-DECISION-DEVICE-FINDING.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-DECISION-F2.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-DECISION-F3.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-DECISION-F4.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-DEVICE-RETEST.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-DEVICE-SESSION.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-EVIDENCE.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-FIXTURE-SCRUB.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-REVIEW-DISPOSITION.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-REVIEW-FIX.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-REVIEW.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-SECURITY.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-UAT.md"
  - ".planning/phases/10-data-platform-integration-modernization/10-VALIDATION.md"
  - "docs/DEVLOG.md"
  - "docs/architecture.md"
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
  - "drinkpulseTests/Domain/Persistence/StoreBootstrapTests+Rollback.swift"
  - "drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift"
  - "drinkpulseTests/Services/HealthServiceConcurrencyTests.swift"
  - "drinkpulseTests/Services/HealthServiceOrderingTests.swift"
  - "drinkpulseTests/Services/HealthServiceRemoveSampleTests.swift"
  - "drinkpulseTests/Services/HealthServiceTests.swift"
  - "drinkpulseTests/Services/HealthServiceUpdateTargetTests.swift"
  - "drinkpulseTests/Services/HealthWriteHooksTests.swift"
  - "drinkpulseTests/Services/NotificationActionHandlerTests.swift"
  - "drinkpulseTests/Services/NotificationDelegateAssignmentTests.swift"
  - "drinkpulseTests/Services/NotificationOptOutTests.swift"
  - "drinkpulseTests/Services/ReminderServiceCancellationTests.swift"
  - "drinkpulseTests/Services/SlowNotificationCenter.swift"
  - "drinkpulseTests/Services/WeeklySummaryCompletedWeekTests.swift"
  - "drinkpulseTests/Services/WeeklySummaryCopyTests.swift"
  - "drinkpulseTests/Services/WeeklySummaryServiceCancellationTests.swift"
  - "drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift"
  - "drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift"
covered_digest: "v4:sha256:e8b4490d0bbc168fe93de285bf13795bc54902a23b3370d274b2679b169f65d0"
behavior_unverified: 0
overrides_applied: 1
overrides:
  - must_have: "Weekly summary cold tap routes to Insights (INT-01)"
    reason: "Owner Amendment 2 (10-DECISION-DEVICE-FINDING.md): a cold weekly tap is recorded only if a weekly notification is naturally delivered while the app is killed; the device clock is never changed to force one. No weekly notification was delivered during the 2026-11-10 re-test (10-DEVICE-RETEST.md Step 5, N/A). Routing is covered by WeeklySummaryTapUITests and NotificationActionHandlerTests; cold weekly delivery itself is NOT device-observed."
    accepted_by: "owner (Amendment 2, 10-DECISION-DEVICE-FINDING.md)"
    accepted_at: "2026-11-09T00:00:00Z"
re_verification:
  previous_status: human_needed
  previous_score: "10/10 (1 via owner-accepted override)"
  gaps_closed:
    - "Round-2 human item 6, R1-WR-01 row: 10-REVIEW-DISPOSITION.md now carries R1-WR-01 (warning, fixed), citing e3359cd and 10-UAT.md round 2 test 1. Committed in a090e77. The row is present in both the frontmatter and the table, and the file has no duplicate id."
    - "Round-2 items 1 to 5 remain closed by owner UAT pass (unchanged from the prior pass)."
  gaps_remaining: []
  regressions: []
  notes: "Code tree unchanged since 9802fe2: git diff 9802fe2 HEAD is limited to 10-REVIEW-DISPOSITION.md; no diff under drinkpulse/, drinkpulseTests/, drinkpulseUITests/, docs/ or .claude/. Working tree differs only in .planning/STATE.md (activity timestamp, not covered) and drinkpulse.xcodeproj/project.pbxproj (advisory, not covered). Must-have evidence is carried from the prior pass because the code it checked is identical. No test command is configured; no tests were run in this pass. Prior pass scoped xcodebuild evidence (50 tests in 8 suites, all passed) is cited as prior evidence only. Item 6 is satisfied for the findings in the current review file. It is NOT satisfied for the historical findings of rounds 1 to 4 (see human_verification), so status stays human_needed."
human_verification:
  - test: "Decide the scope of UAT round 2 item 6 (\"every code-review finding has one traceable disposition row, with no id reuse\"). Option A: scope is the current review (10-REVIEW.md, round 5) plus the round-1 Health finding. Option B: scope is every finding from rounds 1 to 5, so the historical findings listed under Disposition Traceability need their own rows."
    expected: "Option A: the owner records that decision (for example in 10-UAT.md). No other item is open, so re-running this verification returns passed. Option B: the owner or the disposition gate writes one row per historical finding under a distinct id, with its disposition, and no id is reused. The historical findings are recoverable from git (for example 4946faa, ff7635f, b0743f5, 9b1933d, e516837 for the review file, and the disposition history)."
    why_human: "The scope of the expectation is an owner decision. The verifier is not allowed to edit 10-REVIEW-DISPOSITION.md. The gate drops an earlier row when a later finding reuses its id (rule stated in the disposition file), so the historical rows cannot be restored automatically."
---

# Phase 10: Data & Platform Integration Modernization Verification Report (re-verification 4)

**Phase Goal:** Modernize domain, persistence, services and concurrency where justified while preserving existing data and system behavior.
**Requirements:** MOD-03, DATA-01, INT-01, INT-02
**Verified:** 2026-11-10T19:11:50Z
**Status:** human_needed
**Re-verification:** Yes. Prior report `10-VERIFICATION.md` (9802fe2, `human_needed`, 10/10 with one override) was blocked only by UAT round 2 item 6. This pass checks the fix in a090e77 and re-checks the code tree for drift.

## Summary

- The repaired row is in place. `R1-WR-01` (warning, fixed) appears in the frontmatter and the table of `10-REVIEW-DISPOSITION.md`. It cites `e3359cd`, which is the commit that changed `HealthService.performUpdate`, and `10-UAT.md` round 2 test 1, the owner accept. The file has nine unique ids and no duplicate.
- Every finding in the current review (`10-REVIEW.md`, round 5: WR-01, IN-01, IN-02) has exactly one row, and each row matches its finding's title and status.
- The code tree is unchanged since 9802fe2. All ten must-haves therefore carry forward from the prior pass. No must-have regressed.
- UAT round 2 item 6 says "every code-review finding". Read across all five review rounds, that is not yet true. Nine historical finding entries from rounds 1 to 4 have no row of their own, because their ids were reused and the gate dropped the earlier rows. The owner must choose the scope (see human_verification). Until that decision is recorded, status stays `human_needed`.
- No test command is configured. No tests were run in this pass.

## Disposition Traceability (UAT round 2 item 6)

Checked against `10-REVIEW-DISPOSITION.md` at a090e77.

**Current review (`10-REVIEW.md`, round 5):** each finding has exactly one row.

| Finding | Row | Result |
| ------- | --- | ------ |
| WR-01 (rollback claim false when the WAL move fails) | WR-01, warning, fixed, 10-REVIEW-FIX.md | One row. Title matches. |
| IN-01 (compensating-move failure untested) | IN-01, info, fixed | One row. Title matches. |
| IN-02 (`recoverStore` rollback nesting) | IN-02, info, fixed | One row. Title matches. |

**Round-1 Health finding:** `R1-WR-01`, warning, fixed. One row. Cites `e3359cd` and UAT round 2 test 1. This satisfies the specific item the prior report named.

**Other rows in the file:** WR-02 (round-2 "error branches without tests"), IN-03 (round-2 "recovery failure masks original open error"), WR-03 (round-1 fetch failure swallowed), WR-04 (round-1 "any open error" recovery, deferred), WR-05 (round-1 tests write to Application Support). Each row matches its finding. The file has no duplicate id.

**Historical findings with no row of their own** (from the git history of `10-REVIEW.md`; each was overwritten by a later review that reused its id):

| Round and commit | Finding | Row today | Notes |
| ---------------- | ------- | --------- | ----- |
| R1 (ff7635f) WR-02 | Weekly window leaves a 1-second gap | None. WR-02 now holds the round-2 finding. | Owner accepted the fix in UAT round 2 item 2 (45423d7, 130589d). Not traced in the file. |
| R1 (ff7635f) IN-01 | Redundant `cancelEpoch > myEpoch` guard and duplicated epoch logic | None. IN-01 now holds the round-5 finding. | The guard is still present at `ReminderService.swift:65` and `WeeklySummaryService.swift:114`. Not verified as resolved in this pass. |
| R1 (ff7635f) IN-02 | Stale test name `knownIssueF2` | None. IN-02 now holds the round-5 finding. | The name is still present at `HealthServiceConcurrencyTests.swift:50`. Info level. Not verified as resolved. |
| R1 (ff7635f) IN-03 | `seedPendingOpenInsights` not gated on `isActive` | None. IN-03 now holds the round-2 finding. | Not verified as resolved in this pass. |
| R2 (b0743f5) IN-01 | Stale test name and duplicated coverage after `performUpdate` change | None. | Not verified. |
| R2 (b0743f5) IN-02 | Trim test cannot prove the new snapshot survives | None. | Not verified. |
| R3 (9b1933d) and R4 (e516837) WR-01 | Failed rollback leaves a store file without its WAL (rollback family) | None distinct. The lineage continues in the round-5 WR-01 row and fix cebe16b. | Owner accepted the rollback guarantee (UAT round 2 item 5). |
| R3 (9b1933d) and R4 (e516837) IN-01 | Fetch-failure test exercises only the first fetch | None. | Not verified. |
| R3 (9b1933d) and R4 (e516837) IN-02 | Ledger recorded WR-01 as fixed while the defect was live | None. | Bookkeeping. Not verified. |

The R2 WR-01 finding is the same finding as R1 WR-04 (store recovery on any open error), and row WR-04 covers it.

**Reading of item 6.** Under the current-review scope (option A in human_verification), item 6 is satisfied. Under the all-rounds scope that the UAT wording states, it is not. This verifier did not decide the scope for the owner.

## Round-2 Human Items: Closure Check

Carried from the prior pass. The code tree is unchanged, so these checks still hold.

| # | Prior item | UAT round 2 result | Closure |
| - | ---------- | ------------------ | ------- |
| 1 | Health update path, `performUpdate` (`e3359cd`, WR-01); prohibitions 10-05 P1, 10-08 P1 | pass | Closed by owner pass. Row R1-WR-01 now records it. |
| 2 | Weekly scheduling (`scheduleIfEnabled`; `f4e7e03`, `c088a3e`, `45423d7`, `130589d`); prohibitions 10-06 P1, 10-09 P1 | pass | Closed by owner pass. |
| 3 | INT-02 edit path on a HEAD build | pass | Closed by owner pass (advisory: no count record on device). |
| 4 | WR-04 deferral | pass | Closed by owner pass. Row WR-04 is `deferred`. |
| 5 | `StoreBootstrap.rollBack` guarantee (`cebe16b`) | pass | Closed by owner pass. Code re-read in the prior pass. |
| 6 | Disposition traceability | pass | Current-review scope: closed (R1-WR-01 row, a090e77). All-rounds scope: open. See human_verification. |

## Goal Achievement

### Observable Truths

Carried from the prior pass (code tree identical to 9802fe2).

| #  | Truth (source) | Status | Evidence |
| -- | -------------- | ------ | -------- |
| 1  | Phase 08 candidates have documented dispositions; actor and lifecycle changes justified; substantial rewrites have owner briefs (roadmap SC1) | VERIFIED | `10-CONCURRENCY-RECORD.md` D-12 table and per-candidate sections; `10-EVIDENCE.md` C008, C009; decision briefs F2, F3, F4 carry owner records dated 2026-11-09. |
| 2  | Legacy schema fixtures and current store open with data intact, no reset (DATA-01; roadmap SC2) | VERIFIED | Prior pass ran `StoreBootstrapTests` (7 rollback tests). Device: `10-DEVICE-SESSION.md` Steps 1 to 4 PASS. Residual WR-04 accepted (round-2 item 4). |
| 3  | Model-shape changes add a versioned schema and migration; shipped schemas immutable (DATA-01; roadmap SC5) | VERIFIED | `git diff --quiet fbd37fa HEAD -- drinkpulse/Domain/Persistence/Schemas drinkpulse/Domain/Persistence/MigrationPlan.swift` exits 0. No SchemaV5 directory entry in `Schemas/`. |
| 4  | Daily and weekly opt-in, scheduling and completed-week comparison pass tests (INT-01; roadmap SC3, first part) | VERIFIED | Prior pass: `WeeklySummaryCompletedWeekTests`, `WeeklySummaryServiceCancellationTests`, `ReminderServiceCancellationTests`, `NotificationOptOutTests` passed. |
| 5  | Warm (backgrounded) tap routes to Add Drink (INT-01; roadmap SC3, second part) | VERIFIED | Device `10-DEVICE-RETEST.md` Step 4: taps 1, correct 1 (PASS). Routing files unchanged since device build `9ee31d5`. |
| 6  | Killed-app (cold) tap routes to Add Drink (INT-01; roadmap SC3, third part) | VERIFIED | Device `10-DEVICE-RETEST.md` Step 2: taps 3, correct 3 (PASS). `drinkpulseApp.init()` assigns the delegate synchronously (`drinkpulseApp.swift` lines 20 to 41). `NotificationDelegateAssignmentTests` passed in the prior pass. |
| 7  | Weekly summary cold tap routes to Insights (INT-01) | PASSED (override) | Owner Amendment 2 (frontmatter). Not device-observed. Automated routing: `WeeklySummaryTapUITests`, `NotificationActionHandlerTests`. |
| 8  | HealthKit permission, opt-in, write, delete and UUID dedup behave correctly; CloudKit stays disabled (INT-02; roadmap SC4) | VERIFIED | `performRemoveSample` (line 142) and `performUpdate` (line 115) both resolve `store.sampleUUID(forEventUUID:)` first; `performWrite` (line 93) checks for an existing sample (`HealthService.swift`). CloudKit: `drinkpulse.entitlements` has no iCloud or CloudKit key. `productionConfiguration` builds a `ModelConfiguration` without a CloudKit database. See the note on `cloudKitContainerID` under Anti-Patterns. |
| 9  | Approved modernization applied with isolation and lifecycle reasoning and regression evidence (MOD-03) | VERIFIED | F2 query-first remove and update; F3 lifecycle epochs in `ReminderService` (`cancelEpoch == lifecycleEpoch, cancelEpoch > myEpoch` at line 65) and `WeeklySummaryService` (line 114); `NotificationActionHandler` is `Sendable`; `HealthKitAdapter` has no `@unchecked`. |
| 10 | Weekly body carries owner-approved wording for all five variants (roadmap SC3 copy; `10-DECISION-F4.md`) | VERIFIED | `drinkpulse/Localizable.xcstrings` holds the approved strings. `WeeklySummaryCalculator.swift` unchanged since `fbd37fa`. |

**Score:** 10/10 truths verified (9 VERIFIED, 1 PASSED via owner-accepted override). `behavior_unverified: 0`. No `coincidental-reliance` items.

## Required Artifacts

Carried from the prior pass. The code tree is unchanged.

| Artifact | Expected | Status | Details |
| -------- | -------- | ------ | ------- |
| `drinkpulse/Domain/Persistence/MigrationPlan.swift`, `Schemas/SchemaV1` to `SchemaV4` | Shipped schemas immutable | VERIFIED | Unchanged since `fbd37fa`. |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | Reporting seam, rollback, happy-path open unchanged | VERIFIED (WARNING) | Rollback at line 140 (`rollBack`). WR-04 trigger still catches every open error (round-2 item 4). |
| `drinkpulse/Services/HealthService.swift` | F2 query-first remove; update path | VERIFIED (WARNING) | Round-2 item 1 owner accept. |
| `drinkpulse/Services/ReminderService.swift` | F3 lifecycle epoch | VERIFIED | Epoch fields and post-add check in place. |
| `drinkpulse/Services/WeeklySummaryService.swift` | F3 epoch; injectable `now` and `calendar`; fetch seam; half-open windows | VERIFIED (WARNING) | Fetch failure returns before any cancel or reschedule. Round-2 item 2. |
| `drinkpulse/Services/NotificationActionHandler.swift`, `drinkpulse/drinkpulseApp.swift` | Synchronous delegate assignment; `Sendable` handler | VERIFIED | Unchanged since device build `9ee31d5`. |
| `drinkpulse/Services/HealthKitAdapter.swift` | `@unchecked` removed (D-12) | VERIFIED | Unchanged. |
| `drinkpulseTests/Domain/Persistence/StoreBootstrapTests+Rollback.swift` | Pins each rollback failure case | VERIFIED | 7 tests passed in the prior pass. |
| `drinkpulse/Localizable.xcstrings` | Approved weekly strings | VERIFIED | Unchanged. |
| `10-DEVICE-RETEST.md`, `10-DEVICE-SESSION.md` | Device evidence: counts, PASS or FAIL, milliseconds only | VERIFIED | Privacy rule kept. |
| `10-REVIEW-DISPOSITION.md` | One traceable row per current-review finding; `R1-WR-01` present; no duplicate id in the file | VERIFIED for the current review and the R1 Health finding. Historical rows: see Disposition Traceability and human_verification. | a090e77 |

## Key Link Verification

- `drinkpulseApp.init()` to `UNUserNotificationCenter.current().delegate`: present and synchronous.
- `HealthService.performUpdate` to `store.sampleUUID(forEventUUID:)`: present (line 115).
- `HealthService.performRemoveSample` to `store.sampleUUID(forEventUUID:)`: present (line 142, F2).
- `WeeklySummaryService.scheduleIfEnabled` to the fetch seam: present; fetch errors return before any reschedule.
- `StoreBootstrap.makeContainerReportingRecovery` to `recoverStore` to `rollBack`: present.
- `NotificationActionHandler.route` to `docs/architecture.md`: described.

## Requirements Coverage

Cross-checked this pass against the `requirements:` field of all 14 plans and `.planning/REQUIREMENTS.md`. `REQUIREMENTS.md` has not changed since 9802fe2.

| Requirement | Source Plans | Description (REQUIREMENTS.md) | Status | Evidence |
| ----------- | ------------ | ----------------------------- | ------ | -------- |
| MOD-03 | 10-05, 10-06, 10-07, 10-08, 10-09, 10-11 | Approved modernization applied with isolation/lifecycle reasoning and regression evidence | SATISFIED | Truth 9. Prohibitions 8, 9, 11, 12 accepted by owner (round-2 items 1 and 2). |
| DATA-01 | 10-01, 10-03, 10-11, 10-12 | Existing stores keep data; migration without reset; shipped schemas immutable | SATISFIED | Truths 2 and 3. WR-04 residual accepted (round-2 item 4). |
| INT-01 | 10-02, 10-04, 10-06, 10-07, 10-09, 10-10, 10-11, 10-12, 10-13, 10-14 | Daily and weekly notifications preserve opt-in, scheduling, completed-week calculations and cold/warm tap routing on iOS 27 | SATISFIED | Truths 4, 5, 6, 10. Truth 7 PASSED via override. Natural weekly delivery unobserved. |
| INT-02 | 10-05, 10-07, 10-08, 10-11, 10-12 | HealthKit preserves permission, opt-in, write/delete and UUID dedup on iOS 27; CloudKit remains disabled | SATISFIED | Truth 8. Round-2 items 1 and 3. |

**ID cross-reference:**

- Plan frontmatter declares only MOD-03, DATA-01, INT-01 and INT-02. The union across the 14 plans is exactly these four.
- `REQUIREMENTS.md` lists all four (lines 19, 25, 26, 27) and maps each to Phase 10 (lines 57, 59, 60, 61).
- Orphans in REQUIREMENTS.md mapped to Phase 10 but absent from plans: none. Undeclared IDs in plans: none.
- The checkboxes and status column in `REQUIREMENTS.md` still read `Pending` / `[ ]`. The execute-phase orchestrator owns that update after this report reads `passed`. This verifier did not edit it.

## Prohibitions (judgment tier, 25 declared)

Carried from the prior pass. Every prohibition is `verification: judgment`. There are no test-tier prohibitions. Verdicts are non-authoritative.

Held: 1, 2, 4, 5, 6, 7, 10, 13 to 19, 21 to 25 (per the prior pass). Owner accepted as not held as worded: 3 (round 1, `26e164b`), 8 and 11 (round-2 item 1), 9 and 12 (round-2 item 2), 20 (post-10-13 fixes, round-2 items 1, 2 and 5).

## Code Review Findings (current disposition)

| Finding | Sev | Disposition | Verifier check | Effect |
| ------- | --- | ----------- | -------------- | ------ |
| Round 5 WR-01 (rollback WAL claim) | warning | fixed in `cebe16b` | Rollback re-read in prior pass; 7 tests passed | Round-2 item 5. |
| Round 5 IN-01 (compensating-move failure untested) | info | fixed | Covered by `rethrowsOriginalErrorAndKeepsSnapshot_whenTheSweepMoveAlsoFails` (prior pass) | None. |
| Round 5 IN-02 (rollBack nesting) | info | fixed (`rollBack` extracted) | Read in prior pass | None. |
| Round-1 Health finding (`performUpdate` stale sample) | warning | fixed in `e3359cd`; row `R1-WR-01` | Code re-read | Round-2 item 1. |
| Round-1 WR-03, WR-05; round-2 WR-02, IN-03 | warning / info | fixed (rows present) | Per prior pass | None. |
| Round-1 WR-04 (recovery on any open error) | warning | deferred (row WR-04) | `open-questions.md` entry | Round-2 item 4. |

Net: no finding contradicts a must-have truth as written. The historical traceability gap is recorded above.

## Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
| ---- | ---- | ------- | -------- | ------ |
| Changed implementation and test files | - | Debt markers `TBD`, `FIXME`, `XXX` | none | Carried from the prior pass. The code tree is unchanged, so the gate still passes. |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | 16 | `nonisolated static let cloudKitContainerID = "iCloud.com.drinkpulse.app"` is declared but never referenced | info | Harmless. CloudKit stays disabled: `productionConfiguration` sets no CloudKit database, and the entitlements have no iCloud key. The prior report said there was no CloudKit reference in `drinkpulse/`, which was slightly overstated. Remove the constant or note it, at the owner's choice. |
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` | - | `try?` on snapshot cleanup and trim | info | Best-effort cleanup. The rollback logs each failure. |
| `drinkpulse/UITestSeed.swift` | - | Hook keyed on its own launch argument | warning | Prohibition 3, owner accepted in round 1. |

No stub implementations, empty handlers or placeholder UI in changed files.

## Test-Suite Evidence

- **Not run in this pass.** No regression test command is configured, so the regression gate for this run is a no-op. Nothing in this report claims a test passed in this pass.
- **Prior pass (labelled prior evidence, not re-run):** scoped `xcodebuild test` on iPhone 18 Pro, iOS 27 simulator. Run A: 27 tests in 3 suites passed (`StoreBootstrapTests` including the 7 rollback tests, `WeeklySummaryCompletedWeekTests`, `HealthServiceUpdateTargetTests`). Run B: 23 tests in 5 suites passed. Total 50 tests in 8 suites. `** TEST SUCCEEDED **` for both.
- **Not run in any pass:** full unit suite, UI suite, `MigrationChainV1Tests`, `MigrationChainV2V3Tests`, `MigrationSweepTests` (prior pass only), `WeeklySummaryCopyTests` (prior pass only), coverage. The prior UI-suite instability was not re-checked.

## Probe Execution

No probes declared. No `scripts/*/tests/probe-*.sh` exists, and no PLAN or SUMMARY declares one. Skipped.

## Human Verification Required

1. **Scope of UAT round 2 item 6 (disposition traceability).** Choose one:
   - **Option A, current-review scope.** Every finding in `10-REVIEW.md` (round 5) and the round-1 Health finding each have exactly one row, with no duplicate id. Record this decision (for example in `10-UAT.md`). No other item is open, so re-running this verification returns `passed`.
   - **Option B, all-rounds scope.** The owner or the disposition gate writes one row per historical finding listed under Disposition Traceability, under distinct ids, each with its disposition. Then re-run this verification.

   The verifier did not edit `10-REVIEW-DISPOSITION.md`, as the request required. The historical findings can be recovered from git history of `10-REVIEW.md` (commits `ff7635f`, `b0743f5`, `9b1933d`, `e516837`) and of `10-REVIEW-DISPOSITION.md`.

## Advisory (Record and Hygiene, Not Blocking)

- **Uncommitted `drinkpulse.xcodeproj/project.pbxproj`.** The working tree adds `IPHONEOS_DEPLOYMENT_TARGET = 27.0` to two configurations. It is outside the covered set and was present for the prior pass's scoped run. The owner will decide on it separately. Decide whether it belongs in a commit before the next build-based gate.
- **Unused `cloudKitContainerID`** (`StoreBootstrap.swift:16`). See Anti-Patterns. No behavior change.
- **Round-2 accept lines.** Items 1 and 2 are accepted in `10-UAT.md` only; no decision brief records the accept line. Item 4 is `deferred` in the disposition row, but `open-questions.md` still says "To resolve". Item 3 has no counts-only device record. All optional.

## Gaps Summary

**No must-have gaps.** No truth is FAILED. No artifact is missing or a stub. No key link is unwired. No debt marker in changed code. No must-have regressed since the prior pass (the code tree is unchanged).

**Status is `human_needed` for one reason.** UAT round 2 item 6 reads "every code-review finding has one traceable disposition row, with no id reuse". The row the prior report named (`R1-WR-01`) is now present and correct, and the current review's findings are each traced. Across rounds 1 to 4, nine historical findings have no row of their own, because their ids were reused. The owner decides the scope (Option A or Option B). Option A returns `passed` on re-run. Option B needs the historical rows written first.

---

_Verified: 2026-11-10T19:11:50Z_
_Verifier: Claude (gsd-verifier), re-verification 4_
