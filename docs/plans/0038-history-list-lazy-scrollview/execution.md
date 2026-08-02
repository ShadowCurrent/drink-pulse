# Execution log — plan-0038

## 2026-08-02

Implemented steps 1-6, 9, 10 (partial):

- Created `HistoryDaySectionCard.swift` (day title + `dpGlassCard`-wrapped
  `VStack` of rows, `Divider()` between rows, `.eventContextMenu` per row,
  `.transition(.opacity...)` at the card level for whole-day insert/removal).
  Mandatory Preview included.
- Rewrote `HistoryListQueryView.body`: `List(.insetGrouped)` → `ScrollView` +
  `LazyVStack(spacing: 16)`, using `HistoryDaySectionCard` per day.
  `LoadMoreSentinel`/`EndOfListFooter` kept as trailing lazy elements
  (internals unchanged; `EndOfListFooter` dropped its now-invalid
  `.listRowBackground`/`.listRowSeparator` List-only modifiers).
- Removed `.swipeActions` entirely; left a dated `// TODO(iOS 27): ...`
  comment pointing at `swipeActionsContainer()` and this plan.
- Removed the swipe-targeting diagnostic logger (deleted with the code it
  wrapped) and the row-tap diagnostic logger (the plain
  `onEditEvent(event)` closure no longer needs it — folded away naturally
  during the `HistoryDaySectionCard` extraction rather than left as a
  separate step).
- Removed `test_swipeDelete_removesEvent` from `HistoryInteractionUITests.swift`
  and updated the file's header doc comment.
- Updated `.claude/context/open-questions.md`: new entry for re-adding
  native History swipe-to-delete once min deployment reaches iOS 27.
- Registered plan status in `docs/plans/INDEX.md` (draft → in-progress).

**Deviation from plan step 8**: did not remove the `extendListWindow`
diagnostic logger yet — step 8 is explicitly gated on step 7's manual
on-device verification passing, and step 7 (real-hardware cold-start feel
and animation-feel check) has not been run by a human yet. Logger stays
in place until that verification happens.

**Test-fix discovered during scoped run**: `EditVolumeIntegrityUITests.
test_editUntouched_preservesOriginal500mlAsFlOz` asserted on
`app.collectionViews.firstMatch` to detect the List returning after Save —
a `List`-only accessibility element type that does not exist for
`ScrollView`. Fixed to assert the `Edit Drink` nav bar is gone instead
(`XCTAssertFalse(...waitForExistence...)`), matching the same dismiss-check
pattern already used in `EditDeleteConfirmationUITests.swift:94`. This was
not called out as an "In scope" file in the plan (the plan named only
`HistoryInteractionUITests.swift`) — noted here as an in-scope-adjacent
fix required to keep the plan's own "must still pass unmodified" claim
about the other test files true.

**Verification run**: `xcodebuild build` clean, zero warnings. Scoped UI
suite (`HistoryInteractionUITests`, `HistoryUnitDisplayUITests`,
`EditVolumeIntegrityUITests`, `DuplicateEditPersistenceUITests`,
`EditDeleteConfirmationUITests`) — 16/16 passing after the fix above. File
sizes: `HistoryListQueryView.swift` 88 lines, `HistoryDaySectionCard.swift`
72 lines — both well under the 300-line ceiling.

**Outstanding — not done by this session**: plan step 7's manual
on-device verification (cold-install real-hardware hitch check; visual
confirmation of day-card and row insert/delete/duplicate animation feel)
requires a human on real hardware — this is explicitly called out in the
plan as non-automatable ("SwiftUI transition/animation feel is not
meaningfully unit-testable"). Automated tests confirm the mutation paths
still work and animate under `withAnimation` at the code level, but do
not prove perceived smoothness. Plan stays `in-progress` until this run
happens; step 8 (remove remaining diagnostic loggers) follows it.

## 2026-08-02 — plan-0038 (in-progress) — Shrink History list initial fetch window (90 -> 7 days)

Quick task (`.planning/quick/260802-uia-shrink-history-list-initial-fetch-window/`),
direct continuation of this plan rather than a separate untracked change.

**Why**: `LazyVStack` (steps 1-6 above) only fixed the render-side cost —
`List`+`ForEach` eagerly building every row's body and `.contextMenu`
content for the whole loaded window. It did not touch the fetch-side cost:
SwiftData's `@Query` was, until this task, still eagerly fetching a full
90-day window on first load regardless of how lazily it then renders. This
task shrinks what gets *fetched*, complementing (not overlapping) the
List → ScrollView+LazyVStack render-side fix.

**What changed**: `HistoryViewModel.listPageDays` `90` -> `7`. This is a
single shared constant feeding both `initialWindowStart` (the initial
`@Query` window) and `extendedWindowStart` (each load-more page step), so
both moved together — no separate first-page-vs-subsequent-page constant
was introduced. Rewrote the one test with hardcoded day-math tied to the
old page size, `extendedWindowThenHasMore_eventuallyCoversEarliest`
(seeded `earliest` at -200 days, asserted a 0/1/2-extension progression
against 90/180/270): now seeds `earliest` at -20 days and asserts the same
progression against 7/14/21. All other pagination tests
(`initialWindowStart_isOnePageBeforeNow`, `extendedWindowStart_movesBackOnePage`,
`extendedWindowStart_repeatedCalls_keepMovingBack`) already derived their
expected values from `HistoryViewModel.listPageDays` symbolically and
needed no edit.

**What did NOT change**: the `LoadMoreSentinel`/`onAppear` load-more
cascade mechanism itself (`extendListWindow()` in `HistoryView.swift`) is
untouched — this plan's own "Out of scope" section already documents that
cascade as legitimate infinite-scroll behavior, not something this task
alters.

**Verification**: `xcodebuild build` clean, zero warnings.
`HistoryViewModelTests` — 28/28 passing (run standalone; combining
`-only-testing:drinkpulseTests/...` with `-only-testing:drinkpulseUITests/...`
flags in one invocation reports 0 tests executed for the `drinkpulseTests`
bundle — a pre-existing `xcodebuild` tooling quirk unrelated to this
change, confirmed by running each bundle's `-only-testing` set in its own
invocation). Scoped UI suite (`HistoryInteractionUITests`,
`HistoryUnitDisplayUITests`, `EditVolumeIntegrityUITests`,
`DuplicateEditPersistenceUITests`, `EditDeleteConfirmationUITests`) —
16/16 passing, run unmodified (constant change does not alter any
UI-visible flow given the default single-"Today"-event seed; the one
multiday-fixture test only asserts on today's event). No file over 300
lines. No force-unwraps/`print`/PII introduced; no new network calls.
`.claude/context/current-focus.md` checked — states nothing that became
factually wrong from this change, left untouched.
