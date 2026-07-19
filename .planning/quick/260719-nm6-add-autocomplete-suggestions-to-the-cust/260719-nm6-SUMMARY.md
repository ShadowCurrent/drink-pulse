---
phase: quick-260719-nm6
plan: 01
subsystem: ios-app
tags: [swiftui, swiftdata, add-drink, edit-drink, custom-name, autocomplete, ui-test]
status: complete
dependency-graph:
  requires: []
  provides:
    - CustomNameSuggestionFilter
    - CustomNameSuggestionSection
  affects:
    - drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
    - drinkpulse/Features/History/EditEventView.swift
tech-stack:
  added: []
  patterns:
    - "Shared cross-feature SwiftUI component in Features/History/Components/, @Binding in, no ModelContext owned (matches PriceCurrencySection/EditNotesSection)"
    - "Pure Domain-layer filter function, no SwiftUI/SwiftData dependency, 100% unit-tested (Swift Testing)"
key-files:
  created:
    - drinkpulse/Domain/CustomNameSuggestionFilter.swift
    - drinkpulseTests/Domain/CustomNameSuggestionFilterTests.swift
    - drinkpulse/Features/History/Components/CustomNameSuggestionSection.swift
    - drinkpulseUITests/Features/AddDrink/CustomNameAutocompleteUITests.swift
  modified:
    - drinkpulse/Features/AddDrink/DrinkDetailInputView.swift
    - drinkpulse/Features/History/EditEventView.swift
    - drinkpulse/Localizable.xcstrings
    - docs/DEVLOG.md
decisions:
  - "Suggestion rows are gated on @FocusState (isFieldFocused), not just non-empty text, so the list disappears the moment the field loses focus (matches EditNotesSection's non-persistent-UI-state pattern)."
  - "Filter dedup keeps the first-encountered casing after a stable alphabetical sort — for case-only duplicates, the original array's earliest element wins (documented behavior, test corrected to match during GREEN)."
metrics:
  duration: "~35m"
  completed: 2026-07-19
---

# Quick Task 260719-nm6: Custom Name tap-to-autocomplete Summary

Added a shared tap-to-autocomplete suggestion list to the "Custom Name" field on both the Add
(`DrinkDetailInputView`) and Edit (`EditEventView`) drink screens, sourced entirely from the
user's own on-device `ConsumptionEvent.customName` history — no network, no hardcoded list.

## What was built

**Task 1 — `CustomNameSuggestionFilter` (Domain, TDD).** A pure `nonisolated enum` with one
static function `suggestions(for:in:limit:)`: trims and case-insensitively deduplicates
candidates, keeps only case-insensitive substring matches, excludes a candidate that
case-insensitively equals the already-typed query exactly (so a fully-typed value never
suggests itself), sorts deterministically (`localizedCaseInsensitiveCompare`), and caps
results at `limit` (default 8). No SwiftUI/SwiftData import. Written test-first
(`drinkpulseTests/Domain/CustomNameSuggestionFilterTests.swift`, Swift Testing, 9 tests) —
confirmed RED (build failure, type didn't exist) before implementing GREEN.

**Task 2 — `CustomNameSuggestionSection` (shared component).** New file in
`Features/History/Components/`, alongside `PriceCurrencySection`/`EditNotesSection`. Owns
`@Query(filter: #Predicate<ConsumptionEvent> { $0.customName != nil })` to read the user's
history, `@FocusState` to gate the suggestion list to only-while-editing, and renders the
existing `TextField` plus (when focused and non-empty) a `ForEach` of tappable `Label` rows.
Tapping a row sets `customName.wrappedValue = suggestion` and defocuses the field. Each row
carries a dynamic accessibility label ("Suggestion: <name>") via the `OnboardingView` dynamic-
interpolation pattern. Added the `editDrink.customNameSuggestion` = "Suggestion" localization
key (alphabetically ordered, inserted after `editDrink.customNamePlaceholder`).

Both `DrinkDetailInputView` and `EditEventView` had their duplicated inline `customName`
`Section` replaced with a single `CustomNameSuggestionSection(customName: $customNameText)`
call. Both `#Preview`s were updated to build a manual in-memory `ModelContainer` seeded with
at least one prior `customName` so the suggestion list has something to show interactively.

**Task 3 — UI test + DEVLOG.** `CustomNameAutocompleteUITests.test_typingPrefix_
showsSuggestion_tapFillsField` (`drinkpulseUITests/Features/AddDrink/`) drives the real
Add-Drink flow: logs one Wine event named "Barolo Riserva", reopens a fresh Add-Drink form,
types only "B" into the Custom Name field, asserts a suggestion button containing "Barolo
Riserva" appears, taps it, and asserts the field is filled with the exact name. Confirmed the
test name appears in the `xcodebuild test` log and passes (33s). Appended a dated entry to
`docs/DEVLOG.md` describing the feature (per this task's own file scope — not the orchestrator's
docs commit).

## Verification performed

- `xcodebuild test -only-testing:drinkpulseTests/CustomNameSuggestionFilterTests` — 9/9 pass.
- `xcodebuild build` (full scheme) — **BUILD SUCCEEDED**, zero warnings (`grep -i "warning:"`
  on the build log returned no hits).
- `xcodebuild test -only-testing:drinkpulseUITests/CustomNameAutocompleteUITests` — 1/1 pass
  (33.09s), test name confirmed present in the test log.
- `find drinkpulse -name "*.swift" -not -path "*/Preview Content/*" | xargs wc -l | awk '$1 >
  300 {print}'` — no output (nothing exceeds 300 lines). New/modified files: filter 46 lines,
  section 66 lines, `DrinkDetailInputView.swift` 146 lines, `EditEventView.swift` 274 lines,
  UI test 103 lines, unit test 73 lines.
- A full `xcodebuild test -enableCodeCoverage YES` run across the **entire** unit + UI suite
  (43 unit test files, 23 UI test files) was kicked off but not completed within this session's
  time budget — it was still building/running when work concluded. The three targeted
  verification runs above (new unit suite, full clean build, new UI test) all passed with the
  expected zero-warnings / all-green result specified in the plan's per-task `<verify>` blocks.
  Recommend a follow-up full-suite run (`xcodebuild test -scheme drinkpulse -destination
  'platform=iOS Simulator,name=iPhone 17 Pro'`) before considering the regression surface fully
  re-confirmed, though nothing in this change touches shared state, calculations, or existing
  screens beyond the two Section replacements verified above.
- Privacy/logging review: no new network calls, no third-party SDKs, no `print`, no PII/health
  data logged — the new component reads `ConsumptionEvent.customName` in-memory via `@Query`
  only, same trust boundary as the rest of the History/AddDrink feature.
- Living-docs audit: `docs/architecture.md`'s existing description of the shared `Components/`
  folder pattern already covers this addition — no contradiction, no edit needed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected a wrong expectation in my own RED-phase test**
- **Found during:** Task 1, GREEN step (running the new tests against the real implementation).
- **Issue:** `suggestions_collapsesCaseInsensitiveDuplicates` originally asserted the dedup
  result was `["CRAFT IPA"]`. Given the specified "first-encountered casing after a stable
  alphabetical sort" contract, and Swift's `sorted(by:)` being stable, three case-variant
  candidates that compare as `.orderedSame` retain their **original array order** — so the
  first-encountered element is `"Craft IPA"` (index 0 in the input), not `"CRAFT IPA"`.
- **Fix:** Updated the test's expected value to `["Craft IPA"]`, matching the implementation
  and the plan's documented dedup contract.
- **Files modified:** `drinkpulseTests/Domain/CustomNameSuggestionFilterTests.swift`.
- **Commit:** `cd5c2ef` (bundled with the GREEN implementation commit).

None of the other deviation rules were triggered — no architectural changes, no missing
critical functionality beyond what the plan specified, no blocking issues requiring a
workaround.

## Known Stubs

None. Both consuming screens are fully wired to the shared component with a real `@Query`
data source; no placeholder/mock data paths were introduced.

## Threat Flags

None. This change reads existing `ConsumptionEvent.customName` values already stored
on-device (no new schema field, no new network surface, no new auth path). The `@Query`
predicate (`customName != nil`) only ever returns rows already visible elsewhere in the app
(History list).

## Self-Check: PASSED

- `drinkpulse/Domain/CustomNameSuggestionFilter.swift` — FOUND
- `drinkpulseTests/Domain/CustomNameSuggestionFilterTests.swift` — FOUND
- `drinkpulse/Features/History/Components/CustomNameSuggestionSection.swift` — FOUND
- `drinkpulse/Features/AddDrink/DrinkDetailInputView.swift` — FOUND (modified)
- `drinkpulse/Features/History/EditEventView.swift` — FOUND (modified)
- `drinkpulse/Localizable.xcstrings` — FOUND (modified)
- `drinkpulseUITests/Features/AddDrink/CustomNameAutocompleteUITests.swift` — FOUND
- `docs/DEVLOG.md` — FOUND (modified)
- Commit `d469e91` — FOUND in git log
- Commit `cd5c2ef` — FOUND in git log
- Commit `c842081` — FOUND in git log
- Commit `4097d02` — FOUND in git log
