# 0044 — Port step 4: Shell

**Status**: draft
**Size**: small-medium
**Created**: 2026-11-21
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 4
**Branch**: `port/0044-shell` (from `ui-revamp` at `4f3c5e8`; `main` has not moved)

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The shell stops writing into the tabs: each screen that logs drinks owns its own
`+` toolbar item (`ToolbarItem(.primaryAction)` + `.glassProminent`), the action comes through
the environment, Settings has no `+`, and the shell owns one logging haptic and one animated
mutation helper.

**Architecture:** `RootShellView` becomes a plain `TabView` (no `ZStack`, no injected
toolbars) that injects two environment actions: `\.addDrink` (present the sheet) and
`\.drinkLogged` (a drink was inserted → play the logging haptic). Dashboard, Insights and
History add `AddDrinkToolbarItem()`. The haptic choice is a pure, tested function that reuses
`DashboardViewModel.todayPct`, so no limit formula is duplicated. `withMotion` replaces
History's `animatedHistoryChange` as the single animated-mutation helper. No Domain,
persistence, service or schema change.

**Tech stack:** SwiftUI `ToolbarItem(placement: .primaryAction)`, `PrimitiveButtonStyle
.glassProminent`, `@Entry` environment values, `sensoryFeedback(trigger:_:)` (closure returning
`SensoryFeedback?`), `withAnimation(.snappy)`, SwiftData `FetchDescriptor`
(`includePendingChanges` default `true`); Swift Testing; XCUITest.

**Spec:** plan 0040 ("Decisions carried into the port" `+` line and "Charts and motion",
step 4, "Accessibility audit policy", "Rules for every step"); prototype
`~/Developer/drinkpulse-native-proto/DrinkPulseNativeProto/DrinkPulseNativeProto/Shell/RootView.swift`,
`Shell/AddDrinkToolbarItem.swift`, `Components/Motion.swift`; FINDINGS "What replaced what"
(`AddDrinkButton` row), round 13 (logging haptic), round 14 (`withMotion`), round 21 (bar
controls exemption).

## Summary

Today `RootShellView` wraps the tab view in a `ZStack` with a 4 % accent wash and injects the
same `AddDrinkButton` (`.borderedProminent` + `.circle`) into all four tabs, Settings
included, and plays an impact haptic when the sheet opens. The prototype moved the button
into each screen as a system toolbar item, removed it from Settings, dropped the open-sheet
haptic and instead plays one haptic per logged drink: `.success`, or `.warning` when that
drink takes today over the daily limit. This step ports that, plus the shared `withMotion`
helper, and adds the bar-control audit exemption helper the port's audit policy needs.

## Context

- Current files (read 2026-11-21): `Features/Shell/RootShellView.swift` (175 lines; `ZStack`,
  four `.toolbar` blocks, `.sensoryFeedback(.impact(weight: .medium), trigger: showAddDrink)`,
  sheet, UI-test overlay, pending Add Drink / Insights handoff, notification tasks),
  `Shell/Components/AddDrinkButton.swift` (label `addDrink.title` = "Add Drink").
- Drink inserts by the user: `AddDrink/DrinkDetailInputView+Logic.swift` `save()` and
  `History/Components/EventContextMenu.swift` `performDuplicate()` (context menu and
  accessibility action). Edit has no Log Again yet (step 7). Imports, the Health backfill and
  UI-test seeding also insert and must **not** play the haptic.
- `animatedHistoryChange(reduceMotion:_:)` (`EventContextMenu.swift:5`, `.default`
  animation) is the only mutation animation helper; its `reduceMotion` comes from
  `@Environment(\.accessibilityReduceMotion)` only, not `DPMotion` (so the UI-test override is
  ignored there today).
- "Over the daily limit" in the app = `DashboardViewModel.todayPct > 1`
  (`RiskLevel.exceeded`): mode-mass of today's events over `effectiveDailyLimitGrams`, with
  the view model's no-profile defaults.
- UI tests on the `+`: `ShellNavigationUITests` (4 tests incl.
  `test_addDrinkButton_presentOnEveryTab_opensSheet`), `SheetDismissTabSwitchUITests`
  (Home / Insights only), gated `AccessibilityAuditUITests` (`.addDrink` opens from Home).
  All query `app.buttons["Add Drink"]`.
- Audit classes that see the `+` at AX5: Dashboard, Insights, History (old UI, baseline
  failures in open-questions "Accessibility audit failures on the old UI"); Settings
  (green since plan 0043, loses the `+`).
- Apple docs checked while drafting (Xcode MCP `DocumentationSearch`, 2026-11-21):
  `FetchDescriptor.includePendingChanges` (default `true`: a fetch sees the unsaved insert);
  `View.sensoryFeedback(trigger:_:)` with `(T, T) -> SensoryFeedback?`;
  `SensoryFeedback.success` ("task or action has completed") / `.warning`.

## Decisions (this plan)

- **D0044-1 — `+` per screen, not on Settings.** `AddDrinkToolbarItem: ToolbarContent` reads
  `@Environment(\.addDrink)` and places `Button(String(localized: "addDrink.title"),
  systemImage: "plus")` in `.primaryAction` with `.buttonStyle(.glassProminent)` and
  `.accessibilityIdentifier("addDrink.button")`. Dashboard, Insights and History add it in
  their own `.toolbar`. Label stays "Add Drink" (tests keep `app.buttons["Add Drink"]`).
- **D0044-2 — Logging haptic via an explicit action, not a store-count trigger.** The
  prototype keyed the haptic on the total event count; in the app that would fire on import,
  Health backfill and seeding, and needs a whole-store observer in the shell. Instead the two
  user log paths call `@Environment(\.drinkLogged)` with the inserted event after
  `insert` (and before or after `save`; the fetch sees pending changes). The shell fetches
  today's events and the profile, asks `LogFeedback.feedback(…)`, and bumps a
  `@State` pulse that drives `.sensoryFeedback(trigger:_:)`. The open-sheet impact haptic and
  any per-screen haptic are removed (round 13). The reminder-tap path still opens the sheet.
- **D0044-3 — Over-limit check reuses `DashboardViewModel`.** `LogFeedback` builds a
  `DashboardViewModel` (events, profile, now, calendar) and reads `todayPct`. Rejected:
  copying the formula (drift from the hero), moving `todayPct` into `Domain/` (calculation-
  module refactor, needs an owner flag; not needed for this step). `.warning` only when the
  logged drink makes today cross from `<= 1` to `> 1`; already over → `.success`; a drink
  dated before today → `.success`.
- **D0044-4 — `withMotion` replaces `animatedHistoryChange`.** `.snappy` (prototype), off
  under Reduce Motion through `DPMotion.animation(_:reduceMotion:)` so the UI-test override
  applies. Used by the context-menu duplicate / delete and by Add Drink `save()`. The History
  List/Calendar segment spring stays (navigation, not a store change; step 5 rewrites it).
- **D0044-5 — The shell `ZStack` accent wash goes without a replacement.** Today, Insights
  and History lose the 4 % accent behind their content until steps 5 / 6 apply the Frost tint
  (memory rule: no fixes to UI a later step replaces). Settings already has its own tint.
- **D0044-6 — Bar-control audit exemption (round 21, owner accepted 2026-11-20).** New
  `AuditBarControls` in the UI-test target holds the element keys of bar controls whose
  `dynamicType` / `textClipped` findings are exempt (Large Content Viewer). Start with
  `addDrink.button`; add a tab-bar key only if a run reports one. Passed per call through the
  existing `exemptElementKeys`, AX5 variants only. The attachment note in
  `assertNoAuditIssues` names the decision generically instead of "D11-28" only.

## Scope

### In
- `AddDrinkAction` + `DrinkLoggedAction` environment values, `AddDrinkToolbarItem`,
  per-screen toolbars, shell cleanup, `AddDrinkButton` deleted.
- `LogFeedback` (tested), haptic wiring in the shell, callers in Add Drink and History.
- `withMotion` (tested) replacing `animatedHistoryChange`.
- `AuditBarControls`, AX5 audit calls of Dashboard / Insights / History; UI tests for the `+`.
- `docs/architecture.md` Navigation section (shell, `+` ownership, haptic, `withMotion`).

### Out
- Frost tint on Today / Insights / History (steps 5 / 6), Edit "Log Again" (step 7),
  onboarding `fullScreenCover` and its Done haptic (step 8), `.searchable` (step 5).
- Old-UI audit failures in the open-questions baseline.

## Global constraints

- **Xcode MCP for everything it covers** (main checkout, no worktree; owner rule, memory
  "Xcode MCP first"). Session start: `XcodeListWorkspaces` → take the entry whose
  `workspacePath` ends with `drinkpulse.xcodeproj` → pass its `workspaceIdentifier` to every
  call that accepts it; `XcodeListRunDestinations` before every test call (iPhone 18 Pro,
  iOS 27.2 simulator; never the physical device).
  - Build: `BuildProject`, then `GetBuildLog` (warnings) — zero warnings.
  - Tests: `RunSomeTests` with the named classes; `GetTestList` to confirm new test names
    exist and ran. Never `RunAllTests` in this step (no full-suite checkpoint at step 4).
  - Code: `XcodeRead`, `XcodeGrep`, `XcodeGlob`, `XcodeUpdate` / `XcodeWrite`, `XcodeRM` (delete
    `AddDrinkButton.swift`), `XcodeRefreshCodeIssuesInFile` after each edited file.
  - Visual: `RenderPreview` (Light, Dark, AX5 previews).
  - **No CLI `xcodebuild` / `xcrun` without the owner's approval**, even for a named MCP gap.
    Known gap: MCP gives no coverage report (Task 5 Step 3) → ask the owner before any CLI
    coverage run; never decide it alone.
- **Apple docs first:** Xcode MCP `DocumentationSearch` (API and HIG) before each API use or
  design call, even for familiar APIs; developer.apple.com only if MCP lacks the page. Record
  query, symbol and availability per API in `execution.md`. Each task's Step 0 lists its
  lookups.
- Swift 6 strict concurrency, zero warnings. Files under 300 lines; previews for every view.
- No PII in logs: a fetch failure logs the error category only (`Logger` subsystem
  `com.drinkpulse.app`, category `Shell`); no `try?` without a comment.
- New unit tests: Swift Testing, `drinkpulseTests/Features/Shell/` and
  `drinkpulseTests/DesignSystem/`.

## Review focus

1. **Logging a drink while already over the limit** — expected `.success`, not a second
   `.warning`. Pinned in Task 2.
2. **Backdated drink** (date picker set to yesterday) while today is near the limit —
   expected `.success`; today's fraction does not change. Pinned in Task 2.
3. **No `UserProfile`** (deleted mid-session, `-dp_delete_profile_mid_session`) — expected no
   crash, view-model defaults. Pinned in Task 2; `RootShellView` UI test hook stays.
4. **Reminder tap while Settings is selected** — Settings has no `+`, the sheet must still
   open from the notification. Pinned by the existing `LaunchHandoffUITests` /
   `WeeklySummaryTapUITests` run in Task 3.
5. **Import / backfill logs no haptic** — design-level (D0044-2: only the two user paths call
   `drinkLogged`); Task 2 Step 3 greps that no importer calls it.

---

### Task 1: `withMotion`

**Files:**
- Create: `drinkpulse/DesignSystem/WithMotion.swift`
- Modify: `drinkpulse/Features/History/Components/EventContextMenu.swift` (delete
  `animatedHistoryChange`, call `withMotion`; pass the `DPMotion`-resolved flag),
  `drinkpulse/Features/AddDrink/DrinkDetailInputView+Logic.swift` (`save()` insert inside
  `withMotion`; `DrinkDetailInputView` reads `@Environment(\.accessibilityReduceMotion)`)
- Test: `drinkpulseTests/DesignSystem/WithMotionTests.swift`

**Interfaces:**
- Produces: `@MainActor func withMotion(reduceMotion: Bool, _ change: () -> Void)` — runs
  `change` exactly once; inside `withAnimation(.snappy)` unless
  `DPMotion.animation(.snappy, reduceMotion: reduceMotion)` is `nil`.

- [ ] **Step 0: Docs** — `DocumentationSearch`: `withAnimation(_:_:)`, `Animation.snappy`,
  `accessibilityReduceMotion`; HIG Motion ("make motion optional").
- [ ] **Step 1: Write the failing tests** — `test_withMotion_runsChangeOnce_whenMotionAllowed`,
  `test_withMotion_runsChangeOnce_whenReduceMotion` (counter == 1 in both).
- [ ] **Step 2: Run** `WithMotionTests` via `RunSomeTests` — FAIL (undefined).
- [ ] **Step 3: Implement** and replace both call sites; `XcodeGrep` `animatedHistoryChange` → no
  hits; `BuildProject` clean.
- [ ] **Step 4: Run** (`RunSomeTests`) `WithMotionTests`, `DPMotionTests`, `ReduceMotionHistoryUITests`,
  `DuplicateEditPersistenceUITests`, `ContextMenuDeleteConfirmationUITests`,
  `AddDrinkFlowUITests` — PASS.
- [ ] **Step 5: Commit** `[plan-0044] withMotion as the single mutation animation helper`.

### Task 2: Logging haptic

**Files:**
- Create: `drinkpulse/Features/Shell/LogFeedback.swift`,
  `drinkpulse/Features/Shell/DrinkLoggedAction.swift`
- Modify: `RootShellView.swift` (inject `\.drinkLogged`, `@State logPulse`,
  `.sensoryFeedback(trigger: logPulse) { _, new in new?.feedback }`, remove the `.impact`
  modifier), `DrinkDetailInputView+Logic.swift` and `EventContextMenu.swift` (call
  `drinkLogged(event)` after insert; `EventContextMenuModifier` gets the action as a stored
  property from the view that reads the environment)
- Test: `drinkpulseTests/Features/Shell/LogFeedbackTests.swift`

**Interfaces:**
- Consumes: `DashboardViewModel` (`events`, `profile`, `now`, `calendar`, `todayPct`).
- Produces:
  - `struct DrinkLoggedAction { var handler: @MainActor (ConsumptionEvent) -> Void = { _ in };
    @MainActor func callAsFunction(_ event: ConsumptionEvent) }`,
    `extension EnvironmentValues { @Entry var drinkLogged = DrinkLoggedAction() }`.
  - `@MainActor enum LogFeedback { static func feedback(todayEvents: [ConsumptionEvent],
    logged: ConsumptionEvent, profile: UserProfile?, now: Date, calendar: Calendar)
    -> SensoryFeedback }` — `todayEvents` includes `logged` when it is dated today; "before" =
    `todayEvents` without `logged` (by identity `===`).
  - `struct LogPulse: Equatable { let id: UUID; let feedback: SensoryFeedback }` (private to
    the shell file is fine).
  - Shell handler: fetch `ConsumptionEvent` with `consumptionDate >= startOfDay(now)` and the
    first `UserProfile`; on fetch error log and use `.success`.

- [ ] **Step 0: Docs** — `DocumentationSearch`: `sensoryFeedback(trigger:_:)` (closure form),
  `SensoryFeedback.success` / `.warning`, `Entry()` macro, `FetchDescriptor.includePendingChanges`,
  `#Predicate` with a captured `Date`; HIG Playing haptics.
- [ ] **Step 1: Write the failing tests** (WHO, female profile, metric, in-memory events):
  - `test_feedback_isSuccess_whenTodayStaysWithinLimit`
  - `test_feedback_isWarning_whenLoggedDrinkCrossesDailyLimit`
  - `test_feedback_isSuccess_whenTodayWasAlreadyOverLimit` (Review focus 1)
  - `test_feedback_isSuccess_whenLoggedDrinkIsBeforeToday` (Review focus 2)
  - `test_feedback_isWarning_withoutProfile_usesViewModelDefaults` (Review focus 3; default
    daily 20 g: one 500 ml × 5 % beer at `.standardDrinks` density 0.789 = 19.725 g → success,
    a second → warning)
  - `test_feedback_exactlyAtLimit_isSuccess` (fraction == 1 is not over)
- [ ] **Step 2: Run** `LogFeedbackTests` via `RunSomeTests` — FAIL (undefined).
- [ ] **Step 3: Implement** `LogFeedback`, `DrinkLoggedAction`, shell wiring, both callers.
  `XcodeGrep` `drinkLogged` → only `DrinkDetailInputView+Logic.swift`, `EventContextMenu.swift`,
  `RootShellView.swift`, `DrinkLoggedAction.swift` (Review focus 5).
- [ ] **Step 4: Run** (`RunSomeTests`) `LogFeedbackTests`, `AddDrinkFlowUITests`,
  `DuplicateEditPersistenceUITests`, `HealthWriteHooksUITests` — PASS.
- [ ] **Step 5: Commit** `[plan-0044] one logging haptic owned by the shell`.

### Task 3: `+` as a per-screen primary action

**Files:**
- Create: `drinkpulse/Features/Shell/AddDrinkAction.swift`,
  `drinkpulse/Features/Shell/Components/AddDrinkToolbarItem.swift` (with preview)
- Delete: `drinkpulse/Features/Shell/Components/AddDrinkButton.swift`
- Modify: `RootShellView.swift` (drop `ZStack` + accent wash and the four `.toolbar` blocks;
  `.environment(\.addDrink, AddDrinkAction { showAddDrink = true })` on the `TabView`),
  `DashboardView.swift`, `InsightsView.swift`, `HistoryView.swift` (`.toolbar {
  AddDrinkToolbarItem() }`)
- Modify tests: `drinkpulseUITests/Features/Shell/ShellNavigationUITests.swift`

**Interfaces:**
- Produces: `struct AddDrinkAction { var handler: @MainActor () -> Void = {};
  @MainActor func callAsFunction() }`, `@Entry var addDrink = AddDrinkAction()`,
  `struct AddDrinkToolbarItem: ToolbarContent` (D0044-1).

- [ ] **Step 0: Docs** — `DocumentationSearch`: `ToolbarItemPlacement.primaryAction`,
  `PrimitiveButtonStyle.glassProminent`, `Button(_:systemImage:action:)`,
  `ToolbarContent`, `accessibilityIdentifier(_:)`; HIG Toolbars, Tab bars ("use a toolbar for
  actions on the current view").
- [ ] **Step 1: Update the UI tests**
  - Rename `test_addDrinkButton_presentOnEveryTab_opensSheet` →
    `test_addDrinkButton_presentOnLoggingTabs_opensSheet`: Home, Insights, History —
    `app.buttons["addDrink.button"]` exists, is in `navigationBars[name]`, tap opens
    `navigationBars["Add Drink"]`.
  - New `test_addDrinkButton_absentOnSettings` — Settings nav bar shown,
    `app.buttons["addDrink.button"].exists == false`.
  - New `test_loggingFromHomePlus_showsDrinkInHistory` — `+` on Home → log the first preset
    with defaults → sheet gone → History shows a row for it (reuse the `AddDrinkFlowUITests`
    helper path if one exists).
- [ ] **Step 2: Run** `ShellNavigationUITests` via `RunSomeTests` — FAIL (button on Settings, no identifier).
- [ ] **Step 3: Implement**; delete `AddDrinkButton.swift` with `XcodeRM`; `XcodeGrep`
  `AddDrinkButton` → no hits; `BuildProject` clean. `RenderPreview` Dashboard, Insights,
  History, `AddDrinkToolbarItem` (Light, Dark, AX5): `+` trailing in the bar.
- [ ] **Step 4: Run** (`RunSomeTests`) `ShellNavigationUITests`, `SheetDismissTabSwitchUITests`,
  `LaunchHandoffUITests`, `WeeklySummaryTapUITests`, `SettingsUITests`,
  `OnboardingAuthorityUITests` — PASS (Review focus 4).
- [ ] **Step 5: Commit** `[plan-0044] Add Drink as each screen's primary toolbar action`.

### Task 4: Bar-control audit exemption

**Files:**
- Create: `drinkpulseUITests/Features/Shell/AccessibilityAuditBarControls.swift`
- Modify: `AccessibilityAuditSupport.swift` (attachment note text), AX5 calls in
  `DashboardAccessibilityAuditUITests`, `InsightsAccessibilityAuditUITests`,
  `HistoryAccessibilityAuditUITests`, `AccessibilityAuditUITests` (home / insights / history
  ax5)

**Interfaces:**
- Produces: `enum AuditBarControls { static let addDrink = "addDrink.button";
  static let keys: Set<String> }` — doc comment cites round 21 / UIKit
  `UILargeContentViewerInteraction`, `dynamicType` / `textClipped` only (enforced by
  `isExempt`).

- [ ] **Step 0: Docs** — `DocumentationSearch`: UIKit `UILargeContentViewerInteraction`,
  XCTest `performAccessibilityAudit(for:_:)`, `XCUIAccessibilityAuditType.dynamicType` /
  `.textClipped`.
- [ ] **Step 1: Run** (`RunSomeTests`) the Dashboard / Insights / History / Settings audit
  classes (all variants) before the change; record in `execution.md` every finding on `addDrink.button` or
  a tab-bar element, and confirm every other finding is in the open-questions baseline.
- [ ] **Step 2: Implement** `AuditBarControls` with only the keys Step 1 reported (the `+` at
  minimum if it reported); pass `exemptElementKeys: AuditBarControls.keys` to the AX5 calls.
  If Step 1 reported nothing on bar controls, still add the helper with `addDrink` and the
  calls (the policy needs the seam), and note it.
- [ ] **Step 3: Run** the same classes via `RunSomeTests` — bar-control findings gone; remaining failures exactly
  the baseline; Settings green in all three variants.
- [ ] **Step 4: Commit** `[plan-0044] bar-control audit exemption helper`.

### Task 5: Gates, docs, close

**Files:**
- Modify: `docs/architecture.md` (Navigation: `RootShellView` = plain `TabView`, injects
  `addDrink` / `drinkLogged`, owns the sheet and the logging haptic; screens own their `+`;
  `withMotion` in DesignSystem), `docs/plans/0044-shell/execution.md` (create),
  `retrospective.md`, `docs/plans/INDEX.md`, `docs/DEVLOG.md`,
  `.claude/context/current-focus.md`, `.claude/context/open-questions.md`; README only if it
  describes the `+` (`XcodeGrep` / grep first).

- [ ] **Step 1: Build** zero warnings (`BuildProject`, `GetBuildLog`).
- [ ] **Step 2: Scoped run** (`RunSomeTests`, after `XcodeListRunDestinations`) — every class named in Tasks 1–4 plus `DashboardUITests`,
  `InsightsUITests`, `HistoryInteractionUITests`. Expected: green except the baseline audit
  lines.
- [ ] **Step 3: Coverage** — `LogFeedback.swift`, `WithMotion.swift` 100 %. MCP has no
  coverage report: ask the owner before the AGENTS.md CLI coverage command; record the answer
  in `execution.md`.
- [ ] **Step 4: File size** — AGENTS.md find command (shell `find`/`wc`, not a build tool); privacy review (one new `Logger` call, error
  category only; no network).
- [ ] **Step 5: Docs close-out** — execution.md (Apple doc sources), retrospective, INDEX
  (completed), DEVLOG, current-focus (next: step 5 History, plan 0045), open-questions
  (baseline unchanged; device checks below); commit `[plan-0044] docs: close plan`.
- [ ] **Step 6:** `git switch ui-revamp && git merge --no-ff port/0044-shell`; ask the owner
  about push.

## Device check (owner)

- Haptic: log a drink within the limit → success tap; the drink that crosses the daily limit
  → warning; opening the sheet → no haptic; Log Again (context menu) → one haptic, no double.
- `+` glass button in Light / Dark on Today, Insights, History; none on Settings.
- AX5: long-press `+` shows the Large Content Viewer.
- Logging animates History / Today changes; off with Reduce Motion.

## Open questions

- [ ] D0044-5: accept Today / Insights / History without the accent wash until steps 5 / 6.
- [ ] D0044-2: accept the explicit `drinkLogged` action (no haptic on import, Health backfill
      or seeding) instead of the prototype's store-count trigger.

## Tests required

New: `WithMotionTests`, `LogFeedbackTests` (Swift Testing); `ShellNavigationUITests`
presence / absence / log-from-`+` tests. Updated: Shell UI tests that tap `+`; AX5 calls in
the three audit classes. Gate: Settings audit class green; Dashboard / Insights / History audit
classes fail only on the baseline.
