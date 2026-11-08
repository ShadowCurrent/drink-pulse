---
phase: "10"
slug: "data-platform-integration-modernization"
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: draft
nyquist_compliant: false
wave_0_complete: false
created: "2026-11-08"
---

# Phase 10 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (new unit tests); XCTest/XCUITest (UI tests) |
| **Config file** | `drinkpulse.xcodeproj/project.pbxproj` (file-system-synchronized targets) |
| **Quick run command** | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -only-testing:drinkpulseTests/<Class>` |
| **Full suite command** | `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID"` |
| **Estimated runtime** | Scoped ~60 s (incl. build); full suite ~25 min |

---

## Sampling Rate

- **After every task commit:** Run the scoped `-only-testing:` command for the touched class(es)
- **After every plan wave:** Run all Phase 10 test classes together plus a clean `xcodebuild build` with zero warnings
- **Before `/gsd-verify-work`:** Full suite must be green, device checklist signed off by owner, file-size check (no Swift file > 300 lines)
- **Max feedback latency:** ~120 seconds (scoped)

---

## Per-Task Verification Map

Filled in by the planner from `10-RESEARCH.md` § Validation Architecture → Phase Requirements → Test Map.

Scoped command shape for every row (NN is the plan number; each plan creates and uses its own dedicated simulator exported as `LOCAL_IOS_27_UDID_P10_NN`, so plans that run concurrently never share a simulator, and each plan that shares a wave with another runs in its own git worktree so one xcodebuild never compiles another plan's in-progress files; Xcode MCP is used first when connected and these CLI commands are the recorded fallback and gate): `xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID_P10_NN" -derivedDataPath build/p10-NN -only-testing:<target>/<Class>`; only the `-only-testing` selectors are listed below. The full commands live in each plan's `<automated>` blocks.

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-01-01 | 01 | 1 | DATA-01 | T-10-01, T-10-02 | V1 store migrates to V4 with every field; recovery seam reports no move-aside; schemas untouched | unit | `drinkpulseTests/MigrationChainV1Tests` | ❌ W0 | ⬜ pending |
| 10-01-02 | 01 | 1 | DATA-01 | T-10-01, T-10-02 | V2 and V3 stores migrate with identity and dates intact; a corrupted legacy store makes the seam report recovery and a fresh store opens (R-01 seam-level control) | unit | `drinkpulseTests/MigrationChainV2V3Tests` + `MigrationTests` + `StoreBootstrapTests` | ❌ W0 | ⬜ pending |
| 10-01-03 | 01 | 1 | DATA-01 | T-10-02, T-10-03 | Launch sweep merges and drops nothing; shipped schemas unchanged | unit + shell | `drinkpulseTests/MigrationSweepTests` + `RecordDeduplicatorTests` + `git diff --quiet fbd37fa -- Schemas MigrationPlan` | ❌ W0 | ⬜ pending |
| 10-02-01 | 02 | 1 | INT-01 | T-10-04, T-10-05 | Warm weekly-summary tap, delivered through UITestNotificationCenter, lands on Insights; hook only reachable under UI-test flag | UI | `drinkpulseUITests/WeeklySummaryTapUITests` | ✅ (new warm test) | ⬜ pending |
| 10-02-02 | 02 | 1 | INT-01 | T-10-05 | route() sets flag and posts per identifier; existing opt-in, scheduling and completed-week suites green | unit + UI | `drinkpulseTests/NotificationActionHandlerTests` + existing notification suites + Reminder/WeeklySummary/Onboarding UI suites | ❌ W0 | ⬜ pending |
| 10-03-01 | 03 | 1 | DATA-01 | T-10-07, T-10-08 | Fixture loads from bundle; probe import and re-import are no-ops; scrub guide written | unit | `drinkpulseTests/SanitizedBackupFixtureTests` | ❌ W0 | ⬜ pending |
| 10-03-02 | 03 | 1 | DATA-01 | T-10-06 | Owner scrubs and approves before any commit (one-way gate) | manual (owner) | checkpoint:decision, blocking-human | n/a | ⬜ pending |
| 10-03-03 | 03 | 1 | DATA-01 | T-10-06, T-10-08 | Sanitized fixture lint, no-op re-import, no healthKitUUID; importer untouched | unit + shell | `drinkpulseTests/SanitizedBackupFixtureTests` + DataTransfer suites + `git diff --quiet fbd37fa -- drinkpulse/Domain/DataTransfer` | ❌ W0 | ⬜ pending |
| 10-04-01 | 04 | 1 | INT-01 | T-10-09, T-10-10 | Completed-week comparison pinned at fixed dates; F4 staleness characterized | unit | `drinkpulseTests/WeeklySummaryCompletedWeekTests` + existing weekly suites | ❌ W0 | ⬜ pending |
| 10-04-02 | 04 | 1 | INT-01 | T-10-09 | F4 brief in Phase 08 D-10 format with D-16 compliance check and Excluded by D-16 section | doc | python section assertions on `10-DECISION-F4.md` | ❌ W0 | ⬜ pending |
| 10-04-03 | 04 | 1 | INT-01 | T-10-09 | Owner chooses a D-16-compliant route (as-of-last-visit, d16-as-written or d16-then-refresh) before any copy task | manual (owner) | checkpoint:decision | n/a | ⬜ pending |
| 10-04-04 | 04 | 1 | INT-01 | T-10-09 | F4 decision written into the brief's Owner decision record; Outcome, date, five strings and reason filled, no placeholder left | doc | python assertions on `10-DECISION-F4.md` | ❌ W0 | ⬜ pending |
| 10-05-01 | 05 | 1 | INT-02, MOD-03 | T-10-11 | F2 orphan sample pinned with known-issue test plus sequential control | unit | `drinkpulseTests/HealthServiceConcurrencyTests` | ❌ W0 | ⬜ pending |
| 10-05-02 | 05 | 1 | INT-02, MOD-03 | T-10-11, T-10-12 | F2 brief in D-10 format | doc | python section assertions on `10-DECISION-F2.md` | ❌ W0 | ⬜ pending |
| 10-05-03 | 05 | 1 | INT-02, MOD-03 | T-10-11 | Owner decides F2 fix scope | manual (owner) | checkpoint:decision | n/a | ⬜ pending |
| 10-05-04 | 05 | 1 | INT-02, MOD-03 | T-10-11 | F2 decision written into the brief's Owner decision record; Outcome, date, scope and reason filled, no placeholder left | doc | python assertions on `10-DECISION-F2.md` | ❌ W0 | ⬜ pending |
| 10-06-01 | 06 | 1 | INT-01, MOD-03 | T-10-13, T-10-14 | Reminder cancel-during-add race pinned deterministically | unit | `drinkpulseTests/ReminderServiceCancellationTests` | ❌ W0 | ⬜ pending |
| 10-06-02 | 06 | 1 | INT-01, MOD-03 | T-10-13 | Weekly race pinned; F3 brief with scope items S1 to S3 and O1 | unit + doc | `drinkpulseTests/WeeklySummaryServiceCancellationTests` + python assertions on `10-DECISION-F3.md` | ❌ W0 | ⬜ pending |
| 10-06-03 | 06 | 1 | INT-01, MOD-03 | T-10-13 | Owner decides F3 fix scope | manual (owner) | checkpoint:decision | n/a | ⬜ pending |
| 10-06-04 | 06 | 1 | INT-01, MOD-03 | T-10-13 | F3 decision and O1 approval state written into the brief's Owner decision record; no placeholder left | doc | python assertions on `10-DECISION-F3.md` | ❌ W0 | ⬜ pending |
| 10-07-01 | 07 | 1 | MOD-03, INT-02 | T-10-15 | Health per-event ordering and double-write idempotency pinned; a save that stored the sample but never reached the cache is relinked by the next backfill without a duplicate (R-02 seam-level control) | unit | `drinkpulseTests/HealthServiceOrderingTests` | ❌ W0 | ⬜ pending |
| 10-07-02 | 07 | 1 | MOD-03, INT-01 | T-10-16 | Cancel isolation between identifiers; no resurrection after opt-out | unit | `drinkpulseTests/NotificationOptOutTests` | ❌ W0 | ⬜ pending |
| 10-07-03 | 07 | 1 | MOD-03, INT-02 | T-10-15 | Adapter Sendable change (or retained with diagnostic); test-target warning removed; D-12 record started | unit + build | `drinkpulseTests/HealthServiceTests` + `HealthWriteHooksTests` + warning grep | ❌ W0 | ⬜ pending |
| 10-08-01 | 08 | 2 | INT-02, MOD-03 | T-10-17, T-10-18 | Owner-decided F2 resolution with regression tests; ADR-0011 invariants intact | unit | Health suites + `HealthServiceOrderingTests` | ✅ | ⬜ pending |
| 10-08-02 | 08 | 2 | INT-02 | T-10-17 | Edit-then-delete leaves zero Health samples in UI flow | UI | `drinkpulseUITests/HealthWriteHooksUITests` + `HealthSettingsUITests` | ✅ | ⬜ pending |
| 10-09-01 | 09 | 2 | INT-01, MOD-03 | T-10-19 | Owner-decided reminder lifecycle epoch; a superseded schedule never removes a later request; uncontested behavior unchanged | unit | `drinkpulseTests/ReminderServiceCancellationTests` + reminder suites | ✅ | ⬜ pending |
| 10-09-02 | 09 | 2 | INT-01, MOD-03 | T-10-19 | Owner-decided weekly lifecycle epoch with the same supersession guarantee; optional handler Sendable only if approved | unit | `drinkpulseTests/WeeklySummaryServiceCancellationTests` + weekly, opt-out and handler suites | ✅ | ⬜ pending |
| 10-09-03 | 09 | 2 | INT-01 | T-10-20 | ReminderSection generation guard only if approved; notification UI suites green | UI | Reminder/WeeklySummary/Onboarding UI suites | ✅ | ⬜ pending |
| 10-10-01 | 10 | 2 | INT-01 | T-10-21, T-10-22 | Owner-approved wording for the down variant, literal-string test | unit | `drinkpulseTests/WeeklySummaryCopyTests` | ❌ W0 | ⬜ pending |
| 10-10-02 | 10 | 2 | INT-01 | T-10-21, T-10-22 | All five variants pinned, rounding boundaries, copy todo closed | unit | `drinkpulseTests/WeeklySummaryCopyTests` + weekly suites | ❌ W0 | ⬜ pending |
| 10-11-01 | 11 | 3 | MOD-03 | T-10-23 | Sanitizer proven active by a canary created, run and deleted inside the gate, then clean on final code | unit + TSan | scoped suites with `-enableThreadSanitizer YES` | ✅ | ⬜ pending |
| 10-11-02 | 11 | 3 | MOD-03 | T-10-23 | C010, C011, C012 records complete; C008 and C009 dispositions recorded; architecture doc current | doc | python assertions on `10-CONCURRENCY-RECORD.md`, `10-EVIDENCE.md` and `docs/architecture.md` | ✅ | ⬜ pending |
| 10-11-03 | 11 | 3 | MOD-03, DATA-01, INT-01, INT-02 | T-10-24 | Zero warnings, schemas and CloudKit guards, file size, full suite (background gate), overall coverage at least 90 percent, Domain at 100 percent on the non-Persistence Domain files this phase changes (owner waiver D-20; the pre-existing Domain gap in WINDOWS.md row 7 is recorded, not gated), Services coverage on every changed testable Services file, the NotificationActionHandler route function and the Services aggregate | build + shell + full suite | clean `build-for-testing` + guards + background unfiltered `xcodebuild test` with its own result check + xccov | ✅ | ⬜ pending |
| 10-12-01 | 12 | 4 | INT-01, DATA-01 | T-10-27 | D-17 timing procedure dry-run on simulator; device checklist written | shell + doc | simctl launch and `log show` chain + python section assertions | ❌ W0 | ⬜ pending |
| 10-12-02 | 12 | 4 | DATA-01, INT-01, INT-02 | T-10-25, T-10-26 | Owner device session: upgrade in place, import round trip, HealthKit, notification taps, detached timing | manual (owner) | checkpoint:human-action, blocking-human | n/a | ⬜ pending |
| 10-12-03 | 12 | 4 | DATA-01, INT-01, INT-02 | T-10-25 | Results free of personal values; todo closed or escalated; living docs updated | doc | python assertions on results, todo location and DEVLOG | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `drinkpulseTests/Domain/Persistence/MigrationFixtures.swift`, `MigrationChainV1Tests.swift`, `MigrationChainV2V3Tests.swift`, `MigrationSweepTests.swift` — DATA-01
- [ ] `StoreBootstrap` recovery-reporting seam (test-seam only) — DATA-01
- [ ] Sanitized export fixture (not named `drinkpulse-backup-*.json`; owner scrub + review) + `SanitizedBackupFixtureTests` — INT-01 / C009
- [ ] `NotificationActionHandler.route(identifier:defaults:)` + `NotificationActionHandlerTests` — INT-01
- [ ] Time/calendar injection on `WeeklySummaryService.scheduleIfEnabled` — INT-01
- [ ] Warm-tap launch-argument hook (gated on `UITestSeed.isActive`), `UITestNotificationCenter.deliverTap` and the warm UI test in `WeeklySummaryTapUITests` — INT-01
- [ ] `HealthServiceConcurrencyTests`, `ReminderServiceCancellationTests`, `WeeklySummaryServiceCancellationTests` (`withKnownIssue` pins until owner-approved fixes) — INT-02 / INT-01
- [ ] Fix test-target warning `HealthWriteHooksTests.swift:116` — MOD-03
- [ ] Device-session checklist document — DATA-01 / INT-01 / INT-02 / D-17
- [ ] Concurrency disposition record for C010–C012 — MOD-03; C008 and C009 Phase 10 dispositions in `10-EVIDENCE.md` — DATA-01 / INT-01

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Owner's real store upgrades in place, no recovery, data intact | DATA-01 | Real device store cannot be reproduced in CI | Export, install over existing build on iOS 27 device, verify counts/values, import round trip |
| Real-device cold and warm notification taps route to Insights | INT-01 | Notification delivery and launch timing are device-only | Trigger daily/weekly notifications; tap from killed and backgrounded states |
| Real HealthKit prompt, write/update/delete, one sample per `dp_event_uuid` | INT-02 | Health app contents only observable on device | Opt in, log/edit/delete drink, inspect Health app |
| Cold-launch detached-task measurement | D-17 | Device timing | Record ms timings from DEBUG `ViewLoadLogger` |
| Residual risks R-01 (interrupted migration) and R-02 (interrupted Health write) acknowledged | DATA-01, INT-02 | A process kill mid-migration or mid-write cannot be reproduced on demand | Owner acknowledges both in the `10-DEVICE-SESSION.md` Sign-off; mitigations are pinned by StoreBootstrapTests and the Health relink tests |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
