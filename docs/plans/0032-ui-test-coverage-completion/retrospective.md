# 0032 — Retrospective

**Completed**: 2026-06-24

## What went well
- **Feature-by-feature, one sequential Opus 4.8 subagent per feature** worked
  cleanly: 7 steps, 7 new test files, 32 new UI tests, all green. Each agent
  got a focused brief + the prior step's discoveries, so context compounded
  (Save flow found in step 2 fed steps 3–4; element-addressing notes chained
  through 5–7).
- **Zero production behaviour changes.** Every screen turned out fully
  addressable via app-rendered English text, nav/tab bars, picker `.value`,
  segmented controls, and existing accessibility labels/traits — **no new
  `accessibilityIdentifier` was needed anywhere.** The only app-code change
  was an additive, launch-arg-gated, synthetic multi-day seed fixture for
  Insights (`UITestSeed+Fixtures.swift`).
- **No bugs uncovered** — the app's wiring matched expectations on every
  screen, and the History edit data-integrity guard held under a real UI
  driving test.
- Locale-independence held: nothing keyed off Polish system-process UI;
  C-locale number formatting (`%.1f`) made numeric assertions safe.

## What went wrong / surprises
- **Plan coverage table had two small inaccuracies vs. the real UI**, caught
  during execution (not bugs, just doc drift):
  - Onboarding has **no weight input** (collects sex + DOB only); the
    "profile inputs (weight/sex)" carry test asserts sex + guideline instead.
  - Settings has **no in-app app-lock toggle**; "App Lock" deep-links to iOS
    Settings. Test asserts row presence/hittability, doesn't tap into system UI.
- **Transient simulator stall** in step 4 ("Test crashed with signal kill")
  — cleared by `xcrun simctl shutdown all`. Recommend a clean-sim start in CI.
- **SourceKit live diagnostics were misleading** — repeated "No such module
  'XCTest'" and stale "cannot find type" errors on files that compiled fine.
  Resolved by trusting `xcodebuild build` over the index (verified once with a
  full build after the step-5 seed change).
- Theme/appearance settings persist in `@AppStorage`/UserDefaults, which the
  in-memory `-dp_uitest` store does NOT reset → non-deterministic start state
  across runs. Handled by making those tests order-independent.

## Decisions made during execution
- **Standing bug policy (owner):** UI-test-found bug → fix if small, escalate
  if large; BAC/guidelines/sync always escalate. Passed into every subagent
  prompt. (No bug actually triggered it.)
- **One gated multi-day fixture** (`-dp_uitest_dataset multiday`) added for
  Insights only; History's single-day seed sufficed. Fixture is
  priority-ordered above provenance and the default single beer so exactly one
  path runs; inert in production.
- Kept each test file < 300 lines; History split into a `+Helpers` file.

## Leftover open questions
- None blocking. Optional follow-ups:
  - Consider resetting `@AppStorage` theme/scheme keys under `-dp_uitest` for
    fully deterministic appearance tests.
  - CI: clean-sim start (`simctl shutdown all`) to avoid the transient stall.
  - The swipe-to-delete trash control has no accessibility label (SF Symbol
    only) — a minor a11y gap worth a real label someday (driven via coordinate
    swipe for now).
