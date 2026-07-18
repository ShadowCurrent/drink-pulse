# Codebase Structure

**Analysis Date:** 2026-07-18

## Directory Layout

```
drinkpulse/                              # Main app target
├── drinkpulseApp.swift                  # @main entry point; ModelContainer, onboarding gate, HealthService injection
├── UITestSeed.swift                     # UI test fixture seeding and in-memory store creation (gate: -dp_uitest)
├── UITestSeed+Fixtures.swift            # Test data builders
│
├── Features/                            # Feature modules (one folder per screen/flow)
│   ├── Shell/
│   │   ├── RootShellView.swift          # Tab bar and sheet container; UserProfile guard
│   │   └── AppTab.swift                 # Tab enum definition
│   │
│   ├── Dashboard/                       # Home tab
│   │   ├── DashboardView.swift          # Layout, data fetch, VM injection
│   │   └── DashboardViewModel.swift     # Aggregates: today/weekly/monthly grams, risk, streaks
│   │
│   ├── AddDrink/                        # Log-a-drink flow (type grid → detail form)
│   │   ├── AddDrinkView.swift           # NavigationStack wrapper; dismissSheet environment
│   │   ├── DrinkTypeGridView.swift      # Category grid; navigation to detail
│   │   ├── DrinkTypePreset.swift        # Drink template struct; category grouping; volume/ABV presets
│   │   ├── DrinkTypePreset+*.swift      # Category-specific presets (Fermented, Spirits, Mixed)
│   │   ├── DrinkDetailInputView.swift   # Form: volume, ABV, quantity, date, notes, price, custom name
│   │   └── DrinkDetailInputView+Logic.swift  # `save()` and pure calculators (testable)
│   │
│   ├── History/                         # Past events (calendar view)
│   │   ├── HistoryView.swift            # Calendar picker + event list by day
│   │   └── [other history views]
│   │
│   ├── Insights/                        # Trends (area chart, bars, health metrics)
│   │   ├── InsightsView.swift           # Dashboard for analytics
│   │   └── [other insights views]
│   │
│   ├── Settings/                        # Profile editor, guidelines, data export/import
│   │   ├── SettingsView.swift           # Root settings screen
│   │   ├── ProfileEditorView.swift      # Edit profile (age, sex, weight, guideline, unit, currency)
│   │   └── [other settings views]
│   │
│   └── Onboarding/                      # Initial profile creation flow
│       ├── OnboardingView.swift         # Multi-step profile setup
│       └── [other onboarding views]
│
├── Domain/                              # Data models, calculations, import/export
│   ├── ConsumptionEvent.swift           # @Model: single logged drink (identity, LWW, calculation methods)
│   ├── DrinkTemplate.swift              # @Model: reusable preset
│   ├── UserProfile.swift                # @Model: singleton user settings
│   ├── AlcoholUnit.swift                # Enum: display mode (standard drinks, UK units, grams) + density
│   ├── BiologicalSex.swift              # Enum: sex for guideline limits
│   ├── DrinkCategory.swift              # Enum: beer, wine, spirit, etc.
│   ├── GuidelineChoice.swift            # Enum: guideline selection (WHO, country profiles)
│   ├── GuidelineChoice+Display.swift    # Guideline display names, images
│   ├── GuidelineChoice+Limits.swift     # Limit calculation (daily/weekly for sex/weight/custom goal)
│   ├── GuidelineLimits.swift            # Value type: daily/weekly limit thresholds
│   ├── RiskLevel.swift                  # Enum: low/caution/exceeded
│   ├── UnitSystem.swift                 # Enum: metric/imperial
│   ├── UnitSystem+ServingLabels.swift   # Serving name resolution (e.g., "25 ml", "1 oz")
│   ├── UnitSystem+Volume.swift          # Volume conversion and display
│   ├── Currency.swift                   # Currency enum + catalog
│   │
│   ├── DataTransfer/                    # Import/export
│   │   ├── BackupDocument.swift         # File-backed export format metadata
│   │   ├── BackupExport.swift           # Export builder (JSON structure)
│   │   ├── ExportBundle.swift           # Export file container
│   │   ├── ExportRecord.swift           # Single exportable record (event, template, profile)
│   │   ├── DataImporter.swift           # Generic import logic; validates + inserts records
│   │   ├── DrinkControlImporter.swift   # DrinkControl JSON parser (migration from old app)
│   │   ├── ImportError.swift            # Typed errors (invalidFormat, tooOld, versionMismatch, etc.)
│   │   ├── ImportResult.swift           # Success count summary
│   │   ├── ProfileRecord.swift          # Serializable UserProfile snapshot
│   │   └── TemplateRecord.swift         # Serializable DrinkTemplate snapshot
│   │
│   └── Persistence/                     # Store setup, migration, recovery
│       ├── StoreBootstrap.swift         # ModelContainer creation, recovery, CloudKit config
│       ├── MigrationPlan.swift          # Versioned schemas (V1, V2, V3) + migration stages
│       ├── SchemaMigration.swift        # Custom stage logic (backfill uuid, modifiedDate, etc.)
│       ├── UserProfileStore.swift       # Singleton UserProfile fetch-or-create + de-dup
│       └── RecordDeduplicator.swift     # Cross-device de-dup by uuid + LWW
│
├── Services/                            # Platform capability wrappers
│   ├── HealthService.swift              # Mirrors logged drinks to Apple Health (best-effort, serialized)
│   ├── HealthServiceEnvironment.swift   # @Entry custom environment key for HealthService
│   ├── HealthWriteHooks.swift           # Gated write/update/delete hooks (plan-0036, ADR-0011)
│   ├── HealthKitAdapter.swift           # Real HKHealthStore wrapper
│   ├── HealthWriting.swift              # Protocol abstraction (HealthKitAdapter + UITestHealthStore conform)
│   ├── UITestHealthStore.swift          # Non-prompting in-memory stub for UI tests
│   │
│   ├── ReminderService.swift            # Schedules/cancels drink-log reminders
│   ├── NotificationScheduling.swift     # Protocol abstraction (UserNotificationCenter)
│   ├── NotificationActionHandler.swift  # Delegate for handling tapped reminder (routes to Add Drink)
│   └── UITestNotificationCenter.swift   # Test stub for notifications
│
├── DesignSystem/                        # Shared design tokens, components, modifiers
│   ├── DPBrand.swift                    # Typography, spacing, corner radius constants
│   ├── DPColors.swift                   # Semantic colors (primary, accent, backgrounds, etc.)
│   ├── DPSemanticColors.swift           # Alternative name/alias helpers
│   ├── DPLargeTitle.swift               # Reusable large title view modifier
│   ├── DPGlass.swift                    # Liquid Glass background effect (iOS 26)
│   ├── DPArcProgress.swift              # Reusable arc progress indicator
│   ├── RiskLevel+Color.swift            # Risk level → color mapping
│   └── AppStorageKeys.swift             # @AppStorage key constants (onboardingDone, colorScheme, etc.)
│
└── Assets.xcassets/                     # Image assets, app icon, colors, symbol sets

drinkpulseTests/                         # Unit tests (mirrors source structure)
├── Domain/
│   ├── AlcoholUnitTests.swift
│   ├── GuidelineChoiceTests.swift
│   ├── ConsumptionEventTests.swift
│   ├── RiskLevelTests.swift
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
│   │   └── DrinkDetailInputViewTests.swift
│   │
│   ├── History/
│   │   └── [history tests]
│   │
│   ├── Insights/
│   │   └── [insights tests]
│   │
│   ├── Onboarding/
│   │   └── [onboarding tests]
│   │
│   └── Settings/
│       └── [settings tests]
│
├── Performance/
│   └── PerformanceTests.swift
│
└── Services/
    ├── HealthServiceTests.swift
    └── ReminderServiceTests.swift

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
**Key files:** Each feature has at least one view; larger features (e.g., AddDrink, History) may have multiple subviews or a components folder.

### Domain
**Purpose:** Core data models, business logic, calculations, and persistence bootstrap.
**Contains:** SwiftData models (`@Model` classes), pure value types (enums, structs), calculation functions, import/export logic, schema versioning.
**Subdirectories:**
- **`DataTransfer/`**: File import/export, JSON parsing, record serialization.
- **`Persistence/`**: Store setup (StoreBootstrap), versioned schemas, migration stages, deduplication, recovery.

### Services
**Purpose:** Platform capability wrappers (notifications, Health, file I/O) behind protocols for testability.
**Contains:** Service classes (`@MainActor final class`), protocol abstractions, real adapters, test stubs.
**Pattern:** Each capability has a service class, a protocol, a real adapter, and optional test stub. Services inject the protocol via `init()` parameter (defaulting to production implementation).

### DesignSystem
**Purpose:** Shared design tokens, reusable components, and visual constants.
**Contains:** Color tokens, typography constants, spacing, corner radii, reusable view modifiers, shared UI components.
**Key files:** `DPColors`, `DPBrand`, `DPGlass` (Liquid Glass), `DPArcProgress`, `RiskLevel+Color`.

## Key File Locations

### Entry Points
- `drinkpulseApp.swift`: @main app, ModelContainer creation, onboarding gate.
- `Features/Shell/RootShellView.swift`: Tab navigation, sheet container, UserProfile guard.
- `Features/Onboarding/OnboardingView.swift`: Initial profile creation flow.

### Configuration
- `Domain/Persistence/StoreBootstrap.swift`: ModelContainer config, CloudKit container ID, recovery logic.
- `Domain/Persistence/MigrationPlan.swift`: Versioned schemas and migration stages.
- `DesignSystem/AppStorageKeys.swift`: @AppStorage key constants.
- `DesignSystem/DPBrand.swift`: Typography, spacing, corner radius.

### Core Logic
- `Domain/ConsumptionEvent.swift`: Drink log model, calculation methods.
- `Domain/GuidelineChoice*.swift`: Guideline engine, limit derivation.
- `Domain/AlcoholUnit.swift`: Display unit, density calculation.
- `Features/Dashboard/DashboardViewModel.swift`: Aggregates (today/weekly/monthly grams), risk levels.
- `Features/AddDrink/DrinkDetailInputView+Logic.swift`: Form save logic, calculation helpers.

### Testing
- `drinkpulseTests/Domain/`: Unit tests for models, calculations, import/export, persistence.
- `drinkpulseTests/Features/<Name>/`: Unit tests for view model logic (not layout).
- `drinkpulseTests/Services/`: Unit tests for service logic via mocked protocols.
- `drinkpulseUITests/Features/<Name>/`: UI tests for user-facing flows.

## Naming Conventions

### Files
- **Views:** `<FeatureName>View.swift` (e.g., `DashboardView.swift`, `DrinkTypeGridView.swift`)
- **View models:** `<FeatureName>ViewModel.swift` (e.g., `DashboardViewModel.swift`)
- **View logic extensions:** `<ViewName>+Logic.swift` (e.g., `DrinkDetailInputView+Logic.swift`)
- **Previews:** `<ViewName>+Previews.swift` (if extracted; optional if ≤30 lines in the main file)
- **Models:** PascalCase, no suffix (e.g., `ConsumptionEvent.swift`, `DrinkTemplate.swift`)
- **Services:** `<ServiceName>Service.swift` (e.g., `HealthService.swift`, `ReminderService.swift`)
- **Protocols:** `<Capability>` or `<ServiceName>Protocol` (e.g., `HealthWriting.swift`, `NotificationScheduling.swift`)
- **Adapters:** `<Framework><Service>Adapter.swift` (e.g., `HealthKitAdapter.swift`)
- **Test stubs:** `UITest<Name>.swift` (e.g., `UITestHealthStore.swift`, `UITestNotificationCenter.swift`)
- **Constants/helpers:** PascalCase if a type, camelCase if a standalone function (e.g., `AppStorageKeys.swift`, `RiskLevel+Color.swift`)

### Directories
- **Features:** PascalCase, one per feature (e.g., `Dashboard/`, `AddDrink/`, `Settings/`)
- **Subfolders in features:** `Components/` (for extracted subviews), `PreviewContent/` (if needed for preview data)
- **Domain subdirs:** `DataTransfer/`, `Persistence/`
- **Services:** Top-level `Services/`, no subfolders (all ~10 files)
- **DesignSystem:** Top-level `DesignSystem/`, no subfolders

### Type Names
- **Views:** PascalCase ending in `View` (e.g., `DashboardView`, `DrinkTypeGridView`)
- **View models:** PascalCase ending in `ViewModel` (e.g., `DashboardViewModel`)
- **Models:** PascalCase, no suffix (e.g., `ConsumptionEvent`, `UserProfile`)
- **Enums:** PascalCase (e.g., `RiskLevel`, `AlcoholUnit`, `DrinkCategory`)
- **Protocols:** PascalCase, often descriptive (e.g., `HealthWriting`, `NotificationScheduling`)
- **Services:** PascalCase ending in `Service` (e.g., `HealthService`, `ReminderService`)
- **Test classes:** PascalCase ending in `Tests` (e.g., `DashboardViewModelTests`, `HealthServiceTests`)

### Variable/Property Names
- **Local state:** camelCase (e.g., `volumeMl`, `customNameText`, `showAddDrink`)
- **Computed properties:** camelCase (e.g., `todayGrams`, `weeklyPct`, `riskLevel`)
- **Functions:** camelCase (e.g., `save()`, `resolveVolumeForUnit()`, `formattedAlcohol(_:)`)
- **Constants:** camelCase or SCREAMING_SNAKE_CASE if module-level (e.g., `maxRecoveredStores`, `defaultContainerID`)

## Where to Add New Code

### New Feature
1. Create folder under `Features/<FeatureName>/`
2. Add `<FeatureName>View.swift` (required)
3. Add `<FeatureName>ViewModel.swift` if logic doesn't fit in view body
4. Add `Components/` subfolder if subviews exceed ~100 lines each
5. Add test file under `drinkpulseTests/Features/<FeatureName>/<FeatureName>ViewModelTests.swift`
6. Add UI test file under `drinkpulseUITests/Features/<FeatureName>/<FeatureName>UITests.swift` for user-facing flows
7. Register in `Features/Shell/AppTab.swift` and `RootShellView.swift` (if a main tab)

**Example:**
```
Features/Favorites/
├── FavoritesView.swift
├── FavoritesViewModel.swift
└── Components/
    └── FavoriteCard.swift
```

### New Domain Model
1. Create under `Domain/<ModelName>.swift`
2. If the file will exceed 300 lines, split by responsibility:
   - `<ModelName>.swift` — core model
   - `<ModelName>+Validation.swift` — validators
   - `<ModelName>+Previews.swift` — preview data (if >30 lines)
   - `<ModelName>+Calculations.swift` — complex math (if any)
3. Add unit tests under `drinkpulseTests/Domain/<ModelName>Tests.swift`
4. If the model is a SwiftData `@Model`, ensure it follows CloudKit-safe rules (see CLAUDE.md):
   - No `@Attribute(.unique)`
   - All stored properties optional or defaulted
   - Carry `uuid` + `modifiedDate` for identity and LWW

**Example:**
```
Domain/
├── ConsumptionEvent.swift
└── ConsumptionEvent+Previews.swift

drinkpulseTests/Domain/
└── ConsumptionEventTests.swift
```

### New Service
1. Create `Services/<ServiceName>Service.swift` (the service class)
2. Create `Services/<Capability>.swift` (the protocol)
3. Create `Services/<Framework><Service>Adapter.swift` (real adapter)
4. Create `Services/UITest<ServiceName>.swift` (test stub, if applicable)
5. Add unit tests under `drinkpulseTests/Services/<ServiceName>ServiceTests.swift`
6. Export via `@Entry` custom environment key if needed by views (e.g., `HealthServiceEnvironment.swift`)

**Example:**
```
Services/
├── HealthService.swift
├── HealthWriting.swift
├── HealthKitAdapter.swift
├── UITestHealthStore.swift
└── HealthServiceEnvironment.swift

drinkpulseTests/Services/
└── HealthServiceTests.swift
```

### New Calculation or Pure Function
1. If domain-specific, add to the model file or create a `<Name>+Logic.swift` extension
2. Keep pure functions in extensions (e.g., `DrinkDetailInputView+Logic.swift`) so they can be tested in isolation
3. Name calculator types `<Subject><Operation>Calculator` (e.g., `DrinkMassCalculator`)
4. Add unit tests in the corresponding test directory

**Example:**
```
Features/AddDrink/
└── DrinkDetailInputView+Logic.swift
    nonisolated enum DrinkMassCalculator { ... }

drinkpulseTests/Features/AddDrink/
└── DrinkDetailInputViewTests.swift
    func test_massGrams_calculatesPhysicalDensity() { ... }
```

### New DesignSystem Component
1. Add to `DesignSystem/DP<ComponentName>.swift`
2. Keep focused — one component or token per file (or closely related tokens in one file)
3. If reused across multiple features, keep it in DesignSystem; if feature-specific, keep it in the feature's `Components/` folder

**Example:**
```
DesignSystem/
└── DPMyComponent.swift

# vs. feature-specific:

Features/Dashboard/Components/
└── StreakCard.swift
```

## Special Directories

### UITestSeed (Generated at Runtime)
**Purpose:** Create in-memory store with fixture data when `-dp_uitest` launch argument is present.
**Generated:** Yes (populated by `UITestSeed.seedFixtures(into:)` on app start)
**Committed:** No. The seed files (`UITestSeed.swift`, `UITestSeed+Fixtures.swift`) are committed; the in-memory data is ephemeral.
**When to touch:** Add fixture builders when new domain models are introduced or when new UI test scenarios need baseline data.

### Assets.xcassets
**Purpose:** Images, app icon, symbol sets, color sets.
**Generated:** No (maintained in Xcode).
**Committed:** Yes.

### Domain/Persistence (Migration + Schema History)
**Purpose:** Store bootstrap, versioned schemas, migration stages, recovery logic.
**Committed:** Yes. Schema versions are frozen snapshots; never edit a shipped version in place.
**When to touch:** When adding a new field to a model:
  1. Freeze the current schema as a new `VersionedSchema` (e.g., `SchemaV4`)
  2. Add the field to the live model
  3. Create a new `MigrationStage` that backfills the field (or provides a default)
  4. Register in `MigrationPlan`
  See ADR-0009 for the rule.

### RecoveredStores
**Purpose:** Timestamped snapshots of corrupted store files (non-destructive recovery fallback).
**Generated:** Yes, on store open failure. Located in `Application Support/RecoveredStores/`.
**Committed:** No.
**Retention:** At most 3 snapshots; older ones are trimmed by `StoreBootstrap.trimRecoveredStores()`.
**When touched:** Never manually. Cleared by "Delete all data" (calls `clearRecoveredStores()`). Inspected manually only if troubleshooting a genuine store corruption.

---

*Structure analysis: 2026-07-18*
