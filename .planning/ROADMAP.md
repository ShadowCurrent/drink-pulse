# Roadmap: DrinkPulse

## Milestones

- ✅ **v1.1 Weekly Summary Notification** — Phases 1-1.1 (shipped 2026-07-21)
- 🚧 **v1.2 Swift 6 + App-Target Hardening** — Phases 2-3 (in progress)

## Phases

**Phase Numbering:**

- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)
- Phase numbers continue across milestones — v1.1 used 1 and 01.1; v1.2 starts at 2 (never restart at 01)

<details>
<summary>✅ v1.1 Weekly Summary Notification (Phases 1-1.1) — SHIPPED 2026-07-21</summary>

- [x] Phase 1: Weekly Summary Notification (5/5 plans) — completed 2026-07-20
- [x] Phase 01.1: Address tech debt: weekly summary notification (1/1 plan) — completed 2026-07-21

Full detail: `.planning/milestones/v1.1-ROADMAP.md`

</details>

### 🚧 v1.2 Swift 6 + App-Target Hardening (In Progress)

**Milestone Goal:** Bring the app target to real Swift 6 strict concurrency,
fix onboarding's dual-source-of-truth fragility, and make model-container
startup async with a real user-facing error state. This is Cluster A from
the pending-todos triage (`.planning/todos/CLUSTERS.md`) — internal
hardening, not a new user-facing feature. Runs alone; must not interleave
with Cluster B (native feel: motion, layout, chart interaction), which is a
separate, later milestone.

- [x] **Phase 2: Swift 6 Language Mode Migration** - Flip the app target to `SWIFT_VERSION = 6.0` (Debug+Release), fix every data-race error at the source, migrate deprecated APIs the flip surfaces, and decide the fate of the 2 remaining XCTest unit files. (completed 2026-07-27)
- [ ] **Phase 3: App Startup Hardening** - Give the onboarding gate one authoritative source of truth, move `sharedModelContainer` creation off the synchronous `App.init` path, and replace the two `fatalError` crashes with a real, designed user-facing error state.

## Phase Details

### Phase 2: Swift 6 Language Mode Migration

**Goal**: The app target builds and ships under real Swift 6 strict
concurrency — the guarantee CLAUDE.md already claims but which is not
currently true for production code (only the test targets are on
`SWIFT_VERSION = 6.0` today) — with every data-race error fixed at its
source, never suppressed.
**Depends on**: Nothing (first phase of this milestone; v1.1 is shipped and unrelated)
**Requirements**: SWIFT6-01, SWIFT6-02, SWIFT6-03
**Success Criteria** (what must be TRUE):

  1. `xcodebuild build` for the app target (Debug and Release) succeeds with `SWIFT_VERSION = 6.0` and zero warnings — including zero data-race / `Sendable` errors.
  2. No suppression (`@preconcurrency`, `nonisolated(unsafe)`, `@unchecked Sendable`) was used to silence a data-race error without an inline comment justifying it as a deliberate, reviewed exception.
  3. Every deprecated/soft-deprecated API surfaced by the language-mode flip (e.g. the two-argument `onChange(of:perform:)` form) has been migrated to its modern equivalent, confirmed by a clean build log.
  4. The 2 remaining XCTest unit files (`HistoryViewModelTests`, `ScreenComputePerformanceTests`) each carry an explicit, applied decision — converted to Swift Testing, or kept on XCTest with a documented reason (e.g. `measure` blocks have no direct Swift Testing equivalent) — neither is left undecided.
  5. `xcodebuild test` is green and coverage stays at or above the ≥90% overall / per-layer thresholds after the migration.

**Plans**: 2/2 plans executed

Plans:
**Wave 1**

- [x] 02-01-PLAN.md — Flip SWIFT_VERSION to 6.0, fix the 2 real isolation-gap errors, justify the 4 `@unchecked Sendable` sites, confirm zero deprecated APIs (SWIFT6-01, SWIFT6-02)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 02-02-PLAN.md — Apply and document the SWIFT6-03 XCTest decision, run the full build/test/coverage gate, update living docs (SWIFT6-03, SWIFT6-01)

### Phase 3: App Startup Hardening

**Goal**: App startup behaves predictably while the SwiftData store isn't
yet settled — the onboarding gate has one authoritative source of truth,
and container creation or failure never blocks the first frame or crashes
the app.
**Depends on**: Phase 2 (making container creation async is itself a
concurrency change — the isolation/`Sendable` reasoning for it and for the
onboarding-gate rewiring should be done once, under real Swift 6 rules, not
redone after the flip)
**Requirements**: STARTUP-01, STARTUP-02, STARTUP-03
**Success Criteria** (what must be TRUE):

  1. A transient empty `@Query profiles` result (e.g. a single-frame render before the store settles) no longer drops the user back into `OnboardingView`; there is one documented, enforced authoritative source of truth for "onboarding complete."
  2. A `drinkpulseUITests` regression test pins this behavior — proving a transient empty query does not reset onboarding state — extending the existing `-dp_force_onboarding` / `-dp_onboarding_done` launch-argument hooks rather than adding a parallel mechanism.
  3. `sharedModelContainer` creation no longer runs synchronously on `App.init`; the first frame can be drawn before the store finishes opening.
  4. When the model container fails to open, the user sees a real, designed in-app error state (with an explicit next step, e.g. retry) instead of a hard crash — replacing both `fatalError` call sites at `drinkpulseApp.swift:59,68`.
  5. The existing onboarding UI-test hooks (`forceOnboardingPending` / `UITestSeed.forceShowOnboarding`) still behave correctly after the change.

**Open decisions** (deliberately not resolved by this roadmap — resolve
during discuss-phase/plan-phase for Phase 3, per `.planning/todos/CLUSTERS.md`):

  - What replaces the two `fatalError` calls at `drinkpulseApp.swift:59,68`. A store-open failure can put user data at risk, so the recovery/retry UX is a design decision, not an implementation detail.
  - Which source of truth wins for onboarding — the persisted `onboardingDone` flag or the live `@Query profiles` result. Today they disagree by construction; the fix's shape depends on which one is picked.

**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:** Phase 2 → Phase 3

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|-----------------|--------|-----------|
| 1. Weekly Summary Notification | v1.1 | 5/5 | Complete | 2026-07-20 |
| 01.1. Address tech debt | v1.1 | 1/1 | Complete | 2026-07-21 |
| 2. Swift 6 Language Mode Migration | v1.2 | 2/2 | Complete    | 2026-07-27 |
| 3. App Startup Hardening | v1.2 | 0/TBD | Not started | - |

---
*Last updated: 2026-07-27 — v1.2 roadmap created: Phase 2 (Swift 6 Language Mode Migration), Phase 3 (App Startup Hardening). 6/6 v1.2 requirements mapped. Awaiting approval, then `/gsd-plan-phase 2`.*
