# Stack Research — v1.4

Researched 2026-09-15 using installed tooling and official Apple Documentation through Xcode MCP. Research performed inline.

## Baseline

- Xcode 27.0 (27A266a); iOS 27.0 device and simulator SDKs installed (`xcodebuild -version`, `-showsdks`). SDK installation does not prove a usable simulator runtime or passing builds.
- Xcode MCP confirms three targets: drinkpulse, drinkpulseTests, drinkpulseUITests.
- Existing app uses SwiftUI, SwiftData, Swift Charts, Observation, UserNotifications, HealthKit and Swift 6 mode.
- No new library is justified by the approved migration scope. Verify resolved dependencies and build scripts during Phase 08.

## Recommendation

Set iOS 27.0 minimum consistently for all targets/configurations; record exact compiler/SDK/runtime versions in verification. Preserve the existing Swift 6 language mode unless diagnostics and official guidance establish a reason to change it. Compiler version and Swift language mode are separate settings.

## Sources

- https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes
- https://developer.apple.com/documentation/ios-ipados-release-notes/ios-ipados-27-release-notes
- Xcode MCP XcodeListTargets and local xcodebuild metadata, 2026-09-15.

## Limits

Release-note search results included multiple beta snapshots. Re-open the exact official release notes matching the selected installed toolchain during phase planning. No build or runtime compatibility claim has been established by this research.
