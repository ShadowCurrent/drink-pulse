# Phase 2: Swift 6 Language Mode Migration - Research

**Researched:** 2026-07-27
**Domain:** Swift 6 strict concurrency migration (compiler/build-setting flip), SwiftData `@Model` actor isolation, Swift Testing vs. XCTest
**Confidence:** HIGH — the central finding of this research is a directly-executed, reproducible build, not a documentation survey.

## Summary

This phase is smaller than the source todo (`2026-07-26-migrate-app-target-to-swift-6-language-mode.md`) assumed. That todo predicted "the bulk of the work" would be triaging data-race errors across SwiftData `@Model` isolation, `@MainActor` boundaries, and `Sendable` gaps. To find out for certain, this research **actually ran the flip**: `xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug SWIFT_VERSION=6.0 build` (and the same for `-configuration Release`), overriding only the app target's `SWIFT_VERSION` on the command line while every other current build setting (`SWIFT_APPROACHABLE_CONCURRENCY = YES`, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES`) stayed exactly as committed.

**Result: exactly 2 compiler errors, identical in both Debug and Release, zero new warnings, zero deprecated-API diagnostics.** Both errors are the same root cause: `ConsumptionEvent.swift:164` and `:166` (in an `extension ConsumptionEvent { ... }`, calling into `DrinkTypePreset.preset(for:)` and `VolumeOption.name(in:)`) — two pure, stateless helper functions in `Features/AddDrink/DrinkTypePreset.swift` that are missing the `nonisolated` keyword their sibling functions already carry (e.g. `DrinkTypePreset.abvRange(from:through:step:)` right above `preset(for:)` in the same file is already `nonisolated`). This is a one-line-per-site, mechanical fix, not a re-architecture.

**Why the migration is this small:** the codebase was already written in anticipation of the Swift 6 flip. `SWIFT_APPROACHABLE_CONCURRENCY = YES` and `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` are already active on the app target under `SWIFT_VERSION = 5.0` — meaning the compiler is already running its Swift 6-era default-isolation inference today, just without promoting isolation violations to hard errors. On top of that, every `@Observable` view model is already explicitly `@Observable @MainActor`; every `Services/` type is already explicitly `@MainActor` (or `@unchecked Sendable` with a documented rationale for the platform-adapter case); every pure Domain helper (`UnitSystem+Volume.swift`, `AlcoholUnit.swift`, `GuidelineChoice+Limits.swift`, `Currency.swift`, persistence schemas, etc.) already carries explicit `nonisolated`; and one `EnvironmentValues.@Entry` doc comment (`HealthServiceEnvironment.swift`) *explicitly anticipates* "a Swift 6 isolation error" and defaults to `nil` to avoid it. The 2 real errors are a pre-existing gap in that otherwise-consistent pattern, confirmed live via Apple DTS forum guidance: SwiftData `@Model` classes are deliberately **not** MainActor-isolated by default (even under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`) because they must remain usable from non-main-actor `ModelContext`s (background contexts, `@ModelActor`); Apple's own recommendation is to mark such types/members `nonisolated` explicitly — exactly the existing codebase convention.

The SWIFT6-02 deprecated-API sweep also came back essentially empty: a targeted grep across the full deprecated/soft-deprecated API surface (from the `swiftui-expert` skill's `latest-apis.md` quick-lookup table — `onChange(of:perform:)`, `NavigationView`, `actionSheet`, `alert(isPresented:content:)`, `accentColor(_:)` modifier, `tabItem`, `Section(header:...)`, manual `EnvironmentKey`, `MagnificationGesture`/`RotationGesture`, `coordinateSpace(name:)`, `disableAutocorrection`, `UIPasteboard`, `presentationBackground` on sheets) found **zero hits**. All 12 `.onChange(of:)` call sites already use the modern two-parameter or `initial:` forms. The flipped build log itself contained zero `warning:` and zero `deprecated` lines. SWIFT6-02's real work in this phase is confirmation, not migration.

SWIFT6-03 is also narrower than the todo's framing: `HistoryViewModelTests.swift` is **not** an XCTest file — 27 of its ~29 test functions are already Swift Testing (`struct HistoryViewModelTests`, `@Test`, `#expect`); only a second, separate type in the same file, `HistoryViewModelPerformanceTests: XCTestCase` (4 `measure {}` tests), is XCTest. Combined with the standalone `ScreenComputePerformanceTests.swift` (3 more `measure {}` tests), that is exactly 2 XCTest *types* across 2 files — both are performance-profiling harnesses, not correctness tests, and both already compile cleanly today because the test targets are already on `SWIFT_VERSION = 6.0`. Swift Testing has no `measure`/baseline-metrics equivalent (confirmed via web search cross-referencing an Apple Developer Forums thread) — the flip forces no code change here at all; SWIFT6-03 is a documented policy decision, not a compiler-driven fix.

**Primary recommendation:** Flip both `SWIFT_VERSION` settings (Debug + Release, `project.pbxproj:433`/`:468`) to `6.0` in one small task; fix the two `nonisolated` gaps in `DrinkTypePreset.swift`; treat the deprecated-API sweep and the XCTest decision as verification/documentation tasks rather than large migration tasks; then run the full build+test+coverage gate. Budget real time for auditing the 4 existing `@unchecked Sendable` sites against CLAUDE.md's "no suppression without an inline justification comment" rule — none currently carry a comment addressing *why* the unchecked conformance is safe (their doc comments explain the class's purpose, not its concurrency-safety), which is a real, if small, gap this phase's own success criteria surface.

## Architectural Responsibility Map

This is a mobile-only, on-device app (no server tier), so the tier table is adapted to the project's own architecture (`docs/architecture.md`): Views (SwiftUI), ViewModels (`@Observable @MainActor`), Services (platform adapters), Domain (pure calculations + persistence), Persistence (SwiftData `@Model` + `ModelContext`).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Compiler language-mode / strict-concurrency enforcement | Build configuration (`project.pbxproj`) | — | `SWIFT_VERSION` is a per-target build setting; it is not owned by any Swift source tier |
| `@Model` actor isolation (`ConsumptionEvent`, `DrinkTemplate`, `UserProfile`, schema snapshots) | Persistence (Domain/Persistence, Domain/*.swift) | Domain (pure helpers called from `@Model` extensions) | SwiftData model classes must stay `nonisolated` so they remain usable from any `ModelContext`, including future background contexts |
| ViewModel state isolation | ViewModels (Features/*/*ViewModel.swift) | — | Already uniformly `@Observable @MainActor`; no change needed |
| Platform-adapter isolation (`HealthKitAdapter`, `UNUserNotificationCenter` wrapper) | Services | — | Thin framework adapters conforming to a `Sendable` protocol; the app already isolates all call sites to `@MainActor` Services (`HealthService`, `ReminderService`, `WeeklySummaryService`) |
| Pure calculation/formatting helpers (`UnitSystem`, `AlcoholUnit`, `GuidelineChoice`, `DrinkTypePreset`) | Domain / Feature-local pure types | — | Already `nonisolated`-by-convention; the 2 real build errors are a gap in this exact pattern |
| Deprecated SwiftUI API surface | Views (Features/*/*View.swift, Components/) | — | Views own all UI-facing modifier call sites; verified clean via grep + build log |
| Test framework choice (Swift Testing vs. XCTest) | Test targets (`drinkpulseTests`) | — | Independent of the app-target language-mode flip; test targets are already `SWIFT_VERSION = 6.0` |

## Standard Stack

No new external dependencies are introduced by this phase. This is a compiler/toolchain configuration change plus in-place fixes to existing first-party (Apple) framework usage.

### Core (already in use — unchanged)
| Component | Version (verified) | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Swift language mode | 6.0 target (compiler: Swift 6.3.3, Xcode 26.6) `[VERIFIED: xcodebuild -version / swift --version on this machine]` | Strict data-race safety at compile time | This is the phase's entire subject — the CLAUDE.md-claimed guarantee |
| Swift Testing | Bundled with Xcode 26.6 toolchain `[VERIFIED: 44/46 files in drinkpulseTests already use `@Test`/`#expect`]` | Primary test framework | Already the project's dominant test style |
| XCTest | Bundled with Xcode 26.6 toolchain `[VERIFIED: grep]` | Legacy tests + all UI tests + performance `measure {}` | `drinkpulseUITests` (27 files) must stay XCTest — XCUITest has no Swift Testing equivalent; the 2 remaining unit-test XCTest types use `measure {}`, which also has no Swift Testing equivalent `[CITED: Apple Developer Forums thread 774088 — "Suggestion to Add Performance Metrics for SwiftUI in XCTest"; multiple third-party sources agree measure()/XCTMetric are XCTest-only as of this writing]` |

### Supporting
Not applicable — no new libraries. The relevant build settings (already present on the app target, unchanged by this phase):

| Setting | Current value | Role |
|---------|---------------|------|
| `SWIFT_APPROACHABLE_CONCURRENCY` | `YES` | Enables Swift 6.2-era approachable-concurrency diagnostics/inference even under `SWIFT_VERSION = 5.0` `[VERIFIED: project.pbxproj:429,464]` |
| `SWIFT_DEFAULT_ACTOR_ISOLATION` | `MainActor` | SE-0466: unannotated declarations in this module default to `@MainActor` instead of nonisolated `[VERIFIED: project.pbxproj:430,465]` `[CITED: swift-evolution SE-0466 "Control default actor isolation inference"]` |
| `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` | `YES` | Unrelated upcoming-feature flag already adopted | — |
| `SWIFT_VERSION` (app target, Debug+Release) | `5.0` → must become `6.0` | The actual subject of SWIFT6-01 `[VERIFIED: project.pbxproj:433,468 — confirmed still 5.0 as of this research, matching the 2026-07-26 todo snapshot]` |
| `SWIFT_VERSION` (test targets) | Already `6.0` | Confirms the todo's claim that only the app target lags `[VERIFIED: project.pbxproj:274,483,499,516]` |

### Alternatives Considered
Not applicable — there is no alternative to flipping `SWIFT_VERSION`; it is the literal requirement (SWIFT6-01).

**Installation:** N/A — no packages to install.

**Version verification:** `xcodebuild -version` → Xcode 26.6 (Build 17F113); `swift --version` → Apple Swift 6.3.3 (swiftlang-6.3.3.1.3), target `arm64-apple-macosx26.0`. Both confirmed live on the machine that will execute this phase's plan. `[VERIFIED: local toolchain, 2026-07-27]`

## Package Legitimacy Audit

**Not applicable.** This phase installs no new external packages (no SPM dependencies, no CocoaPods, no npm). It is a build-setting change plus edits to existing first-party Swift files. Skip the Package Legitimacy Gate for this phase.

## Architecture Patterns

### System Architecture Diagram — isolation flow for the one real hazard class found

```
SwiftUI View (implicit @MainActor)
        │
        │ calls
        ▼
ConsumptionEvent.displayName(in:) / .baseName(in:)   ← extension method on an
        │                                                @Model class (Persistence tier)
        │ calls                                          NOT MainActor-isolated by
        ▼                                                 default (SwiftData design;
DrinkTypePreset.preset(for:)                              @Model classes must stay
        │                                                 usable from non-main-actor
        │ calls                                           ModelContexts)
        ▼
VolumeOption.name(in:)   ← BEFORE FIX: implicitly @MainActor
                            (default-actor-isolation module default)
                            → call from a nonisolated @Model extension method FAILS
                            AFTER FIX: explicit `nonisolated`
                            → callable from any isolation domain, matches the
                              existing convention (abvRange, all UnitSystem+*.swift
                              helpers, AlcoholUnit, GuidelineChoice+Limits, etc.)
```

A reader can trace this exact path today by running the reproduction command in
"Common Pitfalls" below and reading the two emitted diagnostics.

### Recommended Project Structure
No structural changes. Existing layout (`Domain/`, `Services/`, `Features/<X>/`, `DesignSystem/`) is unaffected; this phase only touches isolation annotations inside existing files plus the two `SWIFT_VERSION` build settings.

### Pattern 1: `nonisolated` on pure Domain/Feature helpers
**What:** Mark any function/property that performs no `@MainActor`-only work (no UI state, no `@Observable` property access) `nonisolated`, regardless of what type it lives on.
**When to use:** Any pure computation reachable from a `nonisolated` context — which, per the Apple DTS guidance below, includes essentially all `@Model` class members and their extensions.
**Example (the fix this phase needs):**
```swift
// Source: existing codebase convention (drinkpulse/Domain/UnitSystem+Volume.swift,
// AlcoholUnit.swift, GuidelineChoice+Limits.swift all already do this)
extension DrinkTypePreset {
    nonisolated static func preset(for category: DrinkCategory) -> DrinkTypePreset {
        // unchanged body — pure switch over Sendable value types
    }
}

extension DrinkTypePreset.VolumeOption {
    nonisolated func name(in unitSystem: UnitSystem) -> String {
        // unchanged body
    }
}
```
This mirrors `DrinkTypePreset.abvRange(from:through:step:)`, which is already `nonisolated` in the same file — the fix restores consistency rather than introducing a new pattern.

### Pattern 2: `@Model` classes stay `nonisolated`, never `@MainActor`
**What:** SwiftData `@Model` classes (`ConsumptionEvent`, `DrinkTemplate`, `UserProfile`, and the four `SchemaVN` snapshot types) are correctly left with no actor annotation. Do NOT add `@MainActor` to a `@Model` class to "fix" an isolation error — that would work today (all current call sites happen to be on the main actor) but forecloses future background-context use (CloudKit sync, background migration) and contradicts Apple's own DTS guidance.
**When to use:** Always, for `@Model` types.
**Example:**
```swift
// Source: Apple Developer Forums thread 788262 (DTS engineer response), corroborated
// by this project's own existing SchemaVN.swift files, all of which mark their
// `versionIdentifier` / `models` statics `nonisolated`.
@Model
final class ConsumptionEvent {
    // no actor annotation — correct
}
```

### Pattern 3: `@unchecked Sendable` for framework adapters, with an explicit safety comment
**What:** `HealthKitAdapter`, `UITestHealthStore`, `UITestNotificationCenter` (classes with private mutable state, e.g. `samplesByEvent: [UUID: UUID]`, `pending: [String]`) and the `UNUserNotificationCenter: @retroactive @unchecked Sendable` extension all use `@unchecked Sendable` today.
**When to use:** When wrapping an Apple framework type not yet marked `Sendable` in the SDK, or when a class's mutable state is confined by a runtime invariant the compiler cannot see (e.g. "only ever constructed and called from one `@MainActor` service's serialized call chain").
**Gap found — action needed:** none of the 4 sites' doc comments currently state the *concurrency-safety* rationale explicitly (they explain the class's product purpose instead). Per this phase's own success criterion #2 ("no suppression... without an inline comment justifying it as a deliberate, reviewed exception"), each site needs one added sentence, e.g.:
```swift
// @unchecked Sendable: `samplesByEvent` is only ever mutated from
// HealthService's per-event serial `runSerial` chain, which is itself
// @MainActor-confined — no concurrent mutation is possible in practice,
// but the compiler cannot prove it from the type alone. Reviewed 2026-07-27.
final class UITestHealthStore: HealthWriting, @unchecked Sendable { ... }
```
This does not require re-architecting these types into actors; it requires one justification comment per site (4 sites total: `HealthKitAdapter.swift:15`, `UITestHealthStore.swift:12`, `UITestNotificationCenter.swift:14`, `NotificationScheduling.swift:20`).

### Anti-Patterns to Avoid
- **Reaching for `@preconcurrency import`:** Not currently needed anywhere in this codebase (zero warnings surfaced by the flip). Do not add it preemptively "just in case" — CLAUDE.md treats it as a suppression requiring the same justification bar as `@unchecked Sendable`, and none of the frameworks in use (`HealthKit`, `UserNotifications`, `SwiftData`, `SwiftUI`, `Foundation`, `OSLog`, `CoreTransferable`, `UniformTypeIdentifiers`) triggered a diagnostic in the actual flipped build.
- **Widening the `nonisolated` fix beyond the 2 sites the compiler flags:** Other pure Domain helpers (`GuidelineChoice+Display.swift`'s `displayName`, for example) are not currently called from a nonisolated context and compile clean today. Adding `nonisolated` to them is optional stylistic consistency, not required by this phase's success criteria — treat as a "Claude's Discretion"-style nice-to-have, not a blocking task, to keep the diff minimal and source-grounded.
- **Converting `measure {}` performance tests to Swift Testing:** There is no Swift Testing equivalent; forcing the conversion would silently drop the performance baseline that already exists. Document and keep, per SWIFT6-03's own example wording in the phase's success criteria.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Confirming which Domain/Feature functions need `nonisolated` | A manual line-by-line audit of every function signature | The actual `xcodebuild ... SWIFT_VERSION=6.0 build` compiler run | The compiler is the ground truth for isolation errors; this research already ran it and found exactly 2 sites — trust that result rather than re-deriving it by inspection |
| Serializing concurrent access to platform adapters | A custom lock, `DispatchQueue`, or new `actor` type | The existing `HealthService.runSerial(_:_:)` per-event `Task` chaining pattern (already `@MainActor`-confined) | The codebase already has a correct, tested serialization primitive for exactly this problem — don't introduce a second concurrency primitive alongside it |
| Performance regression tracking after the flip | A new benchmarking harness for the 2 XCTest `measure {}` classes | Keep the existing `measure {}` XCTest classes as-is | No Swift Testing equivalent exists; building a replacement is out of scope and unnecessary — the existing harness works and is unaffected by the language-mode flip (test targets are already Swift 6) |

**Key insight:** This phase's biggest risk is *scope inflation* — treating an already-nearly-Swift-6-ready codebase as if it needed a ground-up concurrency audit. The verified build output is the discipline that prevents that: exactly 2 sites need code changes; everything else is confirmation.

## Common Pitfalls

### Pitfall 1: Assuming `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` covers `@Model` classes
**What goes wrong:** A developer expects that because the module defaults to `@MainActor`, every type — including `@Model` classes — is automatically main-actor-isolated, and is surprised when a `@Model` extension method can't call a (correctly) `@MainActor`-defaulted helper.
**Why it happens:** SwiftData's `@Model` macro / `PersistentModel` protocol conformance keeps the class (and its extensions) `nonisolated` regardless of the module-wide default, specifically so model instances remain usable from non-main-actor `ModelContext`s (background import, future `@ModelActor` use, CloudKit sync). `[CITED: Apple Developer Forums thread 788262 (DTS engineer response, "@ModelActor with default actor isolation = MainActor")]`
**How to avoid:** When a `@Model`-class extension method needs a helper from elsewhere, make the helper `nonisolated` (matching the existing project convention) rather than trying to make the `@Model` class `@MainActor`.
**Warning signs:** Compiler error text "call to main actor-isolated {static method|instance method|property} '...' in a synchronous nonisolated context" pointing at a line inside an `extension SomeModelClass { ... }` block.
**Reproduction command (already run for this research; safe to re-run to confirm on the executor's own machine before editing anything):**
```bash
xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug SWIFT_VERSION=6.0 build 2>&1 | grep "error:"
# Expected output (both errors, same as Release config):
# .../Domain/ConsumptionEvent.swift:164:38: error: call to main actor-isolated static method 'preset(for:)' in a synchronous nonisolated context
# .../Domain/ConsumptionEvent.swift:166:30: error: call to main actor-isolated instance method 'name(in:)' in a synchronous nonisolated context
```

### Pitfall 2: Treating the `@unchecked Sendable` gate as "already satisfied" because it compiles
**What goes wrong:** Assuming that because the 4 existing `@unchecked Sendable` sites compile clean under both Swift 5 and (once fixed) Swift 6, they already satisfy CLAUDE.md's "no suppression without justification" rule.
**Why it happens:** The compiler only checks *that* `Sendable` is satisfied, not *why* the developer believes the unchecked promise is safe. CLAUDE.md's rule is a documentation/review requirement, not a compiler-enforced one — it is easy to treat a clean build as "done."
**How to avoid:** Explicitly audit all 4 sites (`HealthKitAdapter.swift:15`, `UITestHealthStore.swift:12`, `UITestNotificationCenter.swift:14`, `NotificationScheduling.swift:20`) as part of this phase and add the missing safety-rationale sentence to each (see Pattern 3 above).
**Warning signs:** `grep -rn "@unchecked\|@preconcurrency\|nonisolated(unsafe)"` finds a site whose surrounding doc comment doesn't mention concurrency/thread-safety at all.

### Pitfall 3: Believing the deprecated-API sweep (SWIFT6-02) requires code changes
**What goes wrong:** Treating SWIFT6-02 as "go find and fix deprecated APIs" work, when the actual codebase state (verified via grep against the full `swiftui-expert` skill's deprecated-API table, and via the zero `warning:`/`deprecated` lines in the flipped build log) has none.
**Why it happens:** The phase description's own example (`onChange(of:perform:)`) is illustrative, carried over from the original todo, not a confirmed finding — all 12 `.onChange(of:)` call sites in the codebase already use the modern iOS 17+ forms.
**How to avoid:** Scope SWIFT6-02's plan task as "confirm via grep + a clean flipped build log, and only fix if something is actually found" rather than assuming migration work exists. If the executor's real build (after editing `project.pbxproj`, not the command-line override used in this research) surfaces something new, fix it then — don't invent work preemptively.
**Warning signs:** None expected, but if found: a diagnostic containing "was deprecated" in the flipped build log.

### Pitfall 4: Confusing the doc comment vs. actual code in `HealthWriteHooks.swift`
**What goes wrong:** `HealthWriteHooks.swift`'s doc comment says the Health op "runs in a detached `Task`," but the code uses plain `Task { ... }` (which inherits the enclosing `@MainActor enum HealthWriteHooks`'s isolation, not detached). This is a pre-existing, harmless doc/code mismatch — not a concurrency bug (the non-detached `Task` is actually the *correct* choice here, since it lets the closure safely capture the non-`Sendable` `ModelContext` parameter under the same-actor rule).
**Why it happens:** Doc comment drift from an earlier implementation.
**How to avoid:** Not part of this phase's required scope (no compiler error, no data race) — flag it in code review as an optional one-line doc fix if convenient, but do not treat it as a Swift6-01 blocker.
**Warning signs:** N/A — noted here only so the plan doesn't misinterpret the comment as evidence of an actual detached-task/Sendable violation.

## Code Examples

### The exact fix (verified against a real compiler run)
```swift
// Source: drinkpulse/Features/AddDrink/DrinkTypePreset.swift — extension already
// containing a sibling `nonisolated` function (abvRange), confirming the intended
// convention.
extension DrinkTypePreset {
    static let all: [DrinkTypePreset] = [ /* unchanged */ ]

    nonisolated static func preset(for category: DrinkCategory) -> DrinkTypePreset {
        switch category {
        case .beer:          return .beer
        // ... unchanged
        }
    }
}
```
```swift
// Source: drinkpulse/Features/AddDrink/DrinkTypePreset.swift — VolumeOption nested struct
struct VolumeOption: Hashable {
    let descriptor: String
    let volumeMl: Double
    let regions: Set<UnitSystem>
    var regionNames: [UnitSystem: String] = [:]

    nonisolated func name(in unitSystem: UnitSystem) -> String {
        regionNames[unitSystem] ?? descriptor
    }

    // `label(in:)` calls `name(in:)` and is itself only ever called from
    // SwiftUI view bodies (already @MainActor) — no change needed there.
    func label(in unitSystem: UnitSystem) -> String { /* unchanged */ }
}
```

### Verification command sequence (build + test + coverage, per CLAUDE.md gates)
```bash
# 1. Confirm the flip in isolation (before touching project.pbxproj, to validate
#    this research's finding on the executor's own machine/toolchain):
xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug SWIFT_VERSION=6.0 build 2>&1 | grep -E "error:|warning:"

# 2. After editing project.pbxproj (SWIFT_VERSION = 6.0 at both Debug and Release
#    sites for the app target only — leave test targets untouched, they're already 6.0)
#    and fixing the 2 nonisolated sites, run the full gate:
xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Release build
xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES -derivedDataPath build/
xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Nonisolated-by-default Swift concurrency model (Swift 6.0) | Main-actor-by-default via `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` (SE-0466, "approachable concurrency") | Swift 6.2 / Xcode 16.3+ (already adopted by this app target under Swift 5 mode) | Most UI-adjacent code no longer needs manual `@MainActor` annotations; pure/background-safe code must opt out with explicit `nonisolated` — this project already follows that convention almost everywhere |
| `onChange(of:perform:)` single-value closure | `onChange(of:) { }` / `onChange(of:, initial:) { old, new in }` | iOS 17 | Already fully adopted in this codebase (0 legacy call sites found) |
| Manual `EnvironmentKey` conformance | `@Entry` macro | Xcode 16+ (back-deploys) | Already fully adopted (`HealthServiceEnvironment.swift`) |

**Deprecated/outdated:** Nothing found in active use in this codebase's app target that needs migrating for this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The *reason* Apple's `@Model` macro keeps model classes nonisolated (rather than the specific mechanism inside the macro expansion) is stated based on an Apple Developer Forums DTS reply, not the Swift compiler source or an official spec document. | Common Pitfalls #1, Architecture Pattern 2 | Low — the *empirical* fact (the build error, and that adding `nonisolated` fixes it per existing codebase convention) is independently verified via the actual compiler run; only the "why" narrative is sourced from a forum reply rather than a primary spec |
| A2 | The command-line `SWIFT_VERSION=6.0` override used for this research produces identical diagnostics to actually editing `project.pbxproj` and rebuilding through Xcode. | Summary, Pitfall 1 | Low-Medium — command-line `-XCODE_SETTING=value` overrides are documented to behave identically to project-file settings for the duration of that invocation; still, the plan should include a real edit-and-rebuild step as its first verification, not rely solely on this research's override-based run |
| A3 | No other Apple framework (HealthKit, UserNotifications, SwiftData, CoreTransferable) will need a `@preconcurrency import` once the setting is made permanent — based on zero warnings in one clean-build run, not on Apple's official Sendable-audit changelog for the exact SDK version in use. | Standard Stack, Anti-Patterns | Low — if wrong, the fix is a well-known, narrowly-scoped one (add `@preconcurrency` to one import with a justification comment), not a rearchitecture |

**If this table is empty:** N/A — see above; all three assumptions are low-risk because they are corroborated by the actual build run, not standalone claims.

## Open Questions (RESOLVED)

1. **Should the other, currently-unaffected `nonisolated`-eligible Domain helpers (e.g. `GuidelineChoice+Display.swift`'s `displayName`) be proactively annotated for consistency, even though the compiler doesn't require it?**
   - What we know: They compile clean today because nothing currently calls them from a nonisolated context.
   - What's unclear: Whether "Claude's Discretion" for this phase should include a small consistency pass, or whether that inflates the diff beyond the phase's stated scope.
   - Recommendation: Leave out of the required task list; call it out as an optional, separately-committable cleanup if the plan wants to offer it, but do not gate SWIFT6-01 on it — the phase's success criteria only require the *build* to be clean, not a fully-annotated Domain layer.
   - **RESOLVED by plan design:** left out of the required task list — plan 02-01 scopes the `nonisolated` fix to only the 2 compiler-flagged sites.

2. **Should the `@unchecked Sendable` justification-comment audit (Pattern 3 / Pitfall 2) be its own explicit task, or folded into the `SWIFT_VERSION` flip task?**
   - What we know: All 4 sites currently compile fine and are not newly broken by the flip; the requirement to justify them comes from this phase's own success criterion #2, not from a compiler error.
   - What's unclear: Whether the planner should treat this as part of Wave 1 (the flip) or a distinct, smaller Wave.
   - Recommendation: Make it a distinct, small task/wave — it touches 4 unrelated files with no compiler dependency on the `nonisolated` fix, so it can run in parallel with (or independently review-gated from) the main flip.
   - **RESOLVED by plan design:** made a distinct task (02-01-02), separate from the flip/fix task (02-01-01).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode / `xcodebuild` | Entire phase (build + test gates) | ✓ | Xcode 26.6 (Build 17F113) `[VERIFIED: xcodebuild -version]` | — |
| Swift compiler | Language-mode flip | ✓ | Apple Swift 6.3.3 (swiftlang-6.3.3.1.3) `[VERIFIED: swift --version]` | — |
| iOS Simulator (iPhone 17 Pro) | Build/test destination used by CLAUDE.md's own build/verify commands | ✓ | Booted and available `[VERIFIED: xcrun simctl list devices available]` | Other available simulators: iPhone 17 Pro Max, 17e, Air, 17 |
| `xcrun xccov` | Coverage reporting gate | ✓ | Bundled with Xcode 26.6 | — |

**Missing dependencies with no fallback:** None.
**Missing dependencies with fallback:** None — everything this phase needs is already present and was exercised directly during this research.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Swift Testing (primary, 44/46 unit-test files) + XCTest (legacy, 2 unit-test types; all 27 `drinkpulseUITests` files) |
| Config file | None — no `.xctestplan`; single shared scheme `drinkpulse.xcscheme` |
| Quick run command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests` |
| Full suite command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (includes `drinkpulseUITests`) |

### Phase Requirements → Test Map
This phase's requirements are about the *build itself*, not new business logic, so the "tests" are largely build-log assertions plus the existing suite staying green.

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SWIFT6-01 | App target builds clean under `SWIFT_VERSION = 6.0`, Debug + Release, zero warnings/errors | build-verification | `xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration {Debug,Release} build 2>&1 \| grep -E "error:\|warning:"` (expect empty output) | ✅ N/A — command-based, no file needed |
| SWIFT6-01 | No unjustified suppression (`@preconcurrency`, `nonisolated(unsafe)`, `@unchecked Sendable`) | manual/code-review | `grep -rn "@unchecked\|@preconcurrency\|nonisolated(unsafe)" drinkpulse/` then inspect each site's comment | ✅ existing sites enumerated in this research |
| SWIFT6-02 | No deprecated/soft-deprecated API left after the flip | build-log + grep verification | Re-run the deprecated-API grep sweep from this research (see Summary) + confirm zero `deprecated` lines in the flipped build log | ✅ N/A — command-based |
| SWIFT6-03 | Explicit, applied decision on `HistoryViewModelPerformanceTests` (in `HistoryViewModelTests.swift`) and `ScreenComputePerformanceTests.swift` | documentation + existing test run | `xcodebuild test -only-testing:drinkpulseTests/HistoryViewModelPerformanceTests -only-testing:drinkpulseTests/ScreenComputePerformanceTests` (confirm they still run/pass under `SWIFT_VERSION=6.0`, which they already do since the test target is unaffected) | ✅ both files exist today |
| — | Coverage stays ≥90% overall / per-layer after the migration | coverage gate | `xcrun xccov view --report --only-targets build/Logs/Test/*.xcresult` | ✅ existing xcresult pipeline |

### Sampling Rate
- **Per task commit:** targeted build (`xcodebuild ... build`) for the file(s) touched, plus `-only-testing:drinkpulseTests` quick run.
- **Per wave merge:** full suite command (unit + UI tests).
- **Phase gate:** Full suite green, both Debug and Release builds clean, before `/gsd-verify-work`.

### Wave 0 Gaps
None — existing test infrastructure (Swift Testing + XCTest, already exercised in this research via direct `xcodebuild` runs) fully covers this phase's requirements. No new test files, fixtures, or framework installs are needed.

## Security Domain

This phase changes compiler enforcement and internal isolation annotations; it does not touch authentication, session handling, network input, or cryptography, and introduces no new attack surface (no new data flows, no new external inputs, no new persisted fields).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture, Design and Threat Modeling | Yes (narrowly) | The "no suppression without a reviewed justification comment" rule (this phase's own success criterion #2) is itself an ASVS V1-style "documented, reviewed exception" control for concurrency-safety exceptions (`@unchecked Sendable`, `@preconcurrency`). Apply it to the 4 existing sites per Pattern 3. |
| V2 Authentication | No | Not touched by this phase |
| V3 Session Management | No | Not touched by this phase |
| V4 Access Control | No | Not touched by this phase |
| V5 Input Validation | No | No new external input introduced |
| V6 Cryptography | No | Not touched by this phase |

### Known Threat Patterns for this stack
None applicable to this phase specifically — data races are a correctness/reliability concern (crashes, corrupted in-memory state), not a STRIDE-style external threat, and Swift 6's compile-time enforcement is itself the mitigation already being adopted.

## Sources

### Primary (HIGH confidence)
- Direct `xcodebuild` execution on this machine (`-scheme drinkpulse -configuration {Debug,Release} SWIFT_VERSION=6.0 build`) — the two real compiler errors, zero warnings, zero deprecated-API diagnostics. `[VERIFIED: xcodebuild, 2026-07-27]`
- `drinkpulse.xcodeproj/project.pbxproj` — current `SWIFT_VERSION`, `SWIFT_APPROACHABLE_CONCURRENCY`, `SWIFT_DEFAULT_ACTOR_ISOLATION` settings for app and test targets. `[VERIFIED: grep, 2026-07-27]`
- Full codebase grep sweep for `@Model`, `@Observable`, `@MainActor`, `actor`, `Sendable`, `nonisolated`, `@unchecked`, `@preconcurrency`, `Task {`, `static var`, and the full deprecated-API table from the `swiftui-expert` skill. `[VERIFIED: grep, 2026-07-27]`
- `xcodebuild -version` / `swift --version` — Xcode 26.6, Swift 6.3.3. `[VERIFIED: local toolchain, 2026-07-27]`

### Secondary (MEDIUM confidence)
- Apple Developer Forums thread 788262, "@ModelActor with default actor isolation = MainActor" (DTS engineer response) — explains why `@Model` classes stay nonisolated under `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. `[CITED: developer.apple.com/forums/thread/788262]`
- Apple Developer Forums thread 774088, "Suggestion to Add Performance Metrics for SwiftUI in XCTest" — corroborates that `measure()`/`XCTMetric` have no Swift Testing equivalent as of this writing. `[CITED: developer.apple.com/forums/thread/774088]`
- Swift Evolution SE-0466, "Control default actor isolation inference" — mechanism and semantics of `SWIFT_DEFAULT_ACTOR_ISOLATION`. `[CITED: github.com/swiftlang/swift-evolution/blob/main/proposals/0466-control-default-actor-isolation.md]`
- `swiftui-expert` skill's `latest-apis.md` reference (locally installed plugin) — used as the deprecated-API checklist for the SWIFT6-02 sweep. `[CITED: local skill reference, swiftui-expert-skill v4.0.0]`

### Tertiary (LOW confidence)
- Various third-party blogs (avanderlee.com, blakecrosley.com, fatbobman.com) surfaced by web search corroborating the general SE-0466 / Swift Testing-vs-XCTest narrative — used only as secondary confirmation alongside the Apple Forums threads and the direct compiler run, never as the sole source for a claim in this document.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependencies; existing toolchain versions directly verified on the executing machine.
- Architecture (isolation patterns, the 2 real errors and their fix): HIGH — derived from an actual, reproducible `xcodebuild` run against the real codebase, not inference.
- Deprecated-API sweep (SWIFT6-02): HIGH — verified via exhaustive grep against a maintained checklist plus a clean, warning-free build log.
- XCTest/Swift Testing decision (SWIFT6-03): HIGH for the factual state (exact file/type inventory verified via grep); MEDIUM for the "no measure equivalent" claim, which rests on forum/blog corroboration rather than an official Swift Testing spec statement.
- Pitfalls: HIGH — the primary pitfall (Model-class isolation) is the actual, reproduced compiler error; the `@unchecked Sendable` gap is a direct grep-and-read finding against CLAUDE.md's own stated rule.

**Research date:** 2026-07-27
**Valid until:** 30 days, or immediately upon any Xcode/Swift toolchain upgrade on the development machine (isolation-inference behavior is toolchain-version-sensitive) — recommend re-running the exact reproduction command in Pitfall 1 at the start of plan execution to reconfirm before writing any fix.
