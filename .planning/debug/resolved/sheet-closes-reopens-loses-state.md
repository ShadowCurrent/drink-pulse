---
status: resolved
trigger: "Bug: edit-drink sheet (possibly add-drink too) closes and reopens while filling form. Loses entered state, user must re-enter data."
created: 2026-07-19
updated: 2026-07-27
resolved: 2026-07-27
---

## Symptoms

- Expected: sheet (Add/Edit drink) stays open and preserves entered field values while user fills it in.
- Actual: while filling in form data, the presented sheet appears to dismiss and re-present itself, resetting entered field state. User has to re-enter data.
- Trigger pattern: unknown/not identified by user. Not obviously tied to a specific field, picker, or keyboard action.
- Timeline: user reports this has "always" happened (not a new regression from the most recent change, per user, though most recent branch work was `quick-260719-nm6` — custom name autocomplete/suggestions on Add/Edit screens).
- Scope: primarily observed in Edit mode; user believes Add mode may also be affected but is not fully certain whether it's Edit-only, Add-only, or both.
- Errors: none checked yet — user has not inspected Xcode console/logs during the repro.
- Reproduction: not reliably reproducible; described as happening "randomly," no fixed steps identified yet.

### 2026-07-26 update — precise repro found by user

- New reproduction (user reports this now happens "practically always"):
  1. Duplicate an existing `ConsumptionEvent` entry (via the duplicate action in History).
  2. Tap the newly duplicated entry to open its Edit sheet.
  3. Set a new date and/or time value in the DatePicker.
  4. When focus leaves that date/time field (i.e. right after committing the date/time change), the Edit sheet dismisses and re-presents itself — reproducing the state-loss bug.
- Additional signal: once per app run (not every repro, but around the same moment), Xcode console logs a system-level fault:
  ```
  Reading from public effective user settings.
  Fault ... ManagedConfiguration MC ... -[MCRestrictionManager memberQueueEffectiveUserSettings] ...
  ```
  Status of this log: NOT YET DETERMINED whether correlated or a red herring (this is a known-benign macOS/iOS Simulator system log pattern seen in many unrelated apps — MDM/managed-configuration restriction check that Simulator triggers lazily on first query per process lifetime — but must be verified, not assumed, in context of this specific repro).
- This is the first concrete, repeatable trigger identified since the session opened (previous 3 hypotheses were eliminated with a generic edit flow, not this specific duplicate→edit-date path).

## Current Focus

reasoning_checkpoint (SUPERSEDES the interactiveDismissDisabled hypothesis below — that one was tested and REFUTED; kept in Eliminated for the record):
  hypothesis: "`EventContextMenu`'s Duplicate action `context.insert()`s the copy but never saves. A freshly-inserted, not-yet-saved SwiftData `@Model` object carries a TEMPORARY `PersistentIdentifier` that only becomes permanent once the `ModelContext` saves. `HistoryView`'s `.sheet(item: $editingEvent)` is keyed by that identifier (via `ConsumptionEvent`'s default `Identifiable` conformance). If the user opens Edit on the fresh duplicate and SwiftData's own autosave fires while the sheet is still open (empirically several seconds after insert, regardless of any gesture), the identifier flips from temporary to permanent, and SwiftUI reads that as 'a different item is now presented' — tearing down and reconstructing `EditEventView` fresh from the model (discarding every unsaved local `@State` field), even though the sheet's own chrome/nav-bar title is unaffected (same `.sheet` presentation, just reconstructed content). This is what the user experiences as 'the sheet closes and reopens, and I lose everything I typed.'"
  confirming_evidence:
    - "Isolated with a 'no drag at all, just wait' UI test: duplicate -> open Edit on the fresh copy -> type a Custom Name marker -> wait in 1-second increments with ZERO further interaction. The marker read back correctly for 7 straight seconds, then was silently reset to the empty placeholder at the 8-second mark, in every run — proving no gesture (drag, tap, DatePicker interaction) is needed at all; pure elapsed time is sufficient."
    - "Isolated which object must be edited: repeating the identical duplicate+wait sequence but opening Edit on the OLDER, already-existing seeded event instead of the fresh duplicate never reproduced the reset (3/3 clean) — the freshly-inserted-but-unsaved object specifically is required, not just 'two rows exist in History.'"
    - "This also retroactively explains the earlier (~29%, drag-dependent) repro finding below: those runs all involved editing a fresh duplicate and spent enough wall-clock time fumbling with the DatePicker's calendar overlay to cross the same autosave window — the drag was incidental, not causal."
    - "Fix verified: after adding `try? context.save()` immediately following `context.insert(copy)` in `EventContextMenu`, the identical 'no drag, just wait 8s' test and the original literal calendar-overlay+drag repro both passed cleanly across repeated runs (8/8 total) with ZERO reverts to any other code (DatePicker style, interactiveDismissDisabled) — pinning the fix precisely to this one change."
  falsification_test: "If, after `context.save()` is added right after the duplicate insert, the marker still resets after an 8-10s wait on a freshly-duplicated event, the temporary-identifier theory is wrong and the timing-based trigger is something else entirely."
  fix_rationale: "Saving immediately after insert closes the temporary-identifier window before the row is ever tappable, so by the time the user can open Edit on it, its `PersistentIdentifier` is already permanent and stable — there is no later autosave-driven identity flip left to race. This is minimal (11 lines, one call site) and targets the confirmed mechanism directly, unlike the two earlier speculative fixes (`.interactiveDismissDisabled()`, switching the DatePicker to `.wheel` style) which were applied, tested, and DISPROVEN (see Eliminated) before this one was found — both were reverted."
  blind_spots: "The exact internal timing/trigger of SwiftData's autosave (why ~7-8s, whether it's a fixed timer vs. an idle heuristic vs. tied to CloudKit sync scheduling) is not directly observable from application code — inferred from black-box behavioral bisection (waiting before vs. after opening Edit, with vs. without the duplicate, with vs. without a drag), not a source-level trace. Only tested on iOS 26.5 Simulator (iPhone 17 Pro); CloudKit sync is off in this dev build, so real-device/CloudKit-enabled timing could differ (though the fix — save before the row is ever interactable — should hold regardless of the exact autosave trigger). Did not audit every other `context.insert(...)` call site in the codebase for the same latent pattern beyond a targeted grep (see Evidence) — `DrinkDetailInputView.save()` was checked and is safe (insert+dismiss happen together, no open-sheet window on an unsaved object)."
next_action: NONE — session closed 2026-07-27. Human verification passed.

## Evidence

- timestamp: 2026-07-19
  checked: `git log --oneline --all -i --grep="sheet"` history for prior sheet bugs in this codebase.
  found: commit `60abd41` "fix: move sheet modifier from Section to List in SettingsView" — a real prior bug where `.sheet(isPresented:)` was attached to a `Section` inside a `Form`, and Section-content churn caused unreliable presentation. Fix was moving `.sheet` to the enclosing `List`/`Form` level.
  implication: gives a concrete, project-specific anti-pattern to check for: presentation modifiers (`.sheet`/`.popover`/`.fullScreenCover`) attached to a fragile/dynamic subview instead of the top-level container.

- timestamp: 2026-07-19
  checked: every `.sheet(`/`.popover(`/`.fullScreenCover(` call site in `drinkpulse/` (grep across the whole target).
  found: Only 4 remain: `SettingsView.swift:116` (`.sheet`, on the `List`, already fixed), `RootShellView.swift:80` (`.sheet(isPresented: $showAddDrink)`, on the outer `ZStack`, top-level), `HistoryView.swift:78` (`.sheet(item: $editingEvent)`, on the outer `VStack`, top-level), `EditEventView.swift:186` (`.popover(isPresented: $showDeleteConfirmation)`, attached to a `Button` inside a `ToolbarItem` — the one remaining instance of the OLD anti-pattern class, but gated on `showDeleteConfirmation` which only becomes true on an explicit trash-icon tap, not during ordinary field editing).
  implication: the Add/Edit sheets themselves are NOT attached the "unsafe" way; the delete-confirmation popover is the only fragile-position presentation left, but it isn't wired to fire during normal form filling.

- timestamp: 2026-07-19
  checked: `DrinkDetailInputView+Logic.swift` `save()` — confirmed the `ConsumptionEvent` is only `modelContext.insert()`-ed on Save tap, never during editing. `EditEventView.save()` similarly only mutates the model on Save tap; `HealthWriteHooks` `context.save()` calls happen inside detached `Task`s fired from `save()`/`update()`, i.e. only AFTER Save was already tapped and `dismiss()` already called.
  implication: no modelContext writes occur while the user is actively typing in either form, so `@Query` re-fetches (in `CustomNameSuggestionSection`, `HistoryListQueryView`, `profiles` queries) are not being triggered by the user's own in-progress edits.

- timestamp: 2026-07-19
  checked: `RootShellView.swift` `.onChange(of: profiles.isEmpty) { _, isEmpty in if isEmpty { onboardingDone = false } }`, cross-referenced against every `modelContext.delete`/`insert` call site for `UserProfile` (grep, no hits outside onboarding). `drinkpulseApp.swift` `Group { if onboardingDone && !forceOnboardingPending { RootShellView() } else { OnboardingView(...) } }`.
  implication: theoretically, if `profiles` ever transiently reports empty, the ENTIRE `RootShellView` (and any open sheet under it) would be torn down in favor of `OnboardingView` — this is a real fragile pattern (dual source of truth: persisted `onboardingDone` vs. live `profiles.isEmpty`), but no code path was found that deletes/reinserts the `UserProfile` row during normal app use, so no concrete trigger was identified. Flagged as a real design smell worth hardening regardless of whether it's this bug (see below), but NOT confirmed as the cause.

- timestamp: 2026-07-19
  checked: BUILT AND RAN the app in the iOS 26 simulator (iPhone 17 Pro) via `xcodebuild test`, driving a temporary XCUITest (`TempSheetReopenReproUITests`, later deleted — investigation-only, not a permanent regression test) that: (1) seeded a second event with a `customName` so `CustomNameSuggestionSection`'s suggestion list would have real candidates, (2) opened the seeded beer's Edit sheet, (3) filled the Notes field with a marker string, (4) typed a 6-character prefix into Custom Name one character at a time — the exact interaction that makes `CustomNameSuggestionSection`'s `Section` grow/shrink its row count on every keystroke (0→1 row and back) while the keyboard is up and `.presentationDetents([.large])` is active, (5) after every keystroke asserted the `"Edit Drink"` nav bar was still present, (6) at the end scrolled back and asserted the Notes field's VALUE (queried by content, not by placeholder-label, since a filled TextField's a11y label is no longer its placeholder) still equalled the marker string, (7) additionally backgrounded the app (`XCUIDevice.shared.press(.home)`) and reactivated it while the sheet was still open with unsaved edits, then re-asserted the sheet was still open and the Custom Name value ("Barolo") survived.
  found: Test PASSED on every check. The `"Edit Drink"` nav bar never disappeared during the typing loop. The suggestion row for "Barolo Riserva" was confirmed to actually appear (churn genuinely exercised, not a no-op check). The Notes marker value and the Custom Name value both survived the full typing session AND a background/foreground cycle intact.
  implication: this DIRECTLY REFUTES two of the most plausible hypotheses (dynamic-Section-row churn from `CustomNameSuggestionSection` tearing down the sheet; scenePhase/backgrounding causing sheet or state loss) under controlled, repeatable conditions on the current simulator/OS build. The bug — if reproducible at all in its exact reported form — is not triggered by ordinary typing-with-suggestions or a single background/foreground cycle.

- timestamp: 2026-07-19
  checked: `EditDrinkTypeSelectionView` (`NavigationLink` push from the Category row) → `EditEventView.onChange(of: category)` handler.
  found: selecting a NEW category deliberately resets `volumeMl`/`originalVolumeMl`/`abvValue`/`icon` to the new preset's defaults — this is intentional, documented behavior (not a bug); `.onChange` only fires when `category`'s value actually changes, so re-selecting the SAME category is a no-op and does not reset anything.
  implication: category-picker round-trips are not the reported bug — the reset there is by design and category-only.

- timestamp: 2026-07-26
  checked: `duplicated()` (`ConsumptionEvent.swift`) and `eventContextMenu`'s Duplicate action — confirmed the copy gets a fresh `uuid` and `consumptionDate = .now` (distinct identity, not colliding). Also re-read `HistoryView.swift`'s `.sheet(item: $editingEvent)` wiring and `EditEventView.save()`: `date`, `customNameText`, etc. are ALL local `@State`, written to `event.*` only inside `save()`, which runs only on the Save button tap. No `.onChange(of: date)` or any other live write exists.
  found: There is NO code path where changing the DatePicker's local `@State` (or any other field) before Save touches `modelContext` or the `@Query`-driven `events`/`profiles` arrays. This directly rules out hypotheses (a) and (b) from the prior Current Focus (sort-order flip / @Query identity churn caused by an in-progress date edit) — there is nothing for such an edit to trigger downstream.
  implication: the mechanism must be something OTHER than a model/query change — most likely a SwiftUI/UIKit view-identity or gesture-recognizer issue local to the sheet's presentation itself, not a data-layer effect.

- timestamp: 2026-07-26
  checked: BUILT AND RAN the app in the iOS 26.5 simulator (iPhone 17 Pro) via `xcodebuild test`, driving temporary XCUITests (`TempDuplicateDateRepro`, `TempControlNoDateRepro`, both later deleted — investigation-only). Iteratively explored the DatePicker's actual on-screen structure (a compact date button + compact time button; tapping the date button reveals a full calendar-grid overlay rendered on top of the Form, with an invisible "tap outside to dismiss" catcher — confirmed via a "Not hittable" XCUITest error when trying to tap the time button while the date overlay was open). Final repro sequence: duplicate seeded event -> open its Edit sheet -> type a Custom Name marker ("MARKER123") -> open the DatePicker's calendar overlay -> pick a day 2 days before today (a real value change) -> close the overlay via an outside tap -> perform a partial downward drag (press 0.3s, slow velocity, hold 0.1s) starting near the very top of the Form (y≈16% of screen height) ending mid-form (y≈55%) — i.e. NOT a full swipe-to-dismiss, released well before any dismiss animation would complete.
  found: Across 7 valid runs (2 more runs hit an unrelated Simulator infra flake — "Busy/failed preflight checks" — and were excluded), the Custom Name marker was silently reset to its empty placeholder in 2 runs, while `app.navigationBars["Edit Drink"]` remained present and unchanged in EVERY run (never fully disappeared) — this rules out a genuine full dismiss+re-open and points to in-place content reconstruction (SwiftUI re-running `EditEventView.init`, discarding local `@State`, while the surrounding sheet chrome/title stays). A CONTROL test — identical Custom Name marker, identical partial drag, but with NO duplicate and NO DatePicker interaction at all beforehand — never reproduced the reset in 4/4 runs.
  implication: THIS IS THE FIRST DIRECT REPRODUCTION of the state-loss bug. It is intermittent (~2/7 ≈ 29% of runs), requires the DatePicker's calendar overlay to have been shown and dismissed shortly before, and requires a drag gesture near the top of the Form afterward. It does not require a full swipe-to-dismiss — a short, cancelled drag is sufficient. This is consistent with EditEventView's sheet having NO `.interactiveDismissDisabled()`: the drag is momentarily claimed by the sheet's own interactive-dismiss pan gesture recognizer (which conflicts with the List/Form's scroll gesture, especially right after an overlay's presence changed the view tree), and even a cancelled/incomplete interactive dismissal reconstructs the hosted content, wiping unsaved `@State`. Grep confirms `AddDrinkView` (the Add-drink sheet, which pushes `DrinkDetailInputView` containing the SAME `DatePicker(... in: ...Date())` pattern) also has no `.interactiveDismissDisabled()` — consistent with the user's uncertainty about whether Add mode is also affected.
  NOTE (2026-07-26, later same session): this implication was tested and REFUTED — see Eliminated and the entries below. `.interactiveDismissDisabled()` did NOT stop the reset.

- timestamp: 2026-07-26
  checked: Applied `.interactiveDismissDisabled()` to EditEventView + AddDrinkView and re-ran the identical repro sequence from the entry above (duplicate -> edit -> calendar overlay -> pick day -> outside tap -> partial drag) repeatedly.
  found: The reset STILL reproduced (3 of 4 runs failed) — MORE often than before the change, within normal noise for a low-sample intermittent bug. `.interactiveDismissDisabled()` had no measurable effect.
  implication: The interactive-dismiss-gesture-recognizer hypothesis is REFUTED. The mechanism is something else. Moved to Eliminated.

- timestamp: 2026-07-26
  checked: Took screenshots at each step of the repro. Found the "outside tap" (meant to close the calendar overlay) actually landed INSIDE the popup's own header area (dy≈13.5% of screen height maps to the popup's internal "July 2026 ‹ ›" row, not outside it) — the overlay never closed. Ran three isolation variants: (A) tap-inside-popup-header then drag crossing the popup boundary, (B) the same drag with NO preceding tap, (C) the preceding tap with NO drag afterward.
  found: (A) reproduced the reset reliably (2/2, then later 6/6 in a cleaner re-run of the exact original sequence). (B) never reproduced (3/3 survived). (C) never reproduced (1/1 survived, though inconclusive on its own).
  implication: at the time, this pointed to "tap inside the popup, then a drag crossing its boundary" as the necessary combination — but this was later shown to be incidental to elapsed time (see below), not the true mechanism.

- timestamp: 2026-07-26
  checked: Switched `EditEventView`'s and `DrinkDetailInputView`'s `DatePicker` from the default `.compact` style (tap-to-expand calendar/wheel overlay) to `.wheel` style (always-inline, no overlay at all — confirmed via `XCTAssertFalse(app.buttons["Previous Month"].exists)` passing), plus stabilized the `in: ...Date()` range bound into a `@State` captured once at init (`maxSelectableDate`) instead of recomputing `Date()` fresh every body render. Re-ran the duplicate+edit+generic-drag sequence.
  found: The reset STILL reproduced reliably once the right drag coordinates were found (a drag starting inside the ALREADY-EXISTING `.wheel`-style Serving pickers — volume/ABV/count, unrelated to the DatePicker change — and ending further down the Form). Confirmed via a keyboard-dismiss-and-value-echo check that the Custom Name value was intact immediately before the drag and gone immediately after.
  implication: The DatePicker-overlay-specific hypothesis is REFUTED too — the calendar overlay was never the real trigger; it just happened to be one place a drag could start "inside an embedded wheel/scrollable control." Moved to Eliminated. `.wheel` style change and `maxSelectableDate` stabilization were reverted (not part of the final fix) to keep the change minimal and avoid an unnecessary, unconfirmed UI change.

- timestamp: 2026-07-26
  checked: Bisected whether the drag was even necessary, by removing it: duplicate -> open Edit on the fresh copy -> type Custom Name marker -> wait with ZERO further interaction, checking the field's value every second for 8 seconds.
  found: Value read back correctly for 7 straight seconds, then was silently reset to the empty placeholder at second 8 — with NO drag, NO tap, no further interaction of any kind. Repeated: reproduced this way reliably.
  implication: This eliminates ALL gesture-based hypotheses at once. The trigger is pure elapsed wall-clock time. Also tested: delaying BEFORE opening Edit (5s sleep between duplicate and tapping the row) vs. delaying AFTER opening Edit (5s sleep after typing, before checking) — both reproduced equally, confirming it's simply "enough time must pass since the duplicate was inserted," not tied to any specific screen or gesture.

- timestamp: 2026-07-26
  checked: Whether "2 rows in History" alone (regardless of which one is edited) is sufficient, by repeating the same duplicate + 5s-delay + drag sequence but opening Edit on the OLDER (originally-seeded, already-persisted-before-this-session) row instead of the fresh duplicate.
  found: Survived cleanly, 3/3 runs. Editing the already-existing event never reproduces the reset, even with the identical delay and drag.
  implication: Confirms the freshly-inserted, not-yet-saved object specifically is required — not merely "the list has 2+ events." This is consistent with a `PersistentIdentifier` that is only unstable for objects inserted but not yet saved in this session.

- timestamp: 2026-07-26
  checked: Applied the fix — `try? context.save()` immediately after `context.insert(copy)` + `RecordDeduplicator.ensureUniqueIdentity(copy, in: context)` in `EventContextMenu`'s Duplicate action (`drinkpulse/Features/History/Components/EventContextMenu.swift`). Reverted the two earlier speculative changes (`.interactiveDismissDisabled()`, `.wheel` DatePicker style + `maxSelectableDate`) back to original via `git checkout` first, so only this one change remained. Rebuilt clean (zero warnings). Re-ran (a) the "no drag, just wait 8s" test — 3/3 clean; (b) the original literal user-matching repro (calendar overlay, pick a different day, outside tap, partial drag) — 5/5 clean; (c) the full existing History/AddDrink UI test suite (`HistoryInteractionUITests`, `EditVolumeIntegrityUITests`, `EditDeleteConfirmationUITests`, `HistoryUnitDisplayUITests`) — 12/12 passed, no regressions.
  found: Zero reproductions across all re-runs (8 total dedicated repro re-runs + 12 existing regression tests), where the identical sequence had a 100% reproduction rate (calendar-overlay repro) and a 100% reproduction rate (no-drag-just-wait, after 8s) immediately before this one-line fix.
  implication: ROOT CAUSE CONFIRMED AND FIXED. Grep of every other `context.insert(...)` call site in the app confirmed `DrinkDetailInputView.save()` (the Add-drink flow) is NOT affected by this same pattern — it inserts and dismisses in the same call, with no window where the user can sit editing an unsaved, freshly-inserted object via `.sheet(item:)`.

## Eliminated

- hypothesis: Typing in the Custom Name field causes `CustomNameSuggestionSection`'s dynamically shown/hidden suggestion rows to churn the enclosing `Form`'s layout while the sheet has `.presentationDetents([.large])` + `.presentationDragIndicator(.visible)` (Edit only), causing SwiftUI/UIKit to tear down and re-present the sheet and reset its `@State`.
  evidence: reproduction UI test typed a real prefix that provably triggered the suggestion row's appearance/disappearance, checked the sheet's nav bar and two independent field values (Custom Name, Notes) after every keystroke and at the end — nothing was lost, nav bar never disappeared. Directly contradicts the predicted observable of this hypothesis.
  timestamp: 2026-07-19

- hypothesis: Backgrounding/foregrounding the app (scenePhase change) while an Add/Edit sheet is open with unsaved edits causes the sheet or its `@State` to be torn down (possibly via the `onboardingDone`/`profiles.isEmpty` dual-source-of-truth in `RootShellView`, or general scenePhase-driven view identity churn).
  evidence: reproduction test sent the app to background via the Home button and reactivated it with the Edit sheet open and unsaved Custom Name/Notes values present; the sheet was still open and both values were intact afterward.
  timestamp: 2026-07-19

- hypothesis: Selecting a category in `EditDrinkTypeSelectionView` and returning resets unrelated form fields, mimicking "close and reopen with lost state."
  evidence: code read confirms the reset (`volumeMl`, `abvValue`, `icon`) only happens in `.onChange(of: category)` when `category`'s value actually changes — a deliberate, documented product decision (comment: "Category change is a deliberate edit"), and does not affect Notes/Price/Date/CustomName fields at all. Re-selecting the SAME category is a SwiftUI no-op (Equatable short-circuit).
  timestamp: 2026-07-19

- hypothesis: Duplicating a ConsumptionEvent and editing its date/time changes something (identity, sort position, or a derived @Query result) that causes `.sheet(item: $editingEvent)` to see its bound item go stale/re-bind to a "new" item.
  evidence: code read confirms `date` (and every other editable field) is a local `@State` written to the model ONLY inside `save()`, which runs only on Save-button tap — there is no live write for the DatePicker or any other field to trigger a `@Query` re-fetch or sort-order flip while editing. `duplicated()` also gives the copy a fresh, non-colliding `uuid`. There is no code path for an in-progress date edit to affect `HistoryListQueryView`'s or `HistoryView`'s `@Query` results before Save.
  timestamp: 2026-07-26

- hypothesis: EditEventView's/AddDrinkView's sheet has no `.interactiveDismissDisabled()`, so a drag gesture near the top of the Form is momentarily claimed by the sheet's own pan-to-dismiss gesture recognizer, and even a cancelled/incomplete interactive dismissal reconstructs the hosted view and drops local `@State`.
  evidence: applied `.interactiveDismissDisabled()` to both sheets and re-ran the identical repro sequence — the reset STILL reproduced (3 of 4 runs), i.e. no measurable improvement. Directly falsified.
  timestamp: 2026-07-26

- hypothesis: The DatePicker's `.compact`-style calendar-grid overlay (a private UIKit control) has its own internal gesture handling that conflicts with a drag starting inside it and crossing into the Form below, tearing down the sheet's content.
  evidence: switched both DatePickers to `.wheel` style (confirmed no overlay exists at all via `XCTAssertFalse(app.buttons["Previous Month"].exists)`), and the reset STILL reproduced via a drag starting inside the (unrelated, pre-existing) `.wheel`-style Serving pickers (volume/ABV/count) instead. The DatePicker was never the real trigger. Directly falsified; the style change and the `maxSelectableDate` stabilization were reverted.
  timestamp: 2026-07-26

## Resolution

root_cause: >
  `EventContextMenu`'s Duplicate action (`drinkpulse/Features/History/Components/EventContextMenu.swift`)
  called `context.insert(copy)` but never saved the context. A freshly-inserted, not-yet-saved
  SwiftData `@Model` object carries a TEMPORARY `PersistentIdentifier` that only becomes permanent
  once the `ModelContext` saves. `HistoryView`'s `.sheet(item: $editingEvent)` is keyed by that
  identifier (via `ConsumptionEvent`'s default `Identifiable` conformance). When the user opened
  Edit on the fresh duplicate and SwiftData's own autosave fired while the sheet was still open
  (empirically ~7-8 seconds after the insert, independent of any gesture — confirmed by a "no
  interaction at all, just wait" test), the identifier flipped from temporary to permanent, and
  SwiftUI read that as "a different item is now presented" — tearing down and reconstructing
  `EditEventView` fresh from the model, discarding every unsaved local `@State` field, while the
  sheet's own chrome (nav bar title) stayed visually unchanged. This is what the user experienced
  as "the sheet closes and reopens, and I lose everything I typed." Confirmed NOT to require any
  specific gesture, the DatePicker, or interactive dismiss (all three were tested as separate
  hypotheses and refuted — see Eliminated); confirmed to specifically require editing the
  freshly-inserted object itself (editing the older, already-persisted event with the identical
  delay never reproduced it). The Add-drink flow (`DrinkDetailInputView.save()`) is NOT affected:
  it inserts and dismisses in the same call, with no window where the user can sit editing an
  unsaved, freshly-inserted object.
fix: >
  Added `try? context.save()` in `EventContextMenu`'s Duplicate action, immediately after
  `context.insert(copy)` + `RecordDeduplicator.ensureUniqueIdentity(copy, in: context)` — so the
  duplicate's `PersistentIdentifier` is already permanent before the row is ever tappable, closing
  the temporary-identity window entirely. This is the only source change kept; two earlier
  speculative fixes (`.interactiveDismissDisabled()` on both sheets, switching the DatePicker to
  `.wheel` style) were tried, tested, found NOT to resolve the bug, and reverted to keep the change
  minimal and targeted at the confirmed mechanism.
verification: >
  Rebuilt clean (zero warnings). Re-ran the "no interaction, just wait 8s" isolation test (3/3
  clean, vs. 100% reproduction before the fix) and the original literal user-matching repro
  (duplicate -> edit -> calendar overlay -> pick a different day -> outside tap -> partial drag)
  (5/5 clean, vs. 100% reproduction before the fix). Ran the full existing History/AddDrink UI
  test suite (HistoryInteractionUITests, EditVolumeIntegrityUITests, EditDeleteConfirmationUITests,
  HistoryUnitDisplayUITests) — 12/12 passed, no regressions. Added a permanent regression test,
  `drinkpulseUITests/Features/History/DuplicateEditPersistenceUITests.swift`
  (`test_editFreshDuplicate_survivesPastAutosaveWindow`), which duplicates the seeded event, opens
  Edit on the fresh duplicate, enters a Custom Name marker, waits 10s, and asserts the sheet and
  the marker both survive — this test FAILED reliably against the pre-fix code and PASSES against
  the fix. Self-verification complete; awaiting the user's own confirmation in their real workflow
  (see checkpoint).
files_changed:
  - drinkpulse/Features/History/Components/EventContextMenu.swift
  - drinkpulseUITests/Features/History/DuplicateEditPersistenceUITests.swift (new, permanent regression test)
human_verification: >
  2026-07-27 — user confirmed the bug no longer reproduces in their real workflow
  (duplicate an entry, open Edit on the fresh copy, edit a field, set a new
  date/time, wait past the autosave window). Session closed. Fix shipped in
  commit 084b1fe "fix: save duplicated event immediately to close temp-identifier
  race"; the permanent regression test
  (DuplicateEditPersistenceUITests.test_editFreshDuplicate_survivesPastAutosaveWindow)
  guards it going forward.

## Follow-ups NOT closed by this fix

Two items surfaced during the investigation that are real but out of scope of the
fix, deliberately left un-actioned rather than silently dropped:

1. `RootShellView.swift`'s dual source of truth for onboarding — persisted
   `onboardingDone` vs. live `profiles.isEmpty`, wired through
   `.onChange(of: profiles.isEmpty) { if isEmpty { onboardingDone = false } }`.
   If `profiles` ever transiently reports empty, the ENTIRE `RootShellView` (and
   any open sheet under it) is torn down in favour of `OnboardingView`. No code
   path was found that triggers this during normal use, so it is NOT this bug —
   but it remains a fragile pattern worth hardening.
2. Other `context.insert(...)` call sites were only spot-checked by targeted grep,
   not audited exhaustively for the same insert-without-save latent pattern.
   `DrinkDetailInputView.save()` was checked and is safe (insert and dismiss
   happen together, leaving no window where the user edits an unsaved object
   through `.sheet(item:)`).
