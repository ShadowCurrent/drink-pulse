---
phase: quick-261112-kvl
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - drinkpulse/Features/Settings/AppVersionInfo.swift
  - drinkpulse/Features/Settings/Components/AppVersionFooter.swift
  - drinkpulse/Features/Settings/SettingsView.swift
  - drinkpulse/Localizable.xcstrings
  - drinkpulseTests/Features/Settings/AppVersionInfoTests.swift
  - drinkpulseUITests/Features/Settings/AppVersionUITests.swift
  - README.md
  - docs/DEVLOG.md
  - .claude/context/open-questions.md
  - .claude/context/current-focus.md
autonomous: true
requirements:
  - QUICK-261112-kvl
user_setup: []

estimate:
  tokens: 25000
  raw_tokens: 25000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "The very last element of the Settings screen (below the Data section's 'Delete all data' row) is a centered footnote reading 'Version X (Y)', where X is CFBundleShortVersionString and Y is CFBundleVersion read from Bundle.main.infoDictionary at runtime."
    - "A Debug build additionally shows ' · Debug' after the version and a second line 'Built yyyy-MM-dd HH:mm' (local time) taken from the executable's last-modified time; a Release build shows ONLY 'Version X (Y)' (the clean production format)."
    - "The file-timestamp read exists only inside a #if DEBUG region, so the Release binary contains no file-timestamp API call and needs no privacy-manifest declaration (Apple lists FileAttributeKey.modificationDate/creationDate as required-reason APIs; the repo has no PrivacyInfo.xcprivacy)."
    - "Formatting is a pure value type (AppVersionInfo) with unit tests for every branch (release, debug with/without date, missing/empty/non-string keys); a UI test pins presence, position (below 'Delete all data') and the 'Version X (Y)' format."
    - "The text is selectable/copyable, wraps at Dynamic Type AX5, and has no project.pbxproj edit (the unrelated uncommitted IPHONEOS_DEPLOYMENT_TARGET hunk stays untouched and unstaged)."
  artifacts:
    - "drinkpulse/Features/Settings/AppVersionInfo.swift — value type: init(infoDictionary:buildDate:isDebug:), displayText, static formatBuildDate(_:timeZone:), static current (Bundle.main + DEBUG-only executable timestamp)."
    - "drinkpulse/Features/Settings/Components/AppVersionFooter.swift — footnote Text with accessibilityIdentifier 'settings.appVersion', textSelection enabled, previews (release-like, debug-like, AX5)."
    - "drinkpulseTests/Features/Settings/AppVersionInfoTests.swift — Swift Testing suite, @MainActor."
    - "drinkpulseUITests/Features/Settings/AppVersionUITests.swift — XCUITest for the footer."
  key_links:
    - "drinkpulse/Info.plist CFBundleShortVersionString=$(MARKETING_VERSION) and CFBundleVersion=$(CURRENT_PROJECT_VERSION) (GENERATE_INFOPLIST_FILE=NO, INFOPLIST_FILE=drinkpulse/Info.plist, MARKETING_VERSION=1.0, CURRENT_PROJECT_VERSION=1 at project.pbxproj lines 424-433 and 454-463) -> Bundle.main.infoDictionary -> AppVersionInfo.current -> AppVersionFooter -> SettingsForm's outer VStack, placed directly after DataSection()."
    - "AppVersionInfo.current is a static let (evaluated once per launch) so the DEBUG file-attribute read does not repeat on every SettingsForm body evaluation."
---

<objective>
Show the app's version at the bottom of the Settings screen so it works for the developer now (Debug
builds, which can be told apart by build time) and for normal users in production (clean
"Version 1.0 (1)").

Purpose: the owner asked (Polish original, translated) to "add info about the current version, e.g. by
tag or build number, and maybe a date, so it works for me as a developer and in production for a
standard user". Build number is currently constant (CURRENT_PROJECT_VERSION = 1), so the developer
needs the build time to distinguish Debug installs; production users only need version and build.

Output: AppVersionInfo (pure, tested), AppVersionFooter (view), one line added to SettingsView, five
localization keys, unit + UI tests, README/DEVLOG/open-questions/current-focus updates.

Scope decisions (planner, with rationale; none contradict the orchestrator constraints):
- No project.pbxproj edit. All three targets are file-system-synchronized, so new files are picked up
  automatically. The unrelated uncommitted pbxproj hunk (IPHONEOS_DEPLOYMENT_TARGET, +2/-0 baseline)
  must stay unstaged and uncommitted.
- Git tag / commit hash via a Run Script phase is OUT of scope: it needs a pbxproj edit and a build
  phase, which is not trivially safe next to the unrelated pbxproj hunk. Recorded as a rejected
  alternative in DEVLOG (Task 3).
- The build date is shown in DEBUG builds only. Reason (verified, see context): reading a file's
  timestamp uses an API Apple classes as "required reason" (NSPrivacyAccessedAPICategoryFileTimestamp),
  the repo has no privacy manifest, and Apple does not document that an executable's timestamp equals
  the build date for App Store / TestFlight installs (it may be the install or processing time, which
  would show users a wrong "Built" date). Compiling the read out of Release avoids both problems.
  Showing a date to production users needs a build-time source (script phase or Info.plist
  preprocessing, both pbxproj edits) plus a manifest; logged as an open question in Task 3.

Source audit (all four types):
- GOAL: version info at bottom of Settings, dev + production -> Tasks 1, 2.
- REQ: none mapped for this quick task (QUICK-261112-kvl placeholder ID) -> n/a.
- RESEARCH: none (no research phase) -> n/a.
- CONTEXT: orchestrator constraints (no pbxproj edit, runtime derivation, Debug marker, pure tested
  formatter, existing Settings patterns, String Catalog, accessibility, optional selectable text,
  repo-relative paths, build + tests via xcodebuild) -> Tasks 1-3; git tag/commit via script is
  explicitly excluded above. No CONTEXT.md D-xx decisions exist for quick tasks.
</objective>

<execution_context>
@~/.claude/gsd-core/workflows/execute-plan.md
@~/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@AGENTS.md
@drinkpulse/Info.plist
@drinkpulse/Features/Settings/SettingsView.swift
@drinkpulse/Features/Settings/Components/SettingsSection.swift
@drinkpulseUITests/Features/Settings/SettingsUITests.swift

Apple documentation consulted by the planner (Xcode MCP DocumentationSearch is not exposed to the
planner, so developer.apple.com documentation JSON was used; the executor MUST re-confirm each item
through Xcode MCP DocumentationSearch before implementing and record the source in the SUMMARY):
- Bundle.infoDictionary: "A dictionary, constructed from the bundle's Info.plist file, that contains
  information about the receiver." Available iOS 2.0+ (project targets iOS 27.0).
- FileAttributeKey.modificationDate: "The key in a file attribute dictionary whose value indicates the
  file's last modified date." Available iOS 2.0+. Apple states apps must declare its use in a
  PrivacyInfo.xcprivacy file.
- NSPrivacyAccessedAPICategoryFileTimestamp: lists FileAttributeKey.creationDate and
  FileAttributeKey.modificationDate among APIs requiring a reason. Reason DDA9.1 = "display file
  timestamps to the person using the device" (must not be sent off-device); C617.1 = files inside the
  app container; 3B52.1 = user-granted files; 0A2A.1 = third-party SDK wrappers only.
- Still to confirm by the executor via MCP: Bundle.executableURL, FileManager.attributesOfItem(atPath:),
  DateFormatter (dateFormat, locale, calendar, timeZone), View.textSelection(_:), Text accessibility.

Project facts verified by the planner:
- SettingsForm (SettingsView.swift) is a ScrollView > VStack(spacing: 20) of SettingsSection cards
  ending with DataSection(); 201 lines. Footnote text elsewhere uses .font(.footnote) with
  secondary styling (HealthSection, ReminderSection).
- 'Delete all data' (key settings.data.deleteAll) is the last row of DataSection, so it is the last
  existing element.
- App target default actor isolation is MainActor (types are implicitly @MainActor); the unit test
  target is hosted (TEST_HOST), so String(localized:) resolves against the app bundle, and tests that
  touch app types are written as @MainActor structs (see EventRowStringsTests).
- Localization pattern for formatted keys: manual-extraction catalog entries with printf placeholders
  formatted via String(format: String(localized: String.LocalizationValue(key)), args).
- DEBUG is defined for the Debug configuration (SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)").
- No PrivacyInfo.xcprivacy exists in the repo (planner searched, excluding build/).
</context>

<!-- planner-discipline-allow: attributesOfItem -->
<!-- planner-discipline-allow: modificationDate -->
<!-- planner-discipline-allow: creationDate -->

<tasks>

<task type="tracer">
  <name>Task 1: Tracer - "Version X (Y)" row at the bottom of Settings, end to end</name>
  <files>drinkpulse/Features/Settings/AppVersionInfo.swift, drinkpulse/Features/Settings/Components/AppVersionFooter.swift, drinkpulse/Features/Settings/SettingsView.swift, drinkpulse/Localizable.xcstrings, drinkpulseUITests/Features/Settings/AppVersionUITests.swift</files>
  <precondition>LOCAL_IOS_27_UDID is exported to an available, booted-or-bootable iOS 27 simulator (see AGENTS.md "Local iOS 27 simulator destination"). Assert with: test -n "$LOCAL_IOS_27_UDID"</precondition>
  <action>
Wire ONE path through every layer: Info.plist values -> pure formatter -> view -> Settings screen -> UI test. Release-format only in this task; Task 2 adds the Debug extras.

First consult Xcode MCP DocumentationSearch for Bundle.infoDictionary and View.textSelection(_:) (iOS 27) and note the sources for the SUMMARY (AGENTS.md "No guessing").

1. Create `drinkpulse/Features/Settings/AppVersionInfo.swift`: a `struct AppVersionInfo: Equatable, Sendable` holding `version: String?` and `build: String?`, and an `init(infoDictionary: [String: Any]?)` that reads the `CFBundleShortVersionString` and `CFBundleVersion` keys as `String` only (non-String values, missing keys, and empty or whitespace-only strings all become nil). Add a computed `displayText: String` that returns: both present -> "Version %1$@ (%2$@)" via key `settings.version.full`; version only -> key `settings.version.only` ("Version %@"); version missing (even if build exists) -> key `settings.version.unknown` ("Version unavailable"). Format with String(format: String(localized: String.LocalizationValue(key)), ...) exactly like `abvPrecisionLabel` in SettingsView.swift does. Add `static let current = AppVersionInfo(infoDictionary: Bundle.main.infoDictionary)` so the read happens once per launch. No force-unwraps, no logging of the values beyond nothing at all (no logger needed).

2. Add the three catalog entries to `drinkpulse/Localizable.xcstrings` between `settings.systemLock.footer` and `settings.volumeUnit` (alphabetical: settings.version.* sorts before settings.volumeUnit), each with `"extractionState" : "manual"`, English `stringUnit` `state` `translated`: `settings.version.full` = "Version %1$@ (%2$@)", `settings.version.only` = "Version %@", `settings.version.unknown` = "Version unavailable". Mirror the exact JSON shape of the neighbouring entries (2-space indentation, space-colon-space style) and keep the file valid JSON.

3. Create `drinkpulse/Features/Settings/Components/AppVersionFooter.swift`: `struct AppVersionFooter: View` with `var info: AppVersionInfo = .current`. Body is a single `Text(info.displayText)` with `.font(.footnote)`, `.foregroundStyle(.secondary)` (same style the other footnotes use, so contrast matches existing screens), `.multilineTextAlignment(.center)`, `.frame(maxWidth: .infinity)`, `.fixedSize(horizontal: false, vertical: true)` so it wraps instead of truncating at AX5, `.textSelection(.enabled)` (long-press copy, per the optional constraint), and `.accessibilityIdentifier("settings.appVersion")`. It is non-interactive, so no accessibilityLabel is required; the text itself is the VoiceOver label. Add a `#Preview` using a fixed `AppVersionInfo(infoDictionary: ["CFBundleShortVersionString": "1.0", "CFBundleVersion": "1"])` (previews are mandatory per AGENTS.md).

4. Edit `drinkpulse/Features/Settings/SettingsView.swift`: add `AppVersionFooter()` as the last child of the outer `VStack(spacing: 20)`, immediately after `DataSection()`. No other change to that file (it stays far below the 300-line ceiling).

5. Create `drinkpulseUITests/Features/Settings/AppVersionUITests.swift`: `@MainActor final class AppVersionUITests: XCTestCase` with `continueAfterFailure = false`, launching with the same launch arguments as SettingsUITests (`-dp_onboarding_done YES`, `-dp_uitest YES`, `-dp_uitest_unit metric`). One test named exactly `test_appVersionRow_isShownBelowDataSection_inVersionFormat`: open the Settings tab (wait up to 10 s, then wait for the "Settings" navigation bar), swipe up (max 8 times) until the button labelled "Delete all data" is hittable, then locate the version element with `app.descendants(matching: .any).matching(identifier: "settings.appVersion").firstMatch` (type-agnostic on purpose: textSelection may change the element type) and assert (a) it exists within 5 s, (b) its label matches the pattern `(?s)Version [0-9]+(\.[0-9]+)* \([0-9]+\).*` via an NSPredicate MATCHES (`(?s)` because Task 2 adds a second line in Debug), and (c) its `frame.minY` is greater than the "Delete all data" button's `frame.maxY` (proves it sits below the last Data row). Do not assert the literal "Debug" and do not hardcode "1.0" or "1" (MARKETING_VERSION will change). App-rendered text is English-only, so asserting on it is locale-safe (AGENTS.md).

Do NOT edit drinkpulse.xcodeproj/project.pbxproj: the drinkpulse and drinkpulseUITests targets are file-system-synchronized, so the new files are included automatically.
  </action>
  <verify>
    <automated>test -n "$LOCAL_IOS_27_UDID" && python3 -c "import json; json.load(open('drinkpulse/Localizable.xcstrings'))" && xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -only-testing:drinkpulseUITests/AppVersionUITests > build/appversion-ui.log 2>&1 && grep -q 'test_appVersionRow_isShownBelowDataSection_inVersionFormat' build/appversion-ui.log</automated>
  </verify>
  <done>Opening Settings and scrolling to the bottom shows a centered footnote "Version 1.0 (1)" below "Delete all data"; the UI test ran (its name is in the log) and passed; the catalog is valid JSON; project.pbxproj was not touched by this task; build is warning-free for the new files.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Debug marker + DEBUG-only build time, with full unit coverage</name>
  <files>drinkpulse/Features/Settings/AppVersionInfo.swift, drinkpulse/Features/Settings/Components/AppVersionFooter.swift, drinkpulse/Localizable.xcstrings, drinkpulseTests/Features/Settings/AppVersionInfoTests.swift</files>
  <behavior>
    - Release, version "1.0" + build "1": displayText == "Version 1.0 (1)" (no "Debug", no "Built").
    - Release with a buildDate supplied: still "Version 1.0 (1)" (production never shows a date, even if one is passed).
    - Debug, version + build, no date: "Version 1.0 (1) · Debug" (single line).
    - Debug with a date: "Version 1.0 (1) · Debug" newline "Built " + AppVersionInfo.formatBuildDate(date).
    - formatBuildDate(date, timeZone: UTC) for 2026-11-12 14:32:00 UTC == "2026-11-12 14:32"; the same instant in a non-UTC zone (e.g. Europe/Warsaw, UTC+1 in November) == "2026-11-12 15:32"; 00:05 renders zero-padded as "00:05"; output is locale-independent (digits are ASCII even under an Arabic or Polish default locale).
    - version "1.0", build missing / empty / whitespace-only / non-String: "Version 1.0".
    - version missing (nil dictionary, dictionary without keys, non-String value, empty string) -> "Version unavailable", even when build exists; Debug adds " · Debug" to that too.
    - AppVersionInfo.current wiring: version is non-nil, non-empty, and does not contain "$(" (Info.plist placeholder expanded); build likewise; under #if DEBUG, isDebug is true and buildDate is non-nil (the hosted test process has an executable on disk).
  </behavior>
  <action>
Extend AppVersionInfo for Debug builds. Write the tests first (they exercise the behaviors above; the Release-format cases already pass from Task 1, the Debug and date cases must fail first), then implement. Before implementing consult Xcode MCP DocumentationSearch for Bundle.executableURL, FileManager.attributesOfItem(atPath:), FileAttributeKey.modificationDate, and DateFormatter (dateFormat / locale / calendar / timeZone); record the sources, availability (all long-standing, iOS 2.0+ per the planner's check) and rationale in the SUMMARY, and re-confirm the required-reason status of the file-timestamp API in the NSPrivacyAccessedAPICategoryFileTimestamp documentation (AGENTS.md: record official source for every Apple API).

Implementation in `drinkpulse/Features/Settings/AppVersionInfo.swift`:
1. Add stored `buildDate: Date?` and `isDebug: Bool`; change the initializer to `init(infoDictionary:buildDate:isDebug:)` with defaults `buildDate: Date? = nil` and `isDebug: Bool = false` so the Task 1 call sites and preview keep compiling unchanged.
2. `displayText`: version line exactly as in Task 1; when `isDebug`, append " · " plus the localized Debug marker (key `settings.version.debug` = "Debug"); when `isDebug` AND `buildDate` is non-nil, add a second line (separated by a newline character) formatted from key `settings.version.built` = "Built %@" with `Self.formatBuildDate(buildDate)`. When `isDebug` is false the date is ignored entirely (policy lives in this pure type so it is unit-tested).
3. `static func formatBuildDate(_ date: Date, timeZone: TimeZone = .current) -> String`: a DateFormatter with `locale = Locale(identifier: "en_US_POSIX")`, `calendar = Calendar(identifier: .gregorian)`, the injected `timeZone`, `dateFormat = "yyyy-MM-dd HH:mm"`. Deterministic and sortable, which suits distinguishing Debug installs; not localized on purpose (developer-facing build stamp).
4. `static let current` becomes `AppVersionInfo(infoDictionary: Bundle.main.infoDictionary, buildDate: Self.readExecutableDate(), isDebug: Self.isDebugBuild)`. `isDebugBuild` is a private static computed property returning true under `#if DEBUG` and false otherwise.
5. `private static func readExecutableDate() -> Date?` — the ONLY place a file timestamp is read. Structure it as a single `#if DEBUG` block containing the whole read (Bundle.main.executableURL, then FileManager.default.attributesOfItem(atPath:), then the file-modification-date attribute as Date) followed by `#else` with `return nil`. Inside the DEBUG block use `try?` with a short comment saying why it is ignorable (a missing build time only drops the second line; no user data involved) and a comment saying the read is Debug-only because the file-timestamp API is a required-reason API (privacy manifest) and the executable's timestamp is not guaranteed to be the build date on App Store installs. Do not log the path or the date. IMPORTANT for the verify gate: the file-timestamp API names (the attribute lookup, the attributes call) and any comment naming them must appear only between `#if DEBUG` and `#else`/`#endif`; outside that region describe the idea in words ("file timestamp") instead.

Localization: add `settings.version.built` = "Built %@" and `settings.version.debug` = "Debug" to `drinkpulse/Localizable.xcstrings` in alphabetical position (after `settings.version.full`, before `settings.version.only`; `settings.version.debug` sorts before `.full`, `.built` before `.debug`), same manual-extraction JSON shape; keep valid JSON.

Footer previews in `drinkpulse/Features/Settings/Components/AppVersionFooter.swift`: add a Debug-like preview (`isDebug: true`, a fixed `buildDate`) and one at `.dynamicTypeSize(.accessibility5)` to eyeball wrapping. Keep previews short (file stays well under 300 lines).

Tests in `drinkpulseTests/Features/Settings/AppVersionInfoTests.swift` (mirrors drinkpulse/Features/Settings/AppVersionInfo.swift per AGENTS.md test organization): Swift Testing, `@MainActor struct AppVersionInfoTests`, `import Testing`, `import Foundation`, `@testable import drinkpulse`, behaviour-style names like `displayText_returnsVersionAndBuild_whenReleaseBuild`. Build fixed dates with a Gregorian Calendar pinned to UTC (no reliance on the host time zone or locale). Use `#expect` assertions; expected strings are literal for the Release and formatBuildDate cases.
  </action>
  <verify>
    <automated>xcodebuild test -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Debug -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" -only-testing:drinkpulseTests/AppVersionInfoTests > build/appversion-unit.log 2>&1 && grep -q 'AppVersionInfoTests' build/appversion-unit.log && grep -q 'attributesOfItem' drinkpulse/Features/Settings/AppVersionInfo.swift && ! awk '/#if DEBUG/{s=1;next} /#else|#endif/{s=0;next} !s' drinkpulse/Features/Settings/AppVersionInfo.swift | grep -Eq 'attributesOfItem|modificationDate|creationDate' && python3 -c "import json; json.load(open('drinkpulse/Localizable.xcstrings'))"</automated>
  </verify>
  <done>AppVersionInfoTests ran (suite name in the log) and pass; the Debug build shows "Version 1.0 (1) · Debug" plus a "Built yyyy-MM-dd HH:mm" line; the file-timestamp API appears only inside the DEBUG region (the grep for it exists, the region-stripped scan finds none); catalog valid JSON; Task 1's UI test regex still matches the two-line Debug text.</done>
</task>

<task type="auto">
  <name>Task 3: Living docs, final gates, commit hygiene</name>
  <files>README.md, docs/DEVLOG.md, .claude/context/open-questions.md, .claude/context/current-focus.md</files>
  <action>
Docs are part of the change (AGENTS.md "Living docs are part of the change"); everything in English.

1. `README.md`, "### Settings" feature list: add one bullet after the Data bullet, e.g. "App version: version and build number at the bottom of Settings (Debug builds also show a Debug marker and the build time)". Do not touch other sections. Audit `.planning/PROJECT.md` and `docs/architecture.md` for contradictions; none expected (Settings is described generically, no scope change) — if one is found, fix it in this task.
2. `docs/DEVLOG.md`: APPEND (never edit existing entries) one entry, mirroring the heading format of the latest entry: date 2026-11-12 plus time, what changed (AppVersionInfo, AppVersionFooter, 5 localization keys, unit and UI tests) and why. Key decisions and REJECTED alternatives: (a) Run Script phase writing git tag/commit/date into Info.plist — rejected, needs a pbxproj edit and a build phase, beside an unrelated uncommitted pbxproj hunk; (b) Info.plist preprocessing with a compile-time date — rejected, same pbxproj reason; (c) showing the executable timestamp to production users — rejected, the file-timestamp API is a required-reason API needing a PrivacyInfo.xcprivacy declaration (DDA9.1) and Apple does not document the executable timestamp as the build date for App Store/TestFlight installs, so it could show a wrong date; the read is compiled out of Release. Record the Apple sources consulted via Xcode MCP (from Tasks 1-2) and open questions.
3. `.claude/context/open-questions.md`: add one entry (same `## Title` / **Question** / **Current state** / **To resolve** layout as existing entries): "Production build date and privacy manifest". Current state: Release shows only Version X (Y); the repo has no PrivacyInfo.xcprivacy (re-run `find . -name PrivacyInfo.xcprivacy -not -path './build/*'` first to confirm) although the app uses UserDefaults/@AppStorage, which Apple also classes as a required-reason API (check the exact category and reason code via Xcode MCP DocumentationSearch before stating it) — relevant to Phase 11 release verification. To resolve: decide whether production users should see a build date; if yes, add a build-time source (script phase or Info.plist preprocessing, which edits project.pbxproj) and a privacy manifest; independently audit required-reason API declarations before App Store submission.
4. `.claude/context/current-focus.md`: add one sentence under the current status noting the quick task 261112-kvl (Settings version footer) is done and does not change the Phase 11 focus. Do not rewrite the rest of the file.

Final gates (run and report in the SUMMARY): (i) file-size check from AGENTS.md; (ii) Release-configuration build compiles the non-DEBUG branch with zero warnings in the new files — if the Release configuration cannot build for the simulator for reasons unrelated to this change, use `-destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO` and say so; (iii) pbxproj guard; (iv) scoped test run is sufficient (2 test classes, no Domain/shared code touched, so no full-suite escalation per AGENTS.md "Quality gates").

Commit hygiene: STATE.md and quick-task bookkeeping belong to the quick workflow orchestrator, not this plan. When staging, add the files listed in this plan's frontmatter by explicit path ONLY; never use `git add -A`, `git add .` or `git commit -a`; `drinkpulse.xcodeproj/project.pbxproj` must not be staged (it carries an unrelated uncommitted hunk). No push (AGENTS.md).
  </action>
  <verify>
    <automated>test -n "$LOCAL_IOS_27_UDID" && xcodebuild build -project drinkpulse.xcodeproj -scheme drinkpulse -configuration Release -destination "platform=iOS Simulator,id=$LOCAL_IOS_27_UDID" > build/appversion-release.log 2>&1 && ! grep -E 'AppVersion(Info|Footer)\.swift.*warning:' build/appversion-release.log && test -z "$(find drinkpulse -name '*.swift' -not -path '*/Preview Content/*' | xargs wc -l | awk '$2 != "total" && $1 > 300')" && git diff --numstat -- drinkpulse.xcodeproj/project.pbxproj > build/pbx.numstat && test "$(cut -f1,2 build/pbx.numstat | tr '\t' '/')" = "2/0" && grep -q 'App version' README.md && grep -q 'Production build date and privacy manifest' .claude/context/open-questions.md && grep -q 'AppVersionFooter' docs/DEVLOG.md</automated>
  </verify>
  <done>Release build compiles without warnings in the new files; no Swift file exceeds 300 lines; project.pbxproj diff is still exactly the pre-existing +2/-0 (this task and the plan never touched it, and it is not staged); README, DEVLOG, open-questions and current-focus reflect the change; the SUMMARY lists the Apple sources consulted via Xcode MCP.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| app bundle -> UI | Version/build strings come from the app's own signed Info.plist; no user or network input crosses here |
| app -> file system (DEBUG only) | A single read of the app's own executable metadata, compiled out of Release |
| repo -> App Store submission | Required-reason API usage must match the declared privacy manifest |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-kvl-01 | Information Disclosure | Version/build text made selectable and copyable | low | accept | Version and build number are public app metadata, not health or personal data; no logging, no telemetry, nothing leaves the device (AGENTS.md privacy rules). |
| T-kvl-02 | Information Disclosure | Build timestamp from the executable's file metadata | low | mitigate | Read compiled out of Release via `#if DEBUG`; value is never logged and never written anywhere; shown only on the developer's own Debug build. |
| T-kvl-03 | Repudiation / compliance | Required-reason file-timestamp API without a privacy manifest entry | medium | mitigate | No file-timestamp API call in the Release binary (region-scoped awk gate in Task 2 and Release build in Task 3); a Release date is deferred behind an open question that requires a manifest first. |
| T-kvl-04 | Tampering | Accidental commit of the unrelated project.pbxproj hunk | low | mitigate | Plan never edits pbxproj; Task 3 guard asserts the diff is still +2/-0 and instructs explicit-path staging only. |
| T-kvl-SC | Tampering | npm/pip/cargo installs | high | accept | No package-manager installs and no third-party dependencies in this plan; nothing to audit. |
</threat_model>

<verification>
Run, from the repo root, with `LOCAL_IOS_27_UDID` exported:
1. Task 1 command: UI test `AppVersionUITests` passes and its test name is in the log.
2. Task 2 command: `AppVersionInfoTests` passes; the region-scoped scan shows no file-timestamp API outside `#if DEBUG`.
3. Task 3 command: Release build clean for the new files; no file over 300 lines; pbxproj diff unchanged at +2/-0; docs updated.
4. Manual (optional, 30 s): run the Debug build, open Settings, scroll to the bottom, long-press the text and confirm Copy appears; at Accessibility XL (AX5) confirm the text wraps instead of truncating.
</verification>

<success_criteria>
- Settings bottom shows "Version X (Y)" for production and "Version X (Y) · Debug" plus "Built yyyy-MM-dd HH:mm" for Debug builds.
- Pure formatter fully unit-tested; UI test pins presence, position and format; both ran.
- Release binary contains no file-timestamp read; no privacy-manifest change required by this work.
- Zero new warnings, no file over 300 lines, localization via String Catalog (5 keys), accessibility (identifier, Dynamic Type wrap, selectable text) satisfied.
- project.pbxproj untouched by this task; the unrelated hunk remains uncommitted and unstaged.
</success_criteria>

<output>
Create `.planning/quick/261112-kvl-dodaj-do-aplikacji-gdzie-na-dole-w-ustaw/261112-kvl-SUMMARY.md` when done (include the Apple documentation sources consulted via Xcode MCP, the test results, and the pbxproj guard result).
</output>
