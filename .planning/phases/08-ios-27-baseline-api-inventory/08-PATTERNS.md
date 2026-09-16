# Phase 08: iOS 27 Baseline & API Inventory - Pattern Map

**Mapped:** 2026-09-16  
**Files analyzed:** 10 planned artifacts or edits, plus 8 source audit areas  
**Analogs found:** 10 / 18 (audit areas have representative source, not a single file analog)

## File Classification

| New/modified file or audit area | Role | Data flow | Closest tracked analog | Match |
|---|---|---|---|---|
| `drinkpulse.xcodeproj/project.pbxproj` | config | build configuration | same file, Debug/Release target blocks | exact |
| `README.md` | documentation | developer instructions | same file, Development section | exact |
| `CLAUDE.md` | documentation | developer instructions | same file, Build & verify section | exact |
| `.planning/PROJECT.md` | documentation | project state | same file, Constraints section | exact |
| `.claude/context/current-focus.md` | documentation | project state | same file, Status section | exact |
| `08-BASELINE.md` (proposed) | evidence document | batch build/test | shared Xcode scheme and README commands | partial |
| `08-INVENTORY.md` (proposed) | inventory document | batch source review | `08-RESEARCH.md` coverage map and candidate schema | partial, planning source |
| `08-DECISION-<slug>.md` (conditional) | decision document | approval workflow | `docs/decisions/0012-onboarding-single-source-of-truth.md` | partial |
| App entry/startup and `Features/` | component/provider audit | event-driven and CRUD | `HistoryListQueryView.swift` | representative |
| `DesignSystem/` and `Diagnostics/` | component/utility audit | transform/event-driven | `DPGlass.swift`, `ViewLoadLogger.swift` | representative |
| `Domain/` and `Domain/DataTransfer/` | model/utility audit | transform/file-I/O | `BackupExport.swift` | representative |
| `Domain/Persistence/` | model/service audit | CRUD/migration | `MigrationPlan.swift` | representative |
| `Services/` | service audit | async request-response/event-driven | `NotificationScheduling.swift` | representative |
| `drinkpulseTests/` | test audit | request-response | `HealthWriteHooksTests.swift` | representative |
| `drinkpulseUITests/` | test audit | event-driven | `OnboardingFlowUITests.swift` | representative |
| `drinkpulse.xcodeproj/` and active tooling docs | config/documentation audit | batch build/test | project settings, shared scheme, README | representative |

The audit rows name **coverage areas**, not a proposal to edit every source file. Phase 08 inventories source and routes implementation candidates to Phases 09–10. The frozen `SchemaV1.swift`–`SchemaV4.swift` files are read-only review surfaces.

## Pattern Assignments

### `drinkpulse.xcodeproj/project.pbxproj` (config, build configuration)

**Analog:** same tracked file. Update the six existing deployment settings in place and retain Swift 6 language mode. Unit test Release is at line 283, project Debug/Release at 346/405, unit test Debug at 480, UI test Debug/Release at 495/512. The app inherits the project setting.

```text
// drinkpulse.xcodeproj/project.pbxproj:436-440
SWIFT_APPROACHABLE_CONCURRENCY = YES;
SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor;
SWIFT_EMIT_LOC_STRINGS = YES;
SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES;
SWIFT_VERSION = 6.0;
```

Verify effective settings for three targets in Debug and Release. Do not write `SWIFT_VERSION = 6.4`; that is the compiler release.

### Living docs (documentation, developer instructions)

**Analogs:** `README.md:116-131`, `CLAUDE.md:519-535`, `.planning/PROJECT.md:325-332`, `.claude/context/current-focus.md:5-11`. Replace present-tense toolchain and destination claims after selecting the actual simulator; preserve dated historical notes.

```bash
# README.md:120-129, current command shape to update
xcodebuild -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  build
xcodebuild test -scheme drinkpulse \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

`CLAUDE.md:31-43` requires official Apple documentation for API behavior. Apply that evidence rule to inventory claims. `README.md:6`, `CLAUDE.md:10,36`, `.planning/PROJECT.md:9-10,331`, and `.claude/context/current-focus.md:5-11` contain current-state claims to reconcile.

### `08-BASELINE.md` (evidence document, batch build/test)

**Analogs:** tracked shared scheme and README. The scheme declares both testables as active:

```xml
<!-- drinkpulse.xcodeproj/xcshareddata/xcschemes/drinkpulse.xcscheme:45-64 -->
<TestableReference skipped = "NO" parallelizable = "NO">
  <BuildableReference BuildableName = "drinkpulseTests.xctest" BlueprintName = "drinkpulseTests" />
</TestableReference>
<TestableReference skipped = "NO">
  <BuildableReference BuildableName = "drinkpulseUITests.xctest" BlueprintName = "drinkpulseUITests" />
</TestableReference>
```

Use the project/scheme/destination form from README, adding explicit Debug and Release configurations, separate result bundles, exit codes, `xcresulttool` counts, complete raw log paths and SHA-256 hashes. No current tracked baseline manifest provides a closer analog; `08-RESEARCH.md` supplies a planning skeleton.

### `08-INVENTORY.md` and conditional `08-DECISION-<slug>.md` (documents, batch review/approval)

**Analog:** `08-RESEARCH.md` inventory schema and coverage map (planning source); no existing production file has the same role. One row per distinct API/pattern, all exact occurrences, official source and lookup date, availability, evidence, disposition, reason, priority, phase, and brief/outcome link. Add a no-candidate row for every reviewed area. Briefs are separate for behavior, accessibility, data, lifecycle, or integration-sensitive candidates; include owner approve/retain/defer outcome before downstream execution.

### Source audit surfaces (components, services, models, tests)

Use these tracked excerpts to recognize existing behavior and avoid proposing a replacement from a search hit alone:

```swift
// drinkpulse/Features/History/HistoryListQueryView.swift:24-28,38-40,73-80
_events = Query(filter: #Predicate<ConsumptionEvent> { $0.consumptionDate >= windowStart },
                sort: \ConsumptionEvent.consumptionDate, order: .reverse)
List { ForEach(rows) { row in /* row rendering */ } }
.listStyle(.plain)
.onChange(of: events.map(\.modifiedDate), initial: true) { _, _ in refreshRows() }
.onChange(of: scenePhase) { _, phase in if phase == .active { refreshRows() } }
```

History's List/ScrollView/context-menu behavior has prior workaround evidence; verify on iOS 27 before recommending removal.

```swift
// drinkpulse/Services/NotificationScheduling.swift:4-19
protocol NotificationScheduling: Sendable {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
    func pendingRequestIdentifiers() async -> [String]
    func removePendingRequests(withIdentifiers ids: [String])
}
extension UNUserNotificationCenter: @retroactive @unchecked Sendable {}
```

Review the unchecked Sendable conformance against current official Swift guidance and call-site behavior; retain pending proof of a safe replacement.

```swift
// drinkpulse/Domain/Persistence/MigrationPlan.swift:7-14,58-61
enum MigrationPlan: SchemaMigrationPlan {
    nonisolated static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self, SchemaV4.self]
    }
    nonisolated static var stages: [MigrationStage] { [v1ToV2, v2ToV3, v3ToV4] }
    nonisolated static let v3ToV4 = MigrationStage.lightweight(
        fromVersion: SchemaV3.self, toVersion: SchemaV4.self)
}
```

```swift
// drinkpulse/Domain/DataTransfer/BackupExport.swift:19-37
static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(exportedContentType: .json) { export in
        SentTransferredFile(try export.writeTempFile())
    }.suggestedFileName { $0.fileName }
}
func writeTempFile() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
    try encoded().write(to: url, options: .atomic)
    return url
}
```

```swift
// drinkpulseTests/Services/HealthWriteHooksTests.swift:1-8,32-44
import Testing
@testable import drinkpulse
@MainActor @Suite(.serialized) struct HealthWriteHooksTests {
    @Test func write_invokesService_andStampsUUID_whenEnabled() async throws {
        // in-memory container and fake service
        #expect(fake.saveCount == 1)
    }
}
// drinkpulseUITests/Features/Onboarding/OnboardingFlowUITests.swift:1-4,8-16
import XCTest
@MainActor final class OnboardingFlowUITests: XCTestCase {
    func test_fullWalkthrough_landsOnHome() throws {
        let app = launchApp()
        XCTAssertTrue(app.buttons["Continue"].waitForExistence(timeout: 5))
    }
}
```

The excerpts above are compact pattern illustrations; inspect exact source lines before editing or citing an inventory occurrence.

## Shared Patterns

- **No app authentication layer:** privacy relies on on-device storage. Do not invent an auth or server pattern for this audit.
- **Error and data safety:** `MigrationPlan.swift:20-39` propagates fetch/save errors and logs counts, not health values; `BackupExport.swift:26-37` propagates encoding/file errors and writes atomically.
- **Test isolation:** `HealthWriteHooksTests.swift:10-25` restores UserDefaults with `defer` and creates an in-memory SwiftData container. UI tests use launch helpers and accessibility queries.
- **Evidence:** shared scheme includes both test targets; a passing console banner alone does not report counts or skipped tests. Preserve `.xcresult` and parse it.
- **Tracked-source gate:** all named source analogs above were confirmed by `git ls-files`; no install/runtime mirror path is used.

## No Analog Found

| File | Role | Data flow | Reason |
|---|---|---|---|
| `08-BASELINE.md` | evidence document | batch | No prior tracked iOS 27 baseline manifest; use research skeleton and scheme. |
| `08-INVENTORY.md` | inventory document | batch | No prior tracked full API inventory; use research schema. |
| `08-DECISION-<slug>.md` | decision document | approval | Existing ADRs document decisions, but not this candidate-by-candidate owner outcome format. |

## Metadata

**Analog search scope:** tracked app, test, Xcode project, active docs, phase research.  
**Files scanned:** 12 source/config/doc analogs and the two required phase inputs.  
**Pattern extraction date:** 2026-09-16.
