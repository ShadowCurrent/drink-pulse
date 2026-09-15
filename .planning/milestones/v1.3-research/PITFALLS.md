# Pitfalls Research

**Domain:** Adding native-feel interaction/presentation features (Swift Charts scrubbing, cross-container directional transitions, static launch screen) to an existing production SwiftUI + SwiftData iOS app (DrinkPulse v1.3 "Native Feel")
**Researched:** 2026-07-28
**Confidence:** MEDIUM (SwiftUI/Charts/XCUITest mechanics are well-documented public patterns — WWDC sessions, Apple docs, established iOS dev blogs — but no single authoritative source covers "chartXSelection + accessibilityChartDescriptor coexistence" or "cross-container directional transitions" as a combined pattern; those two are synthesized from primitives plus this codebase's actual file layout, so rate MEDIUM not HIGH.)

## Critical Pitfalls

### Pitfall 1: `chartXSelection` becomes the *only* way to read a value, silently breaking VoiceOver parity

**What goes wrong:**
`chartXSelection` is a sighted, gesture-driven interaction — a finger drag. It does not automatically feed VoiceOver. If the drag-to-scrub feature ships as "the" way to read per-point Insights values (e.g. the callout is the only place a number ever shows, and `accessibilityChartDescriptor` is not extended to cover the new interaction), VoiceOver users lose the ability to get exact values entirely, even though the chart "looks" more capable to sighted users. This is a regression hiding inside a feature addition — the existing `accessibilityChartDescriptor` support (per CONCERNS.md context, DrinkPulse already ships charts) can silently drift out of sync with new visual behavior the moment scrubbing is added, because nothing forces the two to be updated together.

**Why it happens:**
`chartXSelection` and `accessibilityChartDescriptor`/`AXChartDescriptor` are two entirely separate APIs with no automatic bridging. Swift Charts does build a base accessibility tree and VoiceOver's own Chart Detail page (double-tap-hold-drag to scan) for free, but a *custom* value callout/annotation rendered off `chartXSelection` is regular SwiftUI content — it needs its own `accessibilityLabel`/`accessibilityValue`, and the existing descriptor needs to be checked to confirm it still reflects the same data granularity as the new interactive readout. Developers test the new gesture with a finger, see it work, and stop — VoiceOver is a separate manual test pass that's easy to skip under time pressure.

**How to avoid:**
- Explicit acceptance criterion: "VoiceOver can retrieve the same per-point values `chartXSelection` reveals, via the existing/extended `accessibilityChartDescriptor`" — not "chart has an accessibility descriptor" (too vague, already nominally true).
- Test with VoiceOver on, not just Reduce Motion / visual QA, before calling either chart done.
- Keep the callout view itself accessible too (in case a VoiceOver user with residual vision still uses touch) — give it a meaningful `accessibilityLabel`/`Value`, not just visual styling.
- Route the callout's number through the same `InsightsViewModel+Formatting` layer already used elsewhere (per the todo) so VoiceOver and sighted users never see two different values for the same point.

**Warning signs:**
- PR/task marked done after only a simulator drag test with VoiceOver off.
- `accessibilityChartDescriptor` code unchanged in the diff despite new per-point data now being surfaced visually.
- Callout `Text` has no accessibility modifiers of its own.

**Phase to address:**
The Insights chart scrubbing phase itself — accessibility parity is not a follow-up, it's part of "done" per CLAUDE.md's accessibility section (mandatory `accessibilityLabel`, chart descriptor requirement already explicit in the todo).

---

### Pitfall 2: Directional slide transition between structurally different containers (`List` vs `ScrollView`) produces layout pops, flashes, or silently falls back to a cross-fade

**What goes wrong:**
`HistoryView`'s two branches are not the same container type — `listContent` is a `List` (`.insetGrouped`), `calendarContent` is a `ScrollView`. SwiftUI's `.slide`/`.move(edge:)` transitions animate insertion/removal of *whichever view is being swapped*, but each container brings its own internal chrome (List's separator insets, section header materialization, safe-area/background behavior differ from a plain ScrollView). A transition that looks clean in isolation (e.g. tested only with two `Text` views) can, once wired to the real `List`/`ScrollView` pair, show a frame of unstyled background, a hitch as `List` finishes laying out off-screen, or the List's own row-appearance animations firing concurrently with the container-level slide — two animations racing on the same frame.

**Why it happens:**
`.slide` is one-directional only (per SwiftUI docs); getting direction-aware behavior requires `.asymmetric(insertion:removal:)` built from `.move(edge:)`, and there's no first-party mechanism to guarantee two structurally different scrollable containers animate their *content* in lockstep rather than their *frames* — a "slide" of a `List` container can visually read as the List's rows appearing/disappearing rather than a smooth pan. This is exactly the risk flagged in the todo itself, but it is easy to under-scope: build and test in Preview (fast, synthetic data, no real List chrome) and never catch the issue until a real device with real row counts.

**How to avoid:**
- Test the transition with the real `HistoryListQueryView` (not a stub) with a realistic dataset — the visual glitches this pitfall describes only show up with real List materialization cost.
- Prefer driving the transition at a level that treats both branches uniformly (e.g. wrap both in a common `ZStack`/`Group` with identical asymmetric insertion/removal transitions and matched animation curve/duration) rather than relying on each container's own default behavior.
- Verify on-device, not just Simulator/Preview — List rendering cost and safe-area material rendering differ meaningfully on-device.
- Explicitly decide and test the **three-state** case, not two: List ↔ Calendar ↔ empty-state (`ContentUnavailableView`) — a transition that only handles the two "happy" branches will look wrong (or crash on a missing `.transition`) whenever the list is empty.

**Warning signs:**
- Transition only ever verified in Xcode Preview with mock/small data.
- No test/manual check with the empty-state `ContentUnavailableView` branch mid-transition.
- The two branches use different transition/animation modifiers instead of a single shared configuration.

**Phase to address:**
The History slide-transition phase — this is exactly the risk the todo pre-flags; the phase plan should include an explicit device-verification step with a populated history, not just a code-complete gate.

---

### Pitfall 3: `@Query`-backed list re-fetches mid-transition, causing content to visibly pop in while sliding

**What goes wrong:**
`HistoryListQueryView` re-runs its `@Query` fetch on appearance. If the slide transition is built naively (start animation → view becomes visible → `@Query` populates), the user sees the incoming List slide in *empty* or with a placeholder, then rows pop in a beat later once the fetch resolves — breaking the "native, polished" feel this milestone is explicitly chasing. This is worse than a static jump-cut because it's an animated stutter, which reads as a bug rather than a stylistic choice.

**Why it happens:**
SwiftData's `@Query` re-evaluates when its owning view re-enters the view hierarchy / re-renders, and there's no built-in "pre-warm before showing" mechanism — `@Query` is push-based (it updates the view once data is available), not something you can await before starting a transition. Combined with `List`'s own diffing/insertion animations, two independent asynchronous-ish processes (SwiftUI's transition animation, SwiftData's query population) run concurrently with no ordering guarantee between them.

**How to avoid:**
- If `HistoryListQueryView` is already mounted (segment control just toggles which branch is visible, both kept in the tree), the `@Query` has almost certainly already fetched before the user switches — verify whether the current code already keeps both branches alive (conditional `.opacity`/`zIndex` rather than a real add/remove) since that alone could sidestep the pop-in risk entirely.
- If the design does destroy/recreate the List branch on each switch (true conditional insertion), consider prefetching/keeping the underlying data query at a parent scope that outlives the transition, so the child view only re-renders already-available data rather than re-querying from zero.
- Manually test switching to List repeatedly, including immediately after adding/deleting an entry, to catch a visible pop confirmed only by watching a real device — this is not something a Preview with static data will reveal.

**Warning signs:**
- List branch is a fresh `HistoryListQueryView()` instance created only inside the switch case (guarantees a fetch cycle every switch).
- No manual verification of the transition immediately after a data mutation (add/delete/edit) that would make the fetch non-trivial.
- Transition timing (duration/curve) was tuned only against empty or tiny fixture data, not the full dataset used elsewhere for performance testing (CONCERNS.md already tracks calendar-view performance at 2k/10k events — this feature should be sanity-checked at the same scale, not just casually).

**Phase to address:**
The History slide-transition phase — must include an explicit check (manual or automated) of the transition on a non-trivial, real dataset, not just empty/mock data.

---

### Pitfall 4: `reduceMotion` implemented as "less animation" instead of "no animation," or applied inconsistently across the three new features

**What goes wrong:**
CLAUDE.md requires honoring `reduceMotion`, and the codebase already has a working pattern (`OnboardingView.swift:80`: `.animation(reduceMotion ? nil : .someCurve, value:)`). The common failure mode when adding *new* animated features is either (a) substituting a faster/simpler animation instead of `nil` — Reduce Motion means no motion, not "quick motion" — or (b) applying the check to one of the three features (e.g. the slide transition, since the todo explicitly calls it out) but forgetting it on the chart scrubbing's selection/callout animation, since `chartXSelection`'s built-in interaction has its own implicit animation/haptic behavior that's easy to assume is "system-handled" and therefore exempt.

**Why it happens:**
Swift Charts' native selection interaction includes its own animation and haptics as part of the framework, which can create a false sense that "it's Apple's animation, not mine, so Reduce Motion is Apple's problem." But the *callout annotation* built on top (the value readout with a `RuleMark`/`PointMark`) is custom SwiftUI content, and the todo explicitly calls out "honor reduceMotion for the selection animation" as a requirement — meaning the annotation's *appearance* transition, not the framework's own scrub interaction, is what's actually in scope and easy to skip.

**How to avoid:**
- Reuse the exact existing project pattern (`.animation(reduceMotion ? nil : .curve, value:)`) rather than inventing a new one, per the todo's own instruction — do not introduce a second reduce-motion idiom in the same codebase.
- Apply it to: the chart callout/annotation appearance, the slide transition, and any incidental new animation (e.g. haptic-adjacent visual feedback) — treat it as a checklist item per new animated surface, not a single global toggle.
- Verify with the actual iOS Simulator/device Accessibility → Motion → Reduce Motion setting toggled on, not just by reading the code.

**Warning signs:**
- `reduceMotion` check present in the slide-transition code but absent from the chart callout code (or vice versa).
- Any `withAnimation(.spring(...))` (or similar) with no reduceMotion branch nearby.

**Phase to address:**
Both the Insights-scrubbing phase and the History-transition phase individually — each should carry its own reduceMotion verification step; do not treat one feature's reduceMotion handling as proof the other is covered.

---

### Pitfall 5: Branded launch screen shipped and "verified" only via Simulator warm relaunch, never a real force-quit cold launch on device

**What goes wrong:**
`UILaunchScreen` is evaluated by the OS before the app process even starts meaningfully executing — its rendering path, caching behavior, and timing differ between a Simulator (which is frequently left warm, with the app process already partially resident) and a real device after a genuine force-quit. The todo explicitly names this: the user's actual complaint was a slow *cold* launch, and simulator warm-relaunch testing will not reproduce the blank-screen duration or confirm the new branded image actually appears during that window. Shipping based on Simulator screenshots alone risks confirming nothing about the actual reported problem.

**Why it happens:**
Simulator app relaunches (Cmd+R in Xcode, or tapping the icon after a recent run) rarely trigger a genuine "iOS decides whether to show the launch screen at all" cold path the way a real force-quit does; developers naturally reach for the faster, simulator-based iteration loop and treat a visually-correct Simulator screenshot as done.

**How to avoid:**
- Explicit test step: install (or force-quit) the app on a **real device**, launch from a fully-terminated state, and visually confirm the branded image appears (not blank white).
- Do not treat Simulator screenshots as sufficient sign-off for this specific todo — the todo document itself states this outright ("verify on a real force-quit cold launch on device, not a simulator warm start").
- Remember `UILaunchScreen` is static by platform design — do not attempt to add a spinner or any animation; if stakeholders expect a loading indicator, that belongs to the in-app loading state gated behind the separate async-container-startup work (Cluster A, already shipped in v1.2), not this launch screen.

**Warning signs:**
- Task marked done with only a Simulator screenshot attached.
- Any attempt in the diff to add custom view code, animation, or a spinner to the launch screen configuration (a sign of scope confusion with the in-app loading state).

**Phase to address:**
The launch-screen phase — the todo already scopes this correctly (low-risk, presentation-only); the only real risk is under-verifying on-device, so the phase's "done" gate must include a device cold-launch check, not just a build succeeding.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|--------------------|-----------------|------------------|
| Testing slide transition only against empty/mock History data in Preview | Fast iteration, no simulator boot | Misses List-materialization glitches and `@Query` pop-in that only appear with real row counts | Never for final sign-off; fine for early layout iteration only |
| Adding `chartXSelection` without touching `accessibilityChartDescriptor` in the same PR | Ships the sighted-user feature faster | VoiceOver parity regression that's easy to forget once the visual feature "looks done" | Never — CLAUDE.md accessibility rules are non-negotiable, and the todo names this explicitly |
| Hardcoding one slide direction instead of deriving it from `HistorySegment` ordering / previous value | Simpler code, ships faster | Looks visibly wrong on the reverse switch (calendar→list sliding the same way as list→calendar) | Never — the todo already flags this as required, not optional |
| Skipping the on-device cold-launch check for the launch screen because Simulator "looks right" | Saves a device-test cycle | Ships unverified against the actual reported bug (which was device-specific cold-launch behavior) | Never for this specific todo |
| Using `Thread.sleep`/fixed delays in the new XCUITest instead of `waitForExistence`/hittability checks | Quick to write | Flaky test that intermittently fails in CI, exactly the kind of flakiness CONCERNS.md already documents as a known problem in this suite | Never — the codebase already has a documented flakiness problem; don't add to it |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|--------------|------------------|-------------------|
| Swift Charts `chartXSelection` + custom callout annotation | Treating the framework's built-in VoiceOver/Audio Graph support as covering the custom callout too | Explicitly extend/verify `accessibilityChartDescriptor` for the new interactive readout; test with VoiceOver on, not just visually |
| SwiftUI transition + SwiftData `@Query` | Assuming `@Query` refetch and the transition animation are independent and won't visibly interact | Verify with real data whether the `@Query`-backed branch is already resident (opacity/zIndex toggle) vs. truly recreated on each segment switch; test post-mutation (after add/delete) not just on a static dataset |
| `List` (`.insetGrouped`) vs `ScrollView` cross-container transition | Assuming the same `.slide`/`.move` modifier behaves identically regardless of container type | Test the transition with the real containers and real data, not stand-in views; consider unifying both branches under one outer container for the animated portion |
| `UILaunchScreen` (static config) | Testing only in Simulator, or attempting to add animation/spinner to it | Verify on a real device with a genuine force-quit cold launch; keep any animated loading UI in-app, gated on the already-shipped async container-startup path |
| `drinkpulseUITests` for animated/transient UI | Asserting mid-animation or relying on fixed-time delays | Pin the post-transition end state (correct segment's content, expected chart value) using `waitForExistence`/hittability, per the todos' own explicit guidance |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|-----------|------------|-----------------|
| Chart scrubbing readout recomputed/reformatted per drag-frame without memoization | Laggy/dropped-frame drag on large date ranges (e.g. "All Time" view, which CONCERNS.md already flags as computation-heavy for the calendar) | Route selection lookups through an efficient index (e.g. binary search / dictionary keyed by date) rather than a linear scan per frame; reuse the existing `InsightsViewModel+Formatting` layer instead of ad hoc per-frame formatting | Noticeable once the selected range/dataset is large — same scale class already documented as a perf concern for Insights "Year"/"All Time" views |
| History transition duplicating both containers' work (List fully renders while ScrollView is also active mid cross-fade) | Frame drop / stutter specifically during the transition window, worse with large history | Avoid literally overlapping two fully-populated real containers during the animated window; prefer swap-after-settle or a lightweight placeholder for the outgoing view | Becomes visible with realistic history sizes (hundreds+ of events), not with a handful of test rows |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Logging selected chart date/value or transition state via `print`/verbose logging while debugging the new gesture code | Violates CLAUDE.md's "never log PII/health data" — a scrubbed chart value is derived directly from consumption events (health data) | Use `os.Logger` with `.private` interpolation per existing convention if any logging is added at all; prefer no logging for this UI-only feature |
| Adding a UI-test seeding/reset hook for the new features that's not properly gated on a launch argument | Could leak into production builds or seed non-representative/real-looking data | Follow the existing `UITestSeed` pattern (launch-arg-gated, inert in production) already used elsewhere in the app |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-------------------|
| Hero/headline card ambiguously mixes "following selection" and "period total" behavior (e.g. flickers between the two, or freezes on the last-scrubbed value after release) | Confusing, feels buggy rather than native — undermines the exact "native iOS 26 feel" this milestone targets | Make an explicit, tested decision per the todo's own suggestion: follow the live selection while scrubbing, revert cleanly to the period total on release — verify the revert transition itself respects reduceMotion too |
| Slide transition direction inverted or inconsistent between List→Calendar and Calendar→List | Feels disorienting, works against the "native feel" goal rather than for it | Derive direction from `HistorySegment.allCases` ordering / the previous vs. new segment, verified by manually toggling back and forth on device |
| Branded launch screen still followed by a long blank/frozen window before first frame (since this todo doesn't address launch *speed*, only presentation) | User may perceive the app as "stuck" on the branded image, same complaint just wearing nicer clothes | Set expectations correctly in review: this todo is presentation-only; if the wait is still long, that's the separate async-container-startup problem (already addressed in v1.2) — don't let scope blur into promising a faster launch |

## "Looks Done But Isn't" Checklist

- [ ] **Chart scrubbing:** Often missing real VoiceOver verification — check that `accessibilityChartDescriptor` was actually extended/tested with VoiceOver on, not just that `chartXSelection` works with a finger.
- [ ] **Chart scrubbing:** Often missing a `reduceMotion` check on the callout/annotation's own appearance animation (separate from the framework's built-in selection animation) — verify with Reduce Motion toggled on in Settings.
- [ ] **Chart scrubbing:** Often missing a decision test for the hero/headline card behavior during vs. after scrubbing — verify both states explicitly, including the release transition.
- [ ] **History transition:** Often missing verification against a real, non-trivial dataset (List materialization + `@Query` timing) — a Preview/mock-data pass alone is not sufficient.
- [ ] **History transition:** Often missing the third state (empty `ContentUnavailableView`) in the transition matrix — verify switching into/out of an empty history, not just List↔Calendar with data.
- [ ] **History transition:** Often missing correct, tested direction reversal (List→Calendar vs. Calendar→List going opposite ways) — verify by toggling back and forth, not just once.
- [ ] **Launch screen:** Often missing a genuine on-device, force-quit cold launch verification — a Simulator screenshot or warm relaunch does not prove this.
- [ ] **All three:** Often missing an actual-running `drinkpulseUITests` test (per CLAUDE.md, mandatory for user-facing changes) that pins a post-transition/post-interaction end state rather than asserting mid-animation.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|----------------|------------------|
| VoiceOver parity regression shipped (chart scrubbing without descriptor update) | LOW | Extend `accessibilityChartDescriptor` to include the interactive per-point values already computed for the visual callout; reuse existing formatting code — no data-model change needed |
| Slide transition glitches with real List/Calendar data discovered late | MEDIUM | Simplify to a single shared transition config (asymmetric move pair) driven from one place; consider deferring List's internal animations during the container-level transition window |
| `@Query` pop-in during transition discovered late | MEDIUM | Restructure to keep both branches resident (toggle visibility rather than identity) if feasible without regressing memory/perf; otherwise prefetch at a parent scope |
| Launch screen verified only in Simulator, later found wrong/blank on device | LOW | Re-check the asset reference and `Info.plist`/`UILaunchScreen` keys against `AppIcon.icon`; re-test cold launch on device — this is a config-only fix, not a rewrite |
| New XCUITest flaky in CI due to timing assumptions | LOW–MEDIUM | Replace fixed delays with `waitForExistence`/hittability waits per the existing documented pattern in CONCERNS.md ("Known UI Test Flakiness"); do not add new flakiness to an already-flagged area |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| VoiceOver parity gap on chart scrubbing | Insights chart-scrubbing phase | Manual VoiceOver pass on both charts confirming per-point values are announced; `drinkpulseUITests` covering the scrub gesture's visible outcome |
| reduceMotion inconsistently applied across chart callout / slide transition | Both feature phases individually | Manual toggle of Reduce Motion in Settings, tested against each new animated surface separately |
| Cross-container transition glitches (List vs ScrollView, real data) | History slide-transition phase | Device test with a realistic, non-trivial history dataset; explicit check of all three states (List, Calendar, empty) and both directions |
| `@Query` pop-in mid-transition | History slide-transition phase | Manual test switching segments immediately after add/delete/edit of an entry, on device |
| Launch screen verified only in Simulator | Launch-screen phase | Explicit device force-quit cold-launch check before marking done |
| Animation-timing-dependent UI test flakiness | All three phases, at test-authoring time | New tests use `waitForExistence`/hittability and pin end-state only; run the new tests in the full suite (not just isolated) to catch the cross-test flakiness already documented in CONCERNS.md |

## Sources

- [Making charts accessible with Swift Charts](https://www.createwithswift.com/making-charts-accessible-with-swift-charts/) — LOW confidence (community blog, not Apple docs directly), cross-checked against known `AXChartDescriptor` API shape
- [Mastering charts in SwiftUI: Accessibility — Swift with Majid](https://swiftwithmajid.com/2023/02/28/mastering-charts-in-swiftui-accessibility/) — LOW confidence, established SwiftUI author
- [iOS Accessibility in SwiftUI: Audio Graphs — Kodeco](https://www.kodeco.com/31561694-ios-accessibility-in-swiftui-create-accessible-charts-using-audio-graphs) — LOW confidence
- [Supporting Reduced Motion accessibility setting in SwiftUI — tanaschita.com](https://tanaschita.com/ios-accessibility-reduced-motion/) — LOW confidence, matches existing in-repo pattern at `OnboardingView.swift:80`
- [How to detect the Reduce Motion accessibility setting — Hacking with Swift](https://www.hackingwithswift.com/quick-start/swiftui/how-to-detect-the-reduce-motion-accessibility-setting) — LOW confidence, well-established reference site
- [Correct SwiftData Concurrency Logic — Apple Developer Forums](https://developer.apple.com/forums/thread/805409) — LOW confidence per source-hierarchy classification, but forum thread on Apple's own platform
- [Any way to force-refresh @Query properties in SwiftUI? — Apple Developer Forums](https://developer.apple.com/forums/thread/766671) — LOW confidence
- [Clean waiting in XCUITest — Source Diving](https://sourcediving.com/clean-waiting-in-xcuitest-43bab495230f) — LOW confidence
- [Dealing With Flaky UI Tests in iOS — Thuyen's Corner](https://trinhngocthuyen.com/posts/tech/dealing-with-flaky-ui-tests/) — LOW confidence
- [Using a Launch Screen Storyboard — Use Your Loaf](https://useyourloaf.com/blog/using-a-launch-screen-storyboard/) — LOW confidence, established iOS reference author
- [Animate Your iOS Splash Screen — Viget](https://www.viget.com/articles/animated-ios-launch-screen) — LOW confidence (pseudo-launch-screen workaround pattern)
- [Symmetrical and asymmetrical transitions in SwiftUI — Create with Swift](https://www.createwithswift.com/symmetrical-and-asymmetrical-transitions-in-swiftui-with-the-scroll-transition-modifier/) — LOW confidence
- Project-internal: `.planning/todos/pending/2026-07-26-scrub-insights-charts-for-per-point-values.md`, `.planning/todos/pending/2026-07-26-slide-transition-between-history-list-and-calendar.md`, `.planning/todos/pending/2026-07-27-branded-static-launch-screen.md`, `.planning/codebase/CONCERNS.md` — HIGH confidence (first-party project documents)

---
*Pitfalls research for: DrinkPulse v1.3 "Native Feel" milestone*
*Researched: 2026-07-28*
