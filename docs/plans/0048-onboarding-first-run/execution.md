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

## 2026-11-25 — Task 3: About You, Welcome, Health; copy; UI tests choose a sex

Docs (Xcode MCP `DocumentationSearch`):
- `Picker(_:selection:content:)` with `tag(_:)`: the `Optional(option)` tags let a `nil` selection
  show no segment selected (also the prototype's accepted pattern, round 19).
- `DatePicker` with `.datePickerStyle(.compact)` and `labelsHidden()` ("Always provide a label for
  controls, even when you hide the label, because SwiftUI uses labels for other purposes,
  including accessibility").
- HIG HealthKit › Privacy protection and Wallet › "Ask only for the data you actually need": date
  of birth stays optional, behind an explicit "Add" (D0048-8).

Done:
- `ProfileStep`: `Picker(selection: $sex)` with `Optional` tags at regular sizes; at
  `isAccessibilitySize` an `OnboardingCard` of `OnboardingChoiceRow`s (`sexChoiceRow.<raw>`);
  Continue `isEnabled: sex != nil`; "Add Date of Birth" (bordered) sets 30 years ago, then the
  compact `DatePicker` (range −120…−13 years); `onboarding.profile.privacy` as the DOB footnote,
  no lock row. `BiologicalSex` is not `CaseIterable` (Domain is out of scope), so the step keeps
  a local `[.male, .female]` in the Settings order.
- `WelcomeStep`: rounded bold title (header trait) and the `onboarding.welcome.privacy` `Label`
  (`lock.fill`, footnote, `dpSecondaryText`).
- `HealthStep`: `OnboardingHeading`, toggles in an `OnboardingCard` on `BrandSurface` (no
  `.thinMaterial`), denied hints in `Color.dpDeniedText`, other hints `dpSecondaryText`.
- Strings (D0048-11): 7 values changed, 2 keys added (`onboarding.profile.addDateOfBirth`,
  `onboarding.welcome.privacy`) with the JSON script; round trip byte-identical before the edit.
  "Weekly check-in" stays (plan).
- UI tests: new `OnboardingWalk` (`chooseSex`, `walkToHealth`); `OnboardingFlowUITests`'
  private `selectSex` removed. `OnboardingHealthStepUITests`, `OnboardingWeeklySummaryUITests`,
  `OnboardingLocaleDefaultUITests`, `OnboardingDynamicTypeUITests` (Guideline and Health) now
  choose a sex. No class under `Shell/` walks past Welcome, so `AccessibilityAuditSupport` is
  unchanged; the gated `AccessibilityAuditUITests` onboarding case takes the D0048-18 opt-in.
- New tests: `test_continueDisabled_untilSexChosen`, `test_swipe_cannotPassAboutYou_untilSexChosen`,
  `test_dateOfBirth_startsBehindAddButton`, `test_onboardingProfile_atAX5_sexRowsEnableContinue`.
  RED run: 3 failed as expected (Continue enabled, no "Add Date of Birth", no `sexChoiceRow`); the
  swipe test already passed, because Task 2 put only `reachableSteps` pages in the `TabView`.
- Ruling: the plan's swipe test says "tap Back twice, then swipe left twice". From About You one
  Back reaches Welcome and there is no second Back, so the test taps Back once (Review focus 4:
  "go Back to Welcome, swipe forward").
- Renders: About You (nothing chosen, chosen + date, AX5), Health Dark, Welcome Light — they match
  the prototype screenshots. The disabled Continue is grey glass.
- Run (Step 6): 6 onboarding UI classes + `HealthStepTests`: 17 passed, 1 failed
  (`test_swipe_cannotPassAboutYou_untilSexChosen`: the forward swipe did not reach Your Guideline),
  and 1 "no result" (`test_pendingOpenInsights…`, Task 4, added to the file after the run's build).
  The test swiped at the screen centre, which on the new About You lies on the sex and date
  controls, and fired its second swipe without waiting for the page to settle. It now swipes on
  the "About You" heading and waits until the heading is hittable: passed. Whether a swipe that
  starts on the segmented control pages the `TabView` on a device is left to the owner's device
  check ("A swipe stops at About You until a sex is chosen").

## 2026-11-25 — Task 4: first run as a cover over the shell

Docs (Xcode MCP `DocumentationSearch`):
- `fullScreenCover(isPresented:onDismiss:content:)`: "Presents a modal view that covers as much of
  the screen as possible"; `onDismiss` is "The closure to execute when dismissing the modal view".
- `Transaction.disablesAnimations`: "true during the initial phase of a two-part transition
  update, to prevent `animation(_:)` from inserting new animations". The docs say nothing about
  presentations, so they do not settle D0048-2.

Order ruling: the plan's Step 0 implements before Step 1's tests. The tests were written and run
first on the `if/else` build: `LaunchHandoffUITests` (3, including the extended fresh-launch test
and `test_onboardingDone_landsOnToday_andCoverIsGone`) and
`test_pendingOpenInsights_waitsForOnboarding_thenOpensInsights` → 4/4 passed. The pending test
passes on the `if/else` build because the shell (and its `onAppear`) only exists after Done; it
guards the cover build, where the shell appears under the cover. These test edits landed in the
Task 3 commit.

Done:
- `drinkpulseApp`: `.ready` always shows `RootShellView().modelContainer(container)`; the
  `onboardingDone` storage, `forceOnboardingPending` and `seedIfUITest` are gone.
- New `Features/Shell/ShellStartup.swift`: the UI-test seed and the `RecordDeduplicator.sweep`
  (with its timing log), unchanged, run from the shell's `onAppear`.
- `RootShellView`: `showsOnboarding` / `firstRunRevealed` start from `startsWithOnboarding`
  (`!onboardingDone || UITestSeed.forceShowOnboarding`, read from `UserDefaults.standard`);
  `.fullScreenCover(isPresented: $showsOnboarding, onDismiss: revealFirstRun)`; `OnboardingView`'s
  `onFinish` sets `onboardingDone` and closes the cover. D0048-3: `openAddDrinkIfPending` /
  `openInsightsIfPending` return while the cover is up, the two notification loops `continue`
  (the handler has already set the pending flag), and `revealFirstRun` runs both after dismissal.
  198 lines.

**D0048-2 (launch presentation): variant A kept, decision moved to the owner's device check.**
The cover is presented with `isPresented` true from the first frame. An MCP screenshot is taken
only after the app is idle, so it cannot show a slide-up or a frame of Today. A screen recording
needs `xcrun simctl io … recordVideo`; the owner declined it on 2026-11-25 and will judge the launch
on the phone ("Device check": no slide-up, no flash of Today). The UI test pins only that Today's
tab is not hittable while "Get Started" is shown.

Run: `LaunchHandoffUITests`, `OnboardingAuthorityUITests`, `StartupErrorUITests`,
`OnboardingFlowUITests`, `ShellNavigationUITests`, `WeeklySummaryTapUITests` → 21/21 passed.
Build: zero warnings.
