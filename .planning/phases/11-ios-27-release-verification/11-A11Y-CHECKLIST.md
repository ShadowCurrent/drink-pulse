# Phase 11 Owner Accessibility Checklist (VER-03)

This is the Phase 11 owner accessibility checklist for VER-03 (plan 11-06). It is run on the iOS 27.2 simulator, not on a device. A device pass on the final build is deferred by 11-CONTEXT.

Covers: ROADMAP success criteria 4 and 5, CONTEXT decisions D11-03 (owner runs the checklist on the simulator), D11-09 (the three skipped Phase 05 checks are folded in) and D11-17 (the three animation sites not gated by Reduce Motion go on the checklist).

Run by the owner on the iOS 27.2 simulator on 2026-11-16 (a simulator, not a device). Results were transcribed by the executor from the owner's reply, which was given in Polish and translated to English by the orchestrator.

Session notes (evidence integrity): accessibility settings were switched with the Xcode 27 Device Hub app and not with the simulator Settings app. For part of the session, at least the early CHK-07 walk, the app ran from an icon launch without the seeded launch arguments (on-disk store of unknown origin, not read); it was relaunched seeded for the Settings and onboarding parts of CHK-07 and for CHK-08 and CHK-09. Layout and Reduce Motion observations do not depend on the dataset. The owner shut the clone down once; the orchestrator rebooted it and reset it. Simulator.app is not present in Xcode 27.2.

Extra owner observations (not checklist items): OBS-A (VoiceOver reads a very large number for an Insights chart point; likely defect; brief 11-DECISION-OBS-A.md), OBS-B (VoiceOver speaks some elements in English and some in Polish; probable cause: the app is English-only and the simulator language is Polish; an observation, not a defect), OBS-C (Settings shows an endless ProgressView when the store has no profile; edge-case defect; brief 11-DECISION-OBS-C.md).

The app is the Debug build of the Phase 11 HEAD, launched with the seeded synthetic dataset (an in-memory dataset: no real data is on the simulator you use).

Automated results (the XCUITest accessibility audit and the existing UI and unit tests, recorded in `11-EVIDENCE.md`) and the human result are different things. Every item below keeps them in separate fields: `automated:` is what a machine already checked and what that does not prove, `result:` is your human result only. The automated audit is not green: it ran once and found open findings (audit run: 16 methods red, 311 open findings, owner decision D11-22). It is gated by default and proves nothing about the items below.

## Privacy rule (read first)

Results in this file hold **PASS, FAIL or OPEN values and a short note of what was seen**. Never write personal values, identifiers (device, simulator or event identifiers) or screenshots into this file, a commit or a chat reply that enters the repository. This file is committed to git, so a value that slips in cannot be cleanly retracted. This checklist runs on synthetic data only.

## Stop rule

If anything looks like data loss, a crash or a startup error screen, stop at that step and report only the category. This checklist uses synthetic data, so none is expected. No fix is made in Phase 11. A confirmed defect goes into `notes:`, the item is marked `fail`, and plan 11-07 turns it into an owner D-09 brief. The defect stays open.

## How to record results

- Each item starts with its result set to pending. Change it to the owner's answer when you have judged the item.
- Allowed values: `pass`, `fail`, `open`.
- `fail` and `open` need a `notes:` line.
- `open` means the check could not be performed or judged, and it is carried forward explicitly. It is not a pass.
- Never write `pass` from the automated field, from the chart descriptor unit tests, or from inference. A pass means you did the human steps and saw the expected behavior.
- Write counts and short phrases only (see the Privacy rule).

## Session setup

- The owner session uses a cloned simulator that the executor prepared with the app already installed. The exact launch and reset commands contain the clone's identifier, so they are given to you in the session message and are not stored here. In the commands below `<clone>` and `<bundle id>` stand for the values in that message.
- The clone exists, is booted, was reset to light appearance, Increase Contrast off and the default text size, and the app is installed and launched with the seeded dataset.
- Reset commands (run after any item that changes the setting):
  - `xcrun simctl ui <clone> appearance light`
  - `xcrun simctl ui <clone> increase_contrast disabled`
  - `xcrun simctl ui <clone> content_size large`
- Relaunch form, with the seeded dataset: `xcrun simctl launch --terminate-running-process <clone> <bundle id> -dp_onboarding_done YES -dp_uitest YES -dp_uitest_dataset multiday -dp_uitest_unit metric`
- Relaunch form for onboarding: `xcrun simctl launch --terminate-running-process <clone> <bundle id> -dp_uitest YES -dp_force_onboarding YES`
- Reduce Motion and VoiceOver are switched in the simulator's Settings app, under Accessibility. The simulator system language is Polish, so the Settings and Accessibility labels are in the simulator language. Find them by path (Accessibility, then Motion, then Reduce Motion; Accessibility, then VoiceOver), not by an English label. The app's own text is English.
- A relaunch is needed after changing the text size.
- The seeded dataset is in memory, so a relaunch restores the same synthetic data.

## Items

### CHK-00

Probe: is VoiceOver, and the rotor action named Audio Graph, reachable on this simulator?

- source: Apple's accessibility-testing article says VoiceOver is not available on Simulator, while plan 09-05 drove `XCUIVoiceOverService` on this simulator (`ShellNavigationUITests`). The conflict is unresolved, so this probe decides. If it fails, items CHK-01, CHK-02 and CHK-10 cannot be judged here.
- automated: `ShellNavigationUITests` VoiceOver test (Add Drink Cancel only; it has no rotor API). Result in `11-EVIDENCE.md`, Accessibility (VER-03), row "VoiceOver traversal". It does not prove that VoiceOver or the rotor Audio Graph action works on this simulator.
- human steps:
  1. In the simulator's Settings app, find Accessibility, then VoiceOver, and try to switch VoiceOver on.
  2. Open the app, go to the Insights tab, and try to focus a chart with VoiceOver.
  3. Open the rotor and try to reach the action named Audio Graph.
  4. If VoiceOver cannot be enabled, or the Audio Graph action cannot be reached, record `open` with the note "not verifiable on simulator, requires device (deferred per 11-CONTEXT)". CHK-01 and CHK-02 are then `open` with the reason "CHK-00". CHK-10 is `open` with the same reason.

result: open
notes: VoiceOver can be switched on, but the rotor cannot be opened on the simulator, so Audio Graph is not reachable; not verifiable on simulator, requires device (deferred per 11-CONTEXT). Related owner observation OBS-A (brief 11-DECISION-OBS-A.md): with VoiceOver on, focusing an Insights chart point reads a very large number instead of date and value.

### CHK-01

AlcoholAreaChart Audio Graph.

- source: archived 05-UAT test 5 (`.planning/milestones/v1.3-phases/05-insights-chart-scrubbing/05-UAT.md`, result skipped there). Expected: the rotor Audio Graph action surfaces every data point's date and value, independent of the drag gesture (CHART-03, D-08). Also WINDOWS row 3 context for the chart-accessibility debt.
- automated: `AlcoholAreaChartAXDescriptorTests` (4 tests, passed in row U1 of `11-EVIDENCE.md`). They check the descriptor content only. They do not prove what VoiceOver speaks or that the rotor action is offered. The chart day marks also appear in audit group A11Y-AUDIT-G05 (audit run: 16 methods red, 311 open findings).
- human steps: with VoiceOver on, focus the area chart on the Insights tab, open the rotor, choose Audio Graph, and listen to or read the points. Check that every data point gives a date and a value.

result: open
notes: CHK-00: the rotor Audio Graph action is not reachable on the simulator. Not marked fail; see OBS-A for the VoiceOver observation on chart points.

### CHK-02

WeekdayBarChart Audio Graph.

- source: archived 05-UAT test 6 (same file, result skipped there). Expected: the rotor Audio Graph action surfaces every data point's weekday and value, additive to the existing per-bar label (CHART-03, D-09).
- automated: `WeekdayBarChartAXDescriptorTests` (4 tests, passed in row U1 of `11-EVIDENCE.md`). Descriptor content only, not the rotor action.
- human steps: same as CHK-01 on the weekday chart on the Insights tab. Check that each bar gives its weekday and value through Audio Graph, and that the per-bar label is still present.

result: open
notes: CHK-00: the rotor Audio Graph action is not reachable on the simulator.

### CHK-03

Reduce Motion on both charts.

- source: archived 05-UAT test 4 (result skipped there) and UI-C-08 (needs human runtime verification). Expected: Reduce Motion suppresses both charts' callout transition and the selection animation together, never just one (CHART-04). Gate code: `drinkpulse/Features/Insights/Components/AlcoholAreaChart.swift` lines 104 and 105, and `drinkpulse/Features/Insights/Components/WeekdayBarChart.swift` lines 85 and 86.
- automated: none. There is no automated route to Reduce Motion behavior.
- human steps: switch Reduce Motion on in Settings (Accessibility, then Motion). On the Insights tab, scrub across each chart, then compare with Reduce Motion off. With it on, the callout appears without scale or fade and the selection marker does not spring. Switch Reduce Motion off again when done.

result: pass
notes: With Reduce Motion on, the chart callout jumps without animation (it disappears and reappears at the new position). Caveat from the owner: the same happens with Reduce Motion off, so no callout animation was visible in either setting and the gate is not demonstrated by a before and after difference.

Re-run (plan 11-14, simulator, 2026-11-16):

- re-run result: open
- re-run notes: Insights callout re-checked with Reduce Motion off and on; discriminating difference: no. The owner sees the callout look the same and appear and disappear abruptly, without animation, in both states, so the Reduce Motion gate on both charts is not demonstrated by a before and after difference. The original result above (pass, with the same caveat) is unchanged; this re-run does not add a pass.

### CHK-04

Reduce Motion on DPArcProgress (Home arc).

- source: `drinkpulse/DesignSystem/DPArcProgress.swift` line 18 has an animation that is not gated by Reduce Motion. Deferred review findings WR-01 and WR-02 in the todo `2026-11-13-triage-deferred-phase-09-review-findings.md` apply: the arc may not interpolate at all, so a missing animation can also come from that bug.
- automated: none.
- human steps: with Reduce Motion on, change the consumption value shown on Home (add a drink from the plus button, then save) and watch whether the arc moves with an animation. `pass` means no animation with Reduce Motion on. `fail` is a confirmed defect (owner D-09 brief, stays open). Note whether the arc animates with Reduce Motion off, so the comparison is clear.

result: open
notes: The arc refreshes when Save is tapped while the Add Drink sheet still covers it, so the owner could not judge whether it animates, with Reduce Motion on or off.

Re-run (plan 11-14, simulator, 2026-11-16):

- re-run result: pass
- re-run notes: With Reduce Motion on the arc shows no animation (the Home arc is now gated through DPMotion). Owner caveat: the arc may have no animation at all, or it runs too fast to see. Open observation OBS-D below: with Reduce Motion off the arc shows no visible animation either.

### CHK-05

Reduce Motion on ConsumptionOverviewCard.

- source: `drinkpulse/Features/Dashboard/Components/ConsumptionOverviewCard.swift` line 110 has an animation (on the percentage bar) that is not gated by Reduce Motion.
- automated: none.
- human steps: same judgement as CHK-04 on the percentage bar of the overview card on Home: with Reduce Motion on, change the consumption value and watch whether the bar animates. `pass` means no animation with Reduce Motion on. `fail` is a confirmed defect.

result: fail
notes: The progress bar of the overview card on Home always animates, with Reduce Motion on and off; it never changes in a jump. Confirmed behavior; owner D-09 brief 11-DECISION-C014.md.

Re-run (plan 11-14, simulator, 2026-11-16):

- re-run result: pass
- re-run notes: With Reduce Motion on the overview bars jump to the new value without a sliding fill; with it off they animate (the gate in ConsumptionOverviewCard now goes through DPMotion).

### CHK-06

Reduce Motion on HistoryCalendarView.

- source: `drinkpulse/Features/History/Components/HistoryCalendarView.swift` line 61 has an animation keyed on the selected day that is not gated by Reduce Motion.
- automated: none.
- human steps: with Reduce Motion on, open the History tab, switch to the calendar, and tap different days. Watch whether the selection or the detail area animates. `pass` means no animation with Reduce Motion on. `fail` is a confirmed defect.

result: fail
notes: The detail area of the History calendar always animates slightly when a day changes, with Reduce Motion on and off; it never changes in a jump. Confirmed behavior; owner D-09 brief 11-DECISION-C015.md.

Re-run (plan 11-14, simulator, 2026-11-16):

- re-run result: pass
- re-run notes: With Reduce Motion on the History calendar detail area appears without animation; with it off it animates (the gate in HistoryCalendarView now goes through DPMotion).

### CHK-07

Dynamic Type through AX5.

- source: WINDOWS row 6 (guideline picker glass cards at AX5, B9-3).
- automated: audit AX5 variants (plan 11-03: Home, Insights, History, Settings, Add Drink, Onboarding) are inside the exploratory audit run, which is red (audit run: 16 methods red, 311 open findings). The text-size findings sit in groups A11Y-AUDIT-G01, G03, G04, G05 and G07 of the audit section in `11-EVIDENCE.md`. Also `HistoryDynamicTypeUITests` (1 test, passed in row G3: a History row grows and stays hittable at AX5). The audit covers the visible viewport of each screen only and does not cover the guideline picker.
- human steps: set the text size to the largest accessibility size with `xcrun simctl ui <clone> content_size accessibility-extra-extra-extra-large`, relaunch the app, and walk Home, Insights, History, Settings (including the guideline picker), the Add Drink sheet and onboarding. Look for clipped, truncated or overlapping text and for controls you cannot reach. Watch point: the Insights area chart has a fixed height and small axis labels. Reset the size afterwards with the reset command in Session setup.

result: fail
notes: At AX5 text is truncated, clipped or overlapping on Home, Insights, Add Drink steps 1 and 2, Settings Preferences and Onboarding; the guideline picker (onboarding and Settings) and History are fine. Human observation, not a confirmation of the audit groups. Details and audit cross-reference in owner D-09 brief 11-DECISION-C016.md.

### CHK-08

Light and dark appearance.

- source: WINDOWS row 4 (contrast over translucent glass, C14-7) and WINDOWS row 6 (guideline picker glass cards in light and dark).
- automated: audit dark variants (Home, Insights, History, Settings) are inside the exploratory audit run, which is red (audit run: 16 methods red, 311 open findings); contrast findings are in groups A11Y-AUDIT-G03, G04, G06 and G08. Also `SettingsUITests` appearance mode (passed in row G4). These do not prove that the screens look right.
- human steps: switch with `xcrun simctl ui <clone> appearance dark`, walk every tab and the Add Drink sheet, then switch back with `xcrun simctl ui <clone> appearance light` and look again. Look for unreadable text, wrong colors, and glass that loses legibility.

result: pass
notes:

### CHK-09

Increase Contrast.

- source: WINDOWS row 4 (C14-7: secondary text over translucent glass is unmeasured).
- automated: none. The audit runs at default contrast only.
- human steps: switch on with `xcrun simctl ui <clone> increase_contrast enabled`, in both appearances, and walk every tab. Look for text or controls that become harder to read. Reset afterwards with `xcrun simctl ui <clone> increase_contrast disabled`.

result: pass
notes:

### CHK-10

VoiceOver actions on a History row (optional).

- source: WINDOWS row 3 (C14-2: Duplicate and Delete as VoiceOver Actions on a History row; Delete presents the confirmation).
- automated: none.
- human steps: with VoiceOver on, focus a History row and check that Duplicate and Delete are offered as actions, and that Delete asks for confirmation. If CHK-00 is `open`, this is `open` with the reason "CHK-00".

result: open
notes: CHK-00: VoiceOver actions on a History row were not checked because the VoiceOver rotor is not reachable on the simulator.

## Open observation from the plan 11-14 re-run (OBS-D, not a checklist item)

Recorded 2026-11-16 from the owner's re-run on the simulator (plan 11-14). With Reduce Motion off, the overview bars and the other gated sites animate but the Home arc (`DPArcProgress`) shows no visible animation. The owner suspects an arc defect, because the bars animate and the arc does not, so its animation looks too fast or not to run. Cause not established: this is a hypothesis only. It may relate to the deferred review findings WR-01 and WR-02 named under CHK-04 (the arc may not interpolate at all). Plan 11-14 did not touch this and made no fix; it only gated the existing arc animation on Reduce Motion. Status: open, needs an owner decision or a later plan. It also means CHK-04 pass above is "no animation with Reduce Motion on", which is true by construction if the arc never animates.

## Observation to record, not to fix

For any new problem you notice that is not an item above: write what you saw in `notes:` of the closest item, and mark it `fail` or `open`. Do not fix it. Plan 11-07 turns a confirmed defect into an owner D-09 brief. Phase 11 makes no fix.
