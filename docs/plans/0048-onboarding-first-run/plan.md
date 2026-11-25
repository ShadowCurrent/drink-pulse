# 0048 — Port step 8: Onboarding and first run

**Status**: draft
**Size**: medium
**Created**: 2026-11-25
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 8
**Branch**: `port/0048-onboarding` (from `ui-revamp` at `4ab843c`; `main` has no new commits)

> Execution: superpowers `executing-plans`, inline, one session where possible (owner workflow,
> plan 0040 "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Onboarding gets the accepted round 19 / 19b / 21 fixes: sex is required, no page can
be skipped, date of birth sits behind "Add", Frost tint, VOICE copy. First run moves from the
`if/else` swap in `drinkpulseApp.swift` to a `fullScreenCover` over the shell. After Done,
Today's cards rise in, the arc track draws, and a success haptic plays (round 20).

**Architecture:** Views change in place. The shell (`RootShellView`) owns the cover, the
first-run state and the Done haptic, next to the logging haptic from plan 0044. A new design
system modifier, `firstRunReveal(_:)`, reads `\.firstRunRevealed` from the environment. The
default is `true`, so no other screen changes. `OnboardingViewModel` keeps the logic: required
sex, reachable pages, and a completion that runs only once. No Domain, calculation, persistence
or schema change.

**Tech stack:** SwiftUI `fullScreenCover(isPresented:onDismiss:content:)`,
`sensoryFeedback(trigger:_:)`, `@Entry` environment values, `TabView` `.page`, `Picker`
`.segmented` with `Optional` tags, `DatePicker` `.compact`, `Button` `.glass` /
`.glassProminent`, `Transaction.disablesAnimations`; Swift Testing; XCUITest.

**Spec:** the brainstorm design approved in chat on 2026-11-25 (variant 1: cover in the shell).
Plan 0040 ("Onboarding and first run", step 8, "Accessibility audit policy"). Prototype
`~/Developer/drinkpulse-native-proto/DrinkPulseNativeProto/DrinkPulseNativeProto/`:
`Onboarding/OnboardingFlow.swift`, `OnboardingChrome.swift`, `OnboardingSteps.swift`,
`Components/FirstRunReveal.swift`, `Shell/RootView.swift`, `Dashboard/HeroGauge.swift`.
FINDINGS rounds 17 (the empty-state and sex decisions only), 19, 19b, 20, 21. `VOICE.md` rows
`onboarding.*`.

## Summary

The app's onboarding saves "Male" when nobody taps the sex picker. The binding is
`get: { sex ?? .male }` in `ProfileStep`, and `complete` also falls back to `?? .male`.
Swiping the paged `TabView` skips About You. Date of birth shows a default date that is saved
only if the person changes it. The Health card uses `.thinMaterial`, which is a material on
content. The copy says "we / us". First run cuts hard from `OnboardingView` to `RootShellView`.
The prototype fixed all of this, and the owner accepted it on 2026-11-20, rounds 20 and 21
included on device.

## Context

- Steps 2–7 are merged into `ui-revamp`. The design tokens are in place: `brandBackground()`,
  `BrandSurface`, `BrandCardStyle`, the rounded title helpers and `withMotion`. The shell
  already owns the logging haptic (`LogPulse`) and the Add Drink sheet (plan 0044).
- `GuidelineStep` already uses `GroupBox` + `BrandCardStyle` (plan 0042). `WelcomeStep` already
  uses `dpSecondaryText` and `DecorativeEmoji`.
- 7 UI test classes go through About You by tapping "Continue" without choosing a sex:
  `OnboardingHealthStepUITests`, `OnboardingLocaleDefaultUITests`,
  `OnboardingWeeklySummaryUITests`, `OnboardingDynamicTypeUITests` (Guideline and Health
  tests), `OnboardingFlowUITests.test_backButton_returnsToPreviousStep` (check it), and the
  audit support where it walks further than Welcome. All of them need a sex tap.
- `OnboardingViewModelTests.completeWithNoSelectionsInsertsDefaultProfile` pins the bug (it
  expects `.male`). It changes in Task 1.
- `UITestSeed.seedFixtures` returns early under `-dp_force_onboarding`. Once the shell sits
  under the cover, `seedIfUITest` and `RecordDeduplicator.sweep` run while onboarding is still
  up, on an empty store. That is harmless and needs no change.
- Today with no `UserProfile` renders under the cover. `DashboardViewModel` already handles
  `profile == nil` (`OnboardingAuthorityUITests` deletes the profile mid-session).

## Decisions (this plan)

- **D0048-1 Cover in the shell** (owner, 2026-11-25, variant 1). `drinkpulseApp` always shows
  `RootShellView` in `.ready`. The `if onboardingDone … else OnboardingView` branch and its
  `forceOnboardingPending` state move into the shell. The shell attaches
  `.fullScreenCover(isPresented: $showsOnboarding, onDismiss: revealFirstRun)`.
  `showsOnboarding` starts as `!onboardingDone || UITestSeed.forceShowOnboarding`.
  `OnboardingView(onFinish:)` sets `onboardingDone = true` and `showsOnboarding = false`.
  Rejected: the cover in `drinkpulseApp` (it splits haptics from the shell and needs a second
  App-to-shell channel); an overlay (round 20); keeping `if/else` (plan 0040).
- **D0048-2 No slide-up at launch** (my call, check in Task 4). The cover must already be up on
  the first frame of a fresh launch, with Today never visible first. Step 0 checks the docs for
  `Transaction.disablesAnimations` on presentations. If the simulator shows a slide-up with
  `isPresented` true from the start, then `showsOnboarding` starts `false` and is set in the
  shell's `onAppear` inside `withTransaction(\.disablesAnimations, true)`. Record the
  observation and the source in `execution.md`. If neither variant avoids it, stop and ask the
  owner.
- **D0048-3 Pending notification actions wait for the cover** (my call). While
  `showsOnboarding` is true, `openAddDrinkIfPending` / `openInsightsIfPending` and the two
  `.task` notification loops keep the pending flag and do nothing else. `revealFirstRun` runs
  the two `open…IfPending` calls after the dismissal. A real user cannot get a notification
  before onboarding finishes. The rule guards UI-test seeds and a sheet that would be presented
  under the cover.
- **D0048-4 Sex is required** (owner, 2026-11-20). `OnboardingViewModel.canContinueProfile`
  is `sex != nil`. Continue on About You is disabled until then. `complete(into:)` inserts
  nothing while `sex == nil`. Existing profiles are not touched, and no migration is needed.
- **D0048-5 Only reachable pages** (round 19). `reachableSteps` is `sex == nil ? 2 : 4`. The
  `TabView` iterates over `0..<vm.reachableSteps`. The step dots still show `totalSteps` (4).
- **D0048-6 Completion runs once** (my call). `complete(into:)` sets
  `private(set) var isCompleted` and returns early on a second call. A fast double tap on Done
  must not insert two `UserProfile`s.
- **D0048-7 Sex at accessibility sizes** (round 21). Choice rows replace the segmented control.
  `GuidelineChoiceRow` becomes the shared `OnboardingChoiceRow(title:detail:isSelected:
  identifier:action:)`. Identifiers: `guidelineChoiceRow.<raw>` (unchanged) and
  `sexChoiceRow.<raw>`. Nothing is selected until a tap, and rows carry the `.isSelected` trait.
- **D0048-8 Date of birth behind "Add"** (round 19). A bordered "Add Date of Birth" button sets
  `dateOfBirth` to 30 years ago, then the compact `DatePicker` shows. The range stays
  `-120…-13` years.
- **D0048-9 Header** (round 19b). Back is a `.glass` circle button (`chevron.backward`, 32 pt
  frame). It is always laid out and hidden on step 1 (`opacity(0)`, `disabled`,
  `accessibilityHidden`), so the header has one height on every step. The header moves to
  `Components/OnboardingHeader.swift`.
- **D0048-10 Look** (round 19): `brandBackground()` behind the whole flow; rounded bold large
  headings (`OnboardingHeading`); primary button `.glassProminent` + `.controlSize(.large)`;
  the Health card on `BrandSurface` at `CardMetrics.cornerRadius` (no `.thinMaterial`); the
  denied hints use `Color.dpDeniedText` (as in Settings, plan 0043) instead of `.red`.
- **D0048-11 Copy** (VOICE.md, round 19 point 5). Edit through `StringCatalogEdit`:
  | Key | New English value |
  |---|---|
  | `onboarding.profile.body` | Some guidelines set different limits for women and men. |
  | `onboarding.profile.privacy` | Optional. Makes your insights more accurate. Stored only on this device. |
  | `onboarding.profile.addDateOfBirth` (new) | Add Date of Birth |
  | `onboarding.guideline.body` | DrinkPulse compares what you drink with these limits. You can change this in Settings. |
  | `onboarding.health.body` | Mirrors the drinks you log to Apple Health. You can change this any time in Settings. |
  | `onboarding.health.weeklySummary.hint` | A weekly note on how your week compares to the last. |
  | `onboarding.welcome.privacy` (new) | Stored only on this device. |
  | `onboarding.welcome.cta.hint` | Begins the setup |
  | `onboarding.progress.label` | Setup Progress |
  The `profile.privacy` line becomes the date-of-birth footnote, with no lock row.
  **"Weekly check-in" stays** (my call). Settings uses the same name, and VOICE rule 8 allows
  one name per thing. The rename to "Weekly Summary" spans screens and belongs to step 9 (copy
  pass).
- **D0048-12 First-run reveal** (round 20). `DesignSystem/FirstRunReveal.swift`:
  `@Entry var firstRunRevealed = true` and `firstRunReveal(_ order: Int)`. The modifier uses
  opacity 0→1 and offset 24→0 with `.smooth(duration: 0.5).delay(0.07 * order)`. Under Reduce
  Motion (`DPMotion.isReduced`) it uses `.easeInOut(duration: 0.25)` with no offset and no
  stagger. Today orders: hero 0, calories / drinks tiles 1, guideline limits 2, This Week 3,
  streak tiles 4, alert card 5. The shell sets `\.firstRunRevealed` to `false` when it starts
  with the cover up, and to `true` in `onDismiss`. Later launches start revealed.
- **D0048-13 Arc track draws on first run** (round 20). `DPArcProgress`'s track becomes
  `ArcShape(from: 0, to: revealed ? 1 : 0)` with `.smooth(duration: 0.8).delay(0.15)` keyed on
  `revealed`, and no animation under Reduce Motion. The environment default `true` leaves
  Insights and every other use unchanged.
- **D0048-14 Done haptic** (round 20). The shell plays
  `.sensoryFeedback(trigger: onboardingDone) { old, new in !old && new ? .success : nil }`.
- **D0048-15 Tests: no full suite** (owner, 2026-11-25). Plan 0040 named the end of step 8 as a
  full-suite checkpoint. The owner overrides that for this step. Only scoped `RunSomeTests`
  runs happen: the classes changed or added here plus the classes that depend on them (list in
  Task 7), in batches of about 10. No `RunAllTests`. As a result, the open-questions entry
  "History edit UI tests fail on their own" stays open, because it was waiting for this full
  run. Coverage is not measured unless the owner asks (as in plans 0045–0047, CLI only).
- **D0048-16 Old-UI audit baseline closes.** `OnboardingAccessibilityAuditUITests` passes since
  plan 0042. This step leaves it green on the new UI and deletes the open-questions entry
  "Accessibility audit failures on the old UI" (that entry says: delete after step 8).
- **D0048-17 Out of scope** (owner, 2026-11-25, option A): the `today.status` dark over-limit
  contrast, the History calendar `dynamicType` finding, the plan 0046 / 0047 owner questions,
  the "Weekly Summary" rename, and step 11 cleanup.

## Scope

### In
`Features/Onboarding/**`, `Features/Shell/RootShellView.swift`, `drinkpulseApp.swift`,
`DesignSystem/FirstRunReveal.swift` (new), `DesignSystem/DPArcProgress.swift`,
`Features/Dashboard/DashboardView.swift` (reveal orders only), `Localizable.xcstrings`
(onboarding keys), onboarding / shell UI tests, `OnboardingViewModelTests`, living docs.

### Out
Domain, persistence, schema, calculations; Settings; Insights / History behaviour; D0048-17.

## Global constraints

- **Xcode MCP for everything it covers** (main checkout, no worktree). At session start, call
  `XcodeListWorkspaces` and take the entry whose `workspacePath` ends with
  `drinkpulse.xcodeproj`. Pass its `workspaceIdentifier` on every call that accepts one. Call
  `XcodeListRunDestinations` before test calls. Target: the iPhone 18 Pro iOS 27.2 simulator,
  never the physical device.
  - Build: `BuildProject`, then `GetBuildLog`. Zero warnings.
  - Tests: `RunSomeTests` with named classes, at most about 10 per call. Use `GetTestList` to
    confirm that new tests exist and ran. **No `RunAllTests`** (D0048-15).
  - Code: `XcodeRead` / `XcodeGrep` / `XcodeUpdate` / `XcodeWrite` / `XcodeMV` / `XcodeRM`,
    `XcodeRefreshCodeIssuesInFile` after each edited file. Strings: `StringCatalogRead` /
    `StringCatalogEdit`. Visual: `RenderPreview` (Light, Dark, AX5).
  - No CLI `xcodebuild` / `xcrun` without the owner's approval.
- **Apple docs first:** run `DocumentationSearch` (API and HIG) before each API use. Record the
  query, the symbol and its availability in `execution.md`. Each task's Step 0 lists them.
- No calculation, schema or persistence change. If one appears, stop.
- Swift 6 strict concurrency, zero warnings. Files under 300 lines. Every changed view keeps
  previews (Light, Dark, AX5; About You with and without a chosen sex).
- No PII in logs (sex and date of birth are health data), no `print`, and no new `try?`
  without a comment. `OnboardingViewModel.complete` keeps its existing `try? context.save()`
  only with a comment, or replaces it with a logged `do / catch` (error type only).
- Unit tests use Swift Testing in `drinkpulseTests/Features/Onboarding/` and
  `drinkpulseTests/DesignSystem/`. UI tests go in `drinkpulseUITests/Features/Onboarding/` and
  `…/Shell/`. Never match system UI by a localized label (simulator locale is Polish). App
  strings are English and safe to match.
- Simulator first-draw stalls are not app bugs. The entrance animation is judged on the device
  (round 20).

## Review focus

1. **Fresh launch:** the cover slides up over an empty Today, or Today flashes before
   onboarding. Expected: onboarding is the first thing shown. Pinned in Task 4 Step 0 /
   D0048-2: a simulator screen recording or `DeviceInteraction` screenshot taken immediately
   after launch, recorded in `execution.md`, plus the owner's device check.
   `LaunchHandoffUITests.test_freshLaunch_landsOnOnboardingWelcomeWithinTimeout` is extended to
   assert that `app.tabBars.buttons[UITestTabs.today].isHittable` is false while "Get Started"
   is shown.
2. **Double tap on Done.** Expected: one `UserProfile`. Pinned in Task 1
   (`completeTwice_insertsOneProfile`).
3. **A pending action while onboarding is up** (seeded `-dp_uitest_pending_open_insights YES`
   with `-dp_force_onboarding YES`). Expected: Insights opens only after Done, and no sheet or
   tab change happens under the cover. Pinned in Task 4
   (`test_pendingOpenInsights_waitsForOnboarding_thenOpensInsights`).
4. **Choose a sex, go Back to Welcome, swipe forward.** Expected: all 4 pages are reachable and
   the choice is kept. Before a choice, a swipe from About You stays on About You. Pinned in
   Task 3 (`test_swipe_cannotPassAboutYou_untilSexChosen`).
5. **AX5:** sex choice rows enable Continue, and the Continue button stays reachable. Pinned in
   Task 3 (`OnboardingDynamicTypeUITests.test_onboardingProfile_atAX5_sexRowsEnableContinue`).

---

### Task 1: Onboarding view model: required sex, reachable pages, one completion

**Files:**
- Modify: `drinkpulse/Features/Onboarding/OnboardingViewModel.swift`
- Test: `drinkpulseTests/Features/Onboarding/OnboardingViewModelTests.swift`

**Interfaces:**
- Produces: `var canContinueProfile: Bool { get }`, `var reachableSteps: Int { get }`,
  `private(set) var isCompleted: Bool`, `func complete(into: ModelContext)` (no-op when
  `sex == nil` or already completed).

- [ ] **Step 0: Docs**: `DocumentationSearch` for `ModelContext.insert(_:)` and
  `ModelContext.save()`.
- [ ] **Step 1: Write the failing tests**
  - Replace `completeWithNoSelectionsInsertsDefaultProfile` with
    `completeWithoutSex_insertsNothing` (0 profiles).
  - `canContinueProfile_falseUntilSexChosen` (nil → false; `.female` → true).
  - `reachableSteps_isTwoWithoutSex_fourWithSex`.
  - `completeTwice_insertsOneProfile` (sex `.male`, call twice, 1 profile, `isCompleted`).
  - Existing tests that call `complete` without a sex (DOB, explicit guideline, default
    guideline) set `vm.sex = .male` first, so they keep testing what they claim.
- [ ] **Step 2: Run** `OnboardingViewModelTests`. Expected: the new tests FAIL.
- [ ] **Step 3: Implement** in `OnboardingViewModel.swift`. Use `guard let sex, !isCompleted`
  in `complete`.
- [ ] **Step 4: Run** `OnboardingViewModelTests`. Expected: PASS.
- [ ] **Step 5: Commit** `[plan-0048] onboarding requires a sex choice and completes once`.

### Task 2: Onboarding chrome: header, layout, heading, shared choice row

**Files:**
- Create: `drinkpulse/Features/Onboarding/Components/OnboardingHeader.swift`,
  `…/Components/OnboardingHeading.swift`
- Move: `…/Components/GuidelineChoiceRow.swift` → `…/Components/OnboardingChoiceRow.swift`
  (`XcodeMV`)
- Modify: `…/Components/OnboardingStepLayout.swift`, `…/OnboardingView.swift`,
  `…/Components/GuidelineStep.swift`

**Interfaces:**
- Consumes: Task 1 `reachableSteps`.
- Produces:
  - `OnboardingHeader(step: Int, total: Int, onBack: () -> Void)`
  - `OnboardingHeading(title: String, message: String)`
  - `OnboardingChoiceRow(title: String, detail: String?, isSelected: Bool,
    identifier: String, action: () -> Void)`
  - `OnboardingStepLayout(buttonTitle:buttonHint:isEnabled: Bool = true:action:content:)`

- [ ] **Step 0: Docs**: `ButtonStyle.glass`, `glassProminent`, `buttonBorderShape(.circle)`,
  `controlSize(.large)`, `PageTabViewStyle`, HIG Buttons and HIG Materials. Record them.
- [ ] **Step 1:** Write the header per D0048-9 and the dots as today (one element, label
  `onboarding.progress.label`, value `onboarding.progress.value`). In `OnboardingView`, use
  `ForEach(0..<vm.reachableSteps)` in the `TabView`, put `.brandBackground()` on the root, and
  pass `sex: vm.sex ?? .female` to `GuidelineStep`. The guideline step is unreachable without a
  sex, so the fallback only feeds previews. Comment that.
- [ ] **Step 2:** In `OnboardingStepLayout`, add `isEnabled` and use `.glassProminent` with
  `.controlSize(.large)` (D0048-10). Make `GuidelineStep` use `OnboardingHeading` and
  `OnboardingChoiceRow` (identifier `guidelineChoiceRow.\(raw)`).
- [ ] **Step 3: Build**, then `RenderPreview` Welcome / Guideline in Light, Dark and AX5.
  Check: no header jump between steps (the 1→2 swipe is checked in Task 3's UI run).
- [ ] **Step 4: Run** `OnboardingFlowUITests`, `OnboardingAccessibilityAuditUITests`.
  Expected: PASS (About You still has the old picker until Task 3).
- [ ] **Step 5: Commit** `[plan-0048] onboarding chrome: glass Back, reserved header, shared rows`.

### Task 3: Steps: About You, Welcome, Health; copy; UI tests choose a sex

**Files:**
- Modify: `…/Components/ProfileStep.swift`, `…/WelcomeStep.swift`, `…/HealthStep.swift`,
  `drinkpulse/Localizable.xcstrings` (D0048-11)
- Create: `drinkpulseUITests/Features/Onboarding/OnboardingWalk.swift` (shared helper)
- Modify (UI tests): the 7 classes from Context, `AccessibilityAuditSupport.swift` only if it
  walks past Welcome
- Test: `OnboardingFlowUITests` (new tests below), `OnboardingDynamicTypeUITests`

**Interfaces:**
- Consumes: Tasks 1–2.
- Produces: `enum OnboardingWalk { static func chooseSex(_ label: String, in: XCUIApplication);
  static func walkToHealth(in: XCUIApplication, sex: String = "Female") }`. `chooseSex` taps
  `app.buttons[label]`, which matches both the segment and the AX row.

- [ ] **Step 0: Docs**: `Picker` with `Optional` tags (`tag(_:)`), `pickerStyle(.segmented)`,
  `DatePicker` `.compact`, `accessibilityAddTraits(.isSelected)`, HIG Onboarding, HIG Privacy.
- [ ] **Step 1: Write the failing UI tests** in `OnboardingFlowUITests`:
  - `test_continueDisabled_untilSexChosen`: after Get Started, `app.buttons["Continue"]
    .isEnabled == false`. Tap "Male", and it is `true`.
  - `test_swipe_cannotPassAboutYou_untilSexChosen`: swipe left on About You, and the
    "About You" title is still shown. Choose "Female", tap Back twice, then swipe left twice,
    and "Your Guideline" is shown.
  - `test_dateOfBirth_startsBehindAddButton`: "Add Date of Birth" exists. Tap it, and the
    button is gone and a date picker exists (`app.datePickers.firstMatch`).
  - In `OnboardingDynamicTypeUITests`, add
    `test_onboardingProfile_atAX5_sexRowsEnableContinue`:
    `app.buttons["sexChoiceRow.female"]` exists. Before the tap, Continue is disabled. After the
    tap, Continue is enabled and reachable (existing `assertPrimaryButtonReachable`).
- [ ] **Step 2: Run** them. Expected: FAIL.
- [ ] **Step 3: Implement** `ProfileStep` (D0048-4, -7, -8; `isEnabled: sex != nil` on the
  layout). Use `Picker(selection: $sex)` with `.tag(Optional(BiologicalSex.male))`, and at
  `dynamicTypeSize.isAccessibilitySize` an `OnboardingChoiceRow` card on `BrandSurface`. In
  `WelcomeStep`, add the `onboarding.welcome.privacy` `Label` with `lock.fill`, footnote,
  `dpSecondaryText`. In `HealthStep`, use `OnboardingHeading`, the `BrandSurface` card and
  `dpDeniedText`. Apply all D0048-11 strings with `StringCatalogEdit`.
- [ ] **Step 4:** Make `OnboardingWalk.swift` and move every class from Context onto
  `OnboardingWalk.chooseSex` / `walkToHealth`. Keep `selectSex` in `OnboardingFlowUITests` only
  if `OnboardingWalk` does not cover it.
- [ ] **Step 5:** `RenderPreview` About You (nothing chosen, chosen + date, Dark, AX5),
  Welcome, Health. Compare with the prototype `screenshots/onboarding-*.png`.
- [ ] **Step 6: Run** all 6 onboarding UI classes and `HealthStepTests`. Expected: PASS.
- [ ] **Step 7: Commit** `[plan-0048] onboarding steps: required sex, DOB behind Add, Frost cards, VOICE copy`.

### Task 4: First run: cover over the shell

**Files:**
- Modify: `drinkpulse/drinkpulseApp.swift` (drop the `if/else` and `forceOnboardingPending`),
  `drinkpulse/Features/Shell/RootShellView.swift`
- Test: `drinkpulseUITests/Features/Shell/LaunchHandoffUITests.swift`,
  `drinkpulseUITests/Features/Onboarding/OnboardingFlowUITests.swift`

**Interfaces:**
- Consumes: `OnboardingView(onFinish:)` (unchanged signature).
- Produces (shell-private): `@State showsOnboarding: Bool`, `@State firstRunRevealed: Bool`,
  `func revealFirstRun()`. Task 5 uses the `\.firstRunRevealed` injection point.

- [ ] **Step 0: Docs**: `fullScreenCover(isPresented:onDismiss:content:)`,
  `Transaction.disablesAnimations`, `withTransaction(_:_:)`. Then implement D0048-1, launch
  the app in the simulator with `-dp_uitest YES -dp_force_onboarding YES`
  (`DeviceInteractionInstallAndRun`), and take an immediate screenshot. Decide D0048-2 and
  record the result.
- [ ] **Step 1: Write the failing UI tests**
  - `LaunchHandoffUITests`: extend the fresh-launch test per Review focus 1. Add
    `test_onboardingDone_landsOnToday_andCoverIsGone`: walk with `OnboardingWalk`, tap Done,
    and then the Today tab is hittable and "Get Started" does not exist.
  - `OnboardingFlowUITests.test_pendingOpenInsights_waitsForOnboarding_thenOpensInsights`:
    launch with `-dp_uitest_pending_open_insights YES -dp_force_onboarding YES`. "Get Started"
    is shown. Walk to Done. The Insights tab is selected (`isSelected`).
- [ ] **Step 2: Run**. Expected: the pending test FAILS on the `if/else` build. The others may
  already pass. Record which.
- [ ] **Step 3: Implement** D0048-1 and D0048-3. The shell takes `seedIfUITest` and the sweep
  unchanged from `drinkpulseApp` (still in the shell's `onAppear` path, through a closure or
  by moving the two calls). Keep `RootShellView` under 300 lines. If needed, move the
  first-run pieces into `Features/Shell/RootShellView+FirstRun.swift`.
- [ ] **Step 4: Run** `LaunchHandoffUITests`, `OnboardingAuthorityUITests`,
  `StartupErrorUITests`, `OnboardingFlowUITests`, `ShellNavigationUITests`,
  `WeeklySummaryTapUITests`. Expected: PASS.
- [ ] **Step 5: Commit** `[plan-0048] first run: onboarding as a full-screen cover over the shell`.

### Task 5: First-run reveal, arc track, Done haptic

**Files:**
- Create: `drinkpulse/DesignSystem/FirstRunReveal.swift`
- Modify: `drinkpulse/DesignSystem/DPArcProgress.swift`,
  `drinkpulse/Features/Dashboard/DashboardView.swift` (orders per D0048-12),
  `RootShellView` (environment + haptic)
- Test: `drinkpulseTests/DesignSystem/FirstRunRevealTests.swift`

**Interfaces:**
- Produces: `extension EnvironmentValues { @Entry var firstRunRevealed: Bool = true }`;
  `extension View { func firstRunReveal(_ order: Int) -> some View }`;
  `nonisolated enum FirstRunRevealMotion { static func offset(revealed: Bool, reduced: Bool) -> CGFloat;
  static func delay(order: Int, reduced: Bool) -> Double }` (pure; the modifier uses it).

- [ ] **Step 0: Docs**: `Entry()` macro, `sensoryFeedback(trigger:_:)` (closure form), HIG
  Playing haptics, HIG Motion, `Animatable.animatableData`.
- [ ] **Step 1: Write the failing tests**: `offset_is24_whenHidden_andMotionOn`,
  `offset_isZero_whenRevealed`, `offset_isZero_whenReduced`, `delay_is70msPerOrder`
  (`order 3 → 0.21`), `delay_isZero_whenReduced`.
- [ ] **Step 2: Run** `FirstRunRevealTests`. Expected: FAIL.
- [ ] **Step 3: Implement** D0048-12, D0048-13 and D0048-14. Use
  `DPMotion.isReduced(system:)` for the reduced flag, so the UI-test override applies.
- [ ] **Step 4: Run** `FirstRunRevealTests`, `DPMotionTests`, `DashboardUITests`,
  `InsightsUITests`, `LaunchHandoffUITests`. Expected: PASS (later launches start revealed, so
  Today's tests see no delay).
- [ ] **Step 5:** `RenderPreview` Today with `\.firstRunRevealed` false and true (a preview
  "Today · First run" with a Reveal button, as in the prototype).
- [ ] **Step 6: Commit** `[plan-0048] first-run entrance on Today and success haptic on Done`.

### Task 6: Audit and Dynamic Type on the new onboarding

**Files:**
- Modify: `drinkpulseUITests/Features/Onboarding/OnboardingAccessibilityAuditUITests.swift`,
  `…/OnboardingDynamicTypeUITests.swift`

- [ ] **Step 0: Docs**: `XCUIApplication.performAccessibilityAudit(for:_:)`; HIG Accessibility.
- [ ] **Step 1:** Add `test_onboardingProfile_standard_hasNoAuditIssues` and
  `test_onboardingProfile_ax5_hasNoAuditIssues` (walk to About You, choose nothing).
- [ ] **Step 2: Run** both onboarding audit and Dynamic Type classes in standard, dark (the
  class's own variants) and AX5. A finding on the glass Back button is a bar-like control, so
  check whether round 21 case 1 applies. Any exemption needs the owner's decision. Record it as
  a decision id, never silently.
- [ ] **Step 3:** Fix findings at the source and re-run. Expected: green.
- [ ] **Step 4: Commit** `[plan-0048] onboarding audit and Dynamic Type on the new UI`.

### Task 7: Gates, docs, close

**Files:**
- Modify: `docs/architecture.md` (Shell: owns the onboarding cover, first-run state and Done
  haptic; App entry: no onboarding branch; DesignSystem: `FirstRunReveal`), `README.md` if it
  describes onboarding (`XcodeGrep` first), `.planning/PROJECT.md` only if scope text names
  optional sex. Also `execution.md`, `retrospective.md`, `INDEX.md`, plan 0040
  `execution.md` (step 8 done), `DEVLOG.md`, `current-focus.md`, `open-questions.md`
  (D0048-15, D0048-16).

- [ ] **Step 1: Build** with zero warnings.
- [ ] **Step 2: Scoped gate run** (D0048-15) in batches of 10 or fewer:
  1. `OnboardingViewModelTests`, `HealthStepTests`, `FirstRunRevealTests`, `DPMotionTests`,
     `OnboardingFlowUITests`, `OnboardingHealthStepUITests`, `OnboardingLocaleDefaultUITests`,
     `OnboardingWeeklySummaryUITests`
  2. `OnboardingDynamicTypeUITests`, `OnboardingAccessibilityAuditUITests`,
     `LaunchHandoffUITests`, `OnboardingAuthorityUITests`, `StartupErrorUITests`,
     `ShellNavigationUITests`, `WeeklySummaryTapUITests`
  3. `AccessibilityAuditUITests` (onboarding case),
     `DashboardUITests`, `DashboardAccessibilityAuditUITests`,
     `DashboardOverLimitAccessibilityAuditUITests`, `InsightsUITests`, `AddDrinkFlowUITests`,
     `SheetDismissTabSwitchUITests`
  Expected: green, except known entries named by test in open-questions (e.g. `today.status`
  dark over limit). Record each result in `execution.md`.
- [ ] **Step 3: File size and privacy.** Run the AGENTS.md `find` command. Check: no new
  network, no PII in logs, no `print`.
- [ ] **Step 4: Docs close-out.** Then commit `[plan-0048] docs: close plan`.
- [ ] **Step 5: Final review.** Run one fresh superpowers reviewer over the branch (standing
  approval). Fix Critical / Important findings; list minors in `execution.md`.
- [ ] **Step 6:** `git switch ui-revamp && git merge --no-ff port/0048-onboarding`, then ask the
  owner about push.

## Device check (owner)

- Fresh install: onboarding is the first screen, with no slide-up and no flash of Today.
- Welcome to About You slides with no header jump. A swipe stops at About You until a sex is
  chosen. The segmented control shows no selection at first.
- Done: the cover slides down, Today's cards rise in order, the arc track draws, and one success
  haptic plays. Under Reduce Motion: a short fade, with no movement.
- VoiceOver: "Setup Progress, Step n of 4"; sex rows at AX5 read "Selected"; Back is reachable.
- Light / Dark / Increase Contrast on all four steps.

## Open questions

- [x] Cover location — shell (owner, 2026-11-25).
- [x] Scope of open-question carry-ins — none (owner, 2026-11-25, option A).
- [x] Full suite at step 8 — skipped, scoped runs only (owner, 2026-11-25).
- [ ] D0048-2 launch presentation — decided by the Task 4 Step 0 observation.
- [ ] Any audit exemption from Task 6 — owner decision if one is needed.

## Tests required

New: `FirstRunRevealTests`; in `OnboardingViewModelTests`: `completeWithoutSex_insertsNothing`,
`canContinueProfile_falseUntilSexChosen`, `reachableSteps_isTwoWithoutSex_fourWithSex`,
`completeTwice_insertsOneProfile`; UI tests `test_continueDisabled_untilSexChosen`,
`test_swipe_cannotPassAboutYou_untilSexChosen`, `test_dateOfBirth_startsBehindAddButton`,
`test_onboardingProfile_atAX5_sexRowsEnableContinue`,
`test_onboardingDone_landsOnToday_andCoverIsGone`,
`test_pendingOpenInsights_waitsForOnboarding_thenOpensInsights`, two About You audit tests.
Updated: the 7 classes that go through About You (`OnboardingWalk`), the fresh-launch handoff
test. Coverage: not measured unless the owner asks (D0048-15).
