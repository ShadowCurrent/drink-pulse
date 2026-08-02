# 0038 — History list: replace `List` with `ScrollView` + `LazyVStack`

**Status**: draft
**Size**: medium
**Created**: 2026-08-02

## Summary

Replace `HistoryListQueryView`'s `List(.insetGrouped)` with a `ScrollView` +
`LazyVStack`, following the exact visual/component recipe already shipped for
Settings (plan-0027, `SettingsSection`/`SettingsRow` over `dpGlassCard`) and
already used unmodified in `HistoryCalendarDayDetail` (plain `VStack`+`ForEach`
+ `Divider`, no `List`). This removes a confirmed, measured main-thread cost:
`List`+`ForEach` in this app eagerly evaluates every row's body **and** its
`.contextMenu`/`.swipeActions` content for the **entire currently-fetched
window** (not just visible rows) on every render — confirmed by device
Console logs (contextMenu-build log count == total events in the loaded
90-day window, firing identically on every tab switch). `ScrollView` +
`LazyVStack` only instantiates rows near the visible viewport, which is the
documented/expected behavior difference between the two containers.

Native `.swipeActions` requires a `List` row context prior to iOS 27 (Apple's
`swipeActionsContainer()`, which unlocks `.swipeActions` on `ScrollView`/
`LazyVStack` rows, is iOS-27-only). Per owner decision (2026-08-02),
swipe-to-delete is **dropped for now** — context-menu Delete becomes the sole
delete path in the list — to be restored once the project's minimum
deployment reaches iOS 27.

## Context

Diagnosed across two sessions:
1. User reported a 0.5–1s hitch on the *first* History-tab open after a fresh
   install (glass pill stutter, `SystemGestureGate _timeOut`), plus a similar
   hitch on the *first* long-press on a row.
2. `ViewLoadLogger` showed `HistoryView`'s own `.onAppear` firing in ~48ms —
   ruling out the view's own mount cost.
3. Diagnostic `os.Logger` calls (quick task, this session) added to
   `extendListWindow()`, the row-tap `Button`, the swipe-delete action, and
   the `.contextMenu` content closure confirmed: the `contextMenu` content log
   fires once per event in the loaded window, on every tab switch — not
   gated by long-press at all. This is a documented SwiftUI `List` limitation
   (Apple DevForums threads 704778, 762005, 688415: `List` calls `init`/`body`
   — and attached modifier content — for every row, not just visible ones;
   `ScrollView`+`LazyVStack` does not have this problem).
4. The separate `ManagedConfiguration`/`MCRestrictionManager` fault the user
   saw on first long-press is a private-framework, once-per-process MDM
   restriction check tied to the first-ever `UIContextMenuInteraction`
   presentation — OS-side, not fixable, not addressed by this plan (same
   class as the `UNUserNotificationCenter`/`HKHealthStore` first-touch costs
   already documented elsewhere in this codebase).
5. Researched the "right fix" (this plan) before writing it, per CLAUDE.md's
   no-guessing rule: confirmed via Apple's own doc page existing at
   `developer.apple.com/documentation/swiftui/view/swipeactionscontainer()`
   (page content not renderable by the fetch tool used, but its existence at
   that URL confirms the API; availability corroborated as iOS 27 by SwiftUI
   authority swiftwithmajid.com, cross-checked against a second independent
   source) that native swipe support outside `List` needs iOS 27. Presented
   this to the owner before finalizing the plan; owner chose to drop swipe
   now and re-add it once the app's minimum deployment reaches iOS 27 (owner
   does not expect to ship before then anyway).

**Regression risk to protect against**: DEVLOG 2026-07-31 ("Fix: History row
insert/delete not animating") already fixed a real bug where History row
insert/delete showed no animation — root cause was `@Query`'s refresh landing
outside the `withAnimation` transaction. That fix (`animatedHistoryChange`
wrapping every mutation call site) must keep working after this rewrite; the
owner explicitly flagged this as their main concern for this plan.

## Scope

### In
- `HistoryListQueryView.swift`: `List` → `ScrollView` + `LazyVStack`.
- New `HistoryDaySectionCard` component (day title + `dpGlassCard`-wrapped,
  divider-separated rows) — extracted so `HistoryListQueryView` stays under
  the 300-line ceiling and mirrors the existing `SettingsSection`/`SettingsRow`
  split.
- Remove `.swipeActions` (trailing swipe-to-delete) from the list; leave a
  dated code comment at the removal site pointing to `swipeActionsContainer()`
  (iOS 27) and this plan as where to resume.
- Remove `test_swipeDelete_removesEvent` (`HistoryInteractionUITests.swift`)
  and its mention in that file's header doc comment, with a comment
  explaining why and the re-add condition.
- Remove the now-swipe-targeting diagnostic logger line (added in the prior
  quick diagnostic task) since the code path it logged is deleted.
- Preserve/verify insert-delete-duplicate animations (`animatedHistoryChange`
  call sites, `.transition()` on rows and day-cards) — explicit manual
  on-device verification, not just code-level inspection, per the owner's
  stated concern.
- `.claude/context/open-questions.md`: new entry — re-add native History
  swipe-to-delete once min deployment reaches iOS 27.
- Remove the two remaining first-session diagnostic loggers
  (`extendListWindow`, row-tap) once the fix is verified — they were
  explicitly throwaway instrumentation.

### Out
- `HistoryCalendarQueryView`/`HistoryCalendarView`/`HistoryCalendarDayDetail`
  — calendar day-detail already uses plain `VStack`+`ForEach` (no `List`, no
  swipe), unaffected.
- Any change to pagination logic (`HistoryViewModel.extendedWindowStart`,
  `hasMoreToLoad`, `listWindowStart`) — the "load more" cascade behavior
  (sentinel `onAppear` extending the window until it fills the viewport) is
  legitimate infinite-scroll behavior, not a bug. What this plan fixes is the
  **cost per cascade step** (was O(all rows in window) due to `List`
  eagerness, becomes O(rows near viewport) with `LazyVStack`) — not the
  cascade's existence.
- Raising the minimum deployment target to iOS 27 — out of scope, a
  standalone project-wide decision for later.
- Any visual redesign beyond replicating the current `.insetGrouped` grouped
  look via `dpGlassCard` per day (already the established pattern from
  plan-0027).

## Implementation steps

1. Create `drinkpulse/Features/History/Components/HistoryDaySectionCard.swift`:
   day-title label (mirrors `HistoryListQueryView.sectionTitle(for:)`, moved
   or passed in) above a `dpGlassCard`-wrapped `VStack` of rows, each row =
   the existing `Button { onEditEvent(event) } label: { EventRow(...) }`
   `.eventContextMenu(...)` combo (verbatim behavior, no `.swipeActions`),
   separated by `Divider()` (matching `HistoryCalendarDayDetail`'s existing
   divider pattern). Mandatory preview per CLAUDE.md.
2. Rewrite `HistoryListQueryView.body`: `List { ... }.listStyle(.insetGrouped)`
   → `ScrollView { LazyVStack(spacing: 16) { ... } }`, using
   `HistoryDaySectionCard` per day, keeping `LoadMoreSentinel`/
   `EndOfListFooter` as the trailing lazy elements (unchanged internals).
3. Add explicit `.transition()` to both the day-card level (whole-day
   removal/insertion when an event is deleted/duplicated into a new day) and
   confirm the per-row removal inside a card animates under `withAnimation`
   (the existing `animatedHistoryChange` wrapping at each mutation call
   site — swipe-delete's copy of this wrapping goes away with swipe itself;
   context-menu delete/duplicate keep theirs unchanged).
4. Remove the `.swipeActions { ... }` block from `HistoryListQueryView`; add
   a dated comment (`// TODO(iOS 27): ...`) pointing at
   `swipeActionsContainer()` and this plan number.
5. Remove the swipe-targeting diagnostic log line added in the prior quick
   task (the code it wrapped is deleted).
6. Remove `test_swipeDelete_removesEvent` from `HistoryInteractionUITests.swift`
   and update the file's header doc comment (drop the "swipe-to-delete"
   mention); add a short comment noting the removal reason.
7. Manual on-device verification pass (cold install, real hardware —
   automated tests can't prove perceived smoothness or animation feel):
   - First History-tab open after fresh install: hitch gone / significantly
     reduced; Console shows the `contextMenu content build start` log firing
     only for rows actually scrolled into view, not the whole window.
   - Add a drink → appears in History with an entrance animation.
   - Context-menu Duplicate → new row animates in.
   - Context-menu Delete of the only event in a day → the whole day card
     animates out (not just the row).
   - Context-menu Delete of one of several events in a day → only that row
     animates out, the card stays.
   - Scroll to the bottom, confirm "load more" still triggers and the
     `EndOfListFooter` still appears at the true end.
8. Once step 7 passes, remove the two remaining first-session diagnostic
   loggers (`extendListWindow`, row-tap) — throwaway instrumentation, its job
   is done.
9. Update `.claude/context/open-questions.md` with the deferred
   swipe-to-delete item (iOS 27 gate).
10. End-of-task checklist per CLAUDE.md (build clean/zero warnings, scoped
    test run — `HistoryInteractionUITests`/`HistoryUnitDisplayUITests`/
    `EditVolumeIntegrityUITests`/`DuplicateEditPersistenceUITests`/
    `EditDeleteConfirmationUITests` — file size, DEVLOG entry,
    `current-focus.md`, `docs/plans/INDEX.md` status → completed).

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/History/HistoryListQueryView.swift` | Modify |
| `drinkpulse/Features/History/Components/HistoryDaySectionCard.swift` | Create |
| `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` | Modify (remove swipe test + header mention) |
| `.claude/context/open-questions.md` | Modify (new deferred-swipe entry) |
| `docs/plans/INDEX.md` | Modify (register this plan; fix stale "Next number") |
| `docs/DEVLOG.md` | Append (on completion) |
| `.claude/context/current-focus.md` | Modify (on completion) |

## Open questions

- [ ] None blocking — the swipe-vs-iOS27 fork was resolved by the owner
      before this plan was written (drop swipe now, re-add post-iOS 27).

## Tests required

- No new unit tests: `HistoryDaySectionCard` is pure SwiftUI layout (excluded
  from the coverage denominator per CLAUDE.md — "pure layout/SwiftUI view
  structure", covered by its mandatory Preview instead).
- UI tests: remove `test_swipeDelete_removesEvent` (feature removed).
  `test_contextMenuDelete_removesEvent` and `test_contextMenuDuplicate_addsEvent`
  (already existing, container-agnostic — no `List`/`.cells`/`.tables`
  element-type queries) must still pass unmodified and now cover the sole
  delete path. Re-run the full scoped History UI test set (see step 10) and
  confirm all green.
- Manual on-device animation verification (step 7) is a hard requirement of
  this plan's definition of done, not optional polish — it is the direct
  answer to the owner's stated concern and cannot be substituted with
  automated coverage (SwiftUI transition/animation feel is not meaningfully
  unit-testable).
