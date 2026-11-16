---
phase: 11-ios-27-release-verification
reviewed: 2026-11-16T00:00:00Z
depth: standard
files_reviewed: 2
files_reviewed_list:
  - drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift
  - drinkpulse/Info.plist
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-11-16
**Depth:** standard
**Files Reviewed:** 2
**Status:** issues_found

## Summary

Scope: the only Phase 11 code changes (`git diff 2aa9156..HEAD` over app and test sources). The audit's gating and allow-list decision (D11-22) were treated as intended, not as defects.

Verified clean:
- Gate (AccessibilityAuditUITests.swift:37-55): `setUpWithError` calls `XCTSkipUnless` before any launch, reading `DP_RUN_A11Y_AUDIT` from the runner process environment. Apple documents that a skip thrown from setup marks every method skipped. The pattern matches `SheetDismissTabSwitchUITests` (`DP_RUN_FLASH_HARNESS`); `TEST_RUNNER_` is the correct xcodebuild prefix. `continueAfterFailure = true` is set only after the skip, so a skipped run is unaffected.
- Apple API claims (checked via Xcode MCP DocumentationSearch): `XCUIDevice.appearance` is get/set; `XCTSkipUnless(_:_:file:line:)` matches the used signature; `XCUIApplication.performAccessibilityAudit(for:_:)` exists, and the issue handler returning `true` means handled, so no duplicate failure is recorded.
- Launch arguments `-dp_force_onboarding`, `-dp_uitest_unit` and `-dp_uitest_dataset` exist in `drinkpulse/UITestSeed.swift`.
- Info.plist: the only change adds `UIInterfaceOrientationPortraitUpsideDown` to `UISupportedInterfaceOrientations~ipad` (D11-21). `GENERATE_INFOPLIST_FILE = NO` and `INFOPLIST_FILE = drinkpulse/Info.plist` for the app target, with no `INFOPLIST_KEY_*` orientation override, so the plist is authoritative. iPhone stays portrait-only; no `UIRequiresFullScreen` was added. No living doc contradicts it.
- Cross-references: the todo `2026-11-14-fix-accessibility-audit-findings` and the `11-EVIDENCE.md` section "Accessibility audit (exploratory run, D11-22)" both exist.
- Concurrency and conventions: no force-unwraps, no `print`, no network. The class is `@MainActor`, and the dark-restore teardown correctly hops with `MainActor.run`. The file is 180 lines.

## Warnings

### WR-01: Navigation failures do not stop the audit, so issues are recorded against the wrong screen

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift:41, 94-125`
**Issue:** `setUpWithError` sets `continueAfterFailure = true`. `open(_:in:)` only uses `XCTAssertTrue`, so when a tab, nav bar or Add Drink button is missing (likely at AX5 or after a UI change), the test records one failure and still calls `performAccessibilityAudit` on whatever screen is showing. The resulting issue lines carry `screen=Insights` (or similar) while describing another screen. The `11-EVIDENCE.md` record is keyed by exactly those `screen=... variant=...` strings, and its counts and digests derive from them, so a navigation failure silently corrupts the evidence instead of failing cleanly. The `.addDrink` path is the most exposed: a failed `add.tap()` audits Home under the label "Add Drink".
**Fix:** Have `open` return success and skip the audit when it fails:
```swift
private func open(_ screen: AuditScreen, in app: XCUIApplication) -> Bool { /* return the waitForExistence results */ }

private func audit(screen: AuditScreen, variant: AuditVariant) throws {
    let app = launchApp(screen: screen, variant: variant)
    guard open(screen, in: app) else { return } // navigation failure already recorded
    try app.performAccessibilityAudit(for: .all) { [self] issue in
        record(issue, screen: screen, variant: variant)
    }
}
```
Alternatively, set `continueAfterFailure = false` around navigation and restore it to `true` just before the audit call.

### WR-02: The `standard` and `ax5` variants do not pin the appearance, so results depend on the simulator's ambient mode

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift:59-70`
**Issue:** Only `.dark` touches `XCUIDevice.shared.appearance`. The `standard` and `ax5` variants run in whatever appearance the simulator currently has. If a previous run was interrupted (crash or killed runner), the teardown never runs and the device stays dark. Those variants are then audited in dark mode while labelled `variant=standard` / `variant=ax5`, which skews contrast results (144 of 311 findings are contrast). The restore logic makes this worse: `restored = previous == .unspecified ? .light : previous` restores `.dark` when `previous` was already dark, so a leaked dark state never heals itself.
**Fix:** Pin the appearance explicitly for every variant and always restore the pre-test value:
```swift
let previous = XCUIDevice.shared.appearance
let restored: XCUIDevice.Appearance = previous == .unspecified ? .light : previous
addTeardownBlock { await MainActor.run { XCUIDevice.shared.appearance = restored } }
XCUIDevice.shared.appearance = (variant == .dark) ? .dark : .light
```

## Info

### IN-01: `nonisolated static` on the gate helper is unexplained and inconsistent with the sibling pattern

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift:46`
**Issue:** The helper only reads `ProcessInfo` and is called from `setUpWithError` of a `@MainActor` class, so `nonisolated` is not needed. The reference gate in `SheetDismissTabSwitchUITests` is a plain `private func`. A reader cannot tell whether the keyword guards a real isolation problem.
**Fix:** Drop `nonisolated static`, or add a one-line comment saying why it is required.

### IN-02: The literal "311" is hard-coded in two places and will go stale

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift:6, 44, 50`
**Issue:** The doc comment and the skip reason both embed the count. Once any finding is fixed under its owner brief, the skip message misreports the audit's state.
**Fix:** Keep the count only in `11-EVIDENCE.md`. Word the comment and skip message as "open findings recorded in 11-EVIDENCE.md".

### IN-03: The audit matrix omits the dark variant for Add Drink and Onboarding

**File:** `drinkpulseUITests/Features/Shell/AccessibilityAuditUITests.swift:176-179`
**Issue:** Home, Insights, History and Settings get standard, ax5 and dark. Add Drink and Onboarding get only standard and ax5. Contrast in dark mode is therefore unaudited on two screens, while SC4 in `11-EVIDENCE.md` claims "light and dark". The "Limits" paragraph of the doc comment does not note the omission.
**Fix:** Add `test_audit_addDrink_dark` and `test_audit_onboarding_dark`, or state the omission under "Limits" so the record stays accurate.

---

_Reviewed: 2026-11-16_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
