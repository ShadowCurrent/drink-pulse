# 0048 — Execution journal

Append-only. Dated entries.

## 2026-11-25 — Setup

- Plan frozen (`3000103`). Branch `port/0048-onboarding`, main checkout, Xcode MCP workspace
  `drinkpulse.xcodeproj` (identifier resolved with `XcodeListWorkspaces`). The active destination
  was the physical iPhone; switched to the iPhone 18 Pro simulator (iOS 27.2) with
  `XcodeSwitchRunDestination` before any build or test.
- Executor: superpowers `executing-plans`, inline.
- As in plans 0046 / 0047: reading source uses read-only shell `cat` / `grep`; builds, tests and
  previews go through Xcode MCP. Bulk test-file edits use small scripts; production edits use
  `XcodeUpdate` / `XcodeWrite`. `Localizable.xcstrings` values are set with a JSON script that
  keeps Xcode's format (English only, so `StringCatalogEdit`'s translation workflow does not fit).

## 2026-11-25 — Task 1: required sex, reachable pages, one completion

Docs (Xcode MCP `DocumentationSearch`, SwiftData):
- `ModelContext.insert(_:)`: "Registers the specified model with the context so it can include
  the model in the next save operation."
- `ModelContext.save()` / `autosaveEnabled`: the main context saves implicitly; the explicit save
  keeps the profile durable before the cover dismisses. The old `try?` became a `do / catch` that
  logs the error type only (`Logger`, category `Onboarding`).

Done:
- `canContinueProfile` (`sex != nil`), `reachableSteps` (`sex == nil ? 2 : 4`),
  `private(set) var isCompleted`, `complete(into:)` guarded by `guard let sex, !isCompleted`.
- Tests: `completeWithNoSelectionsInsertsDefaultProfile` replaced by
  `completeWithoutSex_insertsNothing`; new `canContinueProfile_falseUntilSexChosen`,
  `reachableSteps_isTwoWithoutSex_fourWithSex`, `completeTwice_insertsOneProfile`. Every other
  test that calls `complete` now sets `vm.sex = .male` first.
- RED: the test target failed to compile (no `isCompleted`, `canContinueProfile`,
  `reachableSteps`). GREEN: `OnboardingViewModelTests` 20/20 passed.

## 2026-11-25 — Task 2: header, layout, heading, shared choice row

Docs (Xcode MCP `DocumentationSearch`):
- `PrimitiveButtonStyle.glass` / `.glassProminent` ("applies a (prominent) Liquid Glass effect
  based on the button's context"); `ButtonBorderShape.circle` with `buttonBorderShape(_:)`.
- HIG Buttons › Style: "use a button that has a prominent visual style for the most likely action
  in a view … one or two per view". HIG Materials › Liquid Glass: "Don't use Liquid Glass in the
  content layer"; standard surfaces for content (hence `BrandSurface` cards, not glass).
- `View.hidden()`: "Hidden views are invisible and can't receive or respond to interactions.
  However, they do remain in the view hierarchy and affect layout."

Done:
- New `Components/OnboardingHeader.swift` (glass circle Back, 32 pt frame, always laid out),
  `OnboardingHeading.swift`, `OnboardingCard.swift`; `GuidelineChoiceRow.swift` moved with
  `XcodeMV` to `OnboardingChoiceRow.swift` (`title:detail:isSelected:identifier:action:`).
- `OnboardingStepLayout`: `isEnabled`, `.glassProminent` + `.controlSize(.large)`.
- `OnboardingView`: `ForEach(0..<vm.reachableSteps)`, Frost backdrop, `sex: vm.sex ?? .female`
  for the unreachable guideline page (commented).
- `GuidelineStep`: `OnboardingHeading` + `OnboardingCard` of `OnboardingChoiceRow`s (identifiers
  `guidelineChoiceRow.<raw>` unchanged).
- Renders: Welcome Light, Guideline Dark and AX5 checked (`RenderPreview`, iPhone 18 Pro).

Deviations and findings:
- **`brandBackground()` not used on the onboarding root.** It is
  `containerBackground(for: .navigation)`, which fills an enclosing NavigationStack; onboarding has
  none. The root uses `.background { BrandBackdrop().ignoresSafeArea() }` (as the prototype) plus
  `.groupBoxStyle(BrandCardStyle())`.
- **`OnboardingCard` added** (not in the plan's file list): the prototype's card container, shared
  by the guideline list, the AX sex rows and the Health toggles (D0048-10).
- **Back button hide.** `opacity(0)` + `disabled` + `accessibilityHidden(true)` (on the HStack and
  then on the button) left the disabled glass Back in the accessibility tree on step 1
  (`test_backButton_returnsToPreviousStep` failed; XCUI dump: `Button 'Back', Disabled` at
  16,82 46×46). Fixed with `if step > 0 { backButton } else { backButton.hidden() }`, which keeps
  the header height. The test now waits for non-existence (3 s) instead of an instant `exists`.
- **D0048-18 (owner, 2026-11-25): glass primary button + audit exemption.** With `.glassProminent`
  the Welcome standard audit reports one element-less `contrast` issue; with `.borderedProminent`
  the same audit passes, and a `.headline` label did not help. Owner: keep the glass button for a
  uniform UI and exempt that exact finding. `OnboardingAuditExemptions.glassPrimaryButton`
  (UI tests) passes only `contrast` issues with no element, through the existing
  `exemptSystemControl` hook, which records each as a warning. Device check with Accessibility
  Inspector stays on the owner list.
- Run: `OnboardingFlowUITests` + `OnboardingAccessibilityAuditUITests` 5/5 passed (About You
  still had the old picker).
