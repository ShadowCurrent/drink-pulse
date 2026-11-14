---
phase: 11-ios-27-release-verification
plan: 11
subsystem: verification
tags: [info-plist, ipad, interface-orientations, release-build, store-validation, xcode-mcp, ios27]

requires:
  - phase: 11-ios-27-release-verification
    provides: "Plan 11-01 finding: Release device build emits 'All interface orientations must be supported unless the app requires full screen.'"
provides:
  - "UIInterfaceOrientationPortraitUpsideDown in UISupportedInterfaceOrientations~ipad (owner decision D11-21)"
  - "Proof that the orientation validation warning is gone (second Release device build, exit 0, 0 orientation lines)"
  - "11-EVIDENCE.md subsection 'Fix: iPad orientations (D11-21)' and updated MOD-04 outcome"
affects: [11-04, 11-05, 11-08]

actuals:
  tokens: 2600
  tasks: 1
  commits: 1
plan_head_before: 2da47bb32eacc37f1677456f8d7e96fdf23322cd
plan_head_after: 079082447ef358d30e2c3d5c4bd2e67fc1bbdb07

tech-stack:
  added: []
  patterns:
    - "Runner policy D11-20/D11-21: Xcode MCP for Debug, exactly one extra CLI Release device build"

key-files:
  created: []
  modified:
    - drinkpulse/Info.plist
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md

key-decisions:
  - "Followed owner decision D11-21: add PortraitUpsideDown for iPad only; no UIRequiresFullScreen, TARGETED_DEVICE_FAMILY unchanged, iPhone key still Portrait only"

requirements-completed: []

status: complete
---

# Phase 11 Plan 11: iPad Orientation Warning Fix Summary

One plist array entry (`UIInterfaceOrientationPortraitUpsideDown` for iPad) clears the only app-owned Release warning, proven by a full MCP Debug build and one CLI Release device build.

## What was done

- **Documentation:** Xcode MCP `DocumentationSearch` (query "supportedInterfaceOrientations multitasking all orientations iPad") returned the UIKit page `supportedInterfaceOrientations` (`UIViewController`). It says all iPadOS devices support portraitUpsideDown, enabling it for the iPad idiom is best practice, and multitasking apps must support all orientations. Cited in 11-EVIDENCE.md.
- **Change:** `drinkpulse/Info.plist`, `UISupportedInterfaceOrientations~ipad` now lists LandscapeLeft, LandscapeRight, Portrait, PortraitUpsideDown. iPhone key unchanged (Portrait only). No `UIRequiresFullScreen`. Commit `0790824`.
- **Debug proof (Xcode MCP):** DerivedData for the project removed first (0 `drinkpulse-*` folders left), then `BuildProject` buildForTesting: built successfully, empty error list, 16.975 s. `GetBuildLog` at warning severity: `totalFound` 0. Log holds 3 `appintentsmetadataprocessor` tool notes (same external note as before). Digest `59f77a39...f143163`.
- **Release proof (the one CLI run, D11-21):** `xcodebuild clean build ... -configuration Release -destination "generic/platform=iOS" -derivedDataPath build/p11-release-device CODE_SIGNING_ALLOWED=NO`. Exit 0, `** BUILD SUCCEEDED **`, `validate-for-store` step present, 0 lines of "All interface orientations must be supported", 0 `dismissSheet`. Only plain `warning:` line is the `appintentsmetadataprocessor` note. Digest `bd6c2055...1632c`.
- **Evidence:** 11-EVIDENCE.md has the new subsection, an updated MOD-04 outcome (app-owned non-deprecation warnings: 0), an updated classification row, and a source-guard row recording the single Info.plist change.
- **Ledger and state:** STATE.md blocker for the orientation warning removed. `.planning/WINDOWS.md` entry 12 marked fixed with commit `0790824`.

## Runners used

| Step | Runner |
|------|--------|
| Documentation lookup | Xcode MCP `DocumentationSearch` |
| Workspace resolution | Xcode MCP `XcodeListWorkspaces` |
| Debug build and warning log | Xcode MCP `BuildProject`, `GetBuildLog` |
| Release device build | CLI `xcodebuild` (exactly one invocation, owner-approved D11-21) |

No other CLI `xcodebuild` run and no CLI fallback.

## Deviations from Plan

None - plan executed exactly as written. Two notes:
- A first commit carried AI attribution trailers by mistake; it was amended before anything else used it, per AGENTS.md (local, unpushed). Final commit has none.
- `requirements-completed` is left empty on purpose, as in 11-01: MOD-04 and VER-01 outcomes are owned by the final reconciliation (plan 11-08) and the full-suite plan (11-05); this plan supplies MOD-04 evidence only.

## Verification

Plan `<automated>` verify command printed `ok` (iPad array 4 entries incl. PortraitUpsideDown, iPhone array 1 entry, no `UIRequiresFullScreen`, Release exit 0, success marker, no orientation line, D11-21 in evidence).

Quality gates: no Swift source changed, so no unit or UI test applies (config-only change); app built under Xcode MCP with zero warnings from `GetBuildLog`. No new network, logging or schema surface; no `@Model` change.

## Known Stubs

None.

## Threat Flags

None. T-11-40: only the `~ipad` array changed (iPhone key verified Portrait only). T-11-41: raw logs stayed out of git; only counts and digests are recorded.

## Self-Check: PASSED

- `drinkpulse/Info.plist` change present (4 iPad entries).
- Commit `0790824` is an ancestor of HEAD.
- `release-device-build-2.log` and `.exit` exist in the out-of-git stamp directory.
