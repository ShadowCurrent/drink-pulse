# 0009 — Retrospective

**Completed**: 2026-05-20

## What went well

- Plan scope was well-defined; implementation mapped cleanly to the five files
  outlined in the plan with no structural surprises.
- Using `dateOfBirth: Date?` instead of `age: Int?` (decided before freeze) paid
  off immediately: computed `ageYears` is cleaner than any stored-age approach.
- `OnboardingViewModel` kept pure (no SwiftUI dependency), making the 9 unit
  tests straightforward to write.
- `guidelineExplicitlyPicked` flag neatly solved the "WHO default vs. user
  actually chose WHO" ambiguity without extra stored state.
- `reduceMotion` was wired correctly at the TabView level on the first attempt.
- All 9 test suites (121 tests) pass; no files exceed 300 lines.

## What went wrong / surprises

- **Schema migration gap**: removing `ageYears: Int` (non-optional stored
  property) is not a lightweight migration. Dev workaround (wipe store on
  `ModelContainer` init failure) was put in `drinkpulseApp.swift`. Must be
  replaced with a proper `SchemaMigrationPlan` before App Store submission.
  Tracked in `open-questions.md`.

- **Missing shared xcscheme** (discovered on close): the project had no
  `xcshareddata/xcschemes/drinkpulse.xcscheme` file, so `xcodebuild test`
  ran 0 tests via the auto-generated scheme (which lacked a TestAction).
  Fixed by creating the shared scheme file referencing both the app and
  `drinkpulseTests` targets. Now committed to source control so CI and
  collaborators can run tests without Xcode open.

## Decisions made during execution

- `dateOfBirth: Date?` over `age: Int?` — full DOB needed for Widmark BAC
  and Insights; on-device storage, so privacy cost is acceptable.
- `TabView(.page)` (Q1 default) — native swipe, no custom offset math.
- Welcome → Profile → Guideline order (Q2 default) — matches design handoff.
- Emoji 🫀 placeholder (Q4 default) — ship fast, revisit with brand assets.
- Re-run onboarding from Settings (Q3) — deferred to a follow-up plan.

## Leftover open questions

- SwiftData schema migration for `ageYears → dateOfBirth` (tracked in
  open-questions.md; blocks App Store submission).
- Visual QA in Previews (light / dark / AX5) — can be done in Xcode
  at any time; no code changes expected.
