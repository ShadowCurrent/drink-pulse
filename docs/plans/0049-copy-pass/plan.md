# 0049 — Port step 9: Copy pass

**Status**: in-progress
**Frozen**: 2026-11-25
**Size**: small
**Created**: 2026-11-25
**Programme**: [0040 — Native UI port](../0040-native-ui-port/plan.md), step 9
**Branch**: `port/0049-copy-pass` (from `ui-revamp` at `e8cdfd9`; `main` has no new commits)

> Execution: superpowers `executing-plans`, inline, one session (owner workflow, plan 0040
> "Workflow"). Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The rows of the `VOICE.md` copy table that steps 2–8 did not move land in
`Localizable.xcstrings`, "Weekly check-in" becomes "Weekly Summary" on every screen, and the
weekly notification body becomes the one neutral line the owner decided.

**Architecture:** String values change in the catalog only, except three small code changes:
the Settings guideline picker gets its own label key, the guideline section gets a footer, and
`WeeklySummaryService` uses one body key. The weekly comparison (`WeeklySummaryCalculator`,
Domain) is unchanged and still decides whether a notification is scheduled at all. No
calculation, schema or persistence change.

**Tech stack:** String Catalog (`Localizable.xcstrings`), SwiftUI `Section(content:header:footer:)`
(already used in Settings), `UNMutableNotificationContent`; Swift Testing; XCUITest.

**Spec:** `~/Developer/drinkpulse-native-proto/VOICE.md` ("Copy table — app strings that
change", "Owner decisions (2026-11-20)"); `FINDINGS.md` round 16 copy list (Settings rows:
"Strength Step", "Daily Reminder", "Weekly Summary", section "Health Guideline") and the
prototype `Settings/SettingsView.swift` (guideline footer); plan 0043 D0043-7 and plan 0048
D0048-11 (rename deferred to this step); owner answers in chat 2026-11-25 (D0049-2 to D0049-5).

## Summary

Steps 2–8 moved most of the `VOICE.md` table with each screen. An audit of the catalog on
2026-11-25 left three groups: Settings labels still in sentence case or jargon ("Export all
data", "ABV precision"), the "Weekly check-in" name on Settings and onboarding, and the weekly
notification, which still puts week-over-week numbers on the lock screen.

## Context

- Catalog: `drinkpulse/Localizable.xcstrings`, source language `en`, 300 keys, English only.
- Rows already done in steps 2–8 (value in the catalog matches `VOICE.md`, excluded here):
  `dashboard.hero.eyebrow`, `dashboard.streak.current`, `.soberThisMonth`, `.zeroState`,
  `dashboard.risk.safe` / `.caution` / `.exceeded`, `insights.metric.bingeEpisodes` (+
  `heavyDays.detail`), `.drinkFreeDays`, `.soberStreak`, `.heaviestDay`,
  `history.calendar.soberDayPlaceholder`, `.soberSuffix`, `history.emptyTitle`,
  `.emptyDescription`, `action.duplicate`, `onboarding.guideline.body`,
  `onboarding.profile.body` / `.privacy`, `editDrink.deleteConfirm.message`,
  `dashboard.overview.title` ("Guideline Limits"), `dashboard.alert.title` ("Over Weekly
  Limit"), `editDrink.notesPlaceholder`, `addDrink.pureAlcohol`, `insights.empty.*`,
  `common.logADrink`.
- Rows whose screen element no longer exists after the port (key unused or gone; nothing to
  move): `dashboard.metric.alcohol`, `insights.metric.riskLevel` / `insights.metric.risk.*`
  (Insights has no risk metric since plan 0046), `insights.nav.now` (no "NOW" pill since
  plan 0046), `addDrink.alcoholUnits`, `insights.areaChart.empty`.
- `settings.section.guideline` is both the picker label (and the title of the pushed option
  list, matched by `GuidelinePickerUITests` as `navigationBars["Guideline"]`) and the section
  header.
- `WeeklySummaryService.bodyText(for:)` picks one of five keys by `WeeklySummaryContent`.
  `WeeklySummaryCalculator.content` returns `.skip` only when no event exists before last week.
- Catalog edits: `StringCatalogEdit` is a translation tool gated on the
  `xcode-integration:translation` skill, which is not installed. A script keeps Xcode's format:
  `/private/tmp/claude-501/-Users-fempter-Developer-drinkpulse/6585ce21-1825-4643-878c-3950cef32523/scratchpad/xcstrings_edit.py`
  (2-space JSON, `" : "` separator, empty objects as `{\n\n}`, existing key order kept, new
  keys inserted before the first larger key). A no-op run leaves the file byte-identical
  (checked 2026-11-25).

## Decisions (this plan)

- **D0049-1 Scope.** The remaining rows below, plus the D0043-7 Settings rows, plus the
  "Weekly Summary" rename. Nothing else in the catalog changes.

  | Key | Now | New |
  |---|---|---|
  | `settings.data.export` | Export all data | Export All Data |
  | `settings.data.deleteAll` | Delete all data | Delete All Data |
  | `settings.reminder.toggle` | Daily log reminder | Daily Reminder |
  | `settings.alcoholUnit` | Alcohol unit | Alcohol Unit |
  | `settings.volumeUnit` | Volume unit | Volume Unit |
  | `settings.abvPrecision` | ABV precision | Strength Step |
  | `settings.section.guideline` | Guideline | Health Guideline |
  | `settings.guideline.picker` (new) | — | Guideline |
  | `settings.guideline.footer` (new) | — | Limits are compared in grams of pure alcohol. |
  | `settings.weeklySummary.toggle` | Weekly check-in | Weekly Summary |
  | `onboarding.health.weeklySummary.toggle` | Weekly check-in | Weekly Summary |
  | `settings.weeklySummary.denied` | … to get your weekly check-in. | Notifications are off. Turn them on in Settings to get your weekly summary. |
  | `weeklySummary.notification.body` (new) | — | Your weekly summary is ready. |
  | `weeklySummary.notification.body.up` / `.down` / `.same` / `.directionOnlyUp` / `.directionOnlySame` | five comparison sentences | removed |

  The picker labels follow `VOICE.md` ("Volume Unit", "Alcohol Unit"), not the prototype's
  shorter "Volume" / "Alcohol".
- **D0049-2 Weekly notification: body only** (owner, 2026-11-25). One body for every scheduled
  case. The calculator stays and still decides skip vs schedule; Insights and routing do not
  change. `VOICE.md` says the "as of your last visit" caveat moves into an in-app summary; no
  such screen exists, and with no numbers on the lock screen there is nothing stale to caveat,
  so the caveat is dropped. To keep the week-window tests meaningful, the comparison is
  extracted into `WeeklySummaryService.summaryContent(in:now:calendar:)` and the tests assert
  the content, not the body.
- **D0049-3 Health Guideline header and footer** (owner, 2026-11-25). The section header reads
  "Health Guideline"; the picker row and the pushed list keep "Guideline" through the new key
  `settings.guideline.picker`; the footer is the prototype's line.
- **D0049-4 Title Case outside the table is deferred** (owner, 2026-11-25). Strings that break
  principle 9 but are not in the table ("Import DrinkPulse backup", "Add past drinks", "Not
  now", …) are listed in the final report for a later decision, not changed here.
- **D0049-5 Tests: scoped only** (owner, 2026-11-25). The change touches 13 test classes, which
  AGENTS.md "Quality gates" would escalate to the full suite; the owner overrides that for this
  step. Only `RunSomeTests` on the classes in Task 4, in batches of about 10. No
  `RunAllTests`, no coverage.
- **D0049-6 Hints unchanged.** `settings.weeklySummary.hint` ("A weekly note on how this week
  compares to last.") and `onboarding.health.weeklySummary.hint` keep their wording; whether
  they still fit a neutral notification goes to the report as an owner question.
- **D0049-7 Unused keys stay.** Keys no code reads (e.g. `dashboard.metric.alcohol`,
  `insights.metric.risk.*`, `tab.add`) are left for step 11 cleanup.

## Scope

### In
`drinkpulse/Localizable.xcstrings`; `Features/Settings/Components/GuidelineSection.swift`;
`Services/WeeklySummaryService.swift`; the tests in Tasks 1–3; `README.md`,
`.planning/PROJECT.md`; plan records.

### Out
Domain (`WeeklySummaryCalculator`), Insights, notification routing, hint wording, Title Case
outside the table, unused-key cleanup.

## Global constraints

- **Xcode MCP** (main checkout): `workspaceIdentifier` from `XcodeListWorkspaces` (entry ending
  `drinkpulse.xcodeproj`) on every call that takes it. Destination: iPhone 18 Pro, iOS 27.2
  simulator (`XcodeListRunDestinations` before builds and tests); never a physical device.
  Build with `BuildProject` + `GetBuildLog` (zero warnings). Tests with `RunSomeTests` only.
  Code edits with `XcodeUpdate` / `XcodeWrite`, `XcodeRefreshCodeIssuesInFile` after each
  Swift file. Bulk test-string edits may use small scripts. No CLI `xcodebuild`.
- Catalog values only through the script in Context, one JSON edit file per task.
- Apple docs: no new Apple API is used. Record the `DocumentationSearch` look-ups (HIG
  capitalization; `Section` footer) in `execution.md`.
- Swift 6, zero warnings, files under 300 lines, previews kept, no `print`, no PII in logs.
- UI tests match app strings only (English); never system UI by a localized label.

## Review focus

1. **A stale label somewhere a test does not look:** the weekly toggle in onboarding vs
   Settings must read the same. Pinned in Task 2 by `OnboardingWeeklySummaryUITests`, which
   asserts "Weekly Summary" on both screens.
2. **Pushed guideline list title.** After the header rename, the pushed list must still be
   titled "Guideline", not "Health Guideline". Pinned by `GuidelinePickerUITests`
   (`navigationBars["Guideline"]`, unchanged) in Task 1.
3. **A health number on the lock screen.** For every non-skip content, the body is the neutral
   line and contains no digit or `%`. Pinned in Task 3
   (`WeeklySummaryCopyTests.everyScheduledBody_isNeutral_withNoNumbers`).
4. **Skip still skips.** No prior data must still cancel and add nothing. Pinned by the
   existing `WeeklySummaryServiceScheduleTests.scheduleIfEnabled_cancelsPending_whenNoPriorWeekDataAtAll`
   (kept unchanged).
5. **AX5 exemption keyed on old labels.** `SettingsDynamicTypeUITests.preferencePickerKeys`
   names picker labels; stale keys would turn the provisional exemption into failures. Pinned
   in Task 1 by updating the set and running the class.

---

### Task 1: Settings copy

**Files:**
- Modify: `drinkpulse/Localizable.xcstrings` (rows 1–9 of D0049-1)
- Modify: `drinkpulse/Features/Settings/Components/GuidelineSection.swift` (picker label key
  `settings.guideline.picker`; `footer:` with `settings.guideline.footer` in
  `Color.dpSecondaryText`, like the header)
- Test (update strings): `drinkpulseUITests/Features/Settings/ExportUITests.swift`
  (3× "Export all data"), `SettingsUITests.swift` (lines ~155, 175, 178, 194),
  `AppVersionUITests.swift` (27, 34), `ReminderSettingsUITests.swift` (24),
  `SettingsDynamicTypeUITests.swift` (19, 50: "Volume Unit", "Alcohol Unit", "Strength Step")

- [ ] **Step 0: Docs.** `DocumentationSearch` HIG capitalization (title-style) and
  `Section` `init(content:header:footer:)`; record in `execution.md`.
- [ ] **Step 1: Update the UI test strings** to the new labels (script or `XcodeUpdate`). Also
  add to `SettingsUITests` one assertion in the existing guideline-row test that
  `app.staticTexts["Limits are compared in grams of pure alcohol."]` exists.
- [ ] **Step 2: Run** `SettingsUITests`, `ExportUITests`. Expected: FAIL on the new labels.
- [ ] **Step 3: Catalog + `GuidelineSection`** per D0049-1 / D0049-3. `RenderPreview` of
  `GuidelineSection` (Light, AX5).
- [ ] **Step 4: Build, run** `SettingsUITests`, `ExportUITests`, `AppVersionUITests`,
  `ReminderSettingsUITests`, `SettingsDynamicTypeUITests`, `GuidelinePickerUITests`,
  `SettingsAccessibilityAuditUITests`. Expected: PASS.
- [ ] **Step 5: Commit** `[plan-0049] Settings copy: Title Case, Strength Step, Health Guideline`.

### Task 2: "Weekly Summary" rename

**Files:**
- Modify: `drinkpulse/Localizable.xcstrings` (rows 10–12 of D0049-1)
- Test (update strings): `drinkpulseUITests/Features/Settings/SettingsUITests.swift` (176,
  179), `WeeklySummarySettingsUITests.swift` (24–39),
  `drinkpulseUITests/Features/Onboarding/OnboardingWeeklySummaryUITests.swift` (32–77)
- Modify: `README.md` line 47 ("weekly check-in" → "weekly summary")

- [ ] **Step 1: Update the UI test strings** "Weekly check-in" → "Weekly Summary" (labels and
  assertion messages).
- [ ] **Step 2: Run** `WeeklySummarySettingsUITests`. Expected: FAIL (switch not found).
- [ ] **Step 3: Catalog** rows 10–12; README line.
- [ ] **Step 4: Run** `WeeklySummarySettingsUITests`, `OnboardingWeeklySummaryUITests`,
  `SettingsUITests`. Expected: PASS.
- [ ] **Step 5: Commit** `[plan-0049] rename Weekly check-in to Weekly Summary`.

### Task 3: Neutral weekly notification body

**Files:**
- Modify: `drinkpulse/Services/WeeklySummaryService.swift`
- Modify: `drinkpulse/Localizable.xcstrings` (rows 13–14 of D0049-1)
- Test: `drinkpulseTests/Services/WeeklySummaryCopyTests.swift` (rewrite),
  `WeeklySummaryServiceTests.swift`, `WeeklySummaryServiceScheduleTests.swift`,
  `WeeklySummaryCompletedWeekTests.swift`
- Modify: `.planning/PROJECT.md` (Validated ENGG-01..07 line: add that since plan 0049 the
  body is the neutral line and the comparison only decides skip vs schedule)

**Interfaces:**
- Produces: `func summaryContent(in context: ModelContext, now: Date = .now, calendar: Calendar = .current) throws -> WeeklySummaryContent`
  on `WeeklySummaryService` (internal). It holds the three fetches and the
  `WeeklySummaryCalculator.content` call now inline in `scheduleIfEnabled`; it throws the fetch
  error. `scheduleIfEnabled` calls it inside its existing `do / catch` (same log line, same
  early return) and keeps the rest unchanged.
- `makeRequest(calendar:content:)` keeps its signature; `body =
  String(localized: "weeklySummary.notification.body")`; `bodyText(for:)` is deleted.

- [ ] **Step 1: Write the failing tests.**
  `WeeklySummaryCopyTests` becomes:
  ```swift
  private let neutral = "Your weekly summary is ready."
  @Test(arguments: [WeeklySummaryContent.percentage(fraction: -0.5, direction: .down),
                    .percentage(fraction: 0.5, direction: .up),
                    .percentage(fraction: 0.02, direction: .same),
                    .directionOnly(.up), .directionOnly(.same)])
  func everyScheduledBody_isNeutral_withNoNumbers(content: WeeklySummaryContent) {
      let text = body(for: content)
      #expect(text == neutral)
      #expect(text?.contains(where: \.isNumber) == false)
      #expect(text?.contains("%") == false)
  }
  @Test func skip_hasNoRequest() { #expect(makeService().makeRequest(content: .skip) == nil) }
  ```
  `WeeklySummaryServiceTests`: the five `makeRequest_bodyText_*` tests become one
  parameterized `makeRequest_body_isNeutralKey_forEveryScheduledContent` expecting
  `String(localized: "weeklySummary.notification.body")`.
  `WeeklySummaryCompletedWeekTests`: each test calls `summaryContent(in:now:calendar:)` and
  asserts the content via a helper `percent(_:) -> (SignDirection, Int)?` that returns the
  direction and `Int((abs(fraction) * 100).rounded())` for `.percentage`; same expected values
  as today (down 50, up 100, down 67, …). Trigger / identifier assertions stay on the
  scheduled request.
  `WeeklySummaryServiceScheduleTests` lines ~85, ~114, ~206: assert the content from
  `summaryContent` (e.g. `.directionOnly(.up)`) and that one request was added.
- [ ] **Step 2: Run** the four classes. Expected: FAIL (no `summaryContent`, old body).
- [ ] **Step 3: Implement** the Interfaces above; catalog rows 13–14 (add the new key, remove
  the five old keys).
- [ ] **Step 4: Build, run** `WeeklySummaryCopyTests`, `WeeklySummaryServiceTests`,
  `WeeklySummaryServiceScheduleTests`, `WeeklySummaryCompletedWeekTests`,
  `WeeklySummaryServiceCancellationTests`, `WeeklySummaryCalculatorTests`. Expected: PASS.
- [ ] **Step 5: Commit** `[plan-0049] weekly notification: one neutral body`.

### Task 4: Gates, docs, close

- [ ] **Step 1: Build** with zero warnings; `XcodeGrep` the app and test targets for the old
  strings ("check-in", "all data", "log reminder", "ABV precision", the removed body keys).
  Expected: no hits outside comments and plan history.
- [ ] **Step 2: Scoped gate run** (D0049-5):
  1. `WeeklySummaryCopyTests`, `WeeklySummaryServiceTests`, `WeeklySummaryServiceScheduleTests`,
     `WeeklySummaryCompletedWeekTests`, `SettingsUITests`, `ExportUITests`,
     `AppVersionUITests`, `ReminderSettingsUITests`, `SettingsDynamicTypeUITests`
  2. `WeeklySummarySettingsUITests`, `GuidelinePickerUITests`,
     `SettingsAccessibilityAuditUITests`, `OnboardingWeeklySummaryUITests`,
     `AccessibilityAuditUITests/test_audit_settings_standard`, `…/test_audit_settings_ax5`
  Expected: green. Record results in `execution.md`.
- [ ] **Step 3: File size and privacy** (AGENTS.md `find`; no network, no PII, no `print`).
- [ ] **Step 4: Docs close-out:** `execution.md`, `retrospective.md`, `INDEX.md`, `DEVLOG.md` (step 9 done; plan 0040 has no
  `execution.md`),
  `current-focus.md`, `open-questions.md` (D0049-4 list, D0049-6 question), `VOICE.md` is in
  the prototype repo and is not edited. Commit `[plan-0049] docs: close plan`.
- [ ] **Step 5: Final review:** one fresh superpowers reviewer over the branch (standing
  approval). Fix Critical / Important with tests; minors to `execution.md`.
- [ ] **Step 6:** `git switch ui-revamp && git merge --no-ff port/0049-copy-pass`; ask the owner
  about push.

## Device check (owner)

- Settings: "Health Guideline" header with its footer; the pushed list titled "Guideline";
  "Strength Step" at AX5.
- A delivered weekly notification reads "Your weekly summary is ready." on the lock screen.

## Open questions

- [x] Notification scope — body only (owner, 2026-11-25).
- [x] Health Guideline header and footer — both (owner, 2026-11-25).
- [x] Title Case outside the table — deferred to the report (owner, 2026-11-25).
- [x] Full suite — skipped, scoped runs only (owner, 2026-11-25).
- [ ] Weekly hints after the neutral body (D0049-6) — owner, after this step.

## Tests required

New: `WeeklySummaryCopyTests.everyScheduledBody_isNeutral_withNoNumbers`, `.skip_hasNoRequest`,
`WeeklySummaryServiceTests.makeRequest_body_isNeutralKey_forEveryScheduledContent`, the
guideline footer assertion in `SettingsUITests`. Updated: the four weekly-summary unit classes
(content instead of body), seven Settings UI classes and `OnboardingWeeklySummaryUITests`
(labels). Coverage: not measured (D0049-5).
