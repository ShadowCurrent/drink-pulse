---
phase: 07-swiftui-list-performance-gesture-audit
plan: 03
subsystem: History (row hierarchy, hit target, Dynamic Type, VoiceOver)
tags: [swiftui, accessibility, dynamic-type, hit-target, anylayout, scaledmetric, voiceover, uitest]
status: complete

requires:
  - "07-01: D-01 = approve (ForEach identity on ConsumptionEvent.uuid); EventContextMenuModifier owning the delete confirmation"
  - "07-02: RowUnitContext, EventRowStrings, DaySection"
provides:
  - "EventRowButton — the single definition of the History row hierarchy, used by both History screens"
  - "EventRow as a plain-data view (event + RowUnitContext, zero formatting in body)"
  - "String Catalog keys history.row.hasNote and history.row.editHint"
  - "HistoryDaySectionCard / HistoryCalendarDayDetail now take RowUnitContext instead of UserProfile?"
  - "HistoryInteractionUITests+HitTarget, HistoryDynamicTypeUITests"
affects:
  - drinkpulse/Features/History/Components/EventRow.swift
  - drinkpulse/Features/History/Components/EventRowButton.swift
  - drinkpulse/Features/History/Components/EventRowStrings.swift
  - drinkpulse/Features/History/Components/EventContextMenu.swift
  - drinkpulse/Features/History/Components/HistoryDaySectionCard.swift
  - drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift
  - drinkpulse/Features/History/Components/HistoryCalendarView.swift
  - drinkpulse/Features/History/HistoryListQueryView.swift

tech-stack:
  added: []
  patterns:
    - "Row padding lives inside the Button's label, before contentShape — the padded band is the hit target, not decoration around it"
    - "AnyLayout(VStackLayout/HStackLayout) swaps a row's axis at accessibility Dynamic Type sizes without rebuilding subview identity"
    - "@ScaledMetric drives icon column and divider inset so non-text geometry tracks Dynamic Type"
    - "accessibilityActions live on the same ViewModifier that owns the contextMenu, so both paths share one confirmation flag and cannot drift"
    - "A duplicated view hierarchy is extracted into one component before its bugs are fixed, so one fix lands on every screen"

key-files:
  created:
    - drinkpulse/Features/History/Components/EventRowButton.swift
    - drinkpulseUITests/Features/History/HistoryInteractionUITests+HitTarget.swift
    - drinkpulseUITests/Features/History/HistoryDynamicTypeUITests.swift
  modified:
    - drinkpulse/Features/History/Components/EventRow.swift
    - drinkpulse/Features/History/Components/EventRowStrings.swift
    - drinkpulse/Features/History/Components/EventContextMenu.swift
    - drinkpulse/Features/History/Components/HistoryDaySectionCard.swift
    - drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift
    - drinkpulse/Features/History/Components/HistoryCalendarView.swift
    - drinkpulse/Features/History/HistoryListQueryView.swift
    - drinkpulse/Localizable.xcstrings
    - drinkpulseTests/Features/History/EventRowStringsTests.swift

decisions:
  - "D-01 branch taken: approve — both call sites iterate ForEach(events, id: \\.uuid); the decline branch's `id: \\.id` form appears nowhere"
  - "The AX5 launch argument must carry the constant's RAW VALUE (UICTContentSizeCategoryAccessibilityXXXL), not its symbol name; the plan's spelling is silently ignored by UIKit"
  - "Previews construct RowUnitContext directly instead of a UserProfile — a row genuinely no longer needs one, and it satisfies the zero-UserProfile criterion honestly"
  - "HistoryCalendarView's weekday header loop gained a WeekdayLabel { id, text } value type; weekday symbols repeat within a locale, so the text cannot be the identity"

requirements-completed: [A7-1, A6-1, A4-1, A4-3, A1-3, C12-1, C14-1, C14-2, C14-3, C14-5, C14-6]

metrics:
  duration: ~70 min
  completed: 2026-08-04

actuals:
  tokens: 10700
  tasks: 3
  commits: 5
---

# Phase 07 Plan 03: History Row Extraction, Hit Target and Dynamic Type Summary

**One `EventRowButton` now defines the History row hierarchy for both screens, its 10pt padding is inside the interactive shape instead of being visible-but-inert, the row swaps layout axis and scales its geometry at AX5, and Duplicate/Delete are explicit VoiceOver actions sharing the delete confirmation.**

## Interface signatures for 07-05

07-05 rewires `HistoryListQueryView` against these — recorded verbatim:

```swift
struct EventRowButton: View {
    let event: ConsumptionEvent
    let unitContext: RowUnitContext
    let isLast: Bool
    let onEdit: (ConsumptionEvent) -> Void
    // plus private @Environment: \.modelContext, \.healthService, \.accessibilityReduceMotion
}

struct HistoryDaySectionCard: View {
    let title: String
    let events: [ConsumptionEvent]
    let unitContext: RowUnitContext      // was: let profile: UserProfile?
    let onEditEvent: (ConsumptionEvent) -> Void
}

struct HistoryCalendarDayDetail: View {
    let day: Date
    let events: [ConsumptionEvent]
    let unitContext: RowUnitContext      // was: let profile: UserProfile?
    let onEditEvent: (ConsumptionEvent) -> Void
}

struct EventRow: View {
    init(event: ConsumptionEvent, unitContext: RowUnitContext)
}
```

`HistoryListQueryView` and `HistoryCalendarView` keep their existing `profile: UserProfile?`
parameters and each build the context once via a `private var unitContext: RowUnitContext {
RowUnitContext(profile) }`. **`HistoryView.swift` and `HistoryCalendarQueryView.swift` were not
touched** — the parents' public signatures are unchanged, as the plan required.

## What Was Built

### Task 1 — `EventRow` as plain data that survives AX5 (A4-1, A4-3, A6-1, C14-3, C14-5)

`EventRow` went from six derived properties plus two string builders down to two stored inputs
(`event`, `unitContext`) and one `private let strings: EventRowStrings` built in `init`. The body
now reads only `event.icon`, `event.notes` and the precomputed strings — the comment-stripped
formatting grep returns `0`, so no formatting call survives in the view at all.

Dynamic Type hardening: the 36pt icon frame became `@ScaledMetric(relativeTo: .title2)`, and the
row picks its container through `AnyLayout` — `VStackLayout(alignment: .leading, spacing: 4)` at
accessibility sizes, the existing `HStackLayout(spacing: 12)` otherwise, with the `Spacer()` dropped
in the stacked branch so leading alignment holds. `AnyLayout` erases a *layout*, not a view; the
repo-wide count of the forbidden type-erased **view** wrapper is still `0`, and `GeometryReader`
still appears nowhere under `Features/History/`.

`EventRowStrings` gained the C14-5 note clause: when `notes` is non-empty the spoken label gets a
comma-separated `history.row.hasNote` suffix. The note's **content** is never spoken (T-07-14) — only
its existence.

### Task 2 — `EventRowButton` extraction and explicit accessibility actions (A7-1, A1-3, C12-1, C14-1, C14-2, C14-6, A6-1)

The row hierarchy that was written out verbatim in two files — and had already diverged, with the
calendar copy missing the padding that was the recorded fix for BUG 1 — now has exactly one
definition. Both files construct `EventRowButton` once and contain zero `EventRow(` constructions.

**The C14-1 fix is an ordering change.** The padding moved from the `Button` (outside a
`contentShape(Rectangle())` that had already pinned the interactive shape to the unpadded frame)
to the `EventRow` inside the label, *before* `contentShape`. The measured row height is now
**56.67pt**, all of it hit-testable.

Index-based iteration is gone everywhere under `Features/History/` (A1-3): both row loops iterate the
collection directly keyed by `\.uuid`, computing `isLast` as `event.uuid == events.last?.uuid` — an
equality test on the model's own field, not an identity keypath. The calendar's weekday header loop
also lost its offset-keyed iteration.

C14-2's `accessibilityActions` went on `EventContextMenuModifier`, not on `EventRowButton`, so the
accessibility Delete arms **the same** `isPresentingDeleteConfirmation` flag the menu's destructive
button arms. The Duplicate body was extracted to `performDuplicate()`, mirroring 07-01's
`performDelete()`, so menu item and accessibility action invoke identical code.

### Task 3 — Hit target and AX5 pinned by UI tests (C14-1, C14-3)

Three new executing tests, in two new files; the already-oversized
`HistoryInteractionUITests.swift` (312 lines) was **not** grown.

- `test_rowTopEdge_isTappable_opensEditor` taps a normalized coordinate at `dy 0.06` — inside the
  formerly-dead padding band. A centre tap passes with or without the fix, so it deliberately does
  not use `.tap()`.
- `test_rowHitTarget_meetsMinimumHeight` — 44pt minimum.
- `test_row_growsAndStaysHittable_atAX5` — two passes against one fixture, asserting in order that
  the row grew, is hittable, does not overflow the window, keeps `"500 ml"` in its combined label,
  and still opens the editor.

## Task Commits

| Commit | Type | Description |
|--------|------|-------------|
| `f320820` | test | RED — failing test for the VoiceOver note announcement (C14-5) |
| `df1a997` | feat | GREEN — `EventRow` plain-data + AX5 hardening + `history.row.hasNote` |
| `9099648` | feat | `EventRowButton` extraction, unit-context rewiring, accessibility actions |
| `27fedbf` | test | Hit-target and AX5 UI tests |
| _(this file)_ | docs | SUMMARY |

## Verification Results

| Plan check | Result |
|---|---|
| 1. Seven-suite scoped run | **`** TEST SUCCEEDED **`** — 21 XCTest cases + 9 Swift Testing cases, 0 failures |
| 2. Build warnings | **0 Swift compiler warnings** (see note) |
| 3. No file over 300 lines created/grown | Clean — new files are 74 / 53 / 125 lines; `EventRow.swift` is 100 |
| 4. No schema file touched | `0` paths under `Domain/Persistence/Schemas/` |
| 5. `print(` under `Features/History/` | none |
| 6. `try!` / `as!` in `EventRowButton` / `EventRow` | one `try!`, inside a `#Preview` block — explicitly permitted |
| 7. Both `<human-check>` outcomes recorded | **Recorded as OUTSTANDING — see below** |

Task-level greps all pass: `EventRowButton(` = 1 in each call site, `EventRow(` = 0 in each,
`enumerated()` = 0 across `Features/History/`, `id: \.uuid` = 1 in each row file with `id: \.id` = 0
(proving the declined D-01 branch was not taken by the back door), `UserProfile` = 0 in `EventRow` /
`HistoryDaySectionCard` / `HistoryCalendarDayDetail`, `RowUnitContext(profile)` = 1 in each list
parent, `accessibilityActions` = 1 in `EventContextMenu`, `accessibilityHint` = 1 in `EventRowButton`,
`history.row.hasNote` en value = `has a note`.

**Build-warning note (unchanged from 07-01 / 07-02):** a literal `grep -c 'warning:'` returns `1` on
any clean build because of a pre-existing non-source packaging line — `appintentsmetadataprocessor …
Metadata extraction skipped. No AppIntents.framework dependency found.` Excluding it, the count is `0`.

### Full-suite run (CLAUDE.md escalation)

CLAUDE.md requires escalating past the scoped run when 3+ test classes are affected; seven are, so a
full `xcodebuild test` was run: **82 tests, 81 passed, 1 failure** —
`HealthWriteHooksUITests.test_healthEnabled_deleteDrink_stillRemovesEvent`.

**That failure is pre-existing and not caused by this plan, proven by A/B, not by argument.** This
plan's nine changed files were reverted to `67725ae` (the branch point), the three new files moved
aside, and the single test re-run against that unmodified pre-plan tree: it **failed identically**.
The tree was then restored to `HEAD` and verified byte-identical.

Root cause: the test long-presses a row, taps the context menu's `Delete`, and expects the row to
vanish immediately — but **07-01 gated exactly that behavior behind a confirmation dialog**, so the
menu item now only arms the flag. 07-01 updated `HistoryInteractionUITests` and
`DuplicateEditPersistenceUITests` for the new gate and missed this third file. The fix belongs to the
owner of the confirmation gate; per the scope-boundary rule it was **not** fixed here (it is in a file
this plan does not own, and touching it risks a merge conflict with sibling wave agents). Logged to
`.planning/WINDOWS.md`.

## Human checks — OUTSTANDING (not performed)

Both of Task 3's `<human-check>` items require a human at a device and **were not performed**; they
are recorded here and in `.planning/WINDOWS.md` as `unrun-verify`. Neither is auto-approvable.

**C14-2 — VoiceOver rotor.** With VoiceOver enabled (device preferred over simulator), focus a
History row and swipe up/down through the Actions rotor. Record whether "Duplicate" and "Delete" are
announced, and whether choosing Delete presents the confirmation. This settles 07-RESEARCH
Assumptions Log **A1** (whether `contextMenu` already republishes its items as VoiceOver actions) and
is the first concrete step on STATE.md's outstanding accessibility-audit blocker. The explicit actions
added in Task 2 are correct whichever way A1 resolves — worst case they are redundant, best case they
are the only way a VoiceOver user can reach Duplicate/Delete at all.

**C14-7 — contrast.** Run Accessibility Inspector's contrast audit over the History list in light
appearance, dark appearance, and with Increase Contrast enabled. `EventRow` renders `.secondary` on
`.caption`/`.caption2` over a translucent `.glassEffect` background, so the effective ratio depends on
what is behind the glass and **cannot be determined statically — this is an unmeasured value, not an
asserted violation.** If it fails, the remedy is an explicit color token meeting 4.5:1 (body) / 3:1
(large text), **not** a font-size change, and it should be filed as a follow-up rather than patched
inside this phase.

## Deviations from Plan

### 1. [Rule 3 - Blocking] Task 1's build/test criteria are unsatisfiable under its own file restriction

**Found during:** Task 1.
**Issue:** Task 1 changes `EventRow`'s initialiser and simultaneously forbids touching the two call
sites ("Task 2 owns the call sites"). Its own acceptance criteria then require a clean
`xcodebuild build` and a passing `xcodebuild test` — impossible with two uncompilable call sites.
**Fix:** The two `EventRow(...)` constructions were rewired to `RowUnitContext(profile)` in Task 1's
commit — the minimum to keep the build green. Task 2 replaced those lines wholesale, so the transient
state lived for exactly one commit.
**Committed in:** `df1a997`

### 2. [Rule 1 - Bug] The prescribed AX5 launch-argument value is not a valid content size category

**Found during:** Task 3 — caught by the precondition assertion, working exactly as designed.
**Issue:** The plan specifies `-UIPreferredContentSizeCategoryName
UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`. That is the API **symbol** name
(`UIContentSizeCategory.accessibilityExtraExtraExtraLarge`) with the raw-value prefix glued on, not a
raw value. UIKit silently ignores an unrecognised value, so both passes launched at the default size
and reported **identical** row heights (56.666… vs 56.666…).
**Investigation:** rather than guessing (CLAUDE.md's no-guessing rule), the valid raw values were read
out of the iOS 26.5 simulator runtime's `UIKitCore` binary: the set is
`UICTContentSizeCategory{XS,S,M,L,XL,XXL,XXXL}` and
`UICTContentSizeCategoryAccessibility{M,L,XL,XXL,XXXL}`. Also cross-checked against
`simctl ui … content_size`, which reported the device sitting at `large`.
**Fix:** the test now uses `UICTContentSizeCategoryL` and `UICTContentSizeCategoryAccessibilityXXXL`,
both named constants with a comment recording the trap. The test then **passed on the first re-run**,
which is also the proof that the row genuinely grows, stays hittable and stays in-window at AX5.
**Criterion superseded:** Task 3's acceptance criterion greps for the literal
`UICTContentSizeCategoryAccessibilityExtraExtraExtraLarge`. That string is non-functional, so the
criterion as written would have been satisfied by a suite that silently measured nothing. It still
returns `1` — the invalid form is named in the doc comment as the documented trap — but the load-bearing
check is the working raw value, present twice.
**Committed in:** `27fedbf`

### 3. [Rule 3 - Blocking] `.enumerated()` had a third occurrence the plan did not mention

**Found during:** Task 2.
**Issue:** The A1-3 criterion is repo-scoped (`grep -rc 'enumerated()' drinkpulse/Features/History/`
= 0 for every file), but a third occurrence lived in `HistoryCalendarView`'s weekday header loop,
keyed on `\.offset`.
**Fix:** Introduced a `WeekdayLabel { id, text }` value type. `\.self` would have been wrong — weekday
symbols repeat within a locale (English has two "S" and two "T") — so the column position is the
identity. `HistoryCalendarView.swift` is already in this plan's `files_modified`.
**Committed in:** `9099648`

### 4. [Rule 1 - Bug] Two doc comments tripped their own acceptance greps

**Found during:** Tasks 1 and 2 — the same trap 07-02 hit with `@Observable`.
**Issue:** `EventRow`'s doc comment contained the literal `UserProfile` (criterion: `0`) and
`HistoryCalendarView`'s contained `.enumerated()` (criterion: `0`).
**Fix:** Reworded to "the observable profile model" and "index-pairing / offset-keyed iteration" —
same meaning, no forbidden literal.
**Committed in:** `df1a997`, `9099648`

### 5. [Deviation - documented] Previews use `.grams`, and build no profile at all

`AlcoholUnit.units` — which the plan names for the imperial preview row — was retired in plan-0029;
07-02 hit the same thing and substituted `.grams`. This plan follows that precedent. Separately, the
`HistoryDaySectionCard` / `HistoryCalendarDayDetail` previews now construct `RowUnitContext` directly
rather than a `UserProfile`, which is what makes the zero-`UserProfile` criterion pass **honestly**
rather than by comment-golf — and it demonstrates the point of A6-1: a row no longer needs a profile
to render. `UserProfile.self` was correspondingly dropped from those previews' `ModelContainer`
(nothing in them inserts one; `ConsumptionEvent` has no relationship to it).

### 6. [Deviation - documented] UI tests run on iPhone 17 Pro Max, not iPhone 17 Pro

07-02's SUMMARY records that concurrent `xcodebuild test` runs against one booted simulator produce
spurious "unexpected exit" failures, and recommends the verifier use an idle device. `iPhone 17 Pro`
was already booted (a sibling wave-2 agent), so every run in this plan targeted `iPhone 17 Pro Max`.
No flakiness was observed across ~7 runs. The destination is a harness choice, not a behavioral one.

### Note on Task 2's TDD marking

Task 2 is marked `tdd="true"` but carries **no `<behavior>` block** — its `<verify>` is the four
pre-existing History UI suites. It was therefore executed as a refactor pinned by existing tests
(18/18 green before commit), not as a RED/GREEN cycle. Task 1 supplied this plan's genuine RED
(`f320820` — a real failure on a real assertion). Recorded for gate-compliance transparency.

## Documentation lookup limitation

CLAUDE.md requires verifying unfamiliar APIs against Apple's documentation. **No documentation tool
was reachable in this environment** — no Context7 MCP tools, and `ctx7` is not installed. The APIs
adopted (`AnyLayout`, `VStackLayout`/`HStackLayout`, `accessibilityActions(_:)`,
`DynamicTypeSize.isAccessibilitySize`, `@ScaledMetric(relativeTo:)`) are all long-established and far
below the project's iOS 26 floor, and every one was validated by a zero-warning compile plus an
executing UI test. Where a value could not be safely assumed — the content size category raw
strings — it was read directly out of the iOS 26.5 runtime binary rather than guessed (deviation 2).
The `swiftui-expert-skill` was consulted per CLAUDE.md and supplied the `@ScaledMetric(relativeTo:)`
and `children: .combine` guidance; it does not cover `AnyLayout` or `accessibilityActions`.

## Threat Model Compliance

- **T-07-10 (high, mitigate)** — the new accessibility Delete sets the *same*
  `isPresentingDeleteConfirmation` flag as the menu's destructive button and lives on the same
  modifier, so it cannot drift from the touch path. `ContextMenuDeleteConfirmationUITests` (3/3) still
  passes.
- **T-07-11 (mitigate)** — rows can no longer reach body weight, date of birth or weekly goal; the
  zero-`UserProfile` greps hold in all three row files, and the previews no longer build a profile.
- **T-07-12 (mitigate)** — `-UIPreferredContentSizeCategoryName` is system-provided, alters no app
  state and seeds no data. No new `UITestSeed` hook was added.
- **T-07-13 (high, mitigate)** — no `@Model` type and no file under `Domain/Persistence/Schemas/` was
  touched (verified).
- **T-07-14 (accept)** — `history.row.hasNote` announces only that a note *exists*. The note body is
  never spoken, never logged, never exported.

No new threat surface: no network call, no dependency added, no new trust boundary.

## Known Stubs

None. No placeholder values, no unwired data sources, no skipped tests.

## Deferred Issues

- **`HealthWriteHooksUITests.test_healthEnabled_deleteDrink_stillRemovesEvent` fails** — pre-existing,
  A/B-proven, caused by 07-01's confirmation gate. Not fixed here (out of scope; not this plan's file;
  merge-conflict risk with sibling agents). Logged to `.planning/WINDOWS.md`.
- **Both `<human-check>` items** (C14-2 VoiceOver rotor, C14-7 contrast) remain unperformed — see
  above. Logged to `.planning/WINDOWS.md` as `unrun-verify`.
- **`appintentsmetadataprocessor` packaging warning** — pre-existing on a clean baseline, unrelated,
  out of scope (same finding as 07-01 and 07-02).

## Docs Owed at Phase Close (not written here)

Running as a parallel worktree agent, so shared/append-only docs were deliberately left untouched to
avoid cross-agent merge conflicts. Per CLAUDE.md's end-of-task checklist, the phase close-out owes:

- `docs/DEVLOG.md` — a **phase-level** entry (the file's convention is per-phase, never per-plan).
- `.claude/context/current-focus.md`, `.claude/context/open-questions.md`.

**Living-docs audit performed:** `README.md`, `.planning/PROJECT.md`, `docs/architecture.md` and
`docs/domain.md` mention none of `EventRow`, `HistoryDaySectionCard`, `HistoryCalendarDayDetail` or
`contentShape` (verified by grep), so nothing they state was contradicted. No ADR is owed — this plan
made no new architectural choice; it applied ADR-0004's existing no-repository, value-injection shape.

`.planning/STATE.md` and `.planning/ROADMAP.md` were **not** modified — the orchestrator owns those.

## Next Phase Readiness

- 07-05 can rewire `HistoryListQueryView` against the signatures recorded above; no further shape
  changes are expected from this plan.
- The accessibility-audit blocker in STATE.md is now partly addressable: Dynamic Type up to AX5 is
  pinned by an executing test; VoiceOver remains a human check.
- **Environment caveat for the verifier:** run UI tests on a simulator no sibling agent is using, or
  serially. The full suite takes ~21 minutes.

## Self-Check: PASSED

All three created source/test files and this SUMMARY exist on disk; all five commits
(`f320820`, `df1a997`, `9099648`, `27fedbf`, `9de5fc8`) are in this branch's history; the working
tree is clean and byte-identical to `HEAD` after the A/B revert-and-restore.

---
*Phase: 07-swiftui-list-performance-gesture-audit*
*Completed: 2026-08-04*
