---
last_mapped_commit: 8f0cefeb8c0f6f0169a34fe15b31dce3c8005d57
last_mapped_at: 2026-11-18
---
# Coding Conventions

**Analysis Date:** 2026-11-18

## Naming Patterns

**Files:**
- One primary type per file, named after the type: `drinkpulse/Domain/ConsumptionEvent.swift`, `drinkpulse/Services/ReminderService.swift`.
- Extensions of a type use `Type+Concern.swift`: `drinkpulse/Domain/GuidelineChoice+Limits.swift`, `drinkpulse/Domain/UnitSystem+Volume.swift`, `drinkpulse/Features/Insights/InsightsViewModel+Charts.swift`.
- Feature view models split into extensions the same way: `drinkpulse/Features/Dashboard/DashboardViewModel.swift` plus `+Calculations`-style siblings; `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift`.
- Previews that are too long for the view file go to `<View>+Previews.swift`: `drinkpulse/Features/Dashboard/DashboardView+Previews.swift`, `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Previews.swift`.
- Accessibility helpers that would bloat a chart go to `<Chart>+Accessibility.swift`: `drinkpulse/Features/Insights/Components/WeekdayBarChart+Accessibility.swift`.
- Large static data split by category: `drinkpulse/Features/AddDrink/DrinkTypePreset+SpiritPresets.swift`, `DrinkTypePreset+FermentedPresets.swift`, `DrinkTypePreset+MixedPresets.swift`.
- Schema snapshots are `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` ... `SchemaV4.swift`. Never edit a shipped schema version (see AGENTS.md).
- Design-system files are prefixed `DP`: `DPColors.swift`, `DPGlass.swift`, `DPChip.swift` (`drinkpulse/Features/Dashboard/Components/DPChip.swift`), `DPMotion.swift`.
- Feature components live in a `Components/` subfolder of the feature: `drinkpulse/Features/History/Components/EventRow.swift`.
- Test files end in `Tests.swift` (unit) or `UITests.swift` (UI). Test helpers and fakes have no suffix: `drinkpulseTests/Services/FakeHealthStore.swift`, `drinkpulseTests/Services/SlowNotificationCenter.swift`, `drinkpulseTests/Domain/DataTransfer/BackupFixtureLoader.swift`.

**Types:**
- `UpperCamelCase` for all types. Enums use singular nouns (`AlcoholUnit`, `BiologicalSex`, `RiskLevel`, `DrinkCategory`, `UnitSystem`).
- View models end in `ViewModel`: `DashboardViewModel`, `HistoryViewModel`, `InsightsViewModel`, `OnboardingViewModel`.
- Services end in `Service` (`ReminderService`, `HealthService`, `WeeklySummaryService`) or are protocol-named by capability (`NotificationScheduling`, `HealthWriting`).
- SwiftUI views end in `View` (`DashboardView`, `EditEventView`), subviews/cards end in `Card`, `Row`, `Section`, `Step`, `Tile`, `Chip` (`StreakCard`, `EventRow`, `ReminderSection`, `HealthStep`, `DrinkTypeTile`).
- Test fakes use the `Fake` prefix (`FakeHealthStore`, `FakeNotificationCenter`). Test-only sample classes have no prefix.
- Error types are `enum ...: Error` or `LocalizedError`, suffixed `Error` (`ImportError`, `StartupError`) or nested as `ParseError` / `RecoveryError` inside their owner (`DrinkControlImporter.ParseError`, `StoreBootstrap.RecoveryError`).

**Functions and methods:**
- `lowerCamelCase`, verb-first for actions: `write(_:)`, `update(_:)`, `remove(_:)`, `requestAuthorization()`, `makeRequest(hour:minute:)`.
- Computed derived values are named by noun: `todayGrams`, `weeklyLimitGrams`, `effectiveRiskLevel`, `thirtyDayGrams`.
- Predicates use `is`/`has`/`should` or a clear state word: `isEnabled`, `isHealthDataAvailable`, `isToday`, `isFuture`.
- Tests use the Swift Testing style `snake_case` after `@Test func` in the Domain and Dashboard suites (`weekBarData_alwaysSevenEntries`, `alcoholGrams_quantityMultiplies`) and descriptive `lowerCamel` names elsewhere (`beerHalfLitre5Percent`, `zeroVolumeGivesZeroAlcohol`). UI tests use `test_<screen>_<behaviour>` (`test_heroCard_showsSeededConsumptionValue`). Name tests after behaviour, not implementation.

**Variables and properties:**
- `lowerCamelCase`. Units are part of the name when they are not obvious: `volumeMl`, `abv`, `weeklyGoalGrams`, `dailyLimitGrams`, `bodyWeightKg`, `volumeMl`, `priceCurrency`.
- Stored SwiftData properties keep plain names. Renames use `@Attribute(originalName:)`: `consumptionDate` maps from `timestamp` in `drinkpulse/Domain/ConsumptionEvent.swift`.
- Private storage uses `private let`/`private var` with no underscore prefix. Local `let logger` / `private let logger` per type.
- Constants use `static let` on the owning type (`ReminderService.reminderIdentifier`, `AlcoholUnit.physicalDensityGramsPerMl`, `AppStorageKeys`), not free globals. Exception: a file-private logger, `private let startupLog = Logger(...)` in `drinkpulse/drinkpulseApp.swift`.
- `AppStorage` / `UserDefaults` keys are centralised in `drinkpulse/DesignSystem/AppStorageKeys.swift`. Use these constants; do not inline key strings.

**Enum cases:**
- `lowerCamelCase` raw cases: `case grams`, `case standardDrinks`, `case who, de, uk, au, us, ca, custom` in `GuidelineChoice`. Raw string values match the case name.

## Code Style

**Formatting:**
- No `.swiftformat` or `.editorconfig` in the repo. Formatting follows Xcode defaults: 4-space indent, Xcode-generated spacing.
- Multi-line argument lists put each argument on its own line and close with `)` on its own line (see `drinkpulse/Features/Settings/Components/DataSection.swift`).
- Switch statements over enums are exhaustive; `default:` is used only when a real fallback exists (`drinkpulse/Domain/AlcoholUnit.swift`, `DrinkCategory` mapping).
- Aligned `case` / `return` columns appear in lookup tables (`AlcoholUnit.gramsPerUnit(for:)`). Keep alignment when editing such tables.
- Single-expression bodies are written with implicit return: `var todayCaloriesKcal: Int { Int(physicalGrams(todayGrams) * 7.1) }`.

**Linting:**
- No SwiftLint configuration present (`.swiftlint.yml` absent). The enforced gates are the compiler and tests, not a linter.
- Compiler is strict: `SWIFT_VERSION = 6.0` in `drinkpulse.xcodeproj/project.pbxproj`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`. Swift 6 concurrency warnings must be fixed at the source, not suppressed.
- Build must produce zero warnings (AGENTS.md quality gate).

**File size:**
- Hard ceiling 300 lines (AGENTS.md). Production code is currently under the ceiling; largest is `drinkpulse/Features/History/HistoryView.swift` (263 lines).
- Known violations in test code (not production) at analysis time:
  - `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift` (335 lines)
  - `drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Metrics.swift` (327 lines)
  - `drinkpulseTests/Services/HealthServiceTests.swift` (302 lines)
- Check with the command from AGENTS.md: `find drinkpulse drinkpulseTests drinkpulseUITests -name "*.swift" -exec wc -l {} + | awk '$1>300'`.

## Import Organization

**Order (observed):**
1. Apple system frameworks, alphabetically within the group where possible: `Foundation`, `SwiftUI`, `SwiftData`, `OSLog`, `UserNotifications`, `Testing`, `XCTest`.
2. Blank line, then `@testable import drinkpulse` (tests only), last in the block.

Examples: `drinkpulse/Features/Dashboard/DashboardView.swift` (`SwiftUI`, `SwiftData`); `drinkpulseTests/Features/Dashboard/DashboardViewModelTests.swift` (`Testing`, `Foundation`, `SwiftData`, `@testable import drinkpulse`).

**Path Aliases:**
- Not applicable. Single Xcode module `drinkpulse`; no SwiftPM package aliases.

**Access control:**
- Tests reach internal types with `@testable import drinkpulse`. Do not make production types `public` for tests.
- Prefer `private` for helpers inside a type; use `fileprivate`/module-internal only where a sibling extension in the same module needs it.

## Concurrency and Isolation

- View models and services are `@MainActor`:
  - `@Observable @MainActor final class DashboardViewModel` (`drinkpulse/Features/Dashboard/DashboardViewModel.swift`)
  - `@MainActor final class ReminderService` (`drinkpulse/Services/ReminderService.swift`)
  - `@MainActor enum HealthWriteHooks` (`drinkpulse/Services/HealthWriteHooks.swift`)
- Protocols that cross isolation boundaries are `Sendable`: `protocol NotificationScheduling: Sendable` (`drinkpulse/Services/NotificationScheduling.swift`).
- Test doubles that mutate state use `final class ... : @unchecked Sendable` with `private(set)` recorded counters (`drinkpulseTests/Services/FakeHealthStore.swift`, `drinkpulseTests/Services/ReminderServiceTests.swift`). This is the only accepted use of `@unchecked Sendable` in tests. Production `@unchecked Sendable` appears only in `drinkpulse/Services/NotificationScheduling.swift` and UI-test adapters (`drinkpulse/Services/UITestHealthStore.swift`, `drinkpulse/Services/UITestNotificationCenter.swift`).
- Pure domain helpers that must be callable from any actor are marked `nonisolated`: `nonisolated func density(for:)` in `drinkpulse/Domain/AlcoholUnit.swift`, `nonisolated static let physicalDensityGramsPerMl`. The codebase has about 44 `nonisolated` declarations; apply it to pure value functions, not to view code.
- Concurrency patterns: `async`/`await` with `Task { }` launched from `@MainActor` context (`drinkpulse/Services/HealthWriteHooks.swift`); no Combine, no `DispatchQueue`.
- Observation: `@Observable` only. No `ObservableObject`, `@Published`, or `@StateObject` appears anywhere in `drinkpulse/`.

## State and Data Access

- Views own view models with `@State private var vm = DashboardViewModel()` (`drinkpulse/Features/Dashboard/DashboardView.swift`).
- Views read persistence with `@Query` and inject plain values into the view model in `onChange` handlers:
  ```swift
  .onChange(of: allEvents, initial: true) {
      vm.events = allEvents
  }
  .onChange(of: profiles, initial: true) {
      vm.profile = profiles.first
  }
  ```
- View models never hold a `ModelContext` (ADR-0004; AGENTS.md). Simple mutations (`insert`, `delete`) happen in the view via `@Environment(\.modelContext)`.
- Environment is read with `@Environment(\.scenePhase)`, `@Environment(\.dynamicTypeSize)`, `@Environment(\.accessibilityReduceMotion)`.
- Models are `@Model final class` with CloudKit-safe defaults: every stored property has a default or is optional, no `@Attribute(.unique)` (`drinkpulse/Domain/ConsumptionEvent.swift`).
- Value types for domain data that is not persisted (`GuidelineLimits`, `WeekBarEntry` in `drinkpulse/Features/Dashboard/DashboardViewModel.swift`, chart models in `drinkpulse/Features/Insights/InsightsChartModels.swift`).

## Error Handling

**Patterns in use:**
- Typed errors: `enum ImportError: LocalizedError` with user-facing `errorDescription` via `String(localized:)` (`drinkpulse/Domain/DataTransfer/ImportError.swift`). `enum StartupError: Error, Equatable` (`drinkpulse/Domain/Persistence/StartupError.swift`) lets tests compare cases.
- Service methods throw and the caller shows an alert or logs. Example: `ReminderSection` and `HealthSection` wrap `do { try await ... } catch { logger.error(...) }` and set a UI state flag.
- Alerts carry the error text: `.alert(String(localized: "settings.data.importError.title"), isPresented: ...)` with `Text(msg)` (`drinkpulse/Features/Settings/Components/DataSection.swift`).
- Import/parsing returns result values rather than throwing into the UI: `ImportResult` (`drinkpulse/Domain/DataTransfer/ImportResult.swift`).
- Optional-returning fetches with fallback: `(try? modelContext.fetch(descriptor)) ?? []` (`drinkpulse/Features/Settings/Components/HealthSection.swift`).

**Acceptable `try?`:**
- Only where a failure is genuinely ignorable and a comment states why. Existing example: `drinkpulse/Features/Settings/AppVersionInfo.swift` (`// try? is fine: a missing build time only drops the second line; no user data involved.`).
- Fetch-with-empty-default is accepted for read-only Settings lookups, but the failure must not hide a write. Writes must use `do/catch` and log or surface.

**Known deviations (fix when touched):**
- `drinkpulse/Features/Settings/Components/DataSection.swift` lines ~193-194: `try? modelContext.delete(model:)` in the delete-all path swallows errors without a comment or user feedback. Replace with `do/catch` that surfaces failure.
- `drinkpulse/Features/Shell/RootShellView.swift` line ~159 (`try? modelContext.save()`) swallows a save failure on a write path. AGENTS.md requires errors to be handled or surfaced.
- `drinkpulse/Services/HealthWriteHooks.swift` `Task { ...; try? context.save() }` drops save errors in a fire-and-forget task.
- Forced `try!` appears in SwiftUI `#Preview` blocks only (`drinkpulse/Features/Insights/InsightsView.swift`, `drinkpulse/Features/Shell/RootShellView.swift`, `drinkpulse/Features/Dashboard/DashboardView+Previews.swift`). Force-unwrapped `!` also appears in preview data only (`DashboardView+Previews.swift`, `WeekdayBarChart.swift`). AGENTS.md permits this. Do not add either to production code.

## Logging

**Framework:** `os.Logger` (`import OSLog`) with subsystem `com.drinkpulse.app` (AGENTS.md; about 16 `Logger(subsystem:)` declarations).

**Patterns:**
- One logger per type, stored as `private let logger = Logger(subsystem: "com.drinkpulse.app", category: "<TypeName>")`: `drinkpulse/Services/ReminderService.swift` (`category: "ReminderService"`), `drinkpulse/Features/Settings/Components/HealthSection.swift`.
- Cross-cutting categories: `category: "startup"` (`drinkpulse/drinkpulseApp.swift`), `category: "performance"` (`drinkpulse/Diagnostics/ViewLoadLogger.swift`, `drinkpulse/Features/History/HistoryView.swift`).
- Diagnostics such as `ViewLoadLogger` and `.dp_logViewLoad("Dashboard")` are compiled under `#if DEBUG` (`drinkpulse/Diagnostics/ViewLoadLogger.swift`).
- Interpolate only non-PII. Identifiers, counts, enum cases, and durations are fine. Mark anything user-related with the default `privacy: .private`. Example in use: `logger.notice("View '\(viewName, privacy: .public)' appeared in \(elapsedMs, privacy: .public) ms")` — the view name is a developer constant, not user data.
- No `print(...)` in production code. None found.
- Never log drink contents, notes, prices, body metrics, or full model objects.

## Localization

- All user-facing strings go through `String(localized:)` with dotted keys stored in `drinkpulse/Localizable.xcstrings` (English source, about 261 keys): `String(localized: "tab.home")`, `String(localized: "action.ok")`, `String(localized: "unit.standardDrinks")`.
- Key style: `<area>.<element>[.<detail>]` in lower camel: `settings.data.importError.title`, `settings.alcoholUnit.grams`, `import.error.unsupportedVersion`.
- Formatted strings use `String(format: String(localized: "key"), value)` (`drinkpulse/Domain/DataTransfer/ImportError.swift`).
- English only (AGENTS.md). Do not add other locales.
- **Known deviations:**
  - `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` (callout `Text("\(bar.label) — ...")`) builds a user-visible string with an unlocalized literal and interpolation. Move to a localized format key.
  - `drinkpulse/DesignSystem/DPLargeTitle.swift` (`Text("DrinkPulse")`) is a brand wordmark; acceptable as an unlocalized literal, but document it.
  - `drinkpulse/DesignSystem/DPGlass.swift` `Text("Glass Card")` is preview-only and is acceptable.

## Accessibility (required)

- Every interactive element gets an `accessibilityLabel`. Label-combining pattern is used on compound tiles:
  ```swift
  .accessibilityElement(children: .combine)
  .accessibilityLabel("\(label): \(value)")
  ```
  (`drinkpulse/Features/Dashboard/Components/DPChip.swift`).
- Charts provide an `accessibilityChartDescriptor` or a summary label via `+Accessibility.swift` files (`drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift`, `WeekdayBarChart+Accessibility.swift`).
- Dynamic Type: `@Environment(\.dynamicTypeSize)` branches to switch layout at accessibility sizes (`DPChip`, `DPAdaptiveStack` in `drinkpulse/DesignSystem/DPAdaptiveStack.swift`). Use `.minimumScaleFactor` only when not at an accessibility size.
- Reduce Motion: read `@Environment(\.accessibilityReduceMotion)` and gate animations; shared motion tokens live in `drinkpulse/DesignSystem/DPMotion.swift`.
- Colors come from design tokens: `Color.dpSecondaryText`, `Color.dpAmber` (`drinkpulse/DesignSystem/DPColors.swift`, `DPSemanticColors.swift`). Do not use `.secondary` on glass cards (comment in `DPChip.swift` explains the contrast audit failure).

## SwiftUI View Conventions

- Each feature view is a `struct ...: View` with `body` on top, then `// MARK: -` sections for subviews (`drinkpulse/Features/Dashboard/DashboardView.swift`: `// MARK: - Header`).
- Subviews are `private var` computed properties in the view file when short; extract to `Components/` when they grow (AGENTS.md split rule).
- Modifiers chain on `body` in this order: layout, `navigationTitle`, `onChange`, `.dp_logViewLoad(...)`.
- Glass card styling is a shared modifier: `.dpGlassCard()` (`drinkpulse/DesignSystem/DPGlass.swift`). Use it instead of re-creating background and border.
- Design system components are prefixed `DP`. Put new shared visual primitives in `drinkpulse/DesignSystem/`, feature-specific ones in `Features/<X>/Components/`.
- Every SwiftUI view has at least one `#Preview` with mock data. Multiple variants use named previews: `#Preview("Accessibility 5") { ... .dynamicTypeSize(.accessibility5) }` (`DPChip.swift`), `#Preview("Light / Dark")` (`DPGlass.swift`). 109 `#Preview` declarations across 62 files.
- Previews seed data with an in-memory container: `try! ModelContainer(for: ..., configurations: ModelConfiguration(isStoredInMemoryOnly: true))`.

## Function and Type Design

**Size:**
- Keep functions short; extract `private` helpers. View bodies that exceed a screen get split into computed subviews.

**Parameters:**
- Use labelled parameters, omit the first label when the call reads as a phrase: `fraction(consumedGrams:limitGrams:)`, `riskLevel(consumedGrams:limitGrams:)`, `write(_:)`, `save(grams:date:eventUUID:)`.
- Dependency injection is by initializer with defaults so tests can override: `ReminderService(center: FakeNotificationCenter(), defaults: makeDefaults())`, `HealthService(store: fake)`.
- `@autoclosure` is used to delay expensive defaults (`ReminderService.init(center: @autoclosure @escaping () -> ...)`).

**Return values:**
- Pure calculations return `Double`, `Int`, or value structs. Calculations never return formatted strings; formatting happens at the leaf (`formattedValue(_:guideline:)`, `AlcoholUnit.swift`).
- Optional returns for "no data": `todaySpend: Double?` returns `nil` when there are no prices.

**Enums:**
- Behaviour per case is written as exhaustive `switch` inside the enum (`AlcoholUnit`, `GuidelineChoice+Limits.swift`, `RiskLevel.from(pct:)`). Put case-specific data in computed properties or lookup `switch`es, not parallel arrays.

## Module Design

**Exports:**
- Single app module. No public API surface. Internal visibility is the default.

**Barrel Files:**
- Not used. Each file is imported by name through the module.

**Extensions:**
- Organise by concern in extension files, not by ever-growing type bodies. Examples: `GuidelineChoice.swift` + `+Display` + `+Limits` + `+Selectable`; `UnitSystem.swift` + `+ServingLabels` + `+Volume`.

**Domain rules (apply to every calculation change):**
- Grams of pure alcohol is the unit of truth. Density comes from `AlcoholUnit.density(for:)` for display-mode math and `AlcoholUnit.physicalDensityGramsPerMl` (0.789) for physical mass, calories and future BAC. Do not mix them (`drinkpulse/Domain/AlcoholUnit.swift`, `ConsumptionEvent.swift`).
- Templates and events stay separate. Editing a template never rewrites past events.
- Calculation changes require the owner's hand verification (AGENTS.md).

## Comments

**When to comment:**
- Explain why, not what. Examples in use:
  - `// Not .secondary: a hierarchical style on the glass card is drawn vibrant and fails the contrast audit (plan 11-17).` (`DPChip.swift`)
  - `// try? is fine: a missing build time only drops the second line; no user data involved.` (`AppVersionInfo.swift`)
  - `// F3 (10-DECISION-F3.md): lifecycleEpoch advances on every schedule and cancel` (`ReminderService.swift`)
- Reference plans, ADRs, or decision IDs when a rule comes from them (`plan-0025`, `ADR-0005`, `D11-26`).
- Section headers: `// MARK: - <Section>` with a dash, used heavily in view models and test files.

**JSDoc/TSDoc (Swift doc comments):**
- `///` doc comments on helpers with non-obvious behaviour: `/// Loads backup fixture JSON from the test bundle. Never reads from a repository path.` (`BackupFixtureLoader.swift`), and file-level docs in UI audit files (`AccessibilityAuditUITests.swift`).
- Do not add a file header comment (AGENTS.md).

## Test-only Hooks

- UI tests drive state through launch arguments read in `drinkpulse/UITestSeed.swift` (`-dp_uitest`, `-dp_onboarding_done`, `-dp_force_onboarding`, etc.). Hooks are gated on the `-dp_uitest` argument and must never seed real data in production paths.
- Test-only implementations of platform protocols live in production source with a `UITest` prefix because the app must run them under UI tests: `drinkpulse/Services/UITestHealthStore.swift`, `drinkpulse/Services/UITestNotificationCenter.swift`, seeds in `drinkpulse/UITestSeed+Fixtures.swift`.

---

*Convention analysis: 2026-11-18*
