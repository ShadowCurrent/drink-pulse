---
phase: 1
slug: weekly-summary-notification
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-20
---

# Phase 1 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Device -> Lock Screen notification banner | Weekly-summary notification body renders derived health-trend data (direction/percentage) readable by anyone with physical access to the locked device | Derived alcohol-consumption trend (qualitative + rounded percent) |
| App code -> OSLog | Service/UI code logs error categories via `Logger`; must never log computed grams/percentage values | Error categories only (no health data) |
| OS notification tap -> app navigation | `NotificationActionHandler.didReceive` is the only entry point that can move the app to a specific tab as a side effect of a tap | Locally-generated notification identifier |
| Launch-argument-gated test hook -> production build | `UITestSeed.seedPendingOpenInsights` must be provably inert whenever `-dp_uitest_pending_open_insights` is absent | Test-only boolean navigation flag |
| User tap -> AppStorage write | Onboarding + Settings toggles are the only user-facing controls that flip `weeklySummaryEnabled` | Boolean opt-in flag |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-01-01 | Information Disclosure | `Localizable.xcstrings` notification body strings (plan 01-01) | medium | mitigate | Verified: all `weeklySummary.notification.body.*` strings are qualitative/rounded-percent only (`directionOnlySame`, `directionOnlyUp`, `down`, `same`, `up`) — no raw gram values present | closed |
| T-01-02 | Information Disclosure | `WeeklySummaryCalculator` output values | medium | mitigate | Verified: `Domain/WeeklySummaryCalculator.swift` contains no `OSLog`/`Logger`/`print` — pure function, no logging surface | closed |
| T-01-03 | Information Disclosure | `WeeklySummaryService.bodyText(for:)` | medium | mitigate | Verified: body text uses only localized qualitative strings and a rounded `Int` percent via `String(format:)` — no raw gram interpolation | closed |
| T-01-04 | Information Disclosure | `WeeklySummaryService.scheduleIfEnabled`'s `logger.error` call | medium | mitigate | Verified: only call site is `logger.error("Failed to reschedule weekly summary: \(error.localizedDescription)")` — no Double/Int/Date interpolation of computed values | closed |
| T-01-05 | Tampering | Notification identifier matching (`weeklySummaryIdentifier`) | low | accept | Verified: all identifiers locally generated and locally consumed, no server-issued payload to spoof | closed |
| T-01-06 | Tampering | `NotificationActionHandler.didReceive` identifier match | low | accept | Verified: `if/else if` chain has no trailing `else` — unrecognized identifiers are silently ignored, matching the existing `ReminderService` pattern | closed |
| T-01-07 | Elevation of Privilege | Tap-triggered tab switch | low | accept | Verified: both the in-process (`RootShellView.task`) and cold-launch (`openInsightsIfPending`) paths only ever execute `selectedTab = .insights` — no other side effect, no data mutation | closed |
| T-01-08 | Denial of Service (self) | `WeeklySummarySection.enable()` / `HealthStep.enableWeeklySummary()` | low | accept | Verified: `catch` block always resets `enabled = false` and sets `permissionDenied = true`; generation-counter guards prevent stale re-arm; no retry loop | closed |
| T-01-09 | Information Disclosure | Denied-state hint text | low | accept | Verified: `settings.weeklySummary.denied` / `.hint` strings are generic ("Notifications are off...", "A weekly note on how this week compares to last.") — no health data | closed |
| T-01-10 | Elevation of Privilege | `UITestSeed.seedPendingOpenInsights` | low | accept | Verified: gated behind hardcoded `-dp_uitest_pending_open_insights` launch argument via `ProcessInfo.processInfo.arguments`, identical pattern to shipped `forceShowOnboarding`; inert in production/App Store builds, carries no PII | closed |

*Status: open · closed · open — below {block_on} threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01-01 | T-01-05 | All notification identifiers are locally generated and locally consumed on-device; no server-issued payload exists for an attacker to spoof | plan author (01-02) | 2026-07-20 |
| AR-01-02 | T-01-06 | Existing if/else-if structure already silently ignores unrecognized identifiers — correct, unchanged mitigation shared with `ReminderService` | plan author (01-03) | 2026-07-20 |
| AR-01-03 | T-01-07 | Only possible side effect of any identifier match is selecting an already-visible, existing tab — no privileged action or data mutation | plan author (01-03) | 2026-07-20 |
| AR-01-04 | T-01-08 | Failed authorization always resets UI to a consistent denied state; no infinite retry loop or crash path | plan author (01-04) | 2026-07-20 |
| AR-01-05 | T-01-09 | Denied-state hint text is generic and carries no health data, matching already-shipped `ReminderSection`/`HealthSection` pattern | plan author (01-04) | 2026-07-20 |
| AR-01-06 | T-01-10 | Test-only hook gated on hardcoded launch-argument string, identical to shipped `forceShowOnboarding`; inert in production, no PII | plan author (01-05) | 2026-07-20 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-20 | 10 | 10 | 0 | /gsd-secure-phase (L1 grep-depth, register authored at plan time) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-20
