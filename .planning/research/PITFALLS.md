# Pitfalls Research — v1.4

- **False deprecation matches:** WeekdayBarChart uses Charts BarMark.cornerRadius; do not treat it as SwiftUI View.cornerRadius merely because the text matches. Resolve symbol/overload against Apple docs and compiler diagnostics.
- **Removing proven workarounds blindly:** opaque chart callout backgrounds and History List behavior came from reproduced platform failures. Retain until an iOS 27 reproduction and documented replacement justify removal.
- **Data loss masked as successful startup:** use non-destructive legacy/current store fixtures; verify record values, identities and profile, not merely that a fresh container opens. No resetting user data to make tests pass.
- **Concurrency regressions:** existing nonisolated/@unchecked Sendable sites and detached notification-delegate assignment need ownership/lifecycle analysis. New annotations are not automatic upgrades. Verify cold/warm routing and startup responsiveness.
- **Incomplete platform tests:** an SDK is not a runtime, and automated descriptors do not prove VoiceOver behavior. Confirm test destinations and retain explicit human/device checks.
- **Stale completion claims:** three chart UAT checks remain skipped in archived Phase 05; four Phase 07 ledger checks have later passed UAT evidence. Carry debt explicitly and reconcile only with evidence.
- **Warning suppression:** fix app-owned deprecations; document individually any externally blocked issue with source, owner and impact. Do not globally suppress warnings.

## Sources

- https://developer.apple.com/documentation/SwiftData/SchemaMigrationPlan
- https://developer.apple.com/documentation/Swift/concurrency
- https://developer.apple.com/documentation/UserNotifications/UNUserNotificationCenter (delegate must be assigned before tasks that interact with it)
- Existing archived Phase 05/07 UAT, RootShellView.swift, drinkpulseApp.swift and WeekdayBarChart.swift.
