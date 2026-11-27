---
last_mapped_commit: 19ce3159ee64540aaea8411fc85f24e6bea68714
last_mapped_at: 2026-11-27
---
# Testing Patterns

**Analysis Date:** 2026-11-27

## Test Framework

**Runner:**
- Swift Testing (`import Testing`) for all new unit tests. 832 `@Test` declarations across `drinkpulseTests/`.
- XCTest (`XCTestCase`) for the two legacy unit files `drinkpulseTests/Features/History/HistoryViewModelTests.swift` and `drinkpulseTests/Performance/ScreenComputePerformanceTests.swift`, and for all UI tests.
- Config: no separate test config file. Targets and test plans are in `drinkpulse.xcodeproj`. Test targets are file-system-synchronized, so new `.swift` files in the right folder are compiled automatically.

**Assertion Library:**
- Swift Testing: `#expect(...)` and `#expect(..., "message")`. Some tests use `#require` for unwrapping.
- XCTest: `XCTAssertTrue`, `XCTAssertEqual`, `waitForExistence` on XCUI elements.

**Run Commands:**
```bash
# Build (zero warnings required)
xcodebuild -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" build

# Full suite (milestone close, release builds; slow, includes UI tests)
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID"

# Scoped run (default during phase work)
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" \
  -only-testing:drinkpulseTests/DashboardViewModelTests \
  -only-testing:drinkpulseUITests/AddDrinkFlowUITests

# Coverage
xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" \
  -enableCodeCoverage YES -derivedDataPath build/
xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult
```
- The simulator UDID is machine-specific. Select an iOS 27 simulator with `xcrun simctl list devices available` and export `LOCAL_IOS_27_UDID`.
- Xcode MCP (`RunSomeTests`, `RunAllTests`) can run the same scopes. Ask before `RunAllTests`, because the full suite includes slow UI tests.

## Test Targets and Folder Layout

Tests mirror the production tree by feature (AGENTS.md "Test organization"):

```
drinkpulseTests/
├── Domain/                    # AlcoholUnitTests, GuidelineLimitsTests, ...
│   ├── DataTransfer/          # export/import, Fixtures/ (sanitized backup JSON)
│   └── Persistence/           # MigrationTests, schema tests
├── Features/
│   ├── AddDrink/
│   ├── Dashboard/             # DashboardViewModelTests + +AlcoholFree/+Formatting/+Metrics/+PctAndRisk
│   ├── History/
│   ├── Insights/              # InsightsViewModelTests + +Aggregates
│   ├── Onboarding/            # Components/
│   ├── Settings/
│   └── Shell/
├── Services/                  # HealthService*, ReminderService*, WeeklySummary*, NotificationActionHandlerTests
├── DesignSystem/              # ArcShapeTests, DPMotionTests, RiskToneTests, ContrastRatio.swift helper
├── Diagnostics/               # ViewLoadLoggerTests
└── Performance/               # ScreenComputePerformanceTests

drinkpulseUITests/
└── Features/                  # AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell
```
- Shared fixtures and fakes sit next to the tests that use them: `drinkpulseTests/Services/FakeHealthStore.swift`, `drinkpulseTests/Services/SlowNotificationCenter.swift`, `drinkpulseTests/DesignSystem/ContrastRatio.swift`, `drinkpulseTests/Domain/DataTransfer/Fixtures/`.
- UI test helpers: `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift`.

## Test Structure

**Suite organization (Swift Testing):**
```swift
import Testing
import Foundation
import SwiftData
@testable import drinkpulse

@MainActor
struct DashboardViewModelTests {

    func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func weekBarData_alwaysSevenEntries() {
        let vm = DashboardViewModel()
        vm.events = []
        vm.now = .now
        #expect(vm.weekBarData.count == 7)
    }
}
```
- Suites are `struct`s (not `class`), annotated `@MainActor` when they touch view models or SwiftData. Pure domain suites (e.g. `drinkpulseTests/Domain/AlcoholUnitTests.swift`) have no actor annotation.
- Sections inside a suite are marked with `// MARK: - <area>`. Use the same convention in new files.
- Extensions of a suite (`DashboardViewModelTests+Metrics.swift`) split large suites under the 300-line ceiling.

**Patterns:**
- Setup: a per-suite `makeContainer()` builds an in-memory `ModelContainer` (used in 23 test files). Create a fresh container per test; never share state between tests.
- Fixtures: helper functions with defaulted parameters (`event(daysAgo:grams:relativeTo:in:)`, `gramsProfile(in:)`). Pass `now` explicitly for time-dependent logic.
- Teardown: none needed for value-type suites. Tests that register notifications or health fakes reset them in `init`.
- Assertions: one behaviour per test. Multiple `#expect` lines are fine when they verify the same claim (AGENTS.md).

**Parameterised tests:**
- `arguments:` is used in 12 places for table-driven cases. Prefer it over loops when each case should report separately.

**Localized-string assertions:**
- Tests compare against `String(localized: "key")` rather than literal English so they stay correct if the catalog changes (`drinkpulseTests/Domain/AlcoholUnitTests.swift`).

## Mocking

**Framework:** No mocking library. Hand-written fakes conforming to the production protocol.

**Pattern (service boundary):**
```swift
final class FakeHealthStore: HealthWriting, @unchecked Sendable {
    var available = true
    var status: HealthAuthStatus = .authorized
    var throwOnSave = false
    private(set) var saveCount = 0
    private(set) var savedGrams: [Double] = []
    init(seed: [UUID: UUID] = [:]) { samplesByEvent = seed }
    // ... protocol methods record calls and honour the throw flags
}
```
- Fakes expose configurable flags (`available`, `status`, `throwOnSave`) and recorded calls (`saveCount`, `savedGrams`, `deletedUUIDs`). Recorded state is `private(set)`.
- `@unchecked Sendable` is used only for fakes that hold mutable state accessed from tests; keep it limited to test doubles.

**Services are tested through their protocols:**
- `HealthService(store: fake)` (`drinkpulseTests/Services/HealthServiceTests.swift`).
- Notifications: `SlowNotificationCenter` and the production `UITestNotificationCenter` simulate delays and failures.
- Health: `drinkpulse/Services/UITestHealthStore.swift` is the launch-argument-driven stand-in used by UI tests.

**What to Mock:**
- Platform capabilities behind a protocol: HealthKit (`HealthWriting`), notifications (`NotificationScheduling`), file/system services.
- Time, via an explicit `now` parameter on view models (`vm.now = .now`) rather than mocking the clock.

**What NOT to Mock:**
- Domain calculations. Use real inputs (e.g. `ConsumptionEvent(volumeMl: 500, abv: 0.05, ...)`).
- SwiftData. Use an in-memory `ModelContainer` with `isStoredInMemoryOnly: true`.
- View model internals. Set the public properties (`events`, `profile`) and assert on outputs.

## Fixtures and Factories

**Test data:**
```swift
let abv = target / (500 * 0.789)
let e = ConsumptionEvent(consumptionDate: ts, volumeMl: 500, abv: abv,
                         category: .beer, icon: "🍺")
context.insert(e)
```
- Domain objects are built directly. Derive ABV from the target grams using the physical density (0.789) when a test needs a specific mass.
- Large backup fixtures live in `drinkpulseTests/Domain/DataTransfer/Fixtures/`. They must be sanitized: no real personal data. `SanitizedBackupFixtureTests.swift` checks this.
- The UI test seed is `drinkpulse/UITestSeed.swift`, gated by the `-dp_uitest` launch argument.

**Location:**
- Per-suite helpers at the top of the suite struct. Shared fakes and fixtures in the same folder as the consuming tests.

## Coverage

**Requirements (AGENTS.md):**
- Overall testable code: at least 90% line coverage.
- Domain (`drinkpulse/Domain/`): 100%.
- View models: at least 90%.
- Services (`drinkpulse/Services/`): at least 85%, covering happy, denied and error paths.
- Excluded from the denominator: SwiftUI view layout, SwiftData persistence internals, the `@main` entry point, generated localization accessors.

**View Coverage:**
```bash
xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult
```

## Test Types

**Unit tests (`drinkpulseTests/`):**
- Domain calculations, validators, unit conversions, guideline rules, data transfer, persistence migrations (`drinkpulseTests/Domain/Persistence/MigrationTests.swift`).
- View models (`@Observable` classes) with injected plain values.
- Services through fakes, including cancellation, idempotency and denied authorization.
- Design-system logic (contrast, motion, risk tone) in `drinkpulseTests/DesignSystem/`.

**Performance tests:**
- `drinkpulseTests/Performance/ScreenComputePerformanceTests.swift` uses XCTest `measure`-style checks for calendar marks and screen computation at 2,000 and 10,000 events. Keep budgets generous to avoid flakiness on CI simulators.

**UI tests (`drinkpulseUITests/`, XCTest / XCUITest):**
- Mandatory for every user-facing feature (AGENTS.md). About 79 files across `Features/`.
- Structure:
  ```swift
  @MainActor
  final class AddDrinkFlowUITests: XCTestCase {
      private var app: XCUIApplication!

      override func setUpWithError() throws {
          continueAfterFailure = false
      }

      private func launchApp() {
          app = XCUIApplication()
          app.launchArguments += [
              "-dp_onboarding_done", "YES",
              "-dp_uitest", "YES",
              "-dp_uitest_unit", "metric",
          ]
          app.launch()
      }
  }
  ```
- Launch arguments drive state: `-dp_onboarding_done YES` skips onboarding, `-dp_uitest YES` enables the seeded/stubbed environment, `-dp_uitest_unit metric` fixes units.
- Find elements by accessibility identifier or by stable label. Do not match system UI (share sheets, system alerts) by localized text, because the simulator locale may not be English (AGENTS.md).
- Lazy lists: scroll before asserting rows below the fold (`for _ in 0..<4 where !tile.exists { app.swipeUp() }`).
- Use `waitForExistence(timeout:)` instead of fixed sleeps.
- Accessibility audits run through `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift`.

**E2E tests:** Not used beyond the UI tests above.

## Common Patterns

**Async testing (Swift Testing):**
```swift
@Test func write_doesNothing_whenDenied() async {
    let fake = FakeHealthStore()
    fake.status = .denied
    let service = HealthService(store: fake)
    await service.write(makeEvent())
    #expect(fake.saveCount == 0)
}
```

**Error testing:**
```swift
@Test func write_recordsNoSample_whenSaveThrows() async {
    let fake = FakeHealthStore()
    fake.throwOnSave = true
    // ... act, then assert no UUID was stored
}
```
- Use fake flags (`throwOnSave`, `throwOnDelete`, `throwOnQuery`) to drive error paths. Assert both the observable result and the absence of side effects.

**Expected failures in UI tests:** Use `XCTAssertTrue(element.waitForExistence(timeout: 5), "message")` with a message that names the expected UI.

**Regression tests:** Every fixed bug gets a failing test first, named after the behaviour it protects (AGENTS.md).

## Writing New Tests (checklist)

1. Put the file in the folder that mirrors the source path (`drinkpulseTests/<Path>/<Name>Tests.swift`).
2. Use Swift Testing (`@Test`, `#expect`) with `struct` suites. Add `@MainActor` when touching view models or SwiftData.
3. Build an in-memory `ModelContainer` for SwiftData; inject plain values into view models.
4. Use a fake conforming to the service protocol for platform capabilities. Never mock domain calculations.
5. For user-facing changes, add or update a `drinkpulseUITests/Features/<Area>/` test and drive it through launch arguments.
6. Keep each file under 300 lines. Split by behaviour into `Type+Topic` extensions.
7. Run the scoped `-only-testing:` command, then confirm the test name appears in the log.

## Known Gaps

- `drinkpulseTests/Services/HealthServiceTests.swift` (302 lines) and `drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift` (322 lines) exceed the 300-line limit and need splitting.
- Two legacy XCTest unit files remain. Convert them to Swift Testing when they are next touched.

---

*Testing analysis: 2026-11-27*
