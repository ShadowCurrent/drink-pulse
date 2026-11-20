# 0043 — Execution Log

Append-only. Never edit or delete previous entries.

---

## 2026-11-20 — Tasks 1–5 executed (superpowers `executing-plans`, inline)

Branch `port/0043-settings-form`, commits `36bd224` … (this close-out). Simulator only (iPhone 18
Pro, iOS 27.2); builds, tests and previews through Xcode MCP (`BuildProject`, `GetBuildLog`,
`RunSomeTests`, `RenderPreview`). No CLI `xcodebuild`.

### Done
- **Task 1 — touching binding** (`36bd224`). `UserProfile+TouchingBinding.swift`
  (`touchingBinding(_:)`, `dateOfBirthBinding`). `UserProfileTouchingBindingTests` (6, Swift
  Testing) RED (no member) → GREEN.
- **Task 2 — Form shell, Profile, Preferences, Privacy** (`342afbe`). `SettingsView` is a `Form`
  with `brandRowBackground` / `brandListBackground` / `brandNavigationTitle`; `ProfileSection`,
  `PreferencesSection` (absorbs `AppearanceModeRow`, deleted), `PrivacySection` (`Link` to the
  app's Settings page, footer `settings.systemLock.footer`). New
  `SettingsUITests.test_settings_showsLargeTitle_andNoGlassScrollView` RED → GREEN.
- **Task 3 — guideline picker** (`d542cb5`). `GuidelineSection` (`Picker` `.navigationLink`,
  name + threshold summary per option). `GuidelinePickerSheet` deleted; `GuidelineChoiceRow`
  moved to `Onboarding/Components/`; `GuidelineStep` uses `GroupBox` + `BrandCardStyle`.
  `GuidelinePickerUITests` rewritten (3 tests) RED → GREEN.
- **Task 4 — Notifications, Apple Health, Data** (`772181c`). `NotificationsSection` owns both
  denied flags; `ReminderRows` / `WeeklySummaryRows` (renamed, rows only, logic unchanged);
  shared `OpenSettingsRow`; `HealthSection` and `DataSection` (Data + Delete sections, version
  footer) as `Section`s. `SettingsSection`, `SettingsRow` (+ `SettingsMenuPicker`),
  `SettingsActionRow` deleted. Catalog: `settings.section.notifications` added,
  `settings.section.reminders` / `.weeklySummary` removed. New tests
  `test_notifications_showsBothTogglesInOneSection` (RED → GREEN) and
  `test_deleteAll_cancel_keepsData` (one alert, data kept; passed before the change as a
  characterization guard).
- **Task 5 — gates.** Audit fixes (below), docs. Gate run 63 / 63 green: all Settings UI classes
  including `SettingsAccessibilityAuditUITests` standard / dark / AX5, the cross-feature classes,
  `ShellNavigationUITests`, `OnboardingFlowUITests`, `OnboardingAccessibilityAuditUITests`,
  `UserProfileTouchingBindingTests`, `AppVersionInfoTests`. App target builds with zero warnings.
  `UserProfile+TouchingBinding.swift` coverage 97.3 % (36 / 37; the missed region is the
  unreachable `?? .now` after `Calendar.date(byAdding: .year …)`). No Swift file over 300 lines.
  No logging, network or SDK added.

### Deviations from plan (rulings)
- `Link` is not an XCUI button and `Form` rows load lazily: the App Lock test queries any element
  and scrolls the collection view; a shared `scrollUntilExists` helper in `SettingsUITests`.
- D0043-4 fallback applied: Preferences pickers switch to `.navigationLink` at accessibility sizes.
  The AX5 audit then reported `dynamicType` / `textClipped` on their system-drawn labels although
  the render shows nothing clipped. `SettingsDynamicTypeUITests` exempts the five labels and
  `none#type=nil` (D11-28 shape). **Provisional, owner decision pending** (open-questions).
- The style modifier first sat on the whole Preferences `Section`; the standard / dark audits then
  reported `dynamicType` on every picker label in it (the Sex picker without the modifier was
  clean). Moved to each `Picker`, and the standard-size branch returns the content unchanged
  (automatic = menu style): findings gone.
- Section headers in system grey failed `contrast` on the Light Frost tint (3.2:1; 3.3:1 even
  untinted). Headers, hint footers and the Privacy footer use `Color.dpSecondaryText` (Light
  4.96:1 on the tint). The guideline row's system-grey value failed the same way; it now uses
  `Picker(_:selection:content:currentValueLabel:)` with `dpSecondaryText`.
- Form `Toggle` rows: XCUI `tap()` lands on the label; `FormSwitchSupport.tapSwitch` taps the inner
  switch (Reminder, Weekly summary, Health tests). `AppVersionUITests` "below the last row" check
  is `>=` (the footer frame starts at the row edge). `OnboardingFlowUITests` reads the Guideline
  picker row's label + value.
- Shared `OpenSettingsRow` instead of three copies of the denied "Open Settings" row.
- Build-for-testing warnings exist only in `HistorySearchUITests.swift` (plan 0039, untouched
  here); not fixed (open-questions).

### Apple documentation consulted (Xcode MCP `DocumentationSearch`)
- `Section.init(content:header:footer:)` — every Settings section.
- `Picker`, `pickerStyle(_:)`, `NavigationLinkPickerStyle` / `PickerStyle.navigationLink`
  ("consider … when your design is better expressed by pushing onto a stack"; "In navigation
  stacks, prefer the default menu style") — Guideline, and Preferences at AX sizes.
- `Picker.init(_:selection:content:currentValueLabel:)` — guideline row value.
- `UIApplication.openSettingsURLString` (UIKit) — `Link` in Privacy and `OpenSettingsRow`.
- `alert(_:isPresented:actions:message:)`, `Button(role:)` (`ButtonRole.destructive`,
  `.cancel`) — delete-all confirmation on the Delete button.
- Existing design-system helpers (`scrollContentBackground(.hidden)`,
  `containerBackground(for: .navigation)`, `ToolbarItemPlacement.largeTitle`) were looked up in
  plan 0042.

## 2026-11-20 — final review

Fresh reviewer (whole branch `e070dd3..5ae9c0d`): no Critical, 4 Important, 4 Minor.
- Section-level presentation modifiers in `DataSection`: not reproduced. `ExportUITests` success
  path now asserts exactly one alert and none after dismissal (passes; no "already presenting"
  in the log). Code unchanged; fallback (modifiers on the Export row) stays available.
- `HealthSection` dialog on a one-row section: unchanged (tested path shows it once).
- AX5 exemption scope and red denied text: owner items in open-questions.
- Deferred minors: unknown imported currency shows no picker value; `PrivacySection` could reuse
  `OpenSettingsRow`; old logger category names; relaxed footer check in `AppVersionUITests`.
