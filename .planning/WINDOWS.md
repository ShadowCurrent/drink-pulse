---
schema_version: 1
open_count: 6
waived_count: 0
fixed_count: 0
total_count: 6
last_updated: 2026-08-03T22:47:37.358Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 02 | unmet-truth | drinkpulse/Domain/DrinkTemplate.swift |  | Pre-existing coverage gap predating Phase 2: several Domain/Persistence/Schemas and Domain/DataTransfer files (DrinkTemplate.swift 46%, TemplateRecord.swift 64%, SchemaV1/V2/V3.swift 68-77%, BackupExport/BackupDocument.swift 66-69%, ConsumptionEvent.swift 83%) sit below CLAUDE.md's literal Domain-100% target, though all pure calculation logic (AlcoholUnit, GuidelineChoice+Limits, UnitSystem+Volume, RiskLevel, WeeklySummaryCalculator, etc.) is 100%. Overall app coverage is 93.14% (>=90% met). Not caused by the Swift 6 migration (these files were not touched by 02-01 or 02-02); out of this closure plan's scope to fix. | open |  | 2026-07-27T08:10:20.461Z |  |
| 2 | 06 | deviation | drinkpulseUITests/Features/History/HistoryInteractionUITests.swift |  | File already exceeded the 300-line ceiling before this plan (319 lines); the mandatory additive dataset: parameter on launchApp pushed it to 324. Plan explicitly chose a new file for new tests to avoid growing it further; splitting the pre-existing content is out of this plan's scope. | open |  | 2026-07-31T12:34:41.745Z |  |
| 3 | 07 | unrun-verify | drinkpulse/Features/History/Components/EventContextMenu.swift |  | C14-2 VoiceOver rotor check unrun: confirm Duplicate/Delete appear as VoiceOver Actions on a History row and that Delete presents the confirmation (settles 07-RESEARCH assumption A1) | open |  | 2026-08-03T22:24:25.348Z |  |
| 4 | 07 | unrun-verify | drinkpulse/Features/History/Components/EventRow.swift |  | C14-7 contrast audit unrun: run Accessibility Inspector contrast audit over the History list in light, dark and Increase Contrast; .secondary on .caption/.caption2 over translucent glass is unmeasured, not a confirmed violation | open |  | 2026-08-03T22:24:29.184Z |  |
| 5 | 07 | deviation | drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift | 109 | PRE-EXISTING failure (not caused by 07-03, proven by A/B against 67725ae): test_healthEnabled_deleteDrink_stillRemovesEvent taps the context menu Delete and expects immediate removal, but 07-01 gated that behind a confirmation dialog. Needs the same update 07-01 applied to HistoryInteractionUITests. | open |  | 2026-08-03T22:47:37.358Z |  |
| 6 | 07 | unrun-verify | drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift |  | B9-3 human-check: glass card appearance in light/dark and at AX5 not visually verified by executor | open |  | 2026-08-03T22:04:06.361Z |  |

````json
[
  {
    "id": 1,
    "kind": "unmet-truth",
    "phase": "02",
    "file": "drinkpulse/Domain/DrinkTemplate.swift",
    "line": null,
    "description": "Pre-existing coverage gap predating Phase 2: several Domain/Persistence/Schemas and Domain/DataTransfer files (DrinkTemplate.swift 46%, TemplateRecord.swift 64%, SchemaV1/V2/V3.swift 68-77%, BackupExport/BackupDocument.swift 66-69%, ConsumptionEvent.swift 83%) sit below CLAUDE.md's literal Domain-100% target, though all pure calculation logic (AlcoholUnit, GuidelineChoice+Limits, UnitSystem+Volume, RiskLevel, WeeklySummaryCalculator, etc.) is 100%. Overall app coverage is 93.14% (>=90% met). Not caused by the Swift 6 migration (these files were not touched by 02-01 or 02-02); out of this closure plan's scope to fix.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-27T08:10:20.461Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "06",
    "file": "drinkpulseUITests/Features/History/HistoryInteractionUITests.swift",
    "line": null,
    "description": "File already exceeded the 300-line ceiling before this plan (319 lines); the mandatory additive dataset: parameter on launchApp pushed it to 324. Plan explicitly chose a new file for new tests to avoid growing it further; splitting the pre-existing content is out of this plan's scope.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-31T12:34:41.745Z",
    "resolved_at": null
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "07",
    "file": "drinkpulse/Features/History/Components/EventContextMenu.swift",
    "line": null,
    "description": "C14-2 VoiceOver rotor check unrun: confirm Duplicate/Delete appear as VoiceOver Actions on a History row and that Delete presents the confirmation (settles 07-RESEARCH assumption A1)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T22:24:25.348Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "unrun-verify",
    "phase": "07",
    "file": "drinkpulse/Features/History/Components/EventRow.swift",
    "line": null,
    "description": "C14-7 contrast audit unrun: run Accessibility Inspector contrast audit over the History list in light, dark and Increase Contrast; .secondary on .caption/.caption2 over translucent glass is unmeasured, not a confirmed violation",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T22:24:29.184Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "07",
    "file": "drinkpulseUITests/Features/AddDrink/HealthWriteHooksUITests.swift",
    "line": 109,
    "description": "PRE-EXISTING failure (not caused by 07-03, proven by A/B against 67725ae): test_healthEnabled_deleteDrink_stillRemovesEvent taps the context menu Delete and expects immediate removal, but 07-01 gated that behind a confirmation dialog. Needs the same update 07-01 applied to HistoryInteractionUITests.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T22:47:37.358Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "unrun-verify",
    "phase": "07",
    "file": "drinkpulse/Features/Settings/Components/GuidelinePickerSheet.swift",
    "line": null,
    "description": "B9-3 human-check: glass card appearance in light/dark and at AX5 not visually verified by executor",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-08-03T22:04:06.361Z",
    "resolved_at": null
  }
]
````
