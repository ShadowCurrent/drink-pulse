---
last_mapped_commit: 19ce3159ee64540aaea8411fc85f24e6bea68714
last_mapped_at: 2026-11-27
---
# Coding Conventions

**Analysis Date:** 2026-11-27

## Naming Patterns

**Files:**
- One primary type per file, named after the type: `drinkpulse/Domain/AlcoholUnit.swift`, `drinkpulse/Features/Dashboard/DashboardViewModel.swift`.
- Extensions and helpers use `Type+Concern.swift`: `drinkpulse/Domain/GuidelineChoice+Limits.swift`, `drinkpulse/Features/Insights/InsightsViewModel+Charts.swift`, `drinkpulse/Features/AddDrink/DrinkTypePreset+SpiritPresets.swift`.
- Previews live in `Type+Previews.swift` when long: `drinkpulse/Features/Dashboard/DashboardView+Previews.swift`.
- Feature folders hold SwiftUI views, view models and feature-local helpers; subviews go in `Components/`: `drinkpulse/Features/Insights/Components/`.
- Schema snapshots: `drinkpulse/Domain/Persistence/Schemas/SchemaV1.swift` ... `SchemaV4.swift`.
- Test files mirror source names with a `Tests` suffix: `drinkpulseTests/Domain/AlcoholUnitTests.swift`. Split test files use `Type+Topic`: `drinkpulseTests/Features/Dashboard/DashboardViewModelTests+Metrics.swift`.

**Types:**
- `UpperCamelCase` for types, protocols and enums. Protocols describe a capability, no `-Protocol` suffix: `HealthWriting` (`drinkpulse/Services/HealthWriting.swift`), `NotificationScheduling` (`drinkpulse/Services/NotificationScheduling.swift`).
- Enum cases are lowerCamelCase: `AlcoholUnit.grams`, `AlcoholUnit.standardDrinks` (`drinkpulse/Domain/AlcoholUnit.swift`).
- Value types are the default. Classes are used for `@Observable` view models, SwiftData `@Model` types, and test fakes.

**Functions and variables:**
- lowerCamelCase. Boolean properties read as predicates (`isAllTime`, `isToday`, `isFuture`).
- Domain functions that depend on a choice take it as a labelled argument: `unitLabel(for:)`, `density(for:)`, `gramsPerUnit(for:)`, `alcoholGrams(density:)`.
- Feature-internal helpers may be `private`; keep `private` on anything not used outside the file.

**Test names:**
- Swift Testing functions use `snake_case`-style underscores that separate subject, condition and expectation: `weekBarData_alwaysSevenEntries`, `write_doesNothing_whenDenied`, `unitLabel_standardDrinks_uk_readsUnits` (`drinkpulseTests/Domain/AlcoholUnitTests.swift`).
- XCTest UI tests use the `test_<screen>_<behaviour>` form: `test_fullLogFlow_savedEvent_appearsInHistory` (`drinkpulseUITests/Features/AddDrink/AddDrinkFlowUITests.swift`).

## Code Style

**Formatting:**
- No `.swiftformat` or `.editorconfig` in the repo. Formatting follows Xcode defaults: 4-space indentation, one declaration per line.
- Trailing closures and multi-line argument lists are common. Keep long argument lists wrapped with one argument per line only when they exceed the line.
- Use `// MARK: - Section` to group members in larger types (e.g. `drinkpulse/Features/Insights/InsightsViewModel.swift`, `drinkpulse/Features/History/EditEventView.swift`). About 90 MARK lines across the app.

**Linting:**
- No SwiftLint configuration is present. Enforcement comes from the compiler: Swift 6 strict concurrency is on, and warnings are expected to be zero (`AGENTS.md` quality gate).
- Mandatory manual checks (see `AGENTS.md`):
  - No force unwraps and no `try!` in production code. `try!` appears only inside preview helpers (`drinkpulse/Features/Settings/SettingsView.swift`, `drinkpulse/Features/Shell/RootShellView.swift`, `drinkpulse/Features/History/HistorySearchableList.swift`) and must stay there.
  - No `print` in production code.
  - No `ObservableObject`, `@Published`, `@StateObject`. Use `@Observable`.
  - File size: no Swift file over 300 lines. Check with the `find ... | xargs wc -l` command in `AGENTS.md`.
- Current deviations from the 300-line rule (must be split):
  - `drinkpulseTests/Services/HealthServiceTests.swift` (302 lines)
  - `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift` (322 lines)

**Concurrency:**
- View models and services that touch UI or SwiftData are `@MainActor`. Pattern from `drinkpulse/Features/Insights/InsightsViewModel.swift`:
  ```swift
  @Observable @MainActor final class InsightsViewModel {
      var events: [ConsumptionEvent] = [] {
          didSet { rebuildGramsByDay() }
      }
      @ObservationIgnored private var gramsByDay: [Date: Double] = [:]
  ```
- Pure domain helpers are marked `nonisolated` so they can be called from any context: `drinkpulse/Domain/AlcoholUnit.swift` (`nonisolated static let physicalDensityGramsPerMl`, `nonisolated func density(for:)`). Use `nonisolated` on new pure domain functions.
- Derived caches that should not drive SwiftUI updates use `@ObservationIgnored`.
- Protocols that cross isolation boundaries conform to `Sendable`: `protocol HealthWriting: Sendable` (`drinkpulse/Services/HealthWriting.swift`).

## Observation and State

- `@Observable` view models are `final class`, marked `@MainActor`, and have `@Observable @MainActor final class Name` on one line. Only four exist: `DashboardViewModel`, `HistoryViewModel`, `InsightsViewModel`, `OnboardingViewModel`.
- View models do not own a `ModelContext` (AGENTS.md). Views pass plain values (`[ConsumptionEvent]`, `UserProfile?`) into them.
- Views read persisted data with `@Query` (14 files) or fetch via `@Environment(\.modelContext)` (9 files) for simple insert/delete.
- Dependency injection uses custom `EnvironmentValues` entries declared with `@Entry`, e.g. `drinkpulse/Services/HealthServiceEnvironment.swift`:
  ```swift
  extension EnvironmentValues {
      @Entry var healthService: HealthService? = nil
  }
  ```

## Domain Conventions

- Stored primary unit is grams of pure alcohol. Derived values are computed, never persisted.
- Display choices are expressed as enums with methods taking the choice as an argument (see `AlcoholUnit`, `GuidelineChoice`, `UnitSystem`). Fallback decoding for unknown raw values is explicit:
  ```swift
  nonisolated init(from decoder: Decoder) throws {
      let raw = try decoder.singleValueContainer().decode(String.self)
      self = AlcoholUnit(rawValue: raw) ?? .standardDrinks
  }
  ```
- Physical calculations (calories, BAC, HealthKit grams) use `AlcoholUnit.physicalDensityGramsPerMl` (0.789). Display-unit density is used only for display-mode mass. Do not change this without the owner's review (AGENTS.md).

## Localization

- All user-visible strings go through `String(localized:)` and resolve from the single catalog `drinkpulse/Localizable.xcstrings`. Keys are dotted lowerCamelCase: `"unit.g"`, `"unit.standardDrinks"`, `"settings.alcoholUnit.grams"`.
- Literal SwiftUI `Text("...")` also localizes through the catalog. Interpolated labels such as `Text("\(option.code) · \(option.symbol)")` need no key.
- English only. Do not add other locales.

## Error Handling

**Typed errors:**
- Errors are `enum` types conforming to `Error`: `StartupError` (`drinkpulse/Domain/Persistence/StartupError.swift`) and `StoreBootstrap.RecoveryError` (`drinkpulse/Domain/Persistence/StoreBootstrap.swift`). `StartupError` also conforms to `Equatable` so tests can compare it.
- Services surface failures by throwing; view models and views catch and map them to user-facing state or logs.

**Patterns:**
- Failures that must reach the user are shown through view state. Failures that are logged use `os.Logger` with error categories only (see Logging).
- `try?` is allowed only when the failure is genuinely ignorable, and a comment states why. Example from `drinkpulse/Features/Settings/AppVersionInfo.swift`: `// try? is fine: a missing build time only drops the second line; no user data involved.`
- Do not add empty `catch {}` blocks. Existing `catch` blocks log through `Logger` (e.g. `drinkpulse/Features/Settings/Components/DataSection.swift`, `drinkpulse/Features/Shell/RootShellView.swift`).
- Some `try?` calls remain without a justification comment, e.g. `drinkpulse/Features/Settings/Components/DataSection.swift` lines around `modelContext.delete(model:)` and in `drinkpulse/Features/Shell/RootShellView.swift`. New code must either handle the error or add the comment.

## Logging

**Framework:** `os.Logger` (`import OSLog`), fixed subsystem `com.drinkpulse.app`.

**Pattern:**
```swift
private static let logger = Logger(subsystem: "com.drinkpulse.app", category: "Shell")
...
Self.logger.error("Log feedback fetch failed: \(String(describing: type(of: error)), privacy: .public)")
```
- One category per area, usually the type name or feature: `"startup"`, `"Shell"`, `"EventActions"`, `"Onboarding"`, `"HealthSection"`, `"ReminderSection"`.
- Logged values are counts, timings, error type names, and enum cases. Mark non-personal values `privacy: .public` only when they are of that kind (`drinkpulse/drinkpulseApp.swift`).
- Never log drink names, notes, body metrics, timestamps tied to a person, or model objects. Default `privacy: .private` for anything derived from user data.
- Startup timing and dedup logs go through `startupLog` and `ShellStartup`'s `logger`.

## Comments

**When to comment:**
- Explain why, not what. Keep section comments to `// MARK:`.
- Note non-obvious conventions inline, e.g. the density note on `AlcoholUnit` and the `try?` justification comments above.
- Persisted schema and migration rules are documented in `drinkpulse/Domain/Persistence/`.

**Documentation comments:**
- `///` doc comments appear in about 9 files, mostly domain and persistence types. Use them for public domain APIs whose behaviour is not obvious from the signature.

**Language:** English only, as required by AGENTS.md.

## Function Design

**Size:** Keep functions short. Move calculations out of views into domain types or view-model extensions. Long view bodies are split into `Components/` subviews.

**Parameters:** Labelled arguments, with the choice (unit, guideline, sex) as an argument rather than stored state. Defaults for test convenience (`func event(daysAgo: Int = 0, grams: Double = 20.0, ...)`).

**Return values:** Pure functions return computed values. Mutations go through the owning model's `touch()`/setter path so `modifiedDate` stays current (AGENTS.md: LWW contract).

## Module Design

**Exports:** Single-module app target. Visibility is `internal` by default; `private` for helpers.

**Barrel files:** None. Imports are per file.

**Import order:** `import Foundation` / `import SwiftUI` / `import SwiftData` / `import OSLog` first, then `@testable import drinkpulse` in tests. No ordering tool enforces this.

## Accessibility Conventions

- Interactive controls carry `accessibilityLabel` and, for UI tests, `accessibilityIdentifier` (about 90 occurrences).
- Charts expose `accessibilityChartDescriptor` (e.g. `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift`, `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift`). Keep the accessibility extension in a `+Accessibility.swift` file.
- Animations go through `DPMotion` / `WithMotion` helpers that respect `reduceMotion` (`drinkpulse/DesignSystem/DPMotion.swift`, `drinkpulse/DesignSystem/WithMotion.swift`). Do not call `withAnimation` directly in new feature code.
- Colors come from semantic tokens (`drinkpulse/DesignSystem/DPSemanticColors.swift`, asset catalog colorsets such as `RiskHigh`, `SecondaryText`).

## SwiftUI Conventions

- Every view file ends with a `#Preview` block (71 of 76 view files) or a `+Previews.swift` file, using in-memory SwiftData containers with mock data.
- Shared visual pieces live in `drinkpulse/DesignSystem/` (e.g. `MetricTile.swift`, `LimitGaugeRow.swift`, `DPArcProgress.swift`). Feature-specific pieces go in the feature's `Components/` folder.
- Navigation uses `NavigationStack` with typed routes (e.g. `drinkpulse/Features/AddDrink/AddDrinkRoute.swift`, `drinkpulse/Features/History/EditEventRoute.swift`).

## Persistence Conventions (SwiftData)

- `@Model` types: `ConsumptionEvent`, `DrinkTemplate`, `UserProfile`.
- Every stored property has a default value or is optional (CloudKit-safe shape, AGENTS.md). No `@Attribute(.unique)`.
- Renames use `@Attribute(originalName:)` (`drinkpulse/Domain/ConsumptionEvent.swift`).
- Schema changes add a new `VersionedSchema` (`SchemaV1` ... `SchemaV4`) and a migration stage in `drinkpulse/Domain/Persistence/MigrationPlan.swift`. Shipped schema files are never edited in place.

---

*Convention analysis: 2026-11-27*
