# Phase 3: App Startup Hardening - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 9 (5 modified, 4 new)
**Analogs found:** 9 / 9

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `drinkpulse/drinkpulseApp.swift` (modified) | provider (`App` root, container lifecycle) | event-driven (state machine over async load) | itself (existing file, being restructured) | exact — edit in place |
| `drinkpulse/Features/Shell/RootShellView.swift` (modified) | component (root shell view) | request-response (view gating) | itself (existing file, remove reverse-write) | exact — edit in place |
| `drinkpulse/Domain/Persistence/UserProfileStore.swift` (modified) | model/service (persistence helper) | CRUD | itself (existing file, add `context.save()`) | exact — edit in place |
| `drinkpulse/Domain/Persistence/ContainerLoadState.swift` (new) | model (state enum) | event-driven | `UITestSeed.swift` (small enum-like static-namespace file, launch-arg-gated flags) for file-header/doc-comment convention; shape itself modeled on RESEARCH.md Pattern 1 | role-match |
| `drinkpulse/Domain/Persistence/StartupError.swift` (new) | model (error categorization) | transform (Error → coarse category) | `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (same folder, same `OSLog` + `nonisolated`/`@MainActor` conventions, non-PII logging discipline) | exact (folder + logging convention) |
| `drinkpulse/Features/Shell/StartupErrorView.swift` (new) | component (full-screen error view) | request-response (retry action) | `drinkpulse/Features/History/HistoryView.swift` `emptyState` (`ContentUnavailableView` usage) | role-match |
| `docs/decisions/0012-onboarding-single-source-of-truth.md` (new) | config/doc (ADR) | — | `docs/decisions/0011-health-write-back-and-device-local-sample-identity.md` | exact |
| `drinkpulseUITests/Features/Shell/OnboardingAuthorityUITests.swift` (new) | test (UI regression) | request-response (drive UI, assert view state) | `drinkpulseUITests/Features/Onboarding/OnboardingFlowUITests.swift` | exact |
| `drinkpulseTests/Domain/Persistence/StartupErrorTests.swift` (new) | test (unit) | transform | `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift` (same folder/target, same domain) | exact (folder + subject matter) |

## Pattern Assignments

### `drinkpulse/drinkpulseApp.swift` (provider, event-driven — modified in place)

**Analog:** itself (current on-disk state) + RESEARCH.md Pattern 1 for the target shape.

**Current eager stored-property pattern to REMOVE** (`drinkpulseApp.swift:47-70`):
```swift
var sharedModelContainer: ModelContainer = {
    let schema = Schema([...])
    if UITestSeed.isActive {
        do { return try UITestSeed.makeContainer(schema: schema) }
        catch { fatalError("UITestSeed: could not create in-memory container: \(error)") }
    }
    let modelConfiguration = StoreBootstrap.productionConfiguration(schema: schema)
    do { return try StoreBootstrap.makeContainer(schema: schema, configuration: modelConfiguration) }
    catch { fatalError("Could not create ModelContainer: \(error)") }
}()
```
Both `fatalError` sites (lines 59, 68) are STARTUP-03's target — replace with `containerState = .failed(...)`.

**Existing `@State`-flag-in-`App`-struct convention to reuse for `containerState`** (`drinkpulseApp.swift:33-37`):
```swift
/// One-shot flag: when `-dp_force_onboarding YES` is active, starts `true`
/// and flips to `false` after `OnboardingView.onFinish` fires, allowing
/// the normal `onboardingDone` gate to take over. Inert in production
/// (UITestSeed.forceShowOnboarding is always false outside UI tests).
@State private var forceOnboardingPending = UITestSeed.forceShowOnboarding
```
This is the literal precedent D-12/RESEARCH.md Pattern 1 points to — `containerState: ContainerLoadState` should be declared the same way (a plain `@State private var` initialized from a static/derived value, with a doc comment explaining production-vs-UI-test behavior).

**Existing `.modelContainer(_:)` attachment point to move** (`drinkpulseApp.swift:99`):
```swift
var body: some Scene {
    WindowGroup {
        Group { ... }
        .preferredColorScheme(preferredColorScheme)
        .environment(\.healthService, healthService)
    }
    .modelContainer(sharedModelContainer)   // ← currently at Scene level; RESEARCH.md
                                              //   Pitfall 2 says this must move to the
                                              //   `.ready` case's subtree only.
}
```

**`init()` pattern to preserve unchanged** (`drinkpulseApp.swift:20-32`) — keep cheap/synchronous; do not add container work here:
```swift
init() {
    UITestSeed.resetTransientDefaults()
    if UITestSeed.seedPendingOpenInsights {
        UserDefaults.standard.set(true, forKey: AppStorageKeys.pendingOpenInsights)
    }
    UNUserNotificationCenter.current().delegate = notificationHandler
}
```

**UI-test container branch to preserve, now inside the `.task`** (`drinkpulseApp.swift:53-61`):
```swift
if UITestSeed.isActive {
    do { return try UITestSeed.makeContainer(schema: schema) }
    catch { /* now: containerState = .failed(StartupError(underlying: error)) */ }
}
```

---

### `drinkpulse/Features/Shell/RootShellView.swift` (component, request-response — modified in place)

**Analog:** itself.

**Block to DELETE entirely (D-01)** (`RootShellView.swift:97-99`):
```swift
.onChange(of: profiles.isEmpty) { _, isEmpty in
    if isEmpty { onboardingDone = false }
}
```
No replacement observer. `@Query private var profiles: [UserProfile]` (line 17) stays for any other reads in the file but must not gate `onboardingDone` after this change — grep the rest of the file to confirm no other read of `profiles` implicitly depends on this side effect.

**Existing `@AppStorage` usage convention to match for any new flag** (`RootShellView.swift:7-9`):
```swift
@AppStorage(AppStorageKeys.onboardingDone) private var onboardingDone = false
@AppStorage(AppStorageKeys.pendingAddDrink) private var pendingAddDrink = false
@AppStorage(AppStorageKeys.pendingOpenInsights) private var pendingOpenInsights = false
```
Keys are declared centrally in `drinkpulse/DesignSystem/AppStorageKeys.swift` (e.g. line 6 `static let onboardingDone = "dp_onboarding_done"`) — any new persisted key for D-03's test hook should be added there, following the same `"dp_..."` naming convention.

**Existing UI-test-only probe pattern to copy for D-03's mid-session-deletion hook** (`RootShellView.swift:86-96`):
```swift
.overlay(alignment: .topLeading) {
    // UI-test-only probe (W5 Health-write regression). Surfaces the live
    // Health sample count so XCUITest can assert a sample was written on
    // add. Gated on -dp_uitest; never added in production.
    if UITestSeed.isActive {
        Text(verbatim: "\(healthSampleCount)")
            .font(.system(size: 1))
            .foregroundStyle(.clear)
            .accessibilityIdentifier("dp_health_sample_count")
    }
}
```
D-03 needs a similarly gated hook (likely a launch-argument-triggered `.task`/`.onAppear` action that deletes the seeded profile mid-session via `modelContext.delete`) — same `UITestSeed.isActive` guard style, same "never touches production" comment discipline.

---

### `drinkpulse/Domain/Persistence/UserProfileStore.swift` (model/service, CRUD — modified in place)

**Analog:** itself.

**Exact spot for D-04's fix** (`UserProfileStore.swift:24-32`):
```swift
@MainActor
static func fetchOrCreate(in context: ModelContext) -> UserProfile {
    if let profile = deduplicated(in: context) {
        return profile
    }
    let profile = UserProfile()
    context.insert(profile)
    return profile   // ← add `try? context.save()` before this return (D-04)
}
```

**Existing non-PII logging pattern in the same file to match** (`UserProfileStore.swift:47-49`):
```swift
if profiles.count > 1 {
    log.info("UserProfileStore collapsed \(profiles.count, privacy: .public) profiles to 1")
}
```
Counts/enum cases are `.public`; no model field values are ever logged — same discipline applies to any new logging around the save fix.

**Reminder (Pitfall 5, RESEARCH.md):** grep all call sites of `UserProfileStore.fetchOrCreate` before adding the save — currently only `RootShellView.swift` in production code (confirmed via the codebase read above); `UserProfileStoreTests.swift` also calls it and separately calls `context.save()` redundantly, which stays harmless.

---

### `drinkpulse/Domain/Persistence/ContainerLoadState.swift` (new — model, event-driven)

**Analog:** RESEARCH.md Pattern 1 (synthesized shape) + `UITestSeed.swift`'s file-header doc-comment convention.

**Shape to implement** (from RESEARCH.md, adapted to this codebase's doc-comment style seen in `UITestSeed.swift`/`StoreBootstrap.swift`):
```swift
import SwiftData

/// Tri-state model for `sharedModelContainer`'s async lifecycle (STARTUP-02).
/// Populated from a `.task` in `drinkpulseApp`, never from `App.init` — see
/// ADR-0009 for `MigrationPlan` context and `StoreBootstrap.makeContainer`
/// for the underlying open/recover sequence this state machine wraps.
enum ContainerLoadState {
    case loading
    case ready(ModelContainer)
    case failed(StartupError)
}
```
Doc-comment tone should match `StoreBootstrap.swift`'s header comments (explain *why*, reference plan/ADR numbers, note MainActor/threading posture).

---

### `drinkpulse/Domain/Persistence/StartupError.swift` (new — model, transform)

**Analog:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift` (same folder, same logging + actor-isolation conventions).

**Imports + logger pattern to copy** (`StoreBootstrap.swift:1-5`):
```swift
import Foundation
import SwiftData
import OSLog

private nonisolated let log = Logger(subsystem: "com.drinkpulse.app", category: "persistence")
```

**Non-PII categorization pattern (own logging call to model after)** (`StoreBootstrap.swift:85`):
```swift
log.error("Store files moved to RecoveredStores snapshot — category: recovery")
```
Note the "category: X" string convention already used for non-PII log messages — `StartupError.diagnosticSummary` should follow the identical `"startup-error-category: <case>"` shape (see RESEARCH.md's Code Examples section, already drafted in this style).

**Core shape** (from RESEARCH.md, Pitfall 1):
```swift
enum StartupError: Error, Equatable {
    case storeUnavailable
    case unknown

    var diagnosticSummary: String {
        switch self {
        case .storeUnavailable: "startup-error-category: store-unavailable"
        case .unknown:          "startup-error-category: unknown"
        }
    }

    init(underlying: Error) {
        self = .storeUnavailable
    }
}
```
**Never** interpolate `underlying.localizedDescription` or any `ModelConfiguration.url` into `diagnosticSummary` — matches CLAUDE.md logging rule and D-08.

---

### `drinkpulse/Features/Shell/StartupErrorView.swift` (new — component, request-response)

**Analog:** `drinkpulse/Features/History/HistoryView.swift`'s `emptyState` (`ContentUnavailableView` idiom already established in this codebase).

**Existing `ContentUnavailableView` usage to model from** (`HistoryView.swift:159-165`):
```swift
private var emptyState: some View {
    ContentUnavailableView(
        String(localized: "history.emptyTitle"),
        systemImage: "wineglass",
        description: Text(String(localized: "history.emptyDescription"))
    )
}
```
`StartupErrorView` needs the richer 3-closure initializer (`label:`/`description:`/`actions:`) since it needs a Retry button + spinner + ShareLink, per RESEARCH.md's Code Examples section — same `String(localized:)` string convention, same `systemImage:` icon usage (`"exclamationmark.triangle"` per D-05's "icon + plain-language message + action button(s)").

**`AddDrinkButton`-style button pattern for reference** (button placed in a toolbar elsewhere in `RootShellView.swift`, e.g. `AddDrinkButton { showAddDrink = true }` at line 31) — confirms the codebase's convention of small, dedicated button components taking a closure; `StartupErrorView`'s Retry button can follow the same `Button(action:)` + `.accessibilityLabel(String(localized:))` shape already used project-wide (see `RootShellView.swift:90-95` for the `.accessibilityIdentifier` precedent on test-only elements, though this button is production-facing so use `.accessibilityLabel` instead).

**Spinner-while-in-flight pattern** — no exact analog found in the codebase for a disabled-button-with-spinner; use RESEARCH.md's drafted shape directly:
```swift
Button(action: onRetry) {
    if isRetrying { ProgressView() } else { Text(String(localized: "startup.error.retry")) }
}
.disabled(isRetrying)
```

---

### `docs/decisions/0012-onboarding-single-source-of-truth.md` (new — config/doc)

**Analog:** `docs/decisions/0011-health-write-back-and-device-local-sample-identity.md`

**Header + structure pattern to copy** (`0011-...md:1-8`):
```markdown
# ADR-0011 — Apple Health write-back & device-local sample identity

**Status**: accepted (plan-0036)
**Date**: 2026-06-29
**Builds on**: [ADR-0008](0008-services-layer.md) (Services layer),
[ADR-0009](0009-versioned-schema-and-migration-plan.md) / ...

## Context
...
## Decision
1. ...
## Consequences
```
ADR-0012 should follow the same `# ADR-NNNN — Title` / `**Status**` / `**Date**` / `**Builds on**` header block, then `## Context` → `## Decision` (numbered list) → `## Consequences` sections. "Builds on" should reference ADR-0009 (schema/migration) since D-02's contract touches the same persistence area. Content: the D-01/D-02 single-source-of-truth rule and the explicit obligation on any future delete-profile/delete-all-data flow to set `onboardingDone = false` itself.

---

### `drinkpulseUITests/Features/Shell/OnboardingAuthorityUITests.swift` (new — test, request-response)

**Analog:** `drinkpulseUITests/Features/Onboarding/OnboardingFlowUITests.swift`

**File header + launch-argument-gated launch helper pattern to copy** (`OnboardingFlowUITests.swift:1-22, 133-146`):
```swift
import XCTest

/// ... doc comment explaining scope and launch-arg hooks used ...
@MainActor
final class OnboardingFlowUITests: XCTestCase {
    ...
    private func launchApp() -> XCUIApplication {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += [
            "-dp_uitest", "YES",
            "-dp_force_onboarding", "YES",
        ]
        app.launch()
        return app
    }
}
```
New file (D-03) should add its own launch-argument (e.g. `-dp_uitest_delete_profile_midsession YES`, per CONTEXT.md's "extend the existing convention" instruction) rather than a parallel mechanism, following the same `app.launchArguments += [...]` idiom, then assert `app.tabBars.buttons["Home"]` (or another `RootShellView` marker) still exists / `OnboardingView`'s `"Get Started"` button does NOT reappear — same `waitForExistence(timeout:)` idiom used throughout this file (e.g. line 54).

**Assertion style to reuse** (`OnboardingFlowUITests.swift:53-57`):
```swift
let homeTab = app.tabBars.buttons["Home"]
XCTAssertTrue(homeTab.waitForExistence(timeout: 10),
              "Tab bar with Home tab should appear after onboarding completion")
XCTAssertTrue(homeTab.isSelected, "Home tab should be the selected tab after onboarding")
```
For D-03, the equivalent assertion is the *negative* — that `OnboardingView`'s content does NOT appear after the mid-session delete hook fires, while `RootShellView`'s tab bar stays present.

---

### `drinkpulseTests/Domain/Persistence/StartupErrorTests.swift` (new — test, transform)

**Analog:** `drinkpulseTests/Domain/Persistence/StoreBootstrapTests.swift` (same target/folder — read it directly to match Swift Testing (`@Test`/`#expect`) conventions already used there for the `Domain/Persistence` layer; no additional excerpt needed beyond confirming file location/target mirroring per CLAUDE.md's "Test organization" rule — `drinkpulse/Domain/Persistence/StartupError.swift` → `drinkpulseTests/Domain/Persistence/StartupErrorTests.swift`).

## Shared Patterns

### Non-destructive recovery / retry re-invocation
**Source:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:41-55` (`makeContainer`)
**Apply to:** `drinkpulseApp.swift`'s `retryContainerLoad()`/`loadContainerIfNeeded()` and `StartupErrorView`'s Retry action.
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
Retry must call this exact entry point again (D-06) — never a "just make an empty store" shortcut.

### `@AppStorage` key naming/central declaration
**Source:** `drinkpulse/DesignSystem/AppStorageKeys.swift:6,15` (`"dp_onboarding_done"`, `"dp_pending_add_drink"`)
**Apply to:** any new persisted flag this phase introduces (should not be needed for D-01–D-11's core work, but relevant if D-03's test hook needs a persisted — not just launch-argument — flag).

### Launch-argument-gated test hook convention
**Source:** `drinkpulse/UITestSeed.swift:23-55` (`isActive`, `forceShowOnboarding`, `seedPendingOpenInsights` — all `ProcessInfo.processInfo.arguments`-based, evaluated once, inert in production)
**Apply to:** D-03's new delete hook and D-05/D-06's new "force store failure" hook (`-dp_uitest_force_store_failure YES` per RESEARCH.md's Wave 0 Gaps) — both must follow this exact static-let/argument-index pattern, never a parallel mechanism (UserDefaults toggle, environment variable, etc.).

### Non-PII logging / error categorization
**Source:** `drinkpulse/Domain/Persistence/StoreBootstrap.swift:5, 49, 85` (`Logger(subsystem: "com.drinkpulse.app", category: "persistence")`, `log.error("... — attempting non-destructive recovery")`, `log.error("... category: recovery")`)
**Apply to:** `StartupError`'s categorization and any new logging in `UserProfileStore`/`drinkpulseApp` touched by this phase — category/code only, never `localizedDescription` or file paths, matching CLAUDE.md's logging rules and ASVS V7/V8 per RESEARCH.md's Security Domain section.

### `ContentUnavailableView` empty/error-state idiom
**Source:** `drinkpulse/Features/History/HistoryView.swift:159-165`
**Apply to:** `StartupErrorView` — reuse the same component rather than hand-rolling new chrome, per RESEARCH.md's Code Examples section.

## No Analog Found

None — all 9 files/changes have a usable analog (either an existing file being edited in place, or an existing sibling file establishing the relevant convention). The `ContainerLoadState`/`StartupError`/`StartupErrorView` triad has no *literal* prior instance in this codebase (first designed error-state screen), but RESEARCH.md's Code Examples section already supplies a concrete, codebase-consistent shape, and the underlying conventions (logging, `ContentUnavailableView`, `@State`-flag-in-`App`-struct) all have direct analogs listed above.

## Metadata

**Analog search scope:** `drinkpulse/` (app target), `drinkpulseTests/`, `drinkpulseUITests/`, `docs/decisions/`
**Files read:** `drinkpulseApp.swift`, `RootShellView.swift`, `StoreBootstrap.swift`, `UserProfileStore.swift`, `UITestSeed.swift`, `HistoryView.swift` (partial), `OnboardingFlowUITests.swift`, `AppStorageKeys.swift` (partial), `0011-health-write-back-and-device-local-sample-identity.md` (partial)
**Pattern extraction date:** 2026-07-27
