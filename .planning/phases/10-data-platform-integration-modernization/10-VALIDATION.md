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

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 10-XX-XX | — | — | DATA-01 / INT-01 / INT-02 / MOD-03 | — | — | — | see RESEARCH test map | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `drinkpulseTests/Domain/Persistence/MigrationFixtures.swift`, `MigrationChainTests.swift`, `MigrationSweepTests.swift` — DATA-01
- [ ] `StoreBootstrap` recovery-reporting seam (test-seam only) — DATA-01
- [ ] Sanitized export fixture (not named `drinkpulse-backup-*.json`; owner scrub + review) + `SanitizedBackupFixtureTests` — INT-01 / C009
- [ ] `NotificationActionHandler.route(identifier:defaults:)` + `NotificationActionHandlerTests` — INT-01
- [ ] Time/calendar injection on `WeeklySummaryService.scheduleIfEnabled` — INT-01
- [ ] Warm-tap launch-argument hook (gated on `UITestSeed.isActive`) + warm UI test in `WeeklySummaryTapUITests` — INT-01
- [ ] `HealthServiceConcurrencyTests`, `ReminderServiceCancellationTests`, `WeeklySummaryServiceCancellationTests` (`withKnownIssue` pins until owner-approved fixes) — INT-02 / INT-01
- [ ] Fix test-target warning `HealthWriteHooksTests.swift:116` — MOD-03
- [ ] Device-session checklist document — DATA-01 / INT-01 / INT-02 / D-17
- [ ] Concurrency disposition record for C010–C012 — MOD-03

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Owner's real store upgrades in place, no recovery, data intact | DATA-01 | Real device store cannot be reproduced in CI | Export, install over existing build on iOS 27 device, verify counts/values, import round trip |
| Real-device cold and warm notification taps route to Insights | INT-01 | Notification delivery and launch timing are device-only | Trigger daily/weekly notifications; tap from killed and backgrounded states |
| Real HealthKit prompt, write/update/delete, one sample per `dp_event_uuid` | INT-02 | Health app contents only observable on device | Opt in, log/edit/delete drink, inspect Health app |
| Cold-launch detached-task measurement | D-17 | Device timing | Record ms timings from DEBUG `ViewLoadLogger` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
