# Phase 11 gap execution: orchestrator carry-over notes

Read this before dispatching 11-21..11-24. Pass every point to every executor prompt.

## State (2026-11-17)
- Plans 11-12..11-20 complete (HEAD dd2b1bb). Next: 11-21, then 11-22 (checkpoint), 11-23 (checkpoint), 11-24 (checkpoint).
- G-2, VER-01, VER-03 stay open; never run `requirements mark-complete` unless truly complete.

## Owner cost limit (owner directive)
- Hard limit per executor: at most 2 fix attempts per finding/cluster. After the 2nd failed attempt, stop fixing it, record it as open in 11-DEBT-LEDGER.md with the evidence, and move on.
- Run each audit/test class at most: one red run, one run after fixes, one confirmation run. No exploratory re-runs.
- Avoid RenderPreview loops; one render per check.

## Owner rules for every executor
- Owner chats in Polish; all files, docs, comments, commits in English.
- No AI attribution in commits (no Co-Authored-By / Generated with / Claude-Session). Never push.
- Count audit keys with `LC_ALL=C sort -u`.
- Scheme env set by owner in Run > Arguments (Test inherits). Never edit the scheme; if a gated test skips, stop and report.
- Xcode MCP only (workspaceIdentifier from XcodeListWorkspaces, never written to files); RunSomeTests ids need `()`; one retry on "result bundle incomplete"; no CLI xcodebuild except what 11-23 explicitly gates on the owner.
- AGENTS.md: 300-line limit, previews, String(localized:), zero warnings, list regular-size visual changes in SUMMARY.
- Checkpoint or owner decision needed: stop and return structured checkpoint, never guess.

## Carry-over facts
- Since 11-17 AuditLaunch passes `-dp_color_scheme system`; 11-13 "standard"/"ax5" rows were measured in dark mode. Re-measure light per screen.
- D11-28: exemption for Add Drink step 2 system Form controls only.
- D11-29: opt-in `ignoreTabBarOccludedContent: true` ignores contrast/textClipped on app elements under the real tab bar; logged as warnings.
- D11-30: Insights chart day-mark hitRegion exemption.
- Next free decision id: D11-31. Plan 11-23 text says "D11-28" for the Release answer — it must use the next free id instead.
- `none#type=nil` issues: found by switching view parts off in a temporary, never-committed test (causes seen: emoji Text, tile-wide accessibility frames, minimumScaleFactor, `Group { if/else }` layouts — fixed with AnyLayout).
- Tokens: reuse dpSecondaryText, dpRiskText*, RiskLevel.textColor.
- 11-22: the gated `AccessibilityAuditUITests` does not use D11-29/D11-30 yet and will still report Home `This Week`/`100%` and Insights issues; route it through the shared helper flags or record the keys. Settings after-scroll findings (WEEKLY SUMMARY, DATA, Export all data, version text) noted for 11-22.
- Open ledger items: DL-O18 (Insights axis, fixed, awaiting owner re-check at CHK-07), DL-O19 (Add Drink step 2 placeholders, no owner plan), DL-O20 (Onboarding AX5 owner eye check at 11-22/11-23 checkpoint), DL-T01 (Insights hero-height test, pre-existing).
- 11-24: cite 311 byte-wise distinct keys (not 254); reconcile the review-disposition footer.
- Owner approved the 11-18 toolbar "Cancel" → system "×" change.
- Out of scope: OBS-D (Home arc animation), GuidelineAlertCard localisation note.

## After 11-24
Post-merge gate (full suite ~25 min via MCP), aggregate, verify_phase_goal, code review gate, update_roadmap, transition — per execute-phase.md.
