---
phase: "11"
slug: "ios-27-release-verification"
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: "2026-11-18"
---

# Phase 11 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

Register built from the `<threat_model>` blocks of plans 11-01 to 11-24 (written at plan time) and the SUMMARY Threat Flags sections (all "None"). Audited 2026-11-18 by gsd-security-auditor (ASVS L1, block_on high) with read-only git and grep checks at HEAD 91fde0e. Final build 3f70ff6, production tree e252da14bcff1c5503a18425e8c59a158bb382f3, phase-start commit 2aa9156.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Out-of-git stamp directory to repository | Raw build/test logs, result bundles and simulator identifiers stay in `~/Library/Logs/DrinkPulse/phase-11-ios27/<stamp>`; only counts and sha256 digests enter tracked evidence | Machine paths, device identifiers (sensitive to the owner) |
| UI test harness to production app | Test-only hooks are gated on the `-dp_uitest` launch argument (`UITestSeed.isActive`) | Synthetic seeded data only |
| Owner decisions to tracked records | Owner answers (scheme variable, Release build, coverage, requirement outcomes) are recorded as decisions and stamp files before the dependent action | Decision provenance |
| Local repository to remote | Nothing pushed; no tag created | All phase commits |

---

## Global Checks (evidence keys used in the register)

- G-a: `git ls-files` matching .log/.xcresult/.xcactivitylog/.profraw/.profdata/^build//DerivedData = 0. .gitignore:54 `build/`.
- G-b: UUID-shaped regex over .planning/phases/11-ios-27-release-verification/ = 0 hits; over every added line since 2aa9156 (all paths except xcodeproj) = 0 hits; email regex over Phase 11 dir + ADR 0013 = 0; tracked image/log/sh/txt files in Phase 11 dir = 0.
- G-c: all 43 distinct 64-hex strings in 11-EVIDENCE.md equal the sha256 of an existing file (stamp dir or phase dir). Checklist sha 9c9647... and audit-final.result.txt sha e7e53afa... match.
- G-d: paths changed since 2aa9156 outside .planning/docs/.claude/README = 74. Production (drinkpulse/) = 54: 4 colorsets, DesignSystem (DPAdaptiveStack, DPArcProgress, DPMotion, DPMotionProbe, DPSemanticColors, RiskLevel+Color), Features views (AddDrink, Dashboard, History, Insights, Onboarding, Settings, Shell/RootShellView), Info.plist, Localizable.xcstrings, UITestSeed.swift. Empty diff for drinkpulse.xcodeproj, drinkpulse/Domain, drinkpulse/Services, drinkpulse/Models, entitlements. No ViewModel, Model, Service, Store or Schema path. Authorised by owner decisions D11-21, D11-23, D11-24, D11-25 (11-CONTEXT.md:54-65).
- G-e: scheme drinkpulse.xcscheme: no EnvironmentVariables, no DP_RUN_*, no diff vs HEAD or vs 2aa9156.
- G-f: added production lines since 2aa9156 contain no URLSession/URLRequest/Network/print/Logger/NSLog/.public/analytics/HealthKit/UserDefaults additions; `try!`/`insert` hits are only inside #Preview blocks (DashboardView+Previews.swift, SettingsView.swift lines 209-232).
- G-g: git push state: `git branch -r --contains 2aa9156` = none; 170 commits ahead of origin/verify/phase-08...; no tag newer than v1.3. 123 commits since 2aa9156: all by the repo owner identity, grep for Co-Authored-By/Claude/Anthropic/Generated with = 0.
- G-h: DEVLOG at 2aa9156 is a byte-identical prefix of current docs/DEVLOG.md (283290 of 297319 bytes).


---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Status | Evidence |
|-----------|----------|-----------|----------|-------------|--------|----------|
| T-11-01 | Information Disclosure | Raw build logs and result bundles | medium | mitigate | closed | G-a: 0 tracked logs/bundles; build/ gitignored (.gitignore:54); 9 logs only in stamp dir; G-c digests all match. |
| T-11-02 | Information Disclosure | Simulator and MCP workspace identifiers | low | mitigate | closed | udid.txt and clone-udid.txt exist out-of-git; G-b 0 UUID-shaped strings in Phase 11 docs; clone UDID has 0 tracked hits; no workspaceN literal in 11-EVIDENCE.md. (Primary UDID value appears in 3 pre-existing Phase 10 files, see W1.) |
| T-11-03 | Tampering | Warning scan result | high | mitigate | closed | pbxproj has no SUPPRESS_WARNINGS/-suppress-warnings/-Wno-/TREAT_WARNINGS/OTHER_SWIFT_FLAGS and is unchanged since 2aa9156; added code has no @preconcurrency/@unchecked Sendable/nonisolated(unsafe)/#warning; release-device-build-3.log: exit 0, 0 gate-pattern warnings, only appintentsmetadataprocessor warning lines; digests of mcp-debug-build.log and release logs recorded in evidence and equal files. |
| T-11-04 | Repudiation | Stale or partial build read as result | medium | mitigate | closed | release-device-build{,-2,-3}.exit = 0 each; build-3 log has BUILD SUCCEEDED x1; separate logs with digests; superseded CLI debug-build.log and release-sim-build.log (no digest) are declared superseded in 11-01-SUMMARY.md:116-118, not used as evidence (W3). |
| T-11-05 | Repudiation | Debt ledger silently closing or hiding debt | high | mitigate | closed | all 14 open-questions headings at 2aa9156 occur in 11-DEBT-LEDGER.md; ledger statuses: 21 open, rows marked fixed/superseded carry owner re-run evidence plus verified sha256; WINDOWS rows 1-11 text unchanged; 08/09/10 VERIFICATION.md diff empty; open-questions.md and todos: additions only (0 deleted lines). |
| T-11-06 | Tampering | Discovery outcome claimed without a record | medium | mitigate | closed | 11-DISCOVERIES.md: 31 table rows, 26 backticked file+string pairs re-checked by exact lookup in real files = 26 ok, 0 mismatch; 2 GAP flags, none invented. |
| T-11-07 | Information Disclosure | Test names, todo text, fixtures quoted into ledger | low | mitigate | closed | G-b scans 0 UUID/email; ledger rows quote identifiers and status words. |
| T-11-08 | Tampering | Allow-list muting an unrecorded issue | high | mitigate | closed | Swift allow-list was created empty (9aaf759 `allowedIssues: []`) and removed; HEAD has no allowedIssues/ledgerID in drinkpulseUITests, so Swift IDs = ledger IDs (both empty); issues fail via XCTFail except explicit per-call owner opt-ins D11-28..D11-31 (see note N1). |
| T-11-09 | Tampering | Test hook reaching a production path | medium | mitigate | closed | UITestSeed.swift:6 isActive = launch arg `-dp_uitest`; only new hook forceReduceMotion (UITestSeed.swift:41) starts with `guard isActive`; probes render only under UITestSeed.isActive. |
| T-11-10 | Elevation of Privilege | Appearance left dark after a test | low | mitigate | closed | AccessibilityAuditSupport.swift pinAppearance: addTeardownBlock registered before appearance changes; restores prior value (unspecified becomes light). |
| T-11-11 | Information Disclosure | Issue text or labels quoted into ledger | low | mitigate | closed | seeded dataset synthetic (-dp_uitest_dataset multiday); G-b scans clean. |
| T-11-12 | Repudiation | Silent exception for unknown failure | high | mitigate | closed | final-full.result.txt Failed = exactly 4: InsightsUITests heroCard (DL-T01), HistoryInteractionUITests editCustomNameAndNotes (DL-T02), editCategoryChange (DL-T03), ExportUITests dismissWithoutSaving (DL-T04) = known list; no other Failed id. |
| T-11-13 | Information Disclosure | Test output or device-session values in evidence | low | mitigate | closed | G-b clean; evidence quotes counts/identifiers/PASS-FAIL. |
| T-11-14 | Tampering | Overstated data-safety claim | medium | mitigate | closed | 11-EVIDENCE.md:464 L-03 labels Phase 10 device proof historical and names changed production files since a38a75f; L-04 in-memory store limit cited in the VER-02 note (REQUIREMENTS.md:32). |
| T-11-15 | Denial of Service | Gated D1 harness crashing simulator | low | mitigate | closed | DP_RUN_FLASH_HARNESS only read in SheetDismissTabSwitchUITests; scheme sets no env; final-full shows the cycle and emptyStore harness tests Skipped. |
| T-11-16 | Repudiation | Unknown failure recorded as exception | high | mitigate | closed | same bundle read as T-11-12 (888 total, 866 passed, 4 failed = DL-T01..T04, 18 skipped). |
| T-11-17 | Tampering | Test edited/skipped/harness enabled to turn run green | high | mitigate | closed | G-e no DP_RUN_* in scheme; 18 skipped = 16 gated audit methods + 2 harness tests; no test is skipped to hide a failure; production edits limited to G-d set with owner approval (11-CONTEXT D11-21..D11-25), plan-time "only one code file" guard superseded by owner amendment (N2). |
| T-11-18 | Tampering | Coverage figure restated by hand | medium | mitigate | closed | recomputed from stamp coverage.json: drinkpulse.app 94.65 (10554/11151); Services excluding HealthKitAdapter/NotificationScheduling 97.15 (443/456) = recorded within 0.01; coverage.json mtime 15 Nov, never regenerated. |
| T-11-19 | Information Disclosure | Raw log or result bundle committed | medium | mitigate | closed | G-a; bundle build/p11-full.xcresult under gitignored build/. |
| T-11-20 | Information Disclosure | Owner session real data or screenshot | medium | mitigate | closed | checklist privacy rule at 11-A11Y-CHECKLIST.md:19 (PASS/FAIL/OPEN plus short note); G-b clean; 0 tracked images. |
| T-11-21 | Information Disclosure | Simulator identifier in checklist | low | mitigate | closed | clone-udid.txt out-of-git, 0 tracked hits; no UUID shape in checklist. |
| T-11-22 | Tampering | Accessibility settings leaking into later runs | medium | mitigate | closed | checklist steps address `<clone>` only; clone deleted (T-11-27); primary simulator is Shutdown and its UI settings read "unknown" (not observable, process evidence only). |
| T-11-23 | Repudiation | Human item marked passed without being performed | high | mitigate | closed | checklist forbids pass from automated/inferred evidence (:15); CHK-00/01/02/10 recorded open with reason CHK-00; CHK-03 and CHK-07 recorded open; pass results carry owner re-run notes with build hash. |
| T-11-24 | Repudiation | Human result recorded as pass without owner performing | high | mitigate | closed | unanswered items kept open (result: open x6); Audio Graph dependent items forced open; notes state "Observed by the owner on a cloned simulator" and relay origin of statements (:7, :185, :201). |
| T-11-25 | Information Disclosure | Personal data or identifiers in notes | medium | mitigate | closed | G-b scans clean; notes are short words. |
| T-11-26 | Tampering | Production code changed to make a Reduce Motion item pass | high | mitigate | closed | production Reduce Motion gating came from owner decision D11-23 (11-CONTEXT:61) and briefs 11-DECISION-C014/C015, not unilateral; DPMotion.animation used at DPArcProgress:32, ConsumptionOverviewCard:121, HistoryCalendarView:63; owner re-ran CHK-05/06/04 to pass. |
| T-11-27 | Denial of Service | Leftover clone | low | mitigate | closed | `xcrun simctl list devices`: 0 entries for the clone UDID and 0 for name dp-phase11-a11y. |
| T-11-28 | Tampering | Requirement ticked despite failed/contradicted check | high | mitigate | closed | VER-03 [x]/Complete with open items listed one by one (REQUIREMENTS.md:33,64); ver03-decision.txt = tick; checklist: original fails CHK-04/05/06 re-run to pass on owner observation; CHK-07 history (fail, re-run fail, 11-23 passes) ends as owner-set open at 11-24 (checklist:172-185), fail history preserved (N3). |
| T-11-29 | Repudiation | Frozen records or debt rows rewritten | high | mitigate | closed | WINDOWS.md rows 1-11 unchanged (diff = header counts, tool template text and new row 12, fixed by 11-11); 08/09/10 VERIFICATION.md diff empty; DEVLOG prefix identical (G-h); open-questions.md +61/-0, current-focus.md living doc update, todo file added only. |
| T-11-30 | Information Disclosure | Identifier or health value in final evidence | low | mitigate | closed | G-b clean; inherited figures labelled historical. |
| T-11-31 | Repudiation | DEVLOG history rewritten | medium | mitigate | closed | G-h byte-identical prefix: True. |
| T-11-32 | Information Disclosure | Identifier/log/health value in committed docs | high | mitigate | closed | G-a and G-b: 0 UUID-shaped strings in Phase 11 docs and in all added doc lines since 2aa9156; 0 tracked logs/bundles; 0 emails. |
| T-11-33 | Tampering | Unplanned production, project or schema change | high | mitigate | closed | G-d: xcodeproj/Domain/Services/Models/entitlements/schema diff empty (deployment target and schema untouched); 54 production paths all in the accessibility/design-system/view set under owner decisions; Info.plist change is the single D11-21 line. |
| T-11-34 | Elevation of Privilege | Unapproved publication | medium | mitigate | closed | G-g: no remote branch contains any commit since 2aa9156; no new tag. |
| T-11-35 | Tampering | Allow-list extended without ledger row | high | mitigate | closed | no allow-list entries exist at HEAD (see T-11-08); only explicit per-call opt-ins tied to owner decisions D11-28..D11-31 (N1). |
| T-11-36 | Repudiation | Secondary-destination failure waved through | high | mitigate | closed | S1 16 skipped 0 failed; S2 23 of 23 passed (11-EVIDENCE.md:116); no unmapped failures. |
| T-11-37 | Tampering | Wrong destination left active | low | mitigate | closed | 11-10-SUMMARY.md:52 and evidence state `active destination restored` to iPhone 18 Pro, confirmed via XcodeListRunDestinations. |
| T-11-38 | Information Disclosure | Simulator identifier in evidence | low | mitigate | closed | evidence names model, runtime, build only; G-b clean. |
| T-11-40 | Elevation of Privilege | iPad orientation change alters iPhone | low | mitigate | closed | Info.plist diff = one added line inside `UISupportedInterfaceOrientations~ipad` (:52); iPhone key (:43-46) lists Portrait only. |
| T-11-41 | Information Disclosure | Raw build logs with machine paths committed | low | mitigate | closed | G-a; only counts and digests in evidence. |
| T-11-42 | Repudiation | Corrected counts restated by hand | high | mitigate | closed | recomputation commands recorded in 11-EVIDENCE.md:274-282; I re-ran: audit-exploratory.txt 311 lines, `LC_ALL=C sort -u | wc -l` = 311, matches. |
| T-11-43 | Tampering | Harness change that hides an issue | high | mitigate | closed | handler records XCTFail for every issue (AccessibilityAuditSupport.swift recordAuditIssue path); navigation failure XCTAsserts then returns (AccessibilityAuditUITests.swift:85-104); no XCTExpectFailure/subtracting/type exclusion in drinkpulseUITests; only explicit per-call opt-ins D11-28..31 (N1). |
| T-11-44 | Information Disclosure | Unlabeled-element frame/text committed | low | mitigate | closed | keys hold type and rounded frame (AccessibilityAuditSupport.swift unlabeledKey); G-b clean; synthetic data. |
| T-11-45 | Tampering | Scheme env var left set or committed | high | mitigate | closed | G-e: 0 occurrences of DP_RUN_A11Y_AUDIT in scheme, no diff vs HEAD or 2aa9156; ungated runs show 16 skipped (audit-gated*.result.txt, final-full 18 skipped). |
| T-11-46 | Repudiation | Baseline read from a closed gate or navigation failure | high | mitigate | closed | audit-baseline.counts.txt 16 failed 0 skipped (gate open); navigation failure fails test (AccessibilityAuditUITests.swift:85-104); 0 navigation/appearance-restore failure lines in audit-final logs. |
| T-11-47 | Information Disclosure | Frame or console text copied into evidence | low | mitigate | closed | G-b clean; only coarse element type/frame classes. |
| T-11-48 | Elevation of Privilege | -dp_uitest_reduce_motion reachable in production | medium | mitigate | closed | UITestSeed.swift:41-48 forceReduceMotion = `guard isActive` then arg check; DPMotionProbe.swift renders only inside `if UITestSeed.isActive`. |
| T-11-49 | Tampering | Reduce Motion reported by probe without gating animation | medium | mitigate | closed | DPMotion.animation and DPMotionProbe both at the 3 sites (DPArcProgress:27/32, ConsumptionOverviewCard:78/121, HistoryCalendarView:63/64); isReduced shared by probe and animation. |
| T-11-50 | Information Disclosure | Owner session notes | low | mitigate | closed | G-b clean; clone-udid out-of-git. |
| T-11-51 | Information Disclosure | Probe exposing Health sample count outside tests | low | mitigate | closed | `dp_health_sample_count` appears once in production (RootShellView.swift:84-93), inside `if UITestSeed.isActive`. |
| T-11-52 | Tampering | Helper hides a type/issue so later tests pass | high | mitigate | closed | helper takes `types:` from caller (all tests pass `.all`), no hard-coded type or allow-list; documented exceptions are explicit per-call parameters logged as warning issues (N1). |
| T-11-53 | Repudiation | AX5 test passes because audit cannot see defect | medium | mitigate | closed | AX5 classes plus structural assertions exist (*DynamicTypeUITests, 6 files); owner CHK-07 re-observation recorded (checklist:159-185). |
| T-11-54 | Tampering | Layout change alters saved data/flow | medium | mitigate | closed | G-d: no Domain/Service/Model/ViewModel path; removed-line scan shows persistence bindings preserved (SettingsView abvPrecision/currency still `touching(\.…)`); flow UI classes passed in final-full (888 run). |
| T-11-55 | Information Disclosure | Owner session notes | low | mitigate | closed | G-b clean. |
| T-11-56 | Tampering | Contrast fix hides content / weakens other screens | medium | mitigate | closed | home-t2-tokens/add-t2-tokens regression result files exist and pass; no new accessibilityHidden added to chart/marks (diff scan 0). |
| T-11-57 | Repudiation | Green audit read from single run | medium | mitigate | closed | home-t2-run1 and run2: 3/3 passed each, both saved. |
| T-11-58 | Tampering | Contrast fix hides content / weakens other screens | medium | mitigate | closed | add-t2-regression and add-t2-tokens result files present; no hiding. |
| T-11-59 | Repudiation | Green audit read from single run | medium | mitigate | closed | add-t2-run1 and run2: 2/2 passed each, both saved (superseded runs kept separately). |
| T-11-60 | Tampering | Mark labels disagree with chart data | medium | mitigate | closed | InsightsAccessibilityAuditUITests.swift:79 test_insights_standard_markLabelMatchesCallout compares mark value with scrubbed hero value (:103-106). |
| T-11-61 | Tampering | Hiding chart marks to pass audit | high | mitigate | closed | `git diff fc506f4 HEAD` on AlcoholAreaChart+Accessibility.swift and WeekdayBarChart+Accessibility.swift = empty; accessibilityChartDescriptor call count 1 per chart, same as fc506f4; 0 added accessibilityHidden in the two chart files. |
| T-11-62 | Repudiation | Green audit read from single run | medium | mitigate | closed | ins-t2-run1 and run2: 4/4 passed each, both saved. |
| T-11-63 | Tampering | Fix hides unlabeled element / weakens screens | medium | mitigate | closed | home-t2-g09-diag/regression result files present; element made locatable (11-20-SUMMARY); cumulative run cum-t3-audit-final passes. |
| T-11-64 | Repudiation | Green audit read from single run | medium | mitigate | closed | set-t2-run1 and run2: 3/3 passed each, saved. |
| T-11-65 | Tampering | Scheme env var left set or committed | high | mitigate | closed | same as T-11-45; no diff on scheme; ungated class skips 16 of 16. |
| T-11-66 | Repudiation | Pass read from gate not open / nav failed | high | mitigate | closed | audit-final.counts.txt: passed 16, skipped 0, failed 0, total 16; 0 navigation-failure and 0 appearance-restore lines in audit-final.console.txt/result.txt. |
| T-11-67 | Tampering | Residual findings muted to reach green | high | mitigate | closed | no allow-list; no audit type excluded; residual per-call opt-ins D11-29/30/31 are owner-approved, logged as warning issues (33 recorded in audit-final) and listed as DL-O25 owner-accepted debt (N1). |
| T-11-68 | Repudiation | VER-03 ticked despite failed check / open items hidden | high | mitigate | closed | ver03-decision.txt = tick; REQUIREMENTS.md VER-03 note lists CHK-00,01,02,10,03,07(DL-O19) and OBS-A/C open; no effective fail result. |
| T-11-69 | Information Disclosure | Identifier/log/personal value in committed doc | high | mitigate | closed | G-a, G-b; clone UDID 0 tracked hits. |
| T-11-70 | Tampering | Unplanned production change with documents | high | mitigate | closed | G-d; `git rev-parse HEAD:drinkpulse` = e252da14... equals final-prod-tree.txt; no drinkpulse/ change since 3f70ff6. |
| T-11-71 | Tampering | History fix hides element / weakens screens | medium | mitigate | closed | his-t2-attempt* and his-t2-regression result files; element located by experiment (11-21-SUMMARY); D11-31 opt-in is element-less contrast only, logged. |
| T-11-72 | Repudiation | Green audit read from single run | medium | mitigate | closed | onb-t1-run1 and run2: 2/2 passed each; History: owner-directed his-t2-confirm plus cum-t3-audit-final (deviation from 2 consecutive runs disclosed in 11-21-SUMMARY). |
| T-11-73 | Repudiation | Human pass recorded on a build it was not observed on | high | mitigate | closed | checklist CHK-08/09 re-run blocks name plan 11-23 and build 3f70ff6 (:198-217); production tree unchanged since 3f70ff6. |
| T-11-74 | Tampering | CLI run beyond approval / coverage restated | medium | mitigate | closed | coverage-decision.txt = accept-debt, so no CLI coverage run: coverage.json/coverage.txt mtime 15 Nov, no newer xcresult; D11-33 recorded (11-CONTEXT:80); 94.65 and 97.15 recomputed equal (see T-11-18). |
| T-11-75 | Information Disclosure | Identifier/log/personal value in doc or ADR | high | mitigate | closed | G-b over added lines since 2aa9156 = 0; ADR 0013 (42 lines) has no data values (scan 0). |
| T-11-76 | Repudiation | MOD-04/VER-01 Release evidence predating final build, or CLI run without answer | high | mitigate | closed | release-decision.txt = cli-build written 11:57:10, build-3 run 11:58:16 (after answer); exit 0, BUILD SUCCEEDED, 0 gate-pattern warnings, 0 deprecation warnings (the 2 "deprecat" hits are build-setting exports), 0 orientation notice, only appintentsmetadataprocessor warning lines; digest 0b6456f9... in evidence; production tree = final-prod-tree.txt. |
| T-11-77 | Repudiation | MOD-04 complete with stale Release evidence | high | mitigate | closed | REQUIREMENTS.md:20, :31 and 11-EVIDENCE.md:520 all name build 3f70ff6 / tree e252da14 and D11-32; evidence MOD-04 Outcome cell starts "complete"; L-10 stated not applicable. |
| T-11-78 | Repudiation | VER-01/VER-02 reason/confirmation gaps | high | mitigate | closed | ver01/ver02-decision.txt = tick; REQUIREMENTS.md checkboxes [x] and rows Complete; VER-01 note cites D11-32/D11-33 with the plan-text ids D11-28/D11-29 and states coverage accept-debt; no keep-open row. |
| T-11-SC | Tampering | Package-manager installs (23 plan rows, plans 01-10, 12-24) | low | accept | closed | no Package.resolved/Package.swift/package.json/requirements/Cargo path changed since 2aa9156; xcodeproj diff empty (no SPM reference added). Orchestrator must add the accepted-risk entry to SECURITY.md (no SECURITY.md exists for the accept log). |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-11-01 | T-11-08, T-11-43, T-11-52, T-11-67 | The audit helpers carry per-call exemptions D11-28 to D11-31 (each ignored issue logged as a warning). Code review 2 found them broader than the decisions describe (WR-01 to WR-03); residual: a green audit does not prove absence of issues inside those bands. Carried as debt DL-O25. | Owner | 2026-11-18 |
| AR-11-02 | T-11-SC | Supply-chain risk accepted: no dependency or package file changed since 2aa9156; the app has no third-party SDKs. | Owner (plan-time disposition accept) | 2026-11-18 |

---

## Informational Notes (not registered, low)

- W1: the primary simulator UDID appears in three tracked Phase 10 files from 2026-11-08/09 (10-02-SUMMARY.md, 10-09-SUMMARY.md, 10-RESEARCH.md); predates Phase 11.
- W2: 14 Phase 11 PLAN files (11-11 to 11-24) embed the absolute repository path in verify commands.
- W3: two superseded CLI logs from plan 11-01 (debug-build.log, release-sim-build.log) have no recorded digest; 11-01-SUMMARY.md declares them superseded.
- W4: WINDOWS.md header counts and template text changed and row 12 was appended by the tool; rows 1 to 11 are intact.
- N2: plan-time guards stating that production was unchanged no longer hold literally after gap closure; they are replaced by the allowed-set check under owner decisions D11-21 to D11-25.

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-11-18 | 78 | 78 | 0 | gsd-security-auditor (ASVS L1) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-11-18
