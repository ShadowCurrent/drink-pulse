---
last_mapped_commit: 8f0cefeb8c0f6f0169a34fe15b31dce3c8005d57
last_mapped_at: 2026-11-18
---
# Testing Patterns

**Analysis Date:** 2026-11-18

## Test Framework

**Runner:**
- Swift Testing (`import Testing`, `@Test`, `#expect`) for unit tests. About 721 `@Test` and 1394 `#expect` uses across the test targets.
- XCTest (`XCTestCase`, `XCTAssert*`) for UI tests and a small number of legacy unit tests. 56 files use `XCTestCase`; 71 files use `import Testing`.
- Config: no separate test config file. Test plans are not used. Targets and scheme are in `drinkpulse.xcodeproj` and `drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme` (`BuildableName = "drinkpulseTests.xctest"` and `"drinkpulseUITests.xctest"`).
- Test targets are file-system-synchronised folders: `drinkpulseTests/` and `drinkpulseUITests/`. New files are picked up without `project.pbxproj` edits.

**Assertion Library:**
- Swift Testing: `#expect(...)`, `#expect(throws:)`, `#require`. Use `abs(x - y) < eps` for floating point (`drinkpulseTests/Domain/AlcoholCalculationTests.swift`).
- XCTest: `XCTAssertTrue`, `XCTAssertEqual`, `XCTAssertFalse`, `XCTAssertNotNil`, `XCTAssertLessThanOrEqual`.

**Run Commands:**
```bash
# Local iOS 27 simulator must be selected first (AGENTS.md)
xcrun simctl list devices available
export LOCAL_IOS_27_UDID='<selected-local-ios-27-simulator-udid>'
xcrun simctl bootstatus "$LOCAL_IOS_27_UDID" -b

xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID"              # Full suite (~25 min)

xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" \
  -only-testing:drinkpulseTests/DashboardViewModelTests                    # Scoped (default during task work)

xcodebuild test ... -enableCodeCoverage YES -derivedDataPath build/       # Coverage
xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult       # Coverage report
```
- Xcode MCP `RunAllTests`, `RunSomeTests`, and `GetTestList` are the preferred runner for the main checkout (AGENTS.md). Worktrees must use `xcodebuild` directly.
- Accessibility audit suite is gated: set `DP_RUN_A11Y_AUDIT=1` (scheme Test-action environment for MCP, `TEST_RUNNER_DP_RUN_A11Y_AUDIT=1` for `xcodebuild`). Without it the full audit class skips.
- Watch mode: not configured.

## Test File Organization

**Location:**
- Separate target, mirroring the production folder tree by feature. Unit tests in `drinkpulseTests/`, UI tests in `drinkpulseUITests/Features/<X>/`.
- Example mapping:
  - `drinkpulse/Domain/AlcoholUnit.swift` → `drinkpulseTests/Domain/AlcoholUnitTests.swift`
  - `drinkpulse/Domain/DataTransfer/DataImporter.swift` → `drinkpulseTests/Domain/DataTransfer/DataImporterUpsertTests.swift`
  - `drinkpulse/Features/Dashboard/DashboardViewModel.swift` → `drinkpulseTests/Features/Dashboard/DashboardViewModelTests.swift`
  - `drinkpulse/Services/ReminderService.swift` → `drinkpulseTests/Services/ReminderServiceTests.swift`
  - `drinkpulse/Features/History/EditEventView.swift` (UI flow) → `drinkpulseUITests/Features/History/EditVolumeIntegrityUITests.swift`

**Naming:**
- Unit: `<Subject>Tests.swift`. Split large suites with `+Topic` extensions: `DashboardViewModelTests+Metrics.swift`, `DashboardViewModelTests+Formatting.swift`, `DashboardViewModelTests+PctAndRisk.swift`, `HistoryViewModelTests+Pagination.swift`, `InsightsViewModelTests+Navigation.swift`, `StoreBootstrapTests+Rollback.swift`, `MigrationChainV2V3Tests.swift`.
- UI: `<Screen><Behaviour>UITests.swift` (`DashboardUITests.swift`, `EditDeleteConfirmationUITests.swift`, `AddDrinkDynamicTypeUITests.swift`). Extended UI suites use `+Helpers`, `+Pagination`, `+LoadingState` etc.: `HistoryInteractionUITests+Helpers.swift`.
- Audit UI: `AccessibilityAuditUITests.swift` (gated full audit), per-screen `*AccessibilityAuditUITests.swift`, shared support in `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift` and `AccessibilityAuditOcclusion.swift`.

**Structure:**
```
drinkpulseTests/
├── DesignSystem/           DPMotionTests.swift
├── Diagnostics/            ViewLoadLoggerTests.swift
├── Domain/                 AlcoholCalculationTests.swift, UserProfileTests.swift, ...
│   ├── DataTransfer/       DataImporter*Tests.swift, BackupFixtureLoader.swift
│   └── Persistence/        Migration*Tests.swift, MigrationFixtures*.swift, StoreBootstrapTests*.swift
├── Features/               <Feature>/<Subject>Tests.swift (AddDrink, Dashboard, History, Insights, Onboarding, Settings)
├── Performance/            ScreenComputePerformanceTests.swift
└── Services/               <Service>Tests.swift, Fake*.swift, SlowNotificationCenter.swift

drinkpulseUITests/
└── Features/               AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell
    └── Shell/              AccessibilityAudit*.swift, ShellNavigationUITests.swift, StartupErrorUITests.swift
```

## Test Structure

**Suite organisation (Swift Testing):**
```swift
import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DashboardViewModelTests {

    func makeContainer() throws -> ModelContainer { ... }     // helper, no @Test
    func event(daysAgo: Int = 0, grams: Double = 20.0, in context: ModelContext) -> ConsumptionEvent { ... }

    // MARK: - weekBarData

    @Test func weekBarData_alwaysSevenEntries() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.weekBarData.count == 7)
    }
}
```
- Suites are `struct` (value type, fresh per test) with `@MainActor` when they touch view models or services. `@Suite` is used in a few files for display names (`DPMotionTests.swift`, `NotificationDelegateAssignmentTests.swift`, `HealthWriteHooksTests.swift`).
- Shared fixtures are `private func makeX()` / `func event(...)` helpers on the suite. Container creation is repeated per suite via `makeContainer()`.

**Suite organisation (XCTest UI tests):**
```swift
@MainActor
final class DashboardUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += ["-dp_onboarding_done", "YES", "-dp_uitest", "YES"]
        app.launch()
    }

    func test_heroCard_showsSeededConsumptionValue() throws {
        launchApp()
        waitForHome()
        let hero = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH %@", "Today's Intake")
        ).firstMatch
        XCTAssertTrue(hero.waitForExistence(timeout: 10), "...")
    }
}
```
- Each UI test launches the app fresh with launch arguments; state is seeded through `-dp_*` arguments read in `drinkpulse/UITestSeed.swift`.
- Waiting: `waitForExistence(timeout:)` on elements. Avoid `sleep`.

**Patterns:**
- Setup: helper functions returning a fresh container or fake per test. No shared mutable state between tests.
- Teardown: `defer` removes temp store files (`drinkpulseTests/Domain/Persistence/MigrationTests.swift` removes `-wal`/`-shm` siblings).
- Parameterised cases use `arguments:` where the value table is large (`grep "arguments:"` yields about 60 uses; prefer this for boundary tables).
- Assertion: prefer `#expect` over `XCTAssert` in new unit tests.

**Test naming (follow existing style per folder):**
- Swift Testing, Domain and Dashboard: `subject_expectation_condition`, e.g. `weekBarData_futureEntriesHaveZeroGrams`, `alcoholGrams_quantityMultiplies`, `monthCells_may2026_mondayFirst_returns35Cells`.
- Swift Testing, Service and Domain calculation suites: descriptive camel case, e.g. `beerHalfLitre5Percent`, `zeroVolumeGivesZeroAlcohol`, `write_doesNothing_whenHealthUnavailable`, `reimportingSameBackup_isIdempotent`.
- UI: `test_<screen>_<behaviour>`, e.g. `test_chipRow_present_andShowsSeededDrinkCount`, `test_loggingDrink_updatesVisibleDrinkCount`.
- Test names describe behaviour. Avoid `test_calc1` style.

## Mocking

**Framework:** None. Hand-written fakes that conform to production protocols. No Mockito-style library, no SwiftMock.

**Protocol seams used in tests:**
- `NotificationScheduling` (`drinkpulse/Services/NotificationScheduling.swift`) → `FakeNotificationCenter` (`drinkpulseTests/Services/ReminderServiceTests.swift`) and `SlowNotificationCenter` (`drinkpulseTests/Services/SlowNotificationCenter.swift`, used for concurrency/cancellation races).
- `HealthWriting` (`drinkpulse/Services/HealthWriting.swift`) → `FakeHealthStore` (`drinkpulseTests/Services/FakeHealthStore.swift`).

**Fake pattern:**
```swift
final class FakeHealthStore: HealthWriting, @unchecked Sendable {
    var available = true
    var status: HealthAuthStatus = .authorized
    var throwOnSave = false
    private(set) var saveCount = 0
    private(set) var savedGrams: [Double] = []

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID {
        saveCount += 1
        if throwOnSave { throw FakeHealthError.save }
        let id = UUID()
        savedGrams.append(grams)
        return id
    }
}
```
- Knobs are `var` flags configured by the test before the call (`fake.available = false`, `fake.throwOnSave = true`).
- Observables are `private(set)` counters and recorded arrays (`saveCount`, `addedRequests`) for assertions.
- Fake errors are private `struct TestError: Error {}` or `enum FakeHealthError`.
- Use `@unchecked Sendable` only for these test doubles.

**Injection in tests:**
```swift
let service = ReminderService(center: FakeNotificationCenter(), defaults: makeDefaults())
let service = HealthService(store: fake)
```
- `UserDefaults(suiteName: "test.reminder.\(UUID().uuidString)")!` isolates persisted state per test (`ReminderServiceTests.swift`).
- Production `HealthService` and `ReminderService` accept injected dependencies with defaults, so tests never touch real `UNUserNotificationCenter` or HealthKit.
- Observation of `ConsumptionEvent` side effects uses `ModelContainer(isStoredInMemoryOnly: true)`, not a fake context.

**What to Mock:**
- Platform capability protocols: notifications, HealthKit store, file IO boundaries.
- Time-sensitive state is injected as values, not mocked: `vm.now = .now`, `vm.calendar = calendar`, `calendar(firstWeekday:)` helpers in `HistoryViewModelTests.swift`.

**What NOT to Mock:**
- Domain calculations. Use real inputs (`ConsumptionEvent(volumeMl: 500, abv: 0.05, ...)`) and assert numbers.
- SwiftData persistence. Use an in-memory `ModelContainer` (`ModelConfiguration(isStoredInMemoryOnly: true)`), per ADR-0004.
- View models. Construct them directly and set their injected `events`, `profile`, `now`.

## Fixtures and Factories

**Test Data:**
- Inline builders per suite: `makeEvent()` returns a `ConsumptionEvent`; `event(daysAgo:grams:in:)` inserts into a context. Grams-to-ABV conversion is written explicitly: `let abv = target / (500 * 0.789)`.
- Migration and backup fixtures are JSON and Swift builders:
  - `drinkpulseTests/Domain/Persistence/MigrationFixtures.swift`, `MigrationFixtures+LegacyV2V3.swift`, `MigrationFixtureValues.swift`
  - `drinkpulseTests/Domain/DataTransfer/BackupFixtureLoader.swift` loads `<name>.json` from the test bundle (`Fixtures/` subdirectory first). Never read repository paths from tests.
  - `SanitizedBackupFixtureTests.swift` verifies the sanitised fixture.
- UI seed data: `drinkpulse/UITestSeed.swift` and `drinkpulse/UITestSeed+Fixtures.swift` seed the production app when `-dp_uitest` is passed. Test data must not contain real PII (AGENTS.md).

**Location:**
- Unit fixtures: next to the suite that uses them (`drinkpulseTests/Domain/Persistence/`), or in the feature folder.
- Shared fakes: `drinkpulseTests/Services/`.
- JSON fixtures: test bundle `Fixtures/` subdirectory.

## Coverage

**Requirements (AGENTS.md):**
- Overall testable code: ≥90% line coverage.
- Domain (`drinkpulse/Domain/`): 100%.
- View models (`drinkpulse/Features/**/*ViewModel*.swift`): ≥90% of non-trivial branches.
- Services (`drinkpulse/Services/`): ≥85%. Thin framework adapters (`HealthKitAdapter.swift`, `UNUserNotificationCenter` bridge) are excluded.
- Excluded from denominator: SwiftUI layout, SwiftData persistence internals, `@main` entry, generated localization accessors, presentation-only modifiers.
- Coverage is a gate. Below threshold blocks completion; add tests in the same task.

**View Coverage:**
```bash
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" \
  -enableCodeCoverage YES \
  -derivedDataPath build/

xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult
```

**Per-layer coverage:** Not measured in CI scripts. The `xccov` report must be read by layer. No coverage percentages are recorded in the repository at analysis time.

## Test Types

**Unit Tests (`drinkpulseTests/`):**
- Domain calculations: `AlcoholCalculationTests.swift`, `AlcoholUnitTests.swift`, `AlcoholUnitFormattingTests.swift`, `GuidelineLimitsTests.swift`, `GuidelineChoiceDisplayTests.swift`, `WeeklySummaryCalculatorTests.swift`, `RiskLevelTests.swift`, `UnitSystemVolumeTests.swift`, `CurrencyTests.swift`.
- Validators and value initialisers: `UserProfileTests.swift`, `CustomNameSuggestionFilterTests.swift`, `DrinkDetailInputMathTests.swift`.
- Persistence: `drinkpulseTests/Domain/Persistence/` covers migration chain V1→V4, store bootstrap rollback, deduplication, user profile store.
- Data transfer: round-trip (`DataImporterRoundTripTests.swift`, `ComprehensiveRoundTripTests.swift`), idempotent upsert (`DataImporterUpsertTests.swift`), edge cases (`DataImporterEdgeCaseTests.swift`), third-party CSV import (`DrinkControlImporterTests.swift`).
- View models: `DashboardViewModelTests*`, `HistoryViewModelTests*`, `InsightsViewModelTests*`, `OnboardingViewModelTests.swift`.
- Services: `ReminderServiceTests.swift` (schedule and cancel), `ReminderServiceCancellationTests.swift`, `HealthService*Tests.swift` (authorization gating, ordering, concurrency, update, removal), `NotificationActionHandlerTests.swift`, `NotificationOptOutTests.swift`, `WeeklySummaryService*Tests.swift`.
- Performance: `drinkpulseTests/Performance/ScreenComputePerformanceTests.swift` checks view-model compute cost.

**Integration Tests:**
- Persistence integration: `MigrationSweepTests.swift` and `MigrationTests.swift` open real SQLite stores in a temp directory and reopen them under the migration plan.
- Service with real SwiftData: in-memory containers for `HealthServiceTests` and `WeeklySummaryServiceScheduleTests`.

**UI Tests (`drinkpulseUITests/`):**
- XCUIApplication driving the real screens. Required for every user-facing feature (AGENTS.md).
- Feature suites: AddDrink (`AddDrinkFlowUITests`, `VolumeServingUITests`, `CustomNameAutocompleteUITests`, `CurrencyUITests`, `HealthWriteHooksUITests`), Dashboard, History (`EditDeleteConfirmationUITests`, `DuplicateEditPersistenceUITests`, `EditVolumeIntegrityUITests`, `HistoryInteractionUITests`), Insights, Onboarding, Settings (`ExportUITests`, `GuidelinePickerUITests`, `ReminderSettingsUITests`, `HealthSettingsUITests`), Shell (`ShellNavigationUITests`, `StartupErrorUITests`, `SheetDismissTabSwitchUITests`).
- Accessibility variants: `*DynamicTypeUITests` (Dynamic Type up to AX5), `ReduceMotion*UITests`, `*AccessibilityAuditUITests` (per-screen audits). Accessibility audit uses `XCUIApplication.performAccessibilityAudit(for:)` through `AccessibilityAuditSupport.swift`.
- Locale independence: the simulator may run in Polish. Never match system UI by localised label. Use element identifiers or position (AGENTS.md). Assert app-rendered English strings only.
- Launch arguments set the scenario: `-dp_onboarding_done YES`, `-dp_uitest YES`, `-dp_force_onboarding YES`, `-dp_uitest_delete_profile_midsession`, `-dp_uitest_pending_open_insights`, `-dp_uitest_warm_weekly_tap`. Every seed argument must be gated on `-dp_uitest`.

**E2E Tests:**
- Not used beyond XCUITest.

## Common Patterns

**Async Testing (Swift Testing):**
```swift
@Test func write_doesNothing_whenHealthUnavailable() async {
    let fake = FakeHealthStore()
    fake.available = false
    let service = HealthService(store: fake)
    await service.write(event)
    #expect(fake.saveCount == 0)
}
```
- Mark test structs `@MainActor` when they call `@MainActor` services. Use `async` test functions; no `XCTestExpectation` in new code.
- Timing-sensitive code (cancellation, rescheduling) uses an injected slow fake (`SlowNotificationCenter`) and deterministic ordering, not `Task.sleep` assertions.

**Error Testing:**
```swift
@Test func failedAuthorizationDoesNotWriteSamples() async throws {
    let fake = FakeHealthStore()
    fake.authError = FakeHealthError.authorization
    // act ...
    #expect(fake.saveCount == 0)
}
```
- Error cases: assert no side effect (`saveCount == 0`, `deletedUUIDs.isEmpty`) and the model state (`event.healthKitUUID == nil`).
- Typed error equality uses `Equatable` error enums (`StartupError`) with `#expect(error == .expectedCase)`.
- For thrown errors, use `#expect(throws:)`.

**Edge cases to cover (from AGENTS.md and existing suites):**
- Zero and negative volume/ABV, ABV exactly 0.0 and 1.0, quantity 0.
- Empty event collections (`vm.events = []`), nil profile (`DashboardViewModel` falls back to WHO defaults).
- Timezone and day-boundary: `HistoryViewModelTests+DayRollover.swift`, `WeeklySummaryCompletedWeekTests.swift`. Use explicit `Calendar` instances with `firstWeekday` set.
- Unit-mode density: `alcoholGrams(density: 0.8)` vs `0.789`. Test both when a calculation depends on display unit.

**Regression tests:**
- Every fixed bug gets a failing test first, then the fix (AGENTS.md). Examples in suite names: `EditEventVolumeGuardTests.swift`, `WrongRowContextMenuTargetUITests.swift`, `DuplicateEditPersistenceUITests.swift`.

**Data-integrity features:**
- Edits that can rewrite stored data need both a unit test of the function and a UI test driving the real screen (`EditVolumeIntegrityUITests.swift`).

## Gaps and Observations

- Test-only fixtures and fakes are split across two folders (`drinkpulseTests/Services/` and inside `drinkpulseTests/Domain/Persistence/`). Put new fakes beside the protocol's suite.
- Three unit test files exceed the 300-line ceiling (`InsightsViewModelTests+Aggregates.swift` 335, `DashboardViewModelTests+Metrics.swift` 327, `HealthServiceTests.swift` 302). Split by topic when next edited.
- Mixed frameworks in one file: `HistoryViewModelTests.swift` imports both `Testing` and `XCTest`. Prefer one framework per file; use Swift Testing for new unit tests.
- Coverage reporting is manual (`xccov`). There is no coverage threshold script in the repo.

---

*Testing analysis: 2026-11-18*
