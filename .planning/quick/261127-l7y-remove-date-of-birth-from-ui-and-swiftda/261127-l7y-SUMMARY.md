---
phase: quick-261127-l7y
plan: 01
subsystem: profile / persistence / export
status: complete
tags: [swiftdata, migration, privacy, onboarding, settings, export]
requires: []
provides:
  - SchemaV5 (live models) with lightweight v4ToV5 stage
  - Frozen self-contained SchemaV4 snapshot
  - DOB-free onboarding About You and Settings Profile
  - Export without date of birth; legacy v2 backups with the key still import
affects: [UserProfile, MigrationPlan, ProfileRecord, onboarding, Settings]
tech-stack:
  added: []
  patterns: ["freeze shipped VersionedSchema as nested @Model copies, add new version + lightweight stage"]
key-files:
  created:
    - drinkpulse/Domain/Persistence/Schemas/SchemaV5.swift
    - drinkpulseTests/Domain/Persistence/MigrationFixtures+V4.swift
    - drinkpulseTests/Domain/Persistence/MigrationV4ToV5Tests.swift
    - drinkpulseTests/Domain/DataTransfer/LegacyDateOfBirthImportTests.swift
  modified:
    - drinkpulse/Domain/Persistence/Schemas/SchemaV4.swift
    - drinkpulse/Domain/Persistence/MigrationPlan.swift
    - drinkpulse/Domain/UserProfile.swift
    - drinkpulse/Domain/DataTransfer/ProfileRecord.swift
    - drinkpulse/Features/Onboarding/Components/ProfileStep.swift
    - drinkpulse/Features/Settings/Components/ProfileSection.swift
    - drinkpulse/Features/Settings/UserProfile+TouchingBinding.swift
    - drinkpulse/Features/Settings/Components/DataSection.swift
    - drinkpulse/Localizable.xcstrings
decisions:
  - "Date of birth removed from UI, SwiftData model (SchemaV5 + lightweight v4ToV5) and export; stored dates deleted on first launch (owner-requested, one-way)"
  - "Lightweight stage, not custom: Core Data inferred mapping lists removal of an attribute; MigrationV4ToV5Tests is the empirical proof"
  - "Export bundle version stays 2: synthesized decoder ignores the legacy key"
metrics:
  duration: "about 17 min"
  completed: 2026-11-27
actuals:
  tokens: 19300
  tasks: 3
  commits: 3
plan_head_before: 215821deb4b8fc71f59e204dcf71261b5d99253f
plan_head_after: 69e07ff0cebf36200bdfe331026e96ead9c87810
---

# Quick 261127-l7y Plan 01: Remove date of birth Summary

Date of birth removed end to end: About You and Settings Profile show only biological sex,
`UserProfile` loses the attribute through a frozen `SchemaV4` snapshot plus a new `SchemaV5`
and lightweight `v4ToV5` stage, and exports omit the key while legacy v2 backups with it still
import.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 | 7832595 | [quick-261127-l7y] remove date of birth from onboarding and settings UI |
| 2 | 6509a6b | [quick-261127-l7y] drop UserProfile date of birth via SchemaV5 lightweight stage |
| 3 | 69e07ff | [quick-261127-l7y] docs: record date of birth removal |

No AI attribution lines in any commit (AGENTS.md rule).

## Apple documentation consulted (Xcode MCP DocumentationSearch)

- `/documentation/SwiftData/MigrationStage#Migration-stages`: `lightweight(fromVersion:toVersion:)`.
  The SwiftData page does not say which changes a lightweight stage can infer.
- `/documentation/CoreData/migrating-your-data-model-automatically#Generating-an-inferred-mapping-model`:
  "Removal of an attribute" is an obvious migration pattern. Also
  `/documentation/CoreData/NSMappingModel/inferredMappingModel(forSourceModel:destinationModel:)`
  ("removing or renaming an attribute"). Decision: lightweight stage; `MigrationV4ToV5Tests`
  (didRecover == false) is the empirical proof.
- `/documentation/CoreData/NSManagedObjectModel/entityVersionHashesByName` ("used to determine
  schema compatibility") and `NSManagedObjectModel.makeManagedObjectModel(for:mergedWith:)`.
- `/documentation/SwiftData/Schema/Entity#Managing-properties`: `storedPropertiesByName`.
- Availability: all available on the iOS 27 target (Debug build on the iOS 27.2 SDK, 0 warnings).
  The search results did not show introduction versions.

## Hash gate (Task 2 Step 3, run before the live model changed)

```
HASHGATE frozen entities: ["ConsumptionEvent", "DrinkTemplate", "UserProfile"] live entities: ["ConsumptionEvent", "DrinkTemplate", "UserProfile"]
HASHGATE DrinkTemplate equal: true frozen: YRB5hjWswBEZy+vdZTxANiHJgu/+Lvp+K0AcdeLxDaY= live: YRB5hjWswBEZy+vdZTxANiHJgu/+Lvp+K0AcdeLxDaY=
HASHGATE ConsumptionEvent equal: true frozen: Wc3C0xnIs/UCE6wfFu9Vd1KDiT/93mGKY38Xp23uU78= live: Wc3C0xnIs/UCE6wfFu9Vd1KDiT/93mGKY38Xp23uU78=
HASHGATE UserProfile equal: true frozen: ikyasCjp71PV/SjdsDbuGOOagbBGfLzRaSuQ7t48wy0= live: ikyasCjp71PV/SjdsDbuGOOagbBGfLzRaSuQ7t48wy0=
```

Gate passed. `RunCodeSnippet` failed to launch (`abort_could_not_find_entry_point___debug_dylib`,
a tooling failure), so the plan's fallback was used: a temporary Swift Testing test
(`TempV4HashGateTests`), run with `RunSomeTests`, then deleted before the commit.

## Test results (Xcode MCP, iPhone 18 Pro simulator, iOS 27.2)

- Task 1 scoped run: 43/43 passed (`OnboardingViewModelTests`, `UserProfileTouchingBindingTests`,
  `OnboardingFlowUITests`, `OnboardingDynamicTypeUITests`, `SettingsUITests`,
  `SettingsDynamicTypeUITests`). Both new UI tests ran and passed:
  `test_profileStep_hasNoDateOfBirthControl` and `test_profileSection_hasNoDateOfBirthRow`.
- Informational: `OnboardingAccessibilityAuditUITests` 4/4 passed. The known state was 3 of 4
  red. Nothing new failed. The cause of the change was not investigated.
- Task 2 RED: build-for-testing failed with "Cannot find 'SchemaV5' in scope" before production
  code existed.
- Task 2 GREEN: whole `drinkpulseTests` unit target (88 classes, every class in the target):
  864/864 passed. This includes `MigrationV4ToV5Tests` (2), `LegacyDateOfBirthImportTests` (1),
  `MigrationChainV1Tests`, `MigrationChainV2V3Tests`, `MigrationSweepTests`,
  `SanitizedBackupFixtureTests`, `ComprehensiveRoundTripTests` and `UserProfileTests`.
- Builds: 0 warnings after Task 1 and after Task 2 (`GetBuildLog` severity warning: 0 entries).
- Coverage: touched Domain files are at 100% line coverage in the unit run (`UserProfile.swift`,
  `ProfileRecord.swift`, `MigrationPlan.swift`, `SchemaV4.swift`, `SchemaV5.swift`). Overall
  coverage on the project's testable-code denominator was not re-measured. The unit-only raw app
  figure (47.67%) includes views and is not comparable.
- `RunAllTests` was never called. No physical device was used.

## Grep gates

A=0, B=0, C=0/1/1, D=0, E=3 nested @Model / SchemaV5 in plan / v4ToV5 in plan /
`Schema.Version(5, 0, 0)` in SchemaV5.swift, F=0, H=0, I: `SchemaV5` appears 2 times in
architecture.md and the open question is gone.
Gate G: 2 files are reported, and both were over 300 lines before this task and were not
touched by it: `drinkpulseTests/Services/HealthServiceTests.swift` (302) and
`drinkpulseTests/Features/Insights/InsightsViewModelTests+Aggregates.swift` (322). The todo
"Split test files over 300 lines" already tracks them. All files touched or created here are
under 300 lines.
`ExportBundle.swift` and `DataImporter.swift` are unchanged.

## Deviations from Plan

1. **[Rule 3 - Blocking] Hash gate tool fallback.** `RunCodeSnippet` crashed at launch (debug
   dylib entry point not found). I used the plan's named fallback, a temporary test that was
   deleted before the commit.
2. **current-focus.md:** the previous top section ("ui-revamp merged") moved down and was
   renamed "Historical:". Its Next line no longer lists the date-of-birth decision; it now points
   to the new section.
3. **open-questions.md:** I also added one line under the plan 0048 audit follow-up recording
   today's 4/4 audit run. This is informational for the owner.
4. **SanitizedBackupFixtureTests:** the plan named one test with the healthKitUUID check. A
   second test (`probe_exportOfImportedStoreHasNoHealthKitUUID`) has the same check and was left
   unchanged. Only the sanitized test was renamed and extended.

## Flags for the owner

- AGENTS.md and CLAUDE.md are stale: they still list "age" under the `UserProfile` domain model
  and "DOB" in the health-data privacy list. Per instruction, I did not edit them. The DEVLOG
  entry records this.
- One-way: the first launch of this build deletes stored dates of birth (owner-requested).
  CloudKit is not enabled.

## Known Stubs

None.

## Self-Check: PASSED

- Files exist: SchemaV5.swift, MigrationFixtures+V4.swift, MigrationV4ToV5Tests.swift,
  LegacyDateOfBirthImportTests.swift.
- Commits 7832595, 6509a6b and 69e07ff are ancestors of HEAD. `git rev-list --count
  215821d..HEAD` = 3.
