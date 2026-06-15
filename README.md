# DrinkPulse

A personal alcohol-consumption tracker for iPhone. Log what you drink, see how your intake compares against established health guidelines, and review your history over time. Everything runs on-device — no account, no sign-up, no data sent to any server.

**Status:** Early development. Core screens are functional; not yet released on the App Store.
**Minimum deployment:** iOS 18

---

## Features

### Add Drink
- Category grid (beer, wine, champagne, spirits, cocktail, cider, custom)
- Drum-roll pickers for volume, ABV, and quantity with live alcohol readout
- Optional price field per entry
- ABV precision configurable (0.5 % or 0.1 % steps)

### Dashboard
- Time-based greeting with risk badge (safe / caution / exceeded)
- Today metrics: alcohol grams/units, calories, drink count, optional spend
- Consumption overview: Today / 7-day / 30-day progress bars vs guideline limit
- This Week bar chart with per-day colour coding and daily-% annotations
- Sober streak and sober-days-this-month cards
- Guideline alert card when weekly limit is exceeded

### History
- Consumption events grouped by day, newest first
- Swipe to delete; tap to edit any entry

### Settings
- Biological sex, date of birth
- Guideline choice: WHO, UK NHS, US NIAAA, German DHS, or custom weekly goal
- Volume unit: ml, US fl oz, Imperial fl oz
- Alcohol display unit: grams, UK units, standard drinks
- ABV picker precision
- Data: export all data (JSON), import DrinkPulse backup, import from DrinkControl, delete all data

### Guidelines & calculations
- Sex-aware limits for WHO, DE, UK, and US guidelines
- Pure alcohol in grams is the unit of truth; all other measures are derived
- Volume→mass density depends on the display unit (grams / US standard drinks →
  0.789 g/ml scientific; UK units → 0.8 g/ml); calories and BAC always use 0.789
  (see ADR-0005)
- Localised for English, German, and Polish

---

## Tech stack

| Layer | Technology |
|-------|-----------|
| UI | SwiftUI (no UIKit) |
| State | `@Observable` macro (Observation framework) |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Concurrency | Swift 6 strict concurrency, `@MainActor` throughout |
| Sync | CloudKit via SwiftData *(planned)* |

No third-party dependencies.

---

## Architecture

MVVM with `@Observable @MainActor` view models. Domain types live in `Domain/`; shared UI tokens in `DesignSystem/`. One feature folder per screen under `Features/`; larger views extract sub-views into a `Components/` subfolder.

```
drinkpulse/
├── drinkpulse/
│   ├── Domain/                  # SwiftData models, calculations, guideline engine
│   ├── DesignSystem/            # Colour tokens, shared components
│   ├── Features/
│   │   ├── Shell/               # RootShellView — tab bar, UserProfile guard
│   │   ├── AddDrink/            # Category grid + drum-roll pickers
│   │   ├── Dashboard/
│   │   │   ├── Components/      # MetricCard, ConsumptionOverviewCard, ThisWeekCard, …
│   │   │   ├── DashboardView.swift
│   │   │   └── DashboardViewModel.swift
│   │   ├── History/             # Event list, edit sheet
│   │   └── Settings/            # UserProfile form, data export/import/delete
│   └── drinkpulseApp.swift      # App entry point, ModelContainer setup, onboarding gate
├── drinkpulse.xcodeproj/
├── drinkpulseTests/             # 248 unit tests (domain logic, view-model calculations)
├── docs/                        # Architecture, domain rules, roadmap, dev log, ADRs
└── CLAUDE.md                    # Project conventions for AI-assisted development
```

---

## Documentation

| File | Contents |
|------|----------|
| [docs/product.md](docs/product.md) | Vision, privacy stance, user stories |
| [docs/architecture.md](docs/architecture.md) | MVVM pattern, navigation, DI, concurrency |
| [docs/domain.md](docs/domain.md) | Calculation formulas, guideline thresholds, unit conventions |
| [docs/roadmap.md](docs/roadmap.md) | Done, planned, and future ideas |
| [docs/decisions/](docs/decisions/) | Architecture Decision Records |
| [docs/DEVLOG.md](docs/DEVLOG.md) | Chronological development log |

---

## Development

Requires **Xcode 16 or later** and macOS Sequoia.

```bash
# Build
xcodebuild -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build

# Test
xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

No `pod install` or `swift package resolve` step required.

---

## License

TBD.
