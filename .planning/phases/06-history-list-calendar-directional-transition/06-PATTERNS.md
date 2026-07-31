# Phase 6: History List↔Calendar Directional Transition - Pattern Map

**Mapped:** 2026-07-31
**Files analyzed:** 2 (1 modified source file, 1 modified test file)
**Analogs found:** 2 / 2

This phase is unusually self-contained: the primary "analog" for the new
code is another part of the **same file** (`HistoryView.swift`'s own
existing `switch segment` block) plus one cross-feature reuse
(`OnboardingView.swift`'s `reduceMotion` ternary). No new files are
created — CONTEXT.md and RESEARCH.md both confirm this is a body-only
change. `HistoryListQueryView.swift` and `HistoryCalendarQueryView.swift`
are explicitly out of scope (not modified).

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `drinkpulse/Features/History/HistoryView.swift` (`body`, new `@State`/helper) | component (SwiftUI View) | request-response (state-driven re-render, no async I/O) | `drinkpulse/Features/Onboarding/OnboardingView.swift` (`animatedStep` + `reduceMotion` pattern) | role-match (both are `@Observable`-free, `@State`-driven SwiftUI views with an animated-transition-on-state-change shape) |
| `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` (`test_segmentSwitch_togglesListAndCalendar`, extended) | test (XCUITest) | request-response (drive UI, assert end-state) | itself — extend the existing test in place | exact (same file, same test, add an alternating-direction assertion block) |

No new files are created. `HistorySegment.swift` (enum, source of truth
for `allCases` order / D-03) is read but not modified.

## Pattern Assignments

### `drinkpulse/Features/History/HistoryView.swift` (component, request-response)

**Primary analog for the transition/animation wiring:** `drinkpulse/Features/Onboarding/OnboardingView.swift`

**Secondary analog for the switch being wrapped:** `HistoryView.swift` itself, current `body` (lines 64-79) — this is the exact code the plan will modify, not copy from elsewhere.

**Imports pattern** (`HistoryView.swift` lines 1-2, unchanged — no new imports needed):
```swift
import SwiftUI
import SwiftData
```
`Edge` and `AnyTransition`/`withAnimation` are part of `SwiftUI`, already imported. No new import required.

**Reduce Motion ternary pattern to reuse verbatim** (`OnboardingView.swift` lines 9, 86-92):
```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion
...
private func animatedStep(_ action: () -> Void) {
    if reduceMotion {
        action()
    } else {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { action() }
    }
}
```
Apply this exact shape to `HistoryView.swift`: add the same `@Environment(\.accessibilityReduceMotion) private var reduceMotion` property and a private helper (e.g. `selectSegment(_:)`) with the identical `if reduceMotion { action() } else { withAnimation(...) { action() } }` structure — do not invent a new gating idiom (D-04 requires reuse).

**Existing switch being wrapped — current code, to be modified in place** (`HistoryView.swift` lines 64-79):
```swift
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
Target shape (per RESEARCH.md's Pattern 1, composed from Apple's `AnyTransition.move(edge:)` / `.asymmetric(insertion:removal:)` DocC signatures — no direct codebase analog exists for the transition modifier itself since this is new ground):
```swift
@State private var insertionEdge: Edge = .trailing
@Environment(\.accessibilityReduceMotion) private var reduceMotion

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
        .transition(.asymmetric(
            insertion: .move(edge: insertionEdge),
            removal: .move(edge: insertionEdge == .trailing ? .leading : .trailing)
        ))
    }
    .navigationTitle(String(localized: "tab.history"))
    .navigationBarTitleDisplayMode(.inline)
    .sheet(item: $editingEvent) { EditEventView(event: $0) }
}
```

**Existing `Picker` binding to intercept for direction computation** (`HistoryView.swift` lines 81-91):
```swift
private var segmentPickerRow: some View {
    Picker(String(localized: "history.segment.picker"), selection: $segment) {
        ForEach(HistorySegment.allCases, id: \.self) { s in
            Text(s.label).tag(s)
        }
    }
    .pickerStyle(.segmented)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(.bar)
}
```
Per RESEARCH.md Open Question 2 and Pitfall 1, this binding needs an
interception point that computes `insertionEdge` and mutates `segment`
in the *same* synchronous scope (either via `.onChange(of: segment) { old, new in ... }`
added to this view, or converting `selection: $segment` to a custom
`Binding(get:set:)` that calls a `selectSegment(_:)` helper mirroring
`animatedStep`). Do not split direction computation from the mutation
across separate update cycles.

**Direction source of truth** (`HistorySegment.swift`, full file, unchanged):
```swift
enum HistorySegment: String, CaseIterable {
    case list, calendar
    ...
}
```
`allCases` order (`[.list, .calendar]`) is what D-03's spatial mapping
depends on — `.calendar` is "to the right" of `.list`. Do not reorder
cases or change this enum.

**Error handling pattern:** N/A — no I/O, no throwing calls introduced by this change. No error-handling pattern applies.

**Validation pattern:** N/A — no new user input surface.

---

### `drinkpulseUITests/Features/History/HistoryInteractionUITests.swift` (test, request-response)

**Analog:** the file's own existing test, extend rather than duplicate.

**Existing test to extend** (lines 54-81, `test_segmentSwitch_togglesListAndCalendar`):
```swift
func test_segmentSwitch_togglesListAndCalendar() throws {
    launchApp()
    openHistoryTab()

    let beerRow = eventButton(containing: "500 ml")
    XCTAssertTrue(beerRow.waitForExistence(timeout: 10),
                  "List segment should show the seeded 500 ml beer row")
    XCTAssertTrue(app.staticTexts["Today"].exists,
                  "List segment should show a 'Today' section header")

    tapSegment("Calendar")

    let todayCell = calendarDayCell(forTodayNumber: currentDayNumber())
    XCTAssertTrue(todayCell.waitForExistence(timeout: 5),
                  "Calendar segment should render today's day cell (number \(currentDayNumber()))")
    XCTAssertFalse(app.staticTexts["Today"].exists,
                   "Calendar segment should not show the List's 'Today' section header")

    tapSegment("List")
    XCTAssertTrue(eventButton(containing: "500 ml").waitForExistence(timeout: 5),
                  "Returning to List should show the beer row again")
}
```
This test only exercises List→Calendar→List (one direction each way,
fixed order). RESEARCH.md's Pitfall 1 / Wave 0 Gaps calls for extending
this — or adding a sibling test in the same file — with an *alternating*
sequence (e.g. Calendar→List→Calendar, starting from the non-default
segment) to exercise the direction-lag bug class. Follow the exact same
structure: `launchApp()`, `openHistoryTab()`, `tapSegment(...)`,
assert on `eventButton(containing:)` / `app.staticTexts["Today"]` /
`calendarDayCell(forTodayNumber:)` — these are the established helpers
(`HistoryInteractionUITests+Helpers.swift`), reuse them rather than
writing new element queries. As RESEARCH.md notes, XCUITest can only
assert end-state content, not mid-animation direction — do not attempt
to assert animation frames.

**File header/doc-comment convention** (lines 1-25) — if extending with
a new test method, keep it in the existing "Segmented control: List ↔
Calendar" `// MARK:` section (line 49) rather than adding a new one.

---

## Shared Patterns

### Reduce Motion gating
**Source:** `drinkpulse/Features/Onboarding/OnboardingView.swift:9,86-92`
**Apply to:** `HistoryView.swift`'s new segment-switch handler — this is the single cross-cutting pattern this phase reuses. Copy the `@Environment(\.accessibilityReduceMotion) private var reduceMotion` property and the `if reduceMotion { action() } else { withAnimation(...) { action() } }` branching verbatim in shape (spring parameters may differ per plan discretion, but the branching structure must match).

### View-layer-only state (no ViewModel involvement)
**Source:** `HistoryView.swift`'s existing `@State private var segment` (line 9) and CLAUDE.md's MVVM boundary rule
**Apply to:** Any new `@State` this phase adds (`insertionEdge`, etc.) — must live in `HistoryView` as `@State`, not be pushed into `HistoryViewModel` (which RESEARCH.md confirms has zero stored properties today and should stay that way; transition direction is transient UI state, not business logic).

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `.transition(.asymmetric(insertion:removal:))` wiring itself | — (SwiftUI API usage, not a file) | — | No prior directional-transition code exists anywhere in this codebase (RESEARCH.md: "this is new ground"). The pattern to follow is Apple's own DocC-documented API shape (quoted above), not a codebase analog — planner should treat RESEARCH.md's "Pattern 1: Asymmetric directional transition keyed by enum comparison" code example as the primary reference here. |

## Metadata

**Analog search scope:** `drinkpulse/Features/History/`, `drinkpulse/Features/Onboarding/`, `drinkpulseUITests/Features/History/`
**Files scanned:** `HistoryView.swift`, `HistorySegment.swift`, `HistoryListQueryView.swift` (read for context only, out of scope), `HistoryCalendarQueryView.swift` (read for context only, out of scope), `OnboardingView.swift`, `HistoryInteractionUITests.swift`
**Pattern extraction date:** 2026-07-31
