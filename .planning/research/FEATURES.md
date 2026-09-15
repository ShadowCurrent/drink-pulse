# Feature Research — v1.4

## Required capabilities

| Capability | Existing evidence | Migration work |
|---|---|---|
| iOS 27 baseline | Three app/test targets; iOS 26 minimum | Align deployment settings, tooling and living docs |
| SwiftUI modernization | RootShellView already uses Tab, NavigationStack, sensoryFeedback | Inventory actual deprecated/obsolete APIs and justified improvements across screens/design system |
| Data preservation | MigrationPlan lists SchemaV1 through SchemaV4 | Exercise supported legacy fixtures and current store on iOS 27; preserve identities, values and profile |
| Platform integrations | HealthKitAdapter uses async authorization/save/query; notifications use protocol wrappers | Review isolation, permissions, scheduling and launch routing against official docs |
| Accessible existing flows | History UAT passed; archived chart checks skipped | Recheck on iOS 27 including Audio Graph and Reduce Motion |

## Scope boundaries

Modernize existing capabilities. History filtering, autocomplete changes, notification copy improvements, CloudKit activation, BAC, AI, Watch/iPad features and the separately deferred #Index schema change are not added merely because newer APIs exist. Adopt API replacements only with official source, availability and behavior rationale.

## Sources

- https://developer.apple.com/documentation/SwiftUI/Migrating-to-New-Navigation-Types
- https://developer.apple.com/documentation/SwiftUI/SwiftUI_Extended_API_Documentation
- https://developer.apple.com/documentation/HealthKit/HKHealthStore/requestAuthorization(toShare:read:)
- Local RootShellView.swift, HealthKitAdapter.swift, MigrationPlan.swift; archived 05-UAT.md and 07-UAT.md.
