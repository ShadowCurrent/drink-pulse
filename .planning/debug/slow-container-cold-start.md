---
status: resolved
trigger: "Cold-start container loading is taking 5-6+ seconds on a fresh install, which appears to be long enough that iOS's own SpringBoard \"app taking too long to launch\" fallback behavior kicks in. Reported symptoms on a real physical device: (1) right after a fresh Xcode install, the launch screen shows a SMALL icon (Home-Screen-icon-sized, not our enlarged 252pt LaunchIcon) for ~3-4 seconds; (2) then for ~2 more seconds before the Dashboard/Onboarding appears, a MUCH BIGGER, visibly pixelated icon shows; (3) on a SUBSEQUENT launch (force-quit + relaunch, not a fresh install), there's a brief flash where both the small and the big icon appear overlaid simultaneously."
created: 2026-07-29T18:46:37Z
updated: 2026-07-30T07:05:00Z
---

## Current Focus
<!-- OVERWRITE on each update - always reflects NOW -->

CLOSED 2026-07-30 — owner explicitly ended the investigation ("close this issue, I
have no more desire to fight with this problem"). Filenames de-suffixed
(`LaunchIcon-final@Nx.png` -> `LaunchIcon@Nx.png`, commit `309b09e`), five untracked
`.xcappdata` diagnostic dumps removed from the repo root. Final shipped state: 60pt
(120px@2x/180px@3x), matching locked spec D-03. See round 18/19 below for the
technical detail this closure rests on.

ROUND 18/19 — SIZE-INVARIANCE ON REAL DEVICE, UNEXPLAINED, ACCEPTED PER USER DECISION.

After round 17 restored LaunchIcon at 60pt (a2b0e68), user requested 2x enlargement
(120pt, 240px@2x/360px@3x, commit dabfe1a) — real-device retest showed NO visible size
change. Reverted to 60pt with renamed files to rule out an asset-catalog same-filename
recompile-skip theory (commit 95ca17a) — still NO visible size change, even after (a)
full app delete + fresh install, (b) full device power-off/on reboot. At every layer
this environment can inspect, the two opposite-direction edits are genuinely different:
source PNG pixel dimensions differ, and `assetutil --info` against a stat-verified-fresh
compiled Assets.car confirmed the CORRECT rendition shipped each time (180x180@3x after
the revert, matching 60pt exactly). Round 15's Simulator measurement (post-morph,
LaunchIcon renders at its exact intrinsic point size) could not be reproduced as an
explanation here, because both edits SHOULD have produced a measurably different
intrinsic size and did not, on real hardware, after eliminating every install/cache
variable available from this environment.

This is an honest open discrepancy, not a confidently-diagnosed root cause — unlike
rounds 12-17, no direct measurement was possible on the actual device (no physical
device attached to this environment). Given (a) app-side config/asset/build is proven
correct at every inspectable layer, (b) every install/cache-staleness explanation this
session can test has been ruled out, and (c) the user independently requested "just use
one size and forget zooming" before this symptom was even reported — the pragmatic
close-out is to accept the current 60pt state (matches locked spec D-03, matches user's
own simplification request) rather than spend further rounds chasing a device-only
symptom this environment cannot directly observe or reproduce.

---

ROUND 17 — ROUND 15's ROOT CAUSE WAS EMPIRICALLY REFUTED ON REAL-DEVICE RETEST.
Round 16 applied option (C) (remove the icon entirely) based on round 15's claim that
iOS's SpringBoard automatically zoom/morphs the real AppIcon over the launch screen,
making a configured LaunchIcon redundant. Real-device retest after round 16 shipped:
user reports a PLAIN BLANK WHITE SCREEN with NO icon animation at all during launch —
i.e. removing UIImageName did not reveal any OS-level icon animation, it just removed
the only icon that was ever there. This is a direct empirical refutation of round 15's
central causal claim (see Eliminated below) — round 15's Simulator measurement (that
UIImageName renders at exact intrinsic point size) was itself sound, but the INFERENCE
drawn from it (that the reported small-icon phase must therefore be an OS animation,
not our asset) was wrong and was never actually verified on real hardware before
option C was applied.

Orchestrator applied a direct fix (round 17) rather than dispatching another
investigator agent, given the pattern of confidently-wrong conclusions across rounds
9-16 despite thorough-looking verification at each step: restored `UIImageName` +
`LaunchIcon.imageset`, downscaled to the ORIGINAL LOCKED SPEC size (60pt / D-03
"Home Screen-icon-sized") rather than round 8-9's unapproved 252pt escalation — this
simultaneously restores a visible icon AND fixes the pixelation complaint, since the
source's ~120px of real detail is much closer to native resolution at 120-180px than
it was at 756px (6.3x upscale). Deliberately did NOT restore the round-9 `.loading`
overlay (the separate Phase-3-adjacent "blank gap" deviation) — that stays out of
scope for this recovery fix pending its own explicit decision. See Evidence and
Resolution for verification detail.

round_16_fix_plan:
  1: "drinkpulse/Info.plist — remove UIImageName=LaunchIcon from the UILaunchScreen dict, keep UIColorName=LaunchBackground. [status: DONE — built dict verified = {UIColorName: LaunchBackground} on a fresh build]"
  2: "drinkpulse/drinkpulseApp.swift — remove the Image(\"LaunchIcon\") overlay from the .loading case entirely; revert to a bare Color(.systemBackground).ignoresSafeArea() and restore the original D-11 comment (accurate again now). This SUPERSEDES the round-15 intrinsic-sizing edit and its now-obsolete measurement comment — final file must be coherent, not layered stale comments. [status: DONE — round-15 comment removed with the Image; file is 198 lines, no stale commentary]"
  3: "LaunchIcon.imageset — confirmed ORPHANED after steps 1+2: `git grep LaunchIcon` outside .planning returns only Info.plist:41 and drinkpulseApp.swift (the two references being removed) plus the imageset's own Contents.json. No other code path, test, or asset references it. => git rm the whole imageset. [status: DONE — git rm'd; post-change grep returns ZERO hits; built Assets.car no longer contains a LaunchIcon rendition]"
  4: "Fresh clean build (zero warnings) + INFOPLIST_KEY_UILaunchScreen_Generation still absent + full test suite (drinkpulseTests + drinkpulseUITests incl. LaunchHandoffUITests/StartupErrorUITests). TRAP: build/ products can be STALE and falsely report an empty UILaunchScreen / missing LaunchIcon — always `stat` artifacts against sources before drawing any conclusion (see Evidence 22:14). [status: DONE — `rm -rf build` first, artifacts stat-verified newer than sources; BUILD SUCCEEDED zero source warnings; grep -c Generation = 0; TEST SUCCEEDED 649/649, 0 failed, 0 skipped; no file >300 lines]"
  5: "Update this file's Resolution (fix/verification/files_changed) — root_cause already final. [status: DONE]"
  6: "Append a closing deviation entry (14) to 04-01-SUMMARY.md attributing the Task 3 saga to SpringBoard's own icon-launch animation, not our LaunchIcon. [status: DONE — Deviation 14 added; frontmatter patterns/coverage/key-files corrected; two refuted patterns marked SUPERSEDED]"
  7: "Return checkpoint:human-verify for one final real-device cold launch, light + dark. [status: DONE — returned; awaiting the user's real-device confirmation before this session may be archived to resolved/]"

open_product_question_for_the_user: ".planning/REQUIREMENTS.md LAUNCH-01 still reads 'a branded static launch screen (app icon + matching background color, no text, no spinner)'. The app no longer supplies the icon — iOS's own AppIcon launch animation does. NOT edited unilaterally (amending a requirement's definition of done is a product call). LAUNCH-01 remains unchecked/Pending, so nothing is falsely claimed."

test_impact_assessment: "NO UI test asserts on the presence of a launch icon. LaunchHandoffUITests' own doc comment states explicitly that neither of its tests asserts anything about the launch screen (XCUITest attaches only after the pre-process launch screen has handed off); both assert only on the first LIVE frame (Home tab / Get Started). StartupErrorUITests drives the .failed state, which this change does not touch. => no test assertion needs updating; the suites are pure regression proof."

superseded_hypothesis: "ROUND 15 RESULT — BOTH OPEN QUESTIONS ANSWERED BY DIRECT MEASUREMENT; investigation is COMPLETE. Q1: the pre-process `UILaunchScreen` compositor draws `UIImageName` CENTRED AT THE IMAGE'S EXACT INTRINSIC POINT SIZE — measured at 756x756 px = 252.0 pt on an iPhone 17 Pro Simulator @3x by holding the process with `simctl launch --wait-for-debugger` and measuring the screenshot bbox. It does NOT aspect-fit, does NOT shrink to a safe-area container, and does NOT resolve a different scale bucket. Therefore the small phase-1 icon is NOT our LaunchIcon: it is the iOS 26 SpringBoard app-launch ZOOM/MORPH of the real Icon Composer AppIcon, caught in flight in an earlier capture from the same run as a teal full-width rounded rect over the Home Screen. Rounds 2-13 were editing the wrong asset. Q2: the pixelation is real and is an under-resolved asset, not a scale-selection bug — the artwork was extracted from the 120x120 px compiled `AppIcon60x60@2x.png` (04-01-SUMMARY.md line 43) and is displayed at 756 px (~6.3x), with a 280 px native-pixel crop showing the SVG's hard-edged 40-unit pulse stroke smeared over ~8 px. The two causes are AND-gated: the size jump makes the duplicate icon obvious, the low resolution makes the big one look broken. REMAINING WORK IS A PRODUCT DECISION, NOT A DEBUGGING QUESTION — see checkpoint. (Superseded prior hypothesis retained below for history.) TIMING sub-question: CONFIRMED CLOSED (see Evidence 2026-07-29T21:10 — real device measured 9ms, matches Simulator 8-29ms; 5-6s duration is Xcode-Debug-install overhead, external/unfixable, no code change needed). ICON-VISUAL sub-question: REOPENED — the "small icon in phase 1 is an OS-level SpringBoard fallback UI unrelated to our code" theory is REFUTED by direct user correction (see Eliminated below): BOTH the small pre-process LaunchIcon and the large pixelated `.loading`-overlay icon are 100% app-controlled assets added during this same v1.3 phase-04 work, neither is a pre-existing/system icon. This is the SAME size-mismatch bug from `.planning/phases/04-branded-static-launch-screen/04-01-SUMMARY.md` rounds 9-11, confirmed STILL UNRESOLVED after round 11's "remove 1x bucket" fix. A NEW, previously-unreported symptom is also now in scope: a double-icon-overlay flash specifically on WARM relaunch (force-quit + relaunch, not fresh install) — not yet investigated at all.
test: To be determined this round — needs a from-first-principles differential investigation of (a) why the pre-process `UILaunchScreen` LaunchIcon renders smaller than intended/expected, (b) why the SwiftUI `.loading` overlay renders bigger AND pixelated despite round 10's 2x/3x asset fix, (c) why a warm relaunch (not fresh install) shows both icons flashing simultaneously — a scenario not covered by any prior round's investigation.
expecting: A concrete, evidence-based explanation for at least one of (a)/(b)/(c) that goes beyond speculation — ideally identifying exactly which of the two icon rendering paths (pre-process compositor vs. SwiftUI overlay) is misbehaving and why, using techniques not yet tried in 13 prior rounds (e.g. actual device console/log capture during the transition, examining if the `.loading` overlay is somehow mounting during the PRE-PROCESS phase too, or a timing-based double-render race between old cached launch-image snapshot and new content).
next_action: "ROUND 15 COMPLETE — investigation is CLOSED, awaiting ONE product decision from the user (see checkpoint in the round-15 report). Both open questions were answered by direct measurement, and the design-neutral part of the fix is applied and verified (BUILD SUCCEEDED zero source warnings; 649/649 tests pass; no file over 300 lines). The ONLY remaining work is the user choosing how to resolve the app-icon duplication + icon size, which is a product decision made under a now-refuted premise. DO NOT ship another speculative asset edit before that answer. When the answer arrives: option (A) revert the icon to the contract's 60 pt (fixes both causes at once, needs no new asset — the existing 756 px file downsamples cleanly); option (B) keep 252 pt but regenerate the artwork at true resolution, which REQUIRES a fresh high-fidelity export from Icon Composer because `actool` cannot compile a standalone `.icon` bundle and no >152 px raster of the icon exists anywhere in the repo or build tree; option (C) drop `UIImageName` from the `UILaunchScreen` dict and the icon from the `.loading` overlay, leaving the branded background (this is the Apple-guidance option and satisfies 04-CONTEXT.md D-01's zero-diff requirement exactly). (Superseded round-15 plan retained below for history.) ORIGINAL ROUND 15 PLAN: Scope narrowed to exactly two questions. Q1: what is the pre-process `UILaunchScreen` compositor's actual sizing rule for `UIImageName`, and is the phase-1 small icon even the LaunchIcon at all (STRONG NEW LEAD: `drinkpulse/AppIcon.icon/` is an iOS 26 Icon Composer bundle which drives the SpringBoard app-launch zoom/morph — the phase-1 icon may be the AppIcon mid-morph, meaning 13 rounds edited the wrong asset). Discriminator: compare phase-1 icon artwork against AppIcon.icon SVG sources vs LaunchIcon.png. Q2: quantify the true information content of the shipped LaunchIcon PNGs (downscale->upscale->diff, and compare against a fresh render from the 1024x1024 vector source) to confirm/refute that they are upscaled from a low-res raster and therefore look pixelated even at a 1:1 render. Both answerable without a physical device (Simulator + assetutil + sips)."
bug_class: null — reset for reassessment; timing half resolved as environment-class, icon-visual half reopened and not yet classified.
reasoning_checkpoint:
  hypothesis: "The reported 5-6s cold-start duration is not caused by this repo's container/dependency-loading code (loadContainerIfNeeded -> StoreBootstrap.makeContainer); it is dominated by (a) Xcode-Debug-install-specific device overhead (AMFI/dyld, environment category) and (b) the already-tracked early-boot UILaunchScreen compositor behavior (config/platform category) documented in 04-01-SUMMARY.md Deviations 6-13."
  confirming_evidence:
    - "Direct os.Logger measurement: fresh-install container load = 29 ms, warm relaunch = 8 ms (Simulator) — not multi-second."
    - "Full code review of every cold-launch-reachable path (Schema build, HealthService/HKHealthStore init, NotificationActionHandler, UITestSeed) found no blocking work; every requestAuthorization() call site is gated behind explicit user actions, unreachable during cold launch."
    - "04-01-SUMMARY.md's own 13-round investigation (Deviations 6, 8, 9) already positively ruled out legacy storyboard overrides, SDK-conditional build settings, extra targets/schemes, and confirmed device-SDK vs simulator-SDK build products are byte-structurally identical — narrowing the icon-visual component to the early-boot compositor layer specifically, a conclusion this session reuses rather than re-derives."
  falsification_test: "If a physical-device log capture (same instrumentation, Console.app or device log stream) shows loadContainerIfNeeded() itself taking >1s on real hardware, that would refute this conclusion and reopen the in-repo investigation — this is the concrete, falsifiable next check, requested at the human checkpoint below."
  fix_rationale: "No code defect exists to 'fix' — the appropriate action is (1) instrumentation so the human can obtain the one measurement this environment cannot take (real device), and (2) avoiding a 14th round of speculative LaunchIcon asset edits duplicating the already-exhausted phase-04 investigation without new evidence."
  blind_spots: "No physical device attached to this environment — the actual reported symptom (physical-device Xcode-install cold launch) was never directly measured, only its Simulator analogue (which structurally cannot reproduce AMFI/dyld-cache-warming overhead). This conclusion is evidence-converging, not a hardware-confirmed proof."
  candidate_causes:
    - "code: in-repo container/dependency-loading (loadContainerIfNeeded/StoreBootstrap) — tested directly, REFUTED (8-29ms measured)"
    - "environment: Xcode Debug-build first-launch-after-install overhead (AMFI code-signature validation, attached-debugger symbol loading) — not reproducible/testable from this environment, consistent with known Apple-platform behavior"
    - "config/platform: early-boot UILaunchScreen compositor snapshot-caching / scale-bucket resolution — independently documented across 13 prior rounds in the same repo (04-01-SUMMARY.md), already established there as unconfirmable further without physical hardware"
  and_gate: "No — this is not a single failure requiring >1 simultaneous condition. It is two independent symptom clusters (total duration vs. visual icon-size/flash mismatch) with two separate, non-overlapping external explanations; they co-occur in the same user report but do not depend on each other."
tdd_checkpoint: null

## Symptoms
<!-- Written during gathering, then immutable -->

expected: App reaches its first live frame (Dashboard or Onboarding) quickly after a cold launch — a brief `.loading` transition, not a multi-second one indistinguishable from a hang. No iOS system-level "still launching" fallback UI should ever be visible for a well-behaved app.
actual: On a fresh install via Xcode onto a real physical device: (1) ~3-4 seconds showing a small, Home-Screen-icon-sized icon (not our enlarged 252pt LaunchIcon — possibly iOS's own slow-launch fallback UI, not app-controlled at all); (2) ~2 more seconds showing a much bigger, visibly pixelated (upscaled-looking) icon before Dashboard/Onboarding finally appears; (3) on a subsequent launch (force-quit + relaunch, NOT a fresh install), a brief flash shows both the small and the big icon overlapping simultaneously. Total time from tap-to-launch to usable Dashboard: roughly 5-6+ seconds on the slow/fresh-install path.
errors: None reported — no crash, no visible error UI. Purely a timing + visual-compositing symptom cluster.
reproduction: Fresh install of the app via Xcode onto a real physical iOS device, then cold-launch by tapping the Home Screen icon (this is described as "when the app loads the longest" — implying subsequent non-fresh launches may be faster, not yet confirmed/quantified). Separately: force-quit (App Switcher swipe-away) and relaunch to reproduce the double-icon flash.
started: Surfaced 2026-07-29 during phase 04 (branded-static-launch-screen) plan 04-01 Task 3 real-device checkpoint verification (round 11-12 of that checkpoint — see .planning/phases/04-branded-static-launch-screen/04-01-SUMMARY.md for the full prior investigation trail, especially Deviations 11-13 which added a `.loading`-state icon overlay). The underlying async container-loading mechanism itself was implemented earlier in Phase 3 (STARTUP-02/03, completed 2026-07-27, docs/DEVLOG.md). Not yet established whether the 5-6s load time is a NEW regression or pre-existing behavior that was simply invisible before phase 04 (previously both the auto-generated blank launch screen AND the blank `.loading` state looked identical, masking any visible seam or duration).

## Eliminated
<!-- APPEND only - prevents re-investigating after /clear -->

- hypothesis: "The in-repo async container-load path (`loadContainerIfNeeded()` -> `StoreBootstrap.makeContainer` -> `ModelContainer(for:migrationPlan:configurations:)`) is itself the source of the reported multi-second delay (e.g. via the 3-stage V1->V2->V3->V4 migration plan running unnecessarily, CloudKit-adjacent schema validation, or some other in-repo blocking work)."
  evidence: "Direct os.Logger-timed measurement on iPhone 17 Pro Simulator: fresh install (no pre-existing store) container load = 29 ms; warm relaunch (pre-existing store) = 8 ms. Code review of every other init-time path (Schema build, HealthService()/HKHealthStore() construction, NotificationActionHandler, UITestSeed.resetTransientDefaults()) found no blocking work, and every HealthKit/notification `requestAuthorization()` call site is gated behind explicit user-triggered actions (Settings sections, OnboardingView's HealthStep) — none fire during cold launch. `loadContainerIfNeeded()` is also confirmed to fire exactly once per launch (single start/finish log pair each time), ruling out a double-invocation explanation for the reported double-icon flash."
  timestamp: 2026-07-29T21:00:00Z

## Eliminated
<!-- APPEND only - prevents re-investigating after /clear -->

- hypothesis: "The small, Home-Screen-icon-sized icon shown during phase 1 of a fresh-install cold launch is iOS's own SpringBoard-generated 'app taking too long to launch' fallback UI, independent of and unrelated to this repo's own LaunchIcon asset."
  evidence: "Direct user correction: BOTH the small phase-1 icon and the large pixelated phase-2 icon (`.loading` overlay) only started appearing after this same v1.3 phase-04 work was added — the small icon was introduced first (rounds 2-8's LaunchIcon asset work), then the large icon was added afterward (round 9's `.loading`-overlay commit c2e11a1). Neither icon existed before this milestone's changes. This directly refutes any OS-level/system-fallback explanation for the small icon — it is our own `LaunchIcon` asset, rendering smaller than the `.loading` overlay's icon, which is the SAME pre-process-vs-SwiftUI size mismatch already flagged unresolved in 04-01-SUMMARY.md rounds 9-11."
  timestamp: 2026-07-29T21:15:00Z

## Eliminated
<!-- APPEND only - prevents re-investigating after /clear -->

- hypothesis: "iOS's SpringBoard automatically zoom/morphs the real AppIcon (from `drinkpulse/AppIcon.icon`, the Icon Composer bundle) over the launch screen during any cold launch, independent of and without needing a configured `UIImageName` — so removing our LaunchIcon asset entirely (option C) would still show a system-provided icon animation, just not a duplicate/pixelated one."
  evidence: "Real-device retest after round 16 removed UIImageName: user reports a plain blank white background with NO icon or animation visible at any point during launch — not a smaller/cleaner icon, no icon at all. If SpringBoard were genuinely auto-animating the real AppIcon independent of our config, removing our asset could not have produced a blank screen. Round 15's actual measurement (UIImageName renders at exact intrinsic point size, confirmed via `simctl launch --wait-for-debugger` + pixel-measured screenshot) was sound and is NOT eliminated — only the further inference built on top of it (that the observed small-icon phase must therefore be OS-level, not app-level) is wrong."
  timestamp: 2026-07-30T07:15:00Z

## Evidence
<!-- APPEND only - facts discovered during investigation -->

- timestamp: 2026-07-30T11:20:00Z
  checked: "Round 18: user requested 2x enlargement of the round-17 60pt LaunchIcon (120pt, 240px@2x/360px@3x, regenerated via the established pure-Python box-filter downsample, commit dabfe1a). Real-device retest (fresh install + force-quit cold launch, both appearances)."
  found: "No visible size change reported on device, despite the source PNGs genuinely differing (120px/180px vs 240px/360px, confirmed via `file`)."
  implication: "First occurrence of a content-only edit not reaching perceived device output despite passing every prior verification gate (clean build, test suite green)."

- timestamp: 2026-07-30T11:35:00Z
  checked: "Round 19: user asked to drop the zoom attempt and lock a single size. Reverted to the round-17 60pt asset, this time RENAMING the files (LaunchIcon@2x/3x.png -> LaunchIcon-final@2x/3x.png, updating Contents.json) specifically to rule out an Xcode asset-catalog same-filename recompile-skip as the explanation for round 18's null result. Verified via `assetutil --info` against a stat-verified fresh compiled Assets.car: shipped rendition = 180x180px @3x (= 60pt), matching source exactly. Committed 95ca17a. Real-device retest: still no visible size change from the (bigger) prior state."
  found: "Rename did not change the outcome. User then confirmed, via targeted follow-up questions: (a) the icon in question appears AFTER the white/black background fills the screen (i.e. this should be the app's own LaunchIcon rendering path, not the pre-morph transient), (b) full app delete + fresh Xcode install was performed (not an incremental Run), (c) a full device power-off/on reboot was performed after that — and the size still did not visibly change."
  implication: "Rules out asset-catalog same-filename caching, incremental-install staleness, and iOS's own launch-screen snapshot cache (which a reboot would clear) as explanations. No further app-side lever is untested. The discrepancy between this real-device result and round 15's Simulator-measured 1:1 intrinsic-size rendering is unresolved and cannot be root-caused further without a physical device attached to this environment (see blind_spots)."

- timestamp: 2026-07-30T07:00:00Z
  checked: "Real-device retest of round 16's fix (icon removed entirely, background-only launch screen)."
  found: "User: plain white screen, no icon at all during startup."
  implication: "Round 15/16's conclusion is empirically wrong. Reopened; see Eliminated entry above."

- timestamp: 2026-07-30T07:20:00Z
  checked: "Attempted to downscale the last known-good alpha-masked LaunchIcon source (git show c5592cd, 756px, corners alpha=0 confirmed via full manual PNG decode) to 60pt (120px@2x, 180px@3x) using `sips -z 120 120` / `sips -z 180 180`."
  found: "`sips -z` resize SILENTLY ZEROED THE ENTIRE ALPHA CHANNEL — not just corners, the CENTER pixel (which should be fully opaque icon content) also came back alpha=0 after resize. Confirmed via full manual PNG decode (not sips-crop, which is itself unreliable — see below), on both the 120px and 180px outputs."
  implication: "`sips -z`/`-c` cannot be trusted for RGBA PNG transforms in this environment — this is the SECOND distinct sips failure mode found in this saga (the first: `sips -c 1 1` crop-to-sample also composites the cropped pixel against an opaque background rather than preserving true alpha, producing false 'corner is opaque' readings in earlier rounds' pixel probes — some of those may have been sips-crop artifacts rather than real asset defects). Switched to a pure-Python box-filter downsample (stdlib `struct`+`zlib` only, manual PNG scanline defilter for all 5 filter types + re-encode) instead, which correctly preserved alpha=0 corners and alpha=255 center at both target sizes."
  timestamp: 2026-07-30T07:20:00Z

- timestamp: 2026-07-30T07:24:00Z
  checked: "Fresh clean build (`rm -rf build` then `xcodebuild clean build`), compiled Info.plist read from the CORRECT DerivedData path (a naive `find ... | head -1` first grabbed a stale second DerivedData folder from an earlier hash and showed an empty/broken UILaunchScreen dict — same stale-build-product trap round 15 already flagged, reproduced a second time here; resolved by targeting the exact hash from the build log)."
  found: "Compiled Info.plist: `UILaunchScreen = {UIColorName: LaunchBackground, UIImageName: LaunchIcon}` — correct. `INFOPLIST_KEY_UILaunchScreen_Generation` count = 0. `LaunchHandoffUITests` + `StartupErrorUITests`: 4/4 pass, 0 failures."
  implication: "Round 17's restoration fix builds and tests clean. Real-device confirmation still pending from user."

## Resolution
<!-- superseded round-15/16 content retained below for history; round-17 status supersedes it -->

status_note: "Round 15/16's Resolution below is SUPERSEDED — its root_cause/fix were the ones just refuted. Not rewriting those fields destructively so the reasoning trail stays intact; round 17's actual current fix is: `drinkpulse/Info.plist` UIImageName=LaunchIcon restored, `drinkpulse/Assets.xcassets/LaunchIcon.imageset` restored at 60pt (120px@2x/180px@3x, downscaled from the c5592cd 756px source via a pure-Python box filter, alpha verified), committed as a2b0e68. The round-9 `.loading`-overlay deviation stays removed (not restored) — out of scope for this fix, tracked separately. AWAITING final human real-device confirmation before this session moves to resolved/."

## Resolution (round 15/16, superseded)

- timestamp: 2026-07-29T21:40:00Z
  checked: "STATIC ARITHMETIC (round 14, cheapest-first per investigation guidance): read `LaunchIcon.imageset/Contents.json` AND the true pixel dimensions of every PNG via `sips -g pixelWidth -g pixelHeight`, then computed the intrinsic point size each pipeline derives."
  found: "Declared buckets and actual pixel dimensions AGREE exactly. `LaunchIcon@2x.png` = 504x504px declared `2x` -> 504/2 = 252pt. `LaunchIcon@3x.png` = 756x756px declared `3x` -> 756/3 = 252pt. Both buckets yield an identical 252x252pt intrinsic size. No `1x` bucket, no extra/dark/appearance entries — `images` array is exactly 2 entries, universal idiom."
  implication: "REFUTES the entire scale-bucket-mismatch family of hypotheses (rounds 10-13's whole theory of the case). The imageset's intrinsic point size is unambiguously 252pt on every supported device. A declared-scale-vs-actual-pixels mismatch is NOT why the pre-process icon renders smaller — the arithmetic is clean. Whatever makes the launch-screen icon render small must be something the compositor does to a correctly-sized image, not a wrong intrinsic size. Sub-question (a) must be re-aimed at the compositor's own layout/frame/contentMode rules."

- timestamp: 2026-07-29T21:42:00Z
  checked: "Read both rendering pipelines' actual source: `drinkpulse/drinkpulseApp.swift` `.loading` case (lines 99-106) and `drinkpulse/Info.plist`'s `UILaunchScreen` dict (lines 36-42)."
  found: "SwiftUI path: `ZStack { Color(.systemBackground).ignoresSafeArea(); Image(\"LaunchIcon\").resizable().scaledToFit().frame(width: 252, height: 252) }` — an EXPLICIT 252pt frame, and the background IS opaque and full-bleed. `UILaunchScreen` dict contains ONLY `UIColorName: LaunchBackground` and `UIImageName: LaunchIcon` — notably it does NOT set `UIImageRespectsSafeAreaInsets`, so that key takes its default."
  implication: "(1) The SwiftUI side is pinned to 252pt by an explicit frame — it cannot be the variable. Therefore the SIZE DIFFERENCE is entirely attributable to the pre-process compositor's own sizing rule for `UIImageName`. (2) For sub-question (c): the `.loading` overlay's background is opaque + full-bleed, so a transparent-overlay explanation for the double-icon flash is REFUTED — the overlay cannot be letting the launch screen show through. The double-icon must instead come from iOS's cross-dissolve between the launch screen and the app's first frame, which only becomes VISIBLE as two distinct icons because the two icons are different sizes. That makes (c) a symptom of (a), not an independent bug."

- timestamp: 2026-07-29T21:10:00Z
  checked: "User captured the real physical-device Console.app log for subsystem com.drinkpulse.app, category startup, per the checkpoint request."
  found: "Container load finished in 9 ms — matches the Simulator measurement (8-29ms) closely, not multi-second."
  implication: "TIMING sub-question CONFIRMED CLOSED on real hardware, not just Simulator: the in-repo container-load code is not the source of the 5-6s delay on any platform. The 5-6s duration itself is external (most likely Xcode-Debug-install overhead, per the already-documented AMFI/dyld theory) and outside this repo's control — no further code investigation needed for the DURATION component specifically. The ICON-VISUAL component is separately reopened (see Eliminated above) and remains the open question."

- timestamp: 2026-07-29T20:50:00Z
  checked: "drinkpulse/drinkpulseApp.swift (full file), drinkpulse/Domain/Persistence/StoreBootstrap.swift, drinkpulse/Domain/Persistence/MigrationPlan.swift, drinkpulse/Services/HealthService.swift, drinkpulse/Services/HealthKitAdapter.swift, drinkpulse/Services/NotificationActionHandler.swift, drinkpulse/UITestSeed.swift"
  found: "No blocking/synchronous work anywhere on the cold-launch path before `.loading`'s first frame or during `loadContainerIfNeeded()`. Migration stages (v1->v2, v2->v3 custom; v3->v4 lightweight) only execute `didMigrate` fetch/save work when an existing store at an older version is opened — a genuinely fresh install has no store file, so SwiftData creates the container directly at the latest schema with zero migration-stage execution. `requestAuthorization()` call sites (HealthKitAdapter, WeeklySummaryService, ReminderService) are only reachable from Settings sections and OnboardingView's HealthStep — never from `drinkpulseApp.init()` or `loadContainerIfNeeded()`."
  implication: "Rules out SwiftData migration overhead, CloudKit config, and HealthKit/notification authorization prompts as candidates for the reported 5-6s delay — none of them execute during cold launch in production."

- timestamp: 2026-07-29T20:51:00Z
  checked: ".planning/phases/04-branded-static-launch-screen/04-01-SUMMARY.md (full file, 441 lines, Deviations 1-13)"
  found: "This exact symptom cluster (small early icon vs. larger/pixelated `.loading`-state icon, size mismatch between the two rendering paths) is the SAME issue already under active, exhaustive investigation in the Phase 4 plan's own Task 3 checkpoint — 13 rounds across `LaunchIcon.imageset` since round 2 (commit 072c811 through round 13's c5592cd). Round 6 positively ruled out legacy storyboard override, SDK-conditional build settings, extra targets/schemes, and confirmed a genuine `iphoneos`-SDK build product is byte-structurally identical to the simulator build. Round 9 (Dev 11 / commit c2e11a1) already established that before this phase's own branded-launch-screen work, the pre-process launch screen and the `.loading` state were both blank/pixel-identical, so any seam or duration was previously invisible — meaning some version of this hand-off gap likely pre-dates this debug session and was simply unobservable until the branding work made it visible. Round 13 (current state, commit c5592cd) left the investigation explicitly flagged as an unconfirmed working hypothesis (\"early-boot UILaunchScreen compositor has non-standard, quirky trait/scale resolution\"), blocked on human real-device re-verification, with the explicit caveat that this class of behavior \"cannot be fully verified without real hardware\" from this environment."
  implication: "The icon-size/pixelation/double-icon-flash component of this debug session's symptoms is not a new defect to re-investigate from scratch — it is the identical, already-tracked open item in the phase 04 plan's Task 3 checkpoint. Re-running another round of speculative asset edits here would duplicate that saga rather than add new evidence, and this environment has the identical no-physical-device limitation that already blocked rounds 6-13."

- timestamp: 2026-07-29T20:54:22Z
  checked: "Added os.Logger timing (ContinuousClock start/finish around `StoreBootstrap.makeContainer`/`UITestSeed.makeContainer`) to `loadContainerIfNeeded()`; built for iPhone 17 Pro Simulator (0 warnings); uninstalled + fresh-installed the app (`xcrun simctl uninstall` then `install`) to reproduce a genuinely empty-store cold start; captured `xcrun simctl spawn <udid> log stream --predicate 'subsystem == \"com.drinkpulse.app\"'` across both a fresh cold launch and a force-terminate + warm relaunch."
  found: "Fresh cold launch (no pre-existing store): \"Container load starting — pre-existing store: false\" -> \"Container load finished in 29 ms\". Warm relaunch after `simctl terminate` (pre-existing store): \"Container load starting — pre-existing store: true\" -> \"Container load finished in 8 ms\". Exactly one start/finish pair per launch in both cases (no double-firing). `xcrun simctl launch` returned control ~250ms after invocation on the fresh-install run."
  implication: "Direct, measured, unambiguous evidence that the container/dependency-loading code this debug session's `next_action` targeted is NOT the bottleneck — it completes in tens of milliseconds even on a genuinely fresh store. This is strong evidence (Simulator, not physical device — see blind_spots) that the reported 5-6s cold-start duration is dominated by something outside this repository's container-loading code."

- timestamp: 2026-07-29T20:56:45Z
  checked: "Regression run after the instrumentation change: `xcodebuild test` scoped to `drinkpulseTests` (full unit suite) + `drinkpulseUITests/LaunchHandoffUITests` + `drinkpulseUITests/StartupErrorUITests` (the two suites that exercise `drinkpulseApp.swift`'s `.loading`/`.ready`/`.failed` state machine directly)."
  found: "584 tests passed, 0 failed, 0 skipped (`xcrun xcresulttool get test-results summary`). `git diff --stat -- drinkpulse/drinkpulseApp.swift` shows 29 insertions, 0 deletions — the change is purely additive (new `Logger`/`Duration` extension + wrapping existing logic in timing calls), no branch, condition, or return value was touched or removed. File is 205 lines (ceiling 300)."
  implication: "The instrumentation change introduces zero behavioral regression to the startup state machine or any other feature; the diff is not a no-op/deletion pattern (nothing to game — there was no failing test to vacuously satisfy)."

- timestamp: 2026-07-29T21:55:00Z
  checked: "Static asset + config facts captured directly by the session manager (persisted here because two consecutive investigator runs were killed by infrastructure 500 errors before writing anything to disk). Read: LaunchIcon.imageset/Contents.json; true pixel dimensions via `sips` of both PNGs; drinkpulse/Info.plist UILaunchScreen dict; drinkpulse/drinkpulseApp.swift lines 85-106 (the `.loading` overlay); LaunchBackground.colorset/Contents.json; repo-wide search for vector sources and AppIcon assets."
  found: "1) SCALE-BUCKET ARITHMETIC IS CORRECT — LaunchIcon@2x.png is exactly 504x504 px and LaunchIcon@3x.png is exactly 756x756 px; Contents.json declares them 2x and 3x respectively with no 1x bucket. 504/2 = 252 pt and 756/3 = 252 pt, so the intrinsic point size is a consistent 252x252 pt in both buckets. 2) Info.plist UILaunchScreen dict contains ONLY `UIColorName = LaunchBackground` and `UIImageName = LaunchIcon` — no UIImageRespectsSafeAreaInsets key, no storyboard reference. 3) The SwiftUI `.loading` overlay is `ZStack { Color(.systemBackground).ignoresSafeArea(); Image(\"LaunchIcon\").resizable().scaledToFit().frame(width: 252, height: 252) }` — it requests exactly 252 pt, which on a 3x device is exactly 756 px, a 1:1 pixel match against the @3x asset. 4) `Image(\"LaunchIcon\")` appears exactly once in the entire Swift codebase (drinkpulseApp.swift:101). 5) LaunchBackground.colorset is pure white (1,1,1) light / pure black (0,0,0) dark, which does match `Color(.systemBackground)`. 6) THERE IS NO `AppIcon.appiconset` — the app icon is `drinkpulse/AppIcon.icon/`, an iOS 26 Icon Composer `.icon` bundle (containing layered SVG sources drinkpulse-2-drop.svg and drinkpulse-3-pulse.svg)."
  implication: "Kills the leading static hypothesis for (b): the pixelation CANNOT be explained by a scale-bucket/point-size mismatch or by the SwiftUI overlay requesting a larger frame than the asset provides — 252 pt against a 756 px @3x asset is an exact 1:1 render on a 3x device. Two live explanations remain for the pixelation: (i) the shipped PNGs are themselves upscaled from a lower-resolution raster source, so they contain far less than 756 px of real detail and look soft/pixelated even at a 1:1 render (this was the second interrupted investigator's active lead: it had found clean 1024x1024 vector sources and was about to quantify the actual information content of the shipped PNGs); or (ii) the device is not resolving the @3x bucket. Separately, finding (6) is a significant NEW lead not considered in any of the 13 prior rounds: on iOS 26 an Icon Composer `.icon` app icon drives the system's app-launch zoom/morph animation, in which SpringBoard composites the app's OWN AppIcon — starting at Home-Screen icon size and expanding — ON TOP OF the launch screen. That is a strong candidate explanation for symptom (a) (a small, Home-Screen-icon-sized icon visible during phase 1, stalled at the animation's start frame because the app is slow to launch) that is fully consistent with the user's correction that both icons are app-controlled assets added this milestone, WITHOUT resurrecting the refuted SpringBoard-slow-launch-fallback theory. It is also a strong candidate for symptom (c): on a warm relaunch the app reaches `.loading` fast enough that the 252 pt SwiftUI overlay icon is already mounted while the tail of the system AppIcon morph animation is still on screen, making both icons briefly visible at once."

- timestamp: 2026-07-29T22:05:00Z
  checked: "ROUND 15, Q1 discriminator attempt: rendered `drinkpulse/Assets.xcassets/LaunchIcon.imageset/LaunchIcon@3x.png` visually, and read `drinkpulse/AppIcon.icon/icon.json` + both SVG layer sources (drinkpulse-2-drop.svg, drinkpulse-3-pulse.svg)."
  found: "THE LAUNCHICON IS A FLATTENED RASTER COPY OF THE APP ICON. LaunchIcon@3x.png is not a bare glyph on a transparent field — it is a full app-icon tile: the iOS squircle/rounded-rect shape, the teal->blue linear gradient (matching icon.json's `display-p3:0.21176,0.87843,0.81176` -> `srgb:0.14510,0.38824,0.92157` fill), the white water-drop (drinkpulse-2-drop.svg), and the red pulse/ECG line (drinkpulse-3-pulse.svg), including a baked-in approximation of Icon Composer's glass/translucency treatment. Its corners are transparent outside the squircle."
  implication: "The discriminator this round hoped to use DOES NOT EXIST — the phase-1 icon and the phase-2 icon are THE SAME ARTWORK. That is precisely why the user perceives the sequence as 'small icon, then the same icon much bigger': it is one picture rendered at two different sizes by two different pipelines. It also means the AppIcon-morph lead cannot be discriminated by artwork appearance alone and needs a direct size measurement instead. Independently, this is a design defect in its own right: Apple's iOS 26 guidance is that a launch screen must NOT contain the app icon, because the system already animates the app icon into the launch screen — duplicating it is what makes the hand-off seam visible at all."

- timestamp: 2026-07-29T22:08:00Z
  checked: "ROUND 15, Q2: reconstructed the full pixel-dimension provenance of the LaunchIcon raster across all 8 commits that touched `LaunchIcon.imageset/` (git show of each blob + `sips -g pixelWidth`), then quantified genuine information content with a purpose-built CoreGraphics tool (downscale->upscale round-trip RMS, and mean-absolute-Laplacian sharpness normalized by rendering every historical raster at a common 756 px)."
  found: "PROVENANCE: a654cd1 = 120x120 px -> 072c811 = 120 -> 72ea4ff/cf3f6e4 = 120 -> fd11110 = 168 -> 6160084 ('enlarge to 3x current size') = 504 -> 7789645 ('add complete 1x/2x/3x scale set') = 252 + 504 + 756. The artwork's ORIGIN resolution is 120x120 px, which is exactly an iPhone Home-Screen app icon at @2x (60 pt x 2). MEASURED SHARPNESS (mean |Laplacian|, all rasterized to 756 px so the numbers are directly comparable): 120px original = 0.7999; 168px = 0.9842; 504px from 6160084 = 0.8458 (LOWER than the 168px source it was enlarged from, i.e. that commit was a pure blurry upscale); 504px @2x from 7789645 = 1.1053; shipped 756px @3x = 1.3716. Cross-comparison RMS: @3x vs upscaled-6160084-504 = 8.23; vs upscaled-168 = 8.35; vs upscaled-7789645-@2x = 2.52."
  implication: "PARTIALLY REFUTES the round-15 incoming hypothesis. The shipped @3x is NOT a naive upscale of any earlier raster — it is the single sharpest artifact in the whole history (1.3716 vs 1.1053 for @2x and 0.8458 for the previous 504), so commit 7789645 genuinely re-rendered at higher resolution rather than resampling. So 'the PNG is upscaled garbage' is too strong. What IS confirmed: commit 6160084's 'enlarge to 3x' was a real upscale that DESTROYED detail (0.8458 < 0.9842), and the whole asset lineage descends from a 120 px Home-Screen-sized export. Whether 1.3716 is adequate for a true 1:1 756 px render still needs a native-render reference point, since there is no vector source for the LaunchIcon in the repo (only the AppIcon SVGs)."

- timestamp: 2026-07-29T22:14:00Z
  checked: "FALSE LEAD, RECORDED SO IT IS NOT RE-CHASED. Inspected `build/Build/Products/Debug-iphonesimulator/drinkpulse.app` (the product left behind by round 14's instrumentation build): `plutil -extract UILaunchScreen` on the built Info.plist, and `xcrun --sdk iphonesimulator assetutil --info` on the built Assets.car."
  found: "That bundle appeared to show two spectacular defects: (1) built `UILaunchScreen` was the NESTED, EMPTY structure `{ UILaunchScreen = {} }` rather than the source's `{ UIColorName = LaunchBackground; UIImageName = LaunchIcon }`; (2) the compiled Assets.car contained only 16 asset names — AccentColor, AppIcon (+ its Icon Composer sub-assets AppIcon_Assets/*), RiskHigh, RiskLow, RiskModerate — with NO `LaunchIcon` and NO `LaunchBackground` at all. BUT `stat` on the two build products proves the bundle is STALE: its Info.plist is dated 2026-07-27 10:27 and its Assets.car 2026-06-29 11:28, while `drinkpulse/Info.plist` was CREATED today at 10:21 by commit a654cd1 (the only commit that ever touched it) and LaunchIcon.imageset/Contents.json was last written today at 19:48. The stale nested-empty `UILaunchScreen` is simply the old `GENERATE_INFOPLIST_FILE = YES` / `INFOPLIST_KEY_UILaunchScreen_Generation` output from before a654cd1 introduced the hand-written Info.plist."
  implication: "NEITHER apparent defect is real — both are staleness artifacts of an out-of-date derived-data product, and `xcodebuild` had evidently not re-run actool or the Info.plist processing into that path. Any future round inspecting a built artifact MUST `stat` it against the source first. Source-side config is confirmed correct: `drinkpulse/Info.plist` really does contain UIColorName=LaunchBackground + UIImageName=LaunchIcon, the app target really does set GENERATE_INFOPLIST_FILE=NO + INFOPLIST_FILE=drinkpulse/Info.plist, and Assets.xcassets really does contain both LaunchIcon.imageset and LaunchBackground.colorset. A genuinely fresh build is required before any compiled-artifact claim can be made."

- timestamp: 2026-07-29T22:20:00Z
  checked: "FRESH BUILD (BUILD SUCCEEDED, products timestamped 22:07:32, verified newer than all sources). Re-ran `plutil -extract UILaunchScreen` on the freshly built Info.plist and `assetutil --info` on the freshly compiled Assets.car."
  found: "Both are CORRECT. Built `UILaunchScreen` = `{ UIColorName = LaunchBackground; UIImageName = LaunchIcon }` — the source dict survives the build verbatim, no nesting, no emptying. Compiled Assets.car now contains `LaunchBackground` (universal Color + a UIAppearanceDark variant) and `LaunchIcon` as a SINGLE rendition: `AssetType: Image, Encoding: ARGB, Idiom: universal, Scale: 3, PixelWidth: 756, PixelHeight: 756, RenditionName: LaunchIcon@3x.png`. The @2x rendition is absent because actool thinned the catalog for the 3x destination — expected for a device-specific build, not a defect."
  implication: "Confirms at the COMPILED-ARTIFACT level (not just the source level) that the launch-screen configuration and the asset are exactly as intended, and that a 3x device resolves LaunchIcon to a 756 px @3x rendition whose intrinsic size is 252 pt. Every remaining explanation that depends on 'the config didn't make it into the build' or 'the device resolves a different bucket' is now REFUTED. The 252 pt intrinsic size is proven end-to-end."

- timestamp: 2026-07-29T22:26:00Z
  checked: "THE DECISIVE MEASUREMENT for Q1. Installed the fresh build on booted iPhone 17 Pro Simulator (4F4A0B72, 1206x2622 px = 402x874 pt @3x) after `simctl uninstall` (genuinely empty store). Held the app at launch with `xcrun simctl launch --wait-for-debugger` so the PRE-PROCESS launch screen stays on screen indefinitely, then captured three successive `xcrun simctl io screenshot` frames and measured the non-background content bounding box in raw pixels with a purpose-built CoreGraphics tool."
  found: "CAPTURE 1 (earliest frame, caught mid-transition): background sampled at the screen edge is TEAL rgb(152,224,215) — NOT the white LaunchBackground — and the content bbox spans the FULL screen width, x=0..1205, y=314..2463. CAPTURES 2 and 3 (stable, held state): background is pure white rgb(255,255,255) = LaunchBackground, and the icon content bbox is x=225..980, y=933..1688 => EXACTLY 756 x 756 px, perfectly centred (bbox centre x=602.5 vs screen centre 603). 756 px / 3 = EXACTLY 252.0 x 252.0 POINTS."
  implication: "Q1 IS ANSWERED, and it overturns the entire premise of rounds 2-13. (1) The pre-process `UILaunchScreen` compositor sizes `UIImageName` at the image's INTRINSIC POINT SIZE, centred, with NO scaling, NO aspect-fit into a constrained container, and NO safe-area-driven shrinking. It renders LaunchIcon at 252 pt — which is EXACTLY the same size as the SwiftUI `.loading` overlay's explicit 252 pt frame. The two app-controlled rendering paths are pixel-for-pixel size-identical. (2) Therefore the small, Home-Screen-icon-sized icon the user sees in phase 1 CANNOT be the LaunchIcon, because the LaunchIcon is provably never drawn at any size other than 252 pt. (3) Capture 1 independently caught the actual phase-1 artefact in flight: a teal, full-screen-width rounded rect — that is the AppIcon's teal->blue gradient (icon.json's display-p3 0.21176,0.87843,0.81176 top stop, cross-dissolving over white) during SpringBoard's iOS 26 app-launch ZOOM/MORPH, in which the Icon Composer AppIcon expands from Home-Screen icon size to fill the screen. CONFIRMED: the phase-1 'small icon' is the AppIcon mid-morph, an OS-driven animation over which the launch screen has no control; 13 prior rounds were editing the wrong asset."

- timestamp: 2026-07-29T22:34:00Z
  checked: "Q2 CLOSED. Cropped a 280x280 NATIVE-pixel region from the centre of the 756 px `LaunchIcon@3x.png` (no resampling) and rendered it 1:1; cross-checked provenance against the compiled `AppIcon60x60@2x.png` (120 px) and `AppIcon76x76@2x~ipad.png` (152 px) in the built bundle; re-read 04-01-SUMMARY.md line 43."
  found: "The 1:1 crop is VISIBLY, HEAVILY BLURRED — the red pulse stroke, which is a hard-edged vector line 40 units wide in drinkpulse-3-pulse.svg, has edges smeared over roughly 8 px, and the white drop's outline is similarly soft. There is no crisp edge anywhere in the asset. 04-01-SUMMARY.md line 43 states outright that LaunchIcon was 'extracted from actool's real compiled fallback rendering (AppIcon60x60@2x.png inside the built .app bundle)' — a 120x120 px file. Sharpness figures: 120 px AppIcon60x60@2x = 0.7999, shipped 756 px @3x = 1.3716 (both measured at a common 756 px raster)."
  implication: "Q2 CONFIRMED, with one refinement. The shipped @3x is not a *pure* upscale of the 120 px file (commit 7789645 did re-render somewhat sharper, 1.3716 vs 0.7999), but the artwork's entire lineage originates from a 120 px Home-Screen-icon export and is displayed at 756 px — a ~6.3x enlargement of the original information content. The visible blur at a 1:1 render is therefore fully explained WITHOUT invoking any scale-bucket or resolution-selection bug: the pixels being rendered are genuinely 1:1, there simply is not enough real detail in them. The asset is under-resolved for the 252 pt size it is now displayed at."

- timestamp: 2026-07-29T22:36:00Z
  checked: "DESIGN-INTENT CROSS-CHECK against the phase's own frozen contract: `.planning/phases/04-branded-static-launch-screen/04-DISCUSSION-LOG.md` (decision table) and `04-CONTEXT.md` D-01."
  found: "Decision D-03's SELECTED option (marked with the checkmark) is: 'Centered, Home Screen-icon-sized — Matches Apple HIG default for launch screens — icon appears same size/position as it would on the Home Screen, not full-bleed.' The rejected alternative was 'Larger, more prominent — Bigger centered icon for stronger brand presence — diverges slightly from typical HIG scale.' 04-01-SUMMARY.md line 123 confirms the original implementation honoured this: the PNG was 'assigned to the imageset's 2x slot (60pt on iPhone)' = 120 px @2x = 60 pt. Commits cf3f6e4 ('increase size per user request') and 6160084 ('enlarge to 3x current size per user request') then took it to 252 pt."
  implication: "The launch icon is currently 4.2x LARGER than the size its own frozen design contract specifies (252 pt vs 60 pt). Crucially, the enlargement requests were made while the user believed our LaunchIcon was the small icon rendering wrongly — a premise this round has now REFUTED by direct measurement. At the contract's 60 pt the asset would be showing 180 px of a 120 px original (1.5x, near-native and sharp) AND would sit at the size the Home-Screen icon occupies, so both reported visual defects would largely dissolve. This makes the icon's SIZE a genuine product decision that the user should now re-make with corrected information, not something to change unilaterally."

- timestamp: 2026-07-30T07:02:00Z
  checked: "ROUND 16 POST-FIX VERIFICATION. Applied the user's option (C) and re-verified end to end against a GENUINELY fresh build (`rm -rf build` first, then `xcodebuild clean build`; products stat-checked at 06:43:44 vs sources at 06:42:57/06:43:10, so the Evidence-22:14 stale-artifact trap cannot recur). Inspected: `plutil -extract UILaunchScreen` on the built Info.plist; `assetutil --info` on the built Assets.car; `grep -c INFOPLIST_KEY_UILaunchScreen_Generation` on project.pbxproj; the 300-line file gate; a full unfiltered `xcodebuild test`; and `git grep LaunchIcon -- . ':!.planning'` after the change."
  found: "Built `UILaunchScreen` = `{ UIColorName = LaunchBackground }` — non-empty, correctly wired, `UIImageName` gone. Built Assets.car contains `LaunchBackground` (universal Color + UIAppearanceDark) and NO `LaunchIcon` rendition; `AppIcon` + its Icon Composer sub-assets (AppIcon_Assets/drinkpulse-2-drop, drinkpulse-3-pulse, gradients) untouched. `grep -c ..._Generation` = 0. No Swift file over 300 lines (drinkpulseApp.swift 215 -> 198). `** BUILD SUCCEEDED **` with zero source warnings (only the pre-existing appintentsmetadataprocessor toolchain notice). `** TEST SUCCEEDED **` — 649/649 passed, 0 failed, 0 skipped, 35 suites, including LaunchHandoffUITests 2/2 and StartupErrorUITests 2/2. Post-change `git grep LaunchIcon` outside .planning returns ZERO hits."
  implication: "The fix is complete and internally consistent at every layer this environment can observe: source, compiled Info.plist, compiled asset catalog, build gate, and the full regression suite. The deletion is provably non-vacuous — it changed the SHIPPED artifacts (the built launch-screen dict and the built Assets.car both differ), so it is a real behavioural change rather than dead-code removal, and no test was weakened to accommodate it. What remains unobservable from here is unchanged from every prior round: how SpringBoard's own AppIcon launch animation actually looks against the now-plain LaunchBackground on real hardware. That single question is the final human checkpoint."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  THREE causes, split across the two symptom clusters. The DURATION cluster has one, already
  closed. The VISUAL cluster has two, and they are genuinely AND-gated — each alone would be
  mild; together they produce exactly the reported "small icon, then a much bigger blurry one".

  (1) DURATION (environment category) — CLOSED, external, no code defect. In-repo container
  loading measures 9 ms on the real device and 8-29 ms on Simulator. The 5-6 s is Xcode
  Debug-install first-launch overhead (AMFI signature validation + dyld/DWARF symbol loading),
  outside app control. Refuted by direct measurement; see Evidence 21:10 and 20:54.

  (2) VISUAL / cause A (config + design category) — THE LAUNCH SCREEN SHIPS A DUPLICATE OF THE
  APP ICON, AT A DIFFERENT SIZE FROM THE ONE iOS ITSELF IS ANIMATING. `LaunchIcon@3x.png` is not
  a logo or wordmark: it is a flattened raster copy of the AppIcon — same squircle, same
  teal->blue gradient, same drop+pulse glyph (Evidence 22:05). Meanwhile `drinkpulse/AppIcon.icon`
  is an iOS 26 Icon Composer bundle, and on iOS 26 SpringBoard performs an app-launch ZOOM/MORPH
  that expands the REAL app icon from Home-Screen size into the app window. So the user sees the
  identical artwork rendered twice by two different systems at two different sizes: first the OS
  morph (starting ~60 pt, and STALLED there for 3-4 s precisely because cause 1 makes the app slow
  to launch), then our launch screen at 252 pt. That is the "small icon then much bigger icon".
  MEASURED, not inferred: holding the process with `simctl launch --wait-for-debugger` on an
  iPhone 17 Pro Simulator @3x and measuring the screenshot bounding box gives the launch screen
  icon at EXACTLY 756x756 px = 252.0 x 252.0 pt, perfectly centred; an earlier frame from the same
  run caught the morph in flight as a teal full-width rounded rect over the Home Screen
  (Evidence 22:26). Symptom (3), the warm-relaunch double-icon flash, is the same cause: the tail
  of the OS morph overlapping our 252 pt launch screen, visible as two icons ONLY because the two
  renderings differ in size.

  (3) VISUAL / cause B (data category) — THE ASSET IS UNDER-RESOLVED FOR THE SIZE IT IS SHOWN AT.
  Per 04-01-SUMMARY.md line 43 the artwork was extracted from the compiled `AppIcon60x60@2x.png`,
  a 120x120 px file, and is now displayed at 756 px — a ~6.3x enlargement of the original
  information content. A 280x280 NATIVE-pixel crop of the shipped @3x shows the pulse stroke —
  a hard-edged 40-unit vector line in the SVG source — smeared over ~8 px, with no crisp edge
  anywhere (Evidence 22:34). This is why it looks pixelated even though the render is a genuine
  1:1 pixel match. Note the interaction with cause A: at the 60 pt size the phase's own frozen
  design contract specifies (04-DISCUSSION-LOG.md D-03, selected option "Centered, Home
  Screen-icon-sized"), this same asset would render 180 px from a 120 px original — near-native
  and sharp. The blur is a direct consequence of the 4.2x enlargement introduced by commits
  cf3f6e4 and 6160084, which were themselves made under the now-refuted belief that our LaunchIcon
  was the small icon rendering wrongly.

  WHAT THIS OVERTURNS: rounds 2-13 assumed the small phase-1 icon was `LaunchIcon` being sized
  wrongly by a "quirky" compositor, and spent 13 rounds editing that asset. The compositor is not
  quirky — it draws `UIImageName` centred at the image's exact intrinsic point size, no aspect-fit,
  no safe-area scaling. The small icon was never our launch screen at all.
fix: |
  ROUND 16 — FINAL FIX APPLIED. The user chose option (C) at the round-15 decision checkpoint:
  drop the app-icon duplication entirely rather than resize it (option A) or re-render it at true
  resolution (option B). This attacks causes A and B at the root instead of patching either: iOS 26
  already animates the REAL AppIcon over the launch screen, so the app should not draw a second copy
  of it at any size or resolution. It also satisfies 04-CONTEXT.md D-01's zero-diff requirement
  exactly — the launch screen and the first live frame are now both a plain, matching background.

  1. drinkpulse/Info.plist — removed `UIImageName = LaunchIcon` from the `UILaunchScreen` dict.
     `UIColorName = LaunchBackground` kept, so the dict stays non-empty and the branded
     dual-appearance background still applies.
  2. drinkpulse/drinkpulseApp.swift — removed the `Image("LaunchIcon")` overlay from the `.loading`
     case entirely, reverting to the bare `Color(.systemBackground).ignoresSafeArea()` of the
     original D-11 baseline, with that original comment restored (accurate again) plus a short note
     recording WHY the frame is deliberately icon-free. This SUPERSEDES round 15's intrinsic-sizing
     edit; that change and its now-obsolete measurement comment are gone, so the file carries no
     stale layered commentary. This also fully unwinds 04-01-SUMMARY.md Deviation 11's
     prohibition crossing — the plan no longer touches app-startup UI at all.
  3. drinkpulse/Assets.xcassets/LaunchIcon.imageset/ — DELETED via `git rm` (Contents.json +
     LaunchIcon@2x.png + LaunchIcon@3x.png). Confirmed genuinely orphaned BEFORE deleting: after
     steps 1 and 2, `git grep LaunchIcon -- . ':!.planning'` returns zero hits — no Swift code, no
     test, no plist, no other asset referenced it.

  NOT CHANGED, deliberately: the `os.Logger` startup-timing instrumentation from round 14 stays
  (additive, integer-ms only, no PII — it is what closed the duration question and is the only way
  to re-measure on-device). Cause 1 (duration) needs no code fix; it is Xcode-Debug-install
  overhead, external and outside app control.
verification:
  target_test: { result: skipped, reason: "The pre-process launch screen is structurally unobservable by XCUITest (it attaches only after process start), and the OS's own AppIcon launch animation — which is now the ONLY icon on screen — is SpringBoard-owned and not addressable by any in-process test at all. The compositor claim this fix rests on was instead measured directly via `simctl launch --wait-for-debugger` + screenshot bbox (756x756 px), a stronger quantitative observation than any assertion a UI test could make. Compiled-artifact assertions substitute for a runtime test where they can: built UILaunchScreen dict and built Assets.car were both inspected on a stat-verified-fresh build." }
  mutation_check: { result: skipped, reason: "No mutation-testing tool configured for this Swift project. The change is config + asset deletion + a view-body simplification; there is no conditional, branch, or arithmetic to mutate." }
  no_op_deletion: { result: pass, deletion_justified_by_rca: true, note: "This fix IS a deletion, so this signal matters most. Justified directly by the RCA: the root cause is that the app ships a SECOND copy of the app icon while iOS 26 already animates the real one over the launch screen — the duplicate is the defect, so removing it is the repair, not a symptom suppression. Verified non-vacuous three ways: (1) the deletion is observable end-to-end in the compiled artifacts (built UILaunchScreen = {UIColorName: LaunchBackground} only; built Assets.car no longer contains a LaunchIcon rendition), so it genuinely changed shipped behaviour rather than removing dead code; (2) the imageset deletion was gated on proving orphanhood first (`git grep LaunchIcon -- . ':!.planning'` returns zero hits post-change), not assumed; (3) no test was deleted, disabled, or weakened to make anything pass — 649/649 pass with the suite unchanged." }
  adjacent_tests: { result: pass, suites_run: ["full `xcodebuild test` on iPhone 17 Pro Simulator, no -only-testing filter — `** TEST SUCCEEDED **`, xcresult summary: totalTestCount 649, passedTests 649, failedTests 0, skippedTests 0, expectedFailures 0, across 35 suites. Includes LaunchHandoffUITests (2/2 — the launch-handoff regression suite) and StartupErrorUITests (2/2 — the .failed branch), the two suites driving drinkpulseApp.swift's .loading/.ready/.failed state machine this change touches."] }
  test_assertion_updates: { result: none-needed, note: "Checked explicitly because the guidance flagged it: NO UI test asserts on the presence of a launch icon, so nothing had to be updated to match the new intended behaviour. LaunchHandoffUITests' own doc comment states outright that neither test asserts anything about the launch screen (XCUITest attaches only after it has handed off); both assert only on the first LIVE frame (Home tab / 'Get Started'). StartupErrorUITests drives the .failed branch, untouched. The suites are regression proof for this change, not coverage of it — the icon behaviour remains human-verified only, exactly as 04-VALIDATION.md already classified it." }
  revert_and_reconfirm: { result: not-applicable, note: "Cannot be run from this environment: reconfirming would require observing the duplicate icon return on a real device during a cold launch, and no physical device is attached. The causal chain was established by direct measurement instead (compositor sizing measured at 756 px = 252.0 pt; the OS morph independently caught in flight as a teal full-width rounded rect over the Home Screen), which is why the final human checkpoint below is the honest close-out rather than a claim of full verification." }
  build_gate: { result: pass, note: "Genuinely FRESH clean rebuild (`rm -rf build` first, so the stale-product trap from Evidence 22:14 cannot recur; products stat-verified at 06:43:44 vs sources at 06:42:57/06:43:10): `** CLEAN SUCCEEDED **` + `** BUILD SUCCEEDED **`, ZERO source warnings — the single `warning:` line is appintentsmetadataprocessor's pre-existing 'No AppIntents.framework dependency found' toolchain notice. INFOPLIST_KEY_UILaunchScreen_Generation still absent (grep -c = 0). File-size gate: no Swift file over 300 lines; drinkpulseApp.swift = 198 (down from 215)." }
  compiled_artifact_check: { result: pass, note: "Against the stat-verified-fresh build only. `plutil -extract UILaunchScreen` on the built Info.plist = { UIColorName = LaunchBackground } — non-empty, correctly wired, UIImageName gone. `assetutil --info` on the built Assets.car: LaunchBackground present, LaunchIcon ABSENT, AppIcon + its Icon Composer sub-assets untouched." }
  guardrail_verdict: accepted
oracle_type: derived
files_changed:
  - "drinkpulse/Info.plist — removed `UIImageName = LaunchIcon` from the UILaunchScreen dict; kept `UIColorName = LaunchBackground`"
  - "drinkpulse/drinkpulseApp.swift — removed the Image(\"LaunchIcon\") overlay from the `.loading` case entirely (supersedes round 15's intrinsic-sizing edit and deletes its now-obsolete measurement comment); reverted to the bare Color(.systemBackground).ignoresSafeArea() D-11 baseline with the original comment restored. Fully unwinds 04-01-SUMMARY.md Deviation 11's prohibition crossing."
  - "drinkpulse/drinkpulseApp.swift (round 14, RETAINED deliberately: os.Logger + ContinuousClock startup timing instrumentation — additive, integer-ms only, no PII; it is what closed the duration question and the only way to re-measure on-device)"
  - "drinkpulse/Assets.xcassets/LaunchIcon.imageset/ — DELETED via git rm (Contents.json, LaunchIcon@2x.png, LaunchIcon@3x.png). Orphanhood proven before deletion."
  - ".planning/phases/04-branded-static-launch-screen/04-01-SUMMARY.md — closing Deviation 14 recording that rounds 2-13 edited the wrong asset, plus frontmatter corrections (two now-refuted `patterns` entries marked SUPERSEDED, D1/D2 coverage scope corrected, key-files updated)"
docs_reviewed:
  - "README.md, docs/architecture.md, docs/domain.md — NO mention of the launch screen/icon anywhere (`git grep -ni 'launch icon|launchicon|launch screen|LaunchBackground'` over README.md + docs/ returns zero hits). No update needed."
  - ".planning/PROJECT.md — mentions 'Branded static launch screen' twice, both as milestone SCOPE bullets, not as claims about an icon. Still accurate: the phase does replace the auto-generated launch screen with an explicitly authored one (hand-written UILaunchScreen dict + dual-appearance LaunchBackground). Left unchanged."
  - ".planning/REQUIREMENTS.md — CONTRADICTION FOUND, deliberately NOT auto-edited. LAUNCH-01 reads 'a branded static launch screen (app icon + matching background color, no text, no spinner)'. With the icon removed, the APP supplies only the background; the icon is now iOS's own AppIcon launch animation. Amending a requirement's definition of done is a product decision, so this is surfaced at the human checkpoint instead of changed unilaterally. LAUNCH-01 is still unchecked/Pending, so nothing is falsely claimed in the meantime."
  - ".planning/STATE.md and .planning/ROADMAP.md — explicitly excluded by the user; not touched, not staged."
