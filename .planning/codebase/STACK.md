---
last_mapped_commit: 8f0cefeb8c0f6f0169a34fe15b31dce3c8005d57
last_mapped_at: 2026-11-18
---
# Technology Stack

**Analysis Date:** 2026-11-18

## Languages

**Primary:**
- Swift 6.0 language mode (`SWIFT_VERSION = 6.0` in `drinkpulse.xcodeproj/project.pbxproj`; strict concurrency on) - all app, domain, service, test, and UI test code under `drinkpulse/`, `drinkpulseTests/`, `drinkpulseUITests/`
- Toolchain in use: Xcode 27.2 (build 27B52), Apple Swift 6.4.2, per `.claude/context/current-focus.md`

**Secondary:**
- JSON - backup/export format (`drinkpulse/Domain/DataTransfer/BackupDocument.swift`, `drinkpulse/Domain/DataTransfer/ExportBundle.swift`), test fixtures in `drinkpulseTests/Domain/DataTransfer/Fixtures/`
- CSV - legacy import from DrinkControl (`drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift`, file `drinkcontrol.csv` at repo root is a local sample)
- String Catalog (`drinkpulse/Localizable.xcstrings`, source language `en`, English only)
- Property lists - `drinkpulse/Info.plist`, `drinkpulse/drinkpulse.entitlements`, `drinkpulse/Assets.xcassets/` colour and image sets, `drinkpulse/AppIcon.icon/icon.json`
- Shell - `.claude/hooks/check-xcode.sh` (SessionStart hook for developer tooling only)

## Runtime

**Environment:**
- iOS deployment target 27.0 (`IPHONEOS_DEPLOYMENT_TARGET = 27.0`)
- Device families: iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`); README says iPhone first, iPad and Apple Watch later
- Orientation: portrait only on iPhone (`drinkpulse/Info.plist`); all four orientations on iPad
- Default actor isolation: `MainActor` (`SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`)
- Build-time settings: `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`, `ENABLE_USER_SCRIPT_SANDBOXING = YES`
- Development team: `NXXRPVVLH8`; code signing style Automatic
- Bundle identifiers: app `com.haniewicz.drinkpulse`, unit tests `com.drinkpulse.drinkpulseTests`, UI tests `com.haniewicz.drinkpulseUITests`
- Logging subsystem used throughout: `com.drinkpulse.app`

**Package Manager:**
- Xcode project (`drinkpulse.xcodeproj`), no SwiftPM package manifest and no `Package.resolved`
- Third-party dependencies: none detected (all `import` statements resolve to Apple SDK frameworks)
- Lockfile: Not applicable

## Frameworks

**Core (Apple SDK, no third-party):**
- SwiftUI - all UI; `NavigationStack` / `NavigationSplitView`; `@Query` and `@Environment(\.modelContext)` for data access (imported in 84 Swift files)
- SwiftData - persistence; `ModelContainer`, `VersionedSchema`, `SchemaMigrationPlan` (`drinkpulse/Domain/Persistence/`)
- Observation - `@Observable` view models (ADR `docs/decisions/0002-observable-macro.md`)
- Swift Charts - `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift`, `WeekdayBarChart.swift` (4 files import `Charts`)
- HealthKit - Apple Health write-back of alcohol consumption (`drinkpulse/Services/HealthKitAdapter.swift`)
- UserNotifications - local reminders and weekly summary (`drinkpulse/Services/ReminderService.swift`, `WeeklySummaryService.swift`, `NotificationActionHandler.swift`)
- UniformTypeIdentifiers / SwiftUI file importer and exporter - backup JSON and CSV import (`drinkpulse/Features/Settings/Components/DataSection.swift`)
- CoreTransferable - imported in one file for transferable export payloads
- Accessibility - accessibility audits and chart descriptors (4 files import `Accessibility`)
- UIKit - only in limited bridging (`UIApplication.openSettingsURLString` in Settings sections; `import UIKit` in 3 files, UIKit hosting for the paged onboarding `TabView` noted in `drinkpulse/Features/Onboarding/OnboardingView.swift`)
- OSLog (`os.Logger`) - structured logging (15 files import `OSLog`, 2 import `os`)

**Testing:**
- Swift Testing (`@Test`, `#expect`) - newer tests (71 files import `Testing`)
- XCTest - legacy unit tests and all XCUITest UI tests (61 files import `XCTest`); targets `drinkpulseTests`, `drinkpulseUITests`
- Coverage: `xcodebuild -enableCodeCoverage YES` with `xcrun xccov` (commands in `AGENTS.md`)
- Test fixtures: JSON backups in `drinkpulseTests/Domain/DataTransfer/Fixtures/`

**Build/Dev:**
- Xcode 27.2 / `xcodebuild` - build, test, coverage
- Xcode MCP bridge - `.mcp.json` runs `xcrun mcpbridge` (developer tooling, not shipped)
- Claude Code settings - `.claude/settings.json` (enables `swiftui-expert` plugin, Xcode MCP permissions)
- graphify - knowledge graph artefacts in `graphify-out/` (developer tooling, not shipped)
- GSD planning tooling - `.planning/`, `.gsd/` (developer tooling, not shipped)

## Key Dependencies

**Critical:**
- None third-party. Every runtime dependency is an Apple SDK framework: SwiftUI, SwiftData, HealthKit, UserNotifications, Charts, OSLog.

**Infrastructure:**
- CloudKit - declared intent only: `StoreBootstrap.cloudKitContainerID = "iCloud.com.drinkpulse.app"` in `drinkpulse/Domain/Persistence/StoreBootstrap.swift`; production `ModelConfiguration` is created without a CloudKit database, so sync is OFF. Entitlements file contains only HealthKit (no iCloud/CloudKit entitlement yet).
- HealthKit entitlement - `com.apple.developer.healthkit` = true in `drinkpulse/drinkpulse.entitlements`.

## Persistence Layout

- SwiftData store in the app container (`ModelConfiguration(schema:isStoredInMemoryOnly: false)`), managed by `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (startup recovery keeps up to `maxRecoveredStores = 3` moved-aside stores).
- Schema versions: `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` through `SchemaV4.swift`; migration plan `drinkpulse/Domain/Persistence/MigrationPlan.swift` with stages V1→V2 (custom), V2→V3 (custom), V3→V4 (lightweight).
- Architecture decision: `docs/decisions/0009-versioned-schema-and-migration-plan.md`.

## Configuration

**Environment:**
- No environment variables, `.env` files, or runtime config files are used by the app. No secrets in the repository (AGENTS.md policy).
- `.env*` files: Not detected in the repository.
- Feature/test hooks: launch arguments (for example `-dp_onboarding_done YES`) and `UITestSeed.isActive` gate test-only seeding (`drinkpulse/UITestSeed.swift`).

**Build:**
- `drinkpulse.xcodeproj/project.pbxproj` - targets `drinkpulse`, `drinkpulseTests`, `drinkpulseUITests`, all file-system synchronized groups
- `drinkpulse/Info.plist` - HealthKit usage strings (`NSHealthShareUsageDescription`, `NSHealthUpdateUsageDescription`), launch screen, orientations
- `drinkpulse/drinkpulse.entitlements` - HealthKit entitlement
- `.gitignore` - ignores `build/`, `DerivedData/`, `xcuserdata/`, graphify large artefacts

**Localization:**
- English only (`drinkpulse/Localizable.xcstrings`, `sourceLanguage: en`); user-facing strings via `String(localized:)`

## Platform Requirements

**Development:**
- macOS Tahoe 26.6 or later (per `README.md`)
- Xcode 27.2 with iOS 27.2 SDK and an iOS 27 simulator (for example iPhone 18 Pro on iOS 27.2 per `.claude/context/current-focus.md`)
- Simulator UDID is machine-specific; resolve via `xcrun simctl list devices available` (see `AGENTS.md`)

**Production:**
- iOS 27.0 or later, iPhone (iPad supported by device family setting)
- Requires Apple Health for optional write-back; notifications optional
- No server or backend; all data on device (CloudKit sync planned, not enabled)

---

*Stack analysis: 2026-11-18*
