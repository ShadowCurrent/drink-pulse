# 0009 — Execution Journal

_Append-only. Newest entry at the bottom._

---

## 2026-05-19

**Pre-implementation decision (captured before freeze)**

Owner decided to store `dateOfBirth: Date?` on `UserProfile` instead of `age: Int?` or a plain
birth year. Rationale: full DOB gives accurate age for BAC (Widmark) and future insights;
"privacy-first" means data stays on-device, not that less data is collected than the app needs.
Plan updated to reflect this before being frozen.

**What was done**

### Domain model change (`UserProfile.swift`)
- Replaced `ageYears: Int` (stored) with `dateOfBirth: Date?` (stored) + `ageYears: Int?`
  (computed via `Calendar.current.dateComponents([.year], from: dob, to: .now)`).
- Updated `init` signature accordingly; updated `preview` static property.

### Settings (`SettingsView.swift`)
- Replaced `TextField`+`onChange` for `ageYears` with `DatePicker` for `dateOfBirth`.
- Date range: 120 years ago … 13 years ago.
- Added `dobRange` and `dobDefaultDate` computed helpers on `SettingsForm`.

### App routing (`drinkpulseApp.swift`)
- Added `@AppStorage("dp_onboarding_done")` boolean flag.
- Body now shows `OnboardingView` when `onboardingDone == false`, `ContentView` otherwise.
- Removed the auto-insert of `UserProfile()` (onboarding owns profile creation now).
- Added dev-only migration fallback: if `ModelContainer` fails to open (schema changed without
  migration plan), wipe the store file and recreate. **Must be replaced with a proper
  `SchemaMigrationPlan` before App Store submission.**

### Onboarding feature (`Features/Onboarding/`)
- `OnboardingViewModel.swift` — `@Observable @MainActor final class`; `step`, `sex`,
  `dateOfBirth`, `guideline`, `guidelineExplicitlyPicked`; `advance()`, `skipStep()`,
  `setGuideline(_:)`, `complete(into:)`.
- `OnboardingView.swift` — TabView(.page) container with step-dot indicator; routes
  `finish(saving:)` to `vm.complete(into:)` then calls `onFinish`.
- `Components/WelcomeStep.swift` — emoji hero, title, body, Get Started CTA, Skip all setup.
- `Components/ProfileStep.swift` — segmented sex picker, DatePicker for DOB, privacy note.
- `Components/GuidelineStep.swift` — list of WHO/DE/UK/US with limits; checkmark on selected.

### Localisation (`Localizable.xcstrings`)
- Added 15 keys under `onboarding.*` prefix (en/de/pl).
- Renamed `settings.age` → `settings.dateOfBirth` (en: "Date of Birth" / de: "Geburtsdatum" /
  pl: "Data urodzenia").

### Project file (`drinkpulse.xcodeproj/project.pbxproj`)
- Added `OnboardingViewModelTests.swift` to the test target (the main app target uses
  fileSystemSynchronizedGroups so auto-discovers; test target uses explicit file lists).

### Tests (`drinkpulseTests/OnboardingViewModelTests.swift`)
- 8 tests: default guideline, skip-all inserts no profile, sex+DOB, explicit guideline,
  default-unpicked guideline, advance bounds, setGuideline marks explicit.
- Root cause of initial test crash: `makeContext()` was returning `ModelContext` after its
  `ModelContainer` went out of scope. Fixed by using `makeContainer()` pattern (matches
  `DashboardViewModelTests`).

**Test result**: 73 tests in 6 suites — all green. No files over 300 lines.

**Schema migration note**:
Removing `ageYears: Int` (non-optional stored property) is not a lightweight migration.
Dev fix: wipe store on `ModelContainer` init failure (see `drinkpulseApp.swift` comment).
This MUST be replaced with an explicit `SchemaMigrationPlan` before shipping.
Opened as an item in `open-questions.md`.
