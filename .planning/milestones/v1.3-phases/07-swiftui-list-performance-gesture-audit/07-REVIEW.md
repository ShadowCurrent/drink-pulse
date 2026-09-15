---
phase: 07-swiftui-list-performance-gesture-audit
reviewed: 2026-08-04T00:00:00Z
depth: standard
files_reviewed: 31
files_reviewed_list:
  - drinkpulse/Domain/GuidelineChoice+Selectable.swift
  - drinkpulse/Features/History/Components/EventContextMenu.swift
  - drinkpulse/Features/History/Components/EventRow.swift
  - drinkpulse/Features/History/Components/EventRowButton.swift
  - drinkpulse/Features/History/Components/EventRowStrings.swift
  - drinkpulse/Features/History/Components/HistoryCalendarDayDetail.swift
  - drinkpulse/Features/History/Components/HistoryCalendarView.swift
  - drinkpulse/Features/History/Components/HistoryDaySectionCard.swift
  - drinkpulse/Features/History/Components/RowUnitContext.swift
  - drinkpulse/Features/History/HistoryListQueryView.swift
  - drinkpulse/Features/History/HistoryView.swift
  - drinkpulse/Features/History/HistoryViewModel.swift
  - drinkpulse/Features/Onboarding/Components/GuidelineStep.swift
  - drinkpulse/Features/Settings/Components/GuidelineChoiceRow.swift
  - drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift
  - drinkpulse/Features/Settings/Components/SettingsSection.swift
  - drinkpulseTests/Domain/GuidelineChoiceDisplayTests.swift
  - drinkpulseTests/Features/History/EventRowStringsTests.swift
  - drinkpulseTests/Features/History/HistoryViewModelTests+DayRollover.swift
  - drinkpulseTests/Features/History/HistoryViewModelTests.swift
  - drinkpulseTests/Features/History/RowUnitContextTests.swift
  - drinkpulseTests/Performance/ScreenComputePerformanceTests.swift
  - drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift
  - drinkpulseUITests/Features/History/ContextMenuDeleteConfirmationUITests.swift
  - drinkpulseUITests/Features/History/DuplicateEditPersistenceUITests.swift
  - drinkpulseUITests/Features/History/HistoryDynamicTypeUITests.swift
  - drinkpulseUITests/Features/History/HistoryInteractionUITests+DirectionalTransition.swift
  - drinkpulseUITests/Features/History/HistoryInteractionUITests+HitTarget.swift
  - drinkpulseUITests/Features/History/HistoryInteractionUITests+LoadingState.swift
  - drinkpulseUITests/Features/History/HistoryInteractionUITests.swift
  - drinkpulseUITests/Features/Settings/GuidelinePickerUITests.swift
findings:
  critical: 1
  warning: 3
  info: 3
  total: 7
status: issues_found
---

# Phase 07: Code Review Report

**Reviewed:** 2026-08-04T00:00:00Z
**Depth:** standard
**Files Reviewed:** 31
**Status:** issues_found

## Summary

Phase 07 refactors the History list's row hierarchy (`EventRow` → `EventRowStrings` /
`RowUnitContext` → `EventRowButton`), consolidates the duplicated guideline-picker row
into `GuidelineChoiceRow`, adds a confirmation-gated context-menu Delete
(`EventContextMenuModifier`), and introduces a `sections: [DaySection]` cache on
`HistoryListQueryView` refreshed by three explicit triggers instead of recomputing
day-grouping on every body pass. The refactor itself is careful — value types replace
observable-model reads on rows (A6-1), string formatting is deduplicated and unit-tested
(A4-1), and the new Duplicate/Delete UI paths are covered by dedicated UI test files.

Two classes of issue stood out under adversarial reading, both concentrated in the two
riskiest pieces of new logic this phase added — the confirmation-gated delete path and
the new section cache:

1. **Silent `try? context.save()` around a destructive, HealthKit-linked delete** (and
   around the duplicate-then-open-Edit-sheet path) has no error handling or user-facing
   surfacing, in direct tension with the project's own non-negotiable error-handling
   rule. For the delete path specifically, a failed save can leave the on-disk store and
   HealthKit in a state where the "deleted" drink resurrects on next launch after its
   Health sample has already been removed.
2. **The new `sections` cache can go stale** after an in-place edit to `consumptionDate`
   that doesn't change events' relative sort order across the whole window (e.g. editing
   the currently-oldest-in-window event to be even older) — none of the three declared
   refresh triggers (`onChange(of: events)`, `scenePhase == .active`,
   `.NSCalendarDayChanged`) reliably fire for that case within the same foreground
   session, so the edited event can keep rendering under its old day heading.

Everything else — file sizes, force-unwraps, accessibility traits, localization key
coverage, Dynamic Type layout, identity keying — checked out clean.

## Critical Issues

### CR-01: Silent `try? context.save()` on the confirmation-gated Delete/Duplicate path

**File:** `drinkpulse/Features/History/Components/EventContextMenu.swift:111, 123`
**Issue:**
`EventContextMenuModifier.performDuplicate()` and `.performDelete()` both call
`try? context.save()` and discard the result, with no fallback UI, no logging, and no
comment explaining why a save failure is safe to ignore here. CLAUDE.md's "Logging &
observability" section is explicit: *"No empty `catch {}`, no swallowing with `try?`
unless the failure is genuinely ignorable and a comment says why."* The existing
comments explain *why the save call exists* (closing the temporary-`PersistentIdentifier`
window before the row becomes tappable) but not *why a failure of that save is safe to
ignore* — because it isn't:

- `performDelete()` (line 116-125) calls `HealthWriteHooks.remove(event, using:
  healthService)` — a fire-and-forget removal of the corresponding HealthKit sample —
  *before* `context.delete(event)` and the swallowed `save()`. If `save()` throws (disk
  full, container error, CloudKit conflict, etc.), the in-memory context still reflects
  the deletion (so the row visibly disappears and the confirmation flow looks like it
  succeeded), but the on-disk store was never updated. On next launch, the "deleted"
  `ConsumptionEvent` reappears — except the HealthKit sample it pointed to has already
  been removed, leaving the app record and Health store permanently out of sync with no
  user-visible indication anything went wrong. This is exactly the "Health data is
  sensitive" / "errors ... surfaced to the user" scenario CLAUDE.md calls out.
- `performDuplicate()` (line 94-113) has a comment describing precisely why the
  immediate save matters (avoiding the temporary-identifier flip that silently discards
  in-progress edits — the regression `DuplicateEditPersistenceUITests` pins). If that
  same `save()` fails, the fix it exists to provide silently does not apply, and the
  original data-loss bug it was written to close can recur with no signal to the user or
  in the logs.

This is the same swallow pattern the pre-phase code already had (as a bare `contextMenu`
closure), but this phase doubled its surface area: the new `.accessibilityActions` block
arms the exact same `performDelete()`/`performDuplicate()` methods, so the silent-failure
risk now also covers the VoiceOver path this phase added (finding C14-2), not just the
touch path.

**Fix:** At minimum, log the failure via `os.Logger` (category, no PII — e.g. "History
delete save failed") so it is diagnosable, and consider surfacing a non-blocking error
affordance (matching the pattern `StartupErrorView` already established for
container-load failures) rather than a bare `try?`. If the team decides the failure truly
is ignorable, CLAUDE.md requires a comment saying why — that comment does not currently
exist for either call site.
```swift
private func performDelete() {
    animatedHistoryChange(reduceMotion: reduceMotion) {
        HealthWriteHooks.remove(event, using: healthService)
        context.delete(event)
        do {
            try context.save()
        } catch {
            Logger(subsystem: "com.drinkpulse.app", category: "history")
                .error("Context-menu delete save failed: \(error.localizedDescription, privacy: .private)")
            // TODO: surface a non-blocking error state; today this can leave the
            // on-disk store and a just-removed HealthKit sample out of sync.
        }
    }
}
```

## Warnings

### WR-01: `HistoryListQueryView`'s new `sections` cache can go stale for in-place date edits

**File:** `drinkpulse/Features/History/HistoryListQueryView.swift:95-131`
**Issue:** `sections` (`@State`) is recomputed only on three triggers: `.onChange(of:
events, initial: true)`, `.onChange(of: scenePhase)` (only on `.active`), and
`.onReceive(.NSCalendarDayChanged)`. `events` is a `@Query`-sourced `[ConsumptionEvent]`,
where `ConsumptionEvent` is a SwiftData `@Model` reference type without a custom
`Equatable` override, so array equality for `.onChange(of:)` purposes is whatever
SwiftData's macro-synthesized conformance provides — model identity, not a
field-by-field snapshot. `EditEventView` lets a user change `event.consumptionDate` to a
different calendar day (`EditEventView.swift:238`) while `HistoryView` stays fully
foregrounded (no `scenePhase` change) and well before a midnight rollover.

Whenever that edit also happens to change the edited event's relative rank in the
window's full `consumptionDate`-descending order, the resulting array differs from the
cached one (different order) and `.onChange(of: events)` fires correctly. But when the
edited event is already at an extreme of the sort order and stays there after the edit —
e.g. it is currently the oldest event in the window and gets edited to an even older date
— its position in the array does not change, only its date value does. In that case nothing
observably differs about the `events` array from `.onChange`'s point of view, so
`refreshSections()` never runs, and the edited event keeps rendering under its **old**
day's `HistoryDaySectionCard` heading (wrong date, wrong section) until the app is
backgrounded/foregrounded or a real calendar day boundary passes — which may not happen
before the user notices.

This is exactly the "correctness obligation" the method's own doc comment (lines 114-129)
already reasons carefully about for the *today/yesterday relabelling* case, but the
reasoning stops one edit-source short: it accounts for the clock moving while data stays
fixed, not for data moving (into a different day-bucket) while nothing else in the
sort order changes. No existing test (`HistoryViewModelTests+DayRollover.swift`,
`RowUnitContextTests.swift`) exercises this path — those tests call `daySections(_:)`
directly with fixed inputs, which is correct for pinning the pure function, but none of
them exercise `HistoryListQueryView`'s own refresh-trigger wiring against an in-session
edit.

**Fix:** Don't rely solely on default `Equatable` over model references for the
correctness-critical trigger. Either derive an explicit, cheap fingerprint that is
guaranteed to change on a `consumptionDate` edit (e.g. `events.map { $0.uuid }.hashValue`
alongside a sum/xor of `consumptionDate.timeIntervalSince1970` bit patterns, or simpler:
key `.onChange` off `events.map(\.consumptionDate)` instead of `events` itself), or add an
explicit `refreshSections()` call from the edit-save path (`HistoryView`'s
`.sheet(item:)` completion) so a save that could move an event's day bucket always
re-triggers the cache regardless of `@Query` array-equality semantics. Add a regression
test/UI test that edits a seeded event's date across a day boundary while the app stays
foregrounded and asserts the row moves to the correct section.

### WR-02: `EventRowStrings.accessibilityLabel` builds hard-coded English words outside `String(localized:)`

**File:** `drinkpulse/Features/History/Components/EventRowStrings.swift:35-38`
**Issue:** The spoken VoiceOver label is assembled with
`String(format: "%@, %@, %.1f percent ABV, %@ %@, logged at %@", ...)` — the words
"percent ABV" and "logged at" are literal English text embedded in a format string, not
routed through `String(localized:)`. CLAUDE.md: *"All user-facing strings go through
`String(localized:)`."* This predates the phase (the same literal existed inline in
`EventRow.swift` before this refactor moved it into its own file), but it is now
concentrated in a purpose-built, freshly-authored file whose entire job is producing
user-facing (spoken) strings, and one of this phase's stated goals was cleaning up this
exact row. It's low risk today only because the app is English-only; if that ever
changes, this string silently will not appear in the string catalog for translation.

**Fix:** Route the two connector phrases through `String(localized:)` keys (e.g.
`"history.row.a11y.abvSuffix"`, `"history.row.a11y.loggedAtPrefix"`) or build the label
from an interpolated `String(localized:)` template string with format arguments, matching
the pattern already used elsewhere in this file (`"history.row.hasNote"`).

### WR-03: `HistoryCalendarView.dailyLimit`'s no-profile fallback is an undocumented magic number

**File:** `drinkpulse/Features/History/Components/HistoryCalendarView.swift:18-23`
**Issue:** `guard let p = profile else { return 20 }` — `20` (grams) has no named
constant and no comment explaining where it comes from (it happens to match WHO's male
daily limit, but nothing states that, and `RowUnitContext`'s analogous no-profile
fallbacks a few lines above are all named enum defaults with an explanatory doc comment).
This file was directly touched by this phase (the surrounding `unitContext`/`density`
computed properties were rewritten), so the line was in the reviewed diff's neighborhood
even though this particular line itself wasn't changed.

**Fix:** Extract to a named constant with a one-line rationale, e.g.
`private static let fallbackDailyLimitGrams = 20.0 // WHO male daily limit; profile is
always present after onboarding, this is a defensive default only`.

## Info

### IN-01: `DuplicateEditPersistenceUITests` hard-codes a 10-second `Thread.sleep`

**File:** `drinkpulseUITests/Features/History/DuplicateEditPersistenceUITests.swift:87`
**Issue:** `Thread.sleep(forTimeInterval: 10)` is used to wait past an "empirically
observed ~7-8s window" for SwiftData's autosave. The test's own doc comment is candid
about this being empirical rather than deterministic. This isn't flagged as a functional
bug (the doc comment explains the reasoning and there's no better documented API to hook
into), but it does mean: (a) the test always costs at least 10 real seconds, and (b) if a
future SwiftData/OS change shifts the autosave timing window wider, this test would stop
reproducing the regression it exists to pin — silently passing without actually exercising
the risky window, rather than failing loudly.
**Fix:** No action required now; consider a comment noting that a full-suite run should
periodically be checked for how close to the wait boundary the failure was previously
observed, or file a follow-up to find a deterministic hook (e.g. a debug-only "force
autosave" test seam) if this ever becomes a source of flakiness.

### IN-02: `EventContextMenuModifier`'s DEBUG-only logger line sits inside a `contextMenu` `@ViewBuilder`

**File:** `drinkpulse/Features/History/Components/EventContextMenu.swift:44-46`
**Issue:** `let _ = Logger(...).notice(...)` inside the `contextMenu { }` builder runs on
every context-menu content build, gated `#if DEBUG` (so it's inert in Release, and it
logs no PII — compliant with the logging rules). This is pre-existing (moved verbatim
from the old bare `contextMenu` call site), not introduced by this phase. Flagged only as
a minor readability note: a `let _ = expr` statement purely for its side effect inside a
`@ViewBuilder` closure is a slightly unusual pattern that could confuse future
maintainers scanning for stray unused bindings.
**Fix:** No action required; consider a short comment noting the `let _ =` is
intentional (side-effect logging), not a leftover unused binding, if this recurs
elsewhere.

### IN-03: `GuidelinePickerUITests.openGuidelineSheet()` matches the Settings row by fragile substring label

**File:** `drinkpulseUITests/Features/Settings/GuidelinePickerUITests.swift:152-161`
**Issue:** `NSPredicate(format: "label CONTAINS 'Global' OR label CONTAINS 'DHS'")`
couples the test to the exact wording of two `GuidelineChoice.displayName` strings
("... Global ..." for WHO, "... DHS" for Germany) rather than a stable accessibility
identifier (the row's own `guidelineChoiceRow.<rawValue>` identifiers, used everywhere
else in this same file, aren't available on the *Settings* row itself — only inside the
sheet). If either display name's wording changes, this helper breaks with a confusing
"row not found" failure rather than a clear "label changed" one.
**Fix:** Non-blocking; if `GuidelineChoiceRow`'s Settings-screen counterpart
(`SettingsRow`) ever gets its own accessibility identifier, prefer that over the
substring match.

---

_Reviewed: 2026-08-04T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
