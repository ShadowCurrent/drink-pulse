# 0043 — Port step 3: Settings → Form

**Status**: draft
**Size**: medium
**Created**: 2026-11-20
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 3
**Branch**: `port/0043-settings-form` (from `ui-revamp` at `9732e7e`; `main` has not moved)

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the Settings screen as a system `Form` with the Frost tint and rounded large
title, keep every setting, action and side effect it has today, and retire the glass-card
building blocks (`SettingsSection`, `SettingsRow`, `SettingsMenuPicker`, `SettingsActionRow`,
`GuidelinePickerSheet`).

**Architecture:** `SettingsView` stays the `@Query` container; `SettingsForm` becomes a `Form`
whose sections are small views in `Features/Settings/Components/`, one per section, each
returning `Section { … } header: { … } footer: { … }`. Feature state (`@AppStorage`, service
calls, permission handling, import / export, backfill) stays in the section views exactly as
today; only the containers and controls change. The one piece of shared logic, the "write and
`touch()` only on change" binding, moves out of the view into a tested
`UserProfile` extension. No Domain, persistence, service or view-model change; no schema change.

**Tech stack:** SwiftUI `Form`, `Section` (header / footer), `Picker` (menu default and
`.navigationLink`), `Toggle`, `DatePicker`, `Link`, `Button(role: .destructive)`,
`LabeledContent`; brand helpers from plan 0042 (`brandListBackground()`, `brandRowBackground()`,
`brandNavigationTitle(_:)`, `GroupBox` + `BrandCardStyle`); Swift Testing; XCUITest.

**Spec:** plan 0040 ("Decisions carried into the port", step 3, "Accessibility audit policy",
"Rules for every step"); prototype
`~/Developer/drinkpulse-native-proto/DrinkPulseNativeProto/DrinkPulseNativeProto/Settings/SettingsView.swift`;
FINDINGS round 1 (Settings row, trade-off 6), round 9 (tint on List / Form), round 16 (copy),
round 19 point 4 (onboarding guideline card); `VOICE.md` rows `settings.*`;
screenshots `settings.png`, `settings-dark.png`.

## Summary

Settings today is a `ScrollView` of glass cards with hand-built rows, manual dividers, a
custom AX-size menu picker and a guideline sheet with hand-drawn checkmarks (551 lines over 8
files in the prototype count). The prototype showed the same screen as a `Form` in about a
quarter of the code. This step ports that design in place: same sections, same settings, same
service behaviour, system controls, Frost tint, rounded large title, `VOICE.md` copy for the
Settings strings. The `+` toolbar button stays on Settings until step 4 (shell) removes it.

## Context

- Current files (read 2026-11-20): `SettingsView.swift` (238 lines: `SettingsView` +
  private `SettingsForm` with Profile, Guideline, Preferences, Privacy inline, plus helpers
  `touching`, `dobBinding`, labels), `Components/` `SettingsSection`, `SettingsRow` (+
  `SettingsMenuPicker`), `SettingsActionRow`, `AppearanceModeRow`, `GuidelineChoiceRow`,
  `GuidelinePickerSheet`, `ReminderSection`, `WeeklySummarySection`, `HealthSection`,
  `DataSection` (235 lines), `AppVersionFooter`.
- `SettingsSection` + `GuidelineChoiceRow` are also used by onboarding
  (`Onboarding/Components/GuidelineStep.swift:40`).
- `settings.systemLock.footer` ("Managed by iOS. To enable, open Settings → DrinkPulse →
  Require Face ID.") exists in the catalog but is unused; it becomes the Privacy footer.
- The shell (`RootShellView.swift:63`) wraps `SettingsView` in a `NavigationStack` and adds the
  `+` toolbar item; `ShellNavigationUITests.test_addDrinkButton_presentOnEveryTab_opensSheet`
  depends on it. Step 4 owns that change.
- UI tests touching Settings: `Features/Settings/*` (9 classes) plus
  `Onboarding/OnboardingWeeklySummaryUITests`, `Onboarding/OnboardingLocaleDefaultUITests`,
  `History/HistoryUnitDisplayUITests`, `AddDrink/VolumeServingUITests` (volume picker by
  label `CONTAINS 'Millilitres' OR 'fl oz'`), `AddDrink/CurrencyUITests`.
- `SettingsDynamicTypeUITests` scrolls with `app.scrollViews.firstMatch`; a `Form` is a
  collection view, so that query changes.

## Decisions (this plan)

- **D0043-1 — Sections kept, containers native.** Order and content stay: Profile, Health
  Guideline, Preferences, Reminders, Weekly Summary, Apple Health, Privacy & Security, Data,
  Delete (own section, text-only destructive button — FINDINGS trade-off 6), version footer.
  The prototype's merged "Notifications" section is not taken: Reminders and Weekly Summary
  each keep their own hint / denied text as a section footer, and a `Section` has one footer.
- **D0043-2 — Hints and denied messages become section footers.** Footer text = the hint, or
  the denied message in `.red` when permission was denied (same strings, same state). The
  "Open Settings" action stays a row (`Button` with `Label`, trailing
  `arrow.up.right.square`) shown only when denied.
- **D0043-3 — Guideline = `Picker(.navigationLink)`.** Option content: name + threshold
  summary (`.subheadline`, `.secondary`). Footer: new string "Limits are compared in grams of
  pure alcohol." (true per `docs/domain.md`: limits stay in physical grams). The sheet, its
  Close button and the `guidelineChoiceRow.*` identifiers in Settings go away; the pushed list
  gives the checkmark and the selected trait natively.
- **D0043-4 — Preference pickers are plain `Picker`s (menu style by default in a `Form`).**
  `SettingsMenuPicker` existed for value clipping at AX sizes (brief C016) in the old row. If
  `SettingsDynamicTypeUITests` still finds clipped or unreachable pickers at AX5, the fallback is
  fixed now: `.pickerStyle(.navigationLink)` when `dynamicTypeSize.isAccessibilitySize` (same
  pattern as Add / Edit Drink wheels, plan 0040) via one modifier
  `settingsPickerStyle()` in `PreferencesSection.swift`. No custom `Menu`.
- **D0043-5 — Kept from the app, not the prototype:** `fileExporter` / `fileImporter` export
  and both import rows (prototype used `ShareLink` on a mock), the delete-all `alert` with its
  long irreversible-action message, the DOB default (30 years ago until changed; the "Add"
  pattern is onboarding only, step 8), `AppVersionFooter` (debug build info, text selection,
  identifier `settings.appVersion`) as the footer of the Delete section.
- **D0043-6 — Onboarding guideline list.** `GuidelineStep` loses `SettingsSection`; it takes
  `GroupBox` + `BrandCardStyle` (round 19 point 4, the final onboarding design), and
  `GuidelineChoiceRow` moves to `Onboarding/Components/` (its only caller). The rest of
  onboarding is untouched until step 8.
- **D0043-7 — Copy folded into this step** (plan 0040 step 9 allows it), `VOICE.md` rows marked
  ok + FINDINGS round 16:

  | Key | Now | New |
  |-----|-----|-----|
  | `settings.data.export` | Export all data | Export All Data |
  | `settings.data.deleteAll` | Delete all data | Delete All Data |
  | `settings.data.importDP` | Import DrinkPulse backup | Import DrinkPulse Backup |
  | `settings.reminder.toggle` | Daily log reminder | Daily Reminder |
  | `settings.weeklySummary.toggle` | Weekly check-in | Weekly Summary |
  | `settings.weeklySummary.denied` | …get your weekly check-in. | …get your weekly summary. |
  | `settings.volumeUnit` | Volume unit | Volume Unit |
  | `settings.alcoholUnit` | Alcohol unit | Alcohol Unit |
  | `settings.abvPrecision` | ABV precision | Strength Step |
  | `settings.section.guideline` | Guideline | Health Guideline |
  | `settings.guideline.picker` (new) | — | Guideline |
  | `settings.guideline.footer` (new) | — | Limits are compared in grams of pure alcohol. |

  `onboarding.*` keys are not changed (step 8).

## Scope

### In
- `Form` Settings with tint, row surface, rounded large title (`brandNavigationTitle`),
  `.navigationBarTitleDisplayMode` default (large).
- Section views; tested `UserProfile.touchingBinding(_:)`.
- Deleting the five retired components; onboarding guideline card swap (D0043-6).
- Copy table above; all affected UI tests; Settings audit classes green on the new UI.
- `docs/architecture.md` Settings / DesignSystem lines that name the removed components.

### Out
- Removing `+` from Settings and any shell change (step 4).
- Onboarding redesign beyond D0043-6 (step 8).
- Increase Contrast colour variants (open, plan 0042).
- `Color.dpSecondaryText` and `DPGlass.swift` removal (step 11), even if Settings stops using
  them.

## Global constraints

- Simulator only (iPhone 18 Pro, iOS 27.2) through Xcode MCP; never the physical device.
  `XcodeListWorkspaces` → `workspaceIdentifier` first; `XcodeListRunDestinations` before every
  test call.
- Apple docs via Xcode MCP `DocumentationSearch` before each API use; record source and
  availability in `execution.md`. Look up: `Form`, `Section` (`header:footer:`),
  `NavigationLinkPickerStyle` / `PickerStyle.navigationLink` (pop on selection),
  `MenuPickerStyle` in a form, `Link`, `ButtonRole.destructive`, `scrollContentBackground(_:)`,
  presentation modifiers (`alert`, `fileImporter`, `fileExporter`, `confirmationDialog`) on a
  view inside a `Form`; HIG Settings, Toggles, Pickers.
- Swift 6 strict concurrency, zero warnings. Files under 300 lines; one concept per file;
  previews for every view (Light, Dark, AX5 for `SettingsView`).
- No new logging; existing `Logger` calls keep their interpolation privacy.
- New unit tests: Swift Testing, `drinkpulseTests/Features/Settings/`.

## Review focus

1. **AX5 picker values clip or a picker is unreachable** (C016 regression) — expected: every
   preference picker hittable and unclipped at AX5. Pinned by `SettingsDynamicTypeUITests`
   (Task 2); fallback D0043-4.
2. **Presentation modifiers inside a `Form`** (alerts, file importer / exporter, backfill
   dialog) fire twice, or not at all, once they sit on a `Section` — expected: one
   presentation per tap. Pinned by `ExportUITests`, `HealthSettingsUITests` and a new
   delete-all confirmation test (Task 4). Fallback: attach the modifiers to the section's first
   row instead of the `Section`.
3. **Guideline picker does not pop back, or the choice does not persist** — expected: tap an
   option → back on Settings showing it, kept across a tab round-trip, selected trait on the
   current option. Pinned by the rewritten `GuidelinePickerUITests` (Task 3).
4. **Same-value writes bump `modifiedDate`** (menu re-selecting the current value) — breaks the
   LWW contract (AGENTS.md). Pinned by the binding unit tests (Task 1).
5. **Tint or row surface fails contrast in Dark** with system footers / red denied text —
   expected: Settings audit classes clean in standard, dark and AX5. Pinned in Task 5.

---

### Task 1: Touching binding

**Files:**
- Create: `drinkpulse/Features/Settings/UserProfile+TouchingBinding.swift`
- Test: `drinkpulseTests/Features/Settings/UserProfileTouchingBindingTests.swift`

**Interfaces:**
- Produces: `@MainActor extension UserProfile { func touchingBinding<T: Equatable>(_ keyPath:
  ReferenceWritableKeyPath<UserProfile, T>) -> Binding<T> }` (same semantics as today's private
  `touching`: write + `touch()` only when the value differs) and `var dateOfBirthBinding:
  Binding<Date>` (reads `dateOfBirth ?? 30 years before now`, writes + `touch()` only on change).

- [ ] **Step 1: Write the failing tests**
  - `test_touchingBinding_writesAndTouches_whenValueChanges` — set `.unitSystem` from `.metric`
    to `.imperial`: value is `.imperial`, `modifiedDate` is later than before.
  - `test_touchingBinding_doesNotTouch_whenValueIsSame` — set `.metric` again: `modifiedDate`
    unchanged.
  - `test_dateOfBirthBinding_readsDefault_whenNil` — nil DOB reads a date 30 years ago (same
    calendar day), and reading does not write `dateOfBirth`.
  - `test_dateOfBirthBinding_writesAndTouches_onlyOnChange`.
- [ ] **Step 2: Run** `UserProfileTouchingBindingTests` via `RunSomeTests` — FAIL (undefined).
- [ ] **Step 3: Implement** the extension (move the bodies from `SettingsView.swift`).
- [ ] **Step 4: Run** — PASS.
- [ ] **Step 5: Commit** `[plan-0043] tested touching binding for UserProfile`.

### Task 2: Form shell, Profile, Guideline placeholder, Preferences, Privacy

**Files:**
- Modify: `drinkpulse/Features/Settings/SettingsView.swift` (`Form`, `Group { sections }
  .brandRowBackground()`, `.brandListBackground()`, `.brandNavigationTitle("tab.settings")`,
  drop `.navigationBarTitleDisplayMode(.inline)` and the label helpers)
- Create: `Components/ProfileSection.swift`, `Components/PreferencesSection.swift` (absorbs
  `AppearanceModeRow`; holds `settingsPickerStyle()` if D0043-4 fallback is needed),
  `Components/PrivacySection.swift` (`Link` to `UIApplication.openSettingsURLString`,
  `Label(settings.systemLock, systemImage: "lock.shield")`, footer `settings.systemLock.footer`)
- Delete: `Components/AppearanceModeRow.swift`
- Modify: `drinkpulse/Localizable.xcstrings` (copy table, D0043-7)
- Modify tests: `SettingsUITests` (`Appearance, ` prefix stays; `Export All Data`),
  `SettingsDynamicTypeUITests` (titles `Volume Unit`, `Alcohol Unit`, `Strength Step`; scroll
  with `app.collectionViews.firstMatch`), `HistoryUnitDisplayUITests`,
  `OnboardingLocaleDefaultUITests`, `VolumeServingUITests`, `CurrencyUITests` only where a
  label changed.

**Interfaces:**
- Consumes: `touchingBinding(_:)`, `dateOfBirthBinding` (Task 1).
- Produces: `struct ProfileSection: View { @Bindable var profile: UserProfile }`,
  `struct PreferencesSection: View { @Bindable var profile: UserProfile }`,
  `struct PrivacySection: View`. Picker labels are the existing keys; option texts as today
  (`abvPrecisionLabel(permille:)` moves into `PreferencesSection`).

- [ ] **Step 1: Update the UI tests** for new labels and the collection-view scroll; add
  `SettingsUITests.test_settings_showsLargeTitle_andNoGlassScrollView` — `navigationBars
  ["Settings"]` exists and `app.collectionViews.firstMatch` exists on the Settings tab.
- [ ] **Step 2: Run** `SettingsUITests`, `SettingsDynamicTypeUITests` — FAIL (old labels,
  scroll view).
- [ ] **Step 3: Implement** the Form and the three sections; the Guideline, Reminders, Weekly
  Summary, Apple Health and Data sections keep compiling by being placed in the Form unchanged
  for now (they still use `SettingsSection` until Tasks 3–4).
- [ ] **Step 4: Run** `SettingsUITests`, `SettingsDynamicTypeUITests`,
  `HistoryUnitDisplayUITests`, `OnboardingLocaleDefaultUITests`, `VolumeServingUITests`,
  `CurrencyUITests` — PASS. If the AX5 test fails on a preference picker, apply D0043-4 and
  re-run. `RenderPreview` `SettingsView` Light / Dark / AX5.
- [ ] **Step 5: Commit** `[plan-0043] Settings as Form: profile, preferences, privacy`.

### Task 3: Guideline picker

**Files:**
- Create: `Components/GuidelineSection.swift`
- Delete: `Components/GuidelinePickerSheet.swift`
- Move: `Components/GuidelineChoiceRow.swift` → `drinkpulse/Features/Onboarding/Components/`
- Modify: `drinkpulse/Features/Onboarding/Components/GuidelineStep.swift` (`SettingsSection` →
  `GroupBox { … }.groupBoxStyle(BrandCardStyle())`, D0043-6)
- Modify test: `drinkpulseUITests/Features/Settings/GuidelinePickerUITests.swift` (rewrite),
  `SettingsUITests.test_guidelinePicker_changePersists`

**Interfaces:**
- Produces: `struct GuidelineSection: View { @Bindable var profile: UserProfile }` —
  `Picker(settings.guideline.picker, selection: profile.touchingBinding(\.guidelineChoice))`
  over `GuidelineChoice.selectable`, `.pickerStyle(.navigationLink)`, header
  `settings.section.guideline`, footer `settings.guideline.footer`.

- [ ] **Step 1: Rewrite the UI tests** (keyed on labels; app strings are English):
  - `test_guidelinePicker_marksCurrentChoiceSelected` — open the "Guideline" row; the option
    whose label begins `WHO (Global)` `isSelected`, `Germany (DHS)` is not.
  - `test_guidelinePicker_selectingPopsBack_andPersists` — tap `Germany (DHS)` → Settings
    navigation bar is back, the row's label contains `Germany (DHS)`; History tab round-trip
    keeps it; reopening marks Germany selected and WHO not.
  - `test_guidelinePicker_optionsShowThresholdSummary` — every selectable option exists and
    its label contains `g/week`.
  - Drop the Close-glyph test (no sheet any more).
- [ ] **Step 2: Run** `GuidelinePickerUITests`, `SettingsUITests` — FAIL.
- [ ] **Step 3: Implement** `GuidelineSection`; replace the inline guideline row and the
  `.sheet`; delete the sheet; move the row; swap the onboarding card.
- [ ] **Step 4: Run** `GuidelinePickerUITests`, `SettingsUITests`, `OnboardingFlowUITests`,
  `OnboardingAccessibilityAuditUITests` — PASS (onboarding audit: no finding outside the
  open-questions baseline).
- [ ] **Step 5: Commit** `[plan-0043] guideline as navigation-link picker`.

### Task 4: Reminders, Weekly Summary, Apple Health, Data

**Files:**
- Modify: `Components/ReminderSection.swift`, `WeeklySummarySection.swift`,
  `HealthSection.swift`, `DataSection.swift`, `AppVersionFooter.swift` (drop the
  `frame(maxWidth:)` centring only if the footer misaligns in the `Form`)
- Delete: `Components/SettingsSection.swift`, `SettingsRow.swift`, `SettingsActionRow.swift`
- Modify tests: `ReminderSettingsUITests` (`Daily Reminder`), `WeeklySummarySettingsUITests`
  and `OnboardingWeeklySummaryUITests` (Settings toggle `Weekly Summary`; onboarding toggle label
  unchanged), `ExportUITests` (`Export All Data`), `AppVersionUITests` (`Delete All Data`),
  `HealthSettingsUITests` (only if a query breaks)

**Interfaces:**
- Produces: each view's `body` is `Section { rows } header: { Text(key) } footer: { hint or
  denied text }`; `DataSection` returns two sections (Data: Export, Import DrinkPulse Backup,
  Import from DrinkControl as `Button` + `Label`; Delete: `Button(settings.data.deleteAll,
  role: .destructive)` text-only, footer `AppVersionFooter()`). State, service calls and
  presentation modifiers unchanged.

- [ ] **Step 1: Write / update the UI tests**
  - Label updates above.
  - New `SettingsUITests.test_deleteAll_cancel_keepsData` — tap `Delete All Data` → alert
    "Delete All Data?" appears once (one alert element); tap Cancel → History still shows the
    seeded `500 ml` row.
  - `ReminderSettingsUITests`: existing toggle → `Time` row appears / disappears assertions
    stay; hint is found as a footer static text.
- [ ] **Step 2: Run** the six classes — FAIL (labels).
- [ ] **Step 3: Implement** the four sections; delete the three components; grep the project
  for `SettingsSection|SettingsRow|SettingsActionRow|SettingsMenuPicker` → no hits.
- [ ] **Step 4: Run** `ReminderSettingsUITests`, `WeeklySummarySettingsUITests`,
  `OnboardingWeeklySummaryUITests`, `HealthSettingsUITests`, `ExportUITests`,
  `AppVersionUITests`, `SettingsUITests` — PASS. If an alert or dialog shows twice or not at
  all, apply the Review focus 2 fallback.
- [ ] **Step 5: Commit** `[plan-0043] notification, health and data sections in the Form`.

### Task 5: Gates, audit, docs, close

**Files:**
- Modify: `docs/architecture.md` (Settings feature description and any DesignSystem / glass
  line naming the removed components), `docs/plans/0043-settings-form/execution.md` (create),
  `retrospective.md`, `docs/plans/INDEX.md`, `docs/DEVLOG.md`, `.claude/context/current-focus.md`,
  `.claude/context/open-questions.md`; README / PROJECT.md only if they describe the Settings UI
  (grep first).

- [ ] **Step 1: Build** zero warnings (`BuildProject`, `GetBuildLog` warnings).
- [ ] **Step 2: Audit** — `SettingsAccessibilityAuditUITests` (standard, dark, AX5) green on
  the new UI. Bar controls (`+`, tab bar) that fail `dynamicType` / `textClipped`: record in
  `execution.md` for the step 4 exemption helper; do not restyle. Any content finding → fix in
  this task.
- [ ] **Step 3: Scoped run** — all classes in `drinkpulseUITests/Features/Settings/`, the four
  cross-feature classes from Tasks 2–4, `ShellNavigationUITests`, `OnboardingFlowUITests`,
  `UserProfileTouchingBindingTests`, `AppVersionInfoTests`. Expected: green.
- [ ] **Step 4: Coverage** — `UserProfile+TouchingBinding.swift` 100 %.
- [ ] **Step 5: File size** find command; privacy review (no logging added, no network).
- [ ] **Step 6: Docs close-out** — execution.md (Apple doc sources per API), retrospective,
  INDEX (completed), DEVLOG, current-focus (next: step 4 Shell, plan 0044), open-questions;
  commit `[plan-0043] docs: close plan`.
- [ ] **Step 7:** `git switch ui-revamp && git merge --no-ff port/0043-settings-form`; ask the
  owner about push.

## Device check (owner)

- Settings in Light and Dark: Frost tint behind the form, rows on the card surface, rounded
  large title collapses to inline on scroll.
- VoiceOver: guideline picker announces the current value; denied footer is read after the
  toggle.
- AX5: every picker readable and reachable.

## Open questions

- [ ] D0043-1: keep separate Reminders / Weekly Summary sections (this plan), or merge into the
  prototype's "Notifications" section with a combined footer?
- [ ] D0043-7: fold the Settings copy into this step (this plan), or leave it to step 9?

## Tests required

New: `UserProfileTouchingBindingTests` (Swift Testing), `SettingsUITests` large-title /
collection-view and delete-all cancel tests, rewritten `GuidelinePickerUITests`. Updated: every
Settings UI test class, `OnboardingWeeklySummaryUITests`, and the cross-feature volume / currency
tests where labels changed. Gate: `SettingsAccessibilityAuditUITests` three variants.
