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

## Conditional on dropping iOS 17

These items only make sense if the deployment target is raised to iOS 18+.

As of 2026-05-18, general App Store device data: 66% iOS 26 · 24% iOS 18 · 10% Earlier
("Earlier" covers iOS 17 and below combined — iOS 17-only share is a fraction of that 10%).
Bumping to iOS 18 minimum is defensible now, especially before first public release.
After publishing: verify against own App Store Connect analytics before acting.

- 💡 **Biometric lock migration** — remove the in-app lock toggle; show a
  one-time migration alert for users who had it enabled, directing them to
  Settings → DrinkPulse → Require Face ID (iOS 18 system-level app lock).
  Intermediate version should add a footer note informing iOS 18+ users of
  the system alternative first.
  Implementation: `UserDefaults` flag `didShowLockMigrationAlert`;
  `UIApplication.openSettingsURLString` for the deep link.

- 💡 **SwiftData compound indexes** — add `#Index` macro on `ConsumptionEvent`
  for `(timestamp, category)`. Improves query performance in History and
  Dashboard as the event log grows.

- 💡 **SwiftData History API** — use `HistoryDescriptor` to track model
  changes over time. Enables proper conflict resolution for iCloud sync
  (replaces default last-write-wins). Should be evaluated together with the
  iCloud sync plan.

- 💡 **Dynamic `@Query` predicates** — sort and filter descriptors as
  `@State`, without rebuilding views. Unlocks user-facing history filtering
  by category or date range cleanly.

- 💡 **New `TabView` with `Tab {}` syntax** — cleaner `ContentView`; was
  reverted when deployment target was lowered to iOS 17. Pure code quality
  improvement, no user-facing change.
