---
phase: 06-history-list-calendar-directional-transition
plan: 01
subsystem: ui
tags: [swiftui, transition, animation, accessibility, xcuitest, history]

# Dependency graph
requires: []
provides:
  - "HistoryView.edge(forEntering:) pure direction-mapping function"
  - "HistoryView.selectSegment(_:) single synchronous entry point for segment changes"
  - "Directional .asymmetric(insertion:removal:) transition on the List/Calendar switch"
  - "HistoryInteractionUITests.launchApp(dataset:) additive dataset-seeding hook"
  - "HistoryInteractionUITests+DirectionalTransition.swift UI test coverage"
affects: []

# Actuals (#2632)
actuals:
  tokens: 2786
  tasks: 2
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single synchronous selectSegment(_:) entry point computes direction state and mutates segment together, avoiding SwiftUI's diff-based .onChange lag window (RESEARCH.md Pitfall 1)"
    - "Reduce Motion gating reuses OnboardingView.swift's exact if/withAnimation ternary shape verbatim for consistency across the app"

key-files:
  created:
    - drinkpulseTests/Features/History/HistoryViewTests.swift
    - drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift
  modified:
    - drinkpulse/Features/History/HistoryView.swift
    - drinkpulseUITests/Features/History/HistoryInteractionUITests.swift

key-decisions:
  - "Followed UI-SPEC's Motion & Transition Contract verbatim (D-01..D-05): .asymmetric move transition on the Group wrapping switch(segment), .spring(response: 0.4, dampingFraction: 0.8) curve reused from OnboardingView, no .id(segment)"
  - "Picker(selection:) rewired to Binding(get:set:) calling selectSegment(_:) instead of a direct $segment binding or .onChange — routes every selection source (tap, VoiceOver) through one synchronous ordering-safe function"

patterns-established:
  - "Pure static edge(forEntering:) direction function, unit-tested in isolation, keeps the direction-lag bug class structurally impossible rather than relying on test coverage alone"

requirements-completed: [HIST-01, HIST-02, HIST-03]

coverage:
  - id: D1
    description: "List<->Calendar segment switch slides content directionally: List->Calendar enters from trailing, Calendar->List enters from leading, matching HistorySegment.allCases spatial order"
    requirement: HIST-01
    verification:
      - kind: unit
        ref: "drinkpulseTests/Features/History/HistoryViewTests.swift#edgeForEntering_calendar_returnsTrailing"
        status: pass
      - kind: unit
        ref: "drinkpulseTests/Features/History/HistoryViewTests.swift#edgeForEntering_list_returnsLeading"
        status: pass
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/History/HistoryInteractionUITests.swift#test_segmentSwitch_togglesListAndCalendar"
        status: pass
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift#test_segmentSwitch_alternatingDirection_endsInCorrectState"
        status: pass
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift#test_segmentSwitch_rapidRepeatedTaps_endsInCorrectState"
        status: pass
    human_judgment: true
    rationale: "XCUITest cannot assert animation direction or mid-transition frame content (RESEARCH.md Validation Architecture). Automated tests prove correct end-state only; visual slide-direction correctness across repeated switches requires a human watching the running app (Task 2's first <human-check> item)."
  - id: D2
    description: "With Reduce Motion enabled, every segment switch (List, Calendar, empty state) is an instant cut via a bare segment = new assignment outside withAnimation, uniformly through the single selectSegment(_:) entry point"
    requirement: HIST-02
    verification:
      - kind: unit
        ref: "drinkpulse/Features/History/HistoryView.swift selectSegment(_:) reduceMotion branch (matches OnboardingView.animatedStep shape)"
        status: pass
    human_judgment: true
    rationale: "No automated test in this codebase drives accessibilityReduceMotion through a real XCUITest launch; the code-level guarantee is structural (single entry point, no per-content-type branching) but the on-device Reduce Motion behavior itself is not exercised by an automated test in this plan."
  - id: D3
    description: "List, Calendar, and the empty state all participate in the identical transition container with no layout pop, flash, or @Query re-fetch flicker, verified with a real dataset on a real device"
    requirement: HIST-03
    verification:
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift#test_segmentSwitch_withEmptyState_transitionsCorrectly"
        status: pass
      - kind: automated_ui
        ref: "drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift#test_segmentSwitch_withManyEvents_endsInCorrectState"
        status: pass
    human_judgment: true
    rationale: "HIST-03's own requirement text mandates verification on a REAL physical device with a realistic dataset (a simulator pass is not sufficient) — this is the plan's Task 2 second <human-check> item, structurally unverifiable by any automated test in this project (RESEARCH.md Known risk)."

duration: 55min
completed: 2026-07-31
status: complete
---

# Phase 06 Plan 01: History List/Calendar Directional Transition Summary

**Directional `.asymmetric` move transition wired into `HistoryView` via a single synchronous `selectSegment(_:)` entry point, gated by `accessibilityReduceMotion`, plus 6 new automated tests (2 unit + 4 UI) covering direction correctness, rapid/alternating taps, the empty state, and a larger dataset.**

## Performance

- **Duration:** 55 min
- **Started:** 2026-07-31T12:26:00Z
- **Completed:** 2026-07-31T13:21:00Z
- **Tasks:** 2
- **Files modified:** 4 (2 created, 2 modified)

## Accomplishments

- `HistoryView.edge(forEntering:)` — a pure, stateless direction-mapping function immune to the diff-based alternating-switch lag bug (Apple Developer Forums thread 749606) because it reads only the destination segment, never the previous one.
- `HistoryView.selectSegment(_:)` — computes `insertionEdge` and mutates `segment` in one synchronous scope, gated by `reduceMotion` using `OnboardingView.swift`'s exact ternary shape. `segmentPickerRow`'s `Picker` now routes every selection change (tap or VoiceOver) through this function instead of a direct `$segment` binding.
- `Group { switch segment { ... } }` carries `.transition(.asymmetric(insertion: .move(edge:), removal: .move(edge:)))` per the UI-SPEC's locked Motion & Transition Contract — List, Calendar, and the empty state all slide through the identical container with no special-casing.
- `HistoryViewTests.swift` — 2 new unit tests proving the direction mapping for both `HistorySegment` cases.
- `HistoryInteractionUITests+DirectionalTransition.swift` — 4 new UI tests: a six-tap alternating-direction sequence, a rapid back-to-back tap burst, an empty-state round trip via context-menu Delete, and the larger 9-event/14-day `-dp_uitest_dataset multiday` fixture.
- `HistoryInteractionUITests.launchApp` widened to `func launchApp(dataset: String? = nil)` — purely additive; every existing call site is unaffected.

## Task Commits

Each task was committed atomically (Task 1 is TDD: test → feat):

1. **Task 1 RED: failing direction tests** - `b64f3a7` (test)
2. **Task 1 GREEN: directional transition wiring** - `004a038` (feat)
3. **Task 2: UI test coverage** - `4666882` (test)

**Plan metadata:** committed separately below (docs: complete plan)

## Files Created/Modified

- `drinkpulse/Features/History/HistoryView.swift` - Adds `insertionEdge`/`reduceMotion` state, `edge(forEntering:)`, `selectSegment(_:)`, and the `.transition` modifier (255 lines, within the 300-line ceiling)
- `drinkpulseTests/Features/History/HistoryViewTests.swift` - New: 2 unit tests for the pure direction function
- `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` - `launchApp` widened to accept an optional `dataset:` parameter (324 lines — see Deviations)
- `drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift` - New: 4 UI tests (112 lines)

## Decisions Made

- Followed the UI-SPEC's Motion & Transition Contract verbatim — no deviation from the locked `.asymmetric` transition, `.spring(response: 0.4, dampingFraction: 0.8)` curve, or Reduce Motion ternary shape.
- Research's Open Question 2 was resolved per the plan's own instruction: `Binding(get:set:)` calling `selectSegment(_:)`, not `.onChange(of: segment)` — one synchronous function with no lag window, covers non-tap selection sources (VoiceOver) for free.
- New UI tests placed in a new file (`+DirectionalTransition.swift`) rather than growing the already-over-ceiling `HistoryInteractionUITests.swift` further, matching the plan's explicit rationale.

## Deviations from Plan

### Known Issue (not auto-fixed — pre-existing, out of scope)

**1. `HistoryInteractionUITests.swift` remains over the 300-line ceiling**
- **Found during:** Task 2
- **Issue:** The file was already 319 lines before this plan started (pre-existing debt; the plan's own `<read_first>` note for Task 2 flags this and is the stated reason new tests went into a new file instead of growing this one). The mandatory, additive `dataset: String? = nil` parameter on `launchApp` (required by acceptance criteria and by `test_segmentSwitch_withManyEvents_endsInCorrectState`) added 5 net lines, bringing the file to 324.
- **Why not auto-fixed:** Splitting the file's *pre-existing* content (the 8 tests that predate this plan) is a refactor outside this task's `<action>` steps and outside this plan's scope boundary (CONTEXT.md confines this phase to the presentation/transition layer; SCOPE BOUNDARY in the executor's own rules excludes pre-existing issues not directly caused by this task's changes). The signature widening itself was kept as minimal as possible (a single terse doc-comment line plus a 3-line conditional).
- **Files:** `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift`
- **Logged to:** `.planning/WINDOWS.md` (entry id 2, kind `deviation`, phase 06) for cross-phase visibility.
- **Recommendation:** A future cleanup task should split `HistoryInteractionUITests.swift`'s pre-existing 8 tests (e.g., the context-menu/edit tests) into their own file(s), the same pattern this plan already used for the new directional-transition tests.

---

**Total deviations:** 1 logged (pre-existing file-size debt, not auto-fixed — out of task scope per SCOPE BOUNDARY)
**Impact on plan:** No impact on functional correctness or test coverage. Purely a code-organization debt item already flagged by the plan itself.

## Issues Encountered

None — TDD RED/GREEN cycle for Task 1 confirmed cleanly (compile failure before, all green after); Task 2's four new UI tests plus all 8 pre-existing `HistoryInteractionUITests` passed together (12/12) on first run. `xcodebuild build` is clean with zero Swift compiler warnings (the only stderr line seen, `appintentsmetadataprocessor: Metadata extraction skipped. No AppIntents.framework dependency found`, is pre-existing build tooling noise unrelated to this change).

## Known Stubs

None — no hardcoded empty values, placeholder text, or unwired data sources were introduced.

## Threat Flags

None — this plan's threat model (T-06-01/02/03, all `accept`/`mitigate`, none `block`) was followed exactly; no new network, persistence, or auth surface was introduced. No `os.Logger` calls were added near `selectSegment`/direction logic, satisfying T-06-02's mitigation.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Both automated `<verify>` gates in the plan pass: the scoped `-only-testing:drinkpulseTests/HistoryViewTests -only-testing:drinkpulseUITests/HistoryInteractionUITests` run (12/12 pass) and a clean `xcodebuild build` (zero warnings).
- **Outstanding before the phase is considered fully done (per `human_verify_mode: end-of-phase` in config.json):** Task 2's two `<human-check>` items are NOT yet resolved by this worktree execution — they are structurally unverifiable by any automated test:
  1. Visual direction correctness across repeated List<->Calendar<->List switches (watch the slide direction on every tap, not just the first).
  2. HIST-03's mandatory real-device check: run on a REAL physical device with `-dp_uitest_dataset multiday` (or real logged history), switching List<->Calendar<->empty-state repeatedly including mid-animation re-taps, watching for layout pop/flash/`@Query` re-fetch flicker.
  These are recorded in this SUMMARY's `coverage:` block (`D1`, `D3`) with `human_judgment: true` so `gsd-verify-work`'s end-of-phase UAT step routes them to the human, per this project's `human_verify_mode: end-of-phase` config.
- This was the phase's only plan (single-plan phase per ROADMAP.md); once the two human-check items above are resolved, Phase 06 and the v1.3 "Native Feel" milestone are ready to close.

## Self-Check: PASSED

- FOUND: `drinkpulse/Features/History/HistoryView.swift`
- FOUND: `drinkpulseTests/Features/History/HistoryViewTests.swift`
- FOUND: `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift`
- FOUND: `drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift`
- FOUND: commit `b64f3a7` (test RED)
- FOUND: commit `004a038` (feat GREEN)
- FOUND: commit `4666882` (test Task 2)

## TDD Gate Compliance

Task 1 (`tdd="true"`) followed the full RED/GREEN cycle:
- RED gate: `b64f3a7` — `test(06-01): add failing test for HistoryView.edge(forEntering:)`, confirmed failing to compile before implementation (`Type 'HistoryView' has no member 'edge'`).
- GREEN gate: `004a038` — `feat(06-01): wire directional List/Calendar transition in HistoryView`, confirmed all tests passing after implementation.
- No REFACTOR commit was needed (implementation matched the UI-SPEC's locked contract exactly on first pass).

---
*Phase: 06-history-list-calendar-directional-transition*
*Completed: 2026-07-31*
