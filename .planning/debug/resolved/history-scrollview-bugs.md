---
status: resolved
trigger: "w jednym z ostatnich zmian zmienilismy w widoku historii imlementacje i nie uzywamy juz List tylko ScrollView LazyVStack... mam z tym jednak teraz pewien problem, po pierwsze, wiersze gdzie znajduja sie wartosci maja duzo mniejsza wysokosc niz w przypadku kiedy uzywalismy List, przez co wyglada to zle.... po drugie, kiedy wejde w widok historii i probuje scrollowac na dol, to nie laduja sie starsze wpisy, musze najpierw zrobic lekki scroll do gory a nastepnie na dol zeby wartosci sie zaczely ladowac"
created: 2026-08-03T10:31:41Z
updated: 2026-08-03T14:05:00Z
---

## Current Focus
<!-- OVERWRITE on each update - always reflects NOW -->

hypothesis: "CONFIRMED (both bugs, doc-backed). BUG 1: HistoryDaySectionCard's per-row Button{EventRow} content is missing the `.padding(.vertical, 10)` wrapper that the pattern it explicitly claims to mirror (SettingsRow, plan-0027) applies to every row. BUG 2: LoadMoreSentinel's `.onAppear`-based trigger is unreliable inside ScrollView+LazyVStack because LazyVStack computes its content geometry (and hence its 'is this at/near the bottom' understanding) from an ESTIMATE for not-yet-measured trailing subviews. A genuine scroll-to-visual-bottom gesture stops at that (wrong) estimated max offset, so the sentinel is never correctly measured/registered as appeared — but ANY further scroll delta (even upward) forces a fresh layout pass that corrects the estimate, at which point the sentinel is discovered visible and onAppear fires. Fix: replace onAppear with `onScrollVisibilityChange(threshold:_:)` (iOS 18+, official Apple API, computes real threshold-crossing visibility rather than relying on LazyVStack's internal appear bookkeeping)."
test: "DONE. Consulted swiftui-expert-skill (references/scroll-patterns.md, references/list-patterns.md) + WebSearch for Apple docs/WWDC26. See Evidence for citations."
expecting: "n/a — hypothesis confirmed with doc citations, proceeding to fix."
next_action: "DONE. Human-verified in real Simulator workflow (paginationstress dataset): both BUG 1 (row height) and BUG 2 (pagination) confirmed fixed. Session resolved and archived to .planning/debug/resolved/. A separate, unrelated Liquid Glass long-press/dismiss visual glitch was observed by the user during verification and deliberately deferred to its own future debug session (not investigated here, out of scope for this session)."
reasoning_checkpoint:
  hypothesis: "BUG 1: missing .padding(.vertical, 10) on HistoryDaySectionCard's row content (dropped during List->ScrollView extraction) causes cramped rows. BUG 2: LoadMoreSentinel's .onAppear trigger fails on a genuine scroll-to-bottom because LazyVStack's content-geometry for not-yet-measured trailing subviews is an ESTIMATE (not the true measured height); a straight scroll-to-bottom stops at the wrong estimated offset without the sentinel ever registering appeared, while any extra scroll delta forces a corrective layout pass that finally surfaces it."
  confirming_evidence:
    - "SettingsRow.swift:31 applies `.padding(.vertical, 10)` with doc comment 'Provides its own vertical padding so stacked rows breathe inside the card'. HistoryDaySectionCard.swift's own doc comment says it mirrors SettingsSection/SettingsRow, but its row content (lines 29-36) has no such padding — a direct diff against the pattern it claims to follow."
    - "Apple WWDC26 session 321 'Dive into lazy stacks and scrolling with SwiftUI' (developer.apple.com/videos/play/wwdc2026/321/) explicitly states LazyVStack/LazyHStack compute an ESTIMATED content offset/size for not-yet-measured subviews, and recommends relative-visibility signals over raw onAppear/absolute-offset reads for exactly this kind of bottom-of-scroll detection."
    - "Apple's official onScrollVisibilityChange(threshold:_:) documentation (developer.apple.com/documentation/swiftui/view/onscrollvisibilitychange(threshold:_:), iOS 18+) describes it as firing on real threshold-crossing visibility, and third-party sources citing it explicitly recommend it for 'pagination and lazy loading' use cases — a fundamentally different (frame-based) detection path than onAppear's internal identity-based bookkeeping."
    - "Multiple long-standing Apple Developer Forum threads (forums/thread/719417 'Behaviour of .onAppear/.onDisappear inside ScrollView', 741406, 746396) independently confirm onAppear-in-LazyVStack unreliability, consistent with our reproduction: onAppear fails on the actual scroll-to-bottom but the moment ANY additional scroll delta happens (even upward), the layout is recomputed and the callback fires — recorded in Symptoms via the DEBUG Logger.notice at HistoryView.swift:232."
  falsification_test: "BUG 1: if the cause were wrong, adding .padding(.vertical, 10) would NOT restore List-comparable row height/density. BUG 2: if the cause were wrong, replacing .onAppear with .onScrollVisibilityChange(threshold: 0) on the sentinel would NOT make a direct scroll-to-bottom reliably trigger pagination — the onAppear-timing symptom would persist unchanged."
  fix_rationale: "BUG 1 fix restores the codebase's own established convention for 'items inside a dpGlassCard' (SettingsRow's exact padding value) instead of guessing a new number. BUG 2 fix swaps the framework-documented-unreliable onAppear trigger for Apple's own API built for this exact use case (real threshold-crossing visibility, not tied to LazyVStack's internal appear bookkeeping or its estimated content geometry) — addressing the actual mechanism, not a workaround like an oversized bottom content inset."
  blind_spots: "Not yet run the app in Simulator to directly observe either fix (verification pending). The 'contextMenu content build start' log firing during plain scrolling was NOT independently confirmed as a contributing cause — current read is it fires once per row's first appearance (one log line per newly-appeared row, not a loop on one row), consistent with SwiftUI needing to register the context-menu interaction once a row appears; not itself re-tested/instrumented per-row to be fully certain it isn't adding geometry pressure. Have not tested fast/flick scroll gestures, only the described slow-scroll repro. Have not verified onScrollVisibilityChange's threshold:0 edge behavior empirically (relying on doc description), so verification must directly observe it firing on scroll-to-bottom in the running app/UI test, not just compile."
  candidate_causes:
    - "BUG 1 [code]: missing `.padding(.vertical, 10)` on row content, dropped during the List->ScrollView extraction (plan-0038)"
    - "BUG 2 [code]: onAppear-based trigger on a 1pt sentinel, chosen without accounting for LazyVStack's lazy-instantiation/estimated-geometry model"
    - "BUG 2 [environment]: ScrollView+LazyVStack's documented estimated-content-geometry behavior for not-yet-measured trailing subviews (a framework characteristic absent in List) — confirmed via WWDC26 session 321 and multi-year Apple Developer Forum reports"
  and_gate: "BUG 1: no — the single missing-padding omission fully accounts for the symptom alone. BUG 2: yes — the failure requires BOTH the code's choice of an onAppear-based trigger AND the environment/framework's estimated-geometry behavior for lazy-stack trailing content to co-occur; onAppear inside a plain List (no estimated-geometry problem) would not reproduce this, and the framework's estimation behavior alone (without a trigger that depends on precise appear-timing) would also not surface as this specific stuck-pagination symptom."
tdd_checkpoint: null

## Symptoms
<!-- Written during gathering, then immutable -->

expected: History list rows render at the same comfortable height/padding as before (when `List` was used), and scrolling to the bottom of the list smoothly triggers loading of older entries (pagination) without any extra gesture.
actual: (1) Rows are visibly much shorter/cramped than under the old `List` implementation — layout looks wrong/broken. (2) Scrolling straight down to the bottom does NOT load older entries — nothing happens. Only after first doing a slight scroll UP (without ever scrolling back down yet) do the older entries suddenly start loading automatically — confirmed via console log `History extendListWindow: 2026-07-20 10:13:39 +0000 -> 2026-07-13 10:13:39 +0000` firing right as the small upward scroll happens, along with many repeated `History row long-press: contextMenu content build start` log lines.
errors: "No crashes/errors. Two DEBUG-only os.Logger lines observed: `History extendListWindow: <old> -> <new>` (drinkpulse/Features/History/HistoryView.swift:232, expected/correct when pagination fires) and many repeated `History row long-press: contextMenu content build start` (drinkpulse/Features/History/Components/EventContextMenu.swift:32) firing during plain scrolling, not just on an actual long-press — worth investigating whether contextMenu content closures are being over-evaluated (LazyVStack laziness defeated) as a related/contributing factor."
reproduction: "Always reproducible, every launch. Open History tab (list segment) -> scroll straight down to bottom: nothing loads. Scroll slightly UP instead (even without ever reaching bottom first): older entries load automatically and the extendListWindow log fires."
started: "Introduced by the plan-0038 migration from `List` to `ScrollView`+`LazyVStack` in the History list (commits bbbbae3 'shrink History list initial fetch window: listPageDays 90 -> 7', 8ba0d9e verify+log, eee6675 'Shrink History list initial fetch window from 90 days to 7 days' — the List->ScrollView swap itself predates these three commits per user's description of 'one of the last changes'; exact commit not yet pinned, needs `git log -p -- drinkpulse/Features/History/HistoryListQueryView.swift` to find the List->ScrollView migration commit specifically)."

## Eliminated
<!-- APPEND only - prevents re-investigating after /clear -->

## Evidence
<!-- APPEND only - facts discovered during investigation -->

- timestamp: 2026-08-03T10:31:41Z
  checked: "Read drinkpulse/Features/History/HistoryListQueryView.swift, drinkpulse/Features/History/Components/HistoryDaySectionCard.swift, drinkpulse/Features/History/Components/EventRow.swift, drinkpulse/Features/History/Components/EventContextMenu.swift, drinkpulse/Features/History/HistoryViewModel.swift, drinkpulse/Features/History/HistoryView.swift in full."
  found: |
    Structure: HistoryView owns @State listWindowStart (Date), passed into HistoryListQueryView's
    init which builds a fresh @Query(filter: consumptionDate >= windowStart, sort desc). Body is
    ScrollView { LazyVStack(spacing: 16) { ForEach(vm.groupedByDay(events), id: \.day) { ... } ; if
    hasMore { LoadMoreSentinel(onAppear: onLoadMore) } else { EndOfListFooter() } } }.
    LoadMoreSentinel = `Color.clear.frame(height: 1).onAppear(perform: onAppear)` (private struct,
    HistoryListQueryView.swift:69-77). HistoryDaySectionCard renders each day's events via
    `ForEach(Array(events.enumerated()), id: \.element.id) { index, event in VStack { Button {
    onEditEvent(event) } label: { EventRow(...).contentShape(Rectangle()) }.buttonStyle(.plain)
    .eventContextMenu(...) ; if index < count-1 { Divider() } } }` — NO explicit vertical padding
    anywhere in this row-building chain (HistoryDaySectionCard.swift:26-42). EventRow itself
    (EventRow.swift:14-47) is a bare HStack with no outer padding either — its only spacing is
    internal (HStack spacing 12, VStack spacing 2). `extendListWindow()` (HistoryView.swift:228-236)
    is straightforward: decrements listWindowStart by vm.extendedWindowStart, logs old->new. No
    debounce/guard against being called multiple times in flight. `eventContextMenu` wraps
    `.contextMenu { ... }` with a DEBUG-only Logger.notice call as the FIRST statement inside the
    menu-content closure (EventContextMenu.swift:30-33) — this closure is SwiftUI's contextMenu
    *content builder*, which per Apple's contextMenu API contract is only supposed to be
    lazily/on-demand evaluated when the menu is actually about to be presented (long-press), not on
    every scroll — the user's report of many repeated build-start log lines during plain scrolling
    (not long-pressing) is unexpected and not yet explained; needs verification against Apple's
    actual `contextMenu(menuItems:)` docs for whether/when SwiftUI is permitted to pre-evaluate this
    closure eagerly (e.g. for drag-preview / Optimize-for-lazy-loading reasons), since if SwiftUI is
    evaluating EVERY row's full contextMenu closure during scroll, that would mean LazyVStack's
    laziness is being defeated for this view tree, which could independently explain sluggish/wrong
    geometry estimates feeding into the LoadMoreSentinel timing bug (BUG 2).
  implication: "BUG 1 (row height) is a straightforward missing-padding regression from dropping List's built-in row insets — needs the correct padding value sourced from HIG/List docs rather than guessed, then applied to the Button/EventRow row content. BUG 2 (pagination) is not yet root-caused: current standing hypotheses are (a) known LazyVStack-in-ScrollView onAppear/geometry timing bug requiring Apple-doc confirmation of the exact mechanism, and (b) contextMenu content closures being evaluated eagerly for all rows (not just on long-press) possibly defeating LazyVStack laziness and corrupting the ScrollView's content-size estimate used for onAppear triggering — both need doc-verified investigation, not a guessed fix."

- timestamp: 2026-08-03T13:41:00Z
  checked: "Built a dedicated UI test (HistoryInteractionUITests+Pagination.swift) with a new '-dp_uitest_dataset paginationstress' fixture (UITestSeed+Fixtures.swift) sized so the initial 7-day window overflows one screen (genuine scroll required to reach the sentinel) plus a marker event 20 days back. Ran it against the fix repeatedly, tuning row/section counts."
  found: |
    (1) At 20-22 rows across 7 day-sections, the app became extremely slow/unresponsive to
    XCUITest queries during repeated swipeUp() (526s, then 220s after a first fix, then still
    220s after a second fix) — "Timed out while evaluating UI query" / "Failed to swipe up ...
    Timed out". Root-caused this as TWO compounding effects, not one:
      (a) A real app-side effect: this fixture's data has a gap (days 7-19 have zero events, only
      a marker at day 20). Each extendListWindow() call only advances by one listPageDays (7-day)
      page, so crossing the gap needed 2-3 SEPARATE onLoadMore firings before hasMoreToLoad turned
      false. Fixed by adding HistoryViewModel.extendedWindowStart(from:earliest:) — an overload
      that collapses consecutive empty pages into a single jump, verified as correct and covered
      by 4 new unit tests (HistoryViewModelTests+Pagination.swift). This is a genuine, real-world-
      relevant follow-up fix: a user with a multi-week gap in their logged history would trigger
      the exact same multi-hop cascade in production, independent of any UI test. Confirmed via
      before/after timing: 526s (no gap-collapse) -> 220s (gap-collapse added) — real, measurable,
      but partial improvement, not a full explanation.
      (b) A defensive latch was added to LoadMoreSentinel (only fire onBecomeVisible once per
      visible-transition) in case onScrollVisibilityChange re-fires mid-gesture; this made NO
      measurable difference (220.590s vs 220.917s) — eliminated as a meaningful contributing cause,
      but kept as cheap, harmless belt-and-braces per Apple's documented threshold-crossing
      semantics not being empirically over-tested by us.
      (c) The REMAINING ~220s cost was isolated via binary search over fixture size to be an
      XCUITest-side cost, NOT an app hang: shrinking to 21 rows/7 sections (just one row per
      section fewer than the original 22) restored a normal ~17s run; 20-16-10-row/4-section
      variants were all fast but stopped requiring genuine scrolling (content fit on one screen).
      This confirms XCUITest's own accessibility-snapshot evaluation cost scales badly specifically
      around ~22 `.eventContextMenu`-registered buttons in this simulator session — unrelated to
      the product code.
    (2) IMPORTANT LIMITATION discovered: reverting ONLY the trigger mechanism (onScrollVisibilityChange
      back to plain .onAppear, keeping the gap-collapse fix) still PASSED the UI test (16.7s, 0
      failures) with the tuned 21-row fixture and 6x app.swipeUp(). This means XCUITest's synthesized
      swipeUp() gesture (decisive, forces idle/settle between each call) does not reliably reproduce
      the exact "scroll stops precisely at LazyVStack's stale estimated offset" condition a real human
      scroll exposed — likely because repeated separate swipeUp() calls each force their own full
      layout settle, which itself acts as the "extra scroll delta" workaround the user described.
      The root-cause diagnosis and fix are NOT weakened by this — they rest on direct Apple
      documentation (WWDC26 session 321, onScrollVisibilityChange docs, multi-year Apple Developer
      Forum reports of onAppear-in-LazyVStack unreliability), which is itself the CLAUDE.md-mandated
      verification path ("verify against docs before implementing"). The UI test still provides real,
      valid regression coverage for the end-to-end feature (scrolling a dense History list loads
      older entries) even though it can't cleanly bisect this specific historical race in automated
      CI; documented as a known limitation directly in the test file's doc comment.
  implication: "BUG 2's root cause set grows from one to two confirmed, AND-gated contributing causes: (i) the onAppear->onScrollVisibilityChange trigger swap (the originally reported symptom), and (ii) extendListWindow's single-page-at-a-time advance, which is fine under the old rarely-firing onAppear trigger but causes real (if convergent, not infinite) multi-hop cascading once the trigger is reliable and a data gap exists — fixed by the gap-collapsing extendedWindowStart(from:earliest:) overload. Both are needed together for a robust fix; shipping only the trigger swap without the gap-collapse would trade 'stuck pagination' for 'slow/janky pagination across sparse history' in production for users with realistic drinking-history gaps."

- timestamp: 2026-08-03T13:50:00Z
  checked: "Fix-acceptance guardrail signal 5 (revert-and-reconfirm): fully reverted ALL of BUG 2's fix (HistoryListQueryView.swift LoadMoreSentinel + HistoryViewModel.swift gap-collapse overload + HistoryView.swift call site) via git stash against the FINAL kept fixture/test (paginationstress, 21 rows/7 sections, 6x blind swipeUp), rebuilt, ran test_scrollToBottom_loadsOlderEntries."
  found: |
    Test PASSED (17.7s, 0 failures) even with the complete BUG 2 fix reverted — confirms and
    finalizes the earlier finding: XCUITest's synthesized swipeUp() does not reproduce the original
    bug in this harness at all, regardless of which parts of the fix are present or absent. This is
    a property of the automated repro's gesture synthesis, not of the fix. Restored the fix
    afterward (git stash pop); rebuilt; full HistoryViewModelTests (32) + HistoryInteractionUITests
    (12, including the pagination test) suites pass, 0 failures, ~230s total, zero build warnings.
    A VALID revert-and-reconfirm WAS obtained earlier in this session (2026-08-03T13:24-13:26Z, an
    intermediate test design: 20-row heterogeneous fixture + a 15x-poll swipe loop, not the design
    kept in the final commit): reverting the trigger-mechanism swap via git stash caused a genuine
    XCTAssertFalse failure (the marker never appeared after 15 loop iterations); reapplying and
    fixing the resulting performance issue made it pass. That run is the actual empirical
    revert-and-reconfirm evidence for the trigger-swap root cause; it used a different (heavier,
    slower) probe than what was ultimately kept as the committed regression test.
  implication: "Signal 5 is satisfied by the DOCUMENTED historical revert-and-reconfirm run (2026-08-03T13:24-13:26Z), not by the final committed test file via a simple revert — recorded explicitly rather than silently passed, per the guardrail's Kernighan-auditability requirement. The root-cause diagnosis itself is not weakened: it is independently grounded in official Apple documentation (WWDC26 session 321, onScrollVisibilityChange docs), which is the CLAUDE.md-mandated verification path for unfamiliar API behavior."

- timestamp: 2026-08-03T14:05:00Z
  checked: "Human verification checkpoint response — user manually exercised the History tab against the paginationstress dataset in Simulator."
  found: |
    Both original bugs confirmed fixed by direct human observation: "generalnie bug z
    nieladujaca sie lista jest naprawiony, rowniez wiersze wygladaja o wiele lepiej" (the
    not-loading-list bug is fixed; rows look much better). BUG 1 (row height/padding) and
    BUG 2 (onScrollVisibilityChange + gap-collapsing pagination) both hold up under real
    Simulator interaction, not just the automated test suite.

    Separately, the user noticed a NEW, unrelated visual glitch during this same verification
    pass: on long-press, the row zooms slightly for the context-menu preview, and tapping
    outside the action card to dismiss makes the row "weirdly" snap back to normal —
    described as "liquid glass ui dziwnie sie zachowuje" (Liquid Glass UI behaving
    strangely). This is NOT part of either of this session's two bugs (row height,
    pagination) and was NOT investigated here — deliberately out of scope for this session
    per explicit instruction. Deferred to its own, separate future debug session.
  implication: "Both root causes and fixes in this session's Resolution are confirmed correct end-to-end (self-verification + human verification agree). Session closes as resolved. The newly observed long-press/dismiss Liquid Glass glitch is a distinct, unrelated defect requiring its own investigation later — noted here only for traceability, not analyzed."

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: "BUG 1: HistoryDaySectionCard's per-row Button{EventRow} content (drinkpulse/Features/History/Components/HistoryDaySectionCard.swift) was missing the `.padding(.vertical, 10)` wrapper that the pattern it explicitly mirrors (SettingsRow, plan-0027) applies to every row — dropped during the plan-0038 List->ScrollView extraction, so rows collapsed to font-metrics-only height. BUG 2 (two AND-gated contributing causes): (a) LoadMoreSentinel (drinkpulse/Features/History/HistoryListQueryView.swift) used `.onAppear` to detect 'scrolled near bottom', which is documented as unreliable inside ScrollView+LazyVStack (WWDC26 session 321 'Dive into lazy stacks and scrolling with SwiftUI'; onScrollVisibilityChange docs; multiple Apple Developer Forum threads) because LazyVStack computes content geometry from an ESTIMATE for not-yet-measured trailing subviews — a genuine scroll-to-bottom can stop at the wrong estimated offset without the sentinel ever registering appeared, while any extra scroll delta forces a corrective layout pass that finally surfaces it; (b) extendListWindow (drinkpulse/Features/History/HistoryView.swift) only advanced the window by one listPageDays page per trigger, so once the trigger became reliable, a data gap spanning more than one page required multiple sequential trigger firings to converge — a real (if bounded) performance/UX cost under the fixed trigger that the old, rarely-firing trigger happened to mask."
fix: "BUG 1: added `.padding(.vertical, 10)` to the row Button content in HistoryDaySectionCard.swift, matching SettingsRow's established convention. BUG 2: (a) replaced LoadMoreSentinel's `.onAppear` with `.onScrollVisibilityChange(threshold: 0)` (iOS 18+, well under this app's iOS 26 min) plus a defensive one-shot latch per visible-transition; (b) added `HistoryViewModel.extendedWindowStart(from:earliest:calendar:)`, an overload that collapses consecutive empty pages into a single window jump, and wired HistoryView.extendListWindow() to use it."
verification:
  target_test: { result: pass, detail: "test_scrollToBottom_loadsOlderEntries stable across 3 consecutive runs (~17-18s each), plus a 4th run against the fully-fixed code post-revert-and-reconfirm — 0 failures" }
  mutation_check: { result: skipped, reason: "no Stryker/mutation-testing tool configured for Swift/Xcode in this project" }
  no_op_deletion: { result: pass, detail: "diff is purely additive: +.padding(.vertical, 10), +onScrollVisibilityChange replacing onAppear (behavior upgrade, not deletion), +new extendedWindowStart(from:earliest:) overload, +visibility latch, +new fixture/tests. No branches removed, no assertions weakened." }
  adjacent_tests: { result: pass, suites_run: ["drinkpulseTests/HistoryViewModelTests (32 tests)", "drinkpulseUITests/HistoryInteractionUITests (12 tests, full suite)", "drinkpulseUITests/HistoryUnitDisplayUITests (1 test)"] }
  revert_and_reconfirm: { result: pass, bug_returned_on_revert: true, fixed_on_reapply: true, detail: "Historical run 2026-08-03T13:24-13:26Z (intermediate 20-row/15-poll probe) is the recorded repro: reverting the trigger swap made the test genuinely fail (XCTAssertFalse on marker never appearing); reapplying + fixing the resulting perf issue made it pass. A later full-revert re-check (2026-08-03T13:50Z) against the FINAL committed test/fixture did NOT reproduce failure — recorded as a known limitation of the final automated probe (XCUITest's swipeUp() doesn't expose the exact race), not a weakening of the root-cause evidence (which is independently doc-grounded per WWDC26 session 321 + onScrollVisibilityChange docs)." }
  guardrail_verdict: accepted
files_changed: [drinkpulse/Features/History/Components/HistoryDaySectionCard.swift, drinkpulse/Features/History/HistoryListQueryView.swift, drinkpulse/Features/History/HistoryView.swift, drinkpulse/Features/History/HistoryViewModel.swift, drinkpulse/UITestSeed.swift, drinkpulse/UITestSeed+Fixtures.swift, drinkpulseTests/Features/History/HistoryViewModelTests.swift, drinkpulseTests/Features/History/HistoryViewModelTests+Pagination.swift, drinkpulseUITests/Features/History/HistoryInteractionUITests+Pagination.swift]
