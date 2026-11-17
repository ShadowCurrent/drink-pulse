---
phase: 11-ios-27-release-verification
plan: 18
subsystem: accessibility
tags: [accessibility-audit, contrast, text-clipped, xcuitest, gap-closure, add-drink]
status: complete
requires: [11-17]
provides:
  - ungated Add Drink audit class AddDrinkAccessibilityAuditUITests (standard light, AX5 light; all audit types; launch viewport), green on two consecutive runs
  - drink-type emoji drawn as a decorative image (DecorativeEmoji), one combined accessibility element per tile
  - Add Drink Cancel button fixed app-side at the default size (system close glyph) and at AX5 (primary tint on an opaque bottom bar)
affects: [11-19, 11-20, 11-21, 11-22]
tech-stack:
  added: []
  patterns:
    - "Decorative pictograms (emoji) are rendered once with ImageRenderer and shown with Image(decorative:scale:), sized by a @ScaledMetric relative to the text style they replace"
    - "A plain-style Button whose label holds an image and a text uses .accessibilityElement(children: .combine) on the label content, so the text keeps its own accessibility frame"
key-files:
  created:
    - drinkpulseUITests/Features/AddDrink/AddDrinkAccessibilityAuditUITests.swift
    - drinkpulse/Features/AddDrink/Components/DecorativeEmoji.swift
  modified:
    - drinkpulse/Features/AddDrink/Components/DrinkTypeTile.swift
    - drinkpulse/Features/AddDrink/DrinkTypeGrid.swift
    - drinkpulse/Features/AddDrink/DrinkTypeGridView.swift
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md
key-decisions:
  - "Drink-type emoji are decorative pictograms: drawn as an unlabelled decorative image instead of Text. Visual output is unchanged; the audit's text contrast and clipping checks no longer apply to them (executor decision, flagged for owner review)"
  - "Toolbar Cancel uses Button(role: .cancel), which iOS 27 shows as the system close glyph; the text-label Cancel (with or without the role) kept a contrast finding on the system glass button"
metrics:
  duration: "about 60 min on 2026-11-17 (10:35Z to 11:35Z)"
  completed: 2026-11-17
actuals:
  tokens: 2100
  tasks: 2
  commits: 3
plan_head_before: ea81edf429493c46256e3209f21a2c91ab68ba5b
plan_head_after: b303647a288b7c3ccee2eea06db84fce1e0de33c
requirements-completed: []
---

# Phase 11 Plan 18: Add Drink accessibility audit findings Summary

The Add Drink sheet (step 1) now has no audit finding of any type at the default text size and at AX5. Two consecutive runs of the new ungated all-types audit class are green. The drink-type emoji is now a decorative image, each tile is one accessibility element, and the Cancel button was fixed in the app at both sizes. Nothing was muted, filtered or hidden. D11-29 was not used, because the sheet covers the tab bar.

## Outcome

- Tasks: 2 of 2 done. Requirements VER-03 and VER-01 stay open, because other screens, G-2 and DL-O19 are still open.
- Runner: Xcode MCP only (BuildProject, GetBuildLog, RunSomeTests, RenderPreview, XcodeRefreshCodeIssuesInFile, DocumentationSearch). No CLI xcodebuild was used, and the scheme was not edited.

### Audit key counts (light mode, harness with `-dp_color_scheme system`)

| Run | File | Result | Raw issue lines | Distinct keys (`LC_ALL=C sort -u`, variant+type+element) |
| --- | ---- | ------ | --------------- | --------------------------------------------------------- |
| Task 1 red (light baseline re-measured) | `add-t1-red.result.txt` | 2 failed | 57: standard contrast 32, standard textClipped 16, ax5 contrast 9 | 3 |
| Task 1 after | `add-t1-after.result.txt` | 2 passed | 0 | 0 |
| Task 2 run 1 | `add-t2-run1.result.txt` | 2 passed, 0 failed, 0 skipped | 0 | 0 |
| Task 2 run 2 | `add-t2-run2.result.txt` | 2 passed, 0 failed, 0 skipped | 0 | 0 |

- Every red issue had the element key `none#type=nil`. The audit names only `SwiftUI.AccessibilityNode`, with no element or frame. So the 11-13 named keys (`Beer`, `Cancel`, and so on) no longer appear in light mode; those were dark-mode measurements (11-17 deviation 1).
- Dark mode: the plan's class has no dark variant (dark is covered by human check CHK-08). No dark measurement was made in this plan. The 11-13 Add Drink rows (standard 68 and ax5 47 reports) were dark-mode measurements and are superseded for light mode by the row above.
- D11-29 ignored-issue count: not used (0). The sheet covers the tab bar, so the class does not opt in.
- Target keys (`add-t1-target-keys.txt`): `type=contrast element=none#type=nil`, `type=textClipped element=none#type=nil`. Both are present in the red file (57 matches) and absent in the after file.

### Root cause, found by elimination (temporary diagnostic test, deleted and never committed)

The issues carry no element, so they were located by changing one thing at a time and re-running the audit. Each experiment was reverted.

| Experiment | standard | ax5 | Conclusion |
| ---------- | -------- | --- | ---------- |
| baseline | 32 contrast, 16 textClipped | 9 contrast | |
| emoji removed | 1 contrast | 1 contrast | the emoji causes 31 contrast and all 16 textClipped at standard, and 8 contrast at ax5 |
| no tiles at all | 1 | 1 | the remaining 1 is not in the grid |
| Home empty, tab bar hidden, This Week card removed | 1 | 1 | the sheet's background content is not the source |
| sheet actions removed | 0 | 0 | the remaining 1 is the Cancel button at each size |
| merged tile (`.accessibilityElement(children: .ignore)` on content) | 15 contrast, 16 textClipped | 8 | the name text frame became its own; the emoji still failed |
| `accessibilityRepresentation` button | 16 named contrast, 4 dynamicType | 4 | moves the findings onto the tile; rejected |
| emoji as decorative image, names removed, Cancel fixes | 0 | 0 | images are not text-audited; the Cancel fixes work |
| emoji as decorative image, names kept, no combine | 18 contrast, 1 textClipped | 2 | the name's accessibility frame spans the whole tile, so its contrast is measured against the emoji |

Root causes:
1. The decorative emoji was a `Text` hidden from VoiceOver. The pixel checks still treated it as text, and multicolour emoji glyphs cannot meet text contrast. At the default size each emoji was also reported as `textClipped` in its square tile.
2. Inside the plain-style tile `Button`, the name `Text` had an accessibility frame equal to the whole tile. Its contrast was therefore sampled over the emoji pixels.
3. "Champagne" was shrunk by `minimumScaleFactor(0.75)`, which the audit reports as `textClipped`.
4. The toolbar text Cancel on the iOS 27 glass button gave 1 contrast finding. A text label with `role: .cancel` still failed.
5. The AX5 bottom-bar Cancel (accent tint, `.bordered`) failed contrast. The rows that scroll under it also showed through its translucent fill (screenshot: "Alcopop" blurred behind "Cancel").

## Findings fixed per view

| View | Fix |
| ---- | --- |
| `DrinkTypeTile` | The emoji is drawn by `DecorativeEmoji` (new). The tile content has `.accessibilityElement(children: .combine)`, so the name keeps its own frame. The square layout no longer uses `minimumScaleFactor(0.75)`/`lineLimit(2)`: the name uses `fixedSize(horizontal: false, vertical: true)`, and horizontal padding is 8 pt instead of 16 pt, so "Champagne" fits at full size. |
| `DrinkTypeGrid` | The redundant `.accessibilityLabel(preset.name)` was removed. The combined element takes its label from the name text, which is identical. The `.isSelected` trait is kept. |
| `DrinkTypeGridView` (`SheetActionsModifier`) | The toolbar Cancel is `Button(role: .cancel, action:)`. The AX bottom-bar Cancel has `.tint(.primary)`, and the bar content has an opaque `.background(.background)`. |

- G02 stop rule: not triggered. App-side changes removed both Cancel findings.
- No `accessibilityHidden` was added. The one removed `.accessibilityHidden(true)` was on the emoji `Text`, which no longer exists; `Image(decorative:)` is unlabelled by API. Nothing was muted, no audit type was excluded, and no text size was capped.
- Shared color tokens: none changed. `DPColors`, `DPSemanticColors`, `RiskLevel+Color` and the asset catalog are untouched by this plan.
- `Localizable.xcstrings`: unchanged. The `role: .cancel` button uses the system label.

## Regular-size visual changes (owner-visible)

- **Toolbar Cancel is now the system close glyph (an "x" in a glass circle) instead of the word "Cancel".** This is on Add Drink step 1 and also on step 2, because both use `SheetActionsModifier`. The accessibility label stays "Cancel": the UI tests find `app.buttons["Cancel"]` and the VoiceOver Cancel test passes.
- Tile names are no longer scaled down. "Champagne" now renders at full subheadline size, and the tile horizontal padding is 8 pt instead of 16 pt.
- The emoji look the same. They are the same glyphs at the same `.largeTitle`-scaled size, drawn as images.
- At accessibility sizes only: the bottom-bar Cancel is primary (black or white) on gray instead of accent orange, and the bar has an opaque background.

## DL-O19 outcome

DL-O19 is still open and not fixed. These are the step 2 placeholders "Optional name" and "Price (optional)", truncated at AX5.
- Reason: this plan's must_haves allow production changes only in the Add Drink step 1 views, and the placeholders live in step 2 (`DrinkDetailInputView`).
- The ledger row records this. Its Status is unchanged ("open").
- A later plan or an owner decision must take it. A likely technique is `TextField(..., axis: .vertical)` so the placeholder wraps. That is untested.

## Tests

| Run | File | Result |
| --- | ---- | ------ |
| Add Drink audit, Task 1 red | `add-t1-red.result.txt` | 0/2 passed (57 issue reports) |
| Add Drink audit, Task 1 after | `add-t1-after.result.txt` | 2/2 passed |
| Add Drink audit run 1 (final code) | `add-t2-run1.result.txt` | 2/2 passed |
| Add Drink audit run 2 (final code) | `add-t2-run2.result.txt` | 2/2 passed |
| Regression: AddDrinkDynamicTypeUITests 2, AddDrinkFlowUITests 6, AddDrinkPickerFilterUITests 1, CurrencyUITests 2, CustomNameAutocompleteUITests 1, VolumeServingUITests 2, HealthWriteHooksUITests 4, ShellNavigationUITests 4, DashboardAccessibilityAuditUITests 3 | `add-t2-regression.result.txt` | 25 passed, 0 failed |
| Regression re-run after the preview fix (AddDrinkDynamicType 2, AddDrinkFlow 6, ShellNavigation 4) | `add-t2-regression-final.result.txt` | 12 passed, 0 failed |
| Token regression: DashboardDynamicType 2, HistoryAccessibilityAudit 2, HistoryDynamicType 1, InsightsDynamicType 2, SettingsDynamicType 2, OnboardingDynamicType 4, InsightsUITests 7, SettingsUITests 5 | `add-t2-tokens.result.txt` | 24 passed, 1 failed: only the known-list DL-T01 `InsightsUITests/test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` (tolerated) |

- The token regression ran even though this plan changed no token. The plan's verify condition is true because of the 11-17 token changes since fc506f4.
- Home (D11-29) in the regression run ignored 1 issue per variant: standard `This Week`, dark `This Week`, ax5 `100%`. Each run had `tabBarFound=true`. This is the same as 11-17.
- `add-t2-run1/run2-superseded.result.txt` are the first two green runs, both 2/2. They ran before the last commit, which removed the hard scroll-edge modifier; they were then repeated on the final code.
- Build: Xcode MCP `BuildProject` (buildForTesting) succeeded. `GetBuildLog` at warning severity returned 0 entries. `XcodeRefreshCodeIssuesInFile` found 0 issues on DecorativeEmoji, DrinkTypeTile, DrinkTypeGridView and the audit test.
- Guards: both Task verify commands printed `ok`. These cover the allowed production-file set, the schema guard against fbd37fa, and the 300-line limit (largest touched file: DrinkTypeTile.swift, 78 lines).
- Previews: `RenderPreview` of AddDrinkView (light standard; dark AX5) and of DrinkTypeGridView (AX5) rendered.

Evidence digests (stamp directory `20261114T121519Z`, out of git), sha256:
- `add-t1-red.result.txt` `9094a093239acd74309a4bac45fb9443717d9f4af5b4a6d0d1e0928144ba7186`
- `add-t1-target-keys.txt` `f78f381aa9b93d6ee6fb06fda3331fabe4406d47eefaac304d3cf2ec31f170de`
- `add-t1-after.result.txt` `d3971af7eb06a4850ce9993212248575c3b8afb188027d4a45bd8dfef61c3e33`
- `add-t2-run1.result.txt` `a4c39e20a838bbf784fcacb2d56f1e46e2463f752430575a35ac961ddfc1f30b`
- `add-t2-run2.result.txt` `e9a297aedc96b6671a4ae128b99e7d6cdc13a4eb72c321a75e1f4a7ff82b86e0`
- `add-t2-regression.result.txt` `1265c5eb154e11cd8e73d22b54e376dfa231217a8f7f29d822bc231a8e3e93db`
- `add-t2-regression-final.result.txt` `04060549b2c3032b62668792aff2b2615bd90cdd52fb7ba618d86cfe6a8355d8`
- `add-t2-tokens.result.txt` `ae33ee1b7e1d789ad40005aa2e80e1335d68dbde5a26950e8f81643c287312e2`

## Deviations from Plan

**1. [Rule 1 - Bug] Task 1 also fixed the Cancel button**
- The red keys are all `none#type=nil`, and the Cancel findings share that key. The verify rule "no target key remains after Task 1" could therefore only pass once the Cancel was fixed too.
- The Task 1 after file was measured with the Task 2 Cancel fix already in the tree. Commits stay split by task:
  - 83a4efb: tiles plus the test class
  - 47a1b68: Cancel

**2. [Technique outside the plan's list, flagged for owner review] Emoji drawn as a decorative image**
- The plan expected the emoji finding to be fixed "by the tile layout or by merging it into the tile's single accessibility element".
- Both were tried and did not clear it. With merging (`.ignore`), the emoji still produced 15 contrast and 16 textClipped. The layout change kept textClipped.
- The emoji is now rendered with `ImageRenderer` and shown as `Image(decorative:)`. It looks the same, VoiceOver behaviour is the same (unlabelled before, unlabelled now), and it scales with Dynamic Type.
- Rationale: the emoji is a pictogram, not text, and the name carries its meaning. WCAG exempts decorative content from contrast.
- This is not a mute: no audit type is excluded and nothing is hidden from accessibility. It does change what the audit measures for the emoji. If the owner disagrees, revert `DecorativeEmoji` and the G01 emoji findings return.

**3. [Rule 1 - Bug] Preview regression fixed (b303647)**
- The conditional `.scrollEdgeEffectStyle(isAccessibilitySize ? .hard : nil, for: .bottom)` broke the DrinkTypeGridView preview thunk ("ambiguous use of '__designTimeSelection'"). The same preview rendered with the pre-plan file.
- The modifier was removed. The opaque bar background alone keeps AX5 green, as the final runs show.

**4. [Scope] DL-O19 not fixed:** see above.

## Apple API record

| API | Source consulted (Xcode MCP DocumentationSearch) | Availability | Rationale |
| --- | ------------------------------------------------ | ------------ | --------- |
| `ImageRenderer` (`init(content:)`, `scale`, `cgImage`) | SwiftUI, "ImageRenderer": "An object that creates images from SwiftUI views ... You can also render standard SwiftUI views like Text views"; "init(content:)" is `@MainActor` | SwiftUI, iOS 16+ (project minimum iOS 27) | Rasterizes the emoji glyph once per size so it can be shown as an image |
| `Image(decorative:scale:)` | SwiftUI Image (decorative initializers create an unlabelled image that accessibility ignores) | SwiftUI, all supported OS | The emoji is decorative; same VoiceOver behaviour as the former hidden Text |
| `@ScaledMetric(relativeTo:)` | SwiftUI ScaledMetric | SwiftUI | Keeps the emoji size following `.largeTitle` Dynamic Type scaling |
| `accessibilityElement(children:)`, `AccessibilityChildBehavior.combine` | SwiftUI, "combine": "Use this behavior when you want a view represented by a single accessibility element. The new accessibility element merges properties from all non-hidden children" | SwiftUI | One element per tile with the name as label; the name text keeps its own frame (verified in the element tree) |
| `AccessibilityChildBehavior.ignore` | SwiftUI, "ignore": "A new accessibility element is always created" | SwiftUI | Tried (experiment); not kept |
| `accessibilityRepresentation(representation:)` | SwiftUI, "Replaces one or more accessibility elements for this view with new accessibility elements" | SwiftUI | Tried (experiment); rejected because it only moved the findings |
| `Button(role:action:)`, `ButtonRole.cancel` | SwiftUI, "init(role:action:)": "the following view would display a button with a 'x' symbol in the toolbar"; "cancel": "A role that indicates a button that cancels an operation" | SwiftUI (iOS 26+ glyph behaviour) | System close glyph in the toolbar; clears the toolbar Cancel contrast finding |
| `ToolbarItem(placement: .cancellationAction)` | unchanged placement | SwiftUI | Kept |
| `tint(_:)`, `.bordered` button style | PrimitiveButtonStyle "bordered" | SwiftUI | Primary tint gives the AX bottom-bar Cancel a high-contrast label |
| `safeAreaBar(edge:alignment:spacing:content:)` | SwiftUI: "extends the edge effect of any scroll views affected by the inset safe area" | SwiftUI, iOS 26+ | Unchanged; its content now has an opaque `background(.background)` so rows do not show through |
| `scrollEdgeEffectStyle(_:for:)` | SwiftUI: "Configures the scroll edge effect style for scroll views within this hierarchy" | SwiftUI, iOS 26+ | Tried, then removed (preview regression, not needed) |
| `XCUIApplication.performAccessibilityAudit(for:_:)`, `XCUIAccessibilityAuditType.all` | as recorded in 11-17 | XCUIAutomation | Shared helper `assertNoAuditIssues`, unchanged |
| `XCUIDevice.appearance` | as recorded in 11-17 (`pinAppearance`) | iOS | Light appearance pinned per test |

## Known Stubs

None. The scan of the diff against ea81edf for TODO, FIXME, placeholder, `print(`, Logger and URLSession found 0 matches.

## Threat Flags

None. No network, file, auth or schema surface was added.
- T-11-58: nothing is hidden; no token changed, and the token regression ran anyway.
- T-11-59: two consecutive green runs, both saved.

## Notes for later plans

- 11-22 (final gated re-run): the gated `AccessibilityAuditUITests` Add Drink methods audit the same sheet and should now be clean in light mode. Their dark variants are not in this plan's class.
- The toolbar Save button of Add Drink step 2 is a text button on the same system glass. It may show the same contrast finding the text Cancel had. Step 2 is not audited for contrast by any class.
- The pre-existing preview thunk sensitivity in `SheetActionsModifier` is worth knowing: a ternary with `nil` in its modifier chain breaks the preview build.

## Self-Check: PASSED

- Files exist: `AddDrinkAccessibilityAuditUITests.swift`, `DecorativeEmoji.swift`.
- Commits 83a4efb, 47a1b68 and b303647 are ancestors of HEAD.
- The temporary diagnostic test was deleted and never committed: `git log` has no `TempAddDrinkAuditDiag` path.
