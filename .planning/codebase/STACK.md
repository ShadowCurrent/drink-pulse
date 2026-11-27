---
last_mapped_commit: 19ce3159ee64540aaea8411fc85f24e6bea68714
last_mapped_at: 2026-11-27
---
# Technology Stack

**Analysis Date:** 2026-11-27

## Languages

**Primary:**
- Swift 6 language mode (`SWIFT_VERSION = 6.0` in `drinkpulse.xcodeproj/project.pbxproj`, strict concurrency) - all app code under `drinkpulse/` (189 files, about 12,280 lines excluding `Preview Content`), plus `drinkpulseTests/` and `drinkpulseUITests/`

**Secondary:**
- JSON - backup/export format (`drinkpulse/Domain/DataTransfer/BackupDocument.swift`, `drinkpulse/Domain/DataTransfer/ExportBundle.swift`); test fixtures in `drinkpulseTests/Domain/DataTransfer/Fixtures/`
- CSV - one-way legacy import from DrinkControl (`drinkpulse/Domain/DataTransfer/DrinkControlImporter.swift`). `drinkcontrol.csv` at repo root is a local sample, not shipped.
- String Catalog - `drinkpulse/Localizable.xcstrings` (English only)
- Property lists - `drinkpulse/Info.plist`, `drinkpulse/drinkpulse.entitlements`
- Asset catalogs and icon - `drinkpulse/Assets.xcassets/`, `drinkpulse/AppIcon.icon/`
- Shell - `.claude/hooks/check-xcode.sh` (SessionStart developer hook only; not shipped)

## Runtime

**Environment:**
- iOS deployment target 27.0 (`IPHONEOS_DEPLOYMENT_TARGET = 27.0` on all app, test, and UI test configs)
- Device families: `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone and iPad build settings). `AGENTS.md` scopes the product to iPhone first; iPad and Apple Watch are later.
- Orientation: portrait only on iPhone, all four on iPad (`UISupportedInterfaceOrientations` and `~ipad` keys in `drinkpulse/Info.plist`)
- Default actor isolation: `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`
- Marketing version `1.0`, build `1` (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`)
- Bundle identifiers: app `com.haniewicz.drinkpulse`; unit tests `com.drinkpulse.drinkpulseTests`; UI tests `com.haniewicz.drinkpulseUITests`
- Logging subsystem: `com.drinkpulse.app` (`os.Logger`, e.g. `drinkpulse/drinkpulseApp.swift`, `drinkpulse/Services/ReminderService.swift`)
- Toolchain: Xcode with Swift 6 toolchain. Exact Xcode version is recorded in the Phase 08 baseline (`.planning/phases/08-ios-27-baseline-api-inventory/08-BASELINE.md`); not re-verified in this pass.

**Package Manager:**
- Xcode project only (`drinkpulse.xcodeproj`). No `Package.swift`, no `Package.resolved`, no CocoaPods/Carthage manifests.
- Lockfile: Not applicable (no third-party dependencies)

## Frameworks

**Core (Apple SDK only):**
- SwiftUI - all UI; `NavigationStack` / `NavigationSplitView`; `@Query` and `@Environment(\.modelContext)` (about 112 files import SwiftUI)
- SwiftData - persistence; `ModelContainer`, `ModelConfiguration`, `VersionedSchema`, `SchemaMigrationPlan` (`drinkpulse/Domain/Persistence/`)
- Observation - `@Observable` view models (`docs/decisions/0002-observable-macro.md`)
- Swift Charts - `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift`, `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift`, `drinkpulse/Features/Dashboard/Components/ThisWeekCard.swift`
- HealthKit - write-back of logged drinks as Alcohol Consumption (`drinkpulse/Services/HealthKitAdapter.swift`)
- UserNotifications - local reminders and weekly summary (`drinkpulse/Services/ReminderService.swift`, `drinkpulse/Services/WeeklySummaryService.swift`, `drinkpulse/Services/NotificationActionHandler.swift`)
- UniformTypeIdentifiers - backup/CSV file import and export (`drinkpulse/Features/Settings/Components/DataSection.swift`)
- CoreTransferable - export payloads
- Accessibility - audits and chart descriptors (4 files)
- UIKit - limited bridging only (3 files, e.g. `UIApplication.openSettingsURLString` in Settings sections; onboarding paging in `drinkpulse/Features/Onboarding/OnboardingView.swift`)
- OSLog - `Logger` (17 files import `OSLog`, 2 import `os`)
- CoreGraphics - 1 file

**Testing:**
- Swift Testing (`@Test`, `#expect`) - newer unit tests (about 97 files import `Testing`)
- XCTest - legacy unit tests and all XCUITest UI tests (about 79 files import `XCTest`)
- Targets: `drinkpulseTests/`, `drinkpulseUITests/` (both file-system synchronized)
- Coverage: `xcodebuild -enableCodeCoverage YES` plus `xcrun xccov` (commands in `AGENTS.md`)

**Build/Dev (developer tooling, not shipped):**
- `xcodebuild` / Xcode build, test, coverage
- Xcode MCP bridge - `.mcp.json` runs `xcrun mcpbridge` (stdio)
- Claude Code settings - `.claude/settings.json` (enables `swiftui-expert-skill` plugin; allows `xcodebuild`, `xcrun`, `swift build`, `swift test`, `mcp__xcode__*`; denies reading `.env` files and force pushes)
- GSD planning tooling - `.planning/`, `.gsd/`
- graphify knowledge graph - `graphify-out/`

## Key Dependencies

**Critical:**
- None third-party. Every runtime dependency is an Apple SDK framework.

**Infrastructure:**
- SwiftData store - local SQLite store in the app container (`ModelConfiguration(schema:isStoredInMemoryOnly: false)` in `drinkpulse/Domain/Persistence/StoreBootstrap.swift`)
- HealthKit entitlement - `com.apple.developer.healthkit` = true in `drinkpulse/drinkpulse.entitlements`
- CloudKit - planned, NOT enabled. `StoreBootstrap.cloudKitContainerID = "iCloud.com.drinkpulse.app"` is declared, but the production `ModelConfiguration` has no CloudKit database and the entitlements file has no iCloud/CloudKit key. Decision recorded in `docs/decisions/0001-swiftdata-cloudkit.md` (status Accepted) and `docs/decisions/0010-cloudkit-ready-identity-and-lww.md`.

## Persistence Layout

- Store: SwiftData, app container, managed by `drinkpulse/Domain/Persistence/StoreBootstrap.swift`. Startup recovery moves aside failed stores and keeps at most `maxRecoveredStores = 3`.
- Schemas: `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` through `SchemaV4.swift`
- Migration plan: `drinkpulse/Domain/Persistence/MigrationPlan.swift` (stages V1 to V2 custom, V2 to V3 custom, V3 to V4 lightweight)
- Other: `drinkpulse/Domain/Persistence/UserProfileStore.swift`, `drinkpulse/Domain/Persistence/RecordDeduplicator.swift`
- Decision: `docs/decisions/0009-versioned-schema-and-migration-plan.md`
- In-memory containers are used only for previews and UI-test seeding (`drinkpulse/UITestSeed.swift`, `*+Previews.swift` files).

## Configuration

**Environment:**
- No environment variables, no `.env` files, no runtime configuration files required. The app has no backend.
- Launch arguments drive UI-test state (e.g. `-dp_onboarding_done YES`, per `AGENTS.md`).

**Build:**
- `drinkpulse.xcodeproj/project.pbxproj` - single source of build settings
- `drinkpulse/Info.plist` - usage strings and orientation
- `drinkpulse/drinkpulse.entitlements` - HealthKit only
- Settings relevant to Swift 6: `SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`, `ENABLE_USER_SCRIPT_SANDBOXING = YES` (per prior mapping; re-check with GetTargetBuildSettings before relying on them)
- Code signing: Automatic, development team `NXXRPVVLH8`

## Platform Requirements

**Development:**
- macOS with Xcode that supports the iOS 27 SDK and Swift 6
- An iOS 27 simulator for build and test (see `AGENTS.md`, "Local iOS 27 simulator destination")

**Production:**
- iOS 27.0 or later, iPhone (iPad supported by build settings)
- Distribution through the App Store (no backend deployment)

---

*Stack analysis: 2026-11-27*
