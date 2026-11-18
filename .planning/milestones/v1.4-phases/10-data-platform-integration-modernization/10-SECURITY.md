---
phase: "10"
slug: "data-platform-integration-modernization"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-10"
---

# Phase 10 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| App process to on-disk SwiftData store | Migration and recovery can move or reshape the only copy of the user's health history. | Drink history (personal, high) |
| App process to the unified log | Console and sysdiagnose can read log lines; health data must never reach them. | Log text (must hold no personal data) |
| App to Apple Health store | Writes and deletes must hit exactly the sample for one drink event. | HealthKit samples (personal, high) |
| App to the system notification daemon | Schedule and cancel races can leave a request that fires after opt-out. | Notification requests (low) |
| System notification response to the app delegate | The OS delivers taps on app-scheduled notifications, including on a killed app. | App-defined identifier (low) |
| Notification text to the user's lock screen | The body states a health comparison; wording or format specifiers can mislead. | Summary copy (medium) |
| Launch arguments to app behavior | Test-only arguments must never change routing in a production launch. | Launch flags (low) |
| Launch path (main thread, before first frame) | Synchronous system call in init could delay every launch. | Timing (low) |
| Owner's device, real data and exports to the repository | Results, fixtures, logs or screenshots could leak personal values into git history. | Personal values, identifiers (critical) |
| Production configuration | A change to entitlements or model configuration could enable sync of health data. | Entitlements, model config (high) |
| Evidence claims to downstream verification | No-race, zero-warning and device-sample claims are only as strong as their proof. | Evidence (medium) |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-10-01 | Tampering | StoreBootstrap recovery masking a failed migration | high | mitigate | Recovery-reporting seam; migration chain tests assert no recovery and file exists; control test asserts recovery | closed |
| T-10-02 | Tampering | Shipped SchemaV1-V4 and MigrationPlan | high | mitigate | Baseline diff guard vs fbd37fa clean; recorded in 10-EVIDENCE.md | closed |
| T-10-03 | Information disclosure | Test fixtures and output | medium | mitigate | No print in tests; UUID temp store names; defer cleanup in migration tests | closed |
| T-10-04 | Elevation of privilege | Warm-tap launch-argument hook | medium | mitigate | UITestSeed.armWarmWeeklySummaryTap guarded by isActive; single deliverTap call behind warmTapArmed | closed |
| T-10-05 | Tampering | Delegate-to-route extraction | medium | mitigate | NotificationActionHandlerTests route_* cases; WeeklySummaryTapUITests cold and warm | closed |
| T-10-06 | Information disclosure | sanitized-export-v2.json fixture | critical | mitigate | Placeholder values, no healthKitUUID; SanitizedBackupFixtureTests lint plus negative test; owner approval in 10-03-SUMMARY; raw exports gitignored | closed |
| T-10-07 | Information disclosure | Scrub script paths | high | mitigate | 10-FIXTURE-SCRUB.md aborts inside repo, on backup names and unknown keys | closed |
| T-10-08 | Tampering | DataImporter and export format | medium | mitigate | DataTransfer diff guard vs fbd37fa clean | closed |
| T-10-09 | Tampering | Weekly summary period assertion | medium | mitigate | WeeklySummaryCompletedWeekTests f4_*; owner outcome as-of-last-visit recorded before copy change | closed |
| T-10-10 | Tampering | scheduleIfEnabled signature | medium | mitigate | Defaults now: .now, calendar: .current; calculator and InsightsPeriod untouched | closed |
| T-10-11 | Tampering | HealthWriteHooks.remove stale UUID | high | mitigate | Pinned in 10-05, fixed in 10-08 (fix-query-first); pin flipped to plain #expect | closed |
| T-10-12 | Information disclosure | New test data and briefs | low | mitigate | Synthetic UUID() events only; no UUID-shaped strings in briefs | closed |
| T-10-13 | Tampering | Reminder/Weekly cancel vs in-flight add | medium | mitigate | Cancellation test pins; lifecycle epoch fix in 10-09 | closed |
| T-10-14 | Denial of service | SlowNotificationCenter test double | low | mitigate | OSAllocatedUnfairLock state; bounded wait loop | closed |
| T-10-15 | Tampering | HealthKitAdapter Sendable change | medium | mitigate | Unchecked qualifier removed; SDK NS_SWIFT_SENDABLE cited in 10-CONCURRENCY-RECORD.md; warning-free build | closed |
| T-10-16 | Tampering | Cancel removing the wrong identifier | medium | mitigate | NotificationOptOutTests cross-identifier isolation and reschedule-after-opt-out | closed |
| T-10-17 | Tampering | performRemoveSample target resolution | high | mitigate | HealthService queries by dp_event_uuid first, captured UUID fallback; stale/noSample/throws tests | closed |
| T-10-18 | Information disclosure | Logging in changed Health method | low | mitigate | Logs error.localizedDescription only | closed |
| T-10-19 | Tampering | Lifecycle epoch | medium | mitigate | Epoch guard in both services; supersession tests and controls | closed |
| T-10-20 | Tampering | ReminderSection generation guard | low | mitigate | Conditional on S3; owner deferred S3 (10-DECISION-F3.md); file untouched | closed |
| T-10-21 | Tampering | Format specifiers in up/down bodies | medium | mitigate | Catalog has %d%% only in up and down; WeeklySummaryCopyTests over [1,5,50,100] | closed |
| T-10-22 | Repudiation | Misleading period statement | medium | mitigate | Catalog matches as-of-last-visit outcome; literal-string tests | closed |
| T-10-23 | Repudiation | TSan no-race evidence | medium | mitigate | Same-run canary produced a TSan race warning, then removed; 144 tests clean (10-EVIDENCE.md) | closed |
| T-10-24 | Information disclosure | CloudKit enablement / model weakening | high | mitigate | Entitlements hold HealthKit only; no cloudKitDatabase; plain ModelConfiguration; schema guard clean | closed |
| T-10-25 | Information disclosure | Device session results, DEVLOG | high | mitigate | Counts, PASS/FAIL and ms only; no UUID-shaped strings; no images or logs tracked | closed |
| T-10-26 | Tampering | In-place install over real store | high | mitigate | Backup outside repo, never-delete rule, schema stop rule, counts equal before and after | closed |
| T-10-27 | Repudiation | Cold-launch timing under debugger | medium | mitigate | Detached Home Screen launches; simulator dry run documented | closed |
| T-10-28 | Information disclosure | didReceive log line | medium | mitigate | Logs only tapKind as .public; no userInfo or content access; never-echo test | closed |
| T-10-29 | Denial of service | Synchronous UNUserNotificationCenter.current() in init | medium | mitigate | Timing log (Amendment 1); device delegate assigned 5-7 ms, D-17 near | closed |
| T-10-30 | Denial of service | Weak delegate dropping the handler | medium | mitigate | Stored notificationHandler property; identity test; device cold taps 3 of 3 | closed |
| T-10-31 | Information disclosure | Re-test record, DEVLOG entry | high | mitigate | Counts and ms only; no UUID-shaped strings; blocking-human checkpoint | closed |
| T-10-32 | Tampering | Re-test taps over real store | high | mitigate | No delete, no clock change, no real drink; existing store kept; schema and DataTransfer guards clean | closed |
| T-10-33 | Repudiation | Seam tests read as proof of delivery | medium | mitigate | Verification-source statement; device 3 of 3; R-03 owner-accepted | closed |
| T-10-SC (10-01) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-02) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-03) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-04) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-05) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-06) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-07) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-08) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-09) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-10) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-11) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-12) | Tampering | Package install surface | low | accept | No package-manager installs; third-party SDKs forbidden (see Accepted Risks Log) | closed |
| T-10-SC (10-13) | Tampering | npm/pip/cargo installs | high | mitigate | No package manifests or remote Swift packages tracked; pbxproj unchanged; no install task | closed |
| T-10-SC (10-14) | Tampering | npm/pip/cargo installs | high | mitigate | No package manifests or remote Swift packages tracked; pbxproj unchanged; no install task | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

Baseline guards re-run on 2026-11-10 against `fbd37fa`: Schemas and `MigrationPlan.swift` unchanged, `drinkpulse/Domain/DataTransfer` unchanged, entitlements and `project.pbxproj` unchanged.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-10-SC (10-01 to 10-12) | No package-manager installs in these plans and the project forbids third-party SDKs, so there is no install surface to verify. | Plan authors (threat model) | 2026-11-08 |
| AR-02 | R-01 (T-10-01, T-10-26) | Interrupted migration cannot be reproduced on demand; recovery seam and StoreBootstrapTests pin the mitigation. | Owner (10-DEVICE-SESSION.md sign-off) | 2026-11-09 |
| AR-03 | R-02 (T-10-17) | Interrupted Health write cannot be reproduced on demand; relink-on-backfill test pins the mitigation. | Owner (10-DEVICE-SESSION.md sign-off) | 2026-11-09 |
| AR-04 | R-03 (T-10-33) | Killed-app delivery is a finite device sample (3 of 3), not proof for every OS state. | Owner (10-DEVICE-RETEST.md sign-off) | 2026-11-10 |
| AR-05 | T-10-20 | ReminderSection generation guard (S3) deferred by owner decision; the guarded code path was not changed. | Owner (10-DECISION-F3.md) | 2026-11-09 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-10 | 47 | 47 | 0 | gsd-security-auditor (ASVS L1, block_on high) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-10
