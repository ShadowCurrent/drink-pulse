# 0030 — Execution journal

Append-only. Entries are dated; the plan (`plan.md`) is frozen.

## 2026-06-22 — Implementation

### Open decisions resolved (with the plan's proposed defaults)

- **Oz display precision** → **1 decimal place** for both US and imperial
  (`"16.9 fl oz"`); metric rounds to **whole ml** (`"500 ml"`). Recorded as a
  domain rule in `domain.md`. The formatter (`UnitSystem.formatVolume`) uses
  `volume.format.flOz` = `"%.1f fl oz"` and `volume.format.ml` = `"%.0f ml"`.
- **Onboarding default source** → `Locale.current.measurementSystem`, with
  `.us → .usCustomary`, `.uk → .imperial`, `.metric`/unknown → `.metric`. The
  user can override later via the existing Settings volume-unit picker
  (onboarding has no dedicated unit step, so "user-overridable" is satisfied by
  Settings rather than a new onboarding control). `OnboardingViewModel.init`
  picks the default; `complete(into:)` writes it to the new profile.

### What was built (plan steps 1–8)

1. **Domain formatter** — new `Domain/UnitSystem+Volume.swift`:
   `mlPerUSFluidOunce = 29.5735`, `mlPerImperialFluidOunce = 28.4131`,
   `mlPerFluidOunce`, `fluidOunces(fromMl:)`, `volumeUnitLabel`,
   `formatVolume(_:)`. Pure on `(ml, unitSystem)`. 100% unit-tested
   (`UnitSystemVolumeTests`).
2. **`VolumeOption` reshape** — `descriptor` + `volumeMl` + `regions:
   Set<UnitSystem>` (number no longer baked into the string). Added
   `volumes(for:)`, `nearestVolumeMl(to:in:)`, `defaultVolumeMl(for:)`, and
   `VolumeOption.label(for:)`. Replaced `defaultVolumeIndex` with
   `defaultVolumeMl`. Region-tagged the two preset extension files per the
   resolved policy; added native US/imperial servings where a category lacked
   them (coverage invariant). Custom preset: `customVolumes(for:)` gives 10 ml
   steps in metric and 0.5 fl oz steps in oz modes.
3. **DrinkDetailInputView** — index-based selection → ml-based; region filter;
   `resolveVolumeForUnit()` on appear and unit change; formatter labels.
4. **EditEventView** — the central risk. Removed the closest-row snap in `init`;
   selection is now ml-based seeded from the **exact** `event.volumeMl`, which is
   injected as a pre-selected picker option when off-region. Added the static
   pure guard `volumeToPersist(selected:original:)` so `save()` only overwrites
   `event.volumeMl` when the user changed the selection. Regression-pinned by
   `EditEventVolumeGuardTests` (500 ml opened in `.usCustomary`, untouched → still
   500; explicit change → persisted; off-grid 444.5 survives).
5. **EventRow** — subtitle line and accessibility string use
   `unitSystem.formatVolume`.
6. **Onboarding** — locale default (above).
7. **domain.md** — added a "Volume units (display only)" section: conversion
   constants, clean anchors, rounding policy.
8. **Localization** — added `unit.ml`, `unit.flOz`, `volume.format.ml`,
   `volume.format.flOz`, `editDrink.currentServing`.

### Deviations / discoveries

- **`ConsumptionEvent.baseName` simplified** (not explicitly listed in the plan's
  file table but required by the reshape): it previously parsed the baked-in
  number out of `VolumeOption.label` via `components(separatedBy: " · ")`. With
  the new shape it reads `match.descriptor` directly (falls back to the preset
  name when the descriptor is empty, e.g. custom). The "Pint UK" descriptor was
  renamed to "Pint" (the "UK" was redundant with the imperial region tag); the
  corresponding `ConsumptionEventTests` assertion was updated to "Pint".
- **Test target is NOT file-system-synchronized.** Only the `drinkpulse` app and
  `drinkpulseUITests` groups use `PBXFileSystemSynchronizedRootGroup`;
  `drinkpulseTests` lists files explicitly. The two new test files
  (`UnitSystemVolumeTests.swift`, `EditEventVolumeGuardTests.swift`) were
  registered manually in `project.pbxproj` (PBXBuildFile + PBXFileReference +
  group children + Sources build phase). Without this they compiled into the
  index but were silently not run.

### Results

- Build: clean, zero warnings (the AppIntents-metadata note is a pre-existing
  toolchain message, not a code warning).
- Tests: 417 tests in 20 suites, all green.
- Coverage: `UnitSystem+Volume.swift` 100% (33/33); `OnboardingViewModel.swift`
  100%; `DrinkTypePreset.swift` 96.61%; `DrinkTypePreset+FermentedPresets.swift`
  96.30%. SwiftUI view bodies (DrinkDetailInputView, EditEventView, EventRow) are
  excluded from the coverage denominator per CLAUDE.md.
- File size: no Swift file over 300 lines.

## 2026-06-22 — Reopened for UI tests (post-completion)

The plan was marked `completed` after the unit-test pass above. Reopened to
`in-progress` by user request to add end-to-end **UI tests** for the
user-facing flows (the original plan only required unit tests + the edit-guard
regression unit test). `plan.md` stays frozen; this scope is additive and lives
here.

UI-test scope agreed (all four):
1. Edit volume-integrity guard — drive EditEventView in `.usCustomary`, save a
   500 ml event untouched, assert it stays 500 (the load-bearing data-integrity
   risk, pinned at the UI layer, not only as a pure-function unit test).
2. Unit display in history — switch `unitSystem`, assert EventRow subtitles
   render in `fl oz` vs `ml`.
3. Add-drink picker filtering — in US mode, assert the serving picker offers
   oz-native servings / oz labels.
4. Onboarding locale default — fresh onboarding picks `unitSystem` from device
   locale; override honored.

Also: CLAUDE.md gains a mandatory "UI tests for every user-facing feature"
policy (Testing section + end-of-task checklist item). This is a standing
project-rule change, recorded in DEVLOG, not scoped to 0030.

## 2026-06-22 — UI tests implemented

### Test-hook design

New file `drinkpulse/UITestSeed.swift` provides a minimal, production-inert
test fixture hook. All behaviour is gated on `UITestSeed.isActive` (checks
`ProcessInfo.processInfo.arguments.contains("-dp_uitest")`), evaluated once at
app start from an immutable process-scoped value. Inert in production and App
Store builds.

**What the hook does (only when `-dp_uitest YES` is present):**
- Replaces the persistent `StoreBootstrap.makeContainer` with an in-memory
  `ModelContainer` — tests never touch the real user store.
- Seeds a deterministic `UserProfile` + 500 ml 5% beer `ConsumptionEvent` via
  `UITestSeed.seedFixtures(into:)`, called from `RootShellView.onAppear` when
  `onboardingDone` is true (i.e. after skipping onboarding with
  `-dp_onboarding_done YES`). The profile's `unitSystem` is set via the optional
  `-dp_uitest_unit <metric|usCustomary|imperial>` argument (defaults to
  `.metric`).
- `UITestSeed.forceShowOnboarding` (gated on `-dp_force_onboarding YES`) lets
  onboarding-locale tests always start at `OnboardingView` without the
  `NSArgumentDomain` write-blocking problem: rather than overriding
  `dp_onboarding_done` via `NSArgumentDomain` (which would prevent
  `onboardingDone = true` from taking effect inside the app), a separate
  `@State var forceOnboardingPending` in `drinkpulseApp` is seeded from this
  flag and cleared by `OnboardingView.onFinish`, allowing the transition to
  `RootShellView` to happen normally.

**Privacy compliance:** only synthetic fixture data; no PII; no network; no
`print`; no force-unwraps; no third-party SDKs.

**`drinkpulseApp.swift` changes (minimal):**
- Container selection: `UITestSeed.isActive ? UITestSeed.makeContainer : StoreBootstrap.makeContainer`
- Routing: `onboardingDone && !forceOnboardingPending` (the `&&` added to support
  the onboarding locale test; no change in the common production path where both
  flags are false/false → `onboardingDone` alone governs).
- Seeding: `seedIfUITest()` called on `RootShellView.onAppear`.

### Four UI tests (drinkpulseUITests/VolumeUnitUITests.swift)

1. **`EditVolumeIntegrityUITests.test_editUntouched_preservesOriginal500mlAsFlOz`**
   — seeds 500 ml beer + `.usCustomary` profile, navigates to History, opens
   EditEventView, taps Save without touching any picker, asserts the row still
   shows "16.9" fl oz (not "16.0" = the 473 ml snap). Pins the data-corruption
   regression at the UI layer (complementing the pure-function unit test).

2. **`HistoryUnitDisplayUITests.test_unitSwitch_reRendersSubtitle`**
   — starts in `.metric`, asserts EventRow shows "500 ml"; switches to US fl oz
   via Settings picker, asserts row shows "fl oz"; switches back, asserts "500 ml"
   returns. Confirms live re-rendering on unitSystem change.

3. **`AddDrinkPickerFilterUITests.test_addBeer_usMode_showsFlOzLabels`**
   — starts in `.usCustomary`, opens Add Drink → Beer; reads `pickerWheels
   .element(boundBy: 0).value`; asserts it contains "fl oz" and not "500 ml"
   (metric-only Bottle) or "20.0" fl oz (imperial-only Pint). Confirms
   region-filter for new-drink presets.

4. **`OnboardingLocaleDefaultUITests`** — two subtests, each using
   `-dp_force_onboarding YES`:
   - `test_onboarding_enUS_defaultsToUsFlOz`: drives onboarding to completion
     with `en_US` locale; asserts Settings volume picker shows "US fl oz".
   - `test_onboarding_deDE_defaultsToMillilitres`: same with `de_DE`; asserts
     "Millilitres".
   Note: `en_GB` is not used for the imperial assertion because in iOS 26 the
   simulator reports `Locale.current.measurementSystem = .metric` for `en_GB`
   (Foundation changed the UK classification in iOS 26). The unit test
   `OnboardingViewModelTests.test_uk_locale_mapsToImperial` covers the
   `.uk → .imperial` mapping directly via `Locale(identifier: "en_GB")` on macOS,
   which still returns `.uk`. The UI test layer covers the two mappings that are
   stable in the iOS 26 simulator.

### Accessibility structure finding (from diagnostic run)

History `List` cells have `.label == ""` in the XCTest tree. `EventRow` is
rendered as a `.buttonStyle(.plain)` Button inside the cell; its combined
`accessibilityLabel` ("Bottle, 16.9 fl oz, …") lives on the Button element,
not on the cell container. All four tests query `app.buttons.matching(…)` with
`NSPredicate(format: "label CONTAINS %@", …)` rather than `.cells`.

The volume `Picker`'s selected row is readable as `pickerWheels.element(boundBy:
0).value as? String` — wheel-picker content is NOT surfaced as `staticTexts`.

### Results

- Build: clean, zero warnings in production target (pre-existing Swift 6
  main-actor warnings in the UI test target match the existing
  `ExportUITests.swift` — same pattern, pre-existing toolchain behaviour).
- All 7 UI tests pass:
  - `AddDrinkPickerFilterUITests.test_addBeer_usMode_showsFlOzLabels` ✓
  - `EditVolumeIntegrityUITests.test_editUntouched_preservesOriginal500mlAsFlOz` ✓
  - `ExportUITests.test_export_dismissWithoutSaving_showsNoFailureAlert` ✓
  - `ExportUITests.test_export_presentsSavePanel_andConfirmsOnSave` ✓
  - `HistoryUnitDisplayUITests.test_unitSwitch_reRendersSubtitle` ✓
  - `OnboardingLocaleDefaultUITests.test_onboarding_deDE_defaultsToMillilitres` ✓
  - `OnboardingLocaleDefaultUITests.test_onboarding_enUS_defaultsToUsFlOz` ✓
- Unit test suite: 417 tests / 20 suites, all green (unchanged from before).
- File size: no Swift file over 300 lines in `drinkpulse/`.

## 2026-06-22 — File split + seeding guard fix

`VolumeUnitUITests.swift` (389 lines) exceeded the 300-line ceiling. Split into
four per-class files in `drinkpulseUITests/` (all auto-included via
`PBXFileSystemSynchronizedRootGroup`):
- `EditVolumeIntegrityUITests.swift` (88 lines)
- `HistoryUnitDisplayUITests.swift` (88 lines)
- `AddDrinkPickerFilterUITests.swift` (79 lines)
- `OnboardingLocaleDefaultUITests.swift` (113 lines)

Also fixed a seeding race condition: `UITestSeed.seedFixtures` previously
inserted a second `UserProfile` when called from `RootShellView.onAppear` after
an onboarding-locale test completed (the onboarding flow had already created the
profile with the locale-correct `unitSystem`). Fix: added `guard !forceShowOnboarding`
at the top of `seedFixtures` so it skips seeding when `-dp_force_onboarding YES`
is active.

Final verified state: build clean (zero warnings); 428 tests / 0 failures
(421 unit + 7 UI, confirmed via xcresult); all 4 new UI test files under
300 lines.

## 2026-06-23 — Reopened: full volume vision continues in subplan 0031

0030 is **reopened to `in-progress` and now blocked by [0031](../0031-volume-serving-expansion-and-provenance/)**.
Its full volume vision (a realistic per-region serving inventory + a stable,
correctable per-event serving name) is carried forward into subplan 0031.

**0030's own shipped scope is unchanged** — the wiring of `unitSystem` into
volume display/input, the pure `(ml, unitSystem)` formatter, the `VolumeOption`
reshape, the EditEventView integrity guard, and the unit + UI tests all stand as
delivered. This reopening adds no new work to 0030 itself; it records that the
feature is considered fully delivered only once 0031 lands. `plan.md` stays
frozen.

Two follow-on decisions were made:

- **[ADR-0007](../../decisions/0007-volume-provenance-entered-unit.md)** —
  "C′" volume provenance: add an optional `ConsumptionEvent.enteredUnit:
  UnitSystem?` so a logged drink's serving *name* is stable across unit-mode
  switches (resolved via the logged unit, not the current profile) while staying
  correctable (name looked up live in the editable preset table). `volumeMl`
  stays the frozen canonical truth; no calculation change.
- **[plan-0031](../0031-volume-serving-expansion-and-provenance/)** (draft) —
  adopt C′ storage + the proposal-2 (v3) US/imperial/metric serving expansion.
  It carries **two unresolved sign-offs**: pint/fraction display as a new domain
  rule, and the region-tag policy reversal (tagging non-round real measures +
  cross-borrows, which contradicts 0030's "natural round serving only" rule).
