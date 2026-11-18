---
phase: 11-ios-27-release-verification
plan: 07
subsystem: testing
tags: [ver-03, accessibility, owner-session, simulator, reduce-motion, dynamic-type, voiceover]
status: complete

requires:
  - phase: 11-ios-27-release-verification
    provides: plan 11-06 checklist and simulator clone, plans 11-03, 11-04 and 11-10 automated results
provides:
  - "11-A11Y-CHECKLIST.md: owner results for CHK-00 to CHK-10 (3 pass, 3 fail, 5 open, none pending)"
  - "Human column of the Accessibility table in 11-EVIDENCE.md, automated column unchanged"
  - "Phase 05 skipped checks reconciled in 11-DISCOVERIES.md (CHK-03 pass, CHK-01 open, CHK-02 open)"
  - "Ledger rows DL-O04 to DL-O16"
  - "Owner D-09 briefs 11-DECISION-C014, C015, C016 (fails) and 11-DECISION-OBS-A, OBS-C (owner observations), all decision pending"
affects: [11-08, 11-09]

actuals:
  tokens: 12500
  tasks: 3
  commits: 1
plan_head_before: 3289548ae230f14a10814006e0751dfa2ec08ee3
plan_head_after: 9ec6af27d16415bbd3fa79b580dd5bb621422c89

key-files:
  created:
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C014.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C015.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-C016.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-OBS-A.md
    - .planning/phases/11-ios-27-release-verification/11-DECISION-OBS-C.md
  modified:
    - .planning/phases/11-ios-27-release-verification/11-A11Y-CHECKLIST.md
    - .planning/phases/11-ios-27-release-verification/11-EVIDENCE.md
    - .planning/phases/11-ios-27-release-verification/11-DISCOVERIES.md
    - .planning/phases/11-ios-27-release-verification/11-DEBT-LEDGER.md

key-decisions:
  - "No result was written by the executor: every pass, fail and open comes from the owner's reply at the blocking-human checkpoint (never auto-approved); CHK-01, CHK-02 and CHK-10 are open with reason CHK-00 as the rules require"
  - "OBS-A is recorded as an owner D-09 brief but CHK-01 is not marked fail: the owner result is open per CHK-00, and the 'raw date spoken' cause is labelled an unverified hypothesis"
  - "OBS-A and OBS-C briefs use OBS names, not C numbers, so the plan gate that counts 11-DECISION-C0*.md files against fail results (3 fails, 3 briefs) still holds"

requirements-completed: []  # VER-03 completes with plan 11-08 (reconciliation); no STATE or ROADMAP update by instruction

completed: 2026-11-16
---

# Phase 11 Plan 07: Owner Accessibility Session Results Summary

**The owner ran the VER-03 checklist on the iOS 27.2 simulator clone: 3 pass (Reduce Motion on charts, light and dark, Increase Contrast), 3 fail (two ungated animations, AX5 text clipping), 5 open (Audio Graph and VoiceOver items blocked by the simulator, the Home arc not judgeable); five owner briefs filed with decisions pending, no fix made, clone deleted.**

## Owner results (iOS 27.2 simulator, not a device, 2026-11-16)

| Item | Result | Note |
|------|--------|------|
| CHK-00 | open | VoiceOver switches on but the rotor cannot be opened; requires device |
| CHK-01 | open | reason CHK-00 |
| CHK-02 | open | reason CHK-00 |
| CHK-03 | pass | callout jumps without animation with Reduce Motion on; caveat: no callout animation visible with it off either |
| CHK-04 | open | the arc refreshes while the Add Drink sheet covers it, so it could not be judged |
| CHK-05 | fail | Home overview card bar always animates (brief C014) |
| CHK-06 | fail | History calendar detail area always animates (brief C015) |
| CHK-07 | fail | AX5 truncation, clipping and overlap on Home, Insights, Add Drink, Settings Preferences, Onboarding; guideline picker and History fine (brief C016) |
| CHK-08 | pass | light and dark fine |
| CHK-09 | pass | Increase Contrast fine in both appearances |
| CHK-10 | open | reason CHK-00 |

## Accomplishments

- Task 1: the clone was booted and reset (light, Increase Contrast off, default text size), and the seeded app launched (the verify gate printed a process id). Simulator.app does not exist in Xcode 27.2, so the window step could not run; the owner used the Xcode 27 Device Hub app.
- Task 2: blocking-human checkpoint answered by the owner; not auto-approved.
- Task 3: results written into the checklist, the Human column of the Accessibility table filled, the three Phase 05 rows reconciled, ledger rows DL-O04 to DL-O16 added, five owner briefs written, the clone deleted. The plan's verify script passed.
- The D11-22 wording is kept: the automated audit is gated with 311 open findings and is never described as green. CHK-07 cross-references audit groups G01, G03, G04 and G07 by location only; this is not a confirmation of those groups.

## Owner observations outside the checklist

- OBS-A (likely defect): with VoiceOver on, focusing an Insights chart point reads a very large number instead of date and value. Cause is an orchestrator hypothesis (raw date spoken), not verified in code. Related in kind to audit group G05. Brief `11-DECISION-OBS-A.md`.
- OBS-B (observation, not a defect): VoiceOver speaks some elements in English and some in Polish; probable cause is an English-only app on a Polish simulator. Ledger DL-O13, no brief.
- OBS-C (edge-case defect): Settings shows an endless ProgressView when the store has no `UserProfile` (`SettingsView.swift` line 12). Brief `11-DECISION-OBS-C.md`. No store content was read or recorded.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Result and notes lines changed from list items to plain lines**
- **Found during:** Task 3
- **Issue:** the checklist from plan 11-06 wrote `- result:` and `- notes:` as list items, but the verify scripts of plans 11-07 and 11-09 match `^result:` and `^notes:`; with the list prefix the gate would have read every item as missing.
- **Fix:** the recorded lines are plain `result: <value>` and `notes: <text>` lines, preceded by a blank line. The `result: pending` count check of plan 11-06 is unaffected.
- **Files modified:** `11-A11Y-CHECKLIST.md`
- **Commit:** 9ec6af2

**2. [Rule 3 - Blocking] OBS briefs named OBS-A and OBS-C instead of C017 and C018**
- **Found during:** Task 3
- **Issue:** the coordinator asked for briefs for OBS-A and OBS-C in addition to the three fails, but the plan gate asserts that the number of `11-DECISION-C0*.md` files equals the number of `fail` results (3).
- **Fix:** the two extra briefs are `11-DECISION-OBS-A.md` and `11-DECISION-OBS-C.md`, with the same four required headings and `decision: pending`. The verify gate was extended locally to check them for headings and UUID-shaped strings.
- **Commit:** 9ec6af2

**3. [Rule 3 - Blocking] Simulator window could not be opened**
- **Found during:** Task 1
- **Issue:** `open -a Simulator` fails; Xcode 27.2 has no `Simulator.app`. Not a task failure: the owner used the Xcode 27 Device Hub app instead (recorded as session integrity in the checklist header and ledger DL-O16).

### Expected diff guard result

`git diff --quiet 2aa9156 -- drinkpulse drinkpulse.xcodeproj` exits 1, as already recorded in `11-EVIDENCE.md`: the only changed file is `drinkpulse/Info.plist`, the owner-approved D11-21 change from plan 11-11. This plan edited no production or project file.

## Session integrity notes

Settings were switched with the Device Hub app and not the simulator Settings app; part of the early CHK-07 walk ran from an icon launch without the seeded arguments (on-disk store of unknown origin, not read); the owner shut the clone down once and it was rebooted and reset. Layout and Reduce Motion observations do not depend on the dataset. Recorded in the checklist header and as DL-O16.

## Known Stubs

None. No code was written.

## Threat Flags

None. No new network, auth, file or schema surface; documentation only.

## Self-Check: PASSED

- Files checked: `11-DECISION-C014.md`, `C015`, `C016`, `OBS-A`, `OBS-C` and the four modified documents exist.
- Commit `9ec6af2` is an ancestor of HEAD.
- `xcrun simctl list devices` shows no device named dp-phase11-a11y.
- No UUID-shaped string appears in any committed Phase 11 document touched by this plan.
