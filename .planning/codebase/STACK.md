# Technology Stack

**Analysis Date:** 2026-07-18

## Languages

**Primary:**
- Swift 6.0 (production code, strict concurrency enabled)
- Swift 5.0 (legacy test code, mix of XCTest and Swift Testing)

**Platform:** iOS only (SwiftUI + native frameworks)

## Runtime

**Environment:**
- iOS 26.0 minimum deployment target
- Xcode 16.0 or later required (Xcode 2650+)
- macOS Sequoia for development

**Architecture:**
- Single-threaded event loop (main actor isolation is mandatory)
- Strict concurrency checking enabled project-wide
- No background threads; async/await only for structured concurrency

## Package Manager

**Dependency Model:**
- **Zero external dependencies** — no CocoaPods, no Swift Package Manager external imports
- All functionality built on Apple frameworks
- Xcode project structure: `drinkpulse.xcodeproj` with three synchronized file groups:
  - `drinkpulse` (main app)
  - `drinkpulseTests` (unit tests)
  - `drinkpulseUITests` (UI/integration tests)

## Frameworks

**Core UI & State:**
- SwiftUI (no UIKit) — entire user interface
- Observation framework (`@Observable` macro) — reactive state management
- NavigationStack / TabView — navigation

**Persistence:**
- SwiftData — on-device database for `DrinkTemplate`, `ConsumptionEvent`, `UserProfile`
- Schemas versioned and migrated through `Domain/Persistence/` layer
- CloudKit sync via SwiftData (currently disabled; gated by `StoreBootstrap.productionConfiguration`)

**Data Visualization:**
- Swift Charts — area charts (Insights), bar charts (This Week), progress indicators

**Testing:**
- XCTest (legacy test suite)
- Swift Testing (new tests, `@Test` macro; mixed with XCTest)
- XCUITest (UI tests in `drinkpulseUITests` target)

**System Integration:**
- UserNotifications — local reminder scheduling for daily "log drinks" prompt
- HealthKit — optional Apple Health write-back (`HKHealthStore`, `numberOfAlcoholicBeverages` type)
- CoreTransferable — file import/export via document picker
- UniformTypeIdentifiers — MIME types for JSON export/import
- OSLog — structured logging via `os.Logger` (subsystem: `com.drinkpulse.app`)

**Concurrency:**
- async/await + structured concurrency (Swift 6)
- `@MainActor` isolation enforced on all view models and UI-touching services
- No DispatchQueue or GCD; Task-based only

## Key Dependencies

**No third-party packages.** The entire app is built on Apple frameworks:

| Framework | Version | Purpose |
|-----------|---------|---------|
| SwiftUI | iOS 26+ | User interface |
| SwiftData | iOS 26+ | Persistence, schema management |
| Swift Charts | iOS 26+ | Data visualization (area, bar charts) |
| UserNotifications | iOS 26+ | Local reminder scheduling |
| HealthKit | iOS 26+ | Apple Health write-back (optional) |
| Observation | iOS 26+ | Reactive state via `@Observable` |
| CoreTransferable | iOS 26+ | File transfer protocol (export/import) |
| UniformTypeIdentifiers | iOS 26+ | UTType definitions for JSON files |
| OSLog | iOS 26+ | Structured logging |

## Configuration

**Environment Setup:**
- `.entitlements` file: `com.apple.developer.healthkit` enabled (Health read + write capability)
- App ID: `com.haniewicz.drinkpulse`
- No API keys, secrets, or environment variables (on-device only)
- `@AppStorage` (UserDefaults) used for:
  - `AppStorageKeys.onboardingDone` — onboarding completion gate
  - `AppStorageKeys.colorScheme` — light/dark/system preference
  - Reminder schedule (time picker state)
  - ABV precision (0.5% or 0.1% steps)
  - Display unit preference (grams, units, standard drinks)
  - Volume unit (ml, fl oz imperial/US)

**Build Configuration:**
- No `.xcconfig` files; all settings in Xcode project
- Minimum Swift version: 5.0 (tests) and 6.0 (production)
- iOS deployment target: 26.0

**Localization:**
- English (en) only — all strings via `String(localized:)` with `Localizable.xcstrings`
- No support for other languages

## Platform Requirements

**Development:**
- Xcode 16.0+
- macOS Sequoia
- iPhone Simulator (15 Pro or similar, iOS 26)
- Git for version control

**Production (App Store):**
- iOS 26.0+
- iPhone (primary target)
- iPad and Apple Watch planned but not yet implemented
- CloudKit entitlement (not yet enabled)
- HealthKit entitlement (read + write, gated on user opt-in during onboarding/Settings)

**Privacy & Data Protection:**
- No network access outside SwiftData CloudKit sync (not yet enabled)
- App container only — no external file stores
- User data never leaves the device (privacy-first promise)
- No analytics, crash reporters, or third-party SDKs

---

*Stack analysis: 2026-07-18*
