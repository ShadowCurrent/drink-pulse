# Requirements (from PRDs)

Source PRD: docs/product.md (single PRD in this ingest — no competing PRD found for
any of the requirements below, so no competing-variants entries were generated from
requirement overlap). Acceptance criteria are marked absent where product.md states
only a user story / feature line without a separate itemized acceptance section.

## REQ-quick-log-drink
- source: docs/product.md
- description: As a user I can quickly log a drink by choosing its type, volume, and strength.
- acceptance: (absent — no itemized acceptance criteria stated beyond the user story)
- scope: Logging

## REQ-log-multiple-servings
- source: docs/product.md
- description: As a user I can log multiple servings at once (count multiplier).
- acceptance: (absent)
- scope: Logging

## REQ-backdate-entry
- source: docs/product.md
- description: As a user I can back-date an entry to yesterday or earlier.
- acceptance: (absent)
- scope: Logging

## REQ-optional-price
- source: docs/product.md
- description: As a user I can add an optional price to track spending.
- acceptance: (absent)
- scope: Logging

## REQ-today-vs-guideline
- source: docs/product.md
- description: As a user I can see today's total alcohol intake vs my weekly guideline.
- acceptance: (absent)
- scope: Insight

## REQ-history-by-day
- source: docs/product.md
- description: As a user I can browse my history grouped by day.
- acceptance: (absent)
- scope: Insight

## REQ-units-and-grams-per-entry
- source: docs/product.md
- description: As a user I can see my alcohol units and pure-alcohol grams per entry.
- acceptance: (absent)
- scope: Insight

## REQ-sex-and-age-setting
- source: docs/product.md
- description: As a user I can set my biological sex and age.
- acceptance: (absent)
- scope: Settings

## REQ-guideline-choice-setting
- source: docs/product.md
- description: As a user I can choose a health guideline (WHO / DE / UK / US / custom).
- acceptance: (absent)
- scope: Settings

## REQ-volume-unit-preference
- source: docs/product.md
- description: As a user I can set my preferred volume unit (ml / US fl oz / Imperial fl oz).
- acceptance: (absent)
- scope: Settings

## REQ-alcohol-display-unit-preference
- source: docs/product.md
- description: As a user I can set my preferred alcohol display unit (grams / standard drinks; the UK reads "units").
- acceptance: (absent)
- scope: Settings
- note: product.md's phrasing ("grams / standard drinks; UK reads 'units'") matches ADR-0006's two-case model, which is the sole locked/authoritative density rule as of this ingest (ADR-0005's three-case model is now formally Superseded by ADR-0006). No open conflict — see INGEST-CONFLICTS.md INFO (auto-resolved).

## REQ-abv-precision-setting
- source: docs/product.md
- description: As a user I can configure ABV picker precision (0.1% or 0.5%).
- acceptance: (absent)
- scope: Settings

## REQ-currency-preference-and-override
- source: docs/product.md
- description: As a user I can set my preferred currency, and override the currency per drink when logging a price (the currency is saved with the price). (plan-0034)
- acceptance: (absent)
- scope: Settings

## REQ-first-launch-onboarding
- source: docs/product.md
- description: First-launch onboarding — 4 steps (welcome / optional profile / guideline / optional Apple Health opt-in); each step skippable, persisted via @AppStorage. (plan-0009; Health step plan-0036)
- acceptance: (absent)
- scope: Planned (Claude Design handoff, 2026-05-19)
- note: listed under product.md's "Planned" section; docs/roadmap.md marks the equivalent items (plan-0009, plan-0036) as done — see INGEST-CONFLICTS.md WARNING on stale "Planned" section.

## REQ-apple-health-writeback
- source: docs/product.md
- description: Apple Health write-back — opt-in, off by default. Mirrors logged drinks to Apple Health as Alcohol Consumption (a drinks count); edits/deletes reflected, deduplicated so reinstall/sync never duplicates. On-device only, read access used solely to avoid duplicate writes. (plan-0036)
- acceptance: (absent — see ADR-0011 in decisions.md for the implemented technical decision)
- scope: Planned (Claude Design handoff, 2026-05-19)
- note: see INGEST-CONFLICTS.md WARNING — roadmap.md / plans/INDEX.md mark plan-0036 and ADR-0011 as done, contradicting the "Planned" placement here.

## REQ-insights-screen
- source: docs/product.md
- description: Insights screen — area chart, weekday patterns, health metrics, multi-guideline comparison; scope selector with Week / Month / Year / All Time. (plan-0012)
- acceptance: (absent)
- scope: Planned (Claude Design handoff, 2026-05-19)
- note: see INGEST-CONFLICTS.md WARNING — roadmap.md marks plan-0012 as done.

## REQ-history-calendar-view
- source: docs/product.md
- description: History calendar view — clickable days with inline detail panel, month navigation, daily-limit colour coding. (plan-0013)
- acceptance: (absent)
- scope: Planned (Claude Design handoff, 2026-05-19)
- note: see INGEST-CONFLICTS.md WARNING — roadmap.md marks plan-0013 as done.

## REQ-edit-entry-name-notes-category
- source: docs/product.md
- description: Edit entry — override drink name (e.g. "Some Super IPA"), add free-form notes, change category in place. (plan-0014)
- acceptance: (absent)
- scope: Planned (Claude Design handoff, 2026-05-19)
- note: see INGEST-CONFLICTS.md WARNING — roadmap.md marks plan-0014 as done.

## REQ-log-reminders
- source: docs/product.md
- description: Log reminders — opt-in daily nudge to log. (plan-0016). Product.md also notes: single fixed Ember accent (multi-theme palettes from plan-0008 removed in plan-0033); Light/Dark/System mode retained.
- acceptance: (absent)
- scope: Planned (Claude Design handoff, 2026-05-19)
- note: see INGEST-CONFLICTS.md WARNING — roadmap.md marks plan-0016 and plan-0033 as done.

## REQ-risk-language-rename
- source: docs/product.md
- description: Risk language — "Low Risk / Moderate Risk / High Risk" replaces "Safe / Caution / Exceeded" everywhere. (plan-0015)
- acceptance: (absent)
- scope: Planned (Claude Design handoff, 2026-05-19)
- note: see INGEST-CONFLICTS.md WARNING — roadmap.md marks plan-0015 as done.

## REQ-future-bac-estimate
- source: docs/product.md
- description: BAC estimate (Widmark, labeled as estimate / not medical advice). Requires body weight input in Settings.
- acceptance: (absent)
- scope: Future

## REQ-future-currency-spending-tracker
- source: docs/product.md
- description: Currency preference and spending tracker (dedicated screen — spend already shown inside the Insights card per design).
- acceptance: (absent)
- scope: Future

## REQ-future-custom-drink-templates
- source: docs/product.md
- description: Custom drink templates.
- acceptance: (absent)
- scope: Future

## REQ-future-monthly-trend-charts
- source: docs/product.md
- description: Monthly trend charts beyond what Insights provides.
- acceptance: (absent)
- scope: Future

## REQ-future-widget
- source: docs/product.md
- description: Widget / Live Activity showing today's units.
- acceptance: (absent)
- scope: Future

## REQ-future-apple-watch-glance
- source: docs/product.md
- description: Apple Watch quick-log glance (today summary + log drink, iOS app extension — not standalone watchOS).
- acceptance: (absent)
- scope: Future

## REQ-future-weekly-summary-notification
- source: docs/product.md
- description: Notifications for weekly summary.
- acceptance: (absent)
- scope: Future

## REQ-future-ai-nl-drink-entry
- source: docs/product.md
- description: AI natural-language drink entry — type "had a Tyskie at 9pm" and have the app parse it. On-device model preferred to preserve privacy.
- acceptance: (absent)
- scope: Future

## REQ-future-pdf-export-insights
- source: docs/product.md
- description: PDF export of Insights — formatted monthly summary for personal archive or sharing with a clinician.
- acceptance: (absent)
- scope: Future
