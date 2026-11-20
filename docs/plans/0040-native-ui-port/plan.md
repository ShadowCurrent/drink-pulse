# 0040 — Native UI port (programme plan)

**Status**: draft
**Size**: large (umbrella; each step gets its own plan, 0041 onwards)
**Created**: 2026-11-20

## Summary

Port the user interface of DrinkPulse to system SwiftUI components and the design accepted in
the native prototype (`~/Developer/drinkpulse-native-proto`, rounds 1–21, 2026-11-19 to
2026-11-20). The port **updates the existing views in place**. Domain, persistence, services
and view-model logic stay and are reused; only views, design-system pieces and the UI tests
that drive them change. This plan fixes the decisions, the order of the steps and the rules
every step follows. It is not executed directly: each step below becomes its own plan.

## Context

- The owner felt the app fights SwiftUI (glass on content, custom search field, a `+` injected
  by the shell, audit-driven UI branches) and asked for evidence before any rebuild. The
  prototype rebuilt every screen with system components on mock data, no tests.
- Source of truth for every decision, its API source and the rejected options:
  `~/Developer/drinkpulse-native-proto/FINDINGS.md` (rounds 1–21) and `RESUME.md`
  ("Decisions already made", "Port notes"). Copy rules: `VOICE.md` in the same folder.
  Screenshots of the accepted state: `screenshots/`.
- The prototype is a separate git repository; it is not part of this app's build.
- Owner accepted all rounds, 1–21, on 2026-11-20.
- Workflow choice (owner, 2026-11-20): superpowers-style plans in `docs/plans/`, executed inline
  one step per session; not GSD phases (token cost). Scoped test runs per step; full suite at
  checkpoints (AGENTS.md "Quality gates").

## Decisions carried into the port

UI structure
- Settings → `Form`. History → inset-grouped `List` + native `.searchable` + `.searchScopes`
  (`.navigationBarDrawer(displayMode: .always)` under the List/Calendar picker).
- `+` = `ToolbarItem(.primaryAction)` + `.glassProminent`, action passed through the
  environment; not on Settings. The shell stops injecting toolbars and the `ZStack` button.
- No Liquid Glass on content (HIG Materials); cards = `GroupBox` with one `BrandCardStyle`,
  `CardMetrics.cornerRadius = 24` for hero and every card.
- Layout switches on `isAccessibilitySize` / `DPAdaptiveStack` are Apple-documented and stay.
- Wheel pickers stay in Add / Edit Drink (named servings, `@ScaledMetric` widths,
  `.navigationLink` at accessibility sizes).

Visual design
- Palette Frost + tint: accent `#2F6CC2` Light / `#3F86E8` Dark, hero ink `#0C1B3A`; tint =
  grouped background + accent (6 % Light, 18 % Dark); Dark cards 7 % accent; Increase
  Contrast removes the accent. Tint on every screen, `List` / `Form` included
  (`scrollContentBackground(.hidden)` + `containerBackground(for: .navigation)` +
  `listRowBackground`), and in sheets.
- One risk palette `riskTone` for arc, status glyph, gauges, chart bars, over-limit text and
  calendar marks (system green / orange failed 3:1 on white cards). Prototype thresholds
  (75 % / 100 %) are placeholders: use the app's real risk levels.
- Hero gauge = risk-coloured open 240° arc (gap right), `@ScaledMetric` size, animated sweep.
  Status glyph `toneCutOut`. Icons keep natural colours, one colour per concept.
- Rounded SF on figures, large titles (`ToolbarItem(placement: .largeTitle)`, keep
  `navigationTitle`) and card titles. Copy per `VOICE.md` (Within / Close to / Over Limit,
  "Heavy days" with definition, "alcohol-free", Title Case labels, neutral weekly notification).

History
- Dense list: day total in the section header (`ViewThatFits`), no footer,
  `.listSectionSpacing(.compact)`, abbreviated month.
- Row actions: leading swipe Log Again (no full swipe), trailing swipe Delete (full swipe, no
  confirmation), context menu Log Again + Delete (confirmed); Edit screen also has Log Again.
- Calendar = `UICalendarView` with decorations (`DecoratedCalendar`, `UIViewRepresentable`) and a
  "Today" toolbar button shown off today.
- Top edge `.scrollEdgeEffectStyle(.soft, for: .top)` (`.hard` leaves a band on iOS 27.2).

Charts and motion
- Neutral Insights trend; "Daily limit" rule + caption in both charts; fewer axis values and no
  annotations at accessibility sizes; VoiceOver announcement on Insights period change.
- One animated transaction per store change (`withMotion`); period charts keyed by slot
  (`Chart(points, id: \.slot)`); logging haptic (success / warning over the daily limit) owned
  by the shell; hero count-up, glyph replace, one quiet streak bounce. All honour Reduce Motion.

Onboarding and first run
- Keep the app's onboarding design (paged `TabView`, Back + capsule dots,
  `OnboardingStepLayout`, AX-size branch), with fixes: sex required (segmented picker with no
  selection, Continue disabled; choice rows at AX sizes), only reachable pages in the
  `TabView`, date of birth behind "Add", Frost tint + `BrandSurface` cards (no
  `.thinMaterial`), `VOICE.md` copy, Back as a `.glass` circle.
- The onboarding header keeps one height on every step (reserve the Back button's space);
  otherwise the paged `TabView` jumps instead of sliding (app commit `fb697ff`).
- First run: `fullScreenCover` over the shell instead of the `if/else` swap in
  `drinkpulseApp.swift`; Today's cards rise in after `onDismiss`, arc track draws, success
  haptic on Done. Judge first-draw animations on a device, not in the simulator.
- Empty states: `ContentUnavailableView` + bordered "Log a Drink" on Insights and History;
  Today unchanged.

Accessibility audit policy (round 21, owner accepted 2026-11-20)
- Bar controls (toolbar buttons, tab bar, `.principal` picker, search scopes): exempt their
  `dynamicType` / `textClipped` findings per call and element key through `exemptElementKeys`
  in `AccessibilityAuditSupport.swift`, under a new owner decision (Large Content Viewer;
  UIKit `UILargeContentViewerInteraction`).
- Segmented controls in content get an accessibility-size alternative, never an exemption
  (onboarding sex → choice rows; Insights period → `.menu` picker).
- The audit is rebuilt on the new UI, not repaired on the old one (owner, 2026-11-20; plan
  0041 abandoned). There is no separate audit step: each port step leaves the audit class of
  the screen it ports green on the new UI, using the policy above. The bar-control exemption
  helper is added in step 4 (first bar control); the policy goes into `docs/architecture.md`
  in step 2. Audit failures that exist only in old UI are not fixed (baseline in
  open-questions, "Accessibility audit failures on the old UI").

## Step order

Each step is its own plan, ships with green scoped tests and updated UI tests, and leaves the
app working. Tokens move early so later screens are ported once, on the final look.

1. **Audit policy — dropped (owner, 2026-11-20; plan 0041 abandoned).** The audit is rebuilt
   screen by screen in the steps below (see "Accessibility audit policy"). The edge cases
   below still apply, in the step that ports each control. Edge cases: prefer accessibility identifiers as exemption keys (unlabelled system elements
   key on their frame, which is brittle); the exemption covers `dynamicType` / `textClipped`
   only; UI tests that tap a segment by label need the AX-size variant (menu / choice rows);
   check the segmented controls at XXXL (largest non-AX size, still segmented).
2. **Design tokens** — Frost palette + tint helpers, `riskTone` (replaces
   `RiskLevel.color` / `chartColor` / `textColor` and the `Risk*` assets; dynamic colours
   `@Sendable` or asset colour sets), `BrandCardStyle` + `CardMetrics`, `ArcShape`
   `animatableData`, rounded typography helpers. Replaces the ember accent of plan 0033.
3. **Settings** → `Form` (retires `SettingsSection` / `SettingsRow` over `dpGlassCard`).
4. **Shell** — `+` as `.primaryAction` via environment; remove `AddDrinkButton` and the
   `ZStack`; one mutation helper (`withMotion`) and the logging haptic.
5. **History** — inset-grouped `List`, dense headers, row actions, native search with scopes
   (replaces `HistorySearchField` from plan 0039), `UICalendarView` calendar. Edge cases to
   cover: rows stay one per event (do not regress `WrongRowContextMenuTargetUITests`); the
   oldest loaded day can be partial (window = now − 7 days, not a day boundary), so its
   header total must not be shown wrong — align the window to `startOfDay` or load the full
   day; full-swipe Delete has no confirmation and also deletes the Apple Health sample
   (plan 0036) — decide on undo; search results (`HistorySearchResultsQueryView`) get the same
   rows; measure eager row build with many loaded pages on a device.
6. **Today and Insights** — drop `dpGlassCard` from content, then the contrast colour assets
   that existed only for it; hero arc + glyph; charts; empty states.
7. **Add / Edit Drink** — tint in sheets, copy, rolling Pure Alcohol figure, Log Again.
8. **Onboarding and first run** — fixes above, `fullScreenCover`, first-run entrance.
9. **Copy pass** — `VOICE.md` table into `Localizable.xcstrings` (may be folded into steps).
10. **Calculation change (separate plan, owner hand-verifies)** — Insights `drinkFreeDays` /
    `longestSoberStreak` start at the first logged drink; confirm the 60 g heavy-day
    threshold against `docs/domain.md`. Flagged per AGENTS.md "Calculations".
11. **Cleanup** — delete `DPGlass.swift`, unused tokens and assets; living docs; full suite.

## Workflow (owner decisions 2026-11-20)

Branches
- Integration branch **`ui-revamp`**, created from `main`. The port lives there until step 11;
  `main` stays releasable for Phase 11 / milestone closure and gets no half-ported UI.
- One branch per step: **`port/00NN-short-name`** from `ui-revamp` (00NN = the step's plan
  number). Merge back with `git merge --no-ff` (a merge commit per step; no squash, the
  `[plan-00NN]` commits stay readable).
- Merge `main` into `ui-revamp` whenever `main` moves (docs, fixes), at least before each step
  starts, so the final merge has no surprises.
- `ui-revamp` → `main` **once, after step 11**: full suite, coverage report, accessibility
  audit classes, and a device pass. Not at intermediate checkpoints.
- Work in the main checkout (`~/Developer/drinkpulse`), switching branches; no worktree, so
  Xcode MCP keeps working (build, tests, previews, documentation).
- Push: after each step is merged into `ui-revamp`, ask the owner whether to push (backup).
  Every push still needs the owner's explicit "push" (AGENTS.md).

Per step (one step per session where possible)
1. Start: `git switch ui-revamp`, merge `main` if it moved, `git switch -c port/00NN-…`.
2. Write `docs/plans/00NN-…/plan.md` (draft) from this plan + the prototype files and FINDINGS
   rounds for the screen; owner reviews; freeze (`in-progress`, `Frozen:` date); add to INDEX.
3. Implement in small `[plan-00NN]` commits; consult Apple docs via Xcode MCP before each API
   change and record the source in `execution.md`.
4. Gates: zero-warning build; scoped tests for the area (unit + UI + the screen's audit class);
   full suite at the end of steps 5, 8 and 11; files under 300 lines; no PII in logs.
5. Device check list for the step (motion, haptics, VoiceOver) — the owner runs it; first-draw
   animations are judged on device only.
6. Close: `execution.md`, `retrospective.md`, INDEX, DEVLOG, living docs, current-focus,
   open-questions; merge `--no-ff` into `ui-revamp`; ask about push.

Documentation
- This plan stays the map: tick steps here only while it is a draft; once frozen, progress goes
  to its `execution.md`. Freeze it when step 2's plan (0042) is frozen.
- No ADR for the port (owner, 2026-11-20: ADRs are not used in the current workflow). The
  design rules — native system components, no Liquid Glass on content, one card style,
  `riskTone`, tint on every screen — go into `docs/architecture.md` in step 2, replacing the
  glass-card rule from plans 0018 / 0027 / 0033.
- `docs/architecture.md` (DesignSystem section, shell / `+` ownership, History container) is
  updated in the step that changes it, not at the end.
- Session handoff: `.claude/context/current-focus.md` names the current step, branch and
  next action; the prototype's `RESUME.md` stays the design reference only.

## Rules for every step

- Read the prototype file(s) for the screen and the matching FINDINGS round first; consult
  Apple documentation through Xcode MCP before each API change and record the source.
- Change views in place; keep view models stateless w.r.t. persistence (ADR-0004).
- No schema change is expected from the redesign; if one appears, stop (new schema version).
- UI tests: update identifiers and flows in the same step; a user-facing change without a
  UI test that ran is not done.
- Bugs: a bug found in the existing app during a step gets a failing test first, then the fix,
  inside that step's plan. Prototype-only defects are not ported and need no fix.
- Simulator first-draw stalls (GPU pipeline compile) are not app bugs; check motion on device.

## Contradictions with the current state (resolve before the affected step)

- Plan 0038 — closed 2026-11-20 as superseded by this plan. Its `LazyVStack` was already
  reverted (commit `420fc20`, flat per-event `List` rows). Carried into step 5: measure the
  `List` row-build cost on a device (0038's open step 7), remove the DEBUG `extendListWindow`
  logger (0038 step 8), keep the 7-day page.
- Plan 0039 (`HistorySearchField`, inline search) is replaced by native `.searchable`.
- Plan 0033 fixed the ember accent; the port replaces it with the Frost accent.
- Phase 11 — resolved: milestone v1.4 is archived (2026-11-18), so the port starts after it.

## Open questions

- [x] Round 21 audit policy — accepted 2026-11-20.
- [x] Plan 0038 — superseded by 0040 (2026-11-20).
- [x] Start before or after Phase 11 / milestone closure — after: milestone v1.4 was completed
      and archived on 2026-11-18 (`.planning/STATE.md`).
- [ ] App icon in the Frost palette (Icon Composer) — in scope or later.
- [ ] History pagination (`LoadMoreSentinel`) against real `@Query` volume — not prototyped.
- [ ] Drink icons: emoji vs a custom SF Symbols set — later.
- [ ] On-device checks still open: History swipe and context menu, calendar tapping and
      paging, VoiceOver on calendar decorations, menu picker and choice rows, Insights
      announcement, rounded large title collapse, haptics.

## Tests required

Per step, in that step's plan: updated unit tests for any moved logic, UI tests for every
changed screen (driving the real flow), the accessibility audit classes for the screen, and
the coverage targets in AGENTS.md. Full suite at the end of steps 5, 8 and 11.
