# Phase 11: iOS 27 Release Verification - Context

**Gathered:** 2026-11-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 11 shows that the iOS 27 migration is warning-clean, data-safe and accessible, and records build and test evidence for it (MOD-04, VER-01, VER-02, VER-03). It resolves app-owned deprecation warnings without suppression. It records Debug and Release builds and the scoped and then full regression suites on iOS 27. It proves the core user flows, records the accessibility checks, reconciles the three skipped Phase 05 chart checks, and confirms that every substantial modernization discovery has a recorded outcome. It does not fix unrelated verification debt and must not silently close it.

</domain>

<decisions>
## Implementation Decisions

### Readiness of prior phases
- Proceed without re-verifying Phases 08–10. Treat them as done, based on their closure plans: 08-08, 09-10 (closed with D1 deferred) and 10-14. Phase 11 does not re-run the phase verifier for 08, 09 or 10. The stale `09-VERIFICATION.md` (gaps_found, written before 09-10) and the "stale" status of 08 and 10 are listed in the Phase 11 debt ledger as known record states. They are not fixed or rewritten here.

### Regression suite scope (VER-01)
- No test or app fixes in Phase 11 for the known non-green items. Each one is recorded as an open limitation with its cause, todo or open-question link, and owner. VER-01 passes with these named exceptions. The items are: `InsightsUITests.test_heroCard_holdsHeight_whenSwitchingToAllTimeScope` (pre-existing failure), the two `HistoryInteractionUITests` edit tests that fail when run alone (todo `2026-11-13-history-edit-uitests-failing.md`), the Export dismiss UI test flake (todo `2026-11-13-export-dismiss-uitest-flaky.md`), and the two D1 crash harness tests gated behind `DP_RUN_FLASH_HARNESS` (todo `2026-09-18-diagnose-dashboard-flash-after-sheet-dismissal.md`). A new failure that is not on this list is a blocker. It is not added as a silent exception.

### Accessibility human checks (VER-03)
- The owner runs the human accessibility checklist on the iOS 27 simulator, not on the iPhone. The checklist covers: VoiceOver on both chart Audio Graphs (AlcoholAreaChart and WeekdayBarChart), Reduce Motion, Dynamic Type through AX5, light and dark appearance, and Increase Contrast. Each item is recorded as passed, failed or explicitly open. The evidence states that the run was on a simulator, not a device. Automated results (XCUITest and accessibility audits) and human results are kept in separate columns.

### Core flow proof (VER-02)
- Automated UI tests cover onboarding, startup/retry, add/edit/delete, History list and calendar, Insights, settings and backup export/import on iOS 27. The proof that existing data is preserved cites the Phase 10 device session (`10-DEVICE-SESSION.md`: in-place upgrade, import round trip, edit/delete, 214 events before and after). No new device session is planned. The evidence states a limitation: the device proof was made before the Phase 09-10 code changes, which reverted the Dashboard container and gated the harness tests.

### Toolchain and destination (owner update, 2026-11-14)
- Phase 11 evidence uses the installed Xcode 27.2 (27B52) with the iOS 27.2 SDK (`iphoneos27.2` / `iphonesimulator27.2`), and the iPhone 18 Pro simulator on the iOS 27.2 runtime as the primary destination. The iPhone 18 Pro Max on iOS 27.2 is the secondary destination. This replaces the Phase 08 baseline toolchain (Xcode 27.0, 27A266a), so VER-01 evidence must record the toolchain change and must not reuse Phase 08 version strings. `IPHONEOS_DEPLOYMENT_TARGET` stays 27.0 in every target and configuration. The minimum OS is a product decision, and raising it is out of scope.

### Decided autonomously
- [Warnings] Q: 'How to find deprecation warnings (MOD-04)?' → Selected: 'Do clean Debug and Release builds, extract every warning from the logs, classify each one as app-owned or external, and fix app-owned warnings at the source. Any fix that changes behavior or data goes through the Phase 08 D-09 brief first. An external warning records its official source, impact and follow-up.' — evidence method only; changing it later does not affect code.
- [Evidence] Q: 'Where does the evidence go?' → Selected: 'One 11-EVIDENCE.md with the exact commands, Xcode and Swift versions, SDK and runtime, destination, counts and log hashes. Raw logs stay outside git (Phase 08 D-13 pattern).' — document layout only.
- [Tooling] Q: 'How are builds and tests run?' → Selected: 'Xcode MCP first. The CLI xcodebuild is used only where the MCP test timeout is known to break long UI suites (Phase 09-03 precedent), and the evidence records which runner was used. Scoped runs come first, then the full suite.' — runner choice; the results are the same.
- [Phase 05 debt] Q: 'How are the three skipped Phase 05 checks handled?' → Selected: 'Fold the Reduce Motion check and both Audio Graph checks into the VER-03 human checklist, each linked back to the archived 05-UAT.md tests 4, 5 and 6, and record the outcome against each one.' — checklist mapping only.
- [Debt ledger] Q: 'How is the do-not-silently-close-debt criterion met?' → Selected: 'Add a ledger table that lists D1, WINDOWS.md row 7 (Domain coverage), the open-questions items, the pending todos and the prior-phase verification record states, each with its status and owner. Nothing is closed without evidence.' — record only.
- [Discoveries] Q: 'How is SC5 (modernization discoveries) checked?' → Selected: 'Cross-check C001 to C013 and the Phase 10 decisions F2 to F4 and the device finding against their decision records, and confirm that each one has a recorded analysis and outcome.' — read-only audit.

- [Research follow-up] Q: 'Add an automated accessibility audit test?' → Selected: 'Add one test-only class drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift using performAccessibilityAudit, with an allow-list that holds only issues recorded in the debt ledger. No production code changes.' — test-only file, deletable without side effects.
- [Research follow-up] Q: 'Backup import has no UI test (system fileImporter picker). New test or limitation?' → Selected: 'Record it as a VER-02 limitation, backed by the existing importer unit tests and the Phase 10 device import round trip. No new UI test that drives the system picker (the simulator locale is Polish).' — record only.
- [Research follow-up] Q: 'Which files does the device-proof limitation list?' → Selected: 'All nine production files changed after a38a75f (git diff --stat a38a75f HEAD -- drinkpulse), named one by one, not only the Dashboard revert and the harness gating.' — record only.
- [Research follow-up] Q: 'Is the full suite with coverage run through the CLI?' → Selected: 'Yes. Xcode MCP cannot collect coverage, which counts as a named missing capability, so one detached xcodebuild full run uses -enableCodeCoverage YES. Scoped runs stay on MCP.' — runner choice.
- [Research follow-up] Q: 'What happens with a failure not on the known list?' → Selected: 'Re-run it once alone. If it passes on the re-run, record it as a newly observed flake with a new todo. If it fails again, it is a blocker for the owner.' — evidence protocol.
- [Research follow-up] Q: 'Animations not gated by Reduce Motion (DPArcProgress.swift:18, ConsumptionOverviewCard.swift:110, HistoryCalendarView.swift:61)?' → Selected: 'Put each one on the VER-03 human checklist. A confirmed defect gets an owner D-09 brief and stays open. Phase 11 makes no fix.' — record only.
- [Research follow-up] Q: 'Privacy manifest and build date open question?' → Selected: 'Ledger entry only. It is not resolved in Phase 11.' — record only.

### Claude's Discretion
- None. The owner answered every question that was asked.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- UI test suites mirror the features: `drinkpulseUITests/Features/{AddDrink,Dashboard,History,Insights,Onboarding,Settings,Shell}`.
- The chart accessibility code is in `drinkpulse/Features/Insights/Components/AlcoholAreaChart+Accessibility.swift` and `WeekdayBarChart+Accessibility.swift` (Audio Graph descriptors).
- There is a durable VoiceOver UI test from Phase 09-05 (`XCUIVoiceOverService` pattern: skip on failedToStart).
- Baseline evidence format: `08-BASELINE.md` and `.json`, and `10-EVIDENCE.md` (toolchain, zero-warning gate, guards, coverage).

### Established Patterns
- Gate commands and the coverage command are in AGENTS.md. A full-suite pass is required at milestone close.
- Launch-argument test hooks (for example `-dp_onboarding_done YES`). The simulator system locale is Polish, so tests must never match system UI by its localized label.
- Owner-run checklists record results per item (09-UAT.md and 10-DEVICE-SESSION.md style).

### Integration Points
- Living docs to reconcile at the end: README, PROJECT.md, ROADMAP.md, REQUIREMENTS.md (MOD-04 and VER-01 to VER-03), current-focus.md, open-questions.md and DEVLOG.

</code_context>

<specifics>
## Specific Ideas

- Phase 08 found exactly one warning: the `@Entry` closure warning (`dismissSheet`), which Phase 09 addressed. The fresh Phase 11 build must confirm whether any deprecation warnings remain.
- Phase 05 skipped checks: `05-UAT.md` test 4 (Reduce Motion gates both charts), test 5 (AlcoholAreaChart Audio Graph) and test 6 (WeekdayBarChart Audio Graph).

</specifics>

<deferred>
## Deferred Ideas

- Re-running the phase verifier for Phases 08–10, which would refresh the stale 09-VERIFICATION.md. This belongs to separate verification work, not Phase 11.
- Fixing the known red or flaky UI tests and D1. These stay with their existing todos.
- A fresh device pass on the final build, and device-level accessibility checks.

</deferred>
