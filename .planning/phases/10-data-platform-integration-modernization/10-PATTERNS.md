# Phase 10: Data & Platform Integration Modernization - Pattern Map

**Mapped:** 2026-11-08
**Files analyzed:** 22 new/modified (plus 3 doc/device artifacts)
**Analogs found:** 20 / 22
**All analog paths verified git-tracked (`git ls-files`).**

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match |
|---|---|---|---|---|
| `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (add reporting seam) | service/persistence | request-response | itself (lines 18-32) | exact |
| `drinkpulse/Services/NotificationActionHandler.swift` (extract `route`) | service | event-driven | itself (lines 9-25) | exact |
| `drinkpulse/Services/HealthKitAdapter.swift` (drop `@unchecked`) | service adapter | request-response | itself (line 4) | exact |
| `drinkpulse/Services/WeeklySummaryService.swift` (`now:`/`calendar:` seam) | service | batch | itself (`scheduleIfEnabled`) | exact |
| `drinkpulse/Localizable.xcstrings` (D-16 copy, after brief) | config | transform | existing `weeklySummary.notification.body.*` keys | exact |
| `drinkpulse/UITestSeed.swift` (warm-tap launch arg) | utility | event-driven | `seedPendingOpenInsights` (lines 24-30) | exact |
| `drinkpulse/Features/Shell/RootShellView.swift` (warm-tap hook) | component | event-driven | its `onChange(of: scenePhase)` (94-99) | exact |
| `drinkpulseTests/Domain/Persistence/MigrationFixtures.swift` | test util | file-I/O | `MigrationTests.swift` helpers (9-33, 114-129) | role-match |
| `drinkpulseTests/Domain/Persistence/MigrationChainTests.swift` | test | file-I/O | `MigrationTests.swift` | exact |
| `drinkpulseTests/Domain/Persistence/MigrationSweepTests.swift` | test | CRUD | `RecordDeduplicatorTests.swift` + `MigrationTests` | role-match |
| `drinkpulseTests/Domain/DataTransfer/SanitizedBackupFixtureTests.swift` | test | transform | `DataImporterUpsertTests.swift` | exact |
| `drinkpulseTests/Domain/DataTransfer/Fixtures/sanitized-export-v2.json` | fixture | file-I/O | none | none |
| `drinkpulseTests/Services/HealthServiceConcurrencyTests.swift` | test | event-driven | `HealthServiceTests.swift` + `FakeHealthStore.swift` | exact |
| `drinkpulseTests/Services/ReminderServiceCancellationTests.swift` | test | event-driven | `ReminderServiceTests.swift` (`FakeNotificationCenter`) | exact |
| `drinkpulseTests/Services/WeeklySummaryServiceCancellationTests.swift` | test | event-driven | `WeeklySummaryServiceScheduleTests.swift` | exact |
| `drinkpulseTests/Services/NotificationActionHandlerTests.swift` | test | event-driven | `ReminderServiceTests.swift` | role-match |
| `drinkpulseTests/Services/WeeklySummaryCopyTests.swift` | test | transform | `WeeklySummaryServiceScheduleTests.swift:~114` | role-match |
| `drinkpulseUITests/Features/Shell/WeeklySummaryTapUITests.swift` (warm test) | UI test | event-driven | itself (cold test) | exact |
| `drinkpulseTests/Services/HealthWriteHooksTests.swift:116` (warning fix) | test | n/a | itself | exact |
| Device checklist, concurrency record, owner briefs | docs | n/a | `08-DECISION-C0xx.md` | role-match |

## Pattern Assignments

### `StoreBootstrap.swift` recovery-reporting seam (D-03)

**Analog:** itself, `drinkpulse/Domain/Persistence/StoreBootstrap.swift` lines 18-32. Production signature stays; `makeContainer` delegates.

```swift
@MainActor
static func makeContainer(schema: Schema, configuration: ModelConfiguration) throws -> ModelContainer {
    do {
        return try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [configuration])
    } catch {
        log.error("Store open failed — attempting non-destructive recovery")
        try recoverStore(at: configuration.url)
        let container = try ModelContainer(for: schema, migrationPlan: MigrationPlan.self, configurations: [configuration])
        log.info("Recovery complete — fresh container is open")
        return container
    }
}
```
New `makeContainerReportingRecovery(...) throws -> (container: ModelContainer, didRecover: Bool)`: same body, return `didRecover: true` in the catch. Logging rule: identifiers/categories only (log lines above are the model). File is 91 lines, headroom OK.

### `NotificationActionHandler.swift` `route(identifier:defaults:)`

**Analog:** itself, lines 9-25. Move the body into a static func taking `UserDefaults`; `didReceive` calls it.

```swift
let id = response.notification.request.identifier
if id == ReminderService.reminderIdentifier {
    UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingAddDrink)
    await MainActor.run { NotificationCenter.default.post(name: Self.didTapReminder, object: nil) }
} else if id == WeeklySummaryService.weeklySummaryIdentifier {
    UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingOpenInsights)
    await MainActor.run { NotificationCenter.default.post(name: Self.didTapWeeklySummary, object: nil) }
}
```
Keep `@unchecked Sendable` (D-12 retain). `UNNotificationResponse` cannot be constructed, hence the seam.

### Warm-tap hook (`UITestSeed.swift` + `RootShellView.swift`)

**Launch-arg analog** (`UITestSeed.swift` 24-30), copy verbatim with a new name:
```swift
static let seedPendingOpenInsights: Bool = {
    let args = ProcessInfo.processInfo.arguments
    guard let idx = args.firstIndex(of: "-dp_uitest_pending_open_insights"),
          args.indices.contains(idx + 1)
    else { return false }
    return args[idx + 1].uppercased() == "YES"
}()
```
**Hook site** (`RootShellView.swift` 94-99); add one-shot branch gated on `UITestSeed.isActive` and the new arg, calling `route(identifier: WeeklySummaryService.weeklySummaryIdentifier)` on return from background:
```swift
.onChange(of: scenePhase) { _, phase in
    if phase == .active {
        Task { await reminderService.scheduleIfEnabled() }
        Task { await weeklySummaryService.scheduleIfEnabled(context: modelContext) }
    }
}
```
Receiving side already exists: `.task { for await _ in NotificationCenter.default.notifications(named: NotificationActionHandler.didTapWeeklySummary) { pendingOpenInsights = false; selectedTab = .insights } }` (lines 110-117). Never reachable without `-dp_uitest`.

### `HealthKitAdapter.swift` (INT-02, D-12)

Line 4: `final class HealthKitAdapter: HealthWriting, @unchecked Sendable {` -> drop `@unchecked`. Stored state is `HKHealthStore` + `HKQuantityType` (both `NS_SWIFT_SENDABLE`) + `Double` (lines 5-8). Record SDK header source and zero-warning build per D-13.

### `MigrationChainTests.swift` / `MigrationFixtures.swift` (D-01..D-03)

**Analog:** `drinkpulseTests/Domain/Persistence/MigrationTests.swift`.

Helpers (lines 9-13, 27-33):
```swift
private func makeTempStoreURL() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("sqlite")
}
defer {
    for suffix in ["", "-wal", "-shm"] {
        let file = url.deletingPathExtension().appendingPathExtension(url.pathExtension + suffix)
        try? fm.removeItem(at: file)
    }
}
```
Legacy seed (lines 114-129), scoped in a `do {}` so the container drops before reopen:
```swift
let v1Schema = Schema(versionedSchema: SchemaV1.self)
let config = ModelConfiguration(schema: v1Schema, url: url)
let container = try ModelContainer(for: v1Schema, configurations: [config])
let profile = SchemaV1.UserProfile(bodyWeightKg: 77, biologicalSex: .male)
let e1 = SchemaV1.ConsumptionEvent(timestamp: eventStamp, volumeMl: 500, abv: 0.05, name: "Beer", category: .beer, icon: "🍺")
context.insert(profile); context.insert(e1); try context.save()
```
Reopen (lines 131-134): `StoreBootstrap.makeContainer(schema:configuration:)`; for D-03 use the new reporting variant and `#expect(!didRecover)`. Suite attrs: `@MainActor struct ...`, Swift Testing. Per-field assertions: copy the style at lines 76-99 (`let p = try #require(profiles.first)`; `#expect(p.field == value)`). Assert per the determinism table in RESEARCH (V1: no uuid/`name` equality; V2: uuid preserved; V3: all exact). Do NOT read `RecoveredStores` (shared dir, Pitfall 4). Shipped `SchemaV1-V4` untouched.

### `MigrationSweepTests.swift` (D-04)

**Analog:** `RecordDeduplicatorTests.swift` lines 1-40 (struct, `@MainActor`, insert + `RecordDeduplicator.dedupe` + fetch count). Call `RecordDeduplicator.sweep(in: context)` (`RecordDeduplicator.swift:18-22`) on the migrated container's `mainContext`; seed exactly one profile; for V1 seed several events with identical field values.

### `SanitizedBackupFixtureTests.swift` (C009, D-07/D-08)

**Analog:** `DataImporterUpsertTests.swift` lines 1-40.
```swift
let r1 = try DataImporter().importData(data, into: context)
try context.save()
let r2 = try DataImporter().importData(data, into: context)
#expect(r2.imported == 0); #expect(r2.skipped == 1)
```
Load the fixture via `Bundle(for:)` (Wave 0 probe, Pitfall 2; fallback Swift string literal). Name must not match gitignored `drinkpulse-backup-*.json`. Assert no `healthKitUUID` key.

### `HealthServiceConcurrencyTests.swift` (F2, D-11)

**Analog:** `HealthServiceTests.swift` lines 1-30 and `FakeHealthStore.swift`.
```swift
@MainActor
struct HealthServiceTests {
    private func makeEvent() -> ConsumptionEvent {
        ConsumptionEvent(volumeMl: 500, abv: 0.05, category: .beer, icon: "🍺")
    }
    // let fake = FakeHealthStore(); let service = HealthService(store: fake); await service.write(event)
```
Fake exposes `samplesByEvent`, `saveCount`, `deleteCount`, `deletedUUIDs` (FakeHealthStore.swift 14-20). Use RESEARCH's probe (write, `Task{update}`, `Task{removeSample(healthKitUUID:eventUUID:)}`) wrapped in `withKnownIssue` until the owner approves the fix. Existing sequential test at `HealthServiceTests.swift:280-292` is the gap being closed.

### `ReminderServiceCancellationTests.swift` / `WeeklySummaryServiceCancellationTests.swift` (F3)

**Analog:** `ReminderServiceTests.swift` lines 6-35 (`FakeNotificationCenter`, defined in the test file, `NotificationScheduling` conformance):
```swift
final class FakeNotificationCenter: NotificationScheduling, @unchecked Sendable {
    func add(_ request: UNNotificationRequest) async throws { addedRequests.append(request); pendingIds.append(request.identifier) }
    func pendingRequestIdentifiers() async -> [String] { pendingIds }
    func removePendingRequests(withIdentifiers ids: [String]) { removedBatches.append(ids); pendingIds.removeAll { ids.contains($0) } }
}
```
Build a `SlowCenter` variant (RESEARCH "Suspending fake") with `add` suspended on a continuation. Service under test: `ReminderService.schedule/cancel` (`ReminderService.swift:51-58`). Weekly: mirror with `WeeklySummaryServiceScheduleTests.swift` setup. Use `makeDefaults()` injected-suite style from `ReminderServiceTests.swift:59`.

### `NotificationActionHandlerTests.swift`

**Analog:** `ReminderServiceTests.swift` (injected `UserDefaults` suite, Swift Testing). Call `route(identifier:defaults:)` with `ReminderService.reminderIdentifier` / `WeeklySummaryService.weeklySummaryIdentifier`; observe `NotificationCenter` post for `didTapReminder` / `didTapWeeklySummary`.

### `WeeklySummaryCopyTests.swift` (D-16, after brief)

**Analog:** `WeeklySummaryServiceScheduleTests.swift` (~line 114, compares to `String(localized:)`; must instead assert explicit wording). Format sites to cover: `WeeklySummaryService.swift:114-128`, `String(format: String(localized: "weeklySummary.notification.body.down"), Int((abs(fraction) * 100).rounded()))`. Strings in `drinkpulse/Localizable.xcstrings` ~2853-2905. Do not change `WeeklySummaryCalculator`.

### `WeeklySummaryTapUITests.swift` warm test (D-14)

**Analog:** same file, cold test (lines 6-18):
```swift
let app = XCUIApplication()
app.launchArguments += ["-dp_onboarding_done", "YES", "-dp_uitest", "YES", "-dp_uitest_pending_open_insights", "YES"]
app.launch()
XCTAssertTrue(app.navigationBars["Insights"].waitForExistence(timeout: 10), "...")
```
Warm: launch with new arm arg (no pending flag), assert not on Insights, `XCUIDevice.shared.press(.home)`, `app.activate()`, assert `navigationBars["Insights"]`. Class is `@MainActor final class ... : XCTestCase`; `continueAfterFailure = false`. Never match system UI labels.

## Shared Patterns

### Test hygiene (all new tests)
**Source:** AGENTS.md Testing + `MigrationTests.swift`. Swift Testing (`@Test`, `#expect`, `try #require`), `@MainActor struct`, `@testable import drinkpulse`, in-memory containers (`ModelConfiguration(schema:isStoredInMemoryOnly: true)` as in `DataImporterUpsertTests.swift:9-12`) except migration tests (unique temp URL). Files placed in mirrored folder; under 300 lines.

### Test-hook gating
**Source:** `UITestSeed.swift:6` `static let isActive = ProcessInfo.processInfo.arguments.contains("-dp_uitest")`. **Apply to:** every new production-side test hook.

### Logging / privacy
**Source:** `StoreBootstrap.swift:5` `Logger(subsystem: "com.drinkpulse.app", category: "persistence")`. No PII; no `print`.

### Services DI
**Source:** protocols `NotificationScheduling`, `HealthWriting`; fakes injected (`HealthService(store: fake)`, `ReminderService(center:defaults:)`). Mock at the protocol.

### Schema immutability / CloudKit-off gate
`git diff --stat main -- drinkpulse/Domain/Persistence/Schemas/` empty; `! grep -qi icloud drinkpulse/drinkpulse.entitlements && ! grep -rn cloudKitDatabase drinkpulse`.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `drinkpulseTests/Domain/DataTransfer/Fixtures/sanitized-export-v2.json` | fixture | file-I/O | No non-Swift resource in test tree; bundling unproven (probe first); owner-scrubbed |
| Device checklist / `10-CONCURRENCY-RECORD.md` / owner briefs | docs | n/a | Use `08-DECISION-C008..C012.md` and 08-CONTEXT D-09..D-11 brief format |
| `withKnownIssue` tests | test | n/a | No existing use in repo; confirm API via Apple docs before use |

## Metadata

**Analog search scope:** `drinkpulse/Domain/Persistence`, `drinkpulse/Services`, `drinkpulse/Features/Shell`, `drinkpulseTests/{Domain,Services}`, `drinkpulseUITests/Features/Shell`
**Pattern extraction date:** 2026-11-08
