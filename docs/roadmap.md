# Roadmap

Status key: ✅ Done · 🔄 In progress · 🗓 Planned · 💡 Idea

---

## Foundation

- ✅ SwiftData domain models (DrinkTemplate, ConsumptionEvent, UserProfile)
- ✅ **Test coverage ≥90%** — 121 tests; Domain 100%, ViewModels ≥90% ([plan-0017](plans/0017-test-coverage-90/))
- ✅ **UI test coverage — every user-facing feature** — 41 XCUITests across Shell,
  Dashboard, AddDrink, History, Insights, Onboarding, Settings; one gated synthetic
  multi-day seed fixture, zero production behaviour change ([plan-0032](plans/0032-ui-test-coverage-completion/))
- ✅ Root TabView with Home / History / Settings tabs
- ✅ Add Drink flow v2: category grid + drum-roll pickers (volume / ABV / count)
- ✅ Alcohol units live readout
- ✅ Optional price field on ConsumptionEvent
- ✅ Currency: Settings preference + per-event override, saved with the price (plan-0034)
- ✅ Custom-name field: single generic placeholder for all categories (plan-0034)
- ✅ docs/ and .claude/context/ documentation structure
- ✅ History screen: list of ConsumptionEvents grouped by day, swipe-to-delete
- ✅ Localization string catalog (en + de + pl) — dot-notation
- ✅ Dashboard: consumption overview — Today / 7-day / 30-day progress bars vs guideline
- ✅ Settings screen: sex, age, guideline choice, volume unit, ABV precision
- ✅ Alcohol display unit preference (grams / standard drinks; UK reads "units") —
  collapsed to two modes in [plan-0029](plans/0029-alcohol-unit-refactor-density-by-mode-and-guideline/)
- ✅ Sex-aware guideline limits (WHO / DE / UK / US / AU / CA differentiated by biological sex)
  — WHO/DE weekly corrected to daily×5 (2 alcohol-free days); AU (NHMRC 2020) and CA
  (Health Canada LRDG-2011) added ([plan-0028](plans/0028-guideline-limits-fix-and-au-ca/))
- ✅ Volume→mass density depends on the display **mode AND guideline** (`.grams` →
  0.789 always; `.standardDrinks` → 0.789 for US/CA, 0.8 for WHO/DE/AU/UK/custom);
  physical mass (calories/BAC) always 0.789
  ([plan-0029](plans/0029-alcohol-unit-refactor-density-by-mode-and-guideline/), ADR-0006
  amending [plan-0025](plans/0025-quantity-field-and-density-by-unit/) / ADR-0005)
- ✅ Edit existing ConsumptionEvent
- ✅ **Delete all data** — destructive action in Settings → Data; wipes all drink logs
  and templates, resets UserProfile to defaults; confirmation alert required

## Short-term

- ✅ Biometric app lock (Face ID / Touch ID + device passcode fallback, lock-on-background)
- ✅ **Volume unit display wiring** — `UserProfile.unitSystem` now drives serving
  display (whole ml / one-decimal fl oz) and region-native presets for new drinks;
  ml↔oz constants + rounding policy are domain rules; onboarding default from
  device locale. `volumeMl` stays canonical (no migration, no math change)
  ([plan-0030](plans/0030-volume-unit-display/))
- ✅ **Volume serving expansion + provenance (C′)** — realistic US/imperial/metric
  serving inventory (per-region names, pint/fraction display, inline ml hint,
  cross-borrows) + `ConsumptionEvent.enteredUnit` so a logged drink's serving name
  is stable across unit-mode switches. Additive migration, no math change
  ([plan-0031](plans/0031-volume-serving-expansion-and-provenance/) · ADR-0007)
- 🗓 Accessibility audit (VoiceOver, Dynamic Type AX5)
- 🗓 Custom drink templates (user-created DrinkTemplate)
- ✅ **Risk language rename** — "Safe / Caution / Exceeded" → "Low / Moderate / High Risk"
  ([plan-0015](plans/0015-risk-language-rename/))
- ✅ **First-launch onboarding** — welcome / optional profile / guideline; each step
  skippable; `@AppStorage` persistence; `dateOfBirth` replaces stored `ageYears`
  ([plan-0009](plans/0009-onboarding-flow/))
- ✅ **Edit entry: custom name + notes + category change**
  (`ConsumptionEvent.customName / notes` lightweight migration)
  ([plan-0014](plans/0014-edit-entry-notes-and-category/))
- ✅ **Edit screen: delete + tappable type picker; list swipe-to-delete fix**
  — toolbar trash w/ confirmation, category row pushes shared `DrinkTypeGrid`,
  list rows use `.swipeActions` (fixes janky/mismatched delete)
  ([plan-0021](plans/0021-edit-screen-delete-typepicker-swipe-fix/))
- ✅ **History event context menu: Duplicate + Delete** — long-press a list or
  calendar-detail row; Duplicate copies every field with `timestamp = .now` and
  saves immediately (no edit sheet) ([plan-0026](plans/0026-history-event-context-menu/))
- ✅ **Log-reminder local notifications** — opt-in daily nudge with time picker;
  off by default, `UNUserNotificationCenter` auth on enable, single repeating
  request, tap opens Add Drink. Introduces the `Services/` layer
  ([ADR-0008](decisions/0008-services-layer.md), `ReminderService`)
  ([plan-0016](plans/0016-log-reminder-notifications/))

## Medium-term (design handoff — Claude Design 2026-05-19)

- ✅ **Design system: Liquid Glass primitives** — `dpGlassCard`, `dpArcProgress`,
  `dpLargeTitle`, semantic risk colours; pilot on Settings
  ([plan-0007](plans/0007-design-system-liquid-glass/))
- ✅ **Theme palettes** — Ember / Forest / Iris with light/dark/system mode;
  root `.tint()` propagation; Settings Appearance section
  ([plan-0008](plans/0008-theme-palettes-ember-forest-iris/))
  → **superseded by [plan-0033](plans/0033-remove-color-themes-fixed-accent/)**:
  multi-theme palettes removed; single fixed Ember accent via the `AccentColor`
  asset. Light/Dark/System mode kept, folded into the Preferences card.
- ✅ **Floating tab bar with FAB** — glass capsule pill (iOS 26 `glassEffect`) +
  detached 64pt gradient FAB; replaces toolbar `+` buttons
  ([plan-0010](plans/0010-floating-tab-bar-fab/))
- ✅ **Native iOS 26 shell redesign** — reverted to standard native tab bar;
  gradient circle "+" in nav bar (all tabs); theme-tinted background;
  `glassEffect` on all dashboard + AddDrink cards; Settings converted to
  `List + insetGrouped` (eliminates dark/light flash); `GuidelineStep` insetGrouped
  ([plan-0018](plans/0018-native-ios26-shell-redesign/))
- ✅ **Dashboard arc-progress hero + chip row** — collapse 2×2 metric grid to two chips,
  promote arc gauge as hero, risk-based arc colour, zero-state streak copy, equal-height
  streak cards ([plan-0011](plans/0011-dashboard-arc-hero/))
- ✅ **Insights screen** — area chart, weekday bars (over the selected window),
  health metrics (binge, risk, calories, spend), guideline comparison (WHO / NHS / DHS),
  scope selector Week / Month / Year / All Time
  ([plan-0012](plans/0012-insights-screen/)); activity heatmap removed 2026-06-09
- 🗓 **History calendar view** — clickable days with inline detail panel, month nav
  ([plan-0013](plans/0013-history-calendar-clickable-days/))

## Medium-term (data + sync)

- 🗓 iCloud sync via SwiftData CloudKit integration
  (multi-device + backup; conflict resolution strategy TBD)
- 🗓 Apple Health write-back (HKQuantityTypeIdentifierDietaryAlcohol, grams)
  — deduplication via stored HealthKit UUID on ConsumptionEvent;
    edits/deletes in app reflected in Health
- 🗓 BAC estimate (Widmark — needs design approval before implementation)
- 🗓 Widget / Lock Screen widget (today's units)

## Future / Ideas

- 💡 Apple Watch quick-log (iOS app extension, not standalone watchOS) —
  today summary + log drink glance (scope confirmed by owner 2026-05-19)
- 💡 **AI natural-language chat** — user writes "I had a Tyskie and a glass
  of wine at 9pm" → parser maps to drinks; informs `customName`/category
  on `ConsumptionEvent` (depends on [plan-0014](plans/0014-edit-entry-notes-and-category/))
- 💡 **PDF export of Insights** — print-styled monthly summary suitable for
  sharing or saving offline (depends on [plan-0012](plans/0012-insights-screen/))
- 💡 Weekly summary notification
- 💡 Spending tracker (monthly price totals — already shown in Insights mockup;
  this idea is for a dedicated Spend screen)
- ✅ **File export / import + DrinkControl migration** — JSON round-trip backup;
  DrinkControl CSV importer (semicolon format, real format confirmed from export file)
  ([plan-0019](plans/0019-export-import/))
- ✅ **Store-wipe safeguard + backup integrity** — non-destructive recovery
  (`StoreBootstrap` moves store aside instead of deleting); export bundle v2
  (adds `UserProfile`); content-based regen (catches edits, not just count
  changes); typed import errors surfaced to UI
  ([plan-0022](plans/0022-store-wipe-safeguard-and-backup-integrity/))
- ✅ **Quantity (×N) field + density-by-display-unit** — `ConsumptionEvent.quantity`
  (one log = one event, "Bottle · 500 ml ×10"); importer maps `NumberOfDrinks`;
  display density per unit so the unit math is exact (removed the rounding layer);
  UK unit 8.0 g / weekly 112 ([plan-0025](plans/0025-quantity-field-and-density-by-unit/))
- ✅ **Settings: Liquid Glass alignment + bug/privacy fixes** — Settings now
  uses `ScrollView` + `dpGlassCard` sections (was opaque `.insetGrouped`); lazy
  `BackupExport` so export JSON never hits disk until shared; shared
  `AppStorageKeys`; theme-swatch contrast fix
  ([plan-0027](plans/0027-settings-liquid-glass-and-fixes/))
- ✅ **Remove color themes → fixed Ember accent** — deleted the Ember/Forest/Iris
  picker + `DPTheme`; single brand accent via the `AccentColor` asset (drives
  controls + previews); tab icons outline-by-default, `.fill` under the Liquid
  Glass selection (`symbolVariants`); Light/Dark/System mode moved into the
  multi-row Preferences card (dodges an iOS 26 single-row glass menu-morph)
  ([plan-0033](plans/0033-remove-color-themes-fixed-accent/))
- 💡 iPad layout (NavigationSplitView)

## iOS 26+ (deployment target raised 2026-06-23)

Minimum deployment target now **iOS 26** — fully native Liquid Glass, no
backward-compat paths. The only iOS-version shim in the codebase (the
`#available(iOS 26)` fallback in `DPGlass.swift`) was removed; `glassEffect`
is now unconditional. Adoption data at decision time: 66% iOS 26 · 24% iOS 18 ·
10% Earlier.

### iOS 18+ (deployment target raised 2026-05-18)

Minimum deployment target bumped to iOS 18 before first public release.
Adoption data at decision time: 66% iOS 26 · 24% iOS 18 · 10% Earlier.

- ✅ **Biometric lock → system settings deep link** — removed in-app toggle;
  Privacy & Security section now opens Settings → DrinkPulse → Require Face ID
  via `UIApplication.openSettingsURLString`. No migration needed (app not yet
  published at time of change).
- ✅ **New `TabView` with `Tab {}` syntax** — restored in `ContentView`; was
  reverted in plan-0002 when target was lowered to iOS 17.
- 💡 **SwiftData compound indexes** — add `#Index` macro on `ConsumptionEvent`
  for `(timestamp, category)`. Improves query performance as event log grows.
- 💡 **SwiftData History API** — use `HistoryDescriptor` for iCloud sync
  conflict resolution (replaces default last-write-wins). Evaluate together
  with the iCloud sync plan.
- 💡 **Dynamic `@Query` predicates** — sort/filter as `@State` without
  rebuilding views. Unlocks history filtering by category or date range.
