---
phase: 02-swift-6-language-mode-migration
plan: 01
subsystem: infra
tags: [swift6, strict-concurrency, nonisolated, sendable, xcodebuild, healthkit, usernotifications]

# Dependency graph
requires: []
provides:
  - App target builds clean under `SWIFT_VERSION = 6.0` (Debug + Release), zero errors/warnings
  - All 4 pre-existing `@unchecked Sendable` sites carry explicit concurrency-safety justification comments
  - Deprecated-API sweep (SWIFT6-02) confirmed clean — zero hits across 13 patterns and the build log
affects: [phase-03-app-startup-hardening]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "nonisolated on pure Domain/Feature static properties and functions reachable from a @Model extension's nonisolated context (restores existing codebase convention)"
    - "Sendable + nonisolated conformance on pure value types with stored properties, matching sibling Domain types (AlcoholUnit, BiologicalSex, DrinkCategory, GuidelineChoice, UnitSystem)"
    - "@unchecked Sendable suppression sites require an explicit concurrency-safety rationale sentence, not just a product-purpose doc comment"

key-files:
  created: []
  modified:
    - drinkpulse.xcodeproj/project.pbxproj
    - drinkpulse/Features/AddDrink/DrinkTypePreset.swift
    - drinkpulse/Features/AddDrink/DrinkTypePreset+FermentedPresets.swift
    - drinkpulse/Features/AddDrink/DrinkTypePreset+MixedPresets.swift
    - drinkpulse/Features/AddDrink/DrinkTypePreset+SpiritPresets.swift
    - drinkpulse/Domain/GuidelineLimits.swift
    - drinkpulse/Features/Insights/InsightsDataGenerator.swift
    - drinkpulse/Services/HealthKitAdapter.swift
    - drinkpulse/Services/UITestHealthStore.swift
    - drinkpulse/Services/UITestNotificationCenter.swift
    - drinkpulse/Services/NotificationScheduling.swift

key-decisions:
  - "The real project.pbxproj edit surfaced 19 more nonisolated-gap errors than RESEARCH.md's command-line-override run found (17 in DrinkTypePreset+*Presets.swift, plus GuidelineLimits and InsightsDataGenerator only visible when running the test suite) — RESEARCH.md's own Assumption A2 flagged this exact risk. All fixes mirror the plan's own established nonisolated-restoration pattern; none required an architectural change."
  - "GuidelineLimits.swift was the one Domain value type missing Sendable conformance (every sibling — AlcoholUnit, BiologicalSex, DrinkCategory, GuidelineChoice, UnitSystem — already had it). Added `nonisolated struct GuidelineLimits: Sendable` to match convention."

patterns-established:
  - "When a real SWIFT_VERSION=6.0 edit-and-rebuild surfaces more isolation errors than a command-line override run predicted, fix by extending the exact same nonisolated/Sendable convention the plan's read_first already identifies — do not introduce a new suppression pattern (@preconcurrency, @MainActor on @Model types) to route around it."

requirements-completed: [SWIFT6-01, SWIFT6-02]

coverage:
  - id: D1
    description: "App target (Debug + Release) builds clean under SWIFT_VERSION = 6.0 with zero compiler errors/warnings"
    requirement: "SWIFT6-01"
    verification:
      - kind: other
        ref: "xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Debug build 2>&1 | grep -E 'error:|warning:' (empty)"
        status: pass
      - kind: other
        ref: "xcodebuild -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -configuration Release build 2>&1 | grep -E 'error:|warning:' (empty)"
        status: pass
      - kind: unit
        ref: "xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests"
        status: pass
    human_judgment: false
  - id: D2
    description: "All 4 pre-existing @unchecked Sendable sites carry an explicit concurrency-safety justification comment"
    requirement: "SWIFT6-01"
    verification:
      - kind: other
        ref: "grep -rn '@unchecked|@preconcurrency|nonisolated(unsafe)' drinkpulse/ — exactly 4 sites, each with a concurrency/thread-safe sentence"
        status: pass
    human_judgment: false
  - id: D3
    description: "Deprecated/soft-deprecated API sweep (SWIFT6-02) confirmed clean"
    requirement: "SWIFT6-02"
    verification:
      - kind: other
        ref: "13-pattern grep sweep against drinkpulse/ (onChange(of:perform:), NavigationView, actionSheet, alert(isPresented:), .accentColor(), .tabItem, Section(header:), EnvironmentKey, MagnificationGesture, RotationGesture, coordinateSpace(name:), disableAutocorrection, UIPasteboard, presentationBackground) — zero real hits"
        status: pass
      - kind: other
        ref: "Combined Debug+Release build log grep -icE deprecated — zero lines"
        status: pass
    human_judgment: false

duration: 15min
completed: 2026-07-27
status: complete
---

# Phase 2 Plan 01: Swift 6 Language Mode Migration Summary

**Flipped the drinkpulse app target to real Swift 6 strict concurrency (`SWIFT_VERSION = 6.0`, Debug + Release), fixing 21 isolation-gap sites (not the 2 the research run predicted) by restoring the codebase's existing `nonisolated`/`Sendable` convention, and justified all 4 pre-existing `@unchecked Sendable` suppressions with concurrency-safety rationale.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-07-27T06:32:00Z
- **Completed:** 2026-07-27T06:47:00Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments
- App target now builds clean (zero errors, zero warnings) under `SWIFT_VERSION = 6.0` in both Debug and Release configurations
- All 21 real compiler-flagged isolation gaps fixed via `nonisolated`/`Sendable`, restoring the codebase's own established convention (no `@MainActor` added to any `@Model` type, no new suppression pattern introduced)
- All 4 pre-existing `@unchecked Sendable` sites now carry an explicit, reviewed concurrency-safety justification sentence
- Deprecated/soft-deprecated API sweep (SWIFT6-02) confirmed clean via a 13-pattern grep sweep plus a `deprecated`-grep over the combined Debug+Release build log
- `drinkpulseTests` unit suite passes unchanged (no regression from any of the isolation-annotation-only edits)

## Task Commits

Each task was committed atomically:

1. **Task 1: Flip SWIFT_VERSION to 6.0 and fix the real isolation-gap errors** - `70df81f` (feat)
2. **Task 2: Justify the 4 existing @unchecked Sendable suppression sites** - `c4be40e` (docs)
3. **Task 3: Confirm zero deprecated APIs (SWIFT6-02); Wave 1 build gate** - verification-only, no file changes, no commit (see below)

**Plan metadata:** committed alongside this SUMMARY (worktree mode — orchestrator merges into main history)

## Files Created/Modified
- `drinkpulse.xcodeproj/project.pbxproj` - `SWIFT_VERSION` 5.0 → 6.0 for the app target, Debug + Release only (test targets untouched, already 6.0)
- `drinkpulse/Features/AddDrink/DrinkTypePreset.swift` - `nonisolated` added to `VolumeOption.name(in:)` and `preset(for:)` (the 2 sites the plan's `read_first` specified)
- `drinkpulse/Features/AddDrink/DrinkTypePreset+FermentedPresets.swift` - `nonisolated` added to `fullAbvRange`, 7 region-alias helpers, and 6 static presets (`beer`, `wine`, `champagne`, `cider`, `alcopop`, `custom`) — all transitively referenced by the now-`nonisolated preset(for:)` switch
- `drinkpulse/Features/AddDrink/DrinkTypePreset+MixedPresets.swift` - `nonisolated` added to 4 region-alias helpers and 3 static presets (`cocktail`, `fortifiedWine`, `hotDrink`)
- `drinkpulse/Features/AddDrink/DrinkTypePreset+SpiritPresets.swift` - `nonisolated` added to 3 region-alias helpers, `shotVolumes`, and 8 static presets (`spirits`, `brandy`, `cognac`, `vodka`, `whiskey`, `tequila`, `shot`, `liqueur`)
- `drinkpulse/Domain/GuidelineLimits.swift` - marked `nonisolated struct GuidelineLimits: Sendable`, matching every sibling Domain value type
- `drinkpulse/Features/Insights/InsightsDataGenerator.swift` - marked `nonisolated struct InsightsDataGenerator`, the pure/stateless preview-data generator used from test/preview code
- `drinkpulse/Services/HealthKitAdapter.swift` - added concurrency-safety justification sentence to the `@unchecked Sendable` doc comment
- `drinkpulse/Services/UITestHealthStore.swift` - added concurrency-safety justification sentence
- `drinkpulse/Services/UITestNotificationCenter.swift` - added concurrency-safety justification sentence
- `drinkpulse/Services/NotificationScheduling.swift` - added concurrency-safety justification sentence to the `UNUserNotificationCenter` `@retroactive @unchecked Sendable` conformance

## Decisions Made
- **Restored convention, not a new pattern:** for every isolation gap beyond the plan's 2 explicit sites, the fix mirrors the exact same `nonisolated` technique the plan's own `read_first` cites (`abvRange(...)`) or the exact `Sendable` conformance every sibling Domain type already has. No `@preconcurrency`, no `@MainActor` on a `@Model` type, no new suppression pattern was introduced anywhere.
- **GuidelineLimits fix required both `nonisolated` and `Sendable`:** `Sendable` conformance alone did not exempt the struct's stored properties from `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`'s default inference (confirmed empirically — the error persisted with `Sendable` alone, and only cleared once `nonisolated` was added to the type declaration too, matching the dual pattern already used in `Currency.swift`'s `CurrencyOption`).
- **Task 3 required no code changes:** the 13-pattern deprecated-API sweep and the `deprecated`-grep over the flipped build log both returned zero hits, confirming RESEARCH.md's prediction that SWIFT6-02 is confirmation work, not migration work.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] 17 additional `nonisolated` gaps in `DrinkTypePreset+{Fermented,Mixed,Spirit}Presets.swift`**
- **Found during:** Task 1
- **Issue:** RESEARCH.md's command-line-override build (`xcodebuild ... SWIFT_VERSION=6.0 build`) found only 2 compiler errors. The plan's own `read_first` for Task 1 directed marking exactly those 2 sites. But the *real* `project.pbxproj` edit (which the plan itself performs) surfaced 17 more errors: every static preset property (`beer`, `wine`, `spirits`, etc.) and the private region-alias/`shotVolumes`/`fullAbvRange` helpers they depend on are main-actor-isolated by default, and become unreachable from the now-`nonisolated preset(for:)` switch statement. RESEARCH.md's own Assumption A2 explicitly flagged this exact risk ("the plan should include a real edit-and-rebuild step as its first verification, not rely solely on this research's override-based run").
- **Fix:** Added `nonisolated` to all 17 additional declarations across the 3 preset extension files, mirroring the exact convention the plan cites (`abvRange(...)`).
- **Files modified:** `drinkpulse/Features/AddDrink/DrinkTypePreset+FermentedPresets.swift`, `DrinkTypePreset+MixedPresets.swift`, `DrinkTypePreset+SpiritPresets.swift`
- **Verification:** Debug and Release builds both clean (zero errors/warnings)
- **Committed in:** `70df81f` (Task 1 commit)

**2. [Rule 1 - Bug] `GuidelineLimits` missing `Sendable`/`nonisolated`, breaking the test suite under the real flip**
- **Found during:** Task 1 (surfaced only when running `-only-testing:drinkpulseTests`, not the app-only build — Swift Testing test functions are nonisolated by default, unlike the app's own call sites which are all `@MainActor`)
- **Issue:** `GuidelineLimits` (a pure Domain value type per CLAUDE.md's domain model) was the one Domain struct missing `Sendable` conformance; every sibling (`AlcoholUnit`, `BiologicalSex`, `DrinkCategory`, `GuidelineChoice`, `UnitSystem`) already conforms. Under the real `SWIFT_VERSION = 6.0` flip, its stored properties (`dailyGrams`, `weeklyGrams`) were inferred `@MainActor`, breaking `AlcoholUnitFormattingTests.swift` (a nonisolated Swift Testing function) which reads them directly.
- **Fix:** Marked the struct `nonisolated struct GuidelineLimits: Sendable`, matching the codebase's own sibling-type convention.
- **Files modified:** `drinkpulse/Domain/GuidelineLimits.swift`
- **Verification:** `xcodebuild test -only-testing:drinkpulseTests` passes; Debug/Release builds still clean
- **Committed in:** `70df81f` (Task 1 commit)

**3. [Rule 1 - Bug] `InsightsDataGenerator` missing `nonisolated`, breaking the test suite**
- **Found during:** Task 1 (same test-suite-only surfacing as #2 — `InsightsDataGeneratorTests.swift`'s test functions call `gramsForDate(_:)` from a nonisolated context)
- **Issue:** `InsightsDataGenerator` is a pure, stateless preview/seed-data generator (no instance state, only static functions) with no isolation annotation, so it defaulted to `@MainActor` under the real flip.
- **Fix:** Marked the whole struct `nonisolated struct InsightsDataGenerator`, matching the pattern already used by `Currency.swift`'s `CurrencyCatalog`.
- **Files modified:** `drinkpulse/Features/Insights/InsightsDataGenerator.swift`
- **Verification:** `xcodebuild test -only-testing:drinkpulseTests` passes
- **Committed in:** `70df81f` (Task 1 commit)

---

**Total deviations:** 3 auto-fixed, all Rule 1 (bug — real compiler/test errors the actual flip surfaces beyond RESEARCH.md's predicted scope)
**Impact on plan:** All 3 fixes are mechanical extensions of the exact same technique the plan itself specifies (restore `nonisolated`/`Sendable` convention already used throughout the Domain layer). No architectural change, no new suppression pattern, no scope creep beyond what the real compiler/test run required.

## Issues Encountered
- An incremental (non-clean) `xcodebuild` build/test cycle intermittently failed to pick up a source edit to `GuidelineLimits.swift` on the very next invocation, re-surfacing an already-fixed error until a `xcodebuild clean` was run. This looked like a stale-module-cache artifact of the local build system, not a code issue — resolved by running `xcodebuild clean` once before the final verification pass. No further recurrence after that.
- A pre-existing, unrelated build-tool note (`appintentsmetadataprocessor: warning: Metadata extraction skipped. No AppIntents.framework dependency found.`) appears intermittently in build output. Confirmed via `grep -rl "AppIntents" drinkpulse/` (zero hits) that this project uses no App Intents anywhere — this is a harmless, non-deterministic Xcode build-phase note unrelated to the Swift 6 flip or any change in this plan, not a Swift compiler `warning:` diagnostic. Not treated as a deviation requiring a fix.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Wave 1 (SWIFT6-01 core flip + suppression justification + deprecated-API confirmation) is fully verified: Debug + Release builds clean, `drinkpulseTests` passes, 4/4 suppression sites justified, 0/13 deprecated patterns hit.
- Per STATE.md's roadmap decision, Phase 2 (this phase) must complete and be committed before Phase 3 (App Startup Hardening) starts — that dependency is satisfied by this plan.
- SWIFT6-03 (decision on the 2 remaining XCTest performance-test types) is out of this plan's scope — RESEARCH.md documents it as a separate, non-compiler-driven policy decision for a later plan in this phase.

---
*Phase: 02-swift-6-language-mode-migration*
*Completed: 2026-07-27*
