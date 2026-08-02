---
phase: quick-260802-uia
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - drinkpulse/Features/History/HistoryViewModel.swift
  - drinkpulseTests/Features/History/HistoryViewModelTests.swift
  - docs/plans/0038-history-list-lazy-scrollview/execution.md
  - docs/DEVLOG.md
autonomous: true
requirements:
  - TODO-shrink-history-list-initial-fetch-window
user_setup: []

must_haves:
  truths:
    - "HistoryViewModel.listPageDays is 7, not 90 — both the initial @Query window for History's list and each 'load more' scroll-triggered page step move by 7 days."
    - "extendedWindowThenHasMore_eventuallyCoversEarliest (the only test with hardcoded day-math tied to the old 90-day constant) passes against the new 7-day constant deliberately, not by coincidence — its inline comments and numbers are updated to match."
    - "The existing LoadMoreSentinel/onAppear cascade in HistoryView.swift (extendListWindow()) is untouched — only the day-count constant driving it changed, no pagination logic changed."
    - "plan-0038's execution.md (docs/plans/0038-history-list-lazy-scrollview/execution.md) gains a new dated (2026-08-02) append-only entry documenting this change; plan.md itself is not edited (frozen since 2026-08-02)."
    - "docs/DEVLOG.md gains a new dated entry in the file's standard format."
  artifacts:
    - "drinkpulse/Features/History/HistoryViewModel.swift — `static let listPageDays = 7`"
    - "drinkpulseTests/Features/History/HistoryViewModelTests.swift — `extendedWindowThenHasMore_eventuallyCoversEarliest` updated to 7-day-scaled numbers/comments"
    - "docs/plans/0038-history-list-lazy-scrollview/execution.md — new 2026-08-02 entry appended below the existing one"
    - "docs/DEVLOG.md — new entry appended"
  key_links:
    - "listPageDays feeds both initialWindowStart(from:calendar:) (initial @Query fetch window) and extendedWindowStart(from:calendar:) (each load-more step) — this is a single shared constant, so changing it moves both together; no separate first-page-vs-subsequent-page constant is being introduced."
    - "HistoryListQueryView's @Query predicate is built from initialWindowStart's return value — shrinking the constant shrinks what SwiftData actually fetches from the store, distinct from and complementary to plan-0038's List→ScrollView+LazyVStack change (which only reduced what SwiftUI eagerly renders from an already-fetched window)."
---

<objective>
Cut `HistoryViewModel.listPageDays` from `90` to `7` (`drinkpulse/Features/History/HistoryViewModel.swift:15`),
shrinking the initial `@Query` window for History's list from 90 days of events to 7. This is a pure
constant change — the existing `LoadMoreSentinel`/`onAppear` cascade (`HistoryView.swift`'s
`extendListWindow()`, driven by the same `listPageDays`-derived `extendedWindowStart`) already
re-triggers repeatedly on `onAppear` until it fills the viewport, so no new pagination logic is needed.
That cascade is explicitly documented as legitimate, out-of-scope infinite-scroll behavior in
plan-0038's "Out" section — this task does not touch it.

Direct continuation of plan-0038 (`docs/plans/0038-history-list-lazy-scrollview/`, `Status: in-progress`,
`plan.md` frozen 2026-08-02). Per CLAUDE.md's plan-driven-development rules, `plan.md` stays frozen and
unedited; this task's outcome is recorded as a new dated entry appended to plan-0038's `execution.md`
(append-only) instead of a standalone untracked doc trail.

Purpose: plan-0038 fixed the render-side cost (`List`+`ForEach` eagerly building every row's body and
`.contextMenu` content for the whole loaded window; `ScrollView`+`LazyVStack` only builds rows near the
viewport). It did not touch the fetch-side cost — SwiftData's `@Query` was, and until this task remains,
still eagerly fetching a full 90-day window on first load regardless of how lazily it then renders. This
task shrinks what gets fetched, complementing (not overlapping) plan-0038's fix.

Output: `listPageDays = 7`, an updated pagination test with no stale 90/180/200/270-day math, a new
plan-0038 `execution.md` entry, and a `docs/DEVLOG.md` entry.
</objective>

<execution_context>
@/Users/fempter/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@./CLAUDE.md
@drinkpulse/Features/History/HistoryViewModel.swift
@drinkpulseTests/Features/History/HistoryViewModelTests.swift
@docs/plans/0038-history-list-lazy-scrollview/execution.md
@docs/plans/0038-history-list-lazy-scrollview/plan.md

# Key facts already verified during planning:
# - Neither `initialWindowStart`'s nor `extendedWindowStart`'s doc comment mentions "90" literally —
#   both reference `listPageDays` symbolically ("`listPageDays` before `now`" / "one page earlier than
#   `current`"). No doc-comment text edit is needed; still grep to confirm before declaring done, per the
#   task's own instruction not to assume.
# - `initialWindowStart_isOnePageBeforeNow`, `extendedWindowStart_movesBackOnePage`, and
#   `extendedWindowStart_repeatedCalls_keepMovingBack` (all in HistoryViewModelTests.swift) already
#   compute their `expected` values by referencing `HistoryViewModel.listPageDays` directly (e.g.
#   `gregorian().date(byAdding: .day, value: -HistoryViewModel.listPageDays, to: now)`) — they need NO
#   code change, they will automatically pass against the new constant.
# - The ONLY test with hardcoded literal day numbers tied to the old 90-day page size is
#   `extendedWindowThenHasMore_eventuallyCoversEarliest` (lines 211-223): it seeds `earliest` at -200
#   days and asserts the window needs 0, 1, then 2 `extendedWindowStart` calls to cover it (90 short,
#   180 short, 270 covers 200), with inline comments naming "90-day window", "180", "270", "200". This
#   is the one test this plan's Task 1 must rewrite with 7-day-scaled numbers.
# - Grepped `drinkpulseUITests/` for literal "90" and for "multiday"/"dp_uitest_dataset": no History UI
#   test hardcodes "90". Exactly one History UI test consumes the multi-day fixture —
#   `test_segmentSwitch_withManyEvents_endsInCorrectState` in `HistoryInteractionUITests+
#   DirectionalTransition.swift`, via `launchApp(dataset: "multiday")` — and it asserts ONLY on today's
#   (`daysAgo: 0`) seeded 500 ml beer row appearing in the List and Calendar; it never asserts that an
#   older (`daysAgo: 7/9/11/13`) event from `UITestSeed+Fixtures.swift`'s `multiDaySpecs` appears in the
#   initial List load without scrolling. `HistoryInteractionUITests.swift`'s header doc comment confirms
#   the *default* seed (used by every other History UI test) is a single "Today" 500 ml 5% beer. This
#   confirms the task brief's expectation that UI seed data is a non-issue — Task 1 still re-verifies
#   this by grep rather than trusting this note blindly.
# - `.claude/context/current-focus.md` currently describes plan-0038's status (steps 1-6/9-10 done, step
#   7 manual on-device verification still outstanding) and does not mention the 90-day constant anywhere
#   — no fact in it becomes wrong from this change. Leave it untouched (per the task brief, do not
#   rewrite it wholesale even if you double-check).
</context>

<tasks>

<task type="auto">
  <name>Task 1: Shrink listPageDays to 7 and fix the one test with hardcoded 90-day math</name>
  <files>drinkpulse/Features/History/HistoryViewModel.swift, drinkpulseTests/Features/History/HistoryViewModelTests.swift</files>
  <action>
    In `drinkpulse/Features/History/HistoryViewModel.swift`, change `static let listPageDays = 90` to
    `static let listPageDays = 7`. Grep the file for a literal `"90"` in the doc comments above
    `initialWindowStart`/`extendedWindowStart` to confirm neither needs a text edit (they reference
    `listPageDays` by name, not by literal number, per the planning note above) — do not skip this
    check, verify it directly rather than trusting the planning note alone.

    In `drinkpulseTests/Features/History/HistoryViewModelTests.swift`, rewrite
    `extendedWindowThenHasMore_eventuallyCoversEarliest` (currently seeding `earliest` at -200 days and
    asserting a 0/1/2-extension progression against a 90-day page) to use numbers scaled to the new
    7-day page, preserving the exact same test shape (seed an `earliest` date that needs the initial
    window plus two `extendedWindowStart` calls to reach, i.e. lands strictly between two and three
    page-widths back): use `earliest` at -20 days from `now`. First assertion (initial window, -7 days)
    must still see `hasMoreToLoad == true`. After one `extendedWindowStart` call (-14 days), still
    `true`. After a second call (-21 days), `false` (window now reaches past the 20-day-old event).
    Update every inline comment in this test that names a literal day count ("90-day window",
    "200-day-old", "180", "270", "200") to the new equivalents (7-day window, 20-day-old event, 14,
    21, 20) — do not leave stale numeric comment text describing the old page size next to the new
    assertions.

    Then grep `HistoryViewModelTests.swift` for any other literal `90`, `180`, `200`, or `270` tied to
    page-day math to confirm nothing else was missed (the other pagination tests —
    `initialWindowStart_isOnePageBeforeNow`, `extendedWindowStart_movesBackOnePage`,
    `extendedWindowStart_repeatedCalls_keepMovingBack` — already derive their expected values from
    `HistoryViewModel.listPageDays` symbolically and need no edit; confirm this by reading them, not by
    assuming).

    Finally, grep `drinkpulseUITests/Features/History/` for `"90"` and for `multiday`/
    `dp_uitest_dataset` to re-confirm no History UI test relies on an event dated further back than 7
    days appearing in the initial List load without a scroll/load-more step (the planning note above
    states this is already confirmed a non-issue — re-run the grep yourself to verify rather than
    trusting the note). If the grep surfaces anything unexpected, stop and flag it rather than silently
    reconciling it.
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/HistoryViewModelTests 2>&1 | tail -40</automated>
  </verify>
  <done>
    `HistoryViewModel.listPageDays == 7`. `extendedWindowThenHasMore_eventuallyCoversEarliest` and every
    other `HistoryViewModelTests` test passes, with no stale 90/180/200/270-day literal left in any
    comment or assertion. Grep of `drinkpulseUITests/Features/History/` confirms no UI test fixture
    beyond 7 days feeds an initial-load (non-scrolled) assertion. `HistoryViewModelTests.swift` stays
    under the 300-line ceiling.
  </done>
</task>

<task type="auto">
  <name>Task 2: Scoped verification + append plan-0038 execution log and DEVLOG entries</name>
  <files>docs/plans/0038-history-list-lazy-scrollview/execution.md, docs/DEVLOG.md</files>
  <action>
    Run `xcodebuild build` and confirm zero warnings. Run the scoped test set established for
    plan-0038 verification plus the model test: `HistoryViewModelTests`, `HistoryInteractionUITests`,
    `HistoryUnitDisplayUITests`, `EditVolumeIntegrityUITests`, `DuplicateEditPersistenceUITests`,
    `EditDeleteConfirmationUITests` — all must be green. Run the file-size find command from CLAUDE.md
    and confirm no file over 300 lines. Confirm no force-unwraps were introduced, no new network calls,
    no PII/health data logged, no `print`.

    Append a new dated entry, headed `## 2026-08-02 — plan-0038 (in-progress) — Shrink History list
    initial fetch window (90 -> 7 days)` (or similar, matching the file's existing heading style), to
    `docs/plans/0038-history-list-lazy-scrollview/execution.md` — read the existing 2026-08-02 entry
    there first for tone/format and append below it (never edit the existing entry; this file is
    append-only). Cover: **why** — `LazyVStack` renders lazily, but the underlying `@Query` was still
    eagerly fetching the full `listPageDays`-wide window on first load regardless of what's actually
    rendered; this shrinks what's *fetched* from the store, complementing (not overlapping)
    plan-0038's List->ScrollView+LazyVStack render-side fix. **What changed** —
    `HistoryViewModel.listPageDays` 90 -> 7, affecting both `initialWindowStart` (initial `@Query`
    window) and `extendedWindowStart` (each load-more page step), plus the one test
    (`extendedWindowThenHasMore_eventuallyCoversEarliest`) that had hardcoded day-math tied to the old
    value. **What did NOT change** — the `LoadMoreSentinel`/`onAppear` load-more cascade mechanism
    itself (`extendListWindow()` in `HistoryView.swift`) is untouched; plan-0038's own "Out of scope"
    section already documents that cascade as legitimate infinite-scroll behavior, not something this
    task alters. Do NOT edit `docs/plans/0038-history-list-lazy-scrollview/plan.md` — it is frozen.

    Append a new entry to `docs/DEVLOG.md`, matching the existing entries' date+time/structure/tone
    (read the tail of the file first). State this is a direct follow-up to plan-0038, restate the
    fetch-vs-render distinction above, note the constant change and the test fix, and reference the new
    plan-0038 `execution.md` entry.

    Quick-check `.claude/context/current-focus.md`: confirm it states nothing that is now factually
    wrong because of this change (per the planning note, it currently only describes plan-0038's step
    status, not the 90-day constant, so no edit is expected). Leave it untouched unless a stated fact
    is actually contradicted — do not rewrite it wholesale on a hunch.
  </action>
  <verify>
    <automated>xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseTests/HistoryViewModelTests -only-testing:drinkpulseUITests/HistoryInteractionUITests -only-testing:drinkpulseUITests/HistoryUnitDisplayUITests -only-testing:drinkpulseUITests/EditVolumeIntegrityUITests -only-testing:drinkpulseUITests/DuplicateEditPersistenceUITests -only-testing:drinkpulseUITests/EditDeleteConfirmationUITests 2>&1 | tail -60</automated>
  </verify>
  <done>
    Full scoped test set green; `xcodebuild build` clean (zero warnings); no file over 300 lines; no
    force-unwraps/print/PII introduced. `docs/plans/0038-history-list-lazy-scrollview/execution.md` has
    a new 2026-08-02 entry appended below the existing one (plan.md untouched). `docs/DEVLOG.md` has a
    new entry appended. `.claude/context/current-focus.md` is untouched (confirmed no fact in it became
    stale).
  </done>
</task>

</tasks>

<non_goals>
- Do NOT edit `docs/plans/0038-history-list-lazy-scrollview/plan.md` — it is frozen since 2026-08-02;
  all narrative for this change goes into `execution.md` only.
- Do NOT touch `HistoryView.swift`'s `extendListWindow()`, `LoadMoreSentinel`, or any other part of the
  load-more cascade mechanism — plan-0038's own "Out of scope" section already documents that cascade as
  legitimate infinite-scroll behavior; this task changes only the day-count constant driving it.
- Do NOT rewrite `.claude/context/current-focus.md` wholesale — it already accurately describes
  plan-0038 as in-progress; touch it only if this change makes a stated fact in it actually wrong.
- Do NOT register a new entry in `docs/plans/INDEX.md` — this task is not a new plan, it is a
  continuation appended to plan-0038's existing execution log.
- Do NOT perform plan-0038's own still-outstanding step 7 (manual real-hardware verification) — that
  remains a separate, human-only follow-up unrelated to this constant change.
</non_goals>

<verification>
- `HistoryViewModel.listPageDays == 7`; `initialWindowStart`/`extendedWindowStart` both move by 7 days.
- `HistoryViewModelTests` (all cases, including the rewritten
  `extendedWindowThenHasMore_eventuallyCoversEarliest`) pass with no stale 90/180/200/270-day literals.
- Scoped History UI test set (`HistoryInteractionUITests`, `HistoryUnitDisplayUITests`,
  `EditVolumeIntegrityUITests`, `DuplicateEditPersistenceUITests`, `EditDeleteConfirmationUITests`)
  passes unmodified — the constant change does not alter any UI-visible flow given the confirmed seed
  data (single "Today" event for the default seed; the one multiday-fixture test only asserts on
  today's event).
- `xcodebuild build` clean, zero warnings; no file over 300 lines.
- `docs/plans/0038-history-list-lazy-scrollview/execution.md` has a new dated entry; `plan.md` is
  unedited. `docs/DEVLOG.md` has a new entry.
</verification>

<success_criteria>
- History's initial list `@Query` window is 7 days instead of 90 — first-load fetch cost drops
  accordingly, complementing plan-0038's render-side (`List` -> `ScrollView`+`LazyVStack`) fix.
- The load-more cascade (`extendListWindow`/`LoadMoreSentinel`/`onAppear`) is functionally unchanged —
  same mechanism, smaller page size.
- All pagination tests pass deliberately against the new constant, not coincidentally.
- plan-0038's paper trail (`execution.md`) reflects this change; `plan.md` stays frozen.
- `docs/DEVLOG.md` records the change per the standard checklist format.
</success_criteria>

<output>
Append this task's outcome to `docs/plans/0038-history-list-lazy-scrollview/execution.md` (per plan-0038's
append-only execution log — see objective) rather than creating a separate quick-task SUMMARY.md as the
primary record. Additionally create
`.planning/quick/260802-uia-shrink-history-list-initial-fetch-window/260802-uia-SUMMARY.md` (standard GSD
quick-task tracking) that itself points back to the plan-0038 execution.md entry as the authoritative
narrative.
</output>