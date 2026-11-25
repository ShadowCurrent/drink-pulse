# DrinkPulse

A personal alcohol-consumption tracker for iPhone. Log what you drink, see how your intake compares against established health guidelines, and review your history over time. Everything runs on-device — no account, no sign-up, no data sent to any server.

**Status:** Early development. Core screens are functional; not yet released on the App Store.
**Minimum deployment:** iOS 27.0

---

## Features

### Add Drink
- Drink-type list in family sections (Beer & Cider, Wine, Spirits, Mixed & Other) with search
  and up to three Recent drinks that reopen with their serving
- Drum-roll pickers for volume, ABV, and quantity with a live Pure Alcohol readout
- Optional price field per entry, with a per-drink currency override (saved with the price)
- Optional custom name per drink (generic placeholder; overrides the serving-derived name)
- ABV precision configurable (0.5 % or 0.1 % steps)

### Today
- Hero with pure alcohol today, the daily limit, today's status (Within / Close to / Over Limit) and a risk-coloured arc
- Calories and drink-count tiles; alcohol-free streak and alcohol-free-days-this-month tiles
- Guideline Limits: Today / 7-day / 30-day gauges vs guideline limit
- This Week bar chart with risk colours, daily-% annotations and a daily-limit line
- Over Weekly Limit card when the rolling 7-day total is over the weekly limit

### History
- Consumption events grouped by day, newest first, with each day's drink count and total
- Tap to open Edit Drink (pushed, with Log Again and Delete); swipe right to Log Again, swipe left to Delete; long-press for Log Again / Delete
- Search the list by drink name across your whole history, with All / Named / Unnamed scopes
- Calendar view with a risk mark per day (system calendar)

### Insights
- Period picker (week / month / year / all) with previous / next and a Today button
- Total with a neutral trend vs the previous period; alcohol-over-time area chart (scrub to see a day)
- Health Impact (heavy days, calories, alcohol-free days, longest streak, highest day, spend),
  weekday patterns, guideline comparison gauges
- Empty state with Log a Drink before the first drink; VoiceOver announces each period change

### Settings
- Biological sex, date of birth
- Guideline choice: WHO, UK NHS, US NIAAA, German DHS, or custom weekly goal
- Volume unit: ml, US fl oz, Imperial fl oz
- Alcohol display unit: grams or standard drinks (the UK reads "units")
- Currency (default for new drink prices; overridable per drink)
- ABV picker precision
- Notifications: opt-in daily log reminder with a time picker and opt-in weekly check-in (both off by default)
- Apple Health: opt-in write-back of logged drinks as Alcohol Consumption (off by default; also offered during onboarding)
- Data: export all data (JSON), import DrinkPulse backup, import from DrinkControl, delete all data
- App version: version and build number at the bottom of Settings (Debug builds also show a Debug marker and the build time)

### Guidelines & calculations
- Sex-aware limits for WHO, DE, UK, and US guidelines
- Pure alcohol in grams is the unit of truth; all other measures are derived
- Volume→mass density depends on the display mode and guideline (grams → 0.789
  always; standard drinks → 0.789 for US/CA, 0.8 for WHO/DE/AU/UK/custom); calories
  and BAC always use 0.789 (see ADR-0006, amending ADR-0005)
- Localised strings via `String(localized:)`; English (en) only

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
│   │   ├── Onboarding/          # First-run setup (cover over the shell)
│   │   ├── AddDrink/            # Type list (Recent, search) + drum-roll pickers
│   │   ├── Dashboard/
│   │   │   ├── Components/      # DashboardHeroCard, StreakCard, ConsumptionOverviewCard, ThisWeekCard, …
│   │   │   ├── DashboardView.swift
│   │   │   └── DashboardViewModel.swift
│   │   ├── History/             # Event list, pushed Edit Drink
│   │   ├── Insights/            # Period charts, guideline comparison, health metrics
│   │   └── Settings/            # Settings Form: profile, guideline, preferences, notifications, Health, data
│   ├── Services/                # Platform-capability wrappers behind protocols (ReminderService)
│   └── drinkpulseApp.swift      # App entry point, ModelContainer setup
├── drinkpulse.xcodeproj/
├── drinkpulseTests/             # Unit tests (domain logic, view-model calculations)
├── drinkpulseUITests/           # XCUITest UI tests (every user-facing feature)
├── docs/                        # Architecture, domain rules, roadmap, dev log, ADRs
└── CLAUDE.md                    # Project conventions for AI-assisted development
```

---

## Documentation

| File | Contents |
|------|----------|
| [.planning/PROJECT.md](.planning/PROJECT.md) | Vision, privacy stance, requirements |
| [docs/architecture.md](docs/architecture.md) | MVVM pattern, navigation, DI, concurrency |
| [docs/domain.md](docs/domain.md) | Calculation formulas, guideline thresholds, unit conventions |
| [.planning/ROADMAP.md](.planning/ROADMAP.md) | Active milestone phases and progress |
| [docs/decisions/](docs/decisions/) | Architecture Decision Records |
| [docs/DEVLOG.md](docs/DEVLOG.md) | Chronological development log |

---

## Development

Requires **Xcode 27** (Swift 6.4 compiler in Swift 6 language mode) and
macOS Tahoe 26.6 or later. Select an available iOS 27 simulator on this Mac
before running build or test commands. The committed [Phase 08 baseline record](.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md)
preserves the exact historical command, toolchain, result, and capture
environment; its simulator identity is evidence, not a general destination.

```bash
# List locally available simulators, then copy the identifier of an iOS 27 device.
xcrun simctl list devices available
export LOCAL_IOS_27_UDID='<selected-local-ios-27-simulator-udid>'
xcrun simctl bootstatus "$LOCAL_IOS_27_UDID" -b

# Build
xcodebuild -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" \
  build

# Test
xcodebuild -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" test
```

No `pod install` or `swift package resolve` step required.

---

## License

MIT — see [LICENSE](LICENSE). © 2026 Dawid Haniewicz.
