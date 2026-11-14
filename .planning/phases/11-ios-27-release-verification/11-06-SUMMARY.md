---
phase: 11-ios-27-release-verification
plan: 06
subsystem: testing
tags: [ver-03, accessibility, checklist, simulator-clone, owner-session, xcode-mcp]
status: complete

requires:
  - phase: 11-ios-27-release-verification
    provides: plan 11-03 gated audit and D11-22 record, plan 11-04 and 11-10 automated results, plan 11-11 Info.plist change
provides:
  - "11-A11Y-CHECKLIST.md: eleven items CHK-00 to CHK-10, every result pending, automated field kept apart from the human result"
  - "A cloned simulator named dp-phase11-a11y, booted, reset to light appearance, Increase Contrast off and the default text size, with the Debug app installed and launched with the seeded synthetic dataset"
  - "Out-of-git files in the stamp directory: clone-udid.txt, bundle-id.txt, installed-product-path.txt"
affects: [11-07, 11-08, 11-09]

actuals:
  tokens: 9000
  tasks: 2
  commits: 1
plan_head_before: bdfdc79831b70f9aca7633dbe84499477ac1f8df
plan_head_after: 4c2fb7c8ea7eddc7709638517656e7656daaa08f

key-files:
  created:
    - .planning/phases/11-ios-27-release-verification/11-A11Y-CHECKLIST.md
  modified: []

key-decisions:
  - "D11-22 wording used in every automated field that cites the audit: audit run: 16 methods red, 311 open findings; groups G01 to G09 cited where they apply; the audit is never described as green"
  - "The installed app is a fresh MCP Debug build of the current HEAD, not the 11-01 product, because the 11-01 product lacks the D11-21 iPad orientation entry"

requirements-completed: []  # VER-03 completes with plans 11-07 and 11-08 (owner session and reconciliation)

completed: 2026-11-15
---

# Phase 11 Plan 06: Owner Accessibility Checklist and Simulator Clone Summary

**An eleven-item VER-03 owner checklist (all results pending) and an isolated, reset simulator clone with the current Debug build running the seeded synthetic dataset, ready for the plan 11-07 owner session.**

## Accomplishments

- `11-A11Y-CHECKLIST.md` (160 lines): title block stating the run is on the iOS 27.2 simulator, not on a device; Privacy rule, Stop rule, How to record results, Session setup, eleven items, and an observation section. Each item has `source:`, `automated:`, `human steps:`, `result: pending`, `notes:`.
- Probe item CHK-00 decides whether VoiceOver and the rotor Audio Graph action are reachable on the simulator. If not, CHK-01, CHK-02 and CHK-10 become `open` with the reason "CHK-00" (not passed).
- Archived Phase 05 tests are linked: CHK-03 to 05-UAT test 4, CHK-01 to test 5, CHK-02 to test 6. The three ungated animation sites are CHK-04 (`DPArcProgress.swift` line 18), CHK-05 (`ConsumptionOverviewCard.swift` line 110) and CHK-06 (`HistoryCalendarView.swift` line 61). Line numbers were read against the source before writing.
- WINDOWS rows 3, 4 and 6 are the sources of CHK-10, CHK-09/CHK-08 and CHK-07/CHK-08.
- Automated fields that cite the audit (CHK-01, CHK-07, CHK-08) use the D11-22 wording "audit run: 16 methods red, 311 open findings", with groups A11Y-AUDIT-G01, G03 to G08 where relevant. The audit is not described as passing anywhere.
- Clone: `xcrun simctl clone` of the primary simulator after shutting it down, then boot, reset readback `light / disabled / large`, install, launch with `-dp_onboarding_done YES -dp_uitest YES -dp_uitest_dataset multiday -dp_uitest_unit metric` (a process id was printed). A screenshot of the clone showed the Home screen in light appearance with the seeded data, no error screen. The screenshot stays in the scratchpad and is not committed.
- Task 2 gate (booted, reset, app installed, exactly one device named dp-phase11-a11y, no UUID-shaped string in the checklist) printed "clone ready, booted, reset, app installed".

## Task Commits

1. Task 1, checklist: `4c2fb7c` (docs)
2. Task 2: no repository file changed; the clone, the install and the Session setup statement (already written in Task 1 and now true) are the result.

## Deviations from Plan

**1. [Plan assumption stale] Installed product is a new MCP Debug build, not the 11-01 product**
- **Found during:** Task 2 step 4
- **Issue:** The plan assumes no production file changed in Phase 11. Plan 11-11 (D11-21, commit `64642a6`) added `UIInterfaceOrientationPortraitUpsideDown` to `UISupportedInterfaceOrientations~ipad` in `drinkpulse/Info.plist`. The product `build/p11-debug/Build/Products/Debug-iphonesimulator/drinkpulse.app` (built 2026-11-14 13:15) lists only LandscapeLeft, LandscapeRight and Portrait, so it is stale.
- **Fix:** Built current HEAD with Xcode MCP `BuildProject` (workspace resolved with `XcodeListWorkspaces`, active destination iPhone 18 Pro, iOS 27.2): built successfully, `GetBuildLog` at warning severity returned 0 entries. Located the product through `GetTargetBuildSettings` (SYMROOT, `Build/Products/Debug-iphonesimulator/drinkpulse.app` in the project's DerivedData), confirmed its Info.plist lists PortraitUpsideDown, and installed that product. No CLI `xcodebuild` was used (D11-20). The product path is recorded in the out-of-git `installed-product-path.txt`.
- **Files modified:** none in git.

**2. [Plan assumption stale] Source guard cannot exit 0**
- `git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` is non-zero because of D11-21. Same proof as plans 11-04 and 11-05: `git diff --name-only 2aa9156 -- drinkpulse drinkpulse.xcodeproj` lists exactly `drinkpulse/Info.plist`, and `--numstat` reads `1 0`. This plan changed no production or project file.

**3. [Process note] The Session setup statement was written during Task 1**
- The line saying the clone exists and is prepared was written with the checklist and committed before the clone was built. The clone was then prepared and the Task 2 gate confirmed the statement is true. If the clone had failed, the checklist would have needed a correction.

## Simulator state at hand-off

- The primary simulator (iPhone 18 Pro) was shut down for the clone and is still shut down. It never received an accessibility override. Plans that run tests boot it again.
- The iPhone 18 Pro Max simulator (secondary destination) stays booted and was not touched.
- The clone `dp-phase11-a11y` is booted with the app running. It is not deleted: plan 11-07 hands it to the owner and deletes it afterwards.
- No simulator identifier is in any committed file (checked by the Task 1 and Task 2 gates).

## Known Stubs

None.

## Threat Flags

None. No production code, network, auth or schema change. The clone runs the in-memory synthetic dataset only (T-11-20), the checklist holds no identifier (T-11-21), and all settings changes are on the clone, not on the primary simulator (T-11-22). The checklist forbids passing an item from automated or inferred evidence and makes CHK-00 decide whether Audio Graph is verifiable (T-11-23).

## Self-Check: PASSED

- `11-A11Y-CHECKLIST.md` exists, 11 `result: pending`, no UUID-shaped string.
- Commit `4c2fb7c` is an ancestor of HEAD.
- Clone booted with light / disabled / large, app installed, exactly one device named `dp-phase11-a11y`.
