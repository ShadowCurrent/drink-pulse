---
phase: 3
slug: app-startup-hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-07-27
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Swift Testing (`Testing` module, `@Test`/`#expect`) for unit tests; XCTest (`XCUITest`) for UI tests — both already in use project-wide |
| **Config file** | None — no `.xctestplan`; driven by scheme defaults (`xcodebuild test -scheme drinkpulse`) |
| **Quick run command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/<TargetSuite>` (swap suite per file under test) |
| **Full suite command** | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |
| **Estimated runtime** | ~3-5 min quick / ~10-15 min full |

---

## Sampling Rate

- **After every task commit:** Run the specific new/changed test target (`StoreBootstrapTests`, `UserProfileStoreTests`, or the new UI test file) via `-only-testing:`.
- **After every plan wave:** Full `xcodebuild test -scheme drinkpulse` suite green, including all four existing onboarding UI test files (regression gate: `OnboardingFlowUITests`, `OnboardingLocaleDefaultUITests`, `OnboardingHealthStepUITests`, `OnboardingWeeklySummaryUITests`).
- **Before `/gsd-verify-work`:** Full suite must be green, plus a manual Instruments "App Launch" trace (or stopwatch/log-timestamp check) confirming the first frame is not blocked on `StoreBootstrap.makeContainer` — this specific claim (STARTUP-02's "first frame before store settles") is not mechanically provable by `xcodebuild test` alone.
- **Max feedback latency:** ~300 seconds (full suite).

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | STARTUP-01 | — | Transient empty `@Query profiles` no longer resets `onboardingDone` | unit | `xcodebuild test -only-testing:drinkpulseTests/UserProfileStoreTests` | ✅ existing | ⬜ pending |
| 03-01-02 | 01 | 1 | STARTUP-01 | — | Mid-session profile deletion (new test hook) does NOT drop app back to `OnboardingView` | UI (XCUITest) | `xcodebuild test -only-testing:drinkpulseUITests/<NewOnboardingAuthorityUITests>` | ❌ Wave 0 — new file + new `UITestSeed` hook | ⬜ pending |
| 03-02-01 | 02 | 1 | STARTUP-02 | — | `sharedModelContainer` creation does not run synchronously in `App.init` | unit (behavioral) + manual | `xcodebuild test -only-testing:drinkpulseTests/StoreBootstrapTests` (existing, unaffected) + manual Instruments launch trace | ✅ existing coverage of `makeContainer` itself; timing claim is structural, verified by code review + manual check | ⬜ pending |
| 03-03-01 | 03 | 2 | STARTUP-03 | T-3-01 / V7,V8 | Container-open failure shows designed error view with Retry, not a crash; no raw error internals leaked | unit + UI | New `StartupErrorTests` (unit, `StartupError` categorization) + new `StartupErrorUITests` (UI) | ❌ Wave 0 — both new | ⬜ pending |
| 03-03-02 | 03 | 2 | STARTUP-03 | — | Retry button disables + shows spinner while in flight (D-10) | UI | Part of `StartupErrorUITests` | ❌ Wave 0 | ⬜ pending |
| 03-04-01 | — | 2 | STARTUP-01/02/03 | — | Existing onboarding UI hooks (`forceOnboardingPending`/`UITestSeed.forceShowOnboarding`) still behave correctly (Success Criterion 5) | UI (regression) | `xcodebuild test -only-testing:drinkpulseUITests/OnboardingFlowUITests -only-testing:drinkpulseUITests/OnboardingLocaleDefaultUITests -only-testing:drinkpulseUITests/OnboardingHealthStepUITests -only-testing:drinkpulseUITests/OnboardingWeeklySummaryUITests` | ✅ files exist — must re-run and confirm green after refactor | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Task IDs above are provisional — the planner assigns final plan/wave numbers; this map anchors requirement→test intent, not literal task IDs.*

---

## Wave 0 Requirements

- [ ] New UI test file for D-03: mid-session profile-deletion regression (proves `onboardingDone` alone gates the view, independent of `profiles` query state) — extends `UITestSeed` with a new launch-argument or in-app test-only hook, not a parallel mechanism.
- [ ] New `StartupErrorView` + `StartupError` unit tests (categorization logic, `Equatable` conformance if used for state comparison).
- [ ] New UI test(s) for the error screen: needs a deterministic way to force `StoreBootstrap.makeContainer` to fail under `-dp_uitest` (e.g. `-dp_uitest_force_store_failure YES`) so the error screen, Retry-disable, and spinner states are all UI-testable without real disk corruption.
- [ ] ADR `docs/decisions/0012-onboarding-single-source-of-truth.md` (D-02) — documentation artifact required by this phase's definition of done, not a test.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| First frame draws before `StoreBootstrap.makeContainer` completes | STARTUP-02 | Not mechanically provable by `xcodebuild test` alone — this is a timing/ordering claim, not a functional assertion | Run app in Instruments "App Launch" template (or log-timestamp the first `body` render vs. container-ready callback); confirm first frame timestamp precedes container-ready timestamp |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 300s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
