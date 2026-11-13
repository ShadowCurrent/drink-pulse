# C013 — Cross-tab Liquid Glass flicker after Add Drink sheet dismissal

**Status:** proposed — awaiting owner decision (Phase 09 gap closure)
**Proposed destination:** Phase 09

## Current behavior

**Owner-reported defect.** On 2026-11-13 the owner reported that after opening Add Drink, closing it, and switching to another tab, that tab flashes or flickers for a moment. It is most visible on Insights, also happens on Dashboard, happens almost every time but not equally strongly, and affects the glass cards and glass-using elements. An earlier report (2026-09-18, iPhone 15 Pro Max, iOS 27) described the same cycle on Dashboard, with the flash lasting about one second.

**Commit 553ea58.** In response to the 2026-09-18 report, commit `553ea58` wrapped the Dashboard card stack in `GlassEffectContainer(spacing: 0)` in `drinkpulse/Features/Dashboard/DashboardView.swift` (24 changed lines, one file) before any diagnosis. The owner reports the flicker persisted. No Phase 08 candidate authorizes that change: UI-C-09 in `08-INVENTORY-UI.md` is **Retain** for the centralized Liquid Glass layer (`DPGlass.swift`). This is the BLOCKER gap recorded in `09-VERIFICATION.md` and in the corrections of `09-FLASH-DIAGNOSIS.md`.

**Why C006 now has a measured defect.** Decision C006 (`08-DECISION-C006.md`) permits a Liquid Glass change only for a concretely measured defect. The Phase 09 harness could not measure the flicker: on HEAD the app crashes inside the sheet cycle (Add Drink, Cancel, tab switch) at cycle 2 or 3 with `EXC_BREAKPOINT` in `MaterialProviderBox.resolveLayers(in:)` and `GlassEffectResolvedMaterial.value.getter`. Crash isolation on the iPhone 17 iOS 27.2 simulator then narrowed it (all simulator evidence, in `09-FLASH-DIAGNOSIS.md`):

- Glass in tab content plus an Add Drink then Cancel cycle is sufficient. One live `glassEffect` card on either visited tab is enough (`DashboardHeroCard` on Home, `InsightsScopeNavigator` on Insights). The crash is at the first update after the tab switch lands.
- The Dashboard container is not required (V1 without it crashes). The Add Drink sheet content is not required (V3 with a trivial sheet crashes). Replacing glass with a regular material, or removing the sheet cycle, completes 20 of 20 landings.
- A standalone minimal project with no app data reproduces the same signature in 1 of 2 completed glass runs; its material control completed in 2 of 2.

By choosing "C: without the device" (original Polish: "C: bez urządzenia"; 2026-11-13) the owner explicitly accepted that this reproducible simulator crash counts as the measured defect C006 requires. It is a simulator defect: the device flicker is not shown to be the same defect, CH6 (simulator-only) is open, and the flicker-to-crash link is not established. The HEAD frame-delta baseline, the variant frame-delta measurements, and the owner device session were not run, so no flicker measurement exists and the Route S or Route D rule was never applied.

**Data dependence.** Data dependence: not shown (criterion 1 fails: the layer observed for the crash is `glassEffect` material resolution, not store-fed view content, and the data-free minimal repro reproduces it; criterion 2 cannot apply: it needs a Route S owner device classification and a baseline excursion count, and neither exists). This covers the simulator crash only; for the flicker it cannot be judged without device data. Because it is not shown, the empty-store harness test was not run and there are no empty-store results.

**Classification** (from the Conclusion in `09-FLASH-DIAGNOSIS.md`): C-INCONCLUSIVE. H1 to H5 are all untested (no frame-delta or device data), and the owner skipped the device session. The simulator crash is recorded as a layer observation (the shared `glassEffect` resolution reached through any single `dpGlassCard` call site), not as a flicker classification. **Cure proposed: no.**

## Source-backed decision table

**Availability:** Official source checked 2026-11-13 through Xcode MCP `DocumentationSearch`. The `glassEffect(_:in:)` API is iOS 26+ per the earlier C006 and UI-C-09 lookup (the 2026-11-13 search result shows the signature but not the platform line), so the selected iOS 27 minimum satisfies availability. No replacement is inferred from age alone.

| Topic | Evidence |
| --- | --- |
| Official source | [glassEffect(_:in:)](https://developer.apple.com/documentation/swiftui/view/glasseffect(_:in:)): the system renders a shape anchored behind the view with the Liquid Glass material and applies foreground effects over it; it is typically used with a container. [GlassEffectContainer](https://developer.apple.com/documentation/swiftui/glasseffectcontainer) and "Applying Liquid Glass to custom views": a container renders several glass effects together, "improving rendering performance"; it is advised when applying glass to multiple views and is a recommendation, not a requirement. [Glass](https://developer.apple.com/documentation/swiftui/glass): `.regular` is the regular variant. [sheet(isPresented:onDismiss:content:)](https://developer.apple.com/documentation/swiftui/view/sheet(ispresented:ondismiss:content:)) and [TabView](https://developer.apple.com/documentation/swiftui/tabview) / [Tab](https://developer.apple.com/documentation/swiftui/tab): index entries only. **None of these documents states a cause, a trap, or any interaction between a presented sheet and glass effects in tab content**, so the documentation neither predicts nor explains the crash or the flicker. |
| Proposed behavior | No cure is proposed. The only evidence-supported source change is restoring `DashboardView.swift` to its form before `553ea58` (container removed). Alternatively, no source change while more evidence is gathered. |
| Benefit | Restoring the layout returns Dashboard to the Phase 08 retain baseline (UI-C-09) and removes an unauthorized, unevidenced change that neither cured the flicker nor is required for the crash. Gathering evidence avoids shipping a speculative Liquid Glass change. |
| Cost | Restoring: a revert of a 24-line change in one file plus a Dashboard visual check. It does not remove the crash or the flicker. Gathering: a further owner device session and a further gap-closure planning pass; the BLOCKER and MOD-02 stay open. |
| Alternatives | **apply-proposed-fix: not offered (no cure proposed).** **revert-container-only:** restore only the pre-553ea58 Dashboard layout. **gather-more-evidence:** make no source change; request the owner device session again, optionally run the minimal repro on the device (it needs no app data), run a Release build, and decide on submitting the unsent Apple Feedback draft. Replacing glass with a material is a diagnostic result only and is prohibited as a workaround. |
| Compatibility | Both source-affecting and non-affecting options use only APIs already in the app at the iOS 27 minimum; restoring the layout removes a `GlassEffectContainer` use and adds nothing. |
| Data / accessibility / lifecycle risk | No data or persistence change. Restoring the layout changes only Dashboard card composition and merging behavior; check card spacing (cards sit 20 pt apart, the flagged adjacency assumption), Dynamic Type, VoiceOver order, Reduce Motion, and context-menu rendering on Dashboard. Sheet dismissal to the originating tab and navigation are untouched. The empty-data assumption stays open for the flicker (Dashboard loads store data when it appears). Known interaction: `SheetDismissTabSwitchUITests` is committed on HEAD with no skip entry, and its sheet-mode test crashes the app on HEAD within 2 to 3 cycles, so a full UI suite run can fail on it until a later plan decides how to treat it. |

## Recommendation and proposed scope

No cure is proposed, so apply-proposed-fix is not offered: `apply-proposed-fix: not offered (no cure proposed)`. The recommendation below is not an approval and is not treated as one.

Recommend **revert-container-only**, with the owner free to amend the scope to also request the device session again. Reason: owner decision D1 replaces the 553ea58 container unless the diagnosis shows it is part of the right fix, and the diagnosis shows it is neither the cause nor a cure (V1 crashes without it, HEAD crashes with it, and the flicker persisted after it). Choosing it does not close MOD-02 and does not claim to fix the flicker or the crash; both stay open and are recorded as such. Choose **gather-more-evidence** instead if you prefer to change no source until the device session exists.

Scope of the recommended option: restore `drinkpulse/Features/Dashboard/DashboardView.swift` to its form before commit `553ea58`; no change to `DPGlass.swift`, the shell sheet presentation, or the Add Drink sheet content; the centralized Liquid Glass layer stays.

Dashboard container retained: no

Size review trigger: not tripped (0 changed lines, 0 files). This is the planner-set convention of 15 changed lines or 2 production files, used as a review flag and not a limit; no cure is proposed, so it is 0 changed lines in 0 files. For information, the revert itself touches one file and about 24 lines.

Automated flash regression: none (Route D) — owner device confirmation is the only proof

The owner must approve knowing this. The sheet-cycle harness test can intermittently catch the simulator crash (it crashes on HEAD), but it does not assert the flash metric and no frame-delta baseline exists, so nothing automated detects the flicker. Evidence: `09-FLASH-DIAGNOSIS.md` (Conclusion, crash isolation rounds 1 and 2, minimal repro) and C006.

## Owner decision record

**Outcome:** pending
**Decision date:** pending
**Exact scope:** pending (options: revert-container-only, gather-more-evidence; apply-proposed-fix is not offered because no cure is proposed)
**Owner reason:** pending
**Owner response:** pending

No approval is recorded. Silence or a favorable recommendation is not an outcome. Plan 09-08 records the owner's actual response here and in `08-DECISION-REGISTER.md` only after the owner replies.
