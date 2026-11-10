# Phase 10 Device Re-test (Owner): INT-01 killed-app tap fix

Plan 10-14. This is the owner-only re-test of the killed-app notification tap fix from plan 10-13 (the notification delegate is now assigned synchronously in `drinkpulseApp.init()`). It covers requirement INT-01 (F6, D-14, D-17): at least three killed-app daily-reminder taps, one backgrounded tap, three detached cold-launch timings, and a cold weekly tap only if one is naturally delivered.

## Verification source

Automated tests, including the `UITestNotificationCenter` seam tests and the plan 10-13 assignment test (`NotificationDelegateAssignmentTests`), cannot prove system delivery timing on a killed app. This device re-test is the verification source for the INT-01 cold-tap fix. Three or more taps are a finite sample (residual risk R-03 in the Sign-off).

## Privacy rule (read first)

Results in this file hold **counts, PASS or FAIL values and millisecond timings only**. Never write personal values, identifiers (event, sample or device identifiers), unredacted logs or screenshots here, in a commit or in a chat reply. This file is committed to git, so a value that slips in cannot be cleanly retracted.

## Stop rule

If a destination is wrong or anything looks wrong with your data (events missing, a recovery or startup error screen, a wrong or missing notification destination), stop at that step and report only the category. Before stopping on a cold-tap miss, record whether the Console line `Notification tap received, kind: daily` was seen (present, absent or not observed): it tells Claude whether the delegate callback fired. Do **not** delete or reinstall the app. No fix is made in this plan: the finding goes to an owner decision brief first (D-06, Phase 08 D-09 brief gate).

## Hard rules

- Do not delete or reinstall the app. It holds the only copy of your data.
- Do not change the device date or time, not even to force a weekly notification.
- Do not log a real drink. After each tap, dismiss the sheet without saving.
- Never launch the app from Xcode for the tap and timing steps, and keep no debugger attached.

## Simulator dry run (done by Claude before this session)

The reading procedure was proven on the iOS 27 simulator first, so the owner is not the first to find a procedure bug. The procedure is the one plan 10-12 used (unified logging, `log show`; Apple Developer documentation "Viewing log messages"). The Xcode MCP DocumentationSearch tool was not available to this agent, so the Apple page was not re-fetched and the commands below were verified by running them.

Route record: build, install, launch and log read ran through the CLI fallback (`xcodebuild`, `xcrun simctl`), not Xcode MCP. Reason: Xcode MCP acts on the main workspace, not on the isolated worktree that holds this plan's changes, and the log read is the machine-checkable gate.

Commands (a worktree-local derived data path; `LOCAL_IOS_27_UDID` is the selected iOS 27 simulator, exported to the child shell as `P10_14_UDID`):

```bash
xcodebuild build -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -derivedDataPath build/p10-14
xcrun simctl install "$LOCAL_IOS_27_UDID" build/p10-14/Build/Products/Debug-iphonesimulator/drinkpulse.app
xcrun simctl launch --terminate-running-process "$LOCAL_IOS_27_UDID" com.haniewicz.drinkpulse -dp_onboarding_done YES
export P10_14_UDID="$LOCAL_IOS_27_UDID" && bash -c 'xcrun simctl spawn "$P10_14_UDID" log show --last 2m --info --predicate "subsystem == \"com.drinkpulse.app\""'
xcrun simctl uninstall "$LOCAL_IOS_27_UDID" com.haniewicz.drinkpulse
```

No `-dp_uitest` flag is passed, so the app uses its real container path. `ViewLoadLogger` is DEBUG only, so only a Debug build prints the Dashboard line.

All four lines appeared. Line shapes (milliseconds only; simulator values are for reference and not a device figure):

| Line (subsystem com.drinkpulse.app) | Category | Simulator value |
|---|---|---|
| `Notification delegate assigned in N ms` | startup | 9 ms |
| `Container load finished in N ms` | startup | 34 ms |
| `RecordDeduplicator.sweep finished in N ms` | startup | 2 ms |
| `View 'Dashboard' appeared in N ms` | performance | 808 ms |

Limit, stated plainly: the tap-kind line `Notification tap received, kind: daily` cannot be produced on a simulator without a real notification tap, so it is first proven on the device in Step 3. After the dry run the app was uninstalled from the simulator.

## Preflight

- [ ] The iPhone runs iOS 27 and is paired with this Mac, Developer Mode is on (Settings, Privacy and Security, Developer Mode). If it cannot run iOS 27 yet, stop and report that blocker.
- [ ] The plan 10-13 Debug build is installable over the existing install, without deleting the app: Xcode (select the iPhone, Run, then Stop) or `xcrun devicectl device install app --device <device name> <path to drinkpulse.app>`, as in 10-DEVICE-SESSION.md.
- [ ] Console.app is open with the iPhone selected, streaming started ("Start streaming"), Action, "Include Info Messages" on, and the search field set to `subsystem:com.drinkpulse.app`.
- [ ] No debugger is attached for any step (no stop button lit in Xcode, no `lldb` session). If unsure, quit Xcode after the install.
- [ ] You have re-read the Hard rules above.

## Step 1. Install over the existing install and launch once

1. Install the plan 10-13 Debug build over the existing install, without deleting the app.
2. Launch it once from the Home Screen.
3. Record the `Notification delegate assigned in N ms` value (milliseconds only).
4. PASS when it launches with no startup error screen and no recovery behavior.

## Step 2. Killed-app daily reminder taps (at least three)

Repeat the following for each tap, at least three times:

1. Settings, "Daily log reminder": turn it on (allow notifications if asked) and set the time two to three minutes ahead.
2. Force-quit the app from the app switcher.
3. Wait for the reminder to be delivered, then tap it.
4. Note the destination. The Add Drink sheet is correct. Anything else (for example the Dashboard) is a miss.
5. Dismiss the sheet without saving.

Record taps N, correct M. PASS only when N is at least 3 and M equals N. On a miss, stop at that step per the Stop rule.

## Step 3. Callback line in Console

For each cold tap in Step 2, record whether the line `Notification tap received, kind: daily` appeared in Console. Record lines seen n of n, or not observed.

This is evidence for diagnosing a failure, not an input to the PASS verdict. Assumption A-3 (device only): the live Console stream is assumed to show notice lines from a process the system launches from a notification tap. Plan 10-12 saw the timing lines live, but a tap-launched process was not tested. If the line does not appear, record not observed rather than guessing. Do not paste or save the log text.

## Step 4. Backgrounded daily reminder tap

1. Set the Daily log reminder time two to three minutes ahead.
2. Send the app to the background with the home gesture. Do not force-quit it.
3. Tap the delivered reminder.
4. PASS when the Add Drink sheet opens. Record taps 1, correct M. Dismiss the sheet without saving.

## Step 5. Weekly summary cold tap (only if deliverable)

Only if a weekly summary notification is naturally delivered while the app is killed during this session, tap it. Record the destination (Insights is correct) and whether the Console line shows `kind: weekly`. Otherwise record N/A with the note that routing is covered by automated tests only. Never change the device date or time to force a delivery.

## Step 6. Detached cold-launch timings

1. Console.app is streaming as set up in the Preflight.
2. On the iPhone, force-quit the app. Make sure no debugger is attached.
3. Launch the Debug build from the Home Screen icon.
4. Read the four lines: `Container load finished in N ms`, `RecordDeduplicator.sweep finished in N ms`, `View 'Dashboard' appeared in N ms` and `Notification delegate assigned in N ms`.
5. Repeat for three launches (force-quit between each). Record milliseconds only.
6. If the lines do not appear live in Console, record that and read the figures from the Xcode device console (Window, Devices and Simulators, select the iPhone, Open Console) as a labelled fallback.
7. Do not paste or save log text. Record numbers only.

## D-17 closure rule

You judge whether the Dashboard appeared value and the new delegate-assignment value are near. Near means the same order of magnitude as before: tens to a few hundred milliseconds rather than seconds. Earlier device figures (plan 10-12, detached launch) were 6 ms container load and 104 to 118 ms Dashboard appeared.

- **Near:** the change is kept. No startup change is made.
- **Not near:** an owner decision brief (10-DECISION-D17-startup.md, written by Claude) comes before any further startup change. No startup change is made in this plan.

The three older timing lines start inside the container-load task, after `init()` returns, so they cannot see the cost of the synchronous delegate call. Only the new delegate-assignment line shows that cost. Record your judgment on the D-17 verdict line in the Results section.

## Results

Fill one row per check with PASS, FAIL or N/A, the numbers and a short note. Counts, PASS or FAIL values and millisecond timings only. Overwrite the placeholder word on each of the two existing verdict lines below in place, and never add another verdict line.

| Check | Result | Numbers | Notes |
|---|---|---|---|
| Preflight: iOS 27, paired, Developer Mode | PASS | iOS 27 | Owner confirmed the iPhone runs iOS 27; installs and detached launches work. The Xcode debugger attach still hangs (tooling, tracked in open-questions). |
| Step 1: build installed over the existing install | PASS | 1 of 1 | Launch logs show an existing store kept (pre-existing store true); no startup error. |
| Step 2: killed-app daily reminder taps | PASS | 3 of 3 | Every tap opened the Add Drink sheet. |
| Step 3: callback line seen on cold taps | N/A (evidence only) | seen, 1 log excerpt shared | Owner shared one cold-tap log excerpt: the tap-kind line (kind daily) follows delegate assigned in 6 ms; that launch showed container load 12 ms and Dashboard appeared 141 ms. |
| Step 4: backgrounded-app daily reminder tap | PASS | 1 of 1 | Opened the Add Drink sheet. |
| Step 5: weekly summary cold tap | N/A | 0 delivered | No weekly summary was delivered naturally while the app was killed; clock not changed. |
| Step 6: launch 1 container, sweep, Dashboard appeared, delegate assigned | PASS | 5 ms, 5 ms, 117 ms, 6 ms | Detached Home Screen launch. |
| Step 6: launch 2 container, sweep, Dashboard appeared, delegate assigned | PASS | 6 ms, 4 ms, 103 ms, 7 ms | Detached Home Screen launch. |
| Step 6: launch 3 container, sweep, Dashboard appeared, delegate assigned | PASS | 7 ms, 4 ms, 110 ms, 5 ms | Detached Home Screen launch. A fourth launch measured 5 ms, 4 ms, 95 ms, 6 ms. |

D-17 verdict: near

Re-test verdict: PASS

The re-test verdict is PASS only when Step 2 has N at least 3 with M equal to N, Step 4 is 1 of 1, Step 5 is PASS or N/A and the D-17 verdict is near. Otherwise it is FAIL.

## Sign-off

Replace each placeholder with your sign-off. Counts, PASS or FAIL and milliseconds only.

### Residual risks

This risk cannot be removed by any number of taps. It has automated seam-level evidence, a named test gap and your sign-off. In the Owner cell, type the word that accepts the risk and its stated mitigation, or write an objection.

| Risk | Automated evidence | Named test gap | Device check | Owner |
|---|---|---|---|---|
| R-03 system delivery on a killed app depends on OS and device state at delivery, so three or more taps are a finite sample and not a proof for every condition (low memory, Focus modes, first launch after a restart). | `NotificationDelegateAssignmentTests` pins that the delegate is set before `init` returns; `NotificationActionHandlerTests` pin routing. | No automated test delivers a real notification response to a killed app. | Steps 2 to 4. | akceptuję |

Session completed on: 2026-11-10
