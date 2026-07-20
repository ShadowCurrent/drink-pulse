---
phase: 01-weekly-summary-notification
plan: 04
subsystem: ui
tags: [swiftui, settings, onboarding, notifications, appstorage]

# Dependency graph
requires:
  - phase: 01-01
    provides: "AppStorageKeys.weeklySummaryEnabled key, Localizable.xcstrings strings for settings/onboarding copy"
  - phase: 01-02
    provides: "WeeklySummaryService with requestAuthorization/scheduleIfEnabled(context:)/cancel"
provides:
  - "WeeklySummarySection Settings card, mirroring ReminderSection minus the time picker"
  - "Independent Weekly Summary toggle inside the Onboarding HealthStep panel"
  - "The only user-facing way to opt into ENGG-01/ENGG-02"
affects: [01-05]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "New SettingsSection card mirrors ReminderSection's toggle/hint/denied-action-row shape exactly, minus any time-picker row"
    - "Two independent toggle blocks sharing one .thinMaterial panel in onboarding, each with its own @AppStorage key and local @State denial flag"

key-files:
  created:
    - drinkpulse/Features/Settings/Components/WeeklySummarySection.swift
  modified:
    - drinkpulse/Features/Settings/SettingsView.swift
    - drinkpulse/Features/Onboarding/Components/HealthStep.swift

key-decisions:
  - "enable() in WeeklySummarySection sets `enabled = true` before calling service.scheduleIfEnabled(context:), because scheduleIfEnabled re-reads AppStorageKeys.weeklySummaryEnabled from UserDefaults directly — calling it first would make it a no-op"
  - "Reused the existing 'settings.reminder.openSettings' localization key for the denied-state action row instead of adding a new one, per plan instruction"
  - "Onboarding's enableWeeklySummary() only calls requestAuthorization() — no scheduleIfEnabled call — since a brand-new profile has zero ConsumptionEvents and scheduling would resolve to .skip anyway"

patterns-established:
  - "WeeklySummarySection: no DatePicker/time row (fixed 9am schedule, unlike ReminderSection's user-configurable time)"

requirements-completed: [ENGG-01, ENGG-02]

coverage:
  - id: D1
    description: "New WeeklySummarySection Settings card, off by default, inserted between ReminderSection and HealthSection, with working enable/disable and permission-denied UI"
    requirement: "ENGG-01"
    verification:
      - kind: unit
        ref: "xcodebuild build -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' (zero warnings)"
        status: pass
    human_judgment: true
    rationale: "Visual placement, toggle behavior, and denied-state UI in a live Settings screen require a human to confirm the rendered card looks and behaves correctly; plan 01-05's UI tests are the deterministic automated coverage for this surface but were not yet executed by this plan."
  - id: D2
    description: "Onboarding HealthStep gains a second, independent Weekly Summary toggle inside the same .thinMaterial panel as the Health toggle, without changing the 4-step onboarding flow or affecting the Health toggle's state"
    requirement: "ENGG-02"
    verification:
      - kind: unit
        ref: "xcodebuild build -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' (zero warnings)"
        status: pass
    human_judgment: true
    rationale: "Confirming the two toggles are visually and behaviorally independent inside one shared onboarding panel requires either a UI test (plan 01-05) or manual verification in the simulator; this plan only wired the code and verified it compiles."

duration: 25min
completed: 2026-07-20
status: complete
---

# Phase 01 Plan 04: Weekly Summary Opt-In Surfaces Summary

**New `WeeklySummarySection` Settings card (mirrors `ReminderSection` minus the time picker) plus an independent Weekly Summary toggle folded into the existing Onboarding `HealthStep` panel — the only two user-facing ways to opt into ENGG-01/ENGG-02.**

## Performance

- **Duration:** 25 min
- **Started:** 2026-07-20T20:10:00Z
- **Completed:** 2026-07-20T20:35:00Z
- **Tasks:** 2 completed
- **Files modified:** 3 (1 created, 2 edited)

## Accomplishments
- Created `WeeklySummarySection`, a new `SettingsSection` card for the Weekly Summary toggle, mirroring `ReminderSection`'s toggle/hint/denied-action-row shape but with no time picker (fixed 9am schedule)
- Inserted `WeeklySummarySection()` between `ReminderSection()` and `HealthSection()` in `SettingsView.swift`
- Added a second, fully independent Weekly Summary toggle row to the Onboarding `HealthStep`, sharing the existing `.thinMaterial` panel with the Health toggle (one panel, two toggle blocks); `OnboardingViewModel.totalSteps` stays 4

## Task Commits

Each task was committed atomically:

1. **Task 1: WeeklySummarySection.swift + insert into SettingsView (D-07)** - `e59bb0d` (feat)
2. **Task 2: HealthStep — add independent Weekly Summary toggle inside the existing panel (D-05/D-06)** - `b46e095` (feat)

## Files Created/Modified
- `drinkpulse/Features/Settings/Components/WeeklySummarySection.swift` - New Settings card: toggle + permission-denied hint + Open Settings action row
- `drinkpulse/Features/Settings/SettingsView.swift` - New call site `WeeklySummarySection()` between `ReminderSection()` and `HealthSection()`
- `drinkpulse/Features/Onboarding/Components/HealthStep.swift` - New `weeklySummaryEnabled` (`@AppStorage`), `weeklySummaryPermissionDenied` (`@State`), `weeklySummaryToggleBinding`, `enableWeeklySummary()`; restructured the single toggle `VStack` into one outer `VStack` wrapping two independent inner toggle blocks

## Decisions Made
- `WeeklySummarySection.enable()` sets `enabled = true` before calling `service.scheduleIfEnabled(context:)` — `scheduleIfEnabled` reads the same AppStorage key from `UserDefaults.standard` directly, so setting the flag after the call would make it a no-op (documented in the plan; implemented exactly as specified).
- Reused `"settings.reminder.openSettings"` for the denied-state action row rather than adding a new `"settings.weeklySummary.openSettings"` key, per the plan's explicit instruction.
- Onboarding's `enableWeeklySummary()` intentionally omits any `scheduleIfEnabled` call — a brand-new onboarding profile has no `ConsumptionEvent`s yet, so a schedule attempt would immediately resolve to `.skip`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- Both opt-in surfaces (Settings card + Onboarding toggle) are wired and build cleanly with zero warnings.
- Plan 01-05 (UI tests) can now exercise: toggling each surface independently, permission-denied UI, and confirming the two toggles never cross-affect the Health/Reminder AppStorage keys they sit beside.
- No blockers.

---
*Phase: 01-weekly-summary-notification*
*Completed: 2026-07-20*
