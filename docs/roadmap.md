# Roadmap

Status key: ✅ Done · 🔄 In progress · 🗓 Planned · 💡 Idea

---

## Foundation

- ✅ SwiftData domain models (DrinkTemplate, ConsumptionEvent, UserProfile)
- ✅ Root TabView with Home / History / Settings tabs
- ✅ Add Drink flow v2: category grid + drum-roll pickers (volume / ABV / count)
- ✅ Alcohol units live readout
- ✅ Optional price field on ConsumptionEvent
- ✅ docs/ and .claude/context/ documentation structure
- ✅ History screen: list of ConsumptionEvents grouped by day, swipe-to-delete
- ✅ Localization string catalog (en + de + pl) — dot-notation
- ✅ Dashboard: consumption overview — Today / 7-day / 30-day progress bars vs guideline
- ✅ Settings screen: sex, age, guideline choice, volume unit, ABV precision
- ✅ Alcohol display unit preference (grams / regional units / standard drinks)
- ✅ Sex-aware guideline limits (WHO / DE / UK / US differentiated by biological sex)
- ✅ Alcohol density corrected to 0.8 g/ml (BZgA convention)
- ✅ Edit existing ConsumptionEvent

## Short-term

- ✅ Biometric app lock (Face ID / Touch ID + device passcode fallback, lock-on-background)
- 🗓 Volume unit display wiring (History rows, AddDrink picker labels)
- 🗓 Accessibility audit (VoiceOver, Dynamic Type AX5)
- 🗓 Custom drink templates (user-created DrinkTemplate)
- ✅ **Risk language rename** — "Safe / Caution / Exceeded" → "Low / Moderate / High Risk"
  ([plan-0015](plans/0015-risk-language-rename/))
- 🔄 **First-launch onboarding** — welcome / optional profile / guideline; each step
  skippable; `@AppStorage` persistence
  ([plan-0009](plans/0009-onboarding-flow/))
- 🗓 **Edit entry: custom name + notes + category change**
  (`ConsumptionEvent.customName / notes` lightweight migration)
  ([plan-0014](plans/0014-edit-entry-notes-and-category/))
- 🗓 **Log-reminder local notifications** — opt-in daily nudge with time picker
  ([plan-0016](plans/0016-log-reminder-notifications/))

## Medium-term (design handoff — Claude Design 2026-05-19)

- 🗓 **Design system: Liquid Glass primitives** — `dpGlassCard`, `dpArcProgress`,
  `dpLargeTitle`, semantic risk colours; pilot on Settings
  ([plan-0007](plans/0007-design-system-liquid-glass/))
- 🗓 **Theme palettes** — Ember / Forest / Iris with light/dark/system mode
  ([plan-0008](plans/0008-theme-palettes-ember-forest-iris/))
- 🗓 **Floating tab bar with FAB** — Home / Insights / History / Settings + Add-Drink FAB;
  replaces toolbar `+` buttons
  ([plan-0010](plans/0010-floating-tab-bar-fab/))
- 🗓 **Dashboard arc-progress hero + chip row** — collapse 2×2 metric grid to two chips,
  promote arc gauge as hero, zero-state streak copy
  ([plan-0011](plans/0011-dashboard-arc-hero/))
- 🗓 **Insights screen** — area chart, weekday bars, activity heatmap, health metrics,
  guideline comparison (Swift Charts)
  ([plan-0012](plans/0012-insights-screen/))
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
- 💡 Export data (CSV / JSON)
- 💡 iPad layout (NavigationSplitView)

## iOS 18+ (deployment target raised 2026-05-18)

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
