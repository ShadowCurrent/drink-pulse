# 0032 — UI Test Coverage Completion

**Status**: in-progress
**Size**: large
**Created**: 2026-06-24
**Frozen**: 2026-06-24

## Summary

Bring `drinkpulseUITests` from partial, ad-hoc coverage to a complete set
covering every user-facing feature and its components. Work proceeds
**feature by feature**, never all at once. Each feature's UI tests are
written by a dedicated **Opus 4.8 subagent**, dispatched **sequentially**
(one finishes, is reviewed, then the next starts — never simultaneously).

## Context

CLAUDE.md makes a UI test mandatory for every user-facing feature
("any new screen, any change to an existing screen's behaviour, controls,
or displayed values"). Today only narrow regressions are covered:

- `AddDrinkPickerFilterUITests` — US oz serving labels
- `VolumeServingUITests` — pint serving + provenance name stability
- `EditVolumeIntegrityUITests` — edit-untouched preserves stored volume
- `HistoryUnitDisplayUITests` — unit switch re-renders subtitle
- `ExportUITests` — save panel confirm / dismiss
- `OnboardingLocaleDefaultUITests` — locale → default unit

Whole screens have **no** UI test: Dashboard, Insights, the Shell tab
navigation, the full Onboarding walkthrough, most of Settings, and most of
History (calendar, context menu, edit name/notes/category).

### Constraints (carry into every subagent)

1. **No accessibility identifiers exist in the app today.** Tests key off
   app-rendered **English** text, `navigationBars[...]`, `tabBars.buttons[...]`,
   and picker `.value`. The app's own strings are English-only, so asserting
   on app text is safe. **Never** match system-process UI (save/share sheets,
   system alerts) by localized label — the simulator system locale is Polish.
   Add `accessibilityIdentifier` to app views **only** when an element is not
   uniquely addressable by visible text; such additions are additive, change
   no behaviour, and must keep the build warning-clean.
2. **Test hooks** (gated on launch args, inert in production — see
   `drinkpulse/UITestSeed.swift`):
   - `-dp_uitest YES` → in-memory store + deterministic profile + one
     500 ml 5% beer event.
   - `-dp_uitest_unit metric|usCustomary|imperial` → seeded profile unit.
   - `-dp_uitest_provenance YES` → single 568 ml imperial beer instead.
   - `-dp_onboarding_done YES` → skip onboarding.
   - `-dp_force_onboarding YES` → always show onboarding, skip seeding.
   Subagents **may extend** `UITestSeed` with new **gated, additive,
   synthetic-only** launch args (e.g. a multi-day data set for Insights /
   calendar). New fixtures carry **no PII / health data**, mirror the
   existing gating pattern, and stay inert in production.
3. **UI test files are auto-included** (`drinkpulseUITests` is a
   `PBXFileSystemSynchronizedRootGroup`) — no `project.pbxproj` edit needed.
   Still **verify each new test actually ran** (its name appears in the
   test log), per CLAUDE.md.
4. Files < 300 lines; split helpers if a test file grows.
5. Build clean (zero warnings), whole `xcodebuild test` green before a
   feature is declared done.

## Scope

### In
- One new (or extended) UI test file per feature, covering each feature's
  primary user-visible flows and component behaviours.
- Minimal additive app-code changes strictly in service of testability:
  `accessibilityIdentifier`s where text is ambiguous; new gated
  `UITestSeed` fixtures.

### Out
- Unit-test changes (already at ≥90%; this plan is UI-layer only).
- Redesign or behaviour changes to any screen.
- New product features. No network, no analytics (unchanged invariants).
- Touching the calculation module.

## Per-feature coverage targets

| # | Feature | New UI test(s) must assert |
|---|---------|----------------------------|
| 1 | **Shell** | All 4 tabs (Home / Insights / History / Settings) reachable & switch content; FAB "Add Drink" visible on every tab and opens the Add Drink sheet; sheet dismiss returns to prior tab. |
| 2 | **Dashboard** | Hero arc card renders a consumption value reflecting the seeded beer; metric cards present; chip row present; ThisWeek card present; logging a drink updates the visible total. |
| 3 | **AddDrink** (complete) | Full log flow: open → pick category → detail → Save → event appears in History; drink-type grid shows categories; quantity ×N control changes the logged count; custom name path. Keep existing picker/serving tests. |
| 4 | **History** | List ↔ Calendar segment switch; tap a calendar day → day detail; context menu Duplicate adds an event; context menu / swipe Delete removes it; edit custom name & notes persist; edit category change persists. Keep existing edit/unit tests. |
| 5 | **Insights** | Period picker switches range; area chart, weekday bar chart present (chart elements or their a11y summary); hero card value; health metrics rows; guideline comparison card. May need a multi-day seed fixture. |
| 6 | **Onboarding** | Full 3-step walkthrough Welcome → Profile → Guideline → Finish lands on Dashboard; Skip path; profile inputs (weight/sex) carry into Settings. Keep existing locale-default tests. |
| 7 | **Settings** | Theme / appearance switch takes effect; guideline picker change persists & reflects in app; unit-system switch reflects in displayed volumes; app-lock toggle; data section visible. Keep existing export tests. |

## Implementation steps

Each step = one Opus 4.8 subagent = one feature = one commit
(`[plan-0032] UI tests: <feature>`). **Sequential**: dispatch step N+1 only
after step N's tests are green, reviewed, and committed.

1. Shell — `ShellNavigationUITests`
2. Dashboard — `DashboardUITests`
3. AddDrink — `AddDrinkFlowUITests` (complement existing files)
4. History — `HistoryInteractionUITests` (complement existing files)
5. Insights — `InsightsUITests` (+ multi-day seed if needed)
6. Onboarding — `OnboardingFlowUITests` (complement locale test)
7. Settings — `SettingsUITests` (complement export test)

After all 7: full-suite green run, then end-of-task checklist (DEVLOG,
current-focus, INDEX → completed, retrospective).

## Subagent dispatch contract

Each subagent receives: this plan's Constraints block, the target feature
row, the relevant view files, and the existing test that most resembles the
work. It must:
- Write the test file under `drinkpulseUITests/`.
- Run `xcodebuild test` for the UITests target on iPhone 17 Pro.
- Confirm each new test name appears in the run log (not silently skipped).
- Keep build warning-clean; respect locale-independence & no-PII rules.
- Report back: files added, launch args/fixtures introduced, test names,
  pass/fail evidence.

The main thread reviews each report before dispatching the next agent.

## Files

| File | Action |
|------|--------|
| `drinkpulseUITests/ShellNavigationUITests.swift` | Create |
| `drinkpulseUITests/DashboardUITests.swift` | Create |
| `drinkpulseUITests/AddDrinkFlowUITests.swift` | Create |
| `drinkpulseUITests/HistoryInteractionUITests.swift` | Create |
| `drinkpulseUITests/InsightsUITests.swift` | Create |
| `drinkpulseUITests/OnboardingFlowUITests.swift` | Create |
| `drinkpulseUITests/SettingsUITests.swift` | Create |
| `drinkpulse/UITestSeed.swift` | Modify (additive gated fixtures, as needed) |
| `drinkpulse/Features/**` | Modify (add `accessibilityIdentifier` only where text is ambiguous) |

## Open questions

- [x] Locate elements by visible English text or by added a11y identifiers?
  → **Default to visible English text + nav/tab bars + picker values**
  (matches existing tests & is locale-safe). Add `accessibilityIdentifier`
  only when an element is not uniquely addressable. Adding ids must not
  change behaviour and must keep the build clean.
- [x] May subagents extend `UITestSeed`?
  → **Yes** — additive, launch-arg-gated, synthetic-only, inert in
  production (mirror existing pattern).
- [ ] Insights/calendar may need a richer multi-day fixture — confirm the
  fixture shape (how many days / events) when step 5/4 starts.

## Tests required

- One green UI test file per feature (steps 1–7), each asserting the
  user-visible outcomes in the coverage table.
- Every new test confirmed to actually execute (name in test log).
- Full `xcodebuild test` suite green after each step and at the end.
