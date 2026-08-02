# Codebase Structure

**Analysis Date:** 2026-08-02

## Directory Layout

```
drinkpulse/                              # Main app target
├── drinkpulseApp.swift                  # @main entry point; ModelContainer, onboarding gate, HealthService injection
├── UITestSeed.swift                     # UI test fixture seeding and in-memory store creation (gate: -dp_uitest)
├── UITestSeed+Fixtures.swift            # Test data builders
├── Diagnostics/                         # Dev-only diagnostics (view load timing, etc.)
│   └── ViewLoadLogger.swift             # Optional view load instrumentation
│
├── Features/                            # Feature modules (one folder per screen/flow)
│   ├── Shell/
│   │   ├── RootShellView.swift          # Tab bar and sheet container; UserProfile guard
│   │   ├── StartupErrorView.swift       # Store recovery error UI (Retry + Share)
│   │   ├── AppTab.swift                 # Tab enum definition
│   │   └── Components/
│   │       └── AddDrinkButton.swift     # FAB for adding drinks
│   │
│   ├── Dashboard/                       # Home tab
│   │   ├── DashboardView.swift          # Layout, data fetch, VM injection
│   │   ├── DashboardViewModel.swift     # Aggregates: today/weekly/monthly grams, risk, streaks
│   │   └── Components/
│   │       ├── DashboardHeroCard.swift  # Hero card with time-based greeting + risk badge
│   │       ├── ThisWeekCard.swift       # Week bar chart with daily % annotations
│   │       ├── ConsumptionOverviewCard.swift  # Today/7-day/30-day progress bars
│   │       ├── StreakCard.swift         # Sober streak + sober days this month
│   │       ├── GuidelineAlertCard.swift # Exceeded guideline alert
│   │       └── [other dashboard components]
│   │
│   ├── AddDrink/                        # Log-a-drink flow (type grid → detail form)
│   │   ├── AddDrinkView.swift           # NavigationStack wrapper; dismissSheet environment
│   │   ├── DrinkTypeGridView.swift      # Category grid; navigation to detail
│   │   ├── DrinkTypePreset.swift        # Drink template struct; category grouping; volume/ABV presets
│   │   ├── DrinkTypePreset+*.swift      # Category-specific presets (Fermented, Spirits, Mixed)
│   │   ├── DrinkDetailInputView.swift   # Form: volume, ABV, quantity, date, notes, price, custom name
│   │   ├── DrinkDetailInputView+Logic.swift  # `save()` and pure calculators (testable)
│   │   └── Components/
│   │       └── DrinkTypeTile.swift      # Category tile in grid
│   │
│   ├── History/                         # Past events (calendar-based list view)
│   │   ├── HistoryView.swift            # Tab container (segment: calendar/list)
│   │   ├── HistoryListQueryView.swift   # List mode (sorted by date)
│   │   ├── HistoryCalendarQueryView.swift  # Calendar mode (grouped by day)
│   │   ├── HistoryViewModel.swift       # Segment state, filtering
│   │   ├── HistorySegment.swift         # Enum: calendar or list
│   │   ├── EditEventView.swift          # Modal sheet for editing an event
│   │   └── Components/
│   │       ├── EventRow.swift           # Single event display
│   │       ├── HistoryCalendarView.swift # Interactive calendar grid
│   │       ├── HistoryCalendarDayCell.swift # Calendar day tile
│   │       ├── HistoryCalendarDayDetail.swift # Day detail popover
│   │       ├── EventContextMenu.swift   # Long-press: Duplicate, Delete
│   │       ├── EditServingPickers.swift # Edit volume, ABV, quantity
│   │       ├── EditDrinkTypeSelectionView.swift # Edit category
│   │       ├── EditNotesSection.swift   # Edit notes
│   │       ├── PriceCurrencySection.swift # Edit price + per-drink currency
│   │       ├── CustomNameSuggestionSection.swift # Suggested names on edit
│   │       └── DeleteConfirmationPopover.swift # Swipe delete confirmation
│   │
│   ├── Insights/                        # Trends (area chart, bars, health metrics)
│   │   ├── InsightsView.swift           # Dashboard for analytics
│   │   ├── InsightsViewModel.swift      # Chart data, health metrics aggregation
│   │   ├── InsightsViewModel+Charts.swift # Chart data generation
│   │   ├── InsightsViewModel+HealthMetrics.swift # Calories, drink count, spend
│   │   ├── InsightsViewModel+Formatting.swift # Number formatting
│   │   ├── InsightsPeriod.swift         # Enum: week/month/quarter/year
│   │   ├── InsightsChartModels.swift    # Chart entry structs
│   │   ├── InsightsDataGenerator.swift  # Aggregate queries
│   │   ├── Calendar+Days.swift          # Calendar utility
│   │   └── Components/
│   │       ├── InsightsHeroCard.swift   # Summary card with bar chart
│   │       ├── AlcoholAreaChart.swift   # Area chart over time
│   │       ├── AlcoholAreaChart+Accessibility.swift # Chart accessibility
│   │       ├── WeekdayBarChart.swift    # Bar chart by weekday
│   │       ├── WeekdayBarChart+Accessibility.swift # Chart accessibility
│   │       ├── InsightsScopeNavigator.swift # Period picker
│   │       ├── GuidelineComparisonCard.swift # Guideline vs actual
│   │       └── HealthMetricsCard.swift  # Calories, drink count, spend
│   │
│   ├── Settings/                        # Profile editor, guidelines, data export/import
│   │   ├── SettingsView.swift           # Root settings screen
│   │   └── Components/
│   │       ├── AppearanceModeRow.swift  # Light/dark/system picker
│   │       ├── GuidelinePickerSheet.swift # Guideline selection modal
│   │       ├── HealthSection.swift      # Apple Health opt-in + auth status
│   │       ├── ReminderSection.swift    # Daily reminder toggle + time picker
│   │       ├── WeeklySummarySection.swift # Weekly summary toggle + time picker
│   │       ├── DataSection.swift        # Export, import, delete all buttons
│   │       ├── SettingsRow.swift        # Reusable row component
│   │       ├── SettingsActionRow.swift  # Action-button row variant
│   │       └── SettingsSection.swift    # Reusable section header
│   │
│   └── Onboarding/                      # Initial profile creation flow
│       ├── OnboardingView.swift         # Multi-step container
│       ├── OnboardingViewModel.swift    # Form state, validation
│       └── Components/
│           ├── WelcomeStep.swift        # Welcome screen
│           ├── ProfileStep.swift        # Age, sex, weight, guideline, unit mode
│           ├── GuidelineStep.swift      # Guideline choice + custom goal
│           └── HealthStep.swift         # Apple Health opt-in (optional)
│
├── Domain/                              # Data models, calculations, import/export
│   ├── ConsumptionEvent.swift           # @Model: single logged drink (identity, LWW, calculation methods)
│   ├── DrinkTemplate.swift              # @Model: reusable preset
│   ├── UserProfile.swift                # @Model: singleton user settings
│   ├── AlcoholUnit.swift                # Enum: display mode (standard drinks, UK units, grams) + density
│   ├── AlcoholUnit+*.swift              # Extensions: formatting, volume conversion
│   ├── BiologicalSex.swift              # Enum: sex for guideline limits
│   ├── DrinkCategory.swift              # Enum: beer, wine, spirit, cocktail, cider, custom
│   ├── GuidelineChoice.swift            # Enum: guideline selection (WHO, country profiles, custom)
│   ├── GuidelineChoice+Display.swift    # Guideline display names, images
│   ├── GuidelineChoice+Limits.swift     # Limit calculation (daily/weekly for sex/weight/custom goal)
│   ├── GuidelineLimits.swift            # Value type: daily/weekly limit thresholds
│   ├── RiskLevel.swift                  # Enum: low/caution/exceeded
│   ├── UnitSystem.swift                 # Enum: metric/imperial
│   ├── UnitSystem+ServingLabels.swift   # Serving name resolution (e.g., "25 ml", "1 oz")
│   ├── UnitSystem+Volume.swift          # Volume conversion and display
│   ├── Currency.swift                   # Currency enum + catalog
│   ├── CustomNameSuggestionFilter.swift # Filter for custom name suggestions on edit
│   ├── WeeklySummaryCalculator.swift    # Aggregate weekly stats for notifications
│   │
│   ├── DataTransfer/                    # Import/export
│   │   ├── BackupDocument.swift         # SwiftUI FileDocument for export (.fileExporter)
│   │   ├── BackupExport.swift           # Export builder (JSON structure)
│   │   ├── ExportBundle.swift           # Export file container + versioning
│   │   ├── ExportRecord.swift           # Single exportable record (event, template, profile)
│   │   ├── DataImporter.swift           # Generic import logic; validates + inserts records
│   │   ├── DrinkControlImporter.swift   # DrinkControl CSV parser (migration from old app)
│   │   ├── ImportError.swift            # Typed errors (invalidFormat, unsupportedVersion, etc.)
│   │   ├── ImportResult.swift           # Success count summary
│   │   ├── ProfileRecord.swift          # Serializable UserProfile snapshot
│   │   └── TemplateRecord.swift         # Serializable DrinkTemplate snapshot
│   │
│   └── Persistence/                     # Store setup, migration, recovery
│       ├── StoreBootstrap.swift         # ModelContainer creation, recovery, CloudKit config
│       ├── MigrationPlan.swift          # Versioned schemas (V1–V4) + migration stages
│       ├── Schemas/
│       │   ├── SchemaV1.swift           # Frozen: original shape (name, @Attribute(.unique))
│       │   ├── SchemaV2.swift           # Frozen: CloudKit-ready (uuid, modifiedDate, no .unique)
│       │   ├── SchemaV3.swift           # Frozen: timestamp→consumptionDate, add creationDate
│       │   └── SchemaV4.swift           # Frozen: add device-local healthKitUUID
│       ├── UserProfileStore.swift       # Singleton UserProfile fetch-or-create + de-dup
│       ├── RecordDeduplicator.swift     # Cross-device de-dup by uuid + LWW
│       ├── ContainerLoadState.swift     # Enum: .loading / .ready / .failed
│       └── StartupError.swift           # Store open error wrapper
│
├── Services/                            # Platform capability wrappers
│   ├── HealthService.swift              # Mirrors logged drinks to Apple Health (best-effort, serialized)
│   ├── HealthServiceEnvironment.swift   # @Entry custom environment key for HealthService
│   ├── HealthWriteHooks.swift           # Gated write/update/delete hooks (plan-0036, ADR-0011)
│   ├── HealthKitAdapter.swift           # Real HKHealthStore wrapper
│   ├── HealthWriting.swift              # Protocol abstraction (HealthKitAdapter + UITestHealthStore conform)
│   ├── UITestHealthStore.swift          # Non-prompting in-memory stub for UI tests
│   │
│   ├── ReminderService.swift            # Schedules/cancels daily drink-log reminders
│   ├── WeeklySummaryService.swift       # Schedules weekly summary notifications
│   ├── NotificationScheduling.swift     # Protocol abstraction (UserNotificationCenter)
│   ├── NotificationActionHandler.swift  # Delegate for handling tapped reminder (routes to Add Drink)
│   └── UITestNotificationCenter.swift   # Test stub for notifications
│
├── DesignSystem/                        # Shared design tokens, components, modifiers
│   ├── DPBrand.swift                    # Typography, spacing, corner radius constants
│   ├── DPColors.swift                   # Semantic colors (primary, accent, backgrounds, etc.)
│   ├── DPSemanticColors.swift           # Color helper extensions
│   ├── DPLargeTitle.swift               # Reusable large title view modifier
│   ├── DPGlass.swift                    # Liquid Glass background effect (iOS 26)
│   ├── DPArcProgress.swift              # Reusable arc progress indicator (for guideline compliance)
│   ├── RiskLevel+Color.swift            # Risk level → color mapping
│   └── AppStorageKeys.swift             # @AppStorage key constants (onboardingDone, colorScheme, etc.)
│
└── Assets.xcassets/                     # Image assets, app icon, colors, symbol sets

drinkpulseTests/                         # Unit tests (mirrors source structure)
├── Domain/
│   ├── AlcoholUnitTests.swift
│   ├── AlcoholCalculationTests.swift
│   ├── AlcoholUnitFormattingTests.swift
│   ├── GuidelineLimitsTests.swift
│   ├── GuidelineChoiceDisplayTests.swift
│   ├── ConsumptionEventTests.swift
│   ├── DrinkTemplateTests.swift
│   ├── DrinkTypePresetTests.swift
│   ├── UserProfileTests.swift
│   ├── RiskLevelTests.swift
│   ├── CurrencyTests.swift
│   ├── UnitSystemVolumeTests.swift
│   ├── CustomNameSuggestionFilterTests.swift
│   ├── WeeklySummaryCalculatorTests.swift
│   │
│   ├── DataTransfer/
│   │   ├── DataImporterTests.swift
│   │   └── DrinkControlImporterTests.swift
│   │
│   └── Persistence/
│       ├── RecordDeduplicatorTests.swift
│       └── UserProfileStoreTests.swift
│
├── Features/
│   ├── Dashboard/
│   │   └── DashboardViewModelTests.swift
│   │
│   ├── AddDrink/
│   │   └── [AddDrink tests]
│   │
│   ├── History/
│   │   └── [History tests]
│   │
│   ├── Insights/
│   │   └── [Insights tests]
│   │
│   ├── Onboarding/
│   │   └── [Onboarding tests]
│   │
│   └── Settings/
│       └── [Settings tests]
│
├── Services/
│   ├── HealthServiceTests.swift
│   ├── ReminderServiceTests.swift
│   ├── WeeklySummaryServiceTests.swift
│   └── FakeHealthStore.swift            # Test fake for HealthService testing
│
├── Diagnostics/
│   └── ViewLoadLoggerTests.swift
│
└── Performance/
    └── ScreenComputePerformanceTests.swift

drinkpulseUITests/                      # UI tests (XCUITest, mirrors source structure)
├── Features/
│   ├── Dashboard/
│   │   └── DashboardUITests.swift
│   │
│   ├── AddDrink/
│   │   └── AddDrinkUITests.swift
│   │
│   ├── History/
│   │   └── HistoryUITests.swift
│   │
│   ├── Insights/
│   │   └── InsightsUITests.swift
│   │
│   ├── Onboarding/
│   │   └── OnboardingUITests.swift
│   │
│   ├── Settings/
│   │   └── SettingsUITests.swift
│   │
│   └── Shell/
│       └── RootShellUITests.swift
```

## Directory Purposes

### Features
**Purpose:** Feature modules — each feature is self-contained and includes its view(s), view model, and feature-local subviews.
**Contains:** `*View.swift`, `*ViewModel.swift`, local `Components/` subfolder for larger features.
**Pattern:** Each feature folder is a complete, isolated feature with its own navigation, state, and logic.

### Domain
**Purpose:** Core data models, business logic, calculations, and persistence bootstrap.
**Contains:** SwiftData models (`@Model` classes), pure value types (enums, structs), calculation functions, import/export logic, schema versioning.
**Subdirectories:**
- **`DataTransfer/`**: File import/export, JSON parsing, record serialization, backup/restore.
- **`Persistence/`**: Store setup (`StoreBootstrap`), versioned schemas (V1–V4), migration stages, deduplication, recovery.

### Services
**Purpose:** Platform capability wrappers (notifications, Health, file I/O) behind protocols for testability.
**Contains:** Service classes (`@MainActor final class`), protocol abstractions, real adapters, test stubs.
**Pattern:** Each capability has a service class, a protocol, a real adapter, and optional test stub. Services inject the protocol via `init()` parameter.

### DesignSystem
**Purpose:** Shared design tokens, reusable components, and visual constants.
**Contains:** Color tokens, typography constants, spacing, corner radii, reusable view modifiers, shared UI components.
**Key files:** `DPColors`, `DPBrand`, `DPGlass` (Liquid Glass), `DPArcProgress`, `RiskLevel+Color`.

### Diagnostics
**Purpose:** Dev-only instrumentation for measuring and logging (view load timing, etc.).
**Gated:** `#if DEBUG` guards; inert in production.

## Key File Locations

### Entry Points
- `drinkpulseApp.swift`: @main app, ModelContainer creation, onboarding gate.
- `Features/Shell/RootShellView.swift`: Tab navigation, sheet container, UserProfile guard.
- `Features/Onboarding/OnboardingView.swift`: Initial profile creation flow.

### Configuration
- `Domain/Persistence/StoreBootstrap.swift`: ModelContainer config, CloudKit container ID, recovery logic.
- `Domain/Persistence/MigrationPlan.swift`: Versioned schemas (V1–V4) and migration stages.
- `DesignSystem/AppStorageKeys.swift`: @AppStorage key constants.
- `DesignSystem/DPBrand.swift`: Typography, spacing, corner radius.

### Core Logic
- `Domain/ConsumptionEvent.swift`: Drink log model, calculation methods (alcoholGrams, pureAlcoholGrams).
- `Domain/GuidelineChoice*.swift`: Guideline engine, limit derivation.
- `Domain/AlcoholUnit.swift`: Display unit, density calculation.
- `Features/Dashboard/DashboardViewModel.swift`: Aggregates (today/weekly/monthly grams), risk levels, streak calculations.
- `Features/AddDrink/DrinkDetailInputView+Logic.swift`: Form save logic, calculation helpers.

### Testing
- `drinkpulseTests/Domain/`: Unit tests for models, calculations, import/export, persistence (100% coverage target).
- `drinkpulseTests/Features/<Name>/`: Unit tests for view model logic (≥90% coverage target).
- `drinkpulseTests/Services/`: Unit tests for service logic via mocked protocols (≥85% coverage target).
- `drinkpulseUITests/Features/<Name>/`: UI tests for user-facing flows (mandatory for every feature).

## Naming Conventions

### Files
- **Views:** `<FeatureName>View.swift` (e.g., `DashboardView.swift`, `DrinkTypeGridView.swift`)
- **View models:** `<FeatureName>ViewModel.swift` (e.g., `DashboardViewModel.swift`)
- **View logic extensions:** `<ViewName>+Logic.swift` (e.g., `DrinkDetailInputView+Logic.swift`)
- **Previews:** `<ViewName>+Previews.swift` (if extracted; optional if ≤30 lines in main file)
- **Models:** PascalCase, no suffix (e.g., `ConsumptionEvent.swift`, `DrinkTemplate.swift`)
- **Services:** `<ServiceName>Service.swift` (e.g., `HealthService.swift`, `ReminderService.swift`)
- **Protocols:** `<Capability>` or `<ServiceName>Protocol` (e.g., `HealthWriting.swift`, `NotificationScheduling.swift`)
- **Adapters:** `<Framework><Service>Adapter.swift` (e.g., `HealthKitAdapter.swift`)
- **Test stubs:** `UITest<Name>.swift` (e.g., `UITestHealthStore.swift`, `UITestNotificationCenter.swift`)
- **Constants/helpers:** PascalCase if a type, camelCase if standalone (e.g., `AppStorageKeys.swift`, `RiskLevel+Color.swift`)

### Directories
- **Features:** PascalCase, one per feature (e.g., `Dashboard/`, `AddDrink/`, `Settings/`)
- **Subfolders in features:** `Components/` (extracted subviews), `PreviewContent/` (if needed for preview data)
- **Domain subdirs:** `DataTransfer/`, `Persistence/`, `Persistence/Schemas/`
- **Services:** Top-level `Services/`, no subfolders (all service files at root)
- **DesignSystem:** Top-level `DesignSystem/`, no subfolders

### Type Names
- **Views:** PascalCase ending in `View` (e.g., `DashboardView`, `DrinkTypeGridView`)
- **View models:** PascalCase ending in `ViewModel` (e.g., `DashboardViewModel`)
- **Models:** PascalCase, no suffix (e.g., `ConsumptionEvent`, `UserProfile`)
- **Enums:** PascalCase (e.g., `RiskLevel`, `AlcoholUnit`, `DrinkCategory`)
- **Protocols:** PascalCase, descriptive (e.g., `HealthWriting`, `NotificationScheduling`)
- **Services:** PascalCase ending in `Service` (e.g., `HealthService`, `ReminderService`)
- **Test classes:** PascalCase ending in `Tests` (e.g., `DashboardViewModelTests`, `HealthServiceTests`)

### Variable/Property Names
- **Local state:** camelCase (e.g., `volumeMl`, `customNameText`, `showAddDrink`)
- **Computed properties:** camelCase (e.g., `todayGrams`, `weeklyPct`, `riskLevel`)
- **Functions:** camelCase (e.g., `save()`, `resolveVolumeForUnit()`, `formattedAlcohol(_:)`)
- **Constants:** camelCase or SCREAMING_SNAKE_CASE if module-level (e.g., `maxRecoveredStores`, `reminderIdentifier`)

## Where to Add New Code

### New Feature
1. Create folder under `Features/<FeatureName>/`
2. Add `<FeatureName>View.swift` (required)
3. Add `<FeatureName>ViewModel.swift` if logic doesn't fit in view body
4. Add `Components/` subfolder if subviews exceed ~100 lines each or are reused
5. Add test file under `drinkpulseTests/Features/<FeatureName>/<FeatureName>ViewModelTests.swift`
6. Add UI test file under `drinkpulseUITests/Features/<FeatureName>/<FeatureName>UITests.swift` for user-facing flows
7. Register in `Features/Shell/AppTab.swift` and `RootShellView.swift` (if a main tab)

### New Domain Model
1. Create under `Domain/<ModelName>.swift`
2. If file will exceed 300 lines, split by responsibility:
   - `<ModelName>.swift` — core model
   - `<ModelName>+Validation.swift` — validators
   - `<ModelName>+Previews.swift` — preview data (if >30 lines)
   - `<ModelName>+Calculations.swift` — complex math
3. Add unit tests under `drinkpulseTests/Domain/<ModelName>Tests.swift` (100% coverage target)
4. If SwiftData `@Model`, ensure CloudKit-safe (no `.unique`, all properties optional/defaulted, `uuid` + `modifiedDate`)

### New Service
1. Create `Services/<ServiceName>Service.swift` (the service class)
2. Create `Services/<Capability>.swift` (the protocol)
3. Create `Services/<Framework><Service>Adapter.swift` (real adapter)
4. Create `Services/UITest<ServiceName>.swift` (test stub)
5. Add unit tests under `drinkpulseTests/Services/<ServiceName>ServiceTests.swift` (≥85% coverage)
6. Export via `@Entry` custom environment key if needed (e.g., `HealthServiceEnvironment.swift`)

### New Calculation or Pure Function
1. If domain-specific, add to model file or create `<Name>+Logic.swift` extension
2. Keep pure functions in extensions so they can be tested in isolation
3. Name calculator types `<Subject><Operation>Calculator`
4. Add unit tests in corresponding test directory

### New DesignSystem Component
1. Add to `DesignSystem/DP<ComponentName>.swift`
2. Keep focused — one component per file or closely related in one
3. If reused across features, keep in DesignSystem; if feature-specific, keep in feature's `Components/`

## Special Directories

### UITestSeed (Fixture Seeding)
**Purpose:** Create in-memory store with fixture data when `-dp_uitest` launch argument is present.
**Generated:** Yes (populated by `UITestSeed.seedFixtures(into:)` on app start if `-dp_uitest` flag)
**Committed:** UITestSeed files are committed; in-memory data is ephemeral.
**Update when:** New domain models introduced or new UI test scenarios need baseline data.

### Domain/Persistence/Schemas (Versioned Snapshots)
**Purpose:** Frozen snapshots of schema versions; one per major structural change.
**Versions:** V1 (original), V2 (CloudKit-ready), V3 (consumptionDate rename + creationDate), V4 (healthKitUUID)
**Committed:** Yes (immutable once shipped).
**Update when:** Adding a field to a model:
  1. Freeze current schema as new `VersionedSchema` (e.g., V5 if needed)
  2. Add field to live model
  3. Create `MigrationStage` to backfill or default
  4. Register in `MigrationPlan`
  
See ADR-0009: never edit a shipped `VersionedSchema` in place (causes "model version unknown" on device).

### RecoveredStores (Corruption Recovery)
**Purpose:** Timestamped snapshots of corrupted store files (non-destructive fallback).
**Generated:** Yes (on store open failure); located in `Application Support/RecoveredStores/`
**Committed:** No.
**Retention:** At most 3 snapshots; older ones trimmed by `trimRecoveredStores()`.
**Inspect manually:** Only if troubleshooting genuine store corruption (should not happen with migration plan in place).

### Assets.xcassets
**Purpose:** Images, app icon, symbol sets, color sets.
**Generated:** No (maintained in Xcode).
**Committed:** Yes.

---

*Structure analysis: 2026-08-02*
