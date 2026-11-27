---
last_mapped_commit: 19ce3159ee64540aaea8411fc85f24e6bea68714
last_mapped_at: 2026-11-27
---
# Codebase Structure

**Analysis Date:** 2026-11-27

## Directory Layout

```
drinkpulse/                          # repo root
├── drinkpulse/                      # app target (synchronized group)
│   ├── drinkpulseApp.swift          # @main entry
│   ├── UITestSeed.swift             # launch-arg seeding hooks (UI tests)
│   ├── UITestSeed+Fixtures.swift    # fixture data for UI tests
│   ├── Localizable.xcstrings        # String Catalog (English only)
│   ├── Info.plist, drinkpulse.entitlements
│   ├── Assets.xcassets/             # colour sets (RiskLow/Moderate/High, AccentColor), icons
│   ├── AppIcon.icon/
│   ├── Domain/                      # models, calculations, persistence, data transfer
│   ├── Features/                    # one folder per user flow
│   ├── Services/                    # system-framework wrappers behind protocols
│   ├── DesignSystem/                # tokens, shared components
│   └── Diagnostics/                 # #if DEBUG instrumentation
├── drinkpulseTests/                 # unit tests, mirrors app tree
│   ├── Domain/ (DataTransfer/, Persistence/)
│   ├── Features/ (AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell)
│   ├── Services/   DesignSystem/   Diagnostics/   Performance/
├── drinkpulseUITests/               # XCUITest, mirrors Features/
│   └── Features/ (AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell)
├── drinkpulse.xcodeproj/            # project, shared schemes in xcshareddata/xcschemes
├── docs/                            # architecture.md, domain.md, decisions/ (ADRs 0001-0013), plans/
├── .planning/                       # GSD artifacts: PROJECT.md, ROADMAP.md, codebase/, phases/
├── .claude/                         # agent context (current-focus.md, open-questions.md)
└── graphify-out/                    # generated knowledge-graph output (dated folders)
```

## Directory Purposes

**`drinkpulse/Domain/`:**
- Purpose: domain entities, pure calculations, guideline rules
- Contains: `ConsumptionEvent.swift`, `DrinkTemplate.swift`, `UserProfile.swift`, `AlcoholUnit.swift`, `GuidelineChoice*.swift`, `GuidelineLimits.swift`, `WeeklySummaryCalculator.swift`, `AlcoholFreeDay*.swift`, `RiskLevel.swift`, `UnitSystem*.swift`, `Calendar+Days.swift`, `Currency.swift`, `BiologicalSex.swift`
- Key files: `drinkpulse/Domain/ConsumptionEvent.swift`, `drinkpulse/Domain/GuidelineChoice+Limits.swift`

**`drinkpulse/Domain/Persistence/`:**
- Purpose: store bootstrap, migration, recovery
- Contains: `StoreBootstrap.swift`, `MigrationPlan.swift`, `UserProfileStore.swift`, `RecordDeduplicator.swift`, `ContainerLoadState.swift`, `StartupError.swift`
- Subfolder `Schemas/`: `SchemaV1.swift` to `SchemaV4.swift` (frozen snapshots)

**`drinkpulse/Domain/DataTransfer/`:**
- Purpose: export and import
- Contains: `BackupExport.swift`, `BackupDocument.swift`, `DataImporter.swift`, `DrinkControlImporter.swift`, `ExportBundle.swift`, `ExportRecord.swift`, `TemplateRecord.swift`, `ProfileRecord.swift`, `ImportResult.swift`, `ImportError.swift`

**`drinkpulse/Features/<Feature>/`:**
- Purpose: a single screen or flow
- Features present: `Shell`, `Dashboard`, `History`, `Insights`, `AddDrink`, `Onboarding`, `Settings`
- Each has `*View.swift`, optional `*ViewModel.swift`, `*+Previews.swift`, and `Components/`

**`drinkpulse/Services/`:**
- Purpose: platform capabilities behind protocols
- Contains: `HealthService.swift`, `HealthKitAdapter.swift`, `HealthServiceEnvironment.swift`, `HealthWriting.swift`, `HealthWriteHooks.swift`, `NotificationScheduling.swift`, `NotificationActionHandler.swift`, `ReminderService.swift`, `WeeklySummaryService.swift`, `UITestHealthStore.swift`, `UITestNotificationCenter.swift`

**`drinkpulse/DesignSystem/`:**
- Purpose: tokens, cards, motion, adaptive layout, risk palette
- Contains: `Brand.swift`, `BrandBackground.swift`, `BrandCardStyle.swift`, `BrandTypography.swift`, `DPArcProgress.swift`, `DPAdaptiveStack.swift`, `DPMotion.swift`, `DPSemanticColors.swift`, `MetricTile.swift`, `LimitGaugeRow.swift`, `RiskLevel+Status.swift`, `RiskLevel+Tone.swift`, `AppStorageKeys.swift`

**`drinkpulseTests/`:**
- Purpose: unit tests (Swift Testing and legacy XCTest)
- Mirrors: `Domain/`, `Features/<X>/`, `Services/`, `DesignSystem/`, `Diagnostics/`, `Performance/`

**`drinkpulseUITests/Features/<X>/`:**
- Purpose: end-to-end XCUITest flows driven by launch arguments

**`docs/`:**
- Purpose: architecture, domain rules, ADRs, plan history
- Key files: `docs/architecture.md`, `docs/domain.md`, `docs/decisions/README.md`, `docs/plans/INDEX.md`

## Key File Locations

**Entry Points:**
- `drinkpulse/drinkpulseApp.swift`: `@main`, container load
- `drinkpulse/Features/Shell/RootShellView.swift`: tab shell

**Configuration:**
- `drinkpulse/Info.plist`: app plist
- `drinkpulse/drinkpulse.entitlements`: CloudKit and HealthKit entitlements
- `drinkpulse/DesignSystem/AppStorageKeys.swift`: `@AppStorage` key names

**Core Logic:**
- `drinkpulse/Domain/ConsumptionEvent.swift`: pure-alcohol grams
- `drinkpulse/Domain/WeeklySummaryCalculator.swift`: weekly totals
- `drinkpulse/Features/Dashboard/DashboardViewModel.swift`: today's view model
- `drinkpulse/Features/Insights/InsightsViewModel.swift`: trends view model

**Persistence:**
- `drinkpulse/Domain/Persistence/StoreBootstrap.swift`: container config and recovery
- `drinkpulse/Domain/Persistence/MigrationPlan.swift`: migration stages

**Testing:**
- `drinkpulseTests/Domain/`: calculation tests (100% target)
- `drinkpulseUITests/Features/`: UI tests

## Naming Conventions

**Files:**
- Views: `<Name>View.swift` (e.g. `HistoryView.swift`)
- View models: `<Feature>ViewModel.swift`
- Extensions: `<Type>+<Concern>.swift` (e.g. `GuidelineChoice+Limits.swift`, `DrinkTypePreset+FermentedPresets.swift`)
- Previews: `<Name>+Previews.swift` when extracted
- Schemas: `SchemaV<N>.swift`
- Tests: `<Subject>Tests.swift`, UI tests `<Area>UITests.swift`

**Directories:**
- Feature folders: PascalCase noun (`AddDrink`, `Insights`)
- `Components/` for feature-local subviews
- Test trees mirror source trees exactly

**Types:**
- Views and VMs suffixed accordingly; Dashboard type names kept though tab is labelled Today (`drinkpulse/Features/Dashboard/`).

## Where to Add New Code

**New Feature (user flow):**
- Primary code: `drinkpulse/Features/<Feature>/<Feature>View.swift` and `<Feature>ViewModel.swift`
- Subviews: `drinkpulse/Features/<Feature>/Components/`
- Tests: `drinkpulseTests/Features/<Feature>/` and `drinkpulseUITests/Features/<Feature>/`

**New Component (shared UI):**
- Implementation: `drinkpulse/DesignSystem/`

**New Domain rule or calculation:**
- Implementation: `drinkpulse/Domain/`
- Tests: `drinkpulseTests/Domain/` (100% coverage)

**New system integration:**
- Protocol plus `@MainActor` service: `drinkpulse/Services/`
- Test double: `drinkpulseTests/Services/`

**New model field:**
- Add a `SchemaV(N+1)` in `drinkpulse/Domain/Persistence/Schemas/` and a stage in `MigrationPlan.swift`. Never edit a shipped schema.

**Utilities:**
- Shared domain helpers: `drinkpulse/Domain/` (e.g. `Calendar+Days.swift`)
- Shared UI helpers: `drinkpulse/DesignSystem/`

## Special Directories

**`drinkpulse.xcodeproj/xcuserdata/`:**
- Purpose: per-user Xcode state
- Generated: Yes
- Committed: No

**`graphify-out/`:**
- Purpose: generated knowledge-graph output and cache
- Generated: Yes
- Committed: No (ignored in `.gitignore`)

**`build/`:**
- Purpose: `-derivedDataPath` output from the documented `xcodebuild` commands
- Generated: Yes
- Committed: No

**`drinkpulse/AppIcon.icon/`:**
- Purpose: layered app icon source
- Generated: No
- Committed: Yes

---

*Structure analysis: 2026-11-27*
