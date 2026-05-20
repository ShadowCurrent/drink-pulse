# 0017 — Execution Log

Append-only. Never edit or delete previous entries.

---

## 2026-05-20 — Plan frozen, execution started

### Done
- Plan approved by user, status set to in-progress.
- Open question resolved: use inline literal `1.0` for the SB-2 clamp
  (simpler; a named constant adds ceremony without clarity gain here).

### Deviations from plan
- None yet.

### Discoveries
- `xcodebuild` requires `CODE_SIGNING_ALLOWED=NO` on this machine to
  avoid resource-fork codesign failure on the test bundle. All build
  commands in this log include that flag.

---

## 2026-05-20 — Phase A: bug fixes

### Done
- Confirmed SB-1 failing in Polish locale: "WHO" vs "WHO (globalna)".
- Applied all 4 production fixes and 2 coverage-only test additions.
- 73 → 94 tests, all passing.

### Deviations from plan
- SB-4: no new test needed — `presetLookupReturnCorrectCategory()` already
  covers the behavior; the switch just makes future omissions a compile error.

### Discoveries
- SB-1 was broken in English too: "WHO" vs "WHO (Global)". The Polish locale
  just made the mismatch more dramatic in the test output.

---

## 2026-05-20 — Phase B+D: domain coverage + remaining gaps

### Done
- Created GuidelineChoiceDisplayTests.swift, AlcoholUnitTests.swift,
  DrinkTemplateTests.swift. Added skipStep and Hashable tests to existing files.
- 94 → 121 tests, all passing.
- `DashboardViewModelTests` split from 324 lines into 3 files (main / +Metrics /
  +Formatting), all under 200 lines.

### Deviations from plan
- None.

### Discoveries
- `GuidelineChoiceDisplayTests` required `@MainActor` because `displayName`
  is inferred as main-actor-isolated (defined in a file importing SwiftUI).
- `BiologicalSex` is not `CaseIterable`; had to iterate `[.male, .female]` manually.
- `DrinkTemplate` raw xccov coverage reads as 31% (not 100%) because preview
  static getters are counted in the denominator. Testable code is 100%.

### Open questions updated
- Resolved: inline literal `1.0` chosen for SB-2 clamp.

---

## 2026-05-20 — Phase E: final coverage check + docs

### Done
- Final coverage run: Domain ~100%, DashboardViewModel 98%, OnboardingViewModel 100%,
  DrinkTypePreset 91%, UserProfile 91%. All targets met.
- File size check: no files over 300 lines.
- DEVLOG, roadmap, current-focus, INDEX, retrospective updated.
- Plan status → completed.
