---
phase: 07-swiftui-list-performance-gesture-audit
verified: 2026-08-04T01:27:35Z
status: human_needed
score: 17/20 must-haves verified
behavior_unverified: 3
overrides_applied: 0
gaps: []
re_verification:
  previous_status: human_needed
  previous_score: 17/20
  previous_verified: 2026-08-04T00:45:52Z
  trigger: "WR-01 (History section-cache staleness) fixed in e866cf0; disclosure logged in d7ea411"
  gaps_closed:
    - "WR-01 mechanism — `.onChange(of: events, initial: true)` replaced with `.onChange(of: events.map(\\.modifiedDate), initial: true)` (e866cf0). Independently re-derived as sound: `EditEventView.save()` assigns `consumptionDate` (:238) then calls `event.touch()` (:248) unconditionally, `touch()` sets `modifiedDate = .now` unconditionally, and `[Date]` has true value-Equatable — so the trigger now fires for exactly the repro the old identity-keyed array missed."
    - "WR-01 ledger visibility — now `.planning/WINDOWS.md` entry 9 (`kind: deviation`, `status: open`), so `/gsd-ship` blocks on it. Previously recorded only inside 07-REVIEW.md, invisible to the gate."
  gaps_remaining: []
  regressions: []
  evidence: "Full suite re-run at HEAD (d7ea411): `** TEST SUCCEEDED **`, 705 passed / 0 failed / 0 skipped (612 Swift Testing in 46 suites + 93 XCTest UI). Identical count to the pre-fix run — corroborating that no test was added for WR-01, exactly as WINDOWS #9 discloses."
deferred:
  - truth: "A3-1 — `#Index` on `ConsumptionEvent.consumptionDate`"
    addressed_in: "Own follow-up phase (owner decision D-04 = `schedule`)"
    evidence: "ROADMAP.md:69 'Excluded and flagged: A3-1 (needs `SchemaV5` + `MigrationStage` — own phase or accepted-and-deferred, per decision D-04)'; 07-01-PLAN.md:141-155; 07-01-SUMMARY.md D-04 table row; 07-05-SUMMARY.md roll-up item 11; current-focus.md item 3; DEVLOG 'Deferred, deliberately'. Verified in code: zero `#Index` occurrences repo-wide, SchemaV4 still current, the only `Domain/` file changed this phase is the additive `GuidelineChoice+Selectable.swift`."
behavior_unverified_items:
  - truth: "C14-2 — VoiceOver exposes Duplicate and Delete as row actions without a long-press"
    test: "With VoiceOver on (device preferred over simulator), focus a History row, swipe up/down through the Actions rotor"
    expected: "'Duplicate' and 'Delete' are announced as actions; activating Delete presents the confirmation dialog rather than deleting immediately"
    why_human: "XCUITest cannot drive the VoiceOver Actions rotor. Whether `contextMenu` already republishes its items as VoiceOver actions is unresolved (07-RESEARCH Assumptions Log A1) — the explicit `.accessibilityActions` are present and correctly wired to the shared confirmation flag, but the announcement itself is unobservable to grep or to an automated test. Planner-declared `<human-check>` in 07-03-PLAN.md; tracked as WINDOWS.md #3."
  - truth: "C14-7 — `.secondary` captions over translucent glass meet 4.5:1 / 3:1 contrast"
    test: "Run Accessibility Inspector's contrast audit over the History list in light, dark, and with Increase Contrast on"
    expected: "Body text >= 4.5:1, large text >= 3:1 (CLAUDE.md Accessibility)"
    why_human: "Liquid Glass is translucent, so effective contrast depends on what is behind it and on appearance mode — it cannot be determined statically and 07-RESEARCH explicitly declined to assert a violation. No code change was made and none may be needed. Planner-declared `<human-check>` in 07-03-PLAN.md; tracked as WINDOWS.md #4."
  - truth: "The cached `sections` array stays consistent with the underlying data after an in-place `consumptionDate` edit (07-05 must-have: 'Day sections are recomputed when the fetch result changes')"
    test: "Seed >= 3 events spanning two days. With History foregrounded, open Edit on a middle-ranked event and change its date to another day WITHOUT changing its rank in the window's `consumptionDate`-descending order (e.g. Mon 10:00 / Sun 22:00 / Sun 08:00 → edit the Sun 22:00 event to Mon 09:00). Save and return to the list."
    expected: "The edited row moves to the correct day's section heading immediately, without backgrounding the app or crossing midnight"
    why_human: "CHARACTER CHANGED SINCE THE PRIOR PASS. The prior pass found no trigger could fire for this input — a positively-identified latent defect. The e866cf0 fix is now present and its mechanism was re-derived end to end (save() touches unconditionally; `[Date]` is value-Equatable; the old `[ConsumptionEvent]` key was identity-Equatable and provably could not fire). What remains is only that NO automated test exercises the runtime invariant: `HistoryListQueryView`'s refresh wiring is still untested (the passing `HistoryViewModelTests+DayRollover` tests call the pure `daySections(_:now:calendar:)` directly, as their own doc comment states), and the full suite is 705 tests before AND after the fix — no regression test was added. Disclosed as WINDOWS.md #9 (`kind: deviation`, open). This is now a CONFIRMATION check, not a bug hunt."
human_verification:
  - test: "With VoiceOver on (device preferred), focus a History row and swipe through the Actions rotor"
    expected: "Duplicate and Delete are announced; Delete presents the confirmation dialog"
    why_human: "XCUITest cannot drive the VoiceOver Actions rotor (C14-2, planner-declared human-check, WINDOWS.md #3)"
  - test: "Run Accessibility Inspector's contrast audit over the History list in light, dark, and Increase Contrast"
    expected: "Caption text meets 4.5:1 (body) / 3:1 (large text)"
    why_human: "Translucent glass makes effective contrast context-dependent; cannot be measured statically (C14-7, planner-declared human-check, WINDOWS.md #4)"
  - test: "Edit a middle-ranked History event's date to a different day without changing its sort rank, with the app foregrounded"
    expected: "The row moves to the correct day section immediately"
    why_human: "WR-01 — the fix is present and its mechanism is derivable as sound, but no automated test exercises the runtime invariant (WINDOWS.md #9). Confirmation of a fix, not an open defect."
  - test: "Open the Settings guideline picker and the onboarding guideline step in light mode, dark mode, and at AX5"
    expected: "Both render as Liquid Glass cards consistent with Settings/Dashboard/Insights; no clipping or contrast loss at AX5"
    why_human: "B9-3/D-05 visual conversion was never visually verified by the executor (planner-declared human-check in 07-04-PLAN.md, WINDOWS.md #6)"
  - test: "Launch History with every logged drink outside the initial 7-day window and watch the FIRST frame"
    expected: "A centered progress indicator, not a blank list, replaced by rows without an EndOfListFooter flicker"
    why_human: "The state self-heals in ~one render cycle, so a timing assertion would be flaky — the passing `test_allDataOutsideInitialWindow_recoversToRows` deliberately asserts recovery, not that the spinner was seen (planner-declared human-check in 07-05-PLAN.md, WINDOWS.md #8)"
---

# Phase 7: SwiftUI List Performance & Gesture Audit — Verification Report

**Phase Goal:** Every `blocker` and `worth-fixing` finding from the read-only List/gesture audit
(`07-RESEARCH.md`) is either fixed, or explicitly deferred with a stated rationale — no silent drops.

**ROADMAP contract (stricter wording):** "...is closed in code, each pinned by an automated
`xcodebuild test` case — the History row has one definition instead of two diverged copies,
destructive delete is confirmation-gated, rows carry stable identity and plain-data inputs, and
section building leaves the render path."

**Verified:** 2026-08-04T01:27:35Z (re-verification)
**Status:** human_needed
**Re-verification:** Yes — after the WR-01 fix (`e866cf0`) and its ledger disclosure (`d7ea411`)

---

## Re-Verification Scope

The prior pass (2026-08-04T00:45:52Z, `human_needed`, 17/20) reported **no gaps** but escalated one
item as the only real code defect rather than a human-judgment call: **WR-01**, the History
section-cache staleness bug. Two commits landed after that report:

| Commit | Time (UTC) | Subject |
|--------|-----------|---------|
| `e866cf0` | 2026-08-04T00:57:03Z | fix(07): key `HistoryListQueryView`'s section-cache refresh on `modifiedDate`, not `events` identity (WR-01) |
| `d7ea411` | 2026-08-04T00:57:47Z | docs(07): log WR-01 UI-test coverage gap in windows ledger |

Both post-date the prior VERIFICATION.md. Failed/escalated items got full re-verification; passing
items got a regression check (the full suite re-run below covers all of them).

### WR-01 fix — mechanism re-derived from source, not from the commit message

`HistoryListQueryView.swift:104` now reads:

```swift
.onChange(of: events.map(\.modifiedDate), initial: true) { _, _ in refreshSections() }
```

The single-line diff (`git show e866cf0`) confirms it replaced `.onChange(of: events, initial: true)`.
Four independent checks, each read from current source:

1. **Does every save bump `modifiedDate`?** Yes, unconditionally. `EditEventView.save()` assigns
   `event.consumptionDate = date` at `:238` and calls `event.touch()` at `:248` — straight-line code
   with no guard, no `if changed`, and no early return between them. `ConsumptionEvent.touch()`
   (`:114-116`) is `modifiedDate = .now`, also unconditional. The repro's edit therefore always
   changes `modifiedDate`.
2. **Is `[Date]` genuinely different from `[ConsumptionEvent]` for this repro?** Yes. `Date` is a
   value type whose `==` compares the underlying time interval, and `Array`'s `==` is element-wise,
   so the key changes whenever any element's `modifiedDate` changes — **independent of ordering**,
   which is exactly the property the repro needs. The old key was `[ConsumptionEvent]`;
   `grep -rn 'static func ==' drinkpulse/Domain/` returns **zero** custom overrides, so equality fell
   through to `@Model`'s synthesized `PersistentModel: Hashable` conformance — model identity. An
   in-place edit hands back the *same* instances in the *same* order, so the old array compared equal
   and the trigger provably could not fire. Old and new behaviour differ for precisely the described
   input.
3. **Bonus mechanism the fix adds for free.** `events.map(\.modifiedDate)` *reads* an `@Observable`
   property on each event **inside the parent view's body**, registering an Observation dependency the
   old code never had (the old body read no per-event property at this level — `daySections` ran only
   inside `refreshSections()`). The mutation now invalidates the view directly, independent of
   `@Query`'s own change notification.
4. **Second mutation site covered too.** `grep -rn '\.consumptionDate *='` finds exactly two
   production writers: `EditEventView.swift:238` (above) and `DataImporter.apply` at
   `DataImporter.swift:116`, which does not call `touch()` but explicitly writes
   `event.modifiedDate = record.modifiedDate ?? record.consumptionDate` at `:127` under LWW. Either
   way the `[Date]` key changes. *(Minor: the new in-code comment's phrasing "Every
   `ConsumptionEvent` mutator calls `touch()`" is imprecise — the importer assigns `modifiedDate`
   directly — but the conclusion it draws holds.)*

**Verdict on the mechanism: sound.** The fix closes the exact gap the prior pass identified. What it
does **not** come with is a regression test — see the next section.

### Judgement on the WINDOWS.md #9 disclosure

Entry 9 (`kind: deviation`, `status: open`, recorded 2026-08-04T00:57:30Z) states the fix "has no
dedicated UI-test regression proof", because a precise repro needs XCUITest to drive
`EditEventView`'s DatePicker and "this codebase has zero prior precedent for automating that specific
control -- attempting one blind risked a flaky or silently-wrong test."

**Honest?** Yes, and its factual claims check out independently:

- *"zero prior precedent"* — `grep -rn -i 'datePicker' drinkpulseUITests/` returns **0 hits**. The
  claim is literally true, not rhetorical.
- *"no dedicated UI-test regression proof"* — corroborated by arithmetic, not just assertion: the
  full suite is **705 tests before the fix and 705 after**. No test was added, and none was claimed.
- The stated reasoning matches this project's own documented precedent for rejecting flaky
  assertions (the B10-1 "assert recovery, not that the spinner was seen" decision in DEVLOG and
  07-05-SUMMARY) rather than being an ad-hoc excuse.
- It reached the one ledger the ship gate reads. `/gsd-ship` blocks while `open_count > 0`, so the
  gap cannot ship silently — which is the phase goal's own standard ("no silent drops").

**Sufficient to not block phase completion?** Yes, on balance:

- WR-01 is a `warning`-severity code-review finding, not one of the phase's two `blocker` findings.
- The missing artifact is a *regression test*, not the *fix*; the fix itself is verifiable by
  inspection (above) and the History screen already carries 4 UI-test classes.
- The phase goal is "fixed, or explicitly deferred with a stated rationale — no silent drops". A
  disclosed, ledger-tracked test gap satisfies that standard by construction.

**But it is a real, owed follow-up, not a free pass.** CLAUDE.md's testing rules say plainly:
"**Bug fix**: write a failing test that reproduces the bug first, then fix it." That was not done
here. The deviation is disclosed rather than hidden, which is the right handling — but the debt is
real and entry 9 should stay `open` (not be waived) until either a DatePicker-driving UI test exists
or the owner explicitly waives it with a reason.

**One inaccuracy in entry 9's wording.** It claims the fix "is shipped and verified against the full
705-test regression suite". The timeline does not support that as written: `e866cf0` was committed at
00:57:03Z and the ledger entry written at 00:57:30Z — **27 seconds later**, against a suite that
takes ~22 minutes. The run may have happened on the working tree before committing, but no artifact
records it (the DEVLOG's phase-close entry predates the fix and mentions neither CR-01 nor WR-01, and
no SUMMARY was updated). **That claim is now substantiated by this verification's own full-suite
re-run at HEAD** — but it was unsubstantiated when written. Logged as W-8 below.

---

## Must-Have Derivation

07-RESEARCH.md's finding index was enumerated directly from the source document rather than taken
from any SUMMARY:

```
grep -oE "^#### [A-Z0-9-]+ · \`?[a-zA-Z/ -]+" 07-RESEARCH.md
```

That yields **36 findings**: 2 `blocker`, 13 explicitly-labelled `worth-fixing`, plus C14-7
("manual verification required"), which the report's own Findings Summary table counts inside the
C-group's 5 worth-fixing items (5 = C14-1..C14-4 + C14-7, giving the stated total of 14). ROADMAP.md
independently lists C14-7 under worth-fixing. **The goal therefore covers 16 items: A1-1, C13-1
(blockers) and A3-1, A4-1, A4-2, A6-1, A7-1, A7-2, B8-1, B9-1, B10-1, C14-1, C14-2, C14-3, C14-4,
C14-7 (worth-fixing).**

The task brief listed 11 requirement IDs and flagged itself non-exhaustive. Cross-checking against
07-RESEARCH added five it omitted: **A3-1, C14-2, C14-3, C14-4, C14-7**. All five are accounted for
below.

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | **A1-1** (blocker) — every History row keys `ForEach` by a stable identity | ✓ VERIFIED | `HistoryDaySectionCard.swift:31` and `HistoryCalendarDayDetail.swift:65` both read `ForEach(events, id: \.uuid)`. Zero `\.element.id` / `PersistentIdentifier` keying remains in `Features/History/`. Pinned by `DuplicateEditPersistenceUITests.test_duplicate_keepsOriginalRowIdentity` and `test_editFreshDuplicate_survivesPastAutosaveWindow` — both re-run and passed at HEAD |
| 2 | **C13-1** (blocker) — context-menu Delete is confirmation-gated | ✓ VERIFIED | `EventContextMenu.swift:53-57` — the destructive menu button only sets `isPresentingDeleteConfirmation`; `:75-88` `confirmationDialog`; `performDelete()` is `private` and reachable only from the dialog's destructive button. Pinned by 3 passing `ContextMenuDeleteConfirmationUITests`, re-run at HEAD |
| 3 | **A3-1** — `#Index` on `consumptionDate` | ✓ VERIFIED (explicit deferral) | Owner decision D-04 = `schedule`, with a stated schema-safety rationale in 5 places (ROADMAP:69, 07-01-PLAN:141-155, 07-01-SUMMARY, 07-05-SUMMARY roll-up #11, current-focus.md #3, DEVLOG). Verified in code: `grep -rn "#Index" drinkpulse/Domain/` → 0 hits; `SchemaV4` still current; `git diff 3bb5836..HEAD -- drinkpulse/Domain/` shows exactly one file, the additive `GuidelineChoice+Selectable.swift`. No `VersionedSchema` was amended |
| 4 | **A4-1** — row strings computed once, not twice per body pass | ✓ VERIFIED | `EventRowStrings.swift:19-50` derives name/volume/ABV/time/mass once and reuses the same locals for both `subtitle` and `accessibilityLabel`; `EventRow.swift:22-28` builds it in `init`, not in `body`. Pinned by 6 passing `EventRowStringsTests` |
| 5 | **A4-2** — no date formatting during a body pass | ✓ VERIFIED | `DaySection` (`HistoryViewModel.swift:17-21`) stores `title` as data; `sectionTitle(for:todayStart:yesterdayStart:)` runs only inside `daySections(_:now:calendar:)`, which runs only from `refreshSections()` |
| 6 | **A6-1** — rows take plain values, never the observable `UserProfile` | ✓ VERIFIED | `RowUnitContext` is a `struct: Equatable, Sendable` holding 3 enums; resolved once per list at `HistoryListQueryView.swift:41` and `HistoryCalendarView.swift:16`, passed down as a value. `EventRow`/`EventRowButton`/`HistoryDaySectionCard`/`HistoryCalendarDayDetail` hold no `UserProfile`. Pinned by 3 passing `RowUnitContextTests` |
| 7 | **A7-1** — the History row has one definition, not two diverged copies | ✓ VERIFIED | `EventRowButton.swift` is the sole definition; constructed by `HistoryDaySectionCard.swift:32` **and** `HistoryCalendarDayDetail.swift:66`. The previously-diverged 10pt padding now lives once, inside the shared component |
| 8 | **A7-2** — the guideline row has one definition | ✓ VERIFIED | `GuidelineChoiceRow.swift` constructed by `GuidelinePickerSheet.swift:26` **and** `GuidelineStep.swift:35`. `GuidelineChoice.selectable` is the single pickable-list source; neither screen hard-codes a list |
| 9 | **B8-1** — section building leaves the render path | ✓ VERIFIED | `groupedByDay` is gone repo-wide (0 hits). `sections` is `@State` (`HistoryListQueryView.swift:11`), refreshed via `refreshSections()` from three triggers (`:104-110`). Pinned by 2 passing `HistoryViewModelTests+DayRollover` tests + the existing `HistoryViewModelTests` suite (37 cases, re-run at HEAD). *(Cache-consistency edge case: see truth 20)* |
| 10 | **B9-1** — shared row chrome instead of a repeated modifier triple | ✓ VERIFIED | `historyListRowChrome(insets:)` (`HistoryListQueryView.swift:204-212`) with 4 call sites (`:65`, `:77`, `:82`, `:85`) |
| 11 | **B10-1** — empty-window-with-more shows a labelled loading state | ✓ VERIFIED | `HistoryListQueryView.swift:73-79` — a separate `if events.isEmpty && hasMore`, deliberately NOT an `else if` (which would displace `LoadMoreSentinel`); `history.list.loadingOlder` key present. Pinned by `test_allDataOutsideInitialWindow_recoversToRows`, A/B-proven per 07-05-SUMMARY. Fixture `UITestSeed.seedOutsideWindowEvents` + `-dp_uitest_dataset outsidewindow` verified wired |
| 12 | **C14-1** — the row's padded band is hittable | ✓ VERIFIED | `EventRowButton.swift:34-42` — `.padding(.vertical, 10)` applied to the label **before** `.contentShape(Rectangle())`. Pinned by `test_rowTopEdge_isTappable_opensEditor` and `test_rowHitTarget_meetsMinimumHeight`, both re-run and passed at HEAD |
| 13 | **C14-2** — VoiceOver exposes Duplicate and Delete without a long-press | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Code present and correctly wired: `EventContextMenu.swift:67-74` `.accessibilityActions` lives on the same modifier as the context menu, so its Delete arms the identical `isPresentingDeleteConfirmation` flag — the two paths structurally cannot drift. But the *announcement* is unobservable to any automated test (`grep -rln "accessibilityActions" drinkpulseUITests/` → 0). **Planner-declared `<human-check>`** in 07-03-PLAN.md, WINDOWS #3 — an intended deferral, not a verification failure |
| 14 | **C14-3** — the row survives AX5 | ✓ VERIFIED | `EventRow.swift:35-39` `AnyLayout` swap (erases a *layout*, preserving subview identity) + `@ScaledMetric iconWidth`; `EventRowButton.swift:22` `@ScaledMetric dividerInset`. Pinned by `test_row_growsAndStaysHittable_atAX5`, which asserts growth-vs-baseline as an explicit precondition so it cannot pass vacuously |
| 15 | **C14-4** — the selected guideline carries the `.isSelected` trait | ✓ VERIFIED | `GuidelineChoiceRow.swift:53` `.accessibilityAddTraits(isSelected ? .isSelected : [])`, with the glyph `.accessibilityHidden(true)` at `:36`. Pinned by 3 passing `GuidelinePickerUITests`, incl. positive **and** negative trait assertions |
| 16 | **C14-7** — caption contrast over glass | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Deliberately no code change (07-RESEARCH asserted no violation, only that it is unmeasured). The manual audit was **not performed**. **Planner-declared `<human-check>`** in 07-03-PLAN.md with a stated remedy path ("an explicit color token, not a font-size change"), tracked in WINDOWS #4 + open-questions.md — an intended deferral, not a silent drop |
| 17 | **No silent drops** — every one of the 36 findings has a stated disposition | ✓ VERIFIED | All 13 nits closed except A6-3, whose own research text instructs "Note it; do not act on it" — recorded, correctly not acted on. L1 filed under "Later (needs iOS 27)" and carried as the documented `TODO(iOS 27)` at `HistoryListQueryView.swift:111-117`. X1/X2/X3 flagged out of scope per CONTEXT `<deferred>`. Compliant/N-A findings (A5-1, A6-4, A7-3, B9-4, B10-2, C12-0, C13-2) needed no change and got none. **Extended this pass:** the post-review findings also all have dispositions — CR-01 fixed, WR-01 fixed + disclosed, WR-02/WR-03 open (see W-3/W-4) |
| 18 | **Quality gates** — clean build, green suite | ✓ VERIFIED | **Re-run at HEAD (`d7ea411`), after both post-review fixes:** `** TEST SUCCEEDED **`, **705 passed / 0 failed / 0 skipped** (612 Swift Testing in 46 suites + 93 XCTest UI), confirmed from the `.xcresult` summary, not from console text alone. Zero `warning:` lines in the run log. A prior scoped run over the 4 History-critical classes (`HistoryViewModelTests`, `HistoryInteractionUITests`, `DuplicateEditPersistenceUITests`, `EditVolumeIntegrityUITests`) also passed 55/55 |
| 19 | **CLAUDE.md compliance** | ✓ VERIFIED | No repository layer introduced (view holds the cache; `HistoryViewModel` stays stateless w.r.t. persistence, per ADR-0004). `@Observable` only. No `print` in production. No `try?` swallow left in `EventContextMenu.swift` (CR-01 fix confirmed in place at `:111-115` and `:128-135`, both `do/try/catch` with `os.Logger.error`; the delete-side catch carries its explanatory comment). No force-unwrap or `try!` outside `#Preview`. No production file over 300 lines. New user-facing copy routed through `String(localized:)`. *(One standing exception: WR-02, see W-3.)* |
| 20 | **The `sections` cache stays consistent with the data after an in-place date edit** (07-05 must-have) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | **Materially improved, still not behaviourally proven.** The fix is in place (`:104`, `e866cf0`) and its mechanism was independently re-derived from source, not taken from the commit message — see "WR-01 fix — mechanism re-derived" above: `save()` touches unconditionally, `touch()` is unconditional, `[Date]` is value-Equatable (order-independent), and the old `[ConsumptionEvent]` key was identity-Equatable with no custom `==` anywhere, so it provably could not fire. **But** no automated test exercises `HistoryListQueryView`'s refresh wiring — the rollover tests call the pure function directly (their own doc comment says so), and the suite is 705 tests before *and* after the fix. Disclosed as WINDOWS #9. Status held per this report's rule that a state-transition invariant needs a passing behavioural test, not a derivation — but it is now a **confirmation** check, not a suspected defect |

**Score:** 17/20 truths verified (3 present, behavior-unverified) — unchanged from the prior pass in
number, changed in character: truth 20 moved from "inspection says the invariant is broken" to
"inspection says the invariant holds; runtime unexercised".

### Deferred Items

| # | Item | Addressed In | Evidence |
|---|------|-------------|----------|
| 1 | A3-1 — `#Index` on `ConsumptionEvent.consumptionDate` | Own follow-up phase (D-04 = `schedule`) | Rationale stated in 6 documents; schema demonstrably untouched. **Note:** no such phase yet exists in ROADMAP.md and there is no `.planning/BACKLOG.md` — the deferral is explicit but the "schedule" half is not yet materialised (see W-5) |
| 2 | L1 — per-event swipe-to-delete | "Later (needs iOS 27)" | 07-RESEARCH's Later section + `TODO(iOS 27)` at `HistoryListQueryView.swift:111-117`, with the FB11280425 rationale for why the workaround is a regression, not a fix |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `drinkpulse/Features/History/HistoryListQueryView.swift` | Section cache + **WR-01-safe refresh trigger** | ✓ VERIFIED | 213 lines; `:104` keys `.onChange` on `events.map(\.modifiedDate)` with a 9-line comment stating the mechanism and why the identity key failed |
| `drinkpulse/Features/History/Components/EventRowButton.swift` | Single row definition (A7-1) | ✓ VERIFIED | 75 lines; 2 production call sites |
| `drinkpulse/Features/History/Components/EventRowStrings.swift` | One-pass row strings (A4-1) | ✓ VERIFIED | 52 lines; consumed by `EventRow.init` |
| `drinkpulse/Features/History/Components/RowUnitContext.swift` | POD unit context (A6-1) | ✓ VERIFIED | 40 lines; resolved at 2 list roots |
| `drinkpulse/Features/History/Components/EventContextMenu.swift` | `EventContextMenuModifier` + confirmation (C13-1) + **CR-01 fix** | ✓ VERIFIED | 161 lines; `@State` flag, dialog, `.accessibilityActions`, two `do/try/catch` + `os.Logger.error` |
| `drinkpulse/Features/Settings/Components/GuidelineChoiceRow.swift` | Shared guideline row (A7-2, C14-4) | ✓ VERIFIED | 66 lines; 2 production call sites |
| `drinkpulse/Domain/GuidelineChoice+Selectable.swift` | Single pickable-list source (A1-2) | ✓ VERIFIED | 20 lines; `static let`, not a computed property |
| `DaySection` + `daySections(_:now:calendar:)` in `HistoryViewModel.swift` | Pure, clock-injectable (B8-1) | ✓ VERIFIED | `:17-21`, `:83-109` |
| `UITestSeed.seedOutsideWindowEvents(into:)` + `outsidewindow` flag | B10-1 fixture | ✓ VERIFIED | `UITestSeed+Fixtures.swift:150`, `UITestSeed.swift:168, 244` |
| `ContextMenuDeleteConfirmationUITests.swift` | C13-1 | ✓ VERIFIED | 3 tests, all passed at HEAD |
| `HistoryDynamicTypeUITests.swift` | C14-3 | ✓ VERIFIED | 1 test, passed at HEAD |
| `HistoryInteractionUITests+HitTarget.swift` | C14-1 | ✓ VERIFIED | 2 tests, passed at HEAD |
| `HistoryInteractionUITests+LoadingState.swift` | B10-1 | ✓ VERIFIED | 1 test, passed at HEAD |
| `GuidelinePickerUITests.swift` | C14-4, B9-3 | ✓ VERIFIED | 3 tests, passed at HEAD |
| `EventRowStringsTests.swift` / `RowUnitContextTests.swift` / `HistoryViewModelTests+DayRollover.swift` / `GuidelineChoiceDisplayTests.swift` | A4-1 / A6-1 / B8-1+A4-2 / A7-2+A1-2 | ✓ VERIFIED | 6 / 3 / 2 / 16 tests, all suites passed at HEAD |
| *A WR-01 regression test* | Repro: in-place date edit, unchanged sort rank | ✗ **ABSENT — disclosed** | No test file exists and the suite count is unchanged at 705. Deliberate and logged as WINDOWS #9 (`kind: deviation`, open), with the DatePicker-precedent rationale independently confirmed (`grep -i datePicker drinkpulseUITests/` → 0 hits). Does not block (see judgement above); the debt is owed |
| String Catalog keys | 5 new keys | ✓ VERIFIED | `history.row.deleteConfirm.title`, `.message`, `history.row.hasNote`, `history.row.editHint`, `history.list.loadingOlder` — all present in `Localizable.xcstrings` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `HistoryDaySectionCard` | `EventRowButton` | direct construction | ✓ WIRED | `:32-39`, passing `unitContext` and `isLast` |
| `HistoryCalendarDayDetail` | `EventRowButton` | direct construction | ✓ WIRED | `:66-73` — the previously-diverged copy now shares the definition |
| `EventRowButton` | `EventContextMenuModifier` | `.eventContextMenu(for:in:healthService:reduceMotion:)` | ✓ WIRED | `:46-47` |
| Context-menu Delete | `performDelete()` | `isPresentingDeleteConfirmation` → dialog → destructive button | ✓ WIRED | Menu button `:53-57` sets flag only; `performDelete()` is `private`, called only from the dialog |
| VoiceOver Delete action | same confirmation flag | `.accessibilityActions` on the same modifier | ✓ WIRED | `:71-73` sets the identical flag — the two paths cannot diverge |
| `EditEventView.save()` | `HistoryListQueryView.refreshSections()` | `event.touch()` → `modifiedDate` → `.onChange(of: events.map(\.modifiedDate))` | ✓ **WIRED (was ⚠️ PARTIAL)** | `EditEventView.swift:248` → `ConsumptionEvent.swift:114-116` → `HistoryListQueryView.swift:104`. The chain is unconditional at every hop and the key is order-independent — the WR-01 hole is closed. Runtime confirmation still routed to human verification |
| `DataImporter.apply` | same refresh path | `event.modifiedDate = record.modifiedDate ?? record.consumptionDate` | ✓ WIRED | `DataImporter.swift:116, 127` — the second `consumptionDate` writer also moves the key, via explicit LWW assignment rather than `touch()` |
| `HistoryListQueryView` | `refreshSections()` | 3 triggers: `modifiedDate` key change, `scenePhase == .active`, `.NSCalendarDayChanged` | ✓ WIRED | `:104-110`, all routed through one method |
| `GuidelinePickerSheet` / `GuidelineStep` | `GuidelineChoiceRow` | direct construction | ✓ WIRED | `:26-33` / `:35-42` |
| Both guideline screens | `GuidelineChoice.selectable` | `ForEach(GuidelineChoice.selectable, ...)` | ✓ WIRED | `:18` / `:28` — no hard-coded parallel list |
| `EventRow` | `EventRowStrings` | built in `init` | ✓ WIRED | `:27` |
| `HistoryListQueryView` / `HistoryCalendarView` | `RowUnitContext` | resolved once, passed as value | ✓ WIRED | `:41` / `:16` |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `HistoryListQueryView` | `sections` | `vm.daySections(events)` ← `@Query` `#Predicate consumptionDate >= windowStart` | Yes — real SwiftData fetch, no static fallback | ✓ FLOWING |
| `HistoryListQueryView` | `.onChange` key | `events.map(\.modifiedDate)` — live model property reads, not a snapshot | Yes; also registers Observation on each event | ✓ FLOWING |
| `HistoryDaySectionCard` | `events` | `section.events` from the cache above | Yes | ✓ FLOWING |
| `EventRow` | `strings` | `EventRowStrings(event:unitContext:)` over live model fields | Yes | ✓ FLOWING |
| `EventRowButton` | `unitContext` | `RowUnitContext(profile)` ← `@Query` `UserProfile` (`fetchLimit = 1`) | Yes; `nil`-profile fallbacks are documented defaults, unit-tested, not stubs | ✓ FLOWING |
| `GuidelinePickerSheet` / `GuidelineStep` | `GuidelineChoice.selectable` | `allCases.filter { $0 != .custom }` | Yes — in-memory enum by design | ✓ FLOWING |

No hollow props found in the changed tree.

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| WR-01 fix is actually in the file at HEAD | `git show e866cf0 -- HistoryListQueryView.swift`; read current source | Single-line change confirmed: `.onChange(of: events, initial: true)` → `.onChange(of: events.map(\.modifiedDate), initial: true)` at `:104` | ✓ PASS |
| `save()` bumps `modifiedDate` unconditionally | read `EditEventView.swift:230-252`, `ConsumptionEvent.swift:114-116` | `consumptionDate` assigned `:238`, `touch()` called `:248`, no guard between; `touch()` is `modifiedDate = .now` | ✓ PASS |
| No custom `==` making the old key value-comparing | `grep -rn 'static func == ' drinkpulse/Domain/` | 0 hits — old key was identity-Equatable, so the old trigger provably could not fire for the repro | ✓ PASS |
| Every `consumptionDate` writer moves the key | `grep -rn '\.consumptionDate *=' drinkpulse/` | 2 sites: `EditEventView:238` (→`touch()`), `DataImporter:116` (→explicit `modifiedDate` write `:127`) | ✓ PASS |
| Scoped History regression (4 named classes) | `xcodebuild test -only-testing:{HistoryViewModelTests, HistoryInteractionUITests, DuplicateEditPersistenceUITests, EditVolumeIntegrityUITests}` | `** TEST SUCCEEDED **` — 55 passed, 0 failed (`.xcresult` summary) | ✓ PASS |
| Full suite at HEAD, post-CR-01 and post-WR-01 | `xcodebuild test -scheme drinkpulse -destination '...iPhone 17 Pro'` (run **once**) | `** TEST SUCCEEDED **` — **705 passed, 0 failed, 0 skipped**; 612 Swift Testing in 46 suites + 93 XCTest UI | ✓ PASS |
| No test was added for WR-01 (disclosure cross-check) | compare suite totals pre-fix vs post-fix | 705 → 705 — corroborates WINDOWS #9's "no dedicated UI-test regression proof" | ✓ PASS (disclosure honest) |
| DatePicker-precedent claim in WINDOWS #9 | `grep -rn -i 'datePicker' drinkpulseUITests/` | 0 hits — claim is literally true | ✓ PASS |
| A3-1 deferral is still real | `grep -rn "#Index" drinkpulse/Domain/`; `git diff 3bb5836..HEAD -- drinkpulse/Domain/` | 0 `#Index` hits; only `GuidelineChoice+Selectable.swift` changed; `SchemaV4` intact | ✓ PASS |
| WR-01 runtime repro | — | Not automatable without DatePicker automation | ? SKIP → human |
| C14-2 VoiceOver rotor | — | Not automatable | ? SKIP → human |
| C14-7 contrast | — | Not automatable | ? SKIP → human |

### Probe Execution

No `scripts/*/tests/probe-*.sh` exist in this repo and no plan declares a probe. **SKIPPED (no probes
declared or discoverable).** The project's equivalent gate is `xcodebuild test`, executed above.

### Requirements Coverage

| Requirement | Source Plan | Severity | Status | Evidence |
|-------------|-------------|----------|--------|----------|
| A1-1 | 07-01 | blocker | ✓ SATISFIED | Truth 1 |
| C13-1 | 07-01 | blocker | ✓ SATISFIED | Truth 2 |
| A3-1 | *(none — excluded)* | worth-fixing | ✓ DEFERRED (D-04, rationale stated) | Truth 3 |
| A4-1 | 07-02, 07-03 | worth-fixing | ✓ SATISFIED | Truth 4 |
| A4-2 | 07-02, 07-05 | worth-fixing | ✓ SATISFIED | Truth 5 |
| A6-1 | 07-02, 07-03 | worth-fixing | ✓ SATISFIED | Truth 6 |
| A7-1 | 07-03 | worth-fixing | ✓ SATISFIED | Truth 7 |
| A7-2 | 07-04 | worth-fixing | ✓ SATISFIED | Truth 8 |
| B8-1 | 07-02, 07-05 | worth-fixing | ✓ SATISFIED | Truth 9; the cache-staleness regression it introduced (WR-01) is fixed at `e866cf0` — see truth 20 |
| B9-1 | 07-05 | worth-fixing | ✓ SATISFIED | Truth 10 |
| B10-1 | 07-05 | worth-fixing | ✓ SATISFIED | Truth 11 |
| C14-1 | 07-03 | worth-fixing | ✓ SATISFIED | Truth 12 |
| C14-2 | 07-03 | worth-fixing | ? NEEDS HUMAN (planned) | Truth 13 |
| C14-3 | 07-03 | worth-fixing | ✓ SATISFIED | Truth 14 |
| C14-4 | 07-04 | worth-fixing | ✓ SATISFIED | Truth 15 |
| C14-7 | 07-03 | worth-fixing (manual) | ? NEEDS HUMAN (planned) | Truth 16 |
| CR-01 | *(07-REVIEW)* | critical | ✓ SATISFIED | `5b86cd2`; confirmed in code at `EventContextMenu.swift:111-115, 128-135` |
| WR-01 | *(07-REVIEW)* | warning | ✓ SATISFIED (fix) + ⚠️ test gap disclosed | `e866cf0`; mechanism re-derived; WINDOWS #9 |
| WR-02 | *(07-REVIEW)* | warning | ✗ OPEN | `EventRowStrings.swift:36` still untranslated — see W-3 |
| WR-03 | *(07-REVIEW)* | warning | ✗ OPEN | `HistoryCalendarView.swift:18-19` still `return 20` unnamed — see W-4 |
| A1-2, A1-3, A2-1, A3-2, A4-3, A6-2, B8-2, B9-2, B9-3, C12-1, C14-5, C14-6 | 07-02..07-05 | nit | ✓ SATISFIED | Verified in code: `selectable` single source; `id: \.uuid`; explicit terminal `EmptyView()`; `profileDescriptor.fetchLimit = 1`; `EventRow` is plain-data; zero `.id(` calls in `Features/History/`; per-group re-sort dropped with the precondition documented; `.listStyle` divergence removed; glass-card conversion landed; duplicate row hierarchy gone; note announced via `history.row.hasNote`; `.accessibilityHint` on the row button |
| A6-3 | *(none)* | nit | ✓ SATISFIED (no action, as specified) | 07-RESEARCH's own text: "Note it; do not act on it." |
| L1 | *(none)* | Later (iOS 27) | ✓ DEFERRED | `TODO(iOS 27)` at `HistoryListQueryView.swift:111-117` with the FB11280425 rationale |
| D-01..D-05 | 07-01 | owner decisions | ✓ SATISFIED | All five honored in code |

**No orphaned requirements.**

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `drinkpulse/Features/History/HistoryListQueryView.swift` | 111 | `TODO(iOS 27)` | ℹ️ Info | Pre-existing; documents the formally-deferred L1 finding with its rationale and evidence trail. Not an unreferenced debt marker |
| `drinkpulse/Features/History/HistoryView.swift` | 241 | `os.Logger` with `privacy: .public` | ℹ️ Info | `#if DEBUG`-gated, pre-existing (commit `98031df`, before this phase), logs the pagination window boundary — derived UI state, not health data. Tracked under plan-0038 |
| `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` | — | 312 lines (over the 300 ceiling) | ℹ️ Info | Pre-existing, tracked as WINDOWS #2. This phase's edit **reduced** it |
| `drinkpulseUITests/.../DuplicateEditPersistenceUITests.swift` | 87 | `Thread.sleep(forTimeInterval: 10)` | ℹ️ Info | 07-REVIEW IN-01; documented as empirical, no better hook available. Test passed |
| `drinkpulse/Features/Insights/InsightsView.swift` | 28 | `.onChange(of: allEvents, initial: true)` — the same identity-keyed array pattern WR-01 was | ℹ️ Info (**out of phase scope**) | Newly noticed while tracing WR-01. Last touched 2026-07-31 (`d863b17`), so **pre-existing and untouched by phase 7** — InsightsView is not in 07-RESEARCH's audit scope. Lower risk than the History case because `vm.events` holds live references rather than a derived snapshot, so its computed aggregates re-read live fields. Flagged for a future Insights audit, **not a phase-7 gap** |

**Zero** `TBD`/`FIXME`/`XXX` markers in any file this phase touched. **Zero** `print` in production.
**Zero** force-unwraps or `try!` outside `#Preview`. **Zero** production files over 300 lines.
**Zero** `AnyView`. **Zero** empty `catch`.

### Warnings (non-blocking, human decision requested)

**W-1 — ledger coverage of the review warnings is now partial, not absent (improved).**
CR-01 fixed (`5b86cd2`) and confirmed in code. WR-01 fixed (`e866cf0`) **and** now entered in
`.planning/WINDOWS.md` as entry 9, so the ship gate can see it. **WR-02 and WR-03 remain unfixed and
still appear only inside `07-REVIEW.md`** — not in WINDOWS.md, not in open-questions.md, not in the
DEVLOG. Recommend entering both before shipping, or explicitly accepting them.

**W-2 — WR-01 is fixed; only its regression test is missing.** *(Was: "a correctness regression with
no trigger".)* See truth 20 and the mechanism derivation. The remaining exposure is that this
particular refresh path has no automated coverage at all, so a future refactor of the `.onChange` key
would reintroduce the bug silently. That is precisely what a regression test would prevent, and it is
the substance of the owed follow-up.

**W-3 — WR-02: `EventRowStrings.accessibilityLabel` embeds untranslated English. STILL OPEN.**
`EventRowStrings.swift:36` — `"%@, %@, %.1f percent ABV, %@ %@, logged at %@"` puts "percent ABV" and
"logged at" outside `String(localized:)`, against CLAUDE.md's "all user-facing strings" rule. Re-read
at HEAD: unchanged. Zero user impact today (English-only app); it would silently miss the catalog on
localisation.

**W-4 — WR-03: undocumented magic number. STILL OPEN.**
`HistoryCalendarView.swift:18-19` — `guard let p = profile else { return 20 }`, unnamed and
uncommented. Re-read at HEAD: unchanged.

**W-5 — A3-1's "schedule" disposition still has no scheduled artifact.**
D-04 = `schedule` (not `defer`), but ROADMAP.md contains no follow-up phase and the repo has no
`.planning/BACKLOG.md`. The phase goal ("explicitly deferred with a stated rationale") is met — the
follow-up exists only as prose. Same for the Domain-coverage follow-up (WINDOWS #7).

**W-6 — human-check bookkeeping is inconsistent across documents.**
`WINDOWS.md` holds four open `unrun-verify` items for this phase (#3 C14-2, #4 C14-7, #6 B9-3,
#8 B10-1) plus the new #9, but `open-questions.md`, `current-focus.md` and the DEVLOG each describe
only two ("two unperformed human-checks"). The ledger is the more complete record; the narrative docs
under-report. All are surfaced in this report.

**W-7 — `.planning/STATE.md` and ROADMAP checkboxes are stale.**
Uncommitted working tree still shows phase-in-progress bookkeeping while all five plans are complete
and committed. Orchestrator bookkeeping, not phase work.

**W-8 — WINDOWS #9's "verified against the full 705-test regression suite" was unsubstantiated when
written.** The fix commit landed at 00:57:03Z and the ledger entry 27 seconds later at 00:57:30Z,
against a suite that takes ~22 minutes; no DEVLOG entry or SUMMARY records a run in between. The
claim is **now true** — this verification re-ran the full suite at HEAD and got 705/705 — but the
ledger asserted it ahead of its evidence. Also note that **neither CR-01 nor WR-01 has a DEVLOG
entry**: the latest DEVLOG entry is the phase-close one written before both fixes, and CLAUDE.md
requires an entry for non-trivial changes. Recommend appending one covering both.

### Human Verification Required

Five items. All five correspond to open `WINDOWS.md` entries (#3, #4, #9, #6, #8). **Four of the five
(C14-2, C14-7, B9-3, B10-1) are planner-declared `<human-check>` blocks** — verified this pass by
reading the `<verify><human-check>` elements in 07-03-PLAN.md (2), 07-04-PLAN.md (1) and
07-05-PLAN.md (1), each with a stated remedy path. They were always intended to be answered by a
human at a device and are **not** verification failures. Item 3 (WR-01) is the exception: it was not
planned, and it is the one whose character changed this pass — from confirming a suspected defect to
confirming a landed fix.

#### 1. VoiceOver Actions rotor (C14-2 — planner-declared, WINDOWS #3)

**Test:** With VoiceOver on (device preferred over simulator), focus a History row and swipe up/down
through the Actions rotor.
**Expected:** "Duplicate" and "Delete" are announced; activating Delete presents the confirmation
dialog rather than deleting immediately.
**Why human:** XCUITest cannot drive the VoiceOver Actions rotor. The explicit `.accessibilityActions`
are present and share the confirmation flag with the touch path, so the worst case is redundancy.
Also settles 07-RESEARCH Assumptions Log **A1**.

#### 2. Caption contrast over glass (C14-7 — planner-declared, WINDOWS #4)

**Test:** Run Accessibility Inspector's contrast audit over the History list in light mode, dark
mode, and with Increase Contrast enabled.
**Expected:** Body text >= 4.5:1, large text >= 3:1.
**Why human:** Liquid Glass is translucent; effective contrast depends on what is behind it and on
appearance mode. This is an **unmeasured value, not a known failure**. If it fails, the plan's stated
remedy is an explicit colour token, not a font-size change.

#### 3. Section cache after an in-place date edit (WR-01 — WINDOWS #9)

**Test:** Seed at least three events spanning two days, e.g. Mon 10:00, Sun 22:00, Sun 08:00. With
History foregrounded, edit the Sun 22:00 event's date to Mon 09:00 — a change that moves it to a
different day **without** changing its rank in the descending sort. Save and return to the list.
**Expected:** The row appears under the Monday heading immediately.
**Why human:** No automated test exercises `HistoryListQueryView`'s refresh wiring, and this codebase
has no XCUITest precedent for driving a DatePicker (0 `datePicker` references in `drinkpulseUITests/`).
**This is now a confirmation, not a bug hunt** — the fix is in place at `:104` and its mechanism was
re-derived end to end this pass. If the row does move correctly, WR-01 can be marked fixed in the
ledger; if it does not, the mechanism derivation is wrong and this reopens as a real defect.

#### 4. Guideline glass cards, light/dark/AX5 (B9-3 / D-05 — planner-declared, WINDOWS #6)

**Test:** Open the Settings guideline picker and the onboarding guideline step in light mode, dark
mode, and at AX5.
**Expected:** Both render as Liquid Glass cards consistent with Settings/Dashboard/Insights/History;
no clipping, no contrast loss, all six guidelines reachable.
**Why human:** Visual conversion; the automated test proves structure, hit target and selection, not
appearance. `test_guidelinePicker_rendersEveryChoiceAsCardRow_andSelectionStillWorks` deliberately
never scrolls (the `.medium` detent makes a swipe drag the sheet).

#### 5. Empty-window loading first frame (B10-1 — planner-declared, WINDOWS #8)

**Test:** Launch with every logged drink outside the initial 7-day window
(`-dp_uitest_dataset outsidewindow`) and watch the **first** frame of History.
**Expected:** A centred progress indicator, not a blank list, replaced by rows without an
`EndOfListFooter` flicker.
**Why human:** The state self-heals in roughly one render cycle, so a timing assertion would be
flaky — an explicitly chosen, documented trade-off.

### Gaps Summary

**No gaps.** The one item the prior pass escalated as a real code defect — **WR-01** — is closed.
The fix was verified by reading the current source and re-deriving the mechanism from three
independent angles (unconditional `touch()` on save; `[Date]`'s order-independent value-Equatable
semantics; the absence of any custom `==` that could have made the old identity key behave otherwise),
not by trusting the commit message. Both post-review commits are green under a full 705-test suite
re-run at HEAD.

What remains open is a **test-coverage debt, honestly disclosed**, not a behavioural unknown created
by the phase:

- WINDOWS #9 discloses that the WR-01 fix ships without a dedicated regression test, and its stated
  reason (no DatePicker automation precedent in this codebase) is independently true. The suite count
  is unchanged at 705, so no false coverage was claimed. Judged **honest and sufficient — it does not
  block phase completion**, because the phase goal's standard is "fixed, or explicitly deferred with
  a stated rationale — no silent drops", and a ledger entry the ship gate blocks on is the opposite
  of a silent drop. The debt is nonetheless real (CLAUDE.md: "Bug fix: write a failing test that
  reproduces the bug first") and entry 9 should stay `open` until the test exists or the owner waives
  it with a reason.
- The four remaining human items (C14-2, C14-7, B9-3, B10-1) are **planner-declared `<human-check>`
  blocks**, confirmed this pass by reading the plans' own `<verify>` sections. Each has a stated
  remedy path. They are intended deferrals to a human at a device — re-confirming the prior read:
  **they do not block phase completion the way WR-01 did**, because none of them is an unplanned
  code-level defect. WR-01 was; it is now fixed.

**Status stays `human_needed`, not `passed`,** because five items require a human at a device, and
three of those leave a truth behaviourally unproven. The score is unchanged at **17/20** — but truth
20's character improved materially, from "code inspection says the invariant is broken" to "code
inspection says the invariant holds; the runtime confirmation is outstanding".

---

_Verified: 2026-08-04T01:27:35Z (re-verification of 2026-08-04T00:45:52Z)_
_Verifier: Claude (gsd-verifier)_
