# Phase 6: History List↔Calendar Directional Transition - Research

**Researched:** 2026-07-31
**Domain:** SwiftUI view transitions (`AnyTransition`, `withAnimation`, view identity) applied to two structurally different scroll containers (`List` vs `ScrollView`) on iOS 26
**Confidence:** MEDIUM-HIGH — the transition/animation API surface is fully verified against Apple's own DocC JSON (HIGH); the specific List/ScrollView interaction risk this phase exists to de-risk has **no authoritative Apple documentation that names it directly** — the best evidence is a first-party Apple DTS engineer forum reply about a structurally analogous problem (List's *own* item-animation machinery overriding custom transitions) plus SwiftUI-identity mechanics from reputable third-party sources (objc.io, sakunlabs). That gap is exactly why this phase is sequenced last and carries an explicit on-device verification gate — this research narrows the risk, it does not eliminate the need for that gate.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (Transition mechanism):** Primary approach is a common container around the existing `switch segment { case .list: listContent; case .calendar: calendarContent }` in `HistoryView.body`, using `.transition(.asymmetric(insertion: .move(edge:), removal: .move(edge:)))` keyed by `segment`, driven by `withAnimation` on segment change. `List` and `ScrollView` are treated as opaque subviews under a single transition — no snapshot/rendering hack as the first attempt.
- **D-02 (Fallback):** If native `.transition(.move)` shows visual bugs (layout pop, flash, `@Query` re-fetch flicker) during verification: switch to a snapshot-based crossfade (per ROADMAP.md's stated fallback). Plan the native approach first; only add crossfade as a gap-closure step if verification surfaces a real bug on-device — do not pre-emptively build both. **Reversibility:** costly — if crossfade becomes necessary, most of the `.transition`/`withAnimation` wiring in `HistoryView` gets replaced, not reused.
- **D-03 (Direction semantics):** Direction follows segmented-control spatial order: List is the left segment, Calendar is the right segment (`HistorySegment.allCases` = `[.list, .calendar]`). List→Calendar slides leftward (new content enters from the trailing/right edge); Calendar→List slides rightward (new content enters from the leading/left edge). Matches standard iOS segmented-control spatial convention — no fixed "forward/back" semantic independent of picker position.
- **D-04 (Reduce Motion):** With `accessibilityReduceMotion` enabled, segment switching is an instant cut — no slide animation at all. Reuse the existing `reduceMotion` ternary pattern established in `OnboardingView.swift` (`reduceMotion ? nil : .spring(...)` style) rather than introducing a new pattern.
- **D-05 (Empty state):** The empty state (`earliestEvent == nil`, shown inside `listContent`) participates in the same transition container as populated List/Calendar content — switching into or out of empty state slides directionally like any other segment content, no special-cased instant swap or bypass.

### Claude's Discretion

- Exact `@State` shape for tracking transition direction (e.g. a computed `Edge` derived from old/new `HistorySegment` comparison, or an explicit `@State private var transitionEdge: Edge`) — implementation wiring, resolve during planning.
- Whether the outer transition container needs an explicit `.id(segment)` on the `Group`/switch to force SwiftUI to treat list/calendar as distinct identities for the transition to fire correctly — technical detail for research/planning to confirm against SwiftUI's transition-identity rules. **Resolved by this research — see "Do I need `.id(segment)`?" below: no, it is redundant.**
- Whether `calendarNavHeader` (month prev/next chevrons) sits inside or outside the sliding container — reasonable to keep it inside `calendarContent` as today unless research finds a reason to hoist it. **This research finds no reason to hoist it — keep inside `calendarContent`.**

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HIST-01 | Switching the History segmented control between List and Calendar animates with a directional slide — list→calendar and calendar→list travel in opposite directions. | `AnyTransition.asymmetric(insertion:removal:)` + `AnyTransition.move(edge:)` confirmed via Apple DocC (see Code Examples); direction-tracking gotcha confirmed via Apple Developer Forums thread 749606 (see Common Pitfalls #1). |
| HIST-02 | The transition honors `accessibilityReduceMotion`. | `EnvironmentValues.accessibilityReduceMotion` confirmed via Apple DocC; existing `OnboardingView.swift` ternary pattern read directly and quoted verbatim (see Code Examples). |
| HIST-03 | All three states (list, calendar, empty) transition correctly with no layout pop or `@Query` re-fetch flash, verified with a real dataset on device. | List-vs-ScrollView structural-identity mechanics (objc.io, sakunlabs) explain *why* a full remount happens on every segment switch; Apple DTS forum thread 765198 confirms List's internal animation machinery is a documented friction point for custom transitions; `@Query(animation:)` DocC entry documents the first-party lever available if flicker appears — all feed the Common Pitfalls and Validation Architecture sections below. |
</phase_requirements>

## Summary

This phase wraps `HistoryView.body`'s existing `switch segment { }` with SwiftUI's built-in `AnyTransition` system — no new dependency, no custom rendering. `AnyTransition.asymmetric(insertion: .move(edge:), removal: .move(edge:))`, `View.transition(_:)`, and `withAnimation` are all stable, fully-documented SwiftUI APIs (iOS 13+, confirmed live on iOS 26) and require no adaptation for this project's iOS 26 floor. The `accessibilityReduceMotion` gate is a direct copy of the pattern already proven in `OnboardingView.swift` — same ternary shape, same environment key.

The one open technical question this research resolves: **does `.id(segment)` need to be added to force list/calendar to be treated as distinct identities for the transition to fire?** No. Two independent third-party sources (objc.io, sakunlabs — both citing SwiftUI's identity model directly) confirm that `switch`/`if` branches that resolve to different concrete view types (`List` vs `ScrollView`) — or even different *positions* in a `ViewBuilder`'s `buildEither` chain — already have distinct structural identity. SwiftUI treats a branch change as "old view removed, new view inserted" without any `.id()` needed; `.id()` is a tool for forcing identity changes *within* a single branch (e.g. resetting a view when a value changes), not for branches that are already distinct. Adding `.id(segment)` here would be redundant, not incorrect — it changes nothing about whether the transition fires.

The real risk this phase's own CONTEXT.md and ROADMAP.md correctly flag is different from an identity problem: because `List` and `ScrollView` are structurally different, **every switch back to `.list` fully reinitializes `HistoryListQueryView`, including its `@Query`.** This is expected SwiftUI/SwiftData behavior, not a bug — but it means the "no `@Query` re-fetch flicker" success criterion (HIST-03) is really asking "is a fresh local SwiftData fetch on view-init fast enough to be visually indistinguishable from cached content, while it's simultaneously sliding into place?" No source found — including Apple's own DTS engineers on a structurally similar List/SwiftData-animation thread — gives a general guarantee here; it can only be answered by the on-device verification this phase's plan already gates on (per D-02). This research substantiates *why* the risk is real (structural remount, not a hypothetical) without being able to substantiate whether it is *visible* in this app's actual data volumes — that remains genuinely a "verify on device" item, exactly as CONTEXT.md/ROADMAP.md already concluded before this research started.

**Primary recommendation:** Build D-01 exactly as decided — asymmetric `.move(edge:)` transition on the existing switch, `withAnimation` wrapping the `segment` mutation, `reduceMotion` ternary gate copied from `OnboardingView.swift`, no `.id(segment)`, `calendarNavHeader` stays inside `calendarContent`. The one addition this research recommends beyond CONTEXT.md's decisions: **set the direction `@State` in the same synchronous scope, before or atomically with the `segment` mutation** (see Pitfall #1) — do not derive direction lazily inside `body` from `oldValue`/`newValue` phase inspection without also verifying ordering, since a documented Apple Forums thread shows this exact "direction lags one switch behind" bug when direction-state and content-state updates are sequenced wrong.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Segment switch trigger (`Picker` selection) | Browser/Client (SwiftUI View) | — | Pure UI control state, already `@State private var segment` in `HistoryView` |
| Transition direction computation | Browser/Client (SwiftUI View) | — | Transient, per-interaction UI state; CLAUDE.md and ARCHITECTURE.md's own anti-pattern section explicitly forbid pushing this into `HistoryViewModel` (which has zero stored properties today) |
| Directional slide animation | Browser/Client (SwiftUI View) | — | `.transition`/`withAnimation` are View-layer concerns; no business logic involved |
| Reduce Motion gating | Browser/Client (SwiftUI View, via `@Environment`) | — | Accessibility environment read, same tier as the animation it gates |
| Data fetch during segment switch (`@Query` in `HistoryListQueryView`/`HistoryCalendarQueryView`) | Database/Storage (SwiftData) | Browser/Client (View re-render) | Explicitly OUT OF SCOPE for this phase per CONTEXT.md — "No changes to `HistoryListQueryView`, `HistoryCalendarQueryView`, ... — this phase wraps presentation, not data." Included in the map only because HIST-03's flicker risk originates here even though the fix (if needed) is presentation-tier (D-02's crossfade fallback), not data-tier. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `SwiftUI.AnyTransition` (`.move(edge:)`, `.asymmetric(insertion:removal:)`) | iOS 13.0+ (part of the SDK shipped with iOS 26 / Xcode 26.6) [VERIFIED: developer.apple.com/tutorials/data/documentation/swiftui/anytransition/move(edge:).json, developer.apple.com/tutorials/data/documentation/swiftui/anytransition/asymmetric(insertion:removal:).json] | Directional insertion/removal transitions on the `switch segment` branches | First-party, zero-dependency, exactly matches D-01's decided approach; both APIs confirmed live and unchanged since iOS 13, no iOS-26-specific deprecation found |
| `SwiftUI.View.transition(_:)` | iOS 17.0+ generic `Transition`-protocol overload; the `AnyTransition`-typed overload (`func transition(_ transition: AnyTransition) -> some View`) has shipped since iOS 13 and remains fully supported alongside the newer protocol — confirmed still functional, not deprecated [VERIFIED: developer.apple.com/tutorials/data/documentation/swiftui/view/transition(_:).json; CITED: multiple 2024-2025 SwiftUI-5/iOS-17 retrospectives (Medium/DevTechie) confirming `AnyTransition`-based `.transition(_:)` continues to work unchanged alongside the new `Transition` protocol] | Attaches the `AnyTransition` to each switch branch | Matches D-01 exactly — no need to adopt the newer `Transition` protocol (which is for *custom* transition types, not needed here) |
| `SwiftUI.withAnimation` | iOS 13.0+ | Wraps the `segment` state mutation so the transition actually animates | `.transition` alone does nothing without an animated transaction — confirmed by both the objc.io source and Apple's own `.transition(_:)` code sample, which wraps its toggle in `withAnimation { }` [VERIFIED: developer.apple.com/tutorials/data/documentation/swiftui/view/transition(_:).json code example] |
| `EnvironmentValues.accessibilityReduceMotion` | iOS 13.0+ | Reduce Motion gate for HIST-02 | [VERIFIED: developer.apple.com/tutorials/data/documentation/swiftui/environmentvalues/accessibilityreducemotion.json] — "If this property's value is true, UI should avoid large animations, especially those that simulate the third dimension." Already the exact pattern in use at `OnboardingView.swift:9,80,87` [VERIFIED: drinkpulse/Features/Onboarding/OnboardingView.swift:9,86-92 — read this session, quoted verbatim in Code Examples below] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `SwiftData.Query(animation:)` | iOS 17.0+ (SwiftData) | Optional first-party lever to animate `@Query` result changes instead of an instant snap | Only if the on-device verification gate (D-02) finds a visible `@Query`-driven pop *and* the team decides to touch `HistoryListQueryView`'s fetch config specifically for the animation parameter — note this would still be within "presentation, not data" scope since `animation:` doesn't change filter/sort/fetch semantics, only how result changes render. CONTEXT.md's stated scope boundary ("No changes to `HistoryListQueryView`... fetch logic") should be read as protecting the predicate/sort/window logic, not necessarily this display-only knob — flag for the planner to confirm with the user if it becomes relevant, since it's a boundary interpretation call, not a clear "in bounds" fact. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `.transition(.asymmetric(insertion: .move, removal: .move))` on the existing switch (D-01, chosen) | `matchedGeometryEffect`-based cross-fade between List/ScrollView | Already rejected by prior research (`.planning/research/STACK.md:47`) — `matchedGeometryEffect` is for morphing views that share layout geometry; List and ScrollView don't. **This research adds a further, iOS-26-specific reason to avoid matchedGeometryEffect/navigationTransition-zoom-style approaches near this feature**: an active, unresolved Apple regression (iOS 26.0–26.1, DTS-confirmed, no workaround) affects `.navigationTransition(.zoom())` + `matchedTransitionSource` with flicker and misaligned geometry [CITED: developer.apple.com/forums/thread/807208]. That regression is scoped to `navigationTransition`/`NavigationLink`, not plain sibling `.transition`, so it does not block D-01's approach — but it reinforces that matched-geometry-family APIs are the *more* fragile choice on iOS 26 right now, not the safer one. |
| Native `.transition` (try first) | Snapshot-based crossfade (D-02's fallback) | Crossfade sidesteps the List/ScrollView structural-remount question entirely (both views could stay resident, only opacity animates) at the cost of losing the directional slide feel HIST-01 asks for, unless combined with an offset animation on a wrapper. D-02 already scopes this correctly as "only if verification finds bugs." |
| Native `.transition` | `TabView(.page)` as the swap mechanism | Already rejected by prior research (`.planning/research/STACK.md:57`) — changes the interaction model to swipeable paging, not what was asked; the segmented `Picker` must remain the sole driver. |

**Installation:** None. All APIs are part of the SwiftUI/SwiftData frameworks already linked by the `drinkpulse` target — no `Package.swift`, SPM, or CocoaPods changes.

**Version verification:** Not applicable in the npm/pip/cargo sense — these are Apple SDK APIs, not versioned packages. Verified instead by direct fetch against Apple's live DocC JSON endpoints (see citations above) and cross-checked against this machine's installed toolchain: `xcodebuild -version` → Xcode 26.6, Build 17F113 [VERIFIED: `xcodebuild -version` run this session].

## Package Legitimacy Audit

Not applicable — this phase installs no external packages. All APIs used are first-party Apple SDK frameworks (`SwiftUI`, `SwiftData`) already linked by the target. No `npm view` / `pip index` / `cargo search` equivalent exists for Apple SDK symbols; verification was done instead against Apple's own DocC JSON documentation endpoints (see Sources).

## Architecture Patterns

### System Architecture Diagram

```
User taps segmented-control option (Picker bound to $segment)
    │
    ▼
segment: HistorySegment mutates ("list" ↔ "calendar")
    │
    ├──▶ direction @State computed from (oldSegment, newSegment) — SAME
    │    synchronous scope as the segment mutation (see Pitfall #1)
    │
    ▼
withAnimation(reduceMotion ? nil : .someAnimation) {
    segment = newValue   // triggers body re-render
}
    │
    ▼
HistoryView.body: Group { switch segment {
    case .list:      listContent      ──▶ [populated: HistoryListQueryView (List, @Query)]
                                       ──▶ [empty:     emptyState (ContentUnavailableView)]
    case .calendar:  calendarContent  ──▶ ScrollView { calendarNavHeader; HistoryCalendarQueryView (@Query) }
} }
.transition(.asymmetric(insertion: .move(edge: computed), removal: .move(edge: computed)))
    │
    ▼
SwiftUI diffs the two ViewBuilder branches: different concrete types (List vs ScrollView)
→ old branch REMOVED (removal transition), new branch INSERTED (insertion transition)
→ inserted branch's @Query re-evaluates on fresh init (List → HistoryListQueryView re-fetches;
  Calendar → HistoryCalendarQueryView re-fetches)
    │
    ▼
Rendered frame: directional slide visible; verify NO layout pop / flash / @Query-flicker
   on a real device with real data volumes (HIST-03 gate — cannot be fully verified in Preview)
```

### Recommended Project Structure

No new files required for the core mechanism — this is a body-only change to the existing `HistoryView.swift` (currently 223 lines [VERIFIED: `wc -l drinkpulse/Features/History/HistoryView.swift` run this session], well under the 300-line ceiling). If the transition/direction logic pushes the file close to the ceiling after implementation, extract per CLAUDE.md's file-size rules:

```
Features/History/
├── HistoryView.swift              # body wraps switch with .transition; owns segment @State + new direction @State
├── HistorySegment.swift           # unchanged — allCases order is the source of truth for direction (D-03)
├── HistoryListQueryView.swift     # unchanged (out of scope per CONTEXT.md)
├── HistoryCalendarQueryView.swift # unchanged (out of scope per CONTEXT.md)
└── Components/                    # only if extraction becomes necessary post-implementation
```

### Pattern 1: Asymmetric directional transition keyed by enum comparison

**What:** Compute an `Edge` (or two, for insertion/removal) by comparing the previous and new `HistorySegment`, then apply `.transition(.asymmetric(insertion: .move(edge: insertionEdge), removal: .move(edge: removalEdge)))` to the `Group` wrapping the switch.
**When to use:** Exactly this phase's scenario — two (or more) sibling branches in a switch, where the desired slide direction depends on which branch was previously active, not a fixed direction.
**Example (pattern, not verbatim library code — composed from the verified API signatures above):**
```swift
// Source: composed from developer.apple.com DocC entries for
// AnyTransition.move(edge:), AnyTransition.asymmetric(insertion:removal:),
// and View.transition(_:) — all VERIFIED this session (see Sources)
@State private var segment: HistorySegment = .list
@State private var insertionEdge: Edge = .trailing
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var body: some View {
    VStack(spacing: 0) {
        segmentPickerRow
        Group {
            switch segment {
            case .list:     listContent
            case .calendar: calendarContent
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: insertionEdge),
            removal: .move(edge: insertionEdge == .trailing ? .leading : .trailing)
        ))
    }
}

private func selectSegment(_ new: HistorySegment) {
    // Direction is computed and the animated mutation happens in the SAME
    // synchronous call — see Pitfall #1 for why deferring this ordering
    // (e.g. via .onChange + Task) produces a one-switch-behind direction bug.
    insertionEdge = (new == .calendar) ? .trailing : .leading
    if reduceMotion {
        segment = new
    } else {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            segment = new
        }
    }
}
```
Note: `Picker(selection: $segment)` as currently implemented does not route through a function — planning should decide whether to convert it to a `Picker(selection: Binding(get:set:))` that calls `selectSegment`, or use `.onChange(of: segment)` with careful ordering (see Pitfall #1) to compute direction before the animated transaction is committed.

### Anti-Patterns to Avoid

- **Computing transition direction inside `body` from a freshly-read `oldValue` without controlling *when* it's read relative to the animated mutation:** produces the exact "direction lags/misfires on alternating switches" bug documented in a real Apple Developer Forums thread (see Pitfall #1). Direction must be settled synchronously with (or before) the `withAnimation` block that mutates `segment`.
- **Reaching for `matchedGeometryEffect` or `navigationTransition(.zoom())`-family APIs for this feature:** already rejected by prior project research for structural reasons (List/ScrollView don't share matched geometry); this research adds that these API families also carry an active, unresolved iOS 26 regression [CITED: developer.apple.com/forums/thread/807208], making them a strictly worse choice right now even setting the structural mismatch aside.
- **Adding `.id(segment)` "just to be safe":** redundant per this research's identity findings — costs nothing functionally in this exact case (branches are already structurally distinct) but adds a maintenance-signal red herring suggesting identity is fragile here when it isn't. Omit unless a specific on-device bug is found that only `.id()` fixes (not predicted by any source found).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Directional slide between two states | Custom `GeometryReader` + manual `.offset(x:)` drag/animation math | `AnyTransition.asymmetric(insertion: .move(edge:), removal: .move(edge:))` | First-party API does exactly this; hand-rolled offset math would also need to separately solve the Reduce Motion gate, animation curve matching, and interruption/interrupt-safety that `withAnimation`+`.transition` already provide for free |
| Reduce Motion gating | A second ad-hoc accessibility check pattern | The existing `reduceMotion ? nil : .someAnimation` ternary at `OnboardingView.swift:80` (quoted below) | CLAUDE.md's own conventions and this phase's D-04 explicitly mandate reusing the established pattern, not inventing a second one |

**Key insight:** every primitive this phase needs already exists in the SDK and is already proven working elsewhere in this exact codebase (`OnboardingView.swift`'s reduceMotion pattern). The actual engineering risk in this phase is not "which API to call" — it's whether the two structurally different scroll containers produce a visually clean result when swapped via that API, which no amount of API research can fully answer ahead of an on-device check.

## Common Pitfalls

### Pitfall 1: Direction state and content state must be mutated in the same synchronous step

**What goes wrong:** If the "previous segment" or "direction" tracking is computed lazily — e.g., inside a `.onChange(of: segment) { old, new in ... }` closure that updates a `direction` `@State` *after* `segment` has already changed and re-rendered once — the transition can apply the *previous* switch's direction to the *current* switch, so alternating List→Calendar→List→Calendar shows the second and later transitions sliding the wrong way (works correctly going one direction repeatedly, breaks on direction reversal).
**Why it happens:** SwiftUI evaluates the `.transition()` modifier's current value (here, the computed edge) at the moment the animated transaction is committed. Apple Developer Forums thread 749606 documents this exact failure mode in a structurally identical scenario (paginated question navigation with asymmetric transitions): "Next" repeatedly worked, but switching to "Previous" applied the wrong direction because the outgoing view's transition was assigned before the direction state had settled [CITED: developer.apple.com/forums/thread/749606]. The forum's own suggested fix — updating the direction state first, then deferring the content-index mutation via `Task { }` — is explicitly described by the responder as "imperative... uncertainty about Task closure execution timing guarantees... a workaround rather than an ideal solution," so it should not be copied verbatim; it is evidence the ordering problem is real, not a prescription.
**How to avoid:** Compute the direction and mutate `segment` in the *same* function/synchronous scope, both inside (or both immediately preceding) the same `withAnimation { }` block, as shown in the Pattern 1 code example above — do not split "read old segment, compute direction" and "commit new segment" across two separate SwiftUI update cycles (e.g., don't put the direction computation in `.onChange` while the `Picker` binding independently drives `segment`).
**Warning signs:** Manual QA that only tests one direction (e.g., only ever tapping List→Calendar→List→Calendar in that fixed order) will not catch this — it must specifically be tested with an *alternating* or *reversed* sequence of taps, which the existing `test_segmentSwitch_togglesListAndCalendar` UI test already happens to do (List→Calendar→List) but does not assert *direction*, only end-state content (XCUITest cannot assert mid-animation frames, confirmed by prior project research — `.planning/research/ARCHITECTURE.md:103`).

### Pitfall 2: List↔ScrollView switch causes a full `@Query` remount on every switch — this is expected, not a bug, but it is the mechanism behind HIST-03's risk

**What goes wrong:** Every time `segment` flips back to `.list`, `HistoryListQueryView` (and its `@Query private var events`) is destroyed and freshly reinitialized — the `@Query` re-runs its fetch from scratch, not from any cached prior state. If that fetch (plus the `vm.groupedByDay(events)` grouping work, plus `List` row layout) takes any perceptible time on a real device with a realistic dataset size, it can be visible mid-slide as a pop/flash of unstyled or empty content, or as content that "completes" partway through the animation instead of arriving fully formed.
**Why it happens:** `List` and `ScrollView` are different concrete view types; SwiftUI's `ViewBuilder` treats different `switch`-case branches as distinct structural identities regardless of whether the underlying types match [CITED: objc.io "Transitions in SwiftUI" (2022-04-14); sakunlabs "SwiftUI: Understanding identity via transitions"] — so a branch change is always a remove+insert, never an in-place update. This is confirmed as a known friction point in a structurally adjacent scenario by an Apple DTS engineer: "SwiftUI List is supposed to automatically manage the animation of its items when they are inserted or deleted. I don't see a good way that allows you to use SwiftUI List with your own animation" [CITED: developer.apple.com/forums/thread/765198] — that thread is about *row-level* animation inside a List conflicting with custom transitions (not this phase's *container-level* swap), but it is first-party confirmation that List's animation behavior is not fully "just another view" from SwiftUI's transition system's point of view, reinforcing why this needs on-device verification rather than being assumed safe from API docs alone.
**How to avoid:** This cannot be avoided while staying in CONTEXT.md's scope (no changes to `HistoryListQueryView`'s fetch logic) — it can only be *verified as fast enough to be invisible* on a real device with the dataset sizes the app actually sees, per D-02's plan (native first, crossfade fallback only if verification finds a real bug). If verification does find a visible pop, the two lowest-risk remediation options — in order of how much D-01 wiring they preserve — are: (a) `SwiftData.Query(animation:)` on `HistoryListQueryView`'s existing `@Query` declaration to animate the *result* rendering rather than snapping it in (a display-only knob, arguably still "presentation not data" per CONTEXT.md's boundary — flag for user confirmation if pursued, see Supporting Libraries note above), or (b) D-02's crossfade fallback, which sidesteps the remount visibility question by keeping content resident and only animating opacity/offset of a wrapper.
**Warning signs:** Any visible "blank list flashes then rows pop in" during the slide, especially with larger seeded datasets (the existing UI tests seed exactly one event via `-dp_uitest YES`, which is too small a dataset to surface this risk — CLAUDE.md's own HIST-03 wording explicitly calls for "a real dataset on a real device," not the single-event UI-test fixture).

### Pitfall 3: `.transition` requires an animated transaction — a bare state mutation renders instantly with no slide at all

**What goes wrong:** If `segment = newValue` is set outside of `withAnimation { }` (or without an `.animation(_:value:)` modifier attached), the `.transition()` modifier is present but has no effect — the switch happens instantly, silently failing HIST-01 with no error or warning.
**Why it happens:** Confirmed directly in Apple's own DocC example for `View.transition(_:)`: the sample code explicitly wraps the state toggle in `withAnimation { isActive.toggle() }`, and the discussion text states the transition "will be applied... allowing for animating it in and out" only in that animated context [VERIFIED: developer.apple.com/tutorials/data/documentation/swiftui/view/transition(_:).json]. SwiftUI-Lab's advanced-transitions guide independently confirms this pattern has been necessary "since Xcode 11.2" — implicit/bare animations do not reliably drive transitions [CITED: swiftui-lab.com/advanced-transitions/].
**How to avoid:** Always mutate `segment` inside `withAnimation(reduceMotion ? nil : .someCurve) { }`, exactly matching D-04's required reuse of `OnboardingView.swift`'s `animatedStep` pattern (quoted verbatim below).
**Warning signs:** Segment content changes but with a hard cut, even though `.transition()` is correctly attached to the `Group`.

## Code Examples

Verified patterns from official sources and this codebase (read this session):

### Existing Reduce Motion ternary pattern (reuse verbatim per D-04)

```swift
// Source: drinkpulse/Features/Onboarding/OnboardingView.swift:9,86-92
// [VERIFIED: read this session — lines quoted exactly]
@Environment(\.accessibilityReduceMotion) private var reduceMotion

private func animatedStep(_ action: () -> Void) {
    if reduceMotion {
        action()
    } else {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { action() }
    }
}
```

### `View.transition(_:)` — Apple's own usage example

```swift
// Source: developer.apple.com/documentation/swiftui/view/transition(_:)
// [VERIFIED via DocC JSON this session]
if isActive {
    MyView()
        .transition(RotatingFadeTransition())
}
Button("Toggle") {
    withAnimation {
        isActive.toggle()
    }
}
```
(Note: the project's own D-01 uses the older, still-fully-supported `AnyTransition`-typed overload of `.transition(_:)` rather than the custom-`Transition`-protocol form shown above — the animated-transaction requirement is identical for both overloads.)

### `AnyTransition.asymmetric` and `.move(edge:)` signatures

```swift
// Source: developer.apple.com DocC JSON for AnyTransition.asymmetric(insertion:removal:)
// and AnyTransition.move(edge:) — [VERIFIED this session]
static func asymmetric(insertion: AnyTransition, removal: AnyTransition) -> AnyTransition
static func move(edge: Edge) -> AnyTransition
```

### Existing switch this phase wraps (unmodified structure)

```swift
// Source: drinkpulse/Features/History/HistoryView.swift:64-79
// [VERIFIED: read this session — lines quoted exactly]
var body: some View {
    VStack(spacing: 0) {
        segmentPickerRow
        Group {
            switch segment {
            case .list:
                listContent
            case .calendar:
                calendarContent
            }
        }
    }
    .navigationTitle(String(localized: "tab.history"))
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $editingEvent) { EditEventView(event: $0) }
}
```

### `HistorySegment` — direction source of truth (D-03)

```swift
// Source: drinkpulse/Features/History/HistorySegment.swift:1-12 (full file)
// [VERIFIED: read this session — lines quoted exactly]
enum HistorySegment: String, CaseIterable {
    case list, calendar

    var label: String {
        switch self {
        case .list:     return String(localized: "history.segment.list")
        case .calendar: return String(localized: "history.segment.calendar")
        }
    }
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `AnyTransition`-typed `.transition(_:)` as the only transition mechanism | `Transition` protocol (custom `TransitionPhase`-based transitions) added alongside it | iOS 17 / SwiftUI 5 (2023) [CITED: multiple 2024-2025 retrospective articles] | Not relevant to this phase's decided approach (D-01 uses `AnyTransition`, which remains fully supported) — noted only so the planner doesn't mistake `AnyTransition` for a deprecated path. |

**Deprecated/outdated:** Nothing found relevant to this phase's chosen APIs. `AnyTransition.move(edge:)`, `.asymmetric(insertion:removal:)`, `.identity`, and the `AnyTransition`-typed `View.transition(_:)` overload all remain current, undeprecated iOS SDK API as of Xcode 26.6 per direct DocC verification this session.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `SwiftData.Query(animation:)` display-only animation knob would still count as "presentation, not data" under CONTEXT.md's scope boundary, rather than "changes to fetch logic." | Standard Stack (Supporting), Pitfall 2 | Low — flagged explicitly as a boundary-interpretation call requiring user confirmation before use, not presented as settled. If wrong, the planner should treat this remediation option as off-limits and rely solely on D-02's crossfade fallback. |
| A2 | The two ViewBuilder-branch-identity sources (objc.io, sakunlabs) generalize correctly to this project's specific `Group { switch segment { case .list: listContent; case .calendar: calendarContent } }` shape, where `listContent`/`calendarContent` are themselves computed `some View` properties (not raw `List`/`ScrollView` literals inline in the switch). | Summary, Architecture Patterns, Pitfall 2 | Medium — if SwiftUI's identity inference behaves differently through an intermediate computed-property indirection than through inline branch literals, the "no `.id()` needed" conclusion could be wrong for this specific code shape. No source tested this exact shape (computed property returning `some View` as a switch-case body). **Recommend the planner add an explicit on-device check for this specific point** (does the transition fire at all without `.id()`, given the extra indirection) as part of the same verification pass D-02 already requires — cheap to check, and directly falsifiable in minutes if wrong. |

**If this table is empty:** N/A — two assumptions logged above; both are already flagged for on-device confirmation as part of this phase's existing verification gate, so they add no new verification burden beyond what D-02 already requires.

## Open Questions

1. **Does the naive `.transition(.asymmetric(.move))` produce a visually clean slide on a real device with real data volumes, or does it surface the List/ScrollView pop HIST-03 warns about?**
   - What we know: The transition API itself is correct and will fire (confirmed via identity mechanics + Apple's own docs). The @Query remount on every List re-entry is real and expected (Pitfall 2).
   - What's unclear: Whether that remount's latency is perceptible on real hardware with the app's actual dataset sizes — no source (including Apple DTS) makes a general claim either way, because it depends on data volume, device generation, and List row complexity, none of which are knowable from documentation.
   - Recommendation: This is precisely what D-02's "plan native first, verify on-device, fall back to crossfade only if a real bug appears" strategy already exists to answer. No further research can resolve this — it requires running the built feature. The planner should make the on-device verification step (real dataset, real device, both directions of switch, multiple times, near the empty-state boundary too per D-05) an explicit, named checkpoint in the plan, not an implicit "should be fine" assumption.

2. **Does `Picker(selection: $segment)` (a direct two-way binding) fit Pitfall 1's "compute direction synchronously with the mutation" requirement, or does it need to be converted to a custom `Binding(get:set:)` / intercepted via `.onChange` with careful ordering?**
   - What we know: The current code binds `Picker(selection: $segment)` directly (`HistoryView.swift:82`) — there is no intermediate function call today. Pitfall 1 shows a *closure-based* selection handler avoids the ordering bug; a raw `Binding` has no such hook by default.
   - What's unclear: Whether `.onChange(of: segment) { old, new in ... }` (available iOS 17+, well within the iOS 26 floor) — which does receive both old and new values synchronously — is sufficient by itself, or whether it still needs to wrap the *next* frame's transition assignment carefully to avoid the one-cycle-lag bug the forum thread describes for a similar (but not identical — that thread used a manually-incremented index, not a `Picker` binding) setup.
   - Recommendation: Planning should treat "how exactly does `segment`'s mutation get instrumented to compute direction with correct ordering" as a concrete design decision to make at plan-writing time, using `.onChange(of: segment) { old, new in withAnimation { ... } }` as the most idiomatic candidate (it gives both values synchronously, unlike a bare `didSet`-style side channel) — and to explicitly test the alternating-direction scenario from Pitfall 1 during implementation, not just once each direction.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Xcode | Build/test the feature | ✓ | 26.6 (Build 17F113) [VERIFIED: `xcodebuild -version` run this session] | — |
| iOS Simulator (iPhone 17 Pro) | `xcodebuild test` per CLAUDE.md's build/verify commands | ✓ | Present, currently Shutdown state [VERIFIED: `xcrun simctl list devices available` run this session] | — |
| Real iOS 26 device | HIST-03's mandatory real-device verification ("verified with a real dataset on a real device") | Not verifiable from this environment — presence of a physical device cannot be probed via shell tooling | — | None — this is a hard requirement stated directly in the phase's own success criteria and cannot be waived or simulated; the plan must include an explicit real-device checkpoint, not a simulator-only one. |

**Missing dependencies with no fallback:**
- Real physical iOS 26 device for the HIST-03 verification pass — this is a process/access requirement, not a tooling one; flag for the plan's checkpoint step, consistent with how Phase 4's launch-screen work in this same milestone already required real-device-only verification.

**Missing dependencies with fallback:**
- None beyond the above.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | XCTest (UI tests) + XCTest/Swift Testing (unit tests) — project standard per CLAUDE.md |
| Config file | None — scheme-based (`drinkpulse` scheme), `PBXFileSystemSynchronizedRootGroup` targets, no separate test config file |
| Quick run command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/HistoryInteractionUITests` |
| Full suite command | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HIST-01 | Segment switch shows correct end-state content in both directions (List→Calendar→List) | UI (end-state only — XCUITest cannot assert mid-animation frames per prior project research) | `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/HistoryInteractionUITests/test_segmentSwitch_togglesListAndCalendar` | ✅ Exists — `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift:54-81` [VERIFIED: read this session] already asserts List→Calendar→List end states; needs extension (not a new file) to also cover the *direction alternation* scenario from Pitfall 1 (e.g. Calendar→List→Calendar, not just the existing List-first sequence) |
| HIST-01 (direction-correctness specifically) | Slide direction is visually correct and doesn't invert on alternating switches | Manual-only — XCUITest genuinely cannot assert animation direction/frame content mid-transition; this is an inherent limitation of the tool, not a gap to close with more automation | Manual real-device pass per D-02's verification gate | N/A — manual by necessity |
| HIST-02 | Reduce Motion produces an instant cut, no slide | UI, via launch argument toggling `UIAccessibility.isReduceMotionEnabled` simulation OR manual (XCUITest has no first-party way to toggle system Reduce Motion at runtime; existing project pattern for reduceMotion-gated behavior should be checked for precedent) | TBD — planner should check whether any existing test (e.g. for `OnboardingView`'s reduceMotion-gated stepDots) already has a working pattern for testing this in this codebase, since none was found for HIST-02 by this research | ❌ Wave 0 — no existing UI test found that exercises `accessibilityReduceMotion` end-to-end; if XCUITest cannot drive this reliably, this becomes manual-only with justification, consistent with CLAUDE.md's `feedback_uitest_bug_policy` guidance that BAC/guideline/sync-class risk always escalates to manual — Reduce Motion is an accessibility requirement, not that class, but still worth a manual pass given the automation gap |
| HIST-03 | No layout pop/flash/`@Query` flicker across List, Calendar, empty state, real dataset, real device | Manual-only, explicitly per the requirement's own wording ("verified with a real dataset on a real device") | Manual real-device pass; the existing `-dp_uitest YES` seed (single event) is too small to exercise this — plan should note a larger, more realistic seed for this specific manual pass, distinct from the existing UI-test fixture | N/A — manual by requirement's own design |

### Sampling Rate

- **Per task commit:** `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:drinkpulseUITests/HistoryInteractionUITests`
- **Per wave merge:** `xcodebuild test -scheme drinkpulse -destination 'platform=iOS Simulator,name=iPhone 17 Pro'` (full suite)
- **Phase gate:** Full suite green, plus the two manual-only checkpoints above (direction-correctness on alternating switches; HIST-03's real-device/real-dataset pass), before `/gsd-verify-work`.

### Wave 0 Gaps

- [ ] Extend `drinkpulseUITests/Features/History/HistoryInteractionUITests+Helpers.swift` / `HistoryInteractionUITests.swift` — add an alternating-direction assertion (Calendar→List→Calendar, not just the existing List-first sequence) to close the gap Pitfall 1 identifies; still end-state-only per XCUITest's mid-animation limitation, but exercises the code path most likely to expose the direction-lag bug.
- [ ] Decide (during planning, not research) whether HIST-02's Reduce Motion gate can be exercised via any existing project convention for simulating `accessibilityReduceMotion` in XCUITest, or whether it is manual-only — no existing precedent was found in this codebase for automating this specific environment toggle.
- [ ] No new unit-test file identified as required — this phase's changes are presentation-only inside `HistoryView.swift`'s `body`/state, with no new pure-function logic; `HistoryViewModel` is explicitly not being touched (CONTEXT.md's own anti-pattern guidance and ARCHITECTURE.md's finding that it has zero stored properties today) so no incremental unit-test coverage target beyond what `HistoryViewModelTests.swift` already covers.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Not applicable — no auth surface in this app (CLAUDE.md: "no account ever required") |
| V3 Session Management | No | Not applicable |
| V4 Access Control | No | Not applicable — single-user, on-device |
| V5 Input Validation | No | This phase reads and animates existing, already-validated `ConsumptionEvent`/`UserProfile` data via unmodified `@Query`s; no new user input surface is introduced |
| V6 Cryptography | No | Not applicable |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| None identified specific to this phase | — | This phase is a pure presentation-layer animation change over already-fetched, already-on-device health data (`ConsumptionEvent`s). No network calls, no new data surfaces, no logging of user data are introduced (CLAUDE.md's "on-device only" and "never log PII/health data" rules are unaffected by an animation/transition change). The only privacy-adjacent consideration is indirect: CLAUDE.md forbids logging drink contents/timestamps — this phase's implementation must not add any `os.Logger` calls that log `ConsumptionEvent` contents while debugging the transition/animation behavior, but this is a general project rule, not a new threat this phase introduces. |

## Sources

### Primary (HIGH confidence)

- `developer.apple.com/tutorials/data/documentation/swiftui/view/transition(_:).json` — `View.transition(_:)` abstract, discussion, code example, availability (fetched and quoted this session)
- `developer.apple.com/tutorials/data/documentation/swiftui/anytransition/asymmetric(insertion:removal:).json` — signature, parameters, availability (fetched this session)
- `developer.apple.com/tutorials/data/documentation/swiftui/anytransition/move(edge:).json` — signature, parameters, availability, related transitions list (fetched this session)
- `developer.apple.com/tutorials/data/documentation/swiftui/environmentvalues/accessibilityreducemotion.json` — abstract, discussion, availability (fetched this session)
- `developer.apple.com/tutorials/data/documentation/swiftui/view/animation(_:value:).json` — signature, discussion (fetched this session)
- `developer.apple.com/forums/thread/749606` — Apple Developer Forums thread on direction-switching transition bug with a fielded response; direct evidence for Pitfall 1 (fetched and summarized this session)
- `developer.apple.com/forums/thread/765198` — Apple Developer Forums thread with an Apple DTS engineer's confirmation that List's built-in animation management conflicts with custom transitions on inserted/deleted items; supports Pitfall 2 (fetched and summarized this session)
- `developer.apple.com/forums/thread/807208` — Apple Developer Forums thread confirming an active, DTS-acknowledged iOS 26.0–26.1 regression scoped to `navigationTransition(.zoom())`/`matchedTransitionSource`, with no workaround; supports the "avoid matched-geometry-family APIs on iOS 26 for this feature" guidance in Alternatives Considered (fetched and summarized this session)
- Direct reads of `drinkpulse/Features/History/HistoryView.swift`, `HistorySegment.swift`, `HistoryListQueryView.swift`, `HistoryCalendarQueryView.swift`, `Features/Onboarding/OnboardingView.swift`, `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` and `+Helpers.swift` — all read this session, quoted verbatim where cited
- `xcodebuild -version` and `xcrun simctl list devices available` — run this session, confirms Xcode 26.6 / iPhone 17 Pro simulator availability

### Secondary (MEDIUM confidence)

- `www.objc.io/blog/2022/04/14/transitions/` — "Transitions in SwiftUI": render-tree vs. view-tree identity model, `.id()` mechanics, container-wrapping stability tip (fetched and summarized this session)
- `sakunlabs.com/blog/swiftui-identity-transitions/` — structural vs. explicit identity, confirms structurally different container swaps trigger transitions without `.id()` (fetched and summarized this session)
- `swiftui-lab.com/advanced-transitions/` — confirms `withAnimation`/explicit-animation requirement for reliable transitions since Xcode 11.2 (fetched and summarized this session)
- WebSearch-aggregated results on `AnyTransition`/`Transition` protocol coexistence post-iOS 17 (multiple 2024-2025 Medium/DevTechie articles, cross-checked against the DocC availability data above rather than trusted standalone)

### Tertiary (LOW confidence)

- WebSearch snippet summaries on `@Query(animation:)` general behavior (Hacking with Swift article referenced by title/URL but returned HTTP 403 on direct fetch; content triangulated from WebSearch's own summary plus the official DocC-adjacent `init(_:animation:)` page reference, not independently verified against the DocC JSON directly — flagged here rather than promoted to Primary)
- General WebSearch summaries on "SwiftUI segmented picker slide" prior art (Medium article on `matchedGeometryEffect`-based picker animation) — used only to confirm that `matchedGeometryEffect` is a commonly reached-for tool for adjacent problems, not adopted as guidance for this phase (already rejected per Alternatives Considered)

## Metadata

**Confidence breakdown:**
- Standard stack (API existence/signatures/availability): HIGH — every API cited was fetched directly from Apple's own DocC JSON endpoints this session, not inferred from training data or third-party paraphrase.
- Architecture/identity mechanics (why no `.id()` needed): MEDIUM — well-supported by two independent, reputable third-party sources with consistent explanations, but not directly confirmed against an Apple-authored document that names this exact scenario (switch-branch identity for transitions); flagged as Assumption A2 for the specific computed-property-indirection shape used in this codebase.
- List/ScrollView container-mismatch risk (HIST-03's core concern): MEDIUM — real, well-evidenced *mechanism* (structural remount + a first-party-confirmed List/custom-animation friction point in an adjacent scenario), but genuinely LOW confidence on the actual *outcome* (visible or not) for this app's real data — no source, including Apple's own DTS engineers, makes a general claim resolving this, which is exactly why the phase's own decisions (D-01/D-02) already gate on real-device verification rather than trusting research to settle it.
- Pitfalls: HIGH for Pitfall 1 and 3 (both directly evidenced by Apple's own forums/docs), MEDIUM for Pitfall 2 (mechanism confirmed, magnitude unconfirmed).

**Research date:** 2026-07-31
**Valid until:** 30 days (stable, mature SwiftUI APIs; the one genuinely time-sensitive item — the iOS 26.0–26.1 `navigationTransition` regression cited in Alternatives Considered — should be re-checked if this phase is executed more than a few weeks out, since Apple may ship a point-release fix that changes its relevance, though it does not block this phase's chosen approach either way).
