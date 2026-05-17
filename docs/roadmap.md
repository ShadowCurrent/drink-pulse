# Roadmap

Status key: ✅ Done · 🔄 In progress · 🗓 Planned · 💡 Idea

---

## Foundation

- ✅ SwiftData domain models (DrinkTemplate, ConsumptionEvent, UserProfile, GuidelineProfile)
- ✅ Root TabView with Home / History / Settings tabs
- ✅ Add Drink flow v2: category grid + drum-roll pickers (volume / ABV / count)
- ✅ Alcohol units live readout
- ✅ Optional price field on ConsumptionEvent
- ✅ docs/ and .claude/context/ documentation structure

## Next up

- ✅ History screen: list of ConsumptionEvents grouped by day, swipe-to-delete
- ✅ Localization string catalog (en + de + pl) — 20 keys, dot-notation
- ✅ Dashboard: intake rings for today / 7 days / 30 days vs guideline
- ✅ Settings screen: sex, age, guideline choice, volume unit, ABV precision
- ✅ Alcohol display unit preference (grams / regional units / standard drinks)
- ✅ Dashboard overflow rings (> 100% shown as second arc)
- ✅ Sex-aware guideline limits (WHO / DE / UK / US differentiated by biological sex)
- ✅ Alcohol density corrected to 0.8 g/ml (BZgA convention)
- ✅ Edit existing ConsumptionEvent

## Short-term

- 🗓 Accessibility audit (VoiceOver, Dynamic Type AX5)
- 🗓 Custom drink templates (user-created DrinkTemplate)
- 🗓 Volume unit display wiring (History rows, AddDrink picker labels)

## Medium-term

- 🗓 BAC estimate (Widmark — needs design approval before implementation)
- 🗓 Swift Charts: weekly trend, daily breakdown
- 🗓 Widget / Lock Screen widget (today's units)

## Future / Ideas

- 💡 Apple Watch quick-log complication
- 💡 Weekly summary notification
- 💡 Spending tracker (monthly price totals)
- 💡 Export data (CSV / JSON)
- 💡 iPad layout (NavigationSplitView)
