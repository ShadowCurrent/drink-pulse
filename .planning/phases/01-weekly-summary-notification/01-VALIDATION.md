---
phase: 01
slug: weekly-summary-notification
# status lifecycle: draft (seeded by plan-phase) → validated (set by validate-phase §6)
# audit-milestone §5.5 distinguishes NOT-VALIDATED (draft) from PARTIAL (validated + nyquist_compliant: false) (#2117)
status: validated
nyquist_compliant: true
wave_0_complete: true
created: 2026-07-20
validated: 2026-07-20
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`@Test`, `#expect`) — confirmed in use by `drinkpulseTests/Services/ReminderServiceTests.swift` |
| **Config file** | none — target-based (`drinkpulseTests` / `drinkpulseUITests`, file-system-synchronized groups); no separate test config |
| **Quick run command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` |
| **Full suite command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |
| **Estimated runtime** | ~180 seconds (targeted) / ~600 seconds (full suite incl. UI tests) |

---

## Sampling Rate

- **After every task commit:** Run targeted `-only-testing:` for the file(s) touched
- **After every plan wave:** Run full `drinkpulseTests` + `drinkpulseUITests` suite
- **Before `/gsd-verify-work`:** Full suite must be green (build clean, zero warnings)
- **Max feedback latency:** 180 seconds

---

## Per-Task Verification Map

*Task IDs are assigned by the planner (not yet run at validation-strategy creation time). Rows below are keyed by requirement from RESEARCH.md's Phase Requirements → Test Map; the planner should attach these to the task(s) that implement each requirement.*

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-04 T1 | 01-04 | 3 | ENGG-01 | — | Settings toggle enable/disable, off by default | unit + UI | `xcodebuild test -only-testing:drinkpulseUITests/WeeklySummarySettingsUITests` | ✅ | ✅ green |
| 01-04 T2 | 01-04 | 3 | ENGG-02 | — | Onboarding opt-in offered, takes effect immediately (mirrored in Settings) | unit + UI | `xcodebuild test -only-testing:drinkpulseUITests/OnboardingWeeklySummaryUITests` | ✅ | ✅ green |
| 01-01/01-02 | 01-01, 01-02 | 1, 2 | ENGG-03 | T-01 (notification banner content disclosure) | Fires first day of new week (system locale), 9am local, correct % computed; body stays qualitative, never logs computed % / fire time / grams | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ✅ | ✅ green |
| 01-01/01-02 | 01-01, 01-02 | 1, 2 | ENGG-04 | T-01 | Body states %-change or "about the same" within ±5% | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ✅ | ✅ green |
| 01-01/01-02 | 01-01, 01-02 | 1, 2 | ENGG-05 | T-01 | Zero-last-week → direction-only, no numbers (no divide-by-zero) | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ✅ | ✅ green |
| 01-01/01-02 | 01-01, 01-02 | 1, 2 | ENGG-06 | — | No prior week at all → notification skipped (first-ever-week detection) | unit | `xcodebuild test -only-testing:drinkpulseTests/WeeklySummaryServiceTests -only-testing:drinkpulseTests/WeeklySummaryCalculatorTests` | ✅ | ✅ green |
| 01-03/01-05 | 01-03, 01-05 | 3, 4 | ENGG-07 | T-02 (tap-routing identifier spoofing — N/A, local-only) | Tap opens app at Insights tab (D-03/D-04) | UI | `xcodebuild test -only-testing:drinkpulseUITests/WeeklySummaryTapUITests` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `drinkpulseTests/Domain/WeeklySummaryCalculatorTests.swift` — covers ENGG-03/04/05/06 (pure calculator branches: percentage-up, percentage-down, ±5% "same" band boundary, zero-prior direction-only, skip-on-no-prior-data)
- [x] `drinkpulseTests/Services/WeeklySummaryServiceTests.swift` — covers ENGG-03/06 at the service level (mirrors `ReminderServiceTests.swift`: `FakeNotificationCenter`, `makeRequest` component assertions, `scheduleIfEnabled` gating on `@AppStorage`, idempotent schedule/cancel)
- [x] `drinkpulseUITests/Features/Settings/WeeklySummarySettingsUITests.swift` — covers ENGG-01 (mirrors `drinkpulseUITests/Features/Settings/ReminderSettingsUITests.swift`)
- [x] `drinkpulseUITests/Features/Onboarding/OnboardingWeeklySummaryUITests.swift` — covers ENGG-02 (toggle in `HealthStep`, immediate Settings reflection)
- [x] `drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift` — covers ENGG-07/D-03 (simulated tap → Insights tab selected; assert on app's own English strings or a stable `accessibilityIdentifier`, never system-process chrome, per CLAUDE.md's locale-independence rule)
- [x] No new test framework install needed — Swift Testing already the project standard

---

## Manual-Only Verifications

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 180s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** validated 2026-07-20 — all 7 requirements (ENGG-01–07) have passing automated coverage; all 5 Wave-0 test files confirmed present on disk.

## Validation Audit 2026-07-20
| Metric | Count |
|--------|-------|
| Gaps found | 0 |
| Resolved | 0 |
| Escalated | 0 |
