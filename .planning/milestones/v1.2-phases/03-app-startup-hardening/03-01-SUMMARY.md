---
phase: 03-app-startup-hardening
plan: 01
subsystem: startup
tags: [swiftdata, swiftui, onboarding, uitest]

requires: []
provides:
  - "onboardingDone (@AppStorage) as the sole authority gating RootShellView vs OnboardingView"
  - "UserProfileStore.fetchOrCreate flushes its insert internally (no pending unsaved-insert timing gap)"
  - "deleteProfileMidSession UITestSeed hook + OnboardingAuthorityUITests regression coverage"
  - "ADR-0012 documenting the single-source-of-truth contract"
affects: [03-02, startup, onboarding]

tech-stack:
  added: []
  patterns:
    - "onboardingDone is write-only from explicit user action; no @Query observer may reset it"

key-files:
  created:
    - drinkpulseUITests/Features/Shell/OnboardingAuthorityUITests.swift
    - docs/decisions/0012-onboarding-single-source-of-truth.md
  modified:
    - drinkpulse/Features/Shell/RootShellView.swift
    - drinkpulse/Domain/Persistence/UserProfileStore.swift
    - drinkpulse/UITestSeed.swift
    - drinkpulseTests/Domain/Persistence/UserProfileStoreTests.swift
    - docs/DEVLOG.md

key-decisions:
  - "Removed the .onChange(of: profiles.isEmpty) reverse-write entirely rather than debouncing it — onboardingDone must never be flipped by a transient empty @Query render (D-01)"
  - "fetchOrCreate now calls try? context.save() immediately after insert, closing the timing gap that made profiles.isEmpty unreliable in the first place (D-04)"
  - "Any future delete-all-data flow must set onboardingDone = false itself — documented as an explicit forward obligation in ADR-0012 (D-02), not solved in this plan"

patterns-established:
  - "Mid-session destructive-state UI test hooks follow the existing UITestSeed launch-argument gating pattern (forceShowOnboarding) — double-gated on UITestSeed.isActive"

requirements-completed: [STARTUP-01]

coverage:
  - id: D1
    description: "onboardingDone is the sole gate authority; RootShellView no longer resets it on a transient empty @Query render"
    requirement: "STARTUP-01"
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/Shell/OnboardingAuthorityUITests.swift#test_midSessionProfileDeletion_staysOnRootShell_doesNotResetToOnboarding"
        status: pass
    human_judgment: false
  - id: D2
    description: "UserProfileStore.fetchOrCreate flushes its insert immediately, no external save() required"
    requirement: "STARTUP-01"
    verification:
      - kind: unit
        ref: "drinkpulseTests/Domain/Persistence/UserProfileStoreTests.swift#fetchOrCreate_savesImmediately_withoutExternalSaveCall"
        status: pass
    human_judgment: false
  - id: D3
    description: "ADR-0012 documents onboardingDone as sole gate authority and the forward obligation on future delete-all-data flows"
    requirement: "STARTUP-01"
    verification: []
    human_judgment: true
    rationale: "Documentation content quality/completeness is a judgment call, not something a test can verify"

duration: 12min
completed: 2026-07-27
status: complete
---

# Phase 3 Plan 01: Onboarding Single Source of Truth Summary

**Removed the `@Query`-driven reverse-write of `onboardingDone` in `RootShellView`; `UserProfileStore.fetchOrCreate` now saves its insert immediately, closing the timing gap that made the reverse-write look necessary in the first place.**

## Performance

- **Duration:** ~12 min (19:08–19:15 UTC+2)
- **Started:** 2026-07-27T17:08:23Z
- **Completed:** 2026-07-27T17:14:52Z
- **Tasks:** 3 (TDD red/green pair + D-03 hook/test + docs)
- **Files modified:** 7

## Accomplishments
- Deleted the `.onChange(of: profiles.isEmpty)` block in `RootShellView` — `onboardingDone` can no longer be flipped false by a transient empty `@Query` render
- Fixed `UserProfileStore.fetchOrCreate` to `try? context.save()` immediately after insert, so `context.hasChanges` is `false` the instant it returns
- Added `deleteProfileMidSession` UITestSeed hook + `OnboardingAuthorityUITests` proving a mid-session profile deletion never reverts the app to `OnboardingView`
- Documented the contract in ADR-0012, including the obligation on any future delete-all-data flow to set `onboardingDone = false` itself

## Task Commits

1. **Task 1: RED — failing test for immediate save** - `ff634b8` (test)
2. **Task 1: GREEN — remove reverse-write, fix save gap** - `be084b4` (feat)
3. **Task 2: D-03 mid-session-deletion hook + UI test** - `f519ff3` (feat)
4. **Task 3: ADR-0012 + DEVLOG** - `dff13e4` (docs)

_Note: Task 1 was executed as a RED→GREEN TDD pair per plan._

## Files Created/Modified
- `drinkpulse/Features/Shell/RootShellView.swift` - removed reverse-write; added `deleteProfileMidSessionIfUITest()` onAppear hook
- `drinkpulse/Domain/Persistence/UserProfileStore.swift` - `fetchOrCreate` now saves immediately after insert
- `drinkpulse/UITestSeed.swift` - new `deleteProfileMidSession` launch-argument-gated flag
- `drinkpulseTests/Domain/Persistence/UserProfileStoreTests.swift` - new immediate-save regression test
- `drinkpulseUITests/Features/Shell/OnboardingAuthorityUITests.swift` - new regression UI test (created)
- `docs/decisions/0012-onboarding-single-source-of-truth.md` - new ADR (created)
- `docs/DEVLOG.md` - session entry appended

## Decisions Made
- Removed the reverse-write outright instead of debouncing/guarding it — matches D-01 exactly, no partial fix
- `fetchOrCreate` fix scoped to the single missing `save()` call — no broader `UserProfileStore` refactor

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

**SUMMARY.md was not written or committed by the original executor run before it returned.** No production code was affected — worktree contained only the 4 task/docs commits above, working tree was clean (no uncommitted changes), and no files were modified outside the plan's declared `files_modified`. Verified via `git status`/`git log` in the worktree before reconstruction. This SUMMARY.md was reconstructed by the orchestrator directly from the 4 existing commits (diffs reviewed in full) after user confirmed "close out manually" as the recovery path.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- `onboardingDone` is now the sole gate authority — plan 03-02 (async container load) can proceed without this invariant being contested by a live `@Query`
- Prohibition flagged-but-accepted risk remains open per ADR-0012: a user can reach `RootShellView` with `onboardingDone == true` and zero `UserProfile` rows with no in-app recovery path; explicitly out of scope for this plan

---
*Phase: 03-app-startup-hardening*
*Completed: 2026-07-27*
