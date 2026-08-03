---
phase: 07-swiftui-list-performance-gesture-audit
plan: 04
subsystem: Guideline choice (Settings picker + onboarding step)
tags: [swiftui, deduplication, accessibility, liquid-glass, scrollview, uitest]
status: complete

requires:
  - "Owner decisions D-03 (plain checkmark) and D-05 (now) from 07-01-SUMMARY"
  - SettingsSection / dpGlassCard (plan-0027 glass-card chrome)
  - "-dp_uitest YES seeded fixture (profile on WHO)"
provides:
  - "GuidelineChoice.selectable — the single source of the pickable guideline list"
  - "GuidelineChoiceRow — the single guideline row definition, used by both screens"
  - "accessibility identifier pattern guidelineChoiceRow.<rawValue>"
  - "SettingsSection.init(content:) — titleless glass-card section overload"
affects:
  - drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift
  - drinkpulse/Features/Onboarding/Components/GuidelineStep.swift
  - drinkpulse/Features/Settings/Components/SettingsSection.swift

tech-stack:
  added: []
  patterns:
    - "A row duplicated across two screens becomes one View type, so a per-screen accessibility trait cannot exist on one and be missing on the other"
    - "The pickable subset of an enum is a stored static constant, not a filter re-run in every body pass"
    - "A row leaving List supplies its own vertical padding INSIDE the Button's contentShape, so the padded strip stays tappable"
    - "A glass-card section on a screen that already has a title uses the titleless SettingsSection overload rather than repeating the title as a header"

key-files:
  created:
    - drinkpulse/Domain/GuidelineChoice+Selectable.swift
    - drinkpulse/Features/Settings/Components/GuidelineChoiceRow.swift
    - drinkpulseUITests/Features/Settings/GuidelinePickerUITests.swift
  modified:
    - drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift
    - drinkpulse/Features/Onboarding/Components/GuidelineStep.swift
    - drinkpulse/Features/Settings/Components/SettingsSection.swift
    - drinkpulseTests/Domain/GuidelineChoiceDisplayTests.swift

decisions:
  - "D-03 plain: the canonical checkmark is the SF Symbol `checkmark` with .fontWeight(.semibold); the onboarding step's checkmark.circle.fill was the copy that changed"
  - "The checkmark image is .accessibilityHidden(true) because the .isSelected trait now carries that meaning"
  - "D-05 now: Task 4 executed — both screens converted to ScrollView + titleless SettingsSection + dpGlassCard"
  - "Each ForEach element wraps row+Divider in a VStack so the subview count per element stays constant, matching HistoryDaySectionCard"
  - "Onboarding coverage of the conversion is the existing label-matching OnboardingFlowUITests, not a duplicated identifier test"

metrics:
  duration: ~17 min
  completed: 2026-08-03

actuals:
  tokens: 5850
  tasks: 4
  commits: 5
---

# Phase 07 Plan 04: Guideline Row Deduplication + Glass-Card Conversion Summary

The guideline-choice row existed twice, in two diverged copies, and the divergence had already
produced a real accessibility defect. It now exists once — and both screens that use it moved off
`.insetGrouped` onto the app's canonical Liquid Glass chrome, which removes the last `List` of that
style from the codebase.

## Owner Decisions Consumed

Both preconditions were checked against `07-01-SUMMARY.md` before any code was written.

| ID | Recorded answer | Effect here |
|----|-----------------|-------------|
| **D-03** | `plain` | The shared row uses the SF Symbol **`checkmark`** with `.fontWeight(.semibold)`. That is what the Settings picker already drew; the **onboarding step's `checkmark.circle.fill` is the copy that changed**. |
| **D-05** | `now` | **Task 4 ran.** Had it read `defer` or been absent, Task 4 would have been skipped and recorded as skipped. |

## What Was Built

### Task 1 — `GuidelineChoice.selectable` (A1-2)

One stored `static let` derived from `allCases` minus `.custom`. Stored, not computed, is the fix
itself: the Settings picker previously ran `allCases.filter { $0 != .custom }` **inside `body`**,
allocating a fresh array on every body pass, while the onboarding step hard-coded the same six cases
in a parallel list. Three Domain-layer tests pin the contents, the exclusion of `.custom`, and that
the order tracks the enum's declaration order — so a seventh guideline is picked up automatically on
both screens and lands in a predictable slot.

`.custom` is excluded because it is a *derived* state the app assigns when a user overrides
thresholds, never a value offered in a list to choose between.

### Task 2 — `GuidelineChoiceRow` (A7-2, C14-4, B9-2)

One `View` type replaces the two inline copies. The three ways they had diverged:

| Divergence | Settings picker (before) | Onboarding step (before) | Now |
|------------|--------------------------|--------------------------|-----|
| Name source | `displayName` | file-private `onboardingName` | `displayName` |
| Checkmark | `checkmark` | `checkmark.circle.fill` | `checkmark` (D-03) |
| Selected trait | **missing** | present | present, in the shared component |

**C14-4 is the defect that duplication produced.** The Settings picker conveyed selection through a
checkmark glyph alone — no `.accessibilityAddTraits(.isSelected)`, and the image neither labelled nor
hidden — so a VoiceOver user heard the guideline name and its threshold summary with no indication of
which one was active. Its near-identical sibling already did this correctly. Putting the trait in the
shared component makes that divergence structurally impossible rather than merely fixed once.

The checkmark image is now `.accessibilityHidden(true)`: the trait carries the meaning, so exposing
the glyph too would make VoiceOver read a symbol description *in addition to* the state.

Each row also carries `.accessibilityIdentifier("guidelineChoiceRow.\(choice.rawValue)")`, so tests
address rows without depending on localized text.

**T-07-17 discharged — no rendered string changed.** The plan required reading both name sources and
halting if any key differed. Both were read in full before deletion: `onboardingName` and
`displayName` switch over all seven cases and resolve to the **identical** `settings.guideline.*`
String Catalog keys. Confirmed objectively too — `git diff --name-only drinkpulse/Localizable.xcstrings`
is empty for this whole plan.

### Task 3 — UI test pinning the trait (C14-4)

`GuidelinePickerUITests` asserts the current choice reports `isSelected == true` while a different one
reports `false`, and that the trait *moves* when the choice changes. This assertion was impossible
before Task 2. Rows are addressed by `guidelineChoiceRow.*` identifiers, never by localized label —
the simulator's system locale is Polish.

### Task 4 — Glass-card conversion (B9-3, B9-2; D-05 = `now`)

`SettingsSection.swift:5`'s own doc comment records leaving `.insetGrouped` as deliberate — "Replaces
the opaque `.insetGrouped` List rows that made Settings the odd screen out." By that stated rationale
the two guideline screens had become the odd screens out. Both now render as `ScrollView` +
**titleless** `SettingsSection` + `dpGlassCard`.

1. **`SettingsSection` gained a titleless overload.** `titleKey` widened to
   `String.LocalizationValue?`, plus `init(@ViewBuilder content:)`. The existing `init(_:content:)` is
   byte-for-byte unchanged, so **all twelve current call sites compiled untouched** — verified: the
   diff over `drinkpulse/Features/Settings/` contains no file other than this plan's three. Reuse
   rather than a new component was deliberate: copying the container recipe into two more files would
   re-commit the very duplication finding A7-2 exists to remove.
2. **The row carries its own vertical rhythm.** `.padding(.vertical, 10)` sits **immediately before**
   `.contentShape(Rectangle())`, inside the `Button`'s label. Both halves matter and this repo has
   first-hand evidence for each: a row leaving `List` loses the platform's default row insets and
   collapses to font-metrics height (the **plan-0038 regression** recorded at
   `HistoryDaySectionCard.swift:36-44`), and padding applied *outside* the content shape produces a
   strip that is visible but not tappable (the dead-padding defect **C14-1** fixes in History —
   `HistoryDaySectionCard` applies its padding outside the `Button`, which is exactly why C14-1
   exists; that half was deliberately not copied).
3. **Titleless sections on both screens** — the picker's nav title already reads "Guideline" and the
   onboarding step already carries a large title, so a "GUIDELINE" header beneath either would be that
   word twice. This is also what let the conversion introduce **zero new String Catalog keys**.
4. **No background added** to either screen; no screen in this app sets one outside previews.

## Verification

| Check | Result |
|-------|--------|
| `GuidelineChoiceDisplayTests` (16 tests, incl. 3 new `selectable` cases) | **passed** |
| `GuidelinePickerUITests` (3), `SettingsUITests` (5), `OnboardingFlowUITests` (3) | **11/11 passed, `** TEST SUCCEEDED **`** |
| `test_guidelinePicker_changePersists` + full onboarding walkthrough after conversion | **passed unchanged** |
| Swift compiler warnings | **0** |
| `listStyle(.insetGrouped)` repo-wide | **none** (B9-3 closed app-wide) |
| `git diff drinkpulse/Localizable.xcstrings` | **empty** (no copy changed) |
| Other `SettingsSection` call sites needing edits | **none** |
| `SettingsView.swift` / `OnboardingView.swift` edited | **no** |
| Files under `Domain/Persistence/Schemas/` touched | **0** |
| Production files over 300 lines | **none** |
| `print(` / `try!` / `as!` in new files | **none** |
| Padding precedes `contentShape` in the row | **OK** (awk order check) |

### The load-bearing conversion assertion

`test_guidelinePicker_rendersEveryChoiceAsCardRow_andSelectionStillWorks` asserts **all six** rows
exist by identifier. A `List` builds rows lazily; a `VStack` inside a `ScrollView` builds all of them
— so "all six present at the `.medium` detent" is simultaneously the objective signature of the new
layout and the proof that no guideline was dropped in the rewrite. It then asserts the WHO and Germany
rows are `isHittable` with `frame.height >= 44` (CLAUDE.md's floor — the Step 2 padding is what makes
that true), and that selection still works end to end.

The test deliberately **never scrolls**: at the `.medium` detent a swipe can drag the sheet rather
than the scroll view, so existence is asserted for all six but hittability only for rows guaranteed on
screen.

Onboarding coverage of the conversion is the existing `OnboardingFlowUITests`, whose
`selectGuideline(in:named:)` matches `app.buttons` by label and is therefore layout-agnostic. Its pass
is the proof that `GuidelineStep` still selects and advances. That is deliberate coverage, not a gap.

## Outstanding Verification (human-check — NOT satisfied by this plan)

**B9-3 appearance has not been visually verified.** The plan's `<human-check>` requires opening the
Settings guideline sheet and the onboarding guideline step in **light and dark** appearance and at
**AX5**, confirming that the cards read as the same surface as the Settings sections behind them, that
dividers land between rows rather than at the card edge, and that at the `.medium` detent the sheet
still scrolls to reveal the lower choices with no row clipped.

Glass rendering is not machine-assertable, so this cannot be closed by an executor. It is recorded in
`.planning/WINDOWS.md` as an `unrun-verify` entry and is owed at phase verification. **A failure here
is a padding/inset adjustment in `GuidelineChoiceRow` or the section padding — not a revert**; the
conversion is `reversible` (view-layer only, no model, no schema, no persisted value, no public
initializer signature changed).

## Deviations from Plan

### 1. [Rule 2 - Correctness] Each `ForEach` element wraps row + `Divider()` in a `VStack`

**Found during:** Task 4, Step 3.
**Issue:** The plan specified emitting `Divider()` before every element except the first, expressed as
`if choice != GuidelineChoice.selectable.first { Divider() }`. Written literally at the `ForEach`
leaf, that makes the element return **one or two** subviews depending on position — the varying
subview-count shape the phase's own A2 check flags, and a violation of the "constant number of views
per `ForEach` element" rule confirmed via `swiftui-expert-skill` (consulted per CLAUDE.md before this
conversion).
**Fix:** Each element wraps the conditional `Divider()` and the row in a `VStack(spacing: 0)`, so the
element is always exactly one subview. This is the shape `HistoryDaySectionCard` already uses in this
repo. The plan's actual constraint — that the separator is keyed off the **value**, not an enumerated
index (so it works with, not against, finding A1-3) — is preserved exactly, and the acceptance
criterion (`Divider()` appears once per file) still holds.
**Files:** `GuidelinePickerSheet.swift`, `GuidelineStep.swift`
**Commit:** `c1bba26`

### 2. [Documented] UI-test identifiers spelled out in full rather than composed

**Found during:** Task 4, Step 5.
Task 3's helper composed identifiers as `"guidelineChoiceRow.\(choice)"`, which put the literal on a
single line. Task 4's acceptance criterion requires at least six *lines* naming it. The identifiers
are now declared in full in a `private enum RowID`, one per line, and the helper takes a complete
identifier. This is clearer regardless — the assertions name exactly what they address instead of
hiding it behind string interpolation.
**Commit:** `c1bba26`

## TDD Gate Compliance

Task 1 was the only `tdd="true"` task.

| Gate | Commit | Evidence |
|------|--------|----------|
| RED | `9cf0fa8` | Genuine failure: `error: type 'GuidelineChoice' has no member 'selectable'` — the Swift form of a failing test, since the constant did not exist. No failure was fabricated. |
| GREEN | `7210436` | 16/16 tests pass, including all three new `selectable` cases. |
| REFACTOR | — | Not needed; the implementation is a single stored constant. |

## Known Stubs

None.

## Threat Flags

None. No network call, no new `os.Logger` interpolation, no seeding hook, no `@Model` change, no new
String Catalog key.

Threat register outcomes: **T-07-15 mitigated** (one `selectable` source; zero hard-coded lists remain
on either screen — verified by grep). **T-07-16 mitigated** (`.isSelected` in the shared component,
pinned by two UI tests addressing rows by stable identifier). **T-07-17 mitigated** (both name sources
read in full before deletion; identical keys; `Localizable.xcstrings` diff empty). **T-07-18 accepted**
(identifiers derive from a public enum's raw values and carry no user data). **T-07-19 mitigated** (no
`@Model` type and no file under `Domain/Persistence/Schemas/` touched — verified).
**T-07-20 mitigated** (row insets re-supplied inside the content shape; all six rows asserted present,
hittable and ≥44pt; `OnboardingFlowUITests` proves the onboarding step still selects and advances).
**T-07-21 mitigated** (`SettingsSection` change is purely additive; the diff over
`drinkpulse/Features/Settings/` contains no other call site).

## Deferred Issues

- **`drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` is 312 lines**, over the
  300-line ceiling. **Pre-existing and out of scope** — confirmed identical (312 lines) at this wave's
  base commit `67725ae`; this plan neither created nor grew it. It belongs to the History surface
  (07-03), not here.
- **`appintentsmetadataprocessor` build warning.** `grep -c 'warning:'` returns `1`, not `0`. The line
  is `warning: Metadata extraction skipped. No AppIntents.framework dependency found.` — emitted by a
  packaging tool, not the Swift compiler, and present on a clean baseline (already recorded as
  pre-existing in `07-01-SUMMARY.md`). **Swift compiler warnings are zero.**

## Docs Owed at Phase Close (not written here)

This plan ran as a parallel worktree agent, so shared living docs were intentionally left untouched to
avoid cross-agent merge conflicts. Per CLAUDE.md's end-of-task checklist, whoever closes Phase 7 owes:

- `docs/DEVLOG.md` — a phase-level entry (that file's convention is per-phase, never per-plan).
- `.claude/context/current-focus.md` and `.claude/context/open-questions.md` — phase-level state.

No other living doc is contradicted by this plan: `architecture.md`, `domain.md`, `README.md` and
`.planning/PROJECT.md` describe no guideline-picker layout, row component, or list styling (verified by
grep). `.planning/STATE.md` and `.planning/ROADMAP.md` were **not** modified — the orchestrator owns
those.

## Commits

| Commit | Type | Description |
|--------|------|-------------|
| `9cf0fa8` | test | Failing tests for `GuidelineChoice.selectable` (RED) |
| `7210436` | feat | `GuidelineChoice.selectable` as the one pickable-list source (A1-2) |
| `73308dc` | refactor | Extract `GuidelineChoiceRow` shared by both screens (A7-2, C14-4) |
| `c9577bc` | test | Pin the picker's selected-state trait (C14-4) |
| `c1bba26` | style | Convert both guideline screens to glass cards (B9-3, D-05) |
