---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 0
total_count: 2
last_updated: 2026-07-31T12:34:41.745Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 02 | unmet-truth | drinkpulse/Domain/DrinkTemplate.swift |  | Pre-existing coverage gap predating Phase 2: several Domain/Persistence/Schemas and Domain/DataTransfer files (DrinkTemplate.swift 46%, TemplateRecord.swift 64%, SchemaV1/V2/V3.swift 68-77%, BackupExport/BackupDocument.swift 66-69%, ConsumptionEvent.swift 83%) sit below CLAUDE.md's literal Domain-100% target, though all pure calculation logic (AlcoholUnit, GuidelineChoice+Limits, UnitSystem+Volume, RiskLevel, WeeklySummaryCalculator, etc.) is 100%. Overall app coverage is 93.14% (>=90% met). Not caused by the Swift 6 migration (these files were not touched by 02-01 or 02-02); out of this closure plan's scope to fix. | open |  | 2026-07-27T08:10:20.461Z |  |
| 2 | 06 | deviation | drinkpulseUITests/Features/History/HistoryInteractionUITests.swift |  | File already exceeded the 300-line ceiling before this plan (319 lines); the mandatory additive dataset: parameter on launchApp pushed it to 324. Plan explicitly chose a new file for new tests to avoid growing it further; splitting the pre-existing content is out of this plan's scope. | open |  | 2026-07-31T12:34:41.745Z |  |

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
  }
]
````
