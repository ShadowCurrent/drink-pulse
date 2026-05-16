# DrinkPulse

DrinkPulse is a personal alcohol-consumption tracker for iPhone. It lets you log what you drink, see how your intake compares against established health guidelines (WHO, UK NHS, US NIAAA, German DHS), and review your history over time. Everything runs on-device — there is no account, no sign-up, and no data sent to any server. iCloud sync is available as an opt-in convenience through the user's own Apple ID, not through any infrastructure we control.

## Status

Early development. The core logging flow is functional; history, dashboard, and settings screens are not yet built. Not yet released on the App Store.

Minimum deployment target: **iOS 26**.

## Features

- Log a drink in two steps: choose a category (beer, wine, champagne, spirits, cocktail, cider, or custom), then dial in volume, ABV, and quantity using drum-roll pickers
- Seven built-in drink categories with sensible volume and ABV defaults per type
- Optional price field per entry
- Live alcohol-units readout as you adjust the serving
- On-device SwiftData persistence; no network required

**Planned (not yet built):** consumption history grouped by day, dashboard with weekly progress against a guideline, settings screen (body weight, guideline choice, currency, ABV picker precision), BAC estimate, Swift Charts trend views.

## Tech stack

- **SwiftUI** — all UI; no UIKit
- **SwiftData** — on-device persistence with declarative schema migrations
- **CloudKit** — optional cross-device sync via SwiftData's built-in integration
- **Swift Charts** — planned for trend visualisations
- **Swift 6** — strict concurrency enabled throughout; no Objective-C bridging

No third-party dependencies.

## Architecture

MVVM with a repository layer separating view models from SwiftData. Views hold only presentation state; repositories own the `ModelContext` and are injected via SwiftUI environment values. All view models are `@Observable` and `@MainActor`-isolated.

See [docs/architecture.md](docs/architecture.md) for the full breakdown, including navigation patterns, DI approach, and concurrency strategy.

## Project structure

```
drinkpulse/
├── drinkpulse/              # Xcode project source root
│   ├── Domain/              # SwiftData models (DrinkTemplate, ConsumptionEvent, UserProfile, GuidelineProfile)
│   ├── Features/            # One folder per feature: AddDrink, Dashboard, History, Settings
│   ├── ContentView.swift    # Root TabView coordinator
│   └── drinkpulseApp.swift  # App entry point and ModelContainer setup
├── drinkpulse.xcodeproj/    # Xcode project file
├── docs/                    # Project documentation and ADRs
└── .claude/                 # Claude Code project configuration
```

## Documentation

| File | Contents |
|------|----------|
| [docs/product.md](docs/product.md) | Vision, privacy stance, user stories |
| [docs/architecture.md](docs/architecture.md) | MVVM+repository pattern, navigation, DI, concurrency |
| [docs/domain.md](docs/domain.md) | ABV convention, calculation formulas, entity descriptions, guideline thresholds |
| [docs/roadmap.md](docs/roadmap.md) | What is done, what is next, longer-term ideas |
| [docs/decisions/](docs/decisions/) | Architecture Decision Records (ADRs) |
| [docs/DEVLOG.md](docs/DEVLOG.md) | Chronological development log |

## Development

Requires **Xcode 26 or later**.

```bash
# Build
xcodebuild -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  build

# Test
xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

There are no third-party dependencies; no `pod install` or `swift package resolve` step is needed.

## License

TBD.
