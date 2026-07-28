---
phase: 2
slug: swift-6-language-mode-migration
status: validated
nyquist_compliant: true
wave_0_complete: false
created: 2026-07-27
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (primary, 44/46 unit-test files) + XCTest (legacy, 2 unit-test types; all 27 `drinkpulseUITests` files) |
| **Config file** | None — no `.xctestplan`; single shared scheme `drinkpulse.xcscheme` |
| **Quick run command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests` |
| **Full suite command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (includes `drinkpulseUITests`) |
| **Estimated runtime** | ~3-5 min quick / ~10-15 min full |

---

## Sampling Rate

- **After every task commit:** Run `xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build` for a targeted build check, plus `-only-testing:drinkpulseTests` quick run.
- **After every plan wave:** Run the full suite command (unit + UI tests), both Debug and Release builds.
- **Before `/gsd-verify-work`:** Full suite must be green; both Debug and Release builds clean with zero warnings.
- **Max feedback latency:** ~300 seconds (full suite).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | SWIFT6-01 | — | App target Debug+Release build clean under `SWIFT_VERSION=6.0` | build-verification | `xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build \| grep -E "error:\|warning:"` (expect empty) | N/A — command-based | ⬜ pending |
| 02-01-02 | 01 | 1 | SWIFT6-01 | — | No unjustified suppression (`@preconcurrency`, `nonisolated(unsafe)`, `@unchecked Sendable`) | manual/code-review | `grep -rn "@unchecked\|@preconcurrency\|nonisolated(unsafe)" drinkpulse/` then inspect each site's comment | ✅ 4 existing sites enumerated in RESEARCH.md | ⬜ pending |
| 02-02-01 | 02 | 2 | SWIFT6-02 | — | No deprecated/soft-deprecated API left after flip | build-log + grep verification | Re-run deprecated-API grep sweep + confirm zero `deprecated` lines in flipped build log | N/A — command-based | ⬜ pending |
| 02-03-01 | 03 | 2 | SWIFT6-03 | — | Explicit, applied decision on `HistoryViewModelPerformanceTests` and `ScreenComputePerformanceTests` | documentation + existing test run | `xcodebuild test -only-testing:drinkpulseTests/HistoryViewModelPerformanceTests -only-testing:drinkpulseTests/ScreenComputePerformanceTests` | ✅ both files exist today | ⬜ pending |
| 02-04-01 | 04 | 3 | SWIFT6-01 | — | Coverage stays ≥90% overall / per-layer after migration | coverage gate | `xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult` | ✅ existing xcresult pipeline | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs above are provisional — the planner assigns final plan/wave numbers; this map anchors requirement→test intent, not literal task IDs.*

---

## Wave 0 Requirements

*None: existing test infrastructure (Swift Testing + XCTest, already exercised via direct `xcodebuild` runs in research) fully covers this phase's requirements. No new test files, fixtures, or framework installs are needed.*

---

## Manual-Only Verifications

*If none: "All phase behaviors have automated verification."*

All phase behaviors have automated verification via `xcodebuild build`/`test` commands and grep-based suppression audits.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
