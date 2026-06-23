# 0030 — Retrospective

**Completed**: 2026-06-22
**Outcome**: shipped as planned.

## What shipped

`UserProfile.unitSystem` is now live in the volume display + input layer. Serving
volumes render in the user's chosen unit (whole ml / one-decimal fl oz), new-drink
pickers offer region-native presets, and the onboarding default is picked from the
device locale. `volumeMl` stays canonical — no migration, no export-format change,
no calorie/grams/BAC/guideline/risk math change, `alcoholUnit` untouched.

## What went well

- The formatter as a pure Domain function on `(ml, unitSystem)` made 100%
  coverage trivial and keeps it forward-compatible with future user-created
  volume presets.
- The highest-risk item (edit-screen silent volume rewrite) was contained to two
  small, test-pinned changes: inject the exact stored volume as a picker option,
  and a pure static `volumeToPersist` guard. The corruption regression test
  (500 ml opened in US mode, untouched, saved → still 500) passes.
- Region-tagging the existing master list plus adding native servings where
  missing avoided triplicate volume tables, exactly as the plan predicted.

## What was tricky

- The `drinkpulseTests` target is not file-system-synchronized; new test files
  must be registered in `project.pbxproj` by hand. They compiled but were
  silently skipped at first — coverage on the formatter showed 0% until they were
  wired into the Sources build phase. Worth remembering for future test files.

## Decisions

- Oz precision: 1 decimal place; metric whole ml (plan default).
- Onboarding default: `Locale.current.measurementSystem` mapping, overridable via
  Settings (plan default; UK → imperial confirmed independent of UK alcohol unit).

## UI tests (added post-completion, 2026-06-22)

Four XCUITest classes — each in its own file in `drinkpulseUITests/` — pin the
four user-facing flows at the UI layer:

1. `EditVolumeIntegrityUITests.swift` — the 500 ml save-without-interaction regression.
2. `HistoryUnitDisplayUITests.swift` — EventRow re-renders on unit switch.
3. `AddDrinkPickerFilterUITests.swift` — Beer picker offers US-native fl oz rows in US mode.
4. `OnboardingLocaleDefaultUITests.swift` — onboarding locale default (en_US → US fl oz,
   de_DE → metric). Note: `en_GB → imperial` is NOT tested at the UI layer because
   iOS 26 Foundation maps `en_GB` to `.metric` at runtime (the unit test covers
   the `.uk → .imperial` path using `Locale(identifier: "en_GB")` on macOS directly).

Infrastructure: `UITestSeed.swift` provides a production-inert test hook (gated on
`-dp_uitest`): in-memory store, deterministic fixtures, and a `forceShowOnboarding`
flag that avoids NSArgumentDomain write-blocking. Added `forceOnboardingPending:
@State` to `drinkpulseApp` — a one-shot flag cleared by `OnboardingView.onFinish`,
adding no overhead in production. All 7 UI tests + 421 unit tests green (428 total).

## Follow-ups (out of scope here)

- User-created custom volume presets in SwiftData (tied to UnitSystem +
  DrinkCategory) and custom preset names — the shape chosen here
  (`descriptor` + `volumeMl` + `regions`) maps cleanly onto that model.
- Australian-vs-EU metric disambiguation remains a pre-existing limitation
  (`UnitSystem` has no AU case).
