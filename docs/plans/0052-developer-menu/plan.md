# 0052 — Debug-only Developer menu and Debug-only UITestSeed

**Status**: in-progress
**Frozen**: 2026-11-26
**Size**: small
**Created**: 2026-11-26
**Branch**: `dev/0052-developer-menu` (from `ui-revamp` at `c78c494`)

> Execution: superpowers `executing-plans`, inline, one session (owner instruction 2026-11-26).
> Scoped tests only: the new UI test plus the onboarding/settings classes the change touches.
> Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** On the owner's own iPhone (Debug build), replay onboarding and Today's first-run
entrance from Settings without touching real data; ship none of it, nor the UI-test seeding
hooks, in Release.

**Architecture:** `UITestSeed` keeps its API; its real body compiles only under `#if DEBUG` and a
Release stub returns constant `false` / no-ops, so production call sites (`HealthService`,
`ReminderService`, `WeeklySummaryService`, `RootShellView`, `drinkpulseApp`, `DPMotionProbe`)
compile unchanged. A Debug-only environment action `replayOnboarding` is injected by
`RootShellView`; a Debug-only `DeveloperSection` in Settings calls it. A replay is a rehearsal:
`OnboardingView(persistsProfile: false)` skips `vm.complete(into:)`, and `onboardingDone` is not
written.

**Tech stack:** SwiftUI (`fullScreenCover`, `@Entry` environment values, `Form` `Section`),
Swift compilation conditions (`#if DEBUG`), XCUITest. No new Apple API: every API is already
used in the same files.

**Spec:** the short design approved in chat on 2026-11-26 (recorded below in "Decisions").

## Decisions

- D0052-1: Replay is a dry run (owner pick, option A). Done closes the cover; no `UserProfile`
  insert, no `onboardingDone` write. Reason: `complete(into:)` inserts a second profile and every
  screen reads `profiles.first` with no sort, so a second profile makes settings flip at random.
- D0052-2: Entry point is a "Developer" section at the bottom of Settings, Debug only.
- D0052-3: Replay switches to the Home tab and sets `firstRunRevealed = false` before the cover
  opens, so the entrance plays on dismiss through the existing `revealFirstRun()`.
- D0052-4: Debug-only copy uses `Text(verbatim:)` / verbatim strings, not the string catalog, so
  no Debug text ships in Release `Localizable.xcstrings` (deliberate exception to the
  `String(localized:)` rule; owner may overrule).
- D0052-5: `UITestSeed` stays a type in Release (stub) rather than gating every call site;
  `UITestSeed+Fixtures.swift` is Debug only. Fakes (`UITestHealthStore`,
  `UITestNotificationCenter`) stay compiled but are unreachable in Release (`isActive == false`).
- D0052-6: Out of scope: store-recovery restore, profile robustness (missing / duplicate /
  invalid), update-time re-onboarding. Recorded in `open-questions.md` ("Store recovery …").

## Review Focus

1. Release build must compile with every `UITestSeed` member used outside its file.
2. A rehearsal Done must leave the seeded profile unchanged (sex stays Male).
3. Real first-run onboarding must still save the profile (`persistsProfile` default `true`).
4. After a rehearsal, a later real launch must not show onboarding (flag untouched).
5. Rehearsal state must reset on dismiss so a second replay works.

## Tasks

### Task 1: Debug-only `UITestSeed`

**Files:** Modify `drinkpulse/UITestSeed.swift`, `drinkpulse/UITestSeed+Fixtures.swift`.

- [ ] Wrap the current `UITestSeed` enum in `#if DEBUG`; add `#else` stub with
  `isActive`, `forceShowOnboarding`, `deleteProfileMidSession`, `seedPendingOpenInsights`,
  `armWarmWeeklySummaryTap`, `forceReduceMotion` = `false` (same isolation as today),
  `resetTransientDefaults()` no-op, `seedFixtures(into:)` no-op,
  `makeContainer(schema:)` throws `UITestForcedStoreFailure` (unreachable).
- [ ] Wrap `UITestSeed+Fixtures.swift` in `#if DEBUG`.
- [ ] Verify: Debug build clean; Release build (`-configuration Release`, simulator) clean.

### Task 2: Rehearsal replay and Developer section

**Files:**
- Create: `drinkpulse/Features/Shell/OnboardingReplay.swift` (`#if DEBUG`:
  `extension EnvironmentValues { @Entry var replayOnboarding: (@MainActor () -> Void)? = nil }`)
- Create: `drinkpulse/Features/Settings/Components/DeveloperSection.swift` (`#if DEBUG`; one
  button "Replay Onboarding", identifier `dp_dev_replay_onboarding`; preview)
- Modify: `drinkpulse/Features/Onboarding/OnboardingView.swift` (`var persistsProfile = true`;
  `finish()` calls `vm.complete(into:)` only when true)
- Modify: `drinkpulse/Features/Shell/RootShellView.swift` (Debug-only `@State onboardingRehearsal`;
  `replayOnboarding()` sets tab `.home`, `firstRunRevealed = false`, rehearsal, cover; `onFinish`
  writes `onboardingDone` only outside rehearsal; `revealFirstRun()` resets rehearsal)
- Modify: `drinkpulse/Features/Settings/SettingsView.swift` (`#if DEBUG DeveloperSection() #endif`
  after `DataSection()`)
- Test: `drinkpulseUITests/Features/Settings/DeveloperMenuUITests.swift`

- [ ] Write UI test `test_replayOnboarding_rehearsal_keepsSeededProfile`: launch with
  `-dp_onboarding_done YES -dp_uitest YES` (seeded profile Male); Settings → tap
  `dp_dev_replay_onboarding`; assert "Get Started" shown; `OnboardingWalk.walkToHealth(sex:
  "Female")`; tap Done; assert Home shown (tab Home selected); Settings sex picker label contains
  "Male" and not "Female".
- [ ] Run it: FAIL (no `dp_dev_replay_onboarding`).
- [ ] Implement the files above.
- [ ] Run new test: PASS. Run scoped regressions `OnboardingFlowUITests`, `SettingsUITests`.

### Task 3: Docs

- [ ] `execution.md`, `retrospective.md`, `INDEX.md`, `docs/architecture.md` (Debug-only
  Developer menu + `UITestSeed` Release stub), `DEVLOG.md`, `current-focus.md`.
