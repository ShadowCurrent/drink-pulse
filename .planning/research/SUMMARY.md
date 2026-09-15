# Project Research Summary

**Milestone:** v1.4 iOS 27 Migration & Modernization
**Date:** 2026-09-15
**Method:** Inline source review plus official Apple Documentation via authorized Xcode MCP; no implementation or test execution yet.

## Key Findings

The compatible SDK/toolchain is installed. The app already uses modern navigation, Observation and async HealthKit APIs, so the migration must begin with a complete evidence-based inventory rather than generic API replacement recipes. Persistence has four shipped schema versions. Existing platform workarounds require reproduction before removal.

## Implications for Roadmap

1. Phase 08: iOS 27 toolchain/minimum baseline and complete modernization inventory.
2. Phase 09: implement justified SwiftUI/design-system changes.
3. Phase 10: implement justified persistence, concurrency and platform integration changes, preserving existing data.
4. Phase 11: integrated regression, accessibility and release verification.

Final requirements and roadmap remain subject to owner review. Every candidate gets a change/retain/blocked disposition, exact source and availability. No candidate becomes mandatory merely from appearing in research.

## Sources

- https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes
- https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes
- https://developer.apple.com/documentation/SwiftUI/SwiftUI_Extended_API_Documentation
- https://developer.apple.com/documentation/SwiftData/SchemaMigrationPlan
- https://developer.apple.com/documentation/Swift/concurrency
- https://developer.apple.com/documentation/UserNotifications/UNUserNotificationCenter
- https://developer.apple.com/documentation/HealthKit/HKHealthStore/requestAuthorization(toShare:read:)

## Open verification work

No compiler-warning baseline, runtime build, migration fixture execution or human UAT was performed here. Phase 08 must inspect matching toolchain release notes and produce the full inventory; phase execution must attach actual results. Legacy research was preserved under .planning/milestones/v1.3-research/.
