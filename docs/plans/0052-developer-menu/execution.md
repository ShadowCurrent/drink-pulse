# 0052 — Execution journal

## 2026-11-26 — Plan frozen and executed (inline, superpowers `executing-plans`)

- Owner approved the short design in chat (option A: rehearsal, no profile write) and asked to
  plan and execute inline, scoped tests only. Branch `dev/0052-developer-menu` from `ui-revamp`
  at `c78c494`. Xcode MCP workspace `drinkpulse.xcodeproj` (identifier via
  `XcodeListWorkspaces`); destination iPhone 18 Pro simulator, iOS 27.2.
- Apple docs consulted (Xcode MCP `DocumentationSearch`): SwiftUI `Entry()` macro and
  "Creating custom environment values" — `@Entry` on an `EnvironmentValues` extension, set with
  `environment(_:_:)`, read with `@Environment`. No other new API.

### Task 1 — Debug-only `UITestSeed`
- `UITestSeed.swift`: real enum under `#if DEBUG`, Release stub under `#else` (every member used
  outside the file: `isActive`, `forceShowOnboarding`, `deleteProfileMidSession`,
  `seedPendingOpenInsights`, `armWarmWeeklySummaryTap`, `forceReduceMotion` = `false`;
  `resetTransientDefaults()` / `seedFixtures(into:)` no-ops; `makeContainer(schema:)` throws).
  `UITestSeed+Fixtures.swift` wrapped in `#if DEBUG`.
- Release build via `xcodebuild -configuration Release` (Xcode MCP has no configuration
  selector — named missing capability), separate derived data: **BUILD SUCCEEDED**, no compiler
  warnings. `strings` on the Release binary: no `-dp_uitest*`, `-dp_force_onboarding` or
  Developer copy; only `dp_uitest_health_sample_count` (the `UITestHealthStore` key, kept per
  D0052-5).

### Task 2 — Rehearsal replay and Developer section
- RED: `DeveloperMenuUITests/test_replayOnboarding_rehearsal_keepsSeededProfile` failed,
  "Developer 'Replay Onboarding' should be shown".
- Implemented `OnboardingReplay.swift`, `DeveloperSection.swift`, `OnboardingView.persistsProfile`,
  `RootShellView` rehearsal state / `replayOnboarding()` / `isRehearsal`, Settings wiring.
- Test fixes (not product): the Developer row loads only once scrolled to (swipe-up loop); the
  Home tab is labelled "Today"; Settings keeps its scroll position, so the sex-picker check
  swipes back up.
- GREEN: new test passed. Scoped regressions `OnboardingFlowUITests` + `SettingsUITests`:
  15/15 passed (covers Review Focus 3: real first-run save still carries into Settings).
- Debug build (MCP): 0 warnings. No file over 300 lines (`RootShellView.swift` 243).
- Not run: full suite and coverage (owner: scoped only). No unit test added: the new logic is
  view wiring (`#if DEBUG` view code), pinned by the UI test.

## 2026-11-27 — Pre-merge review and fix

- Owner verified the Debug build on their iPhone ("działa"); branch pushed on the owner's word.
- Fresh reviewer (standing OK, one before merge): **With fixes**, 0 Critical, 1 Important.
  - Important (fixed): `HealthStep` toggles write `healthWriteEnabled` / `weeklySummaryEnabled`
    on change (not on Done), request permissions and can cancel the weekly notification, so a
    rehearsal changed real settings despite D0052-1. Fix: `HealthStep(isRehearsal:)` binds both
    toggles to local `@State` (first-run defaults, no service call); `OnboardingView` passes
    `!persistsProfile`.
  - RED: new `test_replayOnboarding_rehearsal_healthStepToggles_leaveSettingsUnchanged` failed
    ("1" is not equal to "0" — Settings Weekly Summary turned on by the rehearsal). GREEN after
    the fix.
  - Minor, deferred: no Done haptic in a rehearsal (keyed on `onboardingDone` false→true);
    no test for a second replay or the entrance itself; Review Focus 4 (flag untouched) holds by
    code reading only — `-dp_onboarding_done YES` in the launch-argument domain would mask a
    stray write; sex-picker lookup by label; closure rebuilt per shell body (Debug only).
- Correction: the 2026-11-26 "Debug build 0 warnings" came from an incremental MCP build log
  and missed one warning: "Storing a closure in '@Entry var replayOnboarding' may invalidate
  dependents on every update because closures may not be comparable." Fix: the entry now holds
  `OnboardingReplayAction` (`Equatable`, always equal — one shell owns it and its closure only
  writes the shell's `@State`; called via `callAsFunction`, the `DismissAction` shape). No Apple
  doc covers the warning (Xcode MCP `DocumentationSearch` searched); the fix follows the
  compiler's diagnostic. Clean builds in fresh derived data: Debug and Release, 0 warnings.
