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
- 🗓 History: calendar view — month grid with per-day colour coding
  (green / orange / red relative to daily guideline; days with no data neutral)
- 🗓 Custom drink templates (user-created DrinkTemplate)

## Medium-term

- 🗓 iCloud sync via SwiftData CloudKit integration
  (multi-device + backup; conflict resolution strategy TBD)
- 🗓 Apple Health write-back (HKQuantityTypeIdentifierDietaryAlcohol, grams)
  — deduplication via stored HealthKit UUID on ConsumptionEvent;
    edits/deletes in app reflected in Health
- 🗓 BAC estimate (Widmark — needs design approval before implementation)
- 🗓 Swift Charts: monthly trend, more advanced breakdown charts
- 🗓 Widget / Lock Screen widget (today's units)

## Future / Ideas

- 💡 Apple Watch quick-log (iOS app extension, not standalone watchOS)
- 💡 Weekly summary notification
- 💡 Spending tracker (monthly price totals)
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
