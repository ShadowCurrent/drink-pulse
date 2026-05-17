# DrinkPulse — Development Log

Append a new entry after every non-trivial session. Never edit or delete old entries.
Format: `## YYYY-MM-DD HH:MM — Title`

---

## 2026-05-17 — Project cleanup

### What changed

- **Removed `GuidelineProfile` SwiftData model** — the type was in the schema and referenced in every preview `ModelContainer`, but never queried or inserted anywhere in the app. All limit logic lives in `GuidelineLimits.swift` / `GuidelineChoice.limits(for:)`. Removed from schema, deleted `Domain/GuidelineProfile.swift`, and stripped `GuidelineProfile.self` from all 8 `#Preview` blocks.
- **Removed unused localization keys** — `dashboard.placeholder` (dashboard now shows rings, never the placeholder) and `history.units` (superseded by `unit.units` / `AlcoholUnit.unitLabel`).
- **Updated CLAUDE.md build destination** — `iPhone 16 Pro` → `iPhone 17 Pro` (16 Pro no longer in available simulators).

---

## 2026-05-17 — Edit ConsumptionEvent screen

### What changed

New `EditEventView` sheet opened by tapping any row in the history list. The form mirrors Add Drink (drum-roll pickers for volume / ABV / count, category picker, name field, date+time picker, price field, live alcohol readout). State is held in `@State` copies of the event's fields — changes are written to the `@Model` only on Save, Cancel is a no-op.

`DrinkTypePreset.preset(for:)` helper added so both `EditEventView` and future code can resolve a preset from a `DrinkCategory` without duplicating the lookup.

### Key decisions

- **Volume/count recovery**: the stored `volumeMl` is the product of serving size × count. On opening, a brute-force search over all (count 1–10) × (preset volumes) finds the pair that minimises the absolute difference. Recovers e.g. 1000 ml → 2 × 500 ml correctly.
- **ABV init without `@Query`**: ABV index is initialised with the default 0.5 % step size in `init` (where profile isn't accessible). `safeAbvIndex` clamps at runtime if the user's precision setting differs — same pattern as `DrinkDetailInputView`.
- **No auto-save**: `@Bindable` direct binding was rejected in favour of local `@State` to avoid partial edits leaking into the history list while the sheet is still open.
- **Date + time in edit**: Add Drink shows `.date` only; Edit shows `.date` and `.hourAndMinute` since correcting a log time is a common edit scenario.

---

## 2026-05-17 — Sex-aware guideline limits + alcohol density correction

### What changed

**Alcohol density constant**: changed from 0.789 g/ml (scientific ethanol density) to 0.8 g/ml (BZgA/European health authority convention). Gives exactly 20 g for 500 ml × 5% beer, consistent with German and other European health materials. Updated in `ConsumptionEvent.pureAlcoholGrams`, `DrinkDetailInputView`, and CLAUDE.md. UK units threshold updated accordingly: 10 ml × 0.8 = 8.0 g/unit (was 7.89 g).

**Sex-aware guideline limits**: added `GuidelineLimits` struct and `GuidelineChoice.limits(for: BiologicalSex)` in a new `Domain/GuidelineLimits.swift`. Dashboard rings and guideline picker sheet now use the user's biological sex to determine thresholds.

| Guideline | Men | Women |
|-----------|-----|-------|
| WHO | 20 g/day · 100 g/week | 10 g/day · 70 g/week |
| DE (DHS) | 24 g/day · 168 g/week | 12 g/day · 84 g/week |
| UK (NHS) | 112 g/week (no daily limit) | same |
| US (NIAAA) | 28 g/day · 196 g/week | 14 g/day · 98 g/week |

### Key decisions

- Density 0.8 vs 0.789: chose 0.8 because users will cross-reference results against health authority materials that use this convention. Scientific precision is secondary to consistency with the guidelines the app is built around.
- `thresholdSummary` in `GuidelinePickerSheet` is now derived from `GuidelineLimits` rather than hardcoded strings, so it stays in sync with the domain logic automatically.

---

## 2026-05-17 — Settings UI redesign

### What changed

Replaced the inline guideline Picker with a half-sheet (`GuidelinePickerSheet`) that displays each option with its name and threshold summary (e.g. "20 g/day · 100 g/week"). Presentation uses `.presentationDetents([.medium])` and `.presentationDragIndicator(.visible)`.

Changed age input from a `Stepper` to an integer `TextField` with `.keyboardType(.numberPad)`, clamped via `.onChange` to 13–120.

ABV precision now uses a standard inline Picker (no custom style), consistent with other preference rows.

### Key decision — guideline row tint

Using `Button` inside a `Form` automatically tints all label content with the accent color (blue), which was inconsistent with other rows like the sex Picker. Replaced with `HStack` + `.contentShape(Rectangle())` + `.onTapGesture` to preserve native row appearance without blue tint.

---

## 2026-05-16 10:00 — Bootstrap domain models and project structure

### What was built

**Domain models** (`Domain/`):
- `DrinkTemplate` — reusable drink preset (name, category, default volume, ABV as fraction 0.0–1.0, icon, colorHex, isFavorite, isArchived). Relationship to ConsumptionEvent with `.nullify` delete rule so deleting a template never cascades to history.
- `ConsumptionEvent` — single logged drink. Snapshots template fields (name/category/icon) at insert time so editing a template never alters history. Computed `pureAlcoholGrams = volumeMl * abv * 0.789`.
- `UserProfile` — SwiftData singleton enforced via `@Attribute(.unique) id = "singleton"`. Fields: bodyWeightKg, biologicalSex, ageYears, guidelineChoice, weeklyGoalGrams, unitSystem.
- `GuidelineProfile` — threshold model for WHO / DE / UK / US / custom. Static factory methods create insertable instances; seeding is the repository's responsibility.

**Key decision — ABV storage**: plain fraction (0.05 = 5%), NOT percentage. Formula: `volumeMl * abv * 0.789`. CLAUDE.md updated accordingly.

**Project structure**:
- `Features/Dashboard/DashboardView.swift` — root Home tab (stub + add button)
- `Features/History/HistoryView.swift` — stub
- `Features/Settings/SettingsView.swift` — stub
- `Features/AddDrink/AddDrinkView.swift` — v1 form sheet (replaced in next session)
- `ContentView.swift` — root TabView (Home / History / Settings)
- `drinkpulseApp.swift` — ModelContainer with all four models

**Removed**: `Item.swift` (Xcode default template model)

### Rejected approaches
- `navigationTransitionSource/Destination` (iOS 26 zoom sheet transition) — API does not exist in the current SDK despite being listed in the swiftui-expert-skill reference. Fell back to standard `.sheet(isPresented:)`.

---

## 2026-05-16 13:30 — Add Drink v1: basic form sheet

### What was built
- `AddDrinkView` as a plain Form sheet with: name field, category Picker, volume TextField (ml), ABV TextField (%), optional notes.
- On Save: converts ABV% → fraction (`/ 100`), inserts `ConsumptionEvent` into modelContext.
- `DashboardView` toolbar trailing `+` button presents the sheet.

---

## 2026-05-16 14:00 — Add Drink v2: two-step flow with drum-roll pickers

### What was built

**Flow redesign**: replaced the plain form with a two-step modal:
1. **DrinkTypeGridView** — `LazyVGrid` of category tiles (icon + name). Cancel dismisses the sheet.
2. **DrinkDetailInputView** — three side-by-side `.wheel` pickers (volume | ABV% | count 1–10×), date picker (date only, default today), optional price field, live alcohol-units readout. Save dismisses the sheet.

**New files**:
- `Features/AddDrink/DrinkTypePreset.swift` — static drink type data (volumes, ABV range per category). Not stored in SwiftData — these are app-level defaults, not user data.
- `Features/AddDrink/DrinkTypeGridView.swift` — step 1 grid + `DrinkTypeTile` subview.
- `Features/AddDrink/DrinkDetailInputView.swift` — step 2 configuration screen.
- `AddDrinkView.swift` updated to be a `NavigationStack` wrapper; injects `dismissSheet` environment value so the pushed detail view can dismiss the whole sheet on save.

**Domain model additions** (all backward-compatible / migration-safe):
- `DrinkCategory`: added `.champagne`, `.cider` cases (String-backed Codable enum — existing records decode fine).
- `ConsumptionEvent`: added `price: Double?` (optional, default nil).
- `UserProfile`: added `currency: String` (default `"USD"`).

**Alcohol units formula** (flagged for hand-verification):
`units = volumeMl × count × abv / 10`
Equivalent to the standard `ml × abv% / 1000`. Example: 568 ml × 0.05 / 10 = 2.84 units (pint of 5% beer).

### Key decisions
- Predefined drink types are **static Swift data**, not SwiftData rows. `DrinkTemplate` in SwiftData is reserved for user-created custom templates (future feature).
- The `DrinkCategory` enum IS stored on `ConsumptionEvent`, so old entries can always be recognized and edited by their category.
- `dismissSheet` custom `@Entry` environment value propagates the sheet-level `dismiss` action into pushed NavigationStack destinations without prop drilling.
- Save/Cancel buttons: **top toolbar** (Cancel leading, Save trailing) — iOS HIG standard for modal forms.
- Currency field added to `UserProfile` for future Settings integration; hardcoded to `"USD"` for now in the price row UI.

### Open / next steps
- Settings screen: ABV picker precision (0.1% or 0.5%), currency selection, guideline profile.
- History screen: list of ConsumptionEvents grouped by day.
- Dashboard: weekly progress bar vs guideline.
- Localization string catalog (en + pl).
- Edit existing ConsumptionEvent flow.

---

## 2026-05-16 16:10 — History screen

### What was built

`Features/History/HistoryView.swift` — replaces the placeholder with a fully functional history list.

- `@Query(sort: \ConsumptionEvent.timestamp, order: .reverse)` fetches all events, most recent first.
- Events are grouped by calendar day into `[(day: Date, events: [ConsumptionEvent])]` via `Dictionary(grouping:)`.
- Day section headers: "Today" / "Yesterday" / abbreviated date (e.g. "Fri, 16 May 2026").
- `EventRow` shows: SF Symbol icon (tinted), drink name, subtitle (`568 ml · 5.0% · 14:32`), alcohol units right-aligned.
- Swipe-to-delete per section via `.onDelete`.
- `ContentUnavailableView` empty state when no events exist.
- Full `accessibilityLabel` on each row combining name, volume, ABV%, units, and time.
- Two previews: "With data" (three pre-inserted mock events) and "Empty state".

### Key decisions

- Used `@Query` directly in the view — ADR 0003 explicitly allows this for simple read-only list views; no viewmodel or repository needed for a fetch-and-display pattern.
- `alcoholUnits` in `EventRow` uses the same `volumeMl * abv / 10` formula as `DrinkDetailInputView`. `volumeMl` on the stored event already includes the × count multiplier applied at save time.
- Empty state uses `ContentUnavailableView` (iOS 17+, fine for iOS 26 minimum target).

### Open / next steps

- Dashboard screen: weekly progress bar vs GuidelineProfile threshold, today's total units.
- Settings screen: unblocks ABV precision, currency, guideline choice, UserProfile seeding.
- Edit existing ConsumptionEvent flow.
- Localization string catalog (en + pl).

---

## 2026-05-16 17:30 — UI polish, i18n, and navigation title experiment

### What was built / changed

- **DrinkDetailInputView pickers**: Volume takes remaining width (`maxWidth: .infinity`); ABV fixed at 88pt, count at 60pt. All picker items use `.callout` font (16pt) for a tighter layout.
- **DrinkTypeTile**: Added `.multilineTextAlignment(.center)`, `.minimumScaleFactor(0.75)`, `.lineLimit(2)` to prevent truncation on longer category names (e.g. "Champagne").
- **Localizable.xcstrings**: Full i18n catalog with 20 dot-notation keys (en/de/pl). All Swift call sites updated. Duplicates (`"Add Drink"` / `"Add drink"`) merged into `addDrink.title`. Literal-style keys converted to `namespace.camelCase`.
- **Navigation title experiment**: Tried `.navigationBarTitleDisplayMode(.inline)` with a leading `ToolbarItem` for a left-aligned title. iOS treats all toolbar items as interactive and the area clips — left `.inline` per user preference on Dashboard and History.

### Key decisions

- Fixed widths for ABV and count pickers rather than proportional layout — simpler, no `GeometryReader` needed, values are stable across device sizes.
- `.minimumScaleFactor` + `.lineLimit(2)` preferred over removing the tile's `aspectRatio` — keeps the grid visually uniform.
- Left-aligned inline nav title is not achievable cleanly in SwiftUI without UIKit; `.inline` kept but title stays centered as per iOS system behavior.
- i18n keys: literal strings with `+`, `()`, or spaces converted to dot-notation. `"Cancel"` / `"Save"` → `action.cancel` / `action.save` for consistency.

### Open / next steps

- Dashboard screen (recommended next).
- Settings screen (unblocks currency, ABV precision, UserProfile seeding).
- Add `Localizable.xcstrings` to Xcode project target (user must do this in Xcode — file exists on disk but is not yet in `.xcodeproj`).

---

## 2026-05-17 12:30 — Bugfixes: Settings loading, unit formulas, overflow rings

### What was fixed

**SwiftData migration crash (ProgressView loop in Settings)**
`abvPrecisionPermille` and `alcoholUnit` were declared without inline property defaults (`var x: T` instead of `var x: T = default`). SwiftData lightweight migration uses the inline default to populate new columns for existing rows — without it, the schema migration silently failed and `@Query<UserProfile>` returned empty. Fixed by adding `= 5` and `= AlcoholUnit.units` at the property declaration level. Note: SwiftData's `@Model` macro requires fully qualified names here (`AlcoholUnit.units`, not `.units`).

**Seeding race condition removed**
Moved `UserProfile` seeding from `ContentView.onAppear` into the `ModelContainer` stored property initializer in `drinkpulseApp`. The old approach had a timing window where `SettingsView` could appear before the seed ran. The new approach seeds synchronously before any view is created.

**`AlcoholUnit.units` formula now guideline-aware**
The `.units` case was hardcoded to the UK formula (`/ 7.89`) regardless of the selected guideline. Fixed to use the correct regional threshold: DE/WHO/custom → 10 g/unit, UK → 7.89 g/unit (10 ml ethanol), US → 14 g/unit. Display precision changed from `%.2f` to `%.1f`.

**Dashboard overflow rings (> 100%)**
Removed the `min(..., 1.0)` cap on `IntakeRing.progress`. Added a second arc (lineWidth 6, red 55% opacity) that draws the overflow portion as a second lap on top of the full primary arc. The center percentage text now shows the real value (150%, 200%, etc.).

**ContentView preview seeding**
The `#Preview` used `.modelContainer(for:inMemory:)` which creates an empty store — `SettingsView` showed `ProgressView` forever in Xcode Previews. Fixed by using an explicit `ModelContainer` with `UserProfile.preview` inserted before rendering.

### Key decisions

- Inline defaults on `@Model` stored properties are the correct pattern for SwiftData lightweight migration; `init` parameter defaults are insufficient.
- The `AlcoholUnit.standardDrinks` option remains useful for UK users who want the WHO 10 g threshold instead of the native UK 7.89 g unit.
- Overflow visual: a thinner concentric arc (rather than a color flash or badge) keeps the ring metaphor consistent and scales to arbitrary multiples.

---

## 2026-05-17 10:30 — Alcohol display unit setting

### What was built

New user preference: **Alcohol unit** — controls how consumed alcohol is displayed everywhere in the app.

**Three options** (Settings → Preferences → Alcohol unit):
| Option | Formula | Example |
|--------|---------|---------|
| Grams (g) | `pureAlcoholGrams` | 22.4 g |
| Units (UK) | `pureAlcoholGrams / 7.89` | 2.84 units |
| Standard drinks | `pureAlcoholGrams / 10` (or `/14` for US guideline) | 2.24 std |

**Formulas — pending hand-verification:**
- Units: derived from existing `volumeMl × abv / 10` formula via `pureAlcoholGrams = volumeMl × abv × 0.789`, giving `units = pureAlcoholGrams / 7.89`.
- Standard drinks: 14g per drink for US guideline (NIAAA), 10g for WHO / DE / UK. Standard drink threshold depends on `UserProfile.guidelineChoice`.

**Changed views:**
- `HistoryView` `EventRow` — right column shows value + unit label from `AlcoholUnit.formattedValue/unitLabel`
- `DashboardView` `IntakeRing` — secondary center text (below %) shows preferred unit; percentage calculation stays grams-vs-grams
- `DrinkDetailInputView` — alcohol readout row label and value both driven by `AlcoholUnit.displayName/formattedValue`

**Domain change** (`UserProfile`): `alcoholUnit: AlcoholUnit` added (default `.units`). SwiftData lightweight migration.

**i18n**: 7 new keys (`settings.alcoholUnit`, `settings.alcoholUnit.*`, `unit.g`, `unit.units`, `unit.standardDrinks`). Existing `history.units` key replaced by `unit.units` in the views.

### Key decisions

- `AlcoholUnit` extension with `formattedValue(_:guideline:)` lives on the enum in `UserProfile.swift` — tightly coupled to domain, not a `@Model` method.
- `IntakeRing` receives a pre-formatted `consumedLabel: String` string from the parent rather than owning the conversion logic — keeps the struct a pure display component.
- `DrinkDetailInputView` now uses `pureAlcoholGrams` directly (was computing `alcoholUnits` via `volumeMl × abv / 10`). Both yield the same displayed value when unit = `.units` since `pureAlcoholGrams / 7.89 ≡ volumeMl × abv / 10`.

### Open / next steps

- Hand-verify the unit conversion formulas.
- Volume unit display wiring (History, AddDrink picker labels).
- Edit existing ConsumptionEvent flow.

---

## 2026-05-17 09:00 — Settings screen

### What was built

**`Features/Settings/SettingsView.swift`** — replaces placeholder with a three-section `Form`:

1. **Profile** — Biological sex (`Picker`), Age (`Stepper` 13–120)
2. **Guideline** — inline `Picker` showing WHO / DE / UK / US with daily+weekly threshold subtitles; `custom` case filtered out (requires its own flow)
3. **Preferences** — Volume unit (`Picker`: ml / US fl oz / Imperial fl oz), ABV precision (segmented: 0.5 % or 0.1 % steps)

No separate ViewModel — `UserProfile` is `@Observable` via `@Model`, so `SettingsForm` takes `@Bindable var profile` and changes auto-persist via SwiftData.

**Domain changes** (`UserProfile.swift`):
- `UnitSystem` enum: added `.usCustomary` case (raw: "usCustomary"), kept `.metric` and `.imperial` raw values for backward compat.
- `abvPrecisionPermille: Int` — new field (default 5). SwiftData lightweight migration adds the column automatically.

**First-launch seeding** (`drinkpulseApp.swift`): `seedDefaultsIfNeeded(in:)` called in `WindowGroup.onAppear` inserts `UserProfile()` if the store is empty. Keeps bootstrap logic out of views.

**ABV precision wired** (`DrinkDetailInputView.swift`): Reads `abvPrecisionPermille` from the profile via `@Query`. `displayedAbvValues` is regenerated from the preset's `abvMin`/`abvMax` (new computed properties on `DrinkTypePreset`) at the user-selected step. `safeAbvIndex` clamps the selection to the current array length.

**i18n**: 18 new `settings.*` keys (en/de/pl); `settings.placeholder` removed.

### Key decisions

- Inline guideline picker (`.pickerStyle(.inline)`) chosen over `.navigationLink` to show all 4 options with threshold subtitles in one view — avoids a push just to pick one of four options.
- Threshold summary strings ("20 g/day · 100 g/week") are hardcoded in the view extension — they're display-layer facts that don't need localization for the initial release.
- ABV precision uses `.segmented` style (2 options, always visible, no push needed).
- Volume unit label strings live in xcstrings; `%` characters in DE/PL translations reworded to avoid Xcode format-specifier false positives (`%-S` parse error on `%-Schritte`).

### Open / next steps

- Volume unit wiring in display layer (History rows, picker labels in AddDrink).
- Edit existing `ConsumptionEvent`.
- First-launch onboarding to guide the user through Settings on fresh install.

---

## 2026-05-17 07:40 — SwiftUI expert review fixes

### What was changed

Applied four correctness fixes flagged in the expert code review:

1. **`ForEach` identity** (`DrinkDetailInputView`): replaced `ForEach(preset.volumes.indices, id: \.self)` and `ForEach(preset.abvValues.indices, id: \.self)` with `ForEach(Array(...enumerated()), id: \.offset)`. `.indices` is an anti-pattern for dynamic content — array mutations can shift indices causing SwiftUI to diff incorrectly.

2. **Price locale bug** (`DrinkDetailInputView`): `Double(priceText)` returns nil for European decimal formats like "1,5". Added `parsedPrice` computed property that normalises comma → period before parsing.

3. **Emoji accessibility** (`DrinkTypeGridView`): added `.accessibilityHidden(true)` to the `Text(preset.icon)` emoji. The wrapping `NavigationLink` already carries `.accessibilityLabel(preset.name)`; without hiding the emoji, VoiceOver would read both the emoji description and the label.

4. **Midnight `@Query` refresh** (`DashboardView`): removed the custom `init()` that baked the 31-day cutoff into a `#Predicate` at view creation time — this cutoff never refreshed if the app stayed open past midnight. Now fetches all events with a plain `@Query`, filters in-memory using `@State private var now`, and updates `now` via `.onChange(of: scenePhase)` whenever the app returns to the foreground.

### Key decisions

- Fetching all `ConsumptionEvent` rows (no predicate) is acceptable for a personal tracking app where the total row count is small. Avoids the complexity of re-creating a `@Query` at runtime.
- `thirtyDayGrams` now explicitly filters for `-30 days` instead of relying on being "all events in the last 31 days" from the old predicate — semantically cleaner.

### Open / next steps

- Settings screen (highest priority).

---

## 2026-05-16 18:30 — Dashboard intake rings

### What was built

`DashboardView` replaces the "Coming soon" placeholder with three circular progress rings:
- **Today** — grams consumed today vs `dailyLimitGrams`
- **7 days** — grams in last 7 days vs `weeklyLimitGrams`
- **30 days** — grams in last 31 days vs `weeklyLimitGrams × (30/7)`

`IntakeRing` (private struct in DashboardView.swift): custom `Circle().trim` arc, color-coded green/orange/red at 70% and 100% thresholds, shows percentage and raw grams in centre, accessible via combined `accessibilityLabel`.

`@Query` with `#Predicate` filters events to last 31 days at init time; today and 7-day windows computed in-memory. Three new i18n keys added (`dashboard.ring.today`, `dashboard.ring.days7`, `dashboard.ring.days30`).

### Key decisions

- Custom `Circle().trim` over `Gauge(.accessoryCircularCapacity)` — the gauge style is unreliable outside widget contexts on iOS.
- 30-day limit derived as `weeklyLimit × (30/7)` — no official monthly guideline exists; this is a proportional approximation, labelled "30 days" not "monthly norm".
- Limits read from `UserProfile` with WHO fallback (20g daily / 100g weekly) since UserProfile seeding is still an open question. Dashboard remains functional without a seeded profile.
- UK guideline has `dailyLimitGrams = 0` (no daily limit stated). Ring shows "—" and no arc for that case.

### Open / next steps

- Settings screen: seeds UserProfile, lets user pick guideline — directly affects ring accuracy.
- UserProfile first-launch seeding (currently rings silently fall back to WHO defaults).
- `Localizable.xcstrings` still needs adding to Xcode project target.
