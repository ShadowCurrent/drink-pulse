# 0041 — Port step 1: accessibility audit policy

**Status**: abandoned (2026-11-20)
**Size**: small
**Created**: 2026-11-20
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 1
**Branch**: `port/0041-audit-policy` (from `ui-revamp`)

> **Abandoned 2026-11-20 (owner):** not executed. Most of it repaired audit failures in old UI
> that the port replaces (Insights stat tiles, Home header, Onboarding CTA, segmented controls).
> The audit is rebuilt on the new UI instead, step by step (plan 0040 "Accessibility audit
> policy"); the baseline below moved to open-questions; the bar-control helper moves to step 4.

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the accessibility audit a trustworthy gate for the port: every ungated audit
class green on `ui-revamp`, and the round-21 audit policy recorded and wired into the shared
audit helper.

**Architecture:** Test-side change in `drinkpulseUITests/Features/Shell/` plus small view fixes
for the failures the diagnosis shows to be real app defects. No Domain, persistence, service or
view-model change. No schema change.

**Spec:** plan 0040 ("Accessibility audit policy", step 1 edge cases); prototype
`~/Developer/drinkpulse-native-proto/FINDINGS.md` round 21; open question "Five accessibility
audit tests fail on main" in `.claude/context/open-questions.md`.

## Summary

Step 1 of the native UI port. Later steps add bar controls (`+` as `.primaryAction`, the
History List/Calendar picker in `.principal`, native `.searchScopes`) whose `dynamicType` /
`textClipped` findings at accessibility sizes are expected and accepted (Large Content Viewer).
Before that, the audit must be green on the current app, otherwise a port regression cannot be
told apart from an old failure. This plan (a) diagnoses and resolves the audit failures that
exist today, (b) records decision **D0041-1** (bar controls) and **D0041-2** (segmented
controls in content), and (c) adds the shared bar-control exemption so steps 4 and 5 use one
named, reviewable set instead of ad-hoc keys.

## Context

Baseline run, 2026-11-20, Xcode MCP `RunSomeTests`, iPhone 18 Pro simulator, iOS 27.2, branch
`port/0041-audit-policy` at `c1b4bec` (same app code as `main`): 9 tests, 5 passed, 4 failed.

| Test | Finding |
|------|---------|
| `DashboardAccessibilityAuditUITests.test_home_standard` | `contrast` on `20. Nov · WHO (Global)` (header subtitle, `DashboardView.swift:49-51`, `.subheadline` + `.secondary`) |
| `InsightsAccessibilityAuditUITests.test_insights_standard` | `dynamicType` on `Longest Streak`, `1/5`, `1 d`, `20%`, `Drink-Free Days` (`HealthMetricsCard.swift` stat tiles) |
| `InsightsAccessibilityAuditUITests.test_insights_dark` | same five as standard |
| `OnboardingAccessibilityAuditUITests.test_onboardingWelcome_standard` | `contrast` on `Get Started` |

Differences from the open question (2026-11-19): Dashboard **dark now passes**; Onboarding now
reports an element (`Get Started`) instead of an element-less issue; Insights values changed
(`1/4` → `1/5`, `25%` → `20%`). The seeded `multiday` dataset is relative to "now", so content
moves with the date. The open question also notes all five were green in the Phase 11 final run
(plan 11-23). So the diagnosis must separate **date-dependent content** from **flaky rendering**.

Prior audit decisions (still in force, recorded in the archived
`.planning/milestones/v1.4-phases/11-ios-27-release-verification/11-CONTEXT.md` and
ADR-0013): D11-22 no allow-list; D11-28 per-call `exemptElementKeys` for Form controls
(`dynamicType` / `textClipped` only); D11-29 tab-bar-occluded content; D11-30 chart day-mark hit
regions; D11-31 element-less contrast under the tab bar. The D11 numbering belongs to the
archived Phase 11; port decisions use `D0041-n` and are recorded in this plan and in
`docs/architecture.md`.

Documentation contradiction found while reading (fix in Task 5): `.claude/context/current-focus.md`
says "re-run the Phase 11 verifier, then milestone closure", but `.planning/STATE.md` says
milestone v1.4 was completed and archived on 2026-11-18. Plan 0040's open question "start before
or after Phase 11 / milestone closure" is therefore answered: after.

## Decisions (owner accepted round 21, 2026-11-20; recorded here under port ids)

- **D0041-1 — Bar controls at accessibility sizes.** Toolbar buttons (`+`, Back, Today), the
  tab bar, a `.principal` picker and native `.searchScopes` stay small by design; the system
  offers the Large Content Viewer on long press (Apple: UIKit `UILargeContentViewerInteraction`,
  "Rely on the large content viewer only in situations where items must remain small due to
  unavoidable design constraints. For example, buttons in a tab bar remain small.").
  Their `dynamicType` and `textClipped` findings are exempt, per call, by element key, through
  `exemptElementKeys`. Keys are accessibility identifiers wherever the app can set one; a label
  key only for system elements without an identifier (tab bar buttons); never a frame key.
  Every other audit type on a bar control still fails. Reversible: drop the argument.
- **D0041-2 — Segmented controls in content get an accessibility-size alternative, never an
  exemption.** Onboarding sex → choice rows; Insights period → `.menu` picker (implemented in
  steps 8 and 6, not here).

## Scope

### In
- Baseline of every ungated audit class, repeated to separate date-dependent from flaky.
- Root cause and resolution for each current failure (fix if app defect; owner decision if not).
- `AuditBarControls` shared exemption set + identifier convention (D0041-1).
- XXXL (largest non-accessibility size) audit check of the existing segmented controls, as input
  for steps 5, 6 and 8.
- Living docs: `docs/architecture.md` audit policy, open-questions, current-focus, plan 0040
  open question, INDEX, DEVLOG.

### Out
- New bar controls themselves (steps 4, 5).
- AX-size alternatives for segmented controls (steps 6, 8).
- Palette / contrast token changes (step 2) — a contrast failure caused by the ember accent is
  fixed here only if the fix is local and does not pre-empt step 2's palette; otherwise it goes
  to the owner (Task 3).
- The gated full class `AccessibilityAuditUITests` (`DP_RUN_A11Y_AUDIT`) — not run in this step.

## Global constraints

- Simulator only: Xcode MCP, active destination **iPhone 18 Pro (iOS 27.2) simulator**; never
  the physical device. Check `XcodeListRunDestinations` before every test call.
- Apple docs via Xcode MCP `DocumentationSearch` before each API change; source recorded in
  `execution.md`.
- No allow-list, no `XCTExpectFailure`, no hiding content from accessibility to pass an audit
  (ADR-0013, D11-22).
- Bug fix = failing test first. The failing audit test is that test; a fix is done when the same
  test passes 3 runs in a row.
- Files under 300 lines: `AccessibilityAuditSupport.swift` is at 274, so new helper code goes in
  a new file.

## Review focus

1. A fix that makes the audit pass by shrinking content out of the audit (lineLimit, hidden
   elements, clipping) instead of fixing it — reviewer checks each diff against ADR-0013.
2. Date dependence: a fix verified only on 2026-11-20 content. Verify with the seed shifted
   (Task 2 step 3).
3. Flaky contrast over Liquid Glass / tint: a pass on one run is not a pass; 3 runs.
4. Exemption creep: `AuditBarControls` must not contain a content element key.
5. Insights AX5 currently passes — the Insights fix must not regress it (run all three
   variants).

---

## Implementation steps

### Task 1: Baseline and stability

**Files:** none changed. Record in `docs/plans/0041-port-audit-policy/execution.md`.

- [ ] **Step 1:** Run every ungated audit class via `RunSomeTests` (simulator): Dashboard,
  Insights, Onboarding, History, HistorySearch, Settings, AddDrink `*AccessibilityAuditUITests`,
  plus `ProbeAccessibilityAuditUITests`.
- [ ] **Step 2:** Re-run the failing tests twice more. Record per test: findings per run and
  whether they are identical across runs.
- [ ] **Step 3:** Record the table in `execution.md`. A finding that differs between runs is
  "flaky"; one stable across runs is "stable".

Expected: the 4 known failures; any other failure is new and goes into Task 2 / 3 the same way.

### Task 2: Insights stat tiles — `dynamicType` at default size

**Files:**
- Modify: `drinkpulse/Features/Insights/Components/HealthMetricsCard.swift` (stat tile, ~lines 127-142)
- Test: `drinkpulseUITests/Features/Insights/InsightsAccessibilityAuditUITests.swift` (existing)

Hypothesis: the tile value has `.minimumScaleFactor(0.7)` and title / value / subtitle have
`.lineLimit(1)` at non-AX sizes; when today's content is wider than the tile, text renders
smaller than its Dynamic Type size, which the `dynamicType` audit reports.

- [ ] **Step 1:** Confirm with `superpowers:systematic-debugging`: read `DocumentationSearch`
  for `XCUIAccessibilityAuditType.dynamicType`; in a preview at default size with the failing
  strings (`1 d`, `20%`, `1/5`, `Drink-Free Days`, `Longest Streak`), check whether they scale or
  truncate.
- [ ] **Step 2:** Fix per ADR-0013 rule "wrapping instead of one-line limits": remove
  `minimumScaleFactor` and the non-AX `lineLimit(1)` (allow wrap, `fixedSize(horizontal: false,
  vertical: true)` if needed); keep the AX branch unchanged.
- [ ] **Step 3:** Run `InsightsAccessibilityAuditUITests` (all 4 tests) 3 times. Expected: all
  pass every run, AX5 included. Run `InsightsDynamicTypeUITests` and `InsightsUITests` once.
- [ ] **Step 4:** Commit `[plan-0041] insights stat tiles wrap instead of scaling`.

If the hypothesis is wrong, stop, record the evidence, and go to the owner checkpoint (Task 3
step 4) for this finding too.

### Task 3: Contrast findings — Home header subtitle, Onboarding "Get Started"

**Files (if fixed):**
- Modify: `drinkpulse/Features/Dashboard/DashboardView.swift:49-51`
- Modify: the Onboarding welcome CTA view (`drinkpulse/Features/Onboarding/Components/WelcomeStep.swift`
  and its button component)
- Test: `DashboardAccessibilityAuditUITests`, `OnboardingAccessibilityAuditUITests` (existing)

- [ ] **Step 1:** For each finding, take a screenshot in the failing variant (simulator) and
  identify what lies behind the text (glass card, tint, gradient, button fill). Record the colour
  pair and the measured ratio against the AGENTS.md thresholds (4.5:1 body, 3:1 large).
- [ ] **Step 2:** Classify: (a) app defect with a local fix that step 2's palette does not
  replace; (b) caused by a token step 2 replaces (ember accent, glass surfaces); (c) audit
  artifact (ratio passes when measured).
- [ ] **Step 3:** (a) → fix, run the class 3 times, commit `[plan-0041] <screen> contrast fix`.
- [ ] **Step 4:** (b) or (c) → **owner checkpoint**: present evidence and options (fix now /
  leave red until step 2 or 8 with a dated open-question entry / narrow decision-scoped
  opt-in). No exemption without the owner's answer.

### Task 4: Bar-control exemption (D0041-1) and XXXL check (D0041-2 input)

**Files:**
- Create: `drinkpulseUITests/Features/Shell/AccessibilityAuditBarControls.swift`
- Modify: `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift` (doc comment only:
  list D0041-1 next to D11-28)
- Modify: `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift` `AuditLaunch`: add
  `static let xxxlCategory = "UICTContentSizeCategoryXXXL"`
- Modify: `InsightsAccessibilityAuditUITests.swift`, `HistoryAccessibilityAuditUITests.swift`
  (add an `xxxl` variant each)

**Interfaces (produced, used by steps 4 and 5):**
```swift
/// D0041-1: bar controls keep their size; the Large Content Viewer covers them.
enum AuditBarControls {
    /// Tab bar button labels (system elements, no app identifier).
    static let tabBar: Set<String>            // "Today", "History", "Insights", "Settings" — copy the real labels
    /// Element keys for the bar controls of one screen: tab bar + the given identifiers.
    static func keys(identifiers: Set<String>) -> Set<String>
}
```
Identifier convention for app-owned bar controls added in later steps: `bar.<screen>.<control>`
(e.g. `bar.shell.addDrink`, `bar.history.modePicker`, `bar.history.today`).

- [ ] **Step 1:** Check `DocumentationSearch` for `XCUIElement.identifier` behaviour on
  toolbar items / segmented picker segments, and record whether search-scope segments expose
  an identifier (if not, D0041-1 allows label keys for them only).
- [ ] **Step 2:** Create the file with the interface above; tab-bar labels taken from
  `ShellNavigationUITests` / the running app, not guessed.
- [ ] **Step 3:** Add `xxxl` variants: `test_insights_xxxl_hasNoAuditIssues`,
  `test_history_xxxl_hasNoAuditIssues` (types `.all`, same opt-ins as the standard variant of
  each class, plus `exemptElementKeys: AuditBarControls.keys(identifiers: [])`).
- [ ] **Step 4:** Run both classes. Record the result per segmented control (Insights period,
  History List/Calendar, History search scopes). A segmented control in content that fails at
  XXXL is input for step 6 / 8 (D0041-2) — record it in `execution.md` and plan 0040's open
  questions; a bar control finding is covered by the exemption. If a content finding fails, the
  owner decides whether the variant stays red until that step or waits for it (checkpoint).
- [ ] **Step 5:** Build with zero warnings; commit `[plan-0041] bar-control audit exemption (D0041-1) and xxxl variants`.

### Task 5: Docs and close

- [ ] `docs/architecture.md` "Accessibility and motion": audit policy bullet — D0041-1 and
  D0041-2, `AuditBarControls`, identifier convention.
- [ ] `.claude/context/open-questions.md`: resolve "Five accessibility audit tests fail on main"
  with the outcome per finding.
- [ ] `.claude/context/current-focus.md`: fix the v1.4 contradiction; name step 2 (plan 0042,
  design tokens) as next.
- [ ] Plan 0040: tick its open question "Start before or after Phase 11" (answered: after,
  milestone v1.4 archived 2026-11-18); freeze it (`in-progress`, `Frozen: <date>`) together with
  this plan, as plan 0040 "Documentation" says.
- [ ] `execution.md`, `retrospective.md`, `docs/plans/INDEX.md` (0040, 0041), `docs/DEVLOG.md`.
- [ ] Gates: zero-warning build; all ungated audit classes from Task 1 green (or owner-recorded);
  file-size check; no production logging change.
- [ ] Merge `--no-ff` into `ui-revamp`; ask the owner about push.

## Files

| File | Action |
|------|--------|
| `drinkpulse/Features/Insights/Components/HealthMetricsCard.swift` | Modify (Task 2) |
| `drinkpulse/Features/Dashboard/DashboardView.swift` | Modify if Task 3 (a) |
| `drinkpulse/Features/Onboarding/Components/WelcomeStep.swift` (+ button component) | Modify if Task 3 (a) |
| `drinkpulseUITests/Features/Shell/AccessibilityAuditBarControls.swift` | Create |
| `drinkpulseUITests/Features/Shell/AccessibilityAuditSupport.swift` | Modify |
| `drinkpulseUITests/Features/Insights/InsightsAccessibilityAuditUITests.swift` | Modify |
| `drinkpulseUITests/Features/History/HistoryAccessibilityAuditUITests.swift` | Modify |
| `docs/architecture.md`, open-questions, current-focus, plan 0040, INDEX, DEVLOG | Modify |
| `docs/plans/0041-port-audit-policy/execution.md`, `retrospective.md` | Create |

## Open questions

- [ ] Contrast findings (Task 3): fix now or wait for step 2 palette — decided at the Task 3
      checkpoint with evidence.
- [ ] XXXL content failures (Task 4): red until steps 6 / 8, or add the variant only in those
      steps — decided at the Task 4 checkpoint if one fails.

## Tests required

- Existing audit classes as the failing tests for Tasks 2 and 3 (3 green runs each).
- New: `test_insights_xxxl_hasNoAuditIssues`, `test_history_xxxl_hasNoAuditIssues`.
- Regression: `InsightsDynamicTypeUITests`, `InsightsUITests`, and for any Task 3 fix the
  screen's UI class (`DashboardUITests` / `OnboardingFlowUITests`).
- No unit-test change (no logic moves); coverage unaffected.
