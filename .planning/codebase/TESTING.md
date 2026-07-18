# Testing Patterns

**Analysis Date:** 2026-07-18

## Test Framework

**Runner:**
- Swift Testing (`@Test`, `#expect`, `#require`) for new tests
- Legacy XCTest kept for existing tests; no migration required
- Config: No separate config file; framework is Swift 5.0+

**Assertion Library:**
- Swift Testing: `#expect()`, `#require()` (the latter halts on failure)
- Legacy XCTest: `XCTAssertTrue()`, `XCTAssertEqual()`, etc.

**Run Commands:**
```bash
xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# With coverage:
xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES \
  -derivedDataPath build/

# View coverage report:
xcrun xccov view --report --only-targets \
  build/Logs/Test/*.xcresult
```

## Test File Organization

**Location:**
- Unit tests: mirror source structure in `drinkpulseTests/`
- UI tests: mirror source structure in `drinkpulseUITests/`
- Example:
  - Source: `drinkpulse/Domain/ConsumptionEvent.swift`
  - Unit test: `drinkpulseTests/Domain/ConsumptionEventTests.swift`
  - Source: `drinkpulse/Features/Dashboard/DashboardViewModel.swift`
  - Unit test: `drinkpulseTests/Features/Dashboard/DashboardViewModelTests.swift`
  - UI test: `drinkpulseUITests/Features/Dashboard/DashboardUITests.swift`

**Naming:**
- Test files: `<SourceFile>Tests.swift`
- Test structs: `struct <SourceName>Tests` for Swift Testing
- Test classes: `final class <SourceName>Tests: XCTestCase` for XCTest UI tests
- Test functions: `@Test func test_<behavior>_<expectedOutcome>()` or `func test<SpecificCase>()`

**Structure:**
```
drinkpulseTests/
├── Domain/
│   ├── AlcoholCalculationTests.swift
│   ├── ConsumptionEventTests.swift
│   ├── DataTransfer/
│   │   ├── DataImporterEdgeCaseTests.swift
│   │   ├── DrinkControlImporterTests.swift
│   │   └── ...
│   └── Persistence/
│       └── MigrationTests.swift
├── Features/
│   ├── Dashboard/
│   │   └── DashboardViewModelTests.swift
│   ├── History/
│   │   ├── EditEventDeleteTests.swift
│   │   └── HistoryViewModelTests.swift
│   └── ...
├── Services/
│   ├── FakeHealthStore.swift
│   ├── HealthServiceTests.swift
│   └── ReminderServiceTests.swift
└── Performance/
    └── ScreenComputePerformanceTests.swift

drinkpulseUITests/
├── Features/
│   ├── Dashboard/
│   │   └── DashboardUITests.swift
│   ├── AddDrink/
│   │   ├── VolumeServingUITests.swift
│   │   └── ...
│   └── ...
```

## Test Structure

**Swift Testing Suite:**
```swift
import Testing
import Foundation
@testable import drinkpulse

@MainActor
struct ConsumptionEventTests {

    // MARK: - Setup helpers (if needed)
    
    private func makeEvent() -> ConsumptionEvent {
        ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    }

    // MARK: - Test section
    
    @Test func displayName_returnsCustomName_whenSet() {
        let event = ConsumptionEvent(volumeMl: 330, abv: 0.05,
                                     category: .beer, icon: "🍺", customName: "Tyskie")
        #expect(event.displayName(in: .metric) == "Tyskie")
    }
    
    @Test("Custom description for the test") 
    func someTest() {
        #expect(true)
    }
}
```

**Legacy XCTest Suite (for UI tests):**
```swift
import XCTest

@MainActor
final class DashboardUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() {
        app = XCUIApplication()
        app.launchArguments += ["-dp_onboarding_done", "YES"]
        app.launch()
    }

    func test_heroCard_showsSeededConsumptionValue() throws {
        launchApp()
        // assertions...
    }
}
```

**Patterns:**
- Section organization with `// MARK: -` comments
- Helper methods (factories) at the top, private
- One test concept per `@Test` function
- Use `@Test("Description")` for custom naming when needed
- `@MainActor` on the struct (or class) for UI/SwiftData tests

## Mocking

**Framework:** Manual protocol-based fakes (no third-party mocking library)

**Patterns:**
```swift
// 1. Create a fake that conforms to the service's protocol
final class FakeHealthStore: HealthWriting {
    var available = true
    var status: HealthAuthStatus = .authorized
    private(set) var saveCount = 0

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID {
        saveCount += 1
        return UUID()
    }
}

// 2. Inject it into the service under test
let fake = FakeHealthStore()
let service = HealthService(store: fake)

// 3. Configure the fake and assert on recorded calls
await service.write(event)
#expect(fake.saveCount == 1)
```

**What to Mock:**
- External platforms: HealthKit (use `FakeHealthStore`), UserNotifications
- Network calls (none in this app, but pattern would be protocol-based)
- File I/O (use in-memory fixtures)

**What NOT to Mock:**
- Domain calculations; test with real inputs
- SwiftData persistence; use in-memory `ModelContainer`
- View models receiving injected data (pass real event arrays)
- Error cases from the faked protocol (configure the fake to throw)

**Creating a Fake Service:**
1. Define the protocol the service uses (e.g., `HealthWriting`)
2. Implement the fake conforming to it with configurable behavior
3. Track calls with private(set) properties (e.g., `saveCount`, `deletedUUIDs`)
4. Allow fault injection (e.g., `throwOnSave = true`)

**Example from codebase (`FakeHealthStore.swift`):**
```swift
final class FakeHealthStore: HealthWriting, @unchecked Sendable {
    var available = true
    var status: HealthAuthStatus = .authorized
    var throwOnSave = false
    private(set) var saveCount = 0
    private(set) var samplesByEvent: [UUID: UUID] = [:]

    init(seed: [UUID: UUID] = [:]) { samplesByEvent = seed }

    func save(grams: Double, date: Date, eventUUID: UUID) async throws -> UUID {
        saveCount += 1
        if throwOnSave { throw FakeHealthError.save }
        let id = UUID()
        samplesByEvent[eventUUID] = id
        return id
    }
}
```

## Fixtures and Factories

**Test Data:**
```swift
// Factory helper (private, at top of test struct)
private func makeEvent() -> ConsumptionEvent {
    ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
}

// SwiftData container (for tests needing persistence)
private func makeContainer() throws -> ModelContainer {
    try ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

// Use in test
@Test func someTest() throws {
    let container = try makeContainer()
    let context = container.mainContext
    let event = makeEvent()
    context.insert(event)
    // test logic
}
```

**Preview Data:**
```swift
// In main source files (extracted to `+Previews.swift` if >30 lines)
extension ConsumptionEvent {
    static var previewBeer: ConsumptionEvent {
        ConsumptionEvent(volumeMl: 568, abv: 0.05, category: .beer, icon: "🍺")
    }
    
    static var previewWine: ConsumptionEvent {
        ConsumptionEvent(volumeMl: 175, abv: 0.135, category: .wine, icon: "🍷")
    }
}

// Used in #Preview blocks
#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    // ... populate with data ...
    return DashboardView()
        .modelContainer(container)
}
```

**Location:**
- Factory helpers: private functions at the top of the test struct
- Preview data: `static var` accessors in `extension` of the type, or in `+Previews.swift`

## Coverage

**Requirements:**
- **Domain layer** (`Domain/`): **100%** — every calculation, validator, guideline rule
- **View models**: **≥90%** — every non-trivial branch
- **Services** (`Services/`): **≥85%** — happy paths + error/denied paths
- **Overall project**: **≥90%** (testable code only; layout and framework internals excluded)

**Excluded from denominator:**
- Pure SwiftUI view layouts
- SwiftData persistence internals
- `@main` entry point
- Auto-generated localization accessors
- Pure presentation modifiers without logic

**View Coverage:**
```bash
xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES \
  -derivedDataPath build/

xcrun xccov view --report --only-targets \
  build/Logs/Test/*.xcresult
```

## Test Types

**Unit Tests:**
- Scope: Single function/method with isolated inputs/outputs
- Approach: Direct instantiation, fast execution, no I/O
- Example: `test_pureAlcohol_returnsZero_whenABVIsZero` in `AlcoholCalculationTests.swift`

**Integration Tests:**
- Scope: Multiple components working together (e.g., view model + SwiftData)
- Approach: Use in-memory `ModelContainer`, inject mock services
- Example: `test_weekBarData_todayEntryReflectsActualGrams` injecting `events` and `profile`

**E2E (UI Tests):**
- Scope: Full user flow from app launch to visible outcome
- Approach: XCTest `XCUIApplication`, drive real UI, assert on accessibility labels
- Example: `test_heroCard_showsSeededConsumptionValue` in `DashboardUITests.swift`
- Tools: XCTest framework, `drinkpulseUITests` target
- Must exist for every user-facing feature change

## Common Patterns

**Async Testing:**
```swift
@Test func write_savesOnce_whenAuthorized() async {
    let fake = FakeHealthStore()
    let service = HealthService(store: fake)
    let event = makeEvent()

    await service.write(event)

    #expect(fake.saveCount == 1)
}
```

**Error Testing:**
```swift
@Test func import_unsupportedVersion_throwsError() throws {
    let json = """
    { "version": 999, "events": [] }
    """.data(using: .utf8)!

    #expect(throws: ImportError.self) {
        try DataImporter().importData(json, into: context)
    }
}

// For specific error cases:
@Test func requestAuthorization_returnsTrue_whenSuccessful() async throws {
    let fake = FakeHealthStore()
    let result = try await fake.requestAuthorization()
    #expect(result == true)
}
```

**Floating-point Comparisons:**
```swift
private let eps = 1e-9

@Test func beerHalfLitre5Percent() {
    let event = ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    #expect(abs(event.pureAlcoholGrams - 19.725) < eps)
}
```

**SwiftData Setup:**
```swift
@MainActor
struct SomeTests {
    
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func someTest() throws {
        let c = try makeContainer()
        let context = c.mainContext
        let event = ConsumptionEvent(...)
        context.insert(event)
        // test logic
    }
}
```

**UI Test Seeding:**
```swift
// At app launch, pass launch arguments to inject test data
private func launchApp() {
    app = XCUIApplication()
    app.launchArguments += [
        "-dp_onboarding_done", "YES",  // Skip onboarding
        "-dp_uitest", "YES",           // Use UITestSeed
    ]
    app.launch()
}

// The app checks for these via UITestSeed.isActive
// and seeds deterministic data for reproducible tests
```

## When to Write Tests

- **New feature**: Write tests *before* or *alongside* implementation. Feature is not done without tests meeting coverage targets.
- **Bug fix**: Write a failing test that reproduces the bug first; then fix it.
- **Changed logic**: Update existing tests to match new behavior before shipping.
- **Coverage audit**: If uncovered code is found, add tests immediately — do not file "TODO: add tests".

## Test Quality Rules

- **One assertion concept per test**: Multiple `#expect` lines are fine if they verify the same claim (e.g., both asserting a value changed)
- **Descriptive names**: `test_pureAlcohol_returnsZero_whenABVIsZero` not `test_calc1`
- **Use Swift Testing for new tests**: `@Test` and `#expect`
- **Keep legacy XCTest**: existing tests stay as-is; no forced migration
- **No tests for getters/setters**: Test behavior, not syntax
- **Mock at the boundary**: Service protocol (injected), not below. Domain types use real inputs.

---

*Testing analysis: 2026-07-18*
