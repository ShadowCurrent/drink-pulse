---
last_mapped_commit: 8f0cefeb8c0f6f0169a34fe15b31dce3c8005d57
last_mapped_at: 2026-11-18
---
# Codebase Structure

**Analysis Date:** 2026-11-18

## Directory Layout

```
drinkpulse/                       # repo root
├── drinkpulse/                   # app target sources (file-system synchronized)
│   ├── drinkpulseApp.swift       # @main entry, container load, onboarding gate
│   ├── UITestSeed.swift          # -dp_uitest launch-arg seeding (test only)
│   ├── UITestSeed+Fixtures.swift # UI test fixture data
│   ├── drinkpulse.entitlements   # app entitlements
│   ├── Assets.xcassets/          # colors (Risk*, SecondaryText, LaunchBackground), icons
│   ├── AppIcon.icon/             # app icon source
│   ├── Diagnostics/              # #if DEBUG view-load timing
│   ├── DesignSystem/             # tokens, shared components, modifiers
│   ├── Domain/                   # entities, pure calculations, persistence, data transfer
│   ├── Features/                 # one folder per feature (View, VM, Components/)
│   └── Services/                 # protocol-wrapped platform capabilities
├── drinkpulseTests/              # unit tests, mirrors drinkpulse/ (Swift Testing + legacy XCTest)
├── drinkpulseUITests/            # XCUITest, mirrors Features/
├── drinkpulse.xcodeproj/         # project, shared schemes in xcshareddata/xcschemes
├── docs/                         # architecture.md, domain.md, DEVLOG.md, decisions/ (ADRs), plans/ (NNNN-*)
├── .planning/                    # GSD planning: PROJECT.md, ROADMAP.md, STATE.md, phases/, milestones/, codebase/
├── .claude/                      # agent context (context/current-focus.md, open-questions.md), hooks, worktrees
├── graphify-out/                 # generated knowledge-graph output (dated folders); generated
├── build/                        # xcodebuild derived output (generated, not committed)
├── AGENTS.md / CLAUDE.md         # project instructions (CLAUDE.md imports AGENTS.md)
├── README.md, LICENSE
└── drinkcontrol.csv, drinkpulse-backup-2026-06-12.json   # local data samples at repo root
```

## Directory Purposes

**`drinkpulse/Domain/`:**
- Purpose: SwiftData entities and pure-Swift domain logic. No UI imports.
- Contains: `@Model` classes, value types, calculators, persistence bootstrap, backup/restore.
- Key files:
  - `drinkpulse/Domain/ConsumptionEvent.swift`, `DrinkTemplate.swift`, `UserProfile.swift` (entities)
  - `drinkpulse/Domain/AlcoholUnit.swift`, `UnitSystem.swift`, `UnitSystem+Volume.swift`, `UnitSystem+ServingLabels.swift` (units)
  - `drinkpulse/Domain/GuidelineChoice.swift`, `GuidelineChoice+Limits.swift`, `GuidelineChoice+Display.swift`, `GuidelineChoice+Selectable.swift`, `GuidelineLimits.swift`, `RiskLevel.swift` (guidelines)
  - `drinkpulse/Domain/WeeklySummaryCalculator.swift`, `CustomNameSuggestionFilter.swift`, `Currency.swift`, `DrinkCategory.swift`, `BiologicalSex.swift`
- Subfolders:
  - `drinkpulse/Domain/Persistence/`: `StoreBootstrap.swift`, `MigrationPlan.swift`, `UserProfileStore.swift`, `RecordDeduplicator.swift`, `ContainerLoadState.swift`, `StartupError.swift`
  - `drinkpulse/Domain/Persistence/Schemas/`: `SchemaV1.swift` through `SchemaV4.swift` (frozen snapshots V1–V3, live V4)
  - `drinkpulse/Domain/DataTransfer/`: `ExportBundle.swift`, `BackupExport.swift`, `BackupDocument.swift`, `DataImporter.swift`, `DrinkControlImporter.swift`, `ExportRecord.swift`, `ProfileRecord.swift`, `TemplateRecord.swift`, `ImportResult.swift`, `ImportError.swift`

**`drinkpulse/Features/`:**
- Purpose: User-facing features. One folder each.
- Feature folders and entry views:
  - `Shell/`: `RootShellView.swift` (tabs), `AppTab.swift`, `StartupErrorView.swift`, `Components/`
  - `Dashboard/`: `DashboardView.swift`, `DashboardViewModel.swift`, `DashboardView+Previews.swift`, `Components/`
  - `Insights/`: `InsightsView.swift`, `InsightsViewModel.swift` (+ `+Charts`, `+Formatting`, `+HealthMetrics`), `InsightsPeriod.swift`, `InsightsChartModels.swift`, `InsightsDataGenerator.swift`, `Calendar+Days.swift`, `Components/`
  - `History/`: `HistoryView.swift`, `HistoryViewModel.swift`, `HistoryListQueryView.swift`, `HistoryCalendarQueryView.swift`, `HistorySegment.swift`, `EditEventView.swift`, `Components/` (rows, calendar, edit sections, context menu)
  - `AddDrink/`: `AddDrinkView.swift`, `DrinkTypeGridView.swift`, `DrinkDetailInputView.swift` (+ `+Logic`), `DrinkTypeGrid.swift`, `DrinkTypePreset.swift` (+ `+FermentedPresets`, `+MixedPresets`, `+SpiritPresets`), `Components/`
  - `Onboarding/`: `OnboardingView.swift`, `OnboardingViewModel.swift`, `Components/`
  - `Settings/`: `SettingsView.swift`, `AppVersionInfo.swift`, `Components/` (`DataSection`, `HealthSection`, `ReminderSection`, `WeeklySummarySection`, `GuidelinePickerSheet`, ...)

**`drinkpulse/DesignSystem/`:**
- Purpose: Shared visual tokens and components. Features must not hard-code colors or motion.
- Key files: `DPColors.swift`, `DPSemanticColors.swift`, `DPBrand.swift`, `DPGlass.swift`, `DPMotion.swift`, `DPMotionProbe.swift` (test-only), `DPAdaptiveStack.swift`, `DPArcProgress.swift`, `DPLargeTitle.swift`, `RiskLevel+Color.swift`, `AppStorageKeys.swift`

**`drinkpulse/Services/`:**
- Purpose: Protocol-wrapped platform capabilities.
- Key files: `ReminderService.swift`, `WeeklySummaryService.swift`, `NotificationScheduling.swift`, `NotificationActionHandler.swift`, `HealthService.swift`, `HealthWriting.swift`, `HealthKitAdapter.swift`, `HealthWriteHooks.swift`, `HealthServiceEnvironment.swift`, `UITestHealthStore.swift`, `UITestNotificationCenter.swift`

**`drinkpulse/Diagnostics/`:**
- Purpose: Dev-only instrumentation. Contains `ViewLoadLogger.swift`.

**`drinkpulseTests/`:**
- Purpose: Unit tests mirroring `drinkpulse/`.
- Layout: `DesignSystem/`, `Diagnostics/`, `Domain/` (+ `DataTransfer/Fixtures/`, `Persistence/`), `Features/<X>/`, `Performance/`, `Services/` (includes `FakeHealthStore.swift`, `SlowNotificationCenter.swift` fakes).

**`drinkpulseUITests/`:**
- Purpose: XCUITest end-to-end flows.
- Layout: `Features/<X>/` for AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell. Accessibility audit helpers (`AccessibilityAuditSupport.swift`, `AccessibilityAuditOcclusion.swift`, `AccessibilityAuditChartMarks.swift`) live under `Features/Shell/`.

**`docs/`:**
- `architecture.md`, `domain.md`, `DEVLOG.md` (append-only), `decisions/` (ADRs `0001`–`0013` plus `README.md`), `plans/` (`0001-*` to `0038-*`, plus `INDEX.md`, `README.md`).

**`.planning/`:**
- `PROJECT.md`, `ROADMAP.md`, `STATE.md`, `RETROSPECTIVE.md`, `MILESTONES.md`, `WINDOWS.md`, `config.json`, `state.json`.
- `phases/`: active phase artifacts. `milestones/`: archived `v1.1`–`v1.4` phase folders. `codebase/`: these mapping documents. Also `quick/`, `debug/`, `todos/`, `research/`, `intel/`, `graphs/`.

## Key File Locations

**Entry Points:**
- `drinkpulse/drinkpulseApp.swift`: `@main` app, container load, onboarding gate.
- `drinkpulse/Features/Shell/RootShellView.swift`: main tab shell and add-drink sheet.

**Configuration:**
- `drinkpulse.xcodeproj/project.pbxproj`: build settings (`SWIFT_VERSION = 6.0`, deployment target iOS 27.0). Read via Xcode MCP build settings, do not parse directly.
- `drinkpulse/drinkpulse.entitlements`: entitlements.
- `drinkpulse/Assets.xcassets/`: colors and icons.
- `drinkpulse/DesignSystem/AppStorageKeys.swift`: all `@AppStorage` / `UserDefaults` keys.

**Core Logic:**
- `drinkpulse/Domain/`: calculations, guidelines, persistence, data transfer.
- `drinkpulse/Features/*/…ViewModel.swift`: presentation logic.

**Persistence:**
- `drinkpulse/Domain/Persistence/StoreBootstrap.swift`: container creation, recovery.
- `drinkpulse/Domain/Persistence/MigrationPlan.swift`: stages.

**Testing:**
- `drinkpulseTests/`: unit tests.
- `drinkpulseUITests/`: UI tests.

## Naming Conventions

**Files:**
- Views: `<Name>View.swift` (e.g. `DashboardView.swift`).
- View models: `<Feature>ViewModel.swift`, extensions `<Feature>ViewModel+<Concern>.swift` (e.g. `InsightsViewModel+Charts.swift`).
- Domain type extensions: `<Type>+<Concern>.swift` (e.g. `GuidelineChoice+Limits.swift`, `UnitSystem+Volume.swift`).
- Previews: `<Name>+Previews.swift` when long.
- Accessibility variants: `<Name>+Accessibility.swift` (e.g. `WeekdayBarChart+Accessibility.swift`).
- Schemas: `SchemaV<N>.swift`.
- Tests: `<Subject>Tests.swift`; suffixes for topics (e.g. `HealthServiceOrderingTests.swift`, `WeeklySummaryCompletedWeekTests.swift`, `StoreBootstrapTests+Rollback`).
- Design system: `DP` prefix (e.g. `DPColors.swift`, `DPMotion.swift`).

**Directories:**
- Feature folders: PascalCase singular/plural noun (`Dashboard`, `AddDrink`, `History`).
- Subfolder for feature-local subviews: `Components/`.
- Test folders mirror source folders exactly.
- Docs plans: `NNNN-kebab-title/` (zero-padded 4 digits).

**Types and symbols:**
- Domain types: nouns (`ConsumptionEvent`, `GuidelineLimits`).
- Services: `<Capability>Service` (`ReminderService`, `HealthService`).
- Adapters: `<Thing>Adapter` (`HealthKitAdapter`). UI-test fakes: `UITest<Thing>` (`UITestHealthStore`).
- `AppStorage` keys: `dp_` prefix (e.g. `dp_onboarding_done`).

## Where to Add New Code

**New Feature:**
- Primary code: `drinkpulse/Features/<Feature>/` with `<Feature>View.swift` and `<Feature>ViewModel.swift` if logic is non-trivial.
- Feature subviews: `drinkpulse/Features/<Feature>/Components/`.
- Tests: `drinkpulseTests/Features/<Feature>/<Feature>ViewModelTests.swift`.
- UI test: `drinkpulseUITests/Features/<Feature>/` (required for user-facing work).
- Tab or sheet entry: wire in `drinkpulse/Features/Shell/RootShellView.swift`. Ask which navigation context it belongs to first.

**New Component (feature-local):**
- `drinkpulse/Features/<Feature>/Components/<Name>.swift`.

**Shared UI component or token:**
- `drinkpulse/DesignSystem/<Name>.swift`. Keep to SwiftUI only.

**New Domain calculation or rule:**
- `drinkpulse/Domain/<Name>.swift`, tests in `drinkpulseTests/Domain/<Name>Tests.swift`. Domain requires 100% coverage. Calculation changes need hand verification.

**New SwiftData field or model shape:**
- Add a new `SchemaVN` snapshot under `drinkpulse/Domain/Persistence/Schemas/` and a `MigrationStage` in `MigrationPlan.swift`. Do not edit the shipped version. Ask whether migration is needed first.

**New platform capability (notifications, Health, file IO):**
- Protocol plus adapter plus `@MainActor` service in `drinkpulse/Services/`. Fake in `drinkpulseTests/Services/`. Environment injection through `drinkpulse/Services/HealthServiceEnvironment.swift` pattern if shared app-wide.

**Shared helpers:**
- Domain helpers: `drinkpulse/Domain/`.
- View helpers: `drinkpulse/DesignSystem/`.

**Import / export:**
- `drinkpulse/Domain/DataTransfer/`. Keep the bundle version and LWW rules.

**Diagnostics:**
- Dev-only: `drinkpulse/Diagnostics/`, wrapped in `#if DEBUG`.

**New file-level rules:**
- Keep each Swift file under 300 lines (aim ~200). Split SwiftUI views into `Components/`, view models via `+Concern.swift` extensions.
- Test files go into the folder mirroring the source; never the target root.

## Special Directories

**`build/`:**
- Purpose: `xcodebuild` derived output and coverage logs (`build/Logs/Test/*.xcresult`).
- Generated: Yes. Committed: No.

**`graphify-out/`:**
- Purpose: Generated knowledge-graph output by date, plus `cache/ast/`.
- Generated: Yes. Committed: Check `.gitignore` before relying on it.

**`drinkpulse.xcodeproj/xcuserdata/`:**
- Purpose: Per-user Xcode state (breakpoints, scheme state).
- Generated: Yes. Committed: No.

**`.claude/worktrees/`:**
- Purpose: Agent git worktrees. Build and test there with `xcodebuild`, not Xcode MCP.
- Generated: Yes. Committed: No.

**`drinkpulse/AppIcon.icon/`:**
- Purpose: Icon Composer source for the app icon.
- Generated: No. Committed: Yes.

**`drinkpulse/UITestSeed*.swift`:**
- Purpose: Test-only seeding, active only under `-dp_uitest`. Lives in the app target, so keep all paths gated.

**Root data files (`drinkcontrol.csv`, `drinkpulse-backup-2026-06-12.json`):**
- Purpose: Local import samples. Contain personal data. Do not quote or commit new copies.

---

*Structure analysis: 2026-11-18*
