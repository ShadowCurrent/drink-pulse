# 0049 — Execution journal

Append-only. Dated entries, newest last.

## 2026-11-25 — Setup

- `main` had no commits beyond `ui-revamp`; no merge needed. Branch `port/0049-copy-pass` from
  `ui-revamp` at `e8cdfd9` (`origin/ui-revamp` is at the same commit: plan 0048 is pushed;
  the stale "Open" line in `current-focus.md` was corrected).
- Xcode MCP: workspace from `XcodeListWorkspaces` (entry ending `drinkpulse.xcodeproj`);
  active destination iPhone 18 Pro, iOS 27.2 simulator, scheme `drinkpulse`.
- Owner answers in chat before freezing: D0049-2 (body only), D0049-3 (header + footer),
  D0049-4 (Title Case outside the table deferred), D0049-5 (scoped tests only).
- Catalog edits use the format-keeping script named in the plan's Context; a no-op run left the
  file byte-identical.
- Executor: superpowers `executing-plans`, inline.

## 2026-11-25 — Task 1: Settings copy

Docs (Xcode MCP `DocumentationSearch`): HIG Buttons › Content and Menus › Labels ("use
title-style capitalization"); SwiftUI `Section.init(content:header:footer:)` (no new API used
in the end, see below).
- UI test strings updated first; RED: `SettingsUITests` / `ExportUITests` 6 of 10 failed on the
  new labels.
- Catalog (script) and `GuidelineSection` (picker label key `settings.guideline.picker`).
  Previews: Light, Dark AX5.
- First GREEN run 18/21: `SettingsAccessibilityAuditUITests` standard and dark reported
  `dynamicType` on the new footer "Limits are compared in grams of pure alcohol.". An explicit
  `.font(.footnote)` did not change it (one run). It is the first `Form` footer inside the
  audited launch viewport. **Owner (chat): drop the footer** rather than exempt it; key
  `settings.guideline.footer` removed, D0049-3 is the header only. Rerun: audit class 3/3 and
  `test_guidelinePicker_changePersists` green.
- Ruling: the Task 3 tests written early were stashed during Tasks 1–2 so the unit target
  compiled.

## 2026-11-25 — Task 2: "Weekly Summary" rename

- RED: `WeeklySummarySettingsUITests` toggle not found. GREEN after the catalog change:
  `WeeklySummarySettingsUITests`, `OnboardingWeeklySummaryUITests`, `SettingsUITests` 11/11.
  README Settings line updated.

## 2026-11-25 — Task 3: neutral weekly notification body

- RED: unit target build error "Value of type 'WeeklySummaryService' has no member
  'summaryContent'".
- `summaryContent(in:now:calendar:)` extracted; `makeRequest` uses
  `weeklySummary.notification.body`; `bodyText(for:)` and the five comparison keys removed.
- Ruling: `WeeklySummaryCompletedWeekTests.f4_bakedComparisonIsOneWeekBehindAtTheNextDelivery`
  (not named in the plan) asserted the baked body; it now asserts the scheduled content and the
  neutral delivered body.
- GREEN: six weekly-summary unit classes 49/49. `.planning/PROJECT.md` ENGG line updated.

## 2026-11-25 — Task 4: gates

- `BuildProject` (build for testing): succeeded, `GetBuildLog` warnings: 0. No old strings left in
  the three targets. No Swift file over 300 lines. No new network, logging or `print`.
- Gate batch 1 (4 unit + 5 UI classes): 47/49. Both `ExportUITests` tests failed waiting for
  the system save panel (`DOCPicker.filenameTextField`, 8 s) after a successful tap on "Export
  All Data". Rerun alone: 1/2 (the other test failed the same way). Both passed in the Task 1
  run on this branch. Ruling: flake in the out-of-process document picker presentation, not the
  label change — recorded in open-questions — cost if wrong: an export regression goes unseen.
- Gate batch 2: 8 passed, 2 skipped (`AccessibilityAuditUITests` Settings cases are gated off
  in the normal run), 1 failed: `SettingsAccessibilityAuditUITests.test_settings_dark` reported
  `dynamicType` on "Strength Step". It passed in the 20:40 run with the same label and passed on
  an immediate rerun (1/1). Ruling: intermittent, recorded in open-questions — cost if wrong: a
  real Dynamic Type issue on the Preferences picker label at default size.
