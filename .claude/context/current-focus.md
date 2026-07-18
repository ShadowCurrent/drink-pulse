# Current Focus

_Update this file at the end of every session._

## Status: plan-0036 post-completion fix — add-time Health push (2026-06-30)

Fixed a device bug: with Health write-back ON, a newly logged drink never reached
Apple Health until the user toggled sync off/on. Cause was a stale `.notDetermined`
write-auth status on a fresh process gating the write silently. `HealthService` now
self-heals (re-requests once on `.notDetermined`, never on `.denied`). Closed the test
gap both layers — `HealthWriteHooksTests` (hook→service wiring) + a UI test asserting a
sample is actually written on add (via a `-dp_uitest` count-only probe). Build clean,
suite green, `HealthService`/`HealthWriteHooks` 100%. Committed locally, **not pushed**.

**Next:** owner decision on remaining threads (BAC, multi-currency, guideline-card tap);
optional stretch — an in-app indicator when Health is enabled but not authorized.

---

## Status: plan-0036 COMPLETE — Apple Health write-back (2026-06-29)

Shipped opt-in, off-by-default Apple Health write-back across 8 isolated waves
(one commit + execution.md entry each). Logged drinks mirror to
`numberOfAlcoholicBeverages` (a drinks **count** = `pureAlcoholGrams / 14.0`, fixed
US-standard-drink size — **HealthKit has no grams type**, the roadmap premise was
wrong). Enable from Settings or a new onboarding 4th step. Dedup by a durable
`dp_event_uuid` sample metadata key (**read+write**) so reinstall/restore/multi-device
never duplicate; `healthKitUUID` is a device-local cache only (never exported/synced).
Best-effort, non-blocking.

- **New:** `Services/HealthService` (+ `HealthWriting` protocol, `HKHealthStore`
  adapter, `UITestHealthStore` stub, `HealthWriteHooks`), `SchemaV4` + v3→v4
  lightweight stage + `ConsumptionEvent.healthKitUUID`, HealthKit entitlement +
  read/write Info.plist strings, ADR-0011.
- **Gates:** build clean (zero new warnings; entitlement embeds, simulator runs
  ad-hoc — **no paid account needed for dev/tests**); full suite TEST SUCCEEDED; app
  coverage **93.23%** (≥90%); HealthService logic 100%; no production file > 300.
- **All work pushed.** `main` in sync with `origin/main` (HEAD e18154c, verified
  2026-06-30); tree clean. Earlier "not committed/not pushed" notes below are stale.
- **Process note:** one subagent (W8) hit a session limit; coordinator finished it
  inline. W8 UI test needed a coordinate tap (XCUI centre-tap misses a full-width
  labelled Toggle) — test fix, not a view bug.

**Device caveat:** on-device install needs the HealthKit capability provisioned
against a team (App Store → paid account). Reading from Health is out of scope.

**Next:** owner's call — all candidate threads need a decision first: BAC (needs
design approval), multi-currency spend display, guideline-card tap. plan-0023
Phase B (CloudKit) stays gated (paid account + provisioned container + one-way
approval). Loose ends: dead `dp_theme` key, History pint subtitle (`formatVolume`
→ `servingVolumeLabel`), pre-existing test-macro warnings (~244 on main).

---

## Status: plan-0036 FROZEN — Apple Health write-back; execution handed off (2026-06-29)

Owner picked Apple Health write as the next feature. Plan-0036 drafted, decisions
locked, **frozen (in-progress)**. **No feature code written here** — owner wants
execution in **separate Opus session(s), parallel where useful**; the wave/session
breakdown + dependencies are the handoff log in
`docs/plans/0036-apple-health-write-back/execution.md`.

- **Scope:** opt-in, write-only mirror of drinks → Health `dietaryAlcohol` (grams =
  `pureAlcoholGrams`, 0.789, no calc change). New `Services/HealthService` (protocol
  + `HKHealthStore` adapter + UI-test stub), same shape as `ReminderService`.
- **Confirmed decisions:** backfill = ask at enable; error model = best-effort
  non-blocking (Health failure never blocks the in-app action); **new ADR-0011**;
  schema = **SchemaV4 + v3→v4 stage** (additive optional `healthKitUUID`, no amend).
- **Dedup correction (post-freeze, in execution.md):** "write fresh" alone would
  DUPLICATE samples on reinstall and on Phase-B multi-device (app delete does NOT
  remove Health samples; Apple Health has its own iCloud sync). Fix: stamp each
  sample with `metadata.dp_event_uuid = ConsumptionEvent.uuid` + **dedup-on-write**
  (query→relink). Scope is now **read + write** (was write-only); Info.plist needs
  `NSHealthShareUsageDescription` too. `healthKitUUID` = device-local fast cache.
- **Waves:** W1 schema (foundation) → W3 service → W4 Settings → W5 hooks; W2
  (protocol+adapters) and W6 (entitlement/Info.plist) are parallel-safe; **W8
  onboarding Health step** (new 4th onboarding step, OFF by default, shares the
  W4 flag/HealthService — extends plan-0009); W7 close-out (ADR-0011, UI test,
  coverage, docs).
- **Flag:** HealthKit on device needs the capability; simulator + UI tests need no
  paid account.

**Also this session:** added CLAUDE.md forward-compat rule (every schema/model
change must stay CloudKit- AND HealthKit-ready). plan-0023 flip-point work
committed locally (`739cbc9`).

**Next:** execute plan-0036 in the handoff sessions, appending to its execution.md.

---

## Status: plan-0023 CloudKit flip-point centralized; live-Settings LWW confirmed (2026-06-29)

Owner direction: **do not enable CloudKit** (no paid Apple Developer account /
provisioned container) — only prepare the code so the future flip is a single,
documented switch. CloudKit stays **OFF**.

- **Live-Settings `modifiedDate` — already done.** Every editable profile field in
  `SettingsView` binds via `touching(_:)` / `dobBinding`, both calling
  `profile.touch()` on a real change (sex, DOB, guideline, unit system, alcohol
  unit, ABV precision, currency). Landed in commit `a06eb03`; the Phase-B pre-req
  TODO is closed — docs just lagged.
- **Flip point centralized.** New `StoreBootstrap.productionConfiguration(schema:)`
  + `cloudKitContainerID` (`iCloud.com.drinkpulse.app`); `drinkpulseApp` calls it
  instead of building `ModelConfiguration` inline. Inline doc gives the exact
  one-way 2-step flip (iCloud entitlement + `.private(cloudKitContainerID)`). **No
  entitlements file added** — one with no provisioned container breaks signing.
- **Gates:** app build clean (zero new warnings); full suite green. Changes left in
  the working tree (not committed).

**plan-0023 stays `in-progress`** — enabling CloudKit (Phase B) is its actual
deliverable and is externally gated (provisioned container + one-way approval). It
is NOT closed. Next work happens on a different topic.

---

## Status: plan-0023 Phase A DONE — CloudKit-ready schema, CloudKit OFF (2026-06-28)

Executed plan-0023 **Phase A** wave by wave (owner: do Phase A now; **Phase B
parked** — no paid Apple Developer account to enable iCloud). Plan frozen
(`in-progress`). Full detail: `docs/plans/0023-cloudkit-sync/execution.md`;
decision: **ADR-0010**.

- **Shipped (CloudKit-ready, NOT enabled):** frozen `SchemaV1` snapshot + new
  `SchemaV2` (drop `.unique`, inline defaults, remove `ConsumptionEvent.name`,
  `timestamp` constant default); custom V1→V2 stage backfilling distinct `uuid` +
  `modifiedDate`. `uuid` identity + `modifiedDate` LWW on the models; `touch()` on
  edits; `duplicated()` mints a fresh uuid. `UserProfileStore` (app singleton) +
  `RecordDeduplicator` (launch sweep + insert-time uniqueness). Import = identity
  upsert + LWW (legacy uuid-less → old heuristic); export/import carry
  `uuid`/`modifiedDate` + `DrinkTemplate` (back-compatible). ADR-0010 created;
  domain.md / architecture.md / roadmap updated.
- **Deviations (documented):** profile manual-import = unconditional restore (LWW
  breaks on `.iso8601` second-truncation), not Q5's LWW; live Settings profile
  edits don't yet bump `modifiedDate` (deferred to Phase B). Executed in one Opus
  session (not the parallel multi-session model the plan envisaged).
- **Gates:** app build clean (2 **pre-existing** `UITestSeed` warnings — commit
  5604699, not mine); **490 unit tests pass**; UI tests green (`ExportUITests`
  made deterministic via `-dp_uitest` seed); **coverage 93.67%**; no file >300.
- **Gotcha:** new SwiftData test helpers must retain the `ModelContainer` (return
  it, not just `.mainContext`) or the suite crashes.
- Changes **left in the working tree, not committed**.

**Next:** owner's call — commit Phase A; Phase B (enable CloudKit) is **blocked**
on a provisioned iCloud container (paid account) + explicit one-way approval.
Optional follow-up: bump `modifiedDate` on live Settings edits before Phase B;
clean the 2 pre-existing `UITestSeed` warnings.

---

## Status: plan-0035 COMPLETED — SwiftData versioned-schema migration foundation (2026-06-28)

Delivered the explicit migration **foundation** — infra-only, zero behaviour
change — that was the App-Store blocker and the hard prerequisite for plan-0023
(CloudKit).

- **Shipped:** `SchemaV1` (`VersionedSchema`, `Schema.Version(1,0,0)`, models =
  `[DrinkTemplate, ConsumptionEvent, UserProfile]`, referencing the live `@Model`
  classes); `MigrationPlan` (`SchemaMigrationPlan`, `schemas=[SchemaV1]`,
  `stages=[]`); `MigrationPlan.self` wired into all three container paths —
  `StoreBootstrap.makeContainer` (initial attempt + post-recovery retry) and
  `UITestSeed.makeContainer` (`drinkpulseApp` unchanged, routes through
  `StoreBootstrap`). New tests: `MigrationTests` (on-disk store seeded, reopened
  under `MigrationPlan`, data intact — clean migration open vs the empty store the
  recovery fallback would yield) and `ComprehensiveRoundTripTests` (every current
  field round-trips export→import, plus a nil-optionals case). ADR-0009 created;
  `domain.md` corrected (`ageYears` → `dateOfBirth`).
- **Decisions (owner-approved):** Q1 reference-live-classes + snapshot-on-divergence
  rule; Q2 version 1.0.0; Q3 accept + owner backs up the real device before
  installing (comprehensive round-trip test added as the safeguard); Q4 infra-only
  — all CloudKit-compat shape changes stay in plan-0023 as SchemaV2 + one stage.
- **Gates:** `xcodebuild build` clean (zero new warnings); `xcodebuild test` →
  `** TEST SUCCEEDED **` (all 3 new tests passed); app coverage **94.22%** (≥90%);
  no file introduced/modified exceeds 300 lines.
- Changes **left in the working tree, not committed**.

**Next:** owner's call — plan-0023 CloudKit (now unblocked; needs approval).

---

## Status: Fixed flaky ReminderSettingsUITests (2026-06-27)

`test_reminderToggle_revealsAndHidesTimeRow` failed because the simulator
persisted `dp_reminder_enabled = true` across reinstalls (a prior run's toggle),
so the reminder started ON at launch — not a label collision as earlier assumed
(hierarchy dump showed Switch `value: 1`). Fix: `UITestSeed.resetTransientDefaults()`
(launch-arg-gated, inert in prod) removes the key, called in `drinkpulseApp.init()`.
Both reminder tests pass; toggle test passes twice without uninstall (isolation
proven). Build clean. Committed locally; not pushed. Open-question resolved/removed.

**Remaining pre-existing (not addressed):** GuidelineLimits/InsightsDataGenerator
main-actor test-macro warnings (244 on pristine main).

---

## Status: Domain/ organization pass DONE (2026-06-27)

Same review-then-fix pass on `Domain/` (already well-organized, no file >300).
Owner-approved scope. Split `UserProfile.swift` into `AlcoholUnit` (CALC,
verbatim move — hand-verify) + `BiologicalSex`/`GuidelineChoice`/`UnitSystem`
bare enums + `UserProfile` @Model; split `UnitSystem+Volume` into
`+Volume`/`+ServingLabels`; deleted dead `DataExporter` (+contentSignature,
grep-confirmed no prod caller) and re-pointed its fixture-only tests at
`BackupExport`; extracted `ImportError`/`ImportResult` from `DataImporter`;
documented 3 best-effort `try? fetch` swallows; added `RiskLevelTests` +
`UserProfileTests`. Marked `RiskLevel` `nonisolated` (annotation only) so the
new nonisolated test compiles. Build clean, no new warnings, unit suite green,
new/changed Domain files all 100% covered, no file >300. Committed on `main`,
not pushed.

**Hand-verify:** the `AlcoholUnit` and `UnitSystem` volume-math relocations are
byte-identical moves — confirm no behaviour drift.

**Still pre-existing (not this pass):** GuidelineLimits/InsightsDataGenerator
main-actor test-macro warnings (244 on pristine main); `ReminderSettingsUITests`
toggle test (see open-questions). Both predate the Features+Domain passes.

**Next:** owner's call — plan-0023 (CloudKit) or the SwiftData migration
question; optionally clean up the pre-existing warnings/test above.

---

## Status: Features/ organization pass DONE (2026-06-26)

Reviewed all six `Features/` folders and fixed every splitting/naming/preview
finding. No behaviour change. 3 renames (PeriodPicker→InsightsScopeNavigator,
AppearanceCard→AppearanceModeRow, Tab→AppTab), 4 two-concept splits, 1
pre-emptive VM split (InsightsViewModel→+HealthMetrics), dead `HealthMetricRow`
removed, 12 missing previews added, and AddDrink's density math extracted
**verbatim** into a `nonisolated DrinkMassCalculator` with 12 unit tests
(hand-verify the math). Onboarding guideline-name dedup deliberately skipped
(touches guidelines). Build clean / 0 warnings, unit suite green, coverage
94.04%, no file > 300. **Not committed** — left in the working tree for review.

**Surfaced (not mine):** `ReminderSettingsUITests.test_reminderToggle_*` fails
on pristine `main` too — pre-existing. See open-questions.md.

**Next:** owner's call — review/commit this pass; the pre-existing reminder UI
test; plan-0023 (CloudKit) or the SwiftData migration question.

---

## Status: plan-0016 COMPLETED — log-reminder notifications + Services layer (2026-06-26)

Opt-in daily local notification reminding the user to log drinks, and the
**first `Services/` layer** member.

- **New layer:** `Services/` ([ADR-0008](../../docs/decisions/0008-services-layer.md)).
  `NotificationScheduling` protocol (+ thin `UNUserNotificationCenter` adapter),
  `ReminderService` (`@MainActor`, injected centre; makeRequest/schedule/cancel/
  requestAuthorization/scheduleIfEnabled; id `dp.daily.log.reminder`; default
  21:00; idempotent remove-then-add), `NotificationActionHandler` (delegate →
  pending-flag + event), `UITestNotificationCenter` (launch-arg-gated
  non-prompting stub).
- **UI:** `ReminderSection` glass card in Settings (toggle + conditional time
  `DatePicker`; denied → inline message + Open Settings deep link).
- **Shell:** opens Add Drink on the persisted `dp_pending_add_drink` flag
  (cold launch) + a `NotificationCenter` async-sequence `.task` (running);
  `scheduleIfEnabled()` on launch + scenePhase active.
- **Deviation:** plan said ADR `0005`; created `0008` (next free). Settings is a
  glass-card `ScrollView` now (not a List) — section matches it.
- Build clean (0 warnings); full suite green (+11 ReminderService unit, +2
  Reminder UI). No file > 300. **Not committed yet — left in working tree
  for review** (will commit locally per instructions).

**Next:** owner's call — plan-0023 (CloudKit, draft, needs approval) or the
SwiftData migration open question. AI chat / widget / watch ideas still parked.

---

## Status: plan-0034 COMPLETED — per-event currency + generic name placeholder (2026-06-25)

Two entry-form fixes (owner-requested).

- **Custom name:** one generic placeholder for every category
  ("Optional name for this drink") replaces the hardcoded beer brand
  "e.g. Tyskie IPA". No prefill. Dead `EditCustomNameSection` removed.
- **Currency:** wired end to end. `Domain/Currency.swift` (`nonisolated`
  `CurrencyOption` + `CurrencyCatalog.common`, 12 currencies). New additive
  `ConsumptionEvent.priceCurrency: String?` persisted **with** the price.
  Shared `PriceCurrencySection` (price + `.menu` currency picker) in Add &
  Edit replaces the hardcoded `Text("USD")`; per-event currency seeds from the
  profile currency, overridable, saved only when a price is set. Settings gains
  a currency `.menu` row (Preferences). Export/import + content-signature
  cover `priceCurrency` (back-compatible).
- **Gotcha:** module default actor isolation is MainActor → new Domain value
  types need `nonisolated` (else key paths like `map(\.code)` fail in tests).

Build clean (0 warnings), `** TEST SUCCEEDED **` (full unit suite + 44 UI
tests, +8 Currency unit + 2 Currency UI), no file > 300. **Not committed** —
left in the working tree for review.

**Out of scope (deliberate):** price+currency display in History/Insights;
cross-currency totals; FX conversion; full ISO 4217 list.

**Next:** owner's call — plan-0016 (notifications, draft), plan-0023 (CloudKit,
draft, needs approval), or the SwiftData migration open question.

---

## Status: plan-0033 COMPLETED — remove color themes, fixed Ember accent (2026-06-24)

Dropped the 3-colour theme system (Ember/Forest/Iris) for a **single fixed Ember
accent**, and made tab icons fill only under the Liquid Glass selection.

- **Accent = the `AccentColor` asset** (`#FA5D36`). Single source of truth →
  resolves in the running app, in previews/canvas, and for `Color.accentColor`
  consumers. Deleted `DPTheme` + `DPTheme+Environment`; `DPBrand.dpAccent`
  aliases `Color.accentColor`; dropped redundant explicit `.tint(.dpAccent)`.
- **Tabs:** base symbols (`house`/`chart.bar`/`clock`/`gearshape`) with
  `.environment(\.symbolVariants, selected ? .fill : .none)` per `Tab` label —
  outline normally, filled under the glass "pile".
- **Light/Dark/System mode kept**, but the standalone Appearance card was a
  single-row `dpGlassCard`; an iOS 26 `.menu` morph anchored to the whole card
  and collapsed it. Fixed structurally: moved the mode row into the **multi-row
  Preferences card** (no single-row menu cards remain). Guideline + App Lock
  stay single-row (Button/sheet rows — they don't morph).
- Removed `DPThemeTests` (+ pbxproj refs) and the theme-swatch UI test; the
  `.menu` appearance-mode UI test stays valid. Strings `theme.*`,
  `settings.appearance.theme`, `settings.section.appearance` removed.

Full suite green: **480 unit/UI tests, 0 failures**, app coverage **93.81%**,
no file >300 lines, zero warnings.

**Open follow-up:** orphan `dp_theme` UserDefaults key left in place (harmless
dead key; not a SwiftData concern). One-shot `removeObject` deferred by decision.

**Next up:** owner's call. Candidate threads: plan-0016 (notifications, draft),
plan-0023 (CloudKit sync, draft), or the SwiftData migration open question.

---

## Status: Deployment target raised to iOS 26 (2026-06-23)

Minimum deployment iOS 18 → **iOS 26**. Codebase is now fully native Liquid
Glass with zero backward-compat branches. Whole-project scan found the entire
iOS-version-shim surface to be one file: `DPGlass.swift` (the `#available(iOS 26)`
glass/material fallback) — removed, `glassEffect` is now unconditional.
`IPHONEOS_DEPLOYMENT_TARGET` 18.0 → 26.0 ×6 in `project.pbxproj`. Tab bar already
native (`TabView`/`Tab {}`), no change. Build clean.

**Pre-existing failing test — FIXED.**
`VolumeServingUITests.test_imperialBeerPicker_showsPintServing` was failing (app
opened imperial beer on a 500 ml bottle, not a pint). Owner decision: imperial beer
should default to 1 pint. Added `DrinkTypePreset.regionDefaults` (`[.imperial: 568]`
for beer); `defaultVolumeMl(for:)` honours it; `DrinkDetailInputView.onAppear` seeds
from it. Metric/US unchanged. +2 unit tests; full suite + 9 UI tests green. Only
beer has a region default for now (cider etc. = possible follow-up).

**Possible iOS-26 adoption follow-ups (opt-in, not required):** FAB
`.buttonStyle(.glass)`, `GlassEffectContainer` morphing, `.scrollEdgeEffect`,
`.tabBarMinimizeBehavior`, `Tab(role: .search)`, `.tabViewBottomAccessory`.

**Not committed yet at time of writing.**

---

## Status: plan-0031 COMPLETED — serving expansion + provenance; 0030 closed (2026-06-23)

Both owner gates signed off this session (pint/fraction rule; region-tag policy
reversal), plan frozen, then executed end to end. plan-0030 reopened-then-closed
(its full volume vision is now delivered). **Both plans completed.** INDEX next
number = 0032.

- **Provenance (C′ / ADR-0007).** `ConsumptionEvent.enteredUnit: UnitSystem?`
  (optional, default nil — additive migration). `displayName(in:)`/`baseName(in:)`
  resolve the serving name via `enteredUnit ?? currentUnit`, stable across
  unit-mode switches, never touches grams/calories/risk/BAC. Set at log time,
  never edited. Export/import gain a back-compatible optional `enteredUnit` key.
- **Serving expansion (proposal-2 v3).** Realistic US/imperial/metric inventory
  across all 9 drink groups. `VolumeOption.regionNames` (568 = "Pint"/"Stovepipe"),
  merged-568 model (no duplicate ml per category×unit), M/X tags + cross-borrows.
  Cocktail/fortified/hot-drink split into `DrinkTypePreset+MixedPresets.swift`.
- **New domain rule (`domain.md`).** `servingVolumeLabel` (pint mode for imperial:
  ⅓/½/⅔/1/2 pint; ounces otherwise), `isRoundServing` (whole/half oz OR pint
  fraction), inline ml hint via `Int(ml.rounded())`. Where proposal-2's tables
  conflicted with its stated rule on exact-half-oz measures, the stated rule won
  (documented). **Region-tag policy reversed** and reconciled in `domain.md`.
- **Localization:** serving descriptors stay English literals; new unit/format
  strings localized. **UI tests:** `VolumeServingUITests` (provenance + pint).

Build clean (0 warnings), `** TEST SUCCEEDED **` (9 UI tests), no file > 300.
Coverage on new Domain code 100% (`UnitSystem+Volume`, `ExportRecord`,
`VolumeOption.name/label`, `ConsumptionEvent` logic). **Not committed** — changes
left in the working tree for review.

**Possible polish follow-up:** History subtitle still uses `formatVolume` (fl oz),
so an imperial pint event shows "Pint · 20.0 fl oz" in the subtitle while the name
is "Pint"; switching the subtitle to `servingVolumeLabel` is optional.

**Next:** plan-0023 CloudKit (needs approval); plan-0016 notifications; hardcoded
"USD" price label still ignores `UserProfile.currency`.

---

## Status: plan-0030 CLOSED — UI tests split + seeding guard fixed (2026-06-22)

plan-0030 is fully closed. The volume-unit display feature (unit tests + UI
tests) is done. Key infrastructure added for future UI tests:

- `UITestSeed.swift` — launch-arg-gated in-memory store + deterministic fixture
  seeding. All behaviour gated on `-dp_uitest YES`. Inert in production.
  Seeding skips when `-dp_force_onboarding YES` is set (onboarding creates its own profile).
- `-dp_force_onboarding YES` — one-shot onboarding bypass for locale tests that
  avoids the NSArgumentDomain write-blocking issue.
- Pattern for querying EventRow buttons: `app.buttons.matching(NSPredicate(…))` —
  History cells themselves have empty labels; the combined accessibility label is
  on the Button inside the cell.
- 4 UI test classes now each in their own file in `drinkpulseUITests/` (auto-included
  via `PBXFileSystemSynchronizedRootGroup`).

All 7 UI tests + 421 unit tests green (428 total, confirmed via xcresult). No file > 300 lines.

**Next:** plan-0023 CloudKit (needs approval); plan-0016 notifications; hardcoded
"USD" price label still ignores `UserProfile.currency`.

---

## Status: plan-0030 COMPLETED — volume unit display made live (2026-06-22)

`UserProfile.unitSystem` now drives serving-volume display and which presets are
offered for new drinks (was a dead setting). Volumes render in the user's unit —
whole ml / one-decimal fl oz — via a new pure Domain formatter
`Domain/UnitSystem+Volume.swift` (`formatVolume`, `fluidOunces(fromMl:)`,
`volumeUnitLabel`, ml↔oz constants 29.5735 / 28.4131). `DrinkTypePreset.VolumeOption`
reshaped to `descriptor` + `volumeMl` + `regions: Set<UnitSystem>`; both input
pickers are ml-based now (re-resolve by ml on a unit switch). `volumeMl` stays
canonical — no migration, no export-format change, no calorie/grams/BAC/guideline/
risk math change, `alcoholUnit` untouched.

Highest-risk part (EditEventView): the old nearest-row snap could silently rewrite a
stored volume under a unit-dependent grid (500 → 473 ml). Fixed by seeding the
selection from the exact `event.volumeMl` (injected as an off-region picker option)
and a pure `volumeToPersist(selected:original:)` guard that only writes on a real
change. Regression-pinned.

Open decisions resolved with the plan's defaults: oz = 1 decimal, metric = whole ml;
onboarding default from `Locale.current.measurementSystem` (UK → imperial),
overridable in Settings.

Note: the `drinkpulseTests` target is not file-system-synchronized — new test files
must be added to `project.pbxproj` manually (PBXBuildFile + PBXFileReference + group
+ Sources phase) or they won't run.

Build clean, 417 tests / 20 suites green, formatter 100% covered, no file > 300.
**Not committed/pushed** — changes left in the working tree for review.

**Next:** plan-0023 CloudKit (needs approval); plan-0016 notifications; the
hardcoded "USD" price label still ignores `UserProfile.currency` (open question).

---

## Status: Export success confirmation (2026-06-22)

Manual backup export now confirms success after the file is actually saved
(parity with the import result alert). `ShareLink` gives no completion callback,
so export switched to SwiftUI's `.fileExporter` (pure SwiftUI, no UIKit) backed
by a new `BackupDocument: FileDocument`. `onCompletion` → "Export complete" on
real save, "Export Failed" on error, no-op on `userCancelled`. The JSON encode
lives in `BackupDocument.fileWrapper` (SwiftUI runs it off-main on save), so the
tap is instant — fixes an interim freeze — and full history hits disk only on an
actual save (lazy-write privacy preserved). Behaviour: share sheet → save panel.

Files: `Domain/DataTransfer/BackupDocument.swift` (new), `DataSection.swift`,
`BackupExport.swift` (comment), `Localizable.xcstrings` (4 keys). architecture.md
export section updated. Build clean, suite green, no file > 300.

Verified end-to-end in the iPhone 17 Pro simulator via a new **`drinkpulseUITests`**
target (project's first UI test target) — `ExportUITests` drives Settings → Data →
Export, asserts the save panel presents with the backup filename and Save →
"Export complete" alert, and that dismissal shows no failure alert. Both pass.
Note: the sim's system locale is Polish, so the test is locale-independent (keys
off `DOCPicker.filenameTextField` + the nav-bar trailing button, not labels).

**Next:** plan-0023 CloudKit (needs approval); plan-0016 notifications.

---

## Status: Insights chart polish (2026-06-19)

Two view-only Insights tweaks (no plan — no domain rule touched). Committed +
pushed: `3c672fd` (`c9a9372..3c672fd main`).

**WeekdayBarChart** — Y axis now reads in the user's chosen unit instead of raw
grams. New `InsightsViewModel.displayUnitDivisor` / `displayUnitLabel` (backed by
`AlcoholUnit.gramsPerUnit(for:)`); bars + a11y label divide by the divisor and
show the unit label. Risk colouring still keys off grams, so thresholds are
unchanged. Title→content spacing 8→14.

**AlcoholAreaChart** — reworked to a categorical (band) X scale keyed per point
with `AxisValueLabel(centered: true)`, so every vertex sits directly above its
day label, matching the bar chart. Interpolation switched `.monotone`→`.linear`.
Iterated through a full-width continuous-scale attempt first (see DEVLOG
2026-06-19 12:30) but the endpoints can't be both centered over their labels and
pinned to the edges — user chose point↔label alignment over full width, accepting
a half-band inset each side.

Build clean, 382 tests green, no file > 300 lines.

**Next:** plan-0023 CloudKit (needs approval); plan-0016 notifications.

---

## Status: plan-0029 COMPLETED (2026-06-16)

**plan-0029 DONE** — Alcohol-unit refactor: two display modes + density by mode × guideline.

`AlcoholUnit` collapsed to `grams` + `standardDrinks` (`.units` removed; UK folds into
standard drinks at 8 g/unit, 0.8). Density now depends on **mode AND guideline** via
`AlcoholUnit.density(for:)`: `.grams` → 0.789 always; `.standardDrinks` → 0.789 for
US/CA (mass-defined std drink), 0.8 for WHO/DE/AU/UK/custom (EU/UK convention).
`unitLabel(for:)` is guideline-aware (UK = "units", others = "standard drinks").
Default unit + all `?? .units` fallbacks → `.standardDrinks`. Custom `init(from:)`
decodes persisted/imported `"units"` (and unknown raw) → `.standardDrinks` (lightweight
migration, no store wipe). Gram limits untouched (plan-0028).

Verified targets: std-drinks — EU 500 ml = 2.0, UK = 2.5, US 355 ml = 1.0, CA 341 ml =
1.0, UK weekly = 14.0; grams = 19.7 g all guidelines; calories identical across toggles.
New **ADR-0006** amends frozen ADR-0005. Build clean, tests green (382 @Test), no file
> 300 lines. The ~1.4% offset now applies only to EU/UK; US/CA have none.

Post-merge follow-up (2026-06-16): Add/Edit live-preview rows switched from
`displayName` to `unitLabel(for: guideline)` so UK reads "units" there too (was
showing "Standard drinks"). 30-day limit formula confirmed correct as
`weeklyLimitGrams × 30/7` (DE: 12 std/week → 51.4 std/30d, consistent — keeps the
2 alcohol-free days/week); no change.

**Merged & pushed to `main`** (2026-06-16): merge commit `5beeee3` (no-ff),
pushed `8d336c1..5beeee3`. Branch `plan-0029-alcohol-unit-refactor` deleted (local;
no remote branch existed). plan-0029 closed.

**Next:** plan-0023 CloudKit (needs approval); plan-0016 notifications.

---

## Status: plan-0028 COMPLETED (2026-06-15)

**plan-0028 DONE** — Guideline limits fix (WHO/DE weekly = daily×5) + Australia + Canada.

WHO/DE weekly limits corrected: WHO male 140→100, female 70→50; DE male 168→120, female 84→60.
Both guidelines assume 2 alcohol-free days per week (×5, not ×7). US unchanged (no free days, ×7);
UK unchanged (independent published 112 g value). AU (NHMRC 2020) added: 40 g/day, 100 g/week.
CA (Health Canada LRDG-2011) added: male 40.35/201.75, female 26.9/134.5 g; std drink 13.45 g.
Both AU/CA wired into `gramsPerUnit` (AU=10, CA=13.45 for `.units` and `.standardDrinks`).
367 tests green. GuidelineChoice+Limits 100% covered. Zero warnings. No file > 300 lines.

**User impact note**: existing users on WHO or DE who were within the old (too-lenient) weekly
limit may now show as exceeded — intended correction, not a regression.

**Next:** plan-0023 CloudKit (needs approval); plan-0016 notifications.

---

## Status: plan-0027 COMPLETED (2026-06-15)

**plan-0027 DONE** — Settings Liquid Glass + bug/privacy fixes. Settings was the
only top-level screen on an opaque `List(.insetGrouped)`; rewrote as a
`ScrollView` of `dpGlassCard` sections (`SettingsSection` + `SettingsActionRow`)
over the themed tint, matching Dashboard/Insights. Privacy/perf: export JSON no
longer written to tmp on every Settings appearance — `BackupExport: Transferable`
(`FileRepresentation`) defers encode + temp-write into the share-sheet closure, so
full history only hits disk on actual export. Shared `AppStorageKeys` constants
(`dp_theme`/`dp_color_scheme`/`dp_onboarding_done`). Theme-swatch checkmark dark
scrim for contrast. +5 BackupExport tests; build clean, suite green, no file > 300.

**Next:** nothing pending on this topic. L3 (GuidelinePickerSheet glass) deferred.
Still outstanding from before: hand-correct the four folded events from plan-0025;
plan-0023 CloudKit (needs approval); plan-0016 notifications.

## Status: plan-0026 COMPLETED (2026-06-15)

**plan-0026 DONE** — History event context menu. Long-press a row (list or
calendar day-detail) → **Duplicate** or **Delete**. Duplicate uses
`ConsumptionEvent.duplicated(timestamp: .now)` (copies all fields + template ref,
resets timestamp) and **saves immediately, no edit sheet** — fast re-log, the copy
appears under "Today". Shared `View.eventContextMenu(for:in:)` modifier
(`History/Components/EventContextMenu.swift`) used in both surfaces;
`HistoryCalendarDayDetail` gained `@Environment(\.modelContext)`. `action.duplicate`
added to l10n. 5 new `duplicated_*` tests; full suite green; no file > 300 lines.

**Next:** nothing pending on this topic. Still outstanding from before: hand-correct
the four folded events from plan-0025 (see below); plan-0023 CloudKit (needs
approval); plan-0016 notifications.

## Status: plan-0025 COMPLETED (2026-06-15)

**plan-0025 DONE** — quantity (×N) field + density-by-display-unit, rounding layer
removed. Build clean, full suite green, no file > 300 lines. Details:
`docs/plans/0025-.../execution.md` + `retrospective.md`; rationale in **ADR-0005**.

Highlights: `ConsumptionEvent.quantity` (one log = one event; importer maps
`NumberOfDrinks`); `AlcoholUnit.densityGramsPerMl` (0.789 / 0.8 / 0.789) +
`physicalDensityGramsPerMl` for calories/BAC; aggregation sums mode-mass and
compares to physical-gram limits, so one 500 ml 5% beer = exactly 2.0 units & 100%
of WHO daily (×10 = 1000%); the 2026-06-14 `displayValue`/`displayPct`/
`todayDisplay*`/`trendDisplayFraction` rounding machinery is deleted. UK unit 8.0 g
/ weekly 112; settings label "Standard drinks (US)". `quantity` round-trips through
export (optional decode → 1). CLAUDE.md/domain.md updated.

**Next (USER action):** correct the four already-folded events by hand in-app
(table in `plan.md` / `execution.md`) — grams unchanged, only label/count/per-portion
volume. After that, no open work on this topic.

Env note: run `xcodebuild test` with the **default** DerivedData — `-derivedDataPath
build/` inside this iCloud-synced repo fails CodeSign (`com.apple.FinderInfo`
detritus on the `.xctest`).

## Status: plan-0025 FROZEN, awaiting execution in a new session (2026-06-14)

**plan-0025** (quantity ×N field + density-by-display-unit + drop unit rounding)
is **frozen / in-progress** and will be executed in a **fresh Opus 4.8 session**.
The plan is a self-contained handoff — start there:
`docs/plans/0025-quantity-field-and-density-by-unit/plan.md`.

Key decisions (all user hand-verified): density keyed to `AlcoholUnit` —
`.grams`/`.standardDrinks` → 0.789, `.units` (UK) → 0.8; UK unit 8 g / weekly
112 g; "Standard drinks (US)" label; calories always 0.789; `quantity` becomes a
persisted field (`volumeMl` reverts to single-portion); the old display rounding
machinery (`displayValue`/`displayPct`) is deleted — this **supersedes the
2026-06-14 hero/overview rounding edits still in the working tree** (they get
reverted during execution). `DrinkControlImporter` folded `NumberOfDrinks` into
volume — fixed here.

**Data correction = option (b)** (no wipe): after execution, 4 already-folded
events are fixed by hand in-app — see the plan's "Manual fixes after execution"
table (2026-01-10 shot, two 2026-01-17 beers, 2026-01-24 beer).

**Next**: execute plan-0025 step by step in the new session; update its
`execution.md` (append-only), then living docs + CLAUDE.md/domain.md/ADR.

## Status: Dashboard % consistent with units (2026-06-14)

Bugfix: the Overview and week chart showed a percentage computed from raw grams
(e.g. 98% at "2.0 / 2.0 units"). The hero arc was already fixed (`todayDisplayPct`),
the rest was not. Added reusable `DashboardViewModel.displayPct(consumedGrams:limitGrams:)`
and `displayRiskLevel(...)` (computed from the rounded `displayValue`), used in `IntakePeriodRow`
(badge/color/bar/over-limit) and `ThisWeekCard` (color + % label). Raw
`todayPct`/`weeklyPct` (badge/alert) and the domain (gramsPerUnit, limits, risk thresholds)
untouched. 336 tests green. (Superseded by plan-0025, which removes this rounding
machinery.) **Next**: nothing on this topic.

## Status: Insights — All Time, weekday window, heatmap removed, perf (2026-06-09)

Added an **All Time** scope to Insights (4th segment: Week / Month / Year /
All Time). All-time range = oldest event → now; nav arrows disabled, no NOW
pill, hero shows total only (no "vs previous"/trend). **Weekday patterns** now
always derive from the *selected* window (end clamped to `now`) instead of a
fixed 90-day window — this also fixed the earlier all-zero weekday chart on the
yearly scope. **Activity heatmap removed** entirely (component, VM extension,
tests, localization).

**Perf**: `gramsForDay` was O(events) and called once per day across many
aggregates → O(days × events), recomputed on every access; Year (365 days) was
slower than All Time (~160 days for current data). Fixed with a memoized
`gramsByDay: [Date: Double]` (rebuilt on `events.didSet`, O(1) lookup). Also
added `effectiveDateRange`: Year/All Time clamp day-iteration to `now` (current
year reads Jan 1 → today, no empty future months); Week/Month keep their full
grid. Split formatting into `InsightsViewModel+Formatting.swift` (300-line
ceiling). 328 tests green. Living docs updated (product/architecture/roadmap).

**Next**: nothing pending here. Possible follow-up: area-chart x-axis density
for very long all-time histories.

## Status: plan-0024 COMPLETED (2026-06-06)

**plan-0024 DONE** — Domain audit bug fixes. Two silent bugs:
(1) `contentSignature` hashed deprecated `name` and missed `customName`/
`category`/`icon`, so editing those left the auto-backup stale; (2) custom
guideline daily limit resolved to 0 in the History calendar (Dashboard/Insights
handled it, History didn't), losing risk shading — reachable via importing a
custom-guideline profile. Fixed by consolidating into
`GuidelineChoice.effectiveLimits(weeklyGoalGrams:for:)` +
`GuidelineLimits.effectiveDailyGrams`, routed through all three views. Also fixed
stale UK-weekly value in domain.md (112 → 110.46). 319 tests green.

## Status: bugfix session completed (2026-06-04)

**Done today**:
- ABV picker precision bug fixed — value-based state (`abvValue: Double`) replaces
  index-based (`abvIndex: Int`) in both `DrinkDetailInputView` and `EditEventView`.
  Events saved at 0.1 % step (e.g. 2.9 %) now load correctly in the edit picker.
- `DrinkCategory` expanded to 17 cases; pressets split into two files.
- All presets share universal ABV range 0.5 %–100 %; type-specific hard bounds removed.
- `InsightsPeriod` nav: dynamic `minAllowedOffset` from actual oldest event replaces
  hardcoded limits.

**plan-0023 (draft)** — CloudKit sync. Models are NOT CloudKit-compatible:
`UserProfile.@Attribute(.unique)` is unsupported, and all three @Model types
have non-optional properties without defaults. Plan covers schema-compat
refactor + migration + entitlements + conflict strategy. Depends on 0022.
**Outward-facing / one-way — needs explicit approval before implementing.**

## Status: plan-0022 COMPLETED (2026-06-03)

**plan-0022 DONE** — Store-wipe safeguard & backup integrity.
All 6 steps shipped: `StoreBootstrap` non-destructive recovery; export bundle
v2 + `ProfileRecord`; content-signature-based regen; typed import errors surfaced
to UI; `DataSection` `deleteAllData` also clears `RecoveredStores/`; 288 tests
green (up from 268). Prerequisite for plan-0023 (CloudKit) is now clear.

## Status: plan-0021 completed (2026-06-01)

**plan-0021 done**: Edit screen (`EditEventView`) — delete a drink (red trash in the toolbar
+ confirmationDialog) and a tappable type field (NavigationLink → `EditDrinkTypeSelectionView`)
instead of the inline Picker. Extracted a shared `DrinkTypeGrid(selected:onSelect:)` used
by Add and Edit. History list: `.onDelete` → per-row `.swipeActions` (fixes janky swipe +
mismatched height of the red button). 268 tests green, build with no warnings.

## Next session candidates

1. **plan-0023** — CloudKit sync. Models need compatibility fixes (`UserProfile.@Attribute(.unique)` unsupported; non-optional fields without defaults). Needs explicit approval before implementing.
2. **plan-0016** — Log-reminder local notifications.
3. **Install on device** — test the new backup v2, recovery, and "Delete All Data" (clears RecoveredStores).
4. **customName/import** — DONE (2026-06-04). `displayName` now derives from volume+category preset lookup. Importer no longer sets `customName`. `name` field deprecated, removal deferred to plan-0023.

## Open items

- SwiftData migration plan required before App Store submission.
- Guideline alert card tap action still deferred (see open-questions.md).
