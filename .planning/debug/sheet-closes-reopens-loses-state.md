---
status: investigating
trigger: "Bug: edit-drink sheet (possibly add-drink too) closes and reopens while filling form. Loses entered state, user must re-enter data."
created: 2026-07-19
updated: 2026-07-19
---

## Symptoms

- Expected: sheet (Add/Edit drink) stays open and preserves entered field values while user fills it in.
- Actual: while filling in form data, the presented sheet appears to dismiss and re-present itself, resetting entered field state. User has to re-enter data.
- Trigger pattern: unknown/not identified by user. Not obviously tied to a specific field, picker, or keyboard action.
- Timeline: user reports this has "always" happened (not a new regression from the most recent change, per user, though most recent branch work was `quick-260719-nm6` — custom name autocomplete/suggestions on Add/Edit screens).
- Scope: primarily observed in Edit mode; user believes Add mode may also be affected but is not fully certain whether it's Edit-only, Add-only, or both.
- Errors: none checked yet — user has not inspected Xcode console/logs during the repro.
- Reproduction: not reliably reproducible; described as happening "randomly," no fixed steps identified yet.

## Current Focus

hypothesis: (all leading hypotheses eliminated with direct evidence; root cause not yet found)
test: (none running — awaiting more diagnostic detail from user, see checkpoint)
expecting: (pending)
next_action: CHECKPOINT — request additional diagnostic detail from user next time the bug occurs (see checkpoint returned to orchestrator). If/when new detail arrives, resume investigation from that lead. Do NOT re-test the three eliminated hypotheses below without new evidence.

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
