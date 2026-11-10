# Phase 10 Device Session (Owner)

Plan 10-12. This is the owner-only session that automation cannot cover: the current-store upgrade, the import round trip, real HealthKit, real notification taps and the debugger-detached cold-launch timing.

Covers: DATA-01 current-store proof (D-05, D-08), INT-02 device checks (D-18), INT-01 cold and warm tap on hardware (D-14, F6), the D-17 todo closure.

## Privacy rule (read first)

Results in this file hold **counts, PASS or FAIL values and millisecond timings only**. Never write personal values, identifiers (event, sample or device identifiers) or unredacted logs here, in a commit, in a chat reply or in a screenshot that enters the repository. Your original backup stays on your machine and is never uploaded. This file is committed to git, so a value that slips in cannot be cleanly retracted.

## Stop rule

If anything looks wrong with your data or the migration (events missing, a recovery or startup error screen, duplicates after import, a wrong or missing notification destination), stop at that step. Report only the category that failed. Do **not** delete or reinstall the app. No fix is made in this plan: the finding goes to an owner decision brief first (D-06, D-09). A model-shape fix would need a new SchemaV5 plus a new MigrationStage, which is one-way.

## Simulator dry run (done by Claude before this session)

The D-17 procedure was proven on the iOS 27 simulator first, so the log lines and the reading method are known to work (source: unified logging as documented for `log show` and Console, Apple Developer documentation "Viewing log messages"; the Xcode MCP DocumentationSearch tool was not available to this agent, so the Apple page was not re-fetched in this run and the commands below were verified by running them).

Route record: the build, install, launch and log read ran through the CLI fallback (`xcodebuild`, `xcrun simctl`), not Xcode MCP. Reason: Xcode MCP acts on the main workspace, not on the isolated worktree that holds this plan's changes, and the log read is the machine-checkable gate.

Commands (a dedicated cloned simulator, a worktree-local derived data path):

```bash
xcodebuild build -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM" -derivedDataPath build/p10-12
xcrun simctl install "$SIM" build/p10-12/Build/Products/Debug-iphonesimulator/drinkpulse.app
xcrun simctl launch --terminate-running-process "$SIM" com.haniewicz.drinkpulse -dp_onboarding_done YES
xcrun simctl spawn "$SIM" log show --last 2m --info --predicate 'subsystem == "com.drinkpulse.app"'
```

No `-dp_uitest` flag is passed, so the app uses its real container path (the UI-test flag switches to an in-memory seeded container and would skip the measured path). `ViewLoadLogger` is DEBUG only, so only a Debug build prints the Dashboard line.

Recorded line shapes (milliseconds only, values from the simulator run for reference, not a device figure):

| Line (subsystem com.drinkpulse.app) | Category | Simulator value |
|---|---|---|
| `Container load finished in N ms` | startup | 19 ms |
| `RecordDeduplicator.sweep finished in N ms` | startup | 7 ms |
| `View 'Dashboard' appeared in N ms` | performance | 466 ms |

The Dashboard figure is measured from the moment the container becomes ready to the first Dashboard appear, so it is the number to compare against the container-load figure. After the run the app was uninstalled from the simulator and the dedicated simulator was deleted.

## Preflight

- [ ] The iPhone runs iOS 27 and is paired with this Mac, Developer Mode is on (Settings, Privacy and Security, Developer Mode). If it cannot run iOS 27 yet, stop and report that blocker; the session is rescheduled (research Open Question 4).
- [ ] The Phase 10 Debug build is installable on it, with Xcode (select the iPhone, Run, then Stop) or `xcrun devicectl device install app --device <device name> <path to drinkpulse.app>`. Installing with Xcode Run and then pressing Stop is fine; for the timing step (Step 7) the app must later be launched from the Home Screen, never from Xcode.
- [ ] The previous build is installed and holds your real data. **Never delete the app** at any step, because that deletes the only copy of the data.
- [ ] You will keep the pre-upgrade backup local (for example in `~/Documents/dp-scrub/`) and **never upload it**, never place it inside the repository, never open it in a shared or synced editor.
- [ ] You know that no debugger may be attached for Step 7.
- [ ] Console.app is available on the Mac with the iPhone connected (cable or trusted network), for Steps 3 and 7.

## Step 1. Export a backup (safety net)

Do this on the **currently installed build, before the upgrade**.

1. Settings, Data, "Export all data". Save the JSON somewhere local (the existing pre-upgrade export from plan 10-03 is also acceptable if you have made no data changes since).
2. Record only: the number of events, the number of templates, and whether a profile exists.
3. PASS when the export succeeds and the three values are recorded.

## Step 2. Install the Phase 10 build over the existing install

1. Install the Phase 10 Debug build **over** the existing install, without deleting the app (Preflight options).
2. Launch it once from the Home Screen (the first launch runs the in-place store upgrade).
3. PASS when the app installs over the old one with no "delete and reinstall" step and launches.

## Step 3. Verify the data

1. Count events and templates in the app and note whether the profile is present. PASS when the counts equal the Step 1 counts.
2. Spot-check that the values look unchanged. Do **not** write any value down.
3. PASS when there is no startup error screen and no recovery behavior (no "restored", reset or empty-store state).
4. In Console.app (Step 7 explains the setup), with the iPhone selected, filter on `subsystem:com.drinkpulse.app` and relaunch the app. PASS when neither line below appears: `Store open failed — attempting non-destructive recovery` or `Store files moved to RecoveredStores snapshot`. Record only that they were absent or present, not the surrounding log text.

## Step 4. Import the Step 1 backup (round trip)

1. Settings, Data, "Import DrinkPulse backup", choose the Step 1 file (the file stays local).
2. Record whether the app reports success and the counts of events and templates afterwards.
3. PASS when the counts equal the Step 1 counts and no duplicates appeared (the import is a last-writer-wins no-op for already present records).

## Step 5. HealthKit (INT-02, D-18)

1. Settings, Apple Health. Record whether "Write to Apple Health" is **off by default** on a fresh state (if you had enabled it on the old build and it is on, record N/A with that note; do not change anything for this).
2. Turn it on. Record that the system permission prompt appears and that the opt-in completes after you allow Dietary Alcohol. If the app offers "Add your past drinks to Apple Health?", choose "Not now" so the sample count in Health stays attributable to the drinks you log below.
3. Log one new drink. In the Health app (Browse, Nutrition, Alcohol Consumption or Dietary Alcohol, Show All Data) record the number of samples from DrinkPulse for that drink: expected exactly one.
4. Edit that drink (change the volume). Record the number of samples again: expected still one (updated, not added).
5. Delete that drink. Record that the delete returns the UI immediately (not blocking) and the number of samples afterwards: expected none for that drink.
6. Confirm that `healthKitUUID` is never in an export: export once more, open the file locally and search it for the text `healthKitUUID`. Record only found or not found. PASS when not found.
7. PASS when: off by default, prompt and opt-in work, one sample after log, one after edit, none after delete, delete does not block, export has no `healthKitUUID`.

## Step 6. Notifications (INT-01, D-14, F6)

Cold-launch tap routing depends on the notification delegate being set in time (research F6), so the killed-app tap is repeated at least three times.

1. Settings, "Daily log reminder": turn it on (allow notifications if asked) and set the time a couple of minutes ahead.
2. **Killed app, tap 1.** Force-quit the app from the app switcher. When the reminder is delivered, tap it. Record the destination. Expected: the app opens on the Add Drink sheet.
3. **Killed app, taps 2 and 3 (and more if you like).** Set a new time a couple of minutes ahead each time, force-quit again, tap the delivered reminder. Record the destination for each. Any miss (app opens but not on Add Drink) is a finding: stop and report it (F6).
4. **Backgrounded app.** Set the time a couple of minutes ahead, put the app in the background (home gesture, do not force-quit), tap the delivered reminder. Record the destination. Expected: the app comes to the foreground on the Add Drink sheet.
5. Weekly summary: the weekly check-in tap routes to Insights and is covered by the unit and UI tests (D-14, D-15). If you happen to receive a natural weekly summary notification and tap it, record the destination and whether the copy names both compared periods; otherwise record N/A, weekly routing covered by automated tests.
6. Turn the daily reminder back to the setting you want to keep.
7. PASS when all three or more killed-app taps and the backgrounded tap land on the expected destination.

## Step 7. Detached cold-launch timing (D-17)

Why: an earlier measurement of about 3 to 5 seconds between container ready and Dashboard appear may come from the debugger-attached launch overhead and not from app code. This step measures it with no debugger attached.

1. Console.app on the Mac, select the iPhone in the sidebar, click "Start streaming". In the menu bar enable Action, "Include Info Messages". In the search field enter `subsystem:com.drinkpulse.app` (a plain search for `finished in` and `appeared in` also works).
2. On the iPhone, force-quit the app. Make sure Xcode is **not** running the app and no debugger is attached (no stop button lit in Xcode, no `lldb` session). If unsure, quit Xcode.
3. Launch the Debug build from the **Home Screen** icon. Read the three lines: `Container load finished in N ms`, `RecordDeduplicator.sweep finished in N ms`, `View 'Dashboard' appeared in N ms`.
4. Repeat for three launches (force-quit between each). Record the three values for each launch, in milliseconds only.
5. If the lines do not appear live in Console on the device (research assumption A3), record that, and read the figures from the Xcode device console (Window, Devices and Simulators, select the iPhone, Open Console) as a labeled fallback.
6. Do not paste or save the log text. Record numbers only.

## D-17 closure rule

You judge whether the "Dashboard appeared" value is near the "Container load" value. Near means roughly the same order of magnitude, tens to a few hundred milliseconds rather than seconds.

- **Near:** the todo is closed as "not an app-code bug". The shipped lazy-center and delegate fixes are kept. No startup change is made.
- **Not near:** an owner decision brief is written before any startup change (startup and lifecycle are a D-09 trigger). No startup change is planned in this plan.

Add the line `D-17 verdict: near` or `D-17 verdict: not near` in the Results section below.

## Results

Fill one row per check with PASS, FAIL or N/A, the numbers and a short note. Counts, PASS or FAIL values and millisecond timings only. No placeholder value may remain in this section when you are done.

| Check | Result | Numbers | Notes |
|---|---|---|---|
| Preflight: iOS 27, paired, Developer Mode | PASS | n/a | debugger attach hangs (LLDB RPC killed by Xcode); detached launch OK |
| Step 1: backup exported | PASS | events 214, templates 0, profile yes | pre-upgrade export kept outside the repo |
| Step 2: Phase 10 build installed over the existing install | PASS | n/a | installed from Xcode over existing app, launched detached from Home Screen |
| Step 3: counts equal Step 1, no startup error, no recovery | PASS | events 214, templates 0 | counts match Step 1 |
| Step 3: recovery log lines absent | PASS | 0 of 2 present | both recovery lines absent |
| Step 4: import round trip, counts unchanged, no duplicates | PASS | events 214, templates 0 | all existing records skipped, no duplicates |
| Step 5: HealthKit off by default | PASS | n/a | off by default |
| Step 5: prompt and opt-in | PASS | n/a | prompt and opt-in work, backfill declined |
| Step 5: samples after log, edit, delete | PASS | log 1, edit 1, delete 0 | as expected |
| Step 5: delete does not block the UI | PASS | n/a | UI returned immediately |
| Step 5: healthKitUUID absent from export | PASS | 0 occurrences | event uuid present, healthKitUUID absent |
| Step 6: killed-app daily reminder taps | FAIL | taps 1, correct 0 | app opened on Dashboard instead of the Add Drink sheet |
| Step 6: backgrounded-app daily reminder tap | PASS | taps 1, correct 1 | Add Drink sheet opened |
| Step 6: weekly summary (natural delivery) | N/A | n/a | no natural delivery observed; covered by automated tests |
| Step 7: launch 1 container, sweep, Dashboard appeared | PASS | 6 ms, 4 ms, 113 ms | detached, Home Screen launch |
| Step 7: launch 2 container, sweep, Dashboard appeared | PASS | 6 ms, 4 ms, 104 ms | detached, Home Screen launch |
| Step 7: launch 3 container, sweep, Dashboard appeared | PASS | 6 ms, 4 ms, 118 ms | detached, Home Screen launch |

D-17 verdict: near

## Sign-off

Replace each placeholder with your sign-off. Counts, PASS or FAIL and milliseconds only.

### Residual risks

These two risks cannot be reproduced on demand, so they cannot be proven on the device. Each has automated seam-level evidence, a named test gap and your acknowledgement as the verification source for the remaining gap. Replace the placeholder with `acknowledged` if you accept the risk and its stated mitigation, or write an objection.

| Risk | Automated evidence | Named test gap | Device check | Owner |
|---|---|---|---|---|
| R-01 interrupted migration (plan 10-01): a store migration completes in milliseconds and a process kill during it cannot be reproduced on demand. Accepted residual risk. | `MigrationChainV2V3Tests.corruptedStore_reportsRecoveryAndOpensFresh` proves an unreadable store takes the recovery path and a fresh usable store opens; the existing `StoreBootstrapTests` recovery tests pin that the store is moved aside and never deleted. | No automated test terminates the process during a real migration. | Step 3 checks the real store after the upgrade. | acknowledged |
| R-02 interrupted Health write (plan 10-07): a kill between the HealthKit save and the local cache write cannot be reproduced on demand. Accepted residual risk. | `HealthServiceOrderingTests.interruptedWrite_savedButNotCached_relinksOnNextBackfill_noDuplicate` shows a save that stored the sample but never reached the cache is relinked by `dp_event_uuid` on the next backfill without a second save, alongside the `HealthServiceTests` relink tests and the plan 10-07 double-write pin. | No automated test kills the process between the HealthKit save and the cache write. | Step 5 checks one sample per logged drink. | acknowledged |

Session completed on: 2026-11-09

## Follow-up (2026-11-10)

The Step 6 killed-app FAIL recorded in this session on 2026-11-09 is followed up by
[10-DEVICE-RETEST.md](./10-DEVICE-RETEST.md) (plan 10-14). Re-test verdict: PASS (killed-app
taps 3, correct 3; backgrounded tap 1, correct 1; D-17 verdict near).
