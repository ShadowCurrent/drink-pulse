# Technology Stack

**Analysis Date:** 2026-08-02

## Languages

**Primary:**
- Swift 6.0 (production code, strict concurrency enabled)
- Swift 5.0+ (legacy test code, mixed XCTest and Swift Testing)

**Platform:** iOS only (SwiftUI + native frameworks)

## Runtime

**Environment:**
- iOS 26.0 minimum deployment target
- Xcode 16.0 or later required
- macOS Sequoia for development

**Architecture:**
- Single-threaded event loop (main actor isolation is mandatory)
- Strict concurrency checking enabled project-wide (`SWIFT_VERSION = 6.0`)
- No background threads; structured concurrency (`async`/`await`) only
- `@MainActor` isolation on all view models and services

## Package Manager

**Dependency Model:**
- **Zero external dependencies** — no CocoaPods, no Swift Package Manager
- All functionality built on Apple frameworks only
- Xcode project structure: `drinkpulse.xcodeproj` with three file-system-synchronized targets:
  - `drinkpulse` (main app, `PBXFileSystemSynchronizedRootGroup`)
  - `drinkpulseTests` (unit tests, mirrors production structure)
  - `drinkpulseUITests` (UI tests, mirrors production structure)

## Frameworks

**Core UI & State:**
- SwiftUI (no UIKit) — entire user interface
- Observation framework (`@Observable` macro) — reactive state management
- NavigationStack / TabView (value-based routing on iOS 26)

**Persistence:**
- SwiftData — on-device database (`DrinkTemplate`, `ConsumptionEvent`, `UserProfile`)
- Versioned schema with migration plan: V1 → V2 → V3 → V4
- CloudKit sync via SwiftData (currently disabled; gated by `StoreBootstrap.productionConfiguration`, plan-0023 Phase B)
- File-based recovery: corrupted stores moved to timestamped `RecoveredStores/` snapshots

**Data Visualization:**
- Swift Charts — area charts (Insights), bar charts (This Week/Insights), progress indicators

**Testing:**
- Swift Testing — new tests use `@Test` macro syntax
- XCTest — legacy tests and UI tests (`drinkpulseUITests`)
- XCUITest — user-facing feature testing

**System Integration:**
- UserNotifications — local reminder scheduling (daily "log drinks" prompt)
- HealthKit — optional Apple Health write-back (`HKHealthStore`, `numberOfAlcoholicBeverages` type)
- CoreTransferable — file import/export via document picker
- UniformTypeIdentifiers — MIME types for JSON export/import
- OSLog — structured logging via `os.Logger` (subsystem: `com.drinkpulse.app`, categories per component)

**Concurrency:**
- async/await + structured concurrency (Swift 6 strict concurrency)
- `@MainActor` isolation enforced
- No DispatchQueue, GCD, or Combine; Task-based only

## Key Dependencies

**No third-party packages.** The entire app uses Apple frameworks:

| Framework | Purpose | Status |
|-----------|---------|--------|
| SwiftUI | User interface | Production |
| SwiftData | Persistence, schema management | Production |
| Swift Charts | Data visualization (area, bar) | Production |
| UserNotifications | Local reminders | Production |
| HealthKit | Apple Health write-back | Production (opt-in) |
| Observation | Reactive state (`@Observable`) | Production |
| CoreTransferable | File transfer (export/import) | Production |
| UniformTypeIdentifiers | UTType definitions | Production |
| OSLog | Structured logging | Production |
| Foundation, UIKit (minimal) | Standard library | Production |

## Configuration

**Environment Setup:**
- `.entitlements` file: `com.apple.developer.healthkit` enabled (read + write)
- Bundle ID: `com.drinkpulse.drinkpulseApp`
- App name: `DrinkPulse`
- No API keys, secrets, or environment variables (on-device only)
- `@AppStorage` (UserDefaults) for:
  - `AppStorageKeys.onboardingDone` — onboarding gate
  - `AppStorageKeys.colorScheme` — light/dark/system preference
  - Reminder schedule, ABV precision, display units, volume units

**Build Configuration:**
- Xcode project settings only (no `.xcconfig` files)
- Swift version: 6.0 (app + unit tests), 5.0+ (legacy tests)
- iOS deployment target: 26.0
- Device families: iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`)

**Localization:**
- English (en) only — all strings via `String(localized:)` with `Localizable.xcstrings`
- No multi-language support

## Platform Requirements

**Development:**
- Xcode 16.0+
- macOS Sequoia
- iPhone Simulator (iOS 26)
- Git for version control

**Production (App Store):**
- iOS 26.0+
- iPhone (primary)
- iPad and Apple Watch (planned, not implemented)
- HealthKit entitlement (read + write, user-opt-in)
- CloudKit entitlement (not yet provisioned; plan-0023 Phase B)

**Privacy & Data Protection:**
- No network access outside SwiftData CloudKit sync (not yet enabled)
- App container only (default file protection)
- User data never leaves device (privacy-first promise)
- Zero analytics, crash reporters, or third-party SDKs

---

*Stack analysis: 2026-08-02*
