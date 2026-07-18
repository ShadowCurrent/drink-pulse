# Coding Conventions

**Analysis Date:** 2026-07-18

## Naming Patterns

**Files:**
- PascalCase for all files: `DashboardViewModel.swift`, `ConsumptionEvent.swift`
- Single concept per file. Never use compound names with "And" or "&"
- Aspect suffix pattern for related code: `DrinkTemplate.swift` + `DrinkTemplate+Previews.swift` + `DrinkTemplate+Validation.swift`
- Component subviews in `Components/` subdirectory: `Features/Dashboard/Components/DashboardHeroCard.swift`
- Test files mirror source structure exactly: `Features/Dashboard/DashboardViewModelTests.swift` for `Features/Dashboard/DashboardViewModel.swift`
- View model file alongside view: `DashboardView.swift` + `DashboardViewModel.swift` in same folder

**Functions:**
- camelCase: `alcoholGrams()`, `displayName()`, `requestAuthorization()`
- Descriptive names reflecting behavior, not implementation: `displayName(in:)` not `getName()`
- Helper functions follow pattern: `private var volumeOptions: [VolumeOption]`, `private func makeEvent()`
- Static factory methods for test data: `static var previewBeer: ConsumptionEvent { ... }`

**Variables:**
- camelCase: `volumeMl`, `abvValue`, `isToday`, `modifiedDate`
- Boolean prefixes: `is`, `has`, `was`, `can`, `should`: `isFavorite`, `isArchived`
- Avoid shortened names; clarity over brevity: `volumeMl` not `vol`, `modifiedDate` not `modDate`
- Private state in views use `@State`: `@State var customNameText`, `@State var priceText`
- View model properties are plain fields (not wrapped): `var events: [ConsumptionEvent] = []`

**Types:**
- PascalCase for all types: `ConsumptionEvent`, `DrinkTemplate`, `UserProfile`, `GuidelineChoice`
- Enums with `.` prefix for cases: `.beer`, `.wine`, `.spirits`, `.authorized`
- Type aliases follow the type's name: `typealias HealthAuthStatus = ...`

## Code Style

**Formatting:**
- No file header comments (Xcode default: omit)
- Blank line between sections marked with `// MARK: -` comments
- Inline documentation for public APIs and complex logic using `///` comments
- Comments are concise but specific to the problem domain (reference ADRs and plans)

**Linting:**
- Swift 6 strict concurrency enabled (all `@MainActor` and concurrency warnings fixed, never suppressed)
- Zero Xcode warnings required before declaring work done
- No force-unwraps in production code (`try!` only in tests and previews)
- No `print()` statements in production; use `OSLog` via `Logger(subsystem:category:)`
- No empty `catch {}` blocks; catch must either handle meaningfully or log the error

## Import Organization

**Order (enforced implicitly by structure):**
1. Foundation framework imports: `import Foundation`
2. Apple platform frameworks: `import SwiftUI`, `import SwiftData`, `import UserNotifications`, `import OSLog`
3. Other frameworks in import order encountered: `import HealthKit`, `import Charts`
4. Test-only: `@testable import drinkpulse` or `import Testing`

**Example from codebase:**
```swift
import Foundation
import SwiftUI
import SwiftData

// OR for tests:
import Testing
import Foundation
@testable import drinkpulse

// OR for services:
import Foundation
import OSLog
```

**Path Aliases:**
- No custom path aliases used; all imports are absolute to the app bundle

## Error Handling

**Patterns:**
- All errors are typed enums conforming to `LocalizedError`:
  ```swift
  enum ImportError: LocalizedError {
      case unsupportedVersion(Int)
      case decodeFailure(underlying: Error)
      
      var errorDescription: String? { ... }
  }
  ```
- Errors are either handled meaningfully or surfaced to the user
- Services use best-effort error swallowing: catch, log the category (never PII), return false/nil
  - Example: `HealthService.requestAuthorization()` returns `Bool` instead of throwing
- No PII in error messages or logs; log only error categories and enums
- Always mark error logging with `privacy: .private` (the default for non-numeric)

## Logging

**Framework:** `OSLog` via `Logger(subsystem: "com.drinkpulse.app", category: "...")`

**Patterns:**
- Initialize at file scope: `private let logger = Logger(subsystem: "com.drinkpulse.app", category: "HealthService")`
- Use appropriate log levels: `.error` for failures, `.info` for milestones, `.debug` for details
- Never log: drink contents, notes, body metrics, timestamps, or any user personal data
- Log only: error categories (enum case names), counts, operation identifiers, no values
- Example: `logger.error("Health authorization request failed: \(error.localizedDescription)")` — NOT `"User fempter failed..."`

## Comments

**When to Comment:**
- Document the "why" not the "what"; code should be self-explanatory
- Mark complex calculations with derivations or hand-verified constants:
  ```swift
  /// 500 ml × 5% × 0.789 = 19.725 g
  var pureAlcoholGrams: Double { volumeMl * abv * 0.789 }
  ```
- Document non-obvious state transitions or edge cases:
  ```swift
  /// When true, a successful `requestAuthorization()` flips `status` to `.authorized` 
  /// — models a real device where a fresh process reports a stale `.notDetermined`.
  var authorizesOnRequest = false
  ```
- Reference ADRs/plans for architectural decisions: `// plan-0023`, `// ADR-0006`

**JSDoc/TSDoc:**
- Use `///` for public APIs and types (all `@Model`, public functions)
- Use `//` for internal logic comments
- Keep doc comments concise; link to detailed docs via ADR/plan references
- Example:
  ```swift
  /// When this record was **created** (logged), as opposed to when the drink was
  /// consumed. Non-optional. New inserts seed it from `consumptionDate`; the V1→V2
  /// migration backfills existing rows with their `consumptionDate`.
  var creationDate: Date = Date(timeIntervalSince1970: 0)
  ```

## Function Design

**Size:**
- Keep functions under 20 lines. Aim for <15
- If a function has more than one clear responsibility, split it
- Nested helpers are acceptable; extract to separate file if >30 lines total

**Parameters:**
- Named parameters always; avoid positional overloads
- Use default values for optional parameters: `func duplicated(consumptionDate: Date = .now)`
- Avoid excessive parameters; use structs for >3 related params

**Return Values:**
- Prefer simple returns. Avoid returning optionals for error cases; throw instead
- Early returns for guard/precondition logic
- Computed properties for derived values: `var pureAlcoholGrams: Double { ... }`

## Module Design

**Exports:**
- SwiftUI views are `struct`, never `class`
- View models are `@Observable @MainActor final class`
- Domain models are `@Model final class` (SwiftData) or `struct` (value types)
- Services are `@MainActor final class`

**Barrel Files:**
- No barrel files (index.ts style); every file is explicit

**File Organization (within a file):**
1. Imports
2. Type/struct/class definition with main responsibility
3. Extensions for computed properties and helper methods
4. Nested types (if any)
5. Preview/fixture data in separate file or at end of same file if <30 lines

**Example structure from `ConsumptionEvent.swift`:**
```swift
import Foundation
import SwiftData

@Model final class ConsumptionEvent {
    // MARK: - Properties
    var uuid: UUID = UUID()
    var volumeMl: Double = 0
    
    // MARK: - Computed values
    var pureAlcoholGrams: Double { ... }
    
    // MARK: - Initializer
    init(...) { ... }
    
    // MARK: - Methods
    func touch() { ... }
}

extension ConsumptionEvent {
    // MARK: - Display
    func displayName(in unitSystem: UnitSystem) -> String { ... }
}

extension ConsumptionEvent {
    // MARK: - Previews
    static var previewBeer: ConsumptionEvent { ... }
}
```

## Strings & Localization

**All user-facing strings use `String(localized:)`:**
```swift
Text(String(localized: "tab.home"))
Text(String(localized: "editDrink.customName"))
String(format: String(localized: "import.error.unsupportedVersion"), v)
```

**Keys:**
- Structured with dot notation: `tab.home`, `editDrink.customName`, `import.error.unsupportedVersion`
- Never interpolate PII or user data directly; use format strings with numbered placeholders

**Language:**
- English only; no other languages in documentation, comments, or code

## Type Usage

**Prefer value types:**
- Use `struct` for simple data containers, pure functions, value semantics
- Use `enum` for type-safe options (never string/int tags)
- Use `final class` only for:
  - SwiftUI views
  - SwiftData `@Model` entities
  - `@Observable` view models
  - Services (platform capabilities)

**Concurrency:**
- `@MainActor` on all `@Observable` view models
- `@MainActor` on all service types
- Test structs can be `@MainActor` for UI-related tests
- Use `async/await` and structured concurrency; no completion handlers

**Sendability:**
- Mark types as `Sendable` where appropriate (immutable value types)
- Use `@unchecked Sendable` only for test fakes that are always accessed on MainActor
- Never suppress concurrency warnings; fix the root cause

---

*Convention analysis: 2026-07-18*
