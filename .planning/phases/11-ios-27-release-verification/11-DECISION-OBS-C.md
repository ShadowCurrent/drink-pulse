# OBS-C - Settings tab shows an endless ProgressView when the store has no UserProfile

**Status:** owner decision pending. Phase 11 makes no fix and writes no production code.
**Source:** owner observation during the CHK-07 walk (`11-A11Y-CHECKLIST.md`), plan 11-07, on the iOS 27.2 simulator (not a device).
**Result:** observation recorded as an edge-case defect. It is not a checklist fail. The file name uses OBS-C, not a C-number, because the plan's gate counts `11-DECISION-C0*.md` files against `fail` results.

## Current behavior

Trigger: the app was launched from its icon without launch arguments, so it used the clone's on-disk store and not the seeded in-memory dataset. That on-disk store had events and onboarding marked done but no `UserProfile`. How the clone's store reached that state is unknown; it was not inspected and no data value is recorded here.

What the owner saw: the Settings tab shows a spinner that never ends, at about 0 percent CPU.

Code location (read-only): `drinkpulse/Features/Settings/SettingsView.swift` lines 9 to 13 show `SettingsForm` when `profiles.first` exists and otherwise `ProgressView()`. A missing profile is therefore indistinguishable from a loading state, and nothing creates a profile on that path. Other code creates a profile in onboarding (`OnboardingViewModel.swift`), in import (`DataImporter.swift`) and in `Domain/Persistence/UserProfileStore.swift`. Whether any of those can run for a returning user with onboarding already done was not investigated in this phase.

Whether a real user can reach this state (for example after an interrupted onboarding, a partial import or store recovery) is not established. Impact: low likelihood, but the screen gives the user no way out.

## Source-backed decision table

**Availability:** the APIs below are available at the iOS 27.0 deployment target. The documentation extracts returned by Xcode MCP DocumentationSearch carry no older-availability line, so no older-version claim is made here.

| Topic | Evidence |
| --- | --- |
| Official source | SwiftUI `ProgressView` ("an indeterminate progress view ... use an initializer that doesn't take a progress value", `/documentation/SwiftUI/ProgressView`) and `ContentUnavailableView` (`/documentation/SwiftUI/ContentUnavailableView`). Read through Xcode MCP DocumentationSearch on 2026-11-16. |
| Option retain | Keep the spinner; accept the edge case. Cost: a dead-end screen if the state is reachable. |
| Option change | Create the missing profile through the existing profile store, or show an empty state with a recovery action instead of a spinner. Cost: touches a data-creating path, so a model and migration review and the CloudKit and HealthKit forward-compatibility rules apply. This is a product decision. |
| Option defer | First establish whether a real user can reach the state (ties to open question WR-04 on store recovery). |
| Recommendation | None in Phase 11 by plan rule; the owner chooses retain, change or defer. |
| Data, accessibility, lifecycle risk | Data: any change that creates a profile is a data-creating path. No schema change is proposed. Accessibility: an endless spinner with no label or action. |

## Recommendation and proposed scope

No fix in Phase 11. The first step is to find out whether the state is reachable by a real user; only then choose between a profile-creating change and an empty state.

## Owner decision record

decision: pending
decision date: none
exact scope: none
owner reason: none
2026-11-16: not decided in the gap-closure planning session; the decision stays pending; no fix is planned in Phase 11 gap closure.
