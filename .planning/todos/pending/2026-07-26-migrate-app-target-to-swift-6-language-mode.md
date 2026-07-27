---
created: 2026-07-26T17:10:00.000Z
title: Migrate app target to Swift 6 language mode and purge deprecated patterns
area: general
severity: major
cluster: A
files:
  - drinkpulse.xcodeproj/project.pbxproj:433 (app target Debug — SWIFT_VERSION = 5.0)
  - drinkpulse.xcodeproj/project.pbxproj:468 (app target Release — SWIFT_VERSION = 5.0)
  - drinkpulseTests/Features/History/HistoryViewModelTests.swift (XCTest, not Swift Testing)
  - drinkpulseTests/Performance/ScreenComputePerformanceTests.swift (XCTest, not Swift Testing)
---

## Problem

User asked to migrate the codebase to the latest Swift 6, drop UIKit in favor
of SwiftUI, avoid deprecated / non-preferred patterns, and cover the tests too.

A survey of the repo on 2026-07-26 narrowed what actually needs doing — two of
the three assumed items are already clean:

**Already done (no work needed):**
- **UIKit is fully gone.** `grep -rn "import UIKit"` over `drinkpulse/`,
  `drinkpulseTests/`, `drinkpulseUITests/` returns **zero** hits. The app is
  SwiftUI-only already.
- **No legacy Combine-era state.** Zero hits for `ObservableObject`,
  `@Published`, `@StateObject`, `@ObservedObject`, `@EnvironmentObject`, and
  zero `NavigationView` — the codebase is already on `@Observable` +
  `NavigationStack` per CLAUDE.md.

**The real gap:**
- **The app target is on `SWIFT_VERSION = 5.0`** in both Debug (pbxproj:433)
  and Release (pbxproj:468), while the *test* targets are on `6.0`
  (pbxproj:274, :483). CLAUDE.md states "Swift 6 strict concurrency checking
  is on" — that is **not true for the app target**. In Swift 5 language mode,
  data-race safety violations are warnings-or-silent, not errors, so the
  strict-concurrency guarantee the project docs promise is not actually being
  enforced on production code. `SWIFT_APPROACHABLE_CONCURRENCY = YES` and
  `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY = YES` are set on the app
  target, which softens but does not replace full Swift 6 mode.
- **Two unit-test files still use XCTest** while 44 use Swift Testing.
  CLAUDE.md says new tests use Swift Testing and legacy XCTest may stay, so
  this is optional — but the user explicitly said "this should also cover all
  of the tests", so it's in scope for a decision.
  (`drinkpulseUITests` must stay XCTest — XCUITest has no Swift Testing
  equivalent. Do not attempt to convert those.)

## Solution

TBD — proposed order, each step independently verifiable:

1. **Flip the app target to `SWIFT_VERSION = 6.0`** (Debug + Release), build,
   and triage the resulting data-race errors. Expect the bulk of the work
   here: SwiftData `@Model` isolation, `@MainActor` boundaries on view models
   and services, and any `Sendable` gaps in `Domain/`. Per CLAUDE.md, fix at
   the source — **never** suppress with `@preconcurrency`,
   `nonisolated(unsafe)`, or `@unchecked Sendable` unless there is a written
   justification.
2. **Sweep for deprecated / soft-deprecated APIs** the build surfaces once
   Swift 6 mode is on (e.g. old `onChange(of:perform:)` two-arg form,
   `NavigationLink(destination:isActive:)`). The `swiftui-expert` skill covers
   migrating soft-deprecated SwiftUI APIs and should be consulted.
3. **Decide on the two XCTest unit files** — convert to Swift Testing
   (`@Test`/`#expect`) or leave as documented legacy. Note
   `ScreenComputePerformanceTests` uses XCTest's `measure` blocks, which have
   no direct Swift Testing equivalent; converting it may mean losing the
   perf-measurement harness. Recommend: convert `HistoryViewModelTests`, keep
   the performance test on XCTest and note why.
4. **Gates per CLAUDE.md:** `xcodebuild build` clean with **zero** warnings,
   `xcodebuild test` green, coverage ≥90% overall and per-layer, no file over
   300 lines.
5. **Living docs:** if the language-mode fact changes, `docs/architecture.md`
   and CLAUDE.md's Stack/Conventions sections must be checked — CLAUDE.md's
   current "strict concurrency checking is on" claim only becomes true after
   step 1.

Size: this is a **multi-file refactor touching the whole app target** — per
CLAUDE.md's plan-driven-development rule this warrants a plan
(`docs/plans/NNNN-*/`), not a quick task.
