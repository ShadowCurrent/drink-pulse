# DrinkPulse — Development Log

Append a new entry after every non-trivial session. Never edit or delete old entries.
Format: `## YYYY-MM-DD HH:MM — Title`

## 2026-06-03 12:40 — Insights: limit nawigacji kalendarza do najstarszego wpisu

### Zmiany

- **`InsightsPeriod.swift`** — usunięto hardcoded `minOffset` (−156 tygodni, −35 mies., −3 lata); dodano `offset(for:relativeTo:calendar:)` zwracający liczbę okresów do tyłu dla dowolnej daty.
- **`InsightsViewModel.swift`** — dodano `oldestEventDate` (min timestamp z `events`) i `minAllowedOffset` (dynamiczny limit oparty na najstarszym wpisie; 0 gdy brak wpisów). `navigatePrev()` teraz blokuje się na tym dynamicznym limicie.
- **`PeriodPicker.swift`** — strzałka „wstecz" wyłącza się przy `vm.minAllowedOffset` zamiast statycznego `period.minOffset`.
- **Testy** — zaktualizowano 5 testów nawigacji (dodano zdarzenia historyczne); przepisano `period_cannotNavigateBeyondMinOffset` → `period_cannotNavigateBeyondOldestEvent`; dodano `period_navigatePrev_blockedWhenNoEvents` oraz 3 testy `minAllowedOffset_*`; zastąpiono 3 testy `minOffset_*` w `InsightsPeriodTests` ośmioma testami `offset(for:relativeTo:calendar:)`.

### Decyzje

- Brak wpisów → `minAllowedOffset = 0` → nawigacja wstecz zablokowana od razu. Sensowne: nie ma historii do pokazania.
- Nie ma sensu trzymać `minOffset` jako martwego kodu; usunięto.

## 2026-06-03 12:30 — plan-0022: Store-wipe safeguard & backup integrity (completed)

### Zmiany

- **`StoreBootstrap`** (`Domain/Persistence/`) — niedestrukcyjna odbudowa kontenera.
  Zamiast `try? FileManager.removeItem` pliki sklepu są przenoszone do
  `Application Support/RecoveredStores/<timestamp>/`. Maksymalnie 3 snapshoty;
  "Delete all data" czyści też `RecoveredStores/`. `drinkpulseApp.swift`
  deleguje bootstrapowanie do `StoreBootstrap.makeContainer` (`@MainActor`).
- **Export bundle v2** — nowe pole `profile: ProfileRecord?`. `ProfileRecord` to
  `Codable` mirror wszystkich stored fields `UserProfile`. Wersja bundla bumped
  do 2; v1 nadal importuje się poprawnie.
- **Content-based regeneracja** — `DataSection.task` ma teraz id = `contentSignature`
  (hash po polach eventów + profilu), nie `events.count`. Edycja drinka odświeża plik.
- **Surfacing błędów importu** — `DataImporter` rzuca `ImportError.decodeFailure` lub
  `.unsupportedVersion` zamiast `try?`. `DataSection` pokazuje alert z komunikatem.
- **Profile upsert** — import v2 nadpisuje istniejący profil w miejscu (single-user,
  restore intent); wstawia nowy jeśli brak.
- **Testy**: 288 testów, wszystkie zielone (20 nowych / zmodyfikowanych w
  `DataExportImportTests`, 6 nowych w `StoreBootstrapTests`).
- **Living docs**: `domain.md` (backup format, version table, upsert rule),
  `architecture.md` (persistence bootstrap section, data transfer section),
  `roadmap.md` (plan-0022 ✅), `open-questions.md` (migration note updated).

### Kluczowe decyzje

- Recovered stores: keep-last-3 (lean z planu; nie keep-all bo disk use).
- Delete all data: czyści RecoveredStores (lean z planu; kompletna akcja).
- Profile restore conflict: overwrite silently (single-user, restore intent).
- `nonisolated` na `recoverStore`/`clearRecoveredStores`/`trimRecoveredStores` —
  tylko operacje FileManager, nie potrzebują main actora.

### Nierozwiązane / do zrobienia

- 5 linii z compiler-generated implicit closures (nil-coalescing `?? []` i `?? .distantPast`)
  nieprzykrytych w `StoreBootstrap`/`DataImporter` — niemożliwe do wywołania w realnym env.
- `SchemaMigrationPlan` nadal wymagany przed App Store (plan-0022 nie dodaje migracji,
  tylko bezpieczną ścieżkę recovery).

## 2026-05-31 16:30 — Przegląd planów draft + reconciliation living docs (enterprise standards)

### Kontekst

Plany draft (0013, 0016, 0020) były pisane przez Sonnet 4.6. Zadanie: zweryfikować je
względem realnego kodu, doprecyzować instrukcje dla wykonawcy, oraz podnieść CLAUDE.md i
living docs do standardów enterprise. Nie pisano kodu — same dokumenty/plany. Plany
pozostają w statusie `draft`.

### Wykryte rozbieżności plan ↔ kod (i poprawki)

- **plan-0013**: krok „usuń toolbar `+` z History" był nieaktualny — w `HistoryView` nie
  ma żadnego `+` (dodawanie obsługuje FAB z plan-0010). `EventRow` jest dziś `private` w
  `HistoryView.swift`; day-detail miał go „odwzorować" → dodano krok ekstrakcji do
  `Components/EventRow.swift` (reuse zamiast duplikacji). Dodano konkretny wzorzec
  dynamicznego `@Query` w `init` (#Predicate na `let` z init), bound earliest-event przez
  `FetchDescriptor.fetchLimit = 1`. Rozstrzygnięto Q3 (przyszłe dni → dimmed, non-tappable).
- **plan-0016**: wprowadza nową warstwę `Services/`, nieobecną w `architecture.md` → dodano
  krok 0 (ADR-0005 + aktualizacja architecture.md). Zdefiniowano jawnie protokół
  `NotificationScheduling` + `FakeNotificationCenter` dla testów (cel ≥85%). Rozstrzygnięto
  Q1–Q4 (21:00; copy neutralne — spójne z risk-language; flaga przeżywa kill; „Open Settings").
- **plan-0020**: najpoważniejsza korekta merytoryczna. Plan twierdził, że poprawka wpływa na
  „weekly progress bar i weekly percentage" — błąd: `weeklyPct`/pasek „7 Days" liczą się z
  `sevenDayGrams` (kroczące, `startOfDay`), niezależne od `firstWeekday`. Realny user-visible
  efekt to wyłącznie `weekBarData` → wykres `ThisWeekCard`. `weeklyGrams` nie ma konsumenta w
  UI (tylko test). Przeprojektowano testy: zdarzenie w niedzielę 2026-05-24 przy `now`=środa
  2026-05-27 wpada w różne tygodnie zależnie od `firstWeekday` (1 vs 2) — poprzedni test
  „sobota" niczego nie dowodził.

### Reconciliation living docs (sprzeczność repository)

Kod nie ma **żadnej** warstwy Repository (0 typów), wszystkie widoki używają `@Query` +
`modelContext`. `architecture.md` był już poprawny, ale **CLAUDE.md** (4 miejsca) i
**ADR-0003** wciąż opisywały repozytoria.

- ADR-0003 oznaczony **Superseded by ADR-0004** (body nietknięte — historia).
- Utworzono **ADR-0004** „Data access via @Query + stateless view models".
- CLAUDE.md: sekcja Architecture przepisana (brak repo, dodano warstwę Services); cele
  pokrycia „Repositories ≥85%" → „Services ≥85%"; „Repository methods" → „Service logic";
  mock boundary → service/data-access.

### Enterprise standards w CLAUDE.md

Dodano sekcję „Engineering standards (non-functional)": privacy & security (on-device only,
brak sieci poza CloudKit, health data jako wrażliwe, brak 3rd-party SDK), logging &
observability (os.Logger, zero PII w logach, brak `print` w produkcji, typed errors),
quality gates (zero warnings, coverage, file-size, brak force-unwrap = definition of done),
change hygiene (migracje przed shipem, zmiany destrukcyjne wymagają zgody). Dodano też punkt
2 checklisty „Privacy & logging review" (przenumerowano 2→3…9→10).

### Decyzje (w tym odrzucone alternatywy)

- ADR-0003 nie był przepisywany (immutable) — użyto statusu Superseded zgodnie z README ADR.
- Warstwa Services: wybrano ADR + architecture.md (nie „lekko bez ADR", nie „bez warstwy").
- Zakres enterprise: pytanie wieloboru wróciło bez odpowiedzi → przyjęto wszystkie cztery
  obszary, ale proporcjonalnie do realiów (solo dev, offline, brak backendu).

### Otwarte / następne kroki

- Plany 0013/0016/0020 gotowe do wykonania (nadal `draft` — zamrożić przy starcie).
- Przy wykonaniu plan-0016: realnie utworzyć ADR-0005 (services-layer) + zaktualizować
  architecture.md (Services/).
- open-questions.md: próg kolorów kalendarza oznaczony RESOLVED (usunąć po wykonaniu 0013).

## 2026-05-31 12:00 — Bugfix: wyciek danych preview z InsightsViewModel

### Problem

`InsightsViewModel` posiadał publiczny `var dataProvider: (Date) -> Int?` — hook pozwalający
wstrzykiwać dane generowane przez `InsightsDataGenerator` bezpośrednio w produkcyjny kod path
(`gramsForDay` miał fallback do `dataProvider`). Choć w produkcji defaultował do `{ _ in nil }`,
architektura była krucha: mutowalny publiczny var mógł zostać przypadkowo ustawiony, a sama obecność
fallbacku w release build była niepotrzebna.

### Rozwiązanie

- Usunięto `var dataProvider` i fallback z `gramsForDay` — metoda korzysta wyłącznie z `events`
- Dodano `InsightsDataGenerator.previewEvents(days:)` zwracające gotowe `ConsumptionEvent` obiekty
- `InsightsViewModel.preview` ustawia teraz `events` bezpośrednio (zamiast podpinać generator)
- Podgląd `InsightsView` wstrzykuje 90 dni zdarzeń do in-memory ModelContainer
- Podział plików testowych: `InsightsViewModelTests` (520→207 linii) + dwa extensions;
  `DashboardViewModelTests` (357→248 linii) + nowy extension

### Wynik

248 testów zielonych. Żaden plik nie przekracza 300 linii.

## 2026-05-30 — Hotfix: bootstrap UserProfile w RootShellView

### Problem

Stary `deleteAllData()` (zanim trafił fix z resetem pól) usunął `UserProfile` ze SwiftData na urządzeniu użytkownika. Po reinstalacji z nowym kodem `SettingsView` wyświetlał `ProgressView()` w nieskończoność — `@Query` zwracał pustą tablicę, a nie było mechanizmu, który by to naprawił.

### Naprawa

Dodano bootstrap w `RootShellView` — jedynym miejscu zakorzenionnym nad wszystkimi widokami wymagającymi profilu:

```swift
.onChange(of: profiles.isEmpty, initial: true) { _, isEmpty in
    if isEmpty { modelContext.insert(UserProfile()) }
}
```

- `initial: true` — odpala od razu przy pierwszym renderze, nie czeka na zmianę
- Naprawia zepsute telefony bez żadnej akcji użytkownika — przy pierwszym uruchomieniu nowego builda `UserProfile` zostaje odtworzony z domyślnymi wartościami
- Obrona przed przyszłymi podobnymi sytuacjami (crashe migracji, błędy sync itp.)

### Dlaczego tu, a nie w SettingsView

Dashboard, History, Insights — wszystkie zależą od `UserProfile`. Gdyby bootstrap był tylko w `SettingsView`, inne zakładki wciąż mogłyby się posypać. `RootShellView` jest jednym widokiem, który wszystkie zakładki obudowuje.

---

## 2026-05-30 — Delete All Data w ustawieniach

### Co zrobiono

Dodano opcję całkowitego wyczyszczenia bazy danych z poziomu Settings → Data.

**`DataSection.swift`**:
- Nowy przycisk „Delete all data" z rolą `.destructive` (systemImage: `trash`)
- Alert potwierdzający z tytułem, komunikatem ostrzegawczym i przyciskiem „Delete All" (`.destructive`)
- Metoda `deleteAllData()`: usuwa wszystkie rekordy `ConsumptionEvent`, `DrinkTemplate` i `UserProfile` przez `modelContext.delete(model:)`; resetuje `AppStorage("dp_onboarding_done")` do `false` — aplikacja wraca do onboardingu

**`Localizable.xcstrings`**:
- Dodano 4 nowe klucze (EN/PL/DE): `action.deleteAll`, `settings.data.deleteAll`, `settings.data.deleteAll.title`, `settings.data.deleteAll.message`

### Decyzje

- Usuwamy również `UserProfile` i resetujemy `onboardingDone`, żeby aplikacja trafiła z powrotem do onboardingu — jest to oczekiwane zachowanie dla „factory reset".
- Brak osobnego repozytorium/serwisu — per architektura, proste mutacje SwiftData pozostają bezpośrednio w widoku.
- Nie ma logiki do testowania jednostkowo (delegujemy do SwiftData API).

---

## 2026-05-30 — Rozbudowa .gitignore + usunięcie śledzonych plików user-data

### Co zrobiono

Przepisano `.gitignore` od zera. Poprzednia wersja pokrywała tylko absolutne minimum (`.DS_Store`, `xcuserdata/`, `DerivedData/`, `.build/`, `build/`, wpisy Claude Code i `drinkcontrol.csv`). Nowa wersja dodaje:

- Dodatkowe artefakty macOS (`._*`, `.AppleDouble`, `.Spotlight-V100`, `.Trashes`, `.fseventsd`)
- Brakujące artefakty Xcode: `*.xccheckout`, `*.xcuserstate`, `*.xcresult`
- Code signing: `*.p12`, `*.cer`, `*.mobileprovision`, `*.certSigningRequest`, `ExportOptions.plist`
- Instruments: `*.trace`, `*.dtps`
- Fastlane (na wypadek przyszłego użycia)
- Env/secrets: `.env`, `.env.*`, `*.secret`, `secrets.plist`
- Edytory: `.vscode/`, `.idea/`
- Komentarz wyjaśniający, że `xcshareddata/xcschemes/` celowo NIE jest ignorowane

### Wyczyszczenie repozytorium

Z indeksu git usunięto plik `drinkpulse.xcodeproj/xcuserdata/fempter.xcuserdatad/xcschemes/xcschememanagement.plist` (był śledzony, a powinien być zignorowany jako user-specific Xcode data). Plik pozostaje lokalnie na dysku, git przestaje go śledzić.

## 2026-05-30 — [plan-0019] File export/import + DrinkControl migration

Analysed real DrinkControl export file (101 entries, semicolon-delimited CSV). Removed unused `ConsumptionEvent.location` field. Implemented native JSON export/import (DataExporter + DataImporter) with deduplication by (timestamp ±1s, volumeMl, abv ±0.001). Implemented DrinkControl CSV importer with full category mapping (including `vodka` → `.spirits`), NumberOfDrinks>1 handling, and RegisteredDate as timestamp. DataSection added to Settings with ShareLink export + two fileImporters + confirmation/result alerts. 22 new tests. 248/248 passing.

Note: DrinkControl uses 0.789 g/ml density vs. DrinkPulse's 0.8 g/ml — imports raw ml+ABV to let DrinkPulse derive grams consistently.

## 2026-05-30 — [plan-0014] Custom name, notes, and category change

Implemented plan-0014 in one pass. Added `customName: String?` to `ConsumptionEvent` (lightweight SwiftData migration) with a `displayName` computed property that falls back to `name` when custom name is blank. `notes` field was already in the schema but not exposed in UI — now wired up in `EditEventView` via new `EditCustomNameSection` and `EditNotesSection` components (notes capped at 500 chars). `HistoryView.EventRow` uses `displayName` and shows a note icon when notes are present. 6 new `ConsumptionEventTests` for `displayName` behaviour. 226/226 tests passing.

Key decision: `customName` is NOT reset on category change — it's a persistent user label separate from the category snapshot `name`.

## 2026-05-30 — [plan-0001] Dashboard Redesign — plan closed

Reviewed Insights screen modified files (HealthMetricsCard, InsightsHeroCard, PeriodPicker, InsightsViewModel) and applied two minor cleanups: removed unused `@Environment(\.dpTheme)` from `InsightsHeroCard` (was generating a Swift warning) and removed the redundant `isCurrentPeriod` guard inside the "jump to now" button action (button is already `.disabled` when on current period).

Closed plan-0001 (Dashboard Redesign). The plan was a large parent that was delivered across plans 0007–0018 over two weeks. Created `retrospective.md`; updated `INDEX.md` status to `completed`.

## 2026-05-22 08:00 — [plan-0012] Insights screen — plan closed

Implemented the full Insights tab from scratch, replacing the "Coming Soon" placeholder.

**What shipped:**
- `InsightsPeriod` (week/month/year) with locale-aware `dateRange`.
- `InsightsViewModel` + `InsightsViewModel+Heatmap` extension: area chart bucketing (day/week/month by period), weekday averages (divided by week count, not day count), 4×7 locale-aware heatmap, binge episode detection (per-guideline threshold: 60 g WHO/DE, 56 g UK, 70 g US), monthly calories, monthly spend, guideline comparison bars (WHO / NHS / DHS).
- 6 Components: `PeriodPicker`, `AlcoholAreaChart`, `WeekdayBarChart`, `ActivityHeatmap`, `HealthMetricRow`/`HealthMetricsCard`, `GuidelineComparisonCard`.
- 27 new tests (167 total, all passing).
- All `insights.*` localization keys translated (en + pl).

**Key decisions:**
- Binge threshold per-guideline (Q2 option B) — owner chose this at session start.
- Heatmap first weekday locale-aware (Q1 option B) — locale-aware, not hard-coded Mon→Sun.
- Heatmap empty state: greyed cells (Q3 option A).
- `cal`/`sex`/`guidelineChoice` changed from `private` to `internal` to allow cross-file extension access.
- `chartYScale(domain: 0...)` → `.automatic(includesZero: true)` — Swift Charts API constraint.

**Open:** plan-0001 (Dashboard Redesign) is now ready to close.

## 2026-05-21 16:00 — [plan-0011] Dashboard arc-progress hero + chip refactor — plan closed

Final review and close of plan-0011.

**Changes in this session:**
- `StreakCard.frame(maxHeight: .infinity)` — both streak cards now match the taller one's height inside the `HStack`.
- Added 9 tests to `DashboardViewModelTests`: `todayPct` (zero / half / raw > 1.0 unclamped), `todayRiskLevel` (safe / caution / exceeded), `effectiveRiskLevel` (daily exceeded, weekly exceeded, both low).

**What plan-0011 delivered in total:**
- `DashboardHeroCard`: 36pt intake value + `DPArcProgress` (100pt, risk-based colour) + high-risk pill when `todayPct > 1.0`.
- `DPChip` + `DashboardChipRow`: Calories (amber) + Drinks (purple). Spend removed from Dashboard — deferred to plan-0012 Insights.
- `DashboardViewModel`: `todayPct` (unclamped), `todayRiskLevel`, `effectiveRiskLevel` (worst of daily + weekly → drives header `RiskBadge`).
- `StreakCard` `zeroStateCopy` API for zero-state messaging.
- Arc colour = risk-based (not theme primary). Deviation from Q2 plan default — chosen during execution for clarity.

140/140 tests passing. Build clean. plan-0001 remains open pending plan-0012.

---

## 2026-05-21 14:00 — [plan-0018] Post-ship polish + plan-0018 fully closed

Follow-up fixes after plan-0018 shipped:

- **Settings row height**: removed `.padding(.vertical, 12)` from `SettingsRow`,
  `guidelineRow`, and system lock button — was doubling List's native cell padding.
- **Theme swatch bug**: `onTapGesture` inside List cell intercepted by List gesture
  recognizer causing wrong theme to apply. Fixed by replacing with `Button.plain`.
- **Tab icon fill**: attempted unfilled icons + mid-slide fill via `selectedTab` binding —
  iOS 26 TabView has no public API for glass pill position. Settled on `.fill` variants
  permanently.
- **`tabViewBottomAccessory` experiment**: explored moving Add Drink to bottom pill; pill
  always renders even when content is empty, no theme color control. Reverted.

Plan-0018 fully closed. All living docs updated.

---

## 2026-05-21 11:30 — [plan-0018] Native iOS 26 shell redesign

Reverted plan-0010's `Tab(role: .search)` hack. App shell is now fully native iOS 26
throughout — no custom containers, no explicit material wrappers, no conflicting backgrounds.

**Changes:**
- `AppTab.addDrink` case removed; `RootShellView` simplified to 4 native tabs.
- New `AddDrinkButton` component: 36pt gradient circle (theme.gradient) shown in nav bar
  toolbar on all 4 tabs. State (`showAddDrink`) stays in `RootShellView`; sheet presentation
  unchanged.
- Background tint: `theme.primary.opacity(0.04)` via ZStack in `RootShellView` — follows
  selected Ember/Forest/Iris palette.
- Dashboard cards (MetricCard, StreakCard, GuidelineAlertCard, ConsumptionOverviewCard,
  ThisWeekCard) switched from `secondarySystemBackground + clipShape` to `dpGlassCard()`.
  GuidelineAlertCard keeps a red `0.10` opacity overlay for visual distinction.
- `DrinkTypeTile` (AddDrink category grid): `dpGlassCard(.chip)`; explicit
  `.background(Color(.systemBackground))` removed from grid view.
- `SettingsView` converted from `ScrollView + VStack + dpGlassCard()` to
  `List { Section { } } .listStyle(.insetGrouped)`. Eliminates the dark/light mode flash
  caused by explicit background conflicting with glassEffect rerender timing.
- `AppearanceCard` → `AppearanceRows`: stripped card wrapper; rows now live inside a List
  Section and inherit native glass card appearance automatically.
- `SettingsRow`: removed explicit `.padding(.horizontal, 16)`; List provides horizontal insets.
  Removed unused `cardRow()` extension.
- `GuidelineStep` (onboarding): `listStyle(.plain)` → `.insetGrouped` for consistency.
- 127/127 tests passing. Build clean. No new tests required (purely UI changes).

---

## 2026-05-20 12:45 — plan-0008 + plan-0010: close both plans

### What changed
- **DPBottomBar redesigned** (plan-0010 pivot): flat `.bar` Material bar replaced with
  floating glass capsule pill (`glassEffect(.regular, in: Capsule())` on iOS 26;
  `ultraThinMaterial + strokeBorder` fallback on iOS 18) + detached 64pt gradient FAB.
  Layout: `HStack(spacing: 10) { pill, FAB }` at `bottom: 14`.
- Retrospectives written for plan-0008 and plan-0010; both marked completed.
- INDEX.md and roadmap.md updated (0008 🔄→✅, 0010 🔄→✅).
- Scheme fixed: `shouldAutocreateTestPlan = "YES"` kept; tests reliably run with
  `-only-testing:drinkpulseTests` (127/127 green).

### Key decisions
- Pill uses native `glassEffect` — one call, no manual background math on iOS 26.
- `TabItemButton` active state: `RoundedRectangle(cornerRadius: 18)` with
  `activeColor.opacity(0.12/0.16 dark)` — matches design spec.
- FAB inner highlight: `LinearGradient([.white.opacity(0.34), .clear])` overlay inside
  the circle — gives tactile "glass dome" appearance without custom shaders.

### Open questions
- None new.

---

## 2026-05-20 12:10 — plan-0010: floating tab bar + FAB

### What changed
- `AppTab` enum (home/insights/history/settings) with SF Symbol names.
- `DPBottomBar` — four tab items + 54pt gradient FAB; `SpringButtonStyle` for press animation; bar background uses `.bar` Material on iOS 26, `.ultraThinMaterial` + divider on iOS 18; extends into home-indicator safe area.
- `RootShellView` replaces `ContentView` as the app shell; `@ViewBuilder switch` over `AppTab`; single `showAddDrink` state drives the Add Drink sheet.
- `InsightsView` placeholder (`ContentUnavailableView`) pending plan-0012.
- `DashboardView` and `HistoryView` had toolbar `+` buttons and `showAddDrink` state removed.
- `drinkpulseApp` updated to use `RootShellView`.
- 4 new localization keys (en/de/pl): `tab.insights`, `insights.comingSoon.*`.

### Key decisions
- Tab state not preserved on switch (ViewBuilder recreates NavigationStack). Acceptable v1; can upgrade to opacity/allowsHitTesting pattern later.
- `.safeAreaInset(edge: .bottom)` keeps bar in-flow; content scrolls above it naturally.

### Open questions
- None new.

---

## 2026-05-20 11:45 — plan-0008: theme palettes Ember / Forest / Iris

### What changed
- `DPTheme` enum: primary colour + gradient pair for Ember (#FA5D36→#FF7C00), Forest (#008140→#529420), Iris (#7D5BE6→#B85DF1). sRGB values pre-converted from oklch via Python.
- `DPTheme+Environment.swift`: `@Entry var dpTheme` key.
- Root injection in `drinkpulseApp`: `.environment(\.dpTheme, theme)`, `.tint(theme.primary)`, `.preferredColorScheme(...)` driven by `@AppStorage("dp_color_scheme")`.
- Settings Appearance section: theme swatch picker + light/dark/system mode picker.
- `SettingsRow` extracted to `Components/SettingsRow.swift` (file-size housekeeping).
- 9 new localization keys (en/de/pl). 6 new tests. 127/127 passing.

### Key decisions
- Scope narrowed: card backgrounds stay system glass, tab bar stays system. Theme drives only `.tint()` + FAB gradient — most iOS 26-native approach.
- Default: Ember. Colour scheme default: system.

### Open questions
- None new; FAB gradient consumed by plan-0010.

---

## 2026-05-20 11:05 — plan-0009: close onboarding flow

### What changed
- Wrote retrospective for plan-0009 and marked it completed.
- Updated INDEX.md (in-progress → completed) and roadmap.md (🔄 → ✅).
- Discovered missing shared xcscheme: created `xcshareddata/xcschemes/drinkpulse.xcscheme`
  so `xcodebuild test` finds the `drinkpulseTests` target. Without it the auto-generated
  scheme produced 0 tests. Now committed to source control.

### Key decisions
- Verified all 121 tests pass (Swift Testing framework; XCTest summary showed 0 because
  Swift Testing has a separate reporter — both are green).

### Open questions
- Schema migration for `ageYears → dateOfBirth` still open (see open-questions.md).

---

## 2026-05-20 10:45 — plan-0017: test coverage to ≥90% + 6 bug fixes

### What changed

**Phase A — Bug fixes (4 production fixes, 2 coverage-only):**
- SB-1: `DashboardViewModel.guidelineDisplayName` was hardcoding English acronyms
  ("WHO", "DHS", "NHS", "NIAAA"). Now delegates to `GuidelineChoice.displayName`
  which uses `String(localized:)`. Confirmed broken in Polish locale by a failing
  test before the fix.
- SB-2: `.custom` guideline with `weeklyGoalGrams == 0` produced a zero denominator,
  making `weeklyPct = 0` and `riskLevel = .safe` regardless of consumption.
  Fixed by clamping `max(weeklyGoalGrams, 1.0)` in `DashboardViewModel.limits`.
- SB-3: `GuidelineStep.onboardingName` had `.who: "WHO"` hardcoded; other cases
  used `String(localized:)`. One-liner fix.
- SB-4: `DrinkTypePreset.preset(for:)` used `first{} ?? .custom` — the fallback was
  unreachable but hid future category additions. Replaced with exhaustive switch.
- SB-5/SB-6: No production fixes; added tests for `formattedAlcohol`, `formattedSpend`,
  `todaySpend`, `todayDrinkCount` (coverage-only).

**Phase B+D — New test files:**
- `GuidelineChoiceDisplayTests.swift` — `displayName` + `thresholdSummary`
- `AlcoholUnitTests.swift` — `unitLabel` + `displayName` on `AlcoholUnit`
- `DrinkTemplateTests.swift` — SwiftData init round-trip

**Test infrastructure:**
- `DashboardViewModelTests.swift` split from 324 lines into 3 files:
  main + `+Metrics.swift` + `+Formatting.swift`. All under 200 lines.
- Test count: 73 → 121 tests.

### Coverage results (testable code)

| Layer | Before | After | Target |
|---|---|---|---|
| Domain | ~64% | ~100% | 100% |
| DashboardViewModel | 71% | 98% | ≥90% |
| OnboardingViewModel | 90% | 100% | ≥90% |
| DrinkTypePreset | 63% | 91% | ≥90% |
| UserProfile | 65% | 91% | 100% (excl. preview helper) |

### Key decisions

- `max(weeklyGoalGrams, 1.0)` as inline literal; named constant would add
  ceremony without clarity (noted in execution log as resolved open question).
- `DashboardViewModelTests` split into 3 files rather than 2: main (streaks/risk/bars),
  +Metrics (counts/spend/limits), +Formatting (display/greeting/formatting).
- `GuidelineChoiceDisplayTests` marked `@MainActor` because `displayName` is
  inferred as main-actor-isolated (defined in a file that imports SwiftUI).

### Open questions

None new. SB-5 confirmed as a testing gap only (no behavioral bug in `formattedAlcohol`).

---

## 2026-05-20 06:15 — plan-0007: design system primitives completed

### What changed (visual QA + AX5 fix)

Visual QA via Previews:
- Light mode: glass cards and arc gauge render correctly.
- Dark mode: ultraThinMaterial fallback produces correct dark charcoal cards.
- AX5: found critical regression — `HStack` rows stacked characters vertically. Fixed with `SettingsRow<Content>` (private struct in SettingsView) that checks `dynamicTypeSize.isAccessibilitySize` and switches to `VStack(alignment: .leading)`. Also fixed guideline disclosure row with inline `typeSize` conditional in `SettingsForm`.

**Also committed:** AX5 fix for `guidelineCard` using `@Environment(\.dynamicTypeSize)` on `SettingsForm`.

**Status:** plan-0007 completed. 73 tests passing.

---

## 2026-05-19 16:40 — plan-0007: design system primitives (in-progress)

### What changed

- **`DesignSystem/DPGlass.swift`** — `dpGlassCard(_:)` view modifier. `DPGlassSize` enum: `.chip` (r=16), `.card` (r=22), `.sheet` (r=28). On iOS 26+: `glassEffect(.regular, in: .rect(cornerRadius:))`. On iOS 18 fallback: `ultraThinMaterial` + white inset stroke + drop shadow (values differ for light vs dark).
- **`DesignSystem/DPSemanticColors.swift`** — `Color.dpRiskLow / .dpRiskModerate / .dpRiskHigh` via three new Asset Catalog colorsets (adaptive light/dark).
- **`DesignSystem/DPLargeTitle.swift`** — `dpLargeTitle()` modifier: `.system(size: 28, weight: .bold)` + `.kerning(-0.6)`.
- **`DesignSystem/DPArcProgress.swift`** — 240° arc gauge. `ArcShape` draws from 150° CCW-in-math (= CW on screen) for correct speedometer orientation. Accessibility label reads localized `arc.progress.label`.
- **`Domain/GuidelineChoice+Display.swift`** — `displayName` and `thresholdSummary(for:)` extracted from private extensions in SettingsView and GuidelineStep. Added to resolve duplication forced by the file-split.
- **`Features/Settings/SettingsView.swift`** — pilot adoption: `Form` replaced by `ScrollView + VStack` with `.dpGlassCard()` on each section. `GuidelinePickerSheet` extracted to `Components/` to keep file under 300 lines.
- **`Localizable.xcstrings`** — added `arc.progress.label` (en/de/pl).

### Key decisions

- Q1 (Form vs custom): custom cards — exact match to design handoff.
- Q2 (iOS 26 native vs hand-rolled): `#available(iOS 26, *)` conditional — native on 26+, material fallback on 18.
- Q3 (corner radii): design values (16/22/28).
- `GuidelineChoice+Display.swift` placed in `Domain/` rather than a feature subfolder because `displayName` + `thresholdSummary` are domain-display concerns shared by Settings and Onboarding.

### Status

Build clean, 73 tests passing. plan-0007 in-progress; visual QA (Previews light/dark/AX5) needed before closing.

---

## 2026-05-19 14:30 — plan-0009: onboarding flow shipped

### What changed

**Domain model** (`UserProfile.swift`):
- `ageYears: Int` (stored) replaced by `dateOfBirth: Date?` (stored) + `ageYears: Int?`
  (computed). Full DOB gives auto-updating age for future BAC/Widmark calculations.
- Breaking schema change: dev-only wipe fallback added to `drinkpulseApp.swift`.
  Must become a proper `SchemaMigrationPlan` before App Store submission.

**App routing** (`drinkpulseApp.swift`):
- `@AppStorage("dp_onboarding_done")` controls first-launch routing.
- Auto-insert of default `UserProfile` removed; onboarding owns profile creation.

**Settings** (`SettingsView.swift`):
- `TextField`+`onChange` for age replaced with `DatePicker` for `dateOfBirth`.

**Onboarding feature** (`Features/Onboarding/`):
- 5 new files: `OnboardingViewModel`, `OnboardingView`, `WelcomeStep`, `ProfileStep`,
  `GuidelineStep`.
- Step container: `TabView(.page)` with dot indicator; reduces-motion aware.
- Profile step: segmented sex picker + DatePicker + "Stored only on this device" privacy note.
- Guideline step: WHO/DE/UK/US list with live g/day · g/week thresholds.
- Skip semantics: skip-all (no profile), skip step, skip guideline (WHO default).

**Tests**: 8 new tests in `OnboardingViewModelTests.swift`; 73 total — all green.

### Key decisions

- `dateOfBirth: Date?` chosen over `birthYear: Int?` (accurate for BAC, full DOB doesn't
  leave device). Per owner decision mid-session.
- `TabView(.page)` used as default (plan Q1 option A) — native swipe, standard iOS feel.
- `guidelineExplicitlyPicked` flag prevents inserting a profile when user only touched
  the guideline screen without changing from WHO default.
- Test container lifetime: `makeContext()` returning orphaned context caused SwiftData
  `brk 1` trap; fixed by using `makeContainer()` pattern (matches existing tests).

### Living docs touched

- `docs/roadmap.md` — plan-0009 🗓 → 🔄.
- `docs/plans/INDEX.md` — plan-0009 `draft` → `in-progress`.
- `.claude/context/open-questions.md` — added SwiftData migration plan item.
- `docs/plans/0009-onboarding-flow/execution.md` — created.
- Localizable.xcstrings — 15 new onboarding keys + `settings.age` → `settings.dateOfBirth`.

### Open for next session

- plan-0009 stays in-progress (no retrospective yet — plan may need further work).
- SwiftData migration plan needed before shipping (see open-questions.md).

---

## 2026-05-19 13:40 — plan-0015: risk language rename completed

### What changed

- Updated `drinkpulse/Localizable.xcstrings` — three keys, all three locales (en / de / pl):
  - `dashboard.risk.safe`:     "On track" → "Low Risk" / "Im Rahmen" → "Geringes Risiko" / "W normie" → "Niskie ryzyko"
  - `dashboard.risk.caution`:  "Watch out" → "Moderate Risk" / "Aufpassen" → "Mittleres Risiko" / "Uważaj" → "Umiarkowane ryzyko"
  - `dashboard.risk.exceeded`: "Over limit" → "High Risk" / "Limit überschritten" → "Hohes Risiko" / "Powyżej normy" → "Wysokie ryzyko"

### Key decisions

- Title-case used ("Low Risk", not "Low risk") — matches design handoff; open question resolved with default.
- Enum case names (`.safe`, `.caution`, `.exceeded`) left unchanged per plan — internal API churn with no user benefit.
- The plan listed outdated string values ("Safe / Caution / Exceeded") that did not match the live file ("On track / Watch out / Over limit"). Actual values replaced; discrepancy noted in execution.md.

### Build / tests

Build clean, 0 errors. No Swift files over 300 lines. No unit tests needed (string-only).

### Living docs touched

- `docs/roadmap.md` — plan-0015 flipped 🗓 → ✅.
- `docs/plans/INDEX.md` — plan-0015 status `draft` → `completed`.
- `docs/plans/0015-risk-language-rename/execution.md` — created.
- `docs/plans/0015-risk-language-rename/retrospective.md` — created.

---

## 2026-05-19 13:15 — Claude Design handoff: 10 draft plans landed

### What changed

No code touched. A Claude Design HTML/CSS prototype bundle for an iOS 26
Liquid Glass refresh of DrinkPulse arrived; carved its content into ten
focused, draft plans so each piece can move independently once Open
questions are answered.

New plans (all `draft`):

| #    | Title                                                         | Size   |
|------|---------------------------------------------------------------|--------|
| 0007 | Design system: iOS 26 Liquid Glass primitives                 | medium |
| 0008 | Theme palettes: Ember / Forest / Iris                         | medium |
| 0009 | Onboarding flow (3 steps, skippable)                          | medium |
| 0010 | Floating tab bar with prominent Add-Drink FAB                 | medium |
| 0011 | Dashboard arc-progress hero + chip refactor                   | medium |
| 0012 | Insights screen                                               | large  |
| 0013 | History calendar with clickable days                          | medium |
| 0014 | Edit entry: custom name, notes, category change               | medium |
| 0015 | Risk language rename ("Safe" → "Low Risk")                    | small  |
| 0016 | Log-reminder local notifications                              | medium |

### Key decisions (captured inside the plans)

- Each plan starts as `draft` with explicit Open questions so the owner
  picks before any plan flips to `in-progress`.
- Plan 0001 (Dashboard Redesign) stays `in-progress`; the visual upgrade
  it scoped is being split into plans 0007/0008/0010/0011/0015. A
  cross-reference entry was appended to `0001/execution.md`.
- "Safe" risk wording is being removed everywhere — alcohol intake is
  never medically "safe" (owner-stated). Plan 0015 owns the rename.
- The Add Drink button moves to a 54pt FAB on the floating tab bar
  (visibility was a stated pain point). Toolbar `+` buttons go away in
  plan 0010.
- Theme palettes (Ember / Forest / Iris) become a brand-level choice in
  Settings; semantic accent colours (`dpTeal`, `dpAmber`, etc.) stay for
  domain-meaning use cases (risk, drink count).
- Onboarding adds **no required fields** — every step skippable; default
  guideline is WHO; default theme is Ember; appearance follows system.
- BAC estimator stays deferred. Apple Watch glance, widget, AI chat,
  PDF export of Insights stay as roadmap ideas — no plans yet.

### Living docs touched

- `docs/plans/INDEX.md` — added 10 rows; next number 0017.
- `docs/roadmap.md` — new "Medium-term (design handoff)" block linking
  plans; future ideas list extended (AI chat, PDF export, watch, widget).
- `docs/product.md` — Future section split into Planned (with plan links)
  vs longer-term Future.
- `README.md` — minimum deployment iOS 17 → iOS 18 (stale since plan 0006).
- `.claude/context/current-focus.md` — overwritten with this session's
  state and next-session candidates.
- `.claude/context/open-questions.md` — calendar-thresholds question
  cross-referenced into plan 0013.

### Memory saved (for future sessions)

`memory/`:
- `reference_claude_design_handoff.md` — pointer to the design bundle.
- `project_future_ai_chat.md`, `project_future_pdf_export_insights.md`,
  `project_future_apple_watch.md`, `project_future_widget.md`,
  `project_future_rerun_onboarding.md`.
- `feedback_risk_language.md`, `feedback_add_drink_prominence.md`.
- `user_role_and_app.md`.

### Build / tests

Not run — doc-only session.

### Open / next steps

Owner reviews the 10 draft plans, answers Open questions in each,
then we flip plans to `in-progress` in dependency order (recommended
sequence in `current-focus.md`).

---

## 2026-05-18 — Raise deployment target to iOS 18 [plan-0006]

### What changed

- **`IPHONEOS_DEPLOYMENT_TARGET`** — 17.0 → 18.0 in all 4 build configurations.
- **`ContentView.swift`** — restored `Tab {}` syntax (iOS 18); removed all biometric
  lock wiring (`AppLockState`, scenePhase observer, lock overlay, `didApplyInitialLock`).
- **`drinkpulseApp.swift`** — removed `AppLockState` creation and `.environment` injection.
- **`Features/Lock/`** — folder deleted: `AppLockState.swift`, `LockScreenView.swift`.
- **`Domain/BiometricService.swift`** — deleted.
- **`drinkpulseTests/BiometricServiceTests.swift`** — deleted; deregistered from `project.pbxproj`.
- **`Domain/UserProfile.swift`** — removed `appLockEnabled: Bool` field. SwiftData
  lightweight migration handles orphaned column automatically; no user action required.
- **`Features/Settings/SettingsView.swift`** — Privacy & Security section now shows a
  tappable row that opens `UIApplication.openSettingsURLString` instead of a Toggle.
  `import LocalAuthentication` replaced with `import UIKit`.
- **`project.pbxproj`** — removed `INFOPLIST_KEY_NSFaceIDUsageDescription`.
- **`Localizable.xcstrings`** — removed 7 keys (`lock.*`, `settings.appLock*`);
  added `settings.systemLock` and `settings.systemLock.footer` (en/de/pl).
- **`CLAUDE.md`**, **`docs/product.md`** — minimum deployment updated to iOS 18.
- **`docs/roadmap.md`** — "Conditional on dropping iOS 17" renamed to "iOS 18+";
  biometric migration and Tab {} items marked ✅.

### Key decisions

- **Removal without migration alert**: app not yet published, zero existing users.
  No `didShowLockMigrationAlert` flag needed.
- **Deep link row instead of toggle**: system-managed feature belongs in iOS Settings,
  not the app. The row opens the correct page directly.
- **SwiftData `appLockEnabled` removal**: no migration code written. SwiftData's
  lightweight migration silently orphans the column; safe for live apps too.

### Results

Build clean, 65/65 tests green (2 tests removed with BiometricServiceTests), 0 errors.

---

## 2026-05-18 — Biometric app lock [plan-0005]

### What changed

- **`Domain/BiometricService.swift`** — new `struct BiometricService` (Sendable). Wraps `LAContext` with an injected factory closure for testability. Exposes `canAuthenticate: Bool` (checks `.deviceOwnerAuthentication` policy) and `authenticate(reason:) async throws`. `biometryType` property used by `LockScreenView` to pick the right SF Symbol at runtime.
- **`Features/Lock/AppLockState.swift`** — new `@Observable @MainActor final class AppLockState`. Single source of truth for transient lock state (`isLocked: Bool`). Injected app-wide via `.environment(lockState)`.
- **`Features/Lock/LockScreenView.swift`** — full-screen overlay. On `.onAppear` triggers biometric auth automatically. Shows app name, biometry icon (faceid / touchid / lock.fill), "Unlock" button, and "Authentication failed" error label on failure. Cancel and system-cancel do not set `authFailed`.
- **`Domain/UserProfile.swift`** — added `appLockEnabled: Bool = false`. SwiftData lightweight migration (new field with inline default — no schema version bump required).
- **`drinkpulseApp.swift`** — creates `@State private var lockState = AppLockState()` and injects it into environment.
- **`ContentView.swift`** — added `@Environment(AppLockState.self)`, `@Environment(\.scenePhase)`, and `@Query profiles`. On `.background` transition, locks if `appLockEnabled`. ZStack overlay shows `LockScreenView` with `.opacity` transition when `lockState.isLocked`.
- **`Features/Settings/SettingsView.swift`** — new "Privacy & Security" section with a `Toggle` bound to `profile.appLockEnabled`. Disabled with explanatory footer when `!biometricService.canAuthenticate` (device has no passcode).
- **`drinkpulse.xcodeproj/project.pbxproj`** — added `INFOPLIST_KEY_NSFaceIDUsageDescription` to both Debug and Release build configurations.
- **`Localizable.xcstrings`** — 8 new keys (en / de / pl): `lock.authFailed`, `lock.authReason`, `lock.title`, `lock.unlock`, `settings.appLock`, `settings.appLock.footer`, `settings.appLock.footer.unavailable`, `settings.section.privacy`.
- **`drinkpulseTests/BiometricServiceTests.swift`** — 2 new tests: `canAuthenticate` returns false with a mock that always fails, true with a mock that always succeeds.

### Key decisions

- **Policy `deviceOwnerAuthentication`** (not `deviceOwnerAuthenticationWithBiometrics`): biometrics first; on failure iOS automatically shows the device passcode UI — no custom PIN needed in the app. Matches the UX expectation described by the user.
- **Lock trigger on `.background`** (not on `.inactive`): `.inactive` fires during screenshot preview and system overlays, which would cause false locks. `.background` only fires when the app truly leaves screen.
- **Transient lock state in `AppLockState`** (not persisted in SwiftData): the persisted flag `appLockEnabled` says whether locking is wanted; the in-memory `isLocked` says whether the app is currently locked. They are separate concerns.
- **`BiometricService` with injected factory** — `LAContext` is a class; the factory closure lets tests substitute a mock without introducing a protocol. Keeps the service a simple value type.

### Results

Build clean, 65/65 tests green (2 new), 0 errors.

---

## 2026-05-18 — Living document audit and update

### What changed

- **`README.md`** — full rewrite to reflect built state: all four screens operational (Dashboard with charts and streak cards, History with edit, Settings with all five preference controls, Add Drink v2), iOS 17 minimum, Xcode 16, 63 unit tests, `Components/` subfolder in architecture diagram.
- **`docs/product.md`** — Settings user stories corrected: body weight and currency are not yet in Settings UI (fields exist in `UserProfile` for future BAC/spending features). Future section split: BAC now explicitly requires body weight input; currency and spending tracker moved there too. "Weekly and monthly trend charts" removed from Future (weekly bar chart is already shipped).
- **`docs/architecture.md`** — four contradictions fixed: (1) "DesignSystem (future)" → DesignSystem exists and is used; (2) MVVM+Repository section rewritten — no repository layer exists; views use `@Query` + `modelContext` directly; view models receive injected plain values; (3) Navigation section updated — only AddDrink uses value-based `NavigationLink(value:)`; other tabs use `NavigationStack` for the title bar only; (4) DI section: removed reference to repositories being injected via `@Entry` keys; clarified the actual usage.
- **`docs/domain.md`** — ConsumptionEvent entity description updated to list optional fields: `price` (captured in AddDrink), `notes` and `location` (scaffolded for future features, not yet in UI).
- **`docs/roadmap.md`** — two corrections: (a) "Dashboard overflow rings (> 100% shown as second arc)" removed — implementation uses progress bars, not rings; (b) "Swift Charts: weekly trend, daily breakdown" updated to "monthly trend, more advanced breakdown charts" since the weekly bar chart is already shipped in plan-0001.
- **`CLAUDE.md`** — added Documentation update model section (append-only / immutable-after-freeze / living documents classification with per-file update triggers); living docs audit added as step 2 of end-of-task checklist; Git push rules section added.

### Key decisions

- Fields that exist in the model but are not yet in the UI (bodyWeightKg, currency, notes, location) are described as "scaffolded for future features" rather than removed — they represent intentional forward-planning, not errors.
- Roadmap items whose implementation took a different shape than originally planned (rings → progress bars) are corrected rather than kept as historical record — the roadmap describes current reality, not design intent.

---

## 2026-05-18 — Dashboard redesign [plan-0001]

### What changed

- **`DesignSystem/DPColors.swift`** — new file with 5 fixed accent colours (`dpTeal`, `dpAmber`, `dpRed`, `dpPurple`, `dpGreen`) as `Color` extensions.
- **`Features/Dashboard/DashboardViewModel.swift`** — new `@Observable @MainActor final class`. Inputs injected by the view (`events`, `profile`, `now`); all computed. Key properties: `todayGrams`, `todayCaloriesKcal`, `todayDrinkCount`, `todaySpend`, `weeklyGrams`, `weeklyPct`, `riskLevel`, `weekBarData` (Mon–Sun chart data), `currentStreakDays`, `soberDaysThisMonth`, `greetingText`. `weekStartsOnMonday: Bool` param added for future UserProfile wiring.
- **`Features/Dashboard/DashboardView.swift`** — full rewrite. Layout: greeting + `RiskBadge` header; `MetricCard` 2×2 grid (spend card hidden if no prices); `WeeklyGoalCard` with weekly ring + Swift Charts bar chart; two `StreakCard` blocks; `GuidelineAlertCard` shown only when limit exceeded.
- **`drinkpulseTests/DashboardViewModelTests.swift`** — 16 unit tests for all plan-required cases. Manually registered in `project.pbxproj` (test target uses explicit file refs).
- **`Localizable.xcstrings`** — 14 new keys (en/de/pl).

### Key decisions

- `weeklyGrams` uses current week interval (Mon–Sun) rather than rolling 7 days, so the ring and bar chart share the same domain. More coherent UX.
- Guideline alert card is non-tappable placeholder; user has a Figma design for the tap action (deferred).
- Currency uses `NumberFormatter.currencyCode` from `UserProfile.currency`. Multi-currency (per-drink currency field) deferred to a separate plan.
- `currentStreakDays` returns 0 when `events` is empty (loop would otherwise return 366+; no drink history = no meaningful streak).
- `UIColor.quinarySystemFill` does not exist; replaced with `quaternarySystemFill` for future bars in bar chart.

### Results

Build clean, 52/52 tests green (16 new), 0 warnings.

---

## 2026-05-18 — Dashboard consumption overview [plan-0003]

### What changed

- **`DashboardViewModel.swift`** — added `thirtyDayGrams`, `thirtyDayLimitGrams`, `effectiveDailyLimitGrams` (UK fallback: `weeklyLimitGrams / 7` when no daily limit), `formattedNumber(_:)` (number only, no unit label).
- **`DashboardView.swift`** — added `sectionLabel(_:)` uppercase header helper; `ConsumptionOverviewCard` with three `IntakePeriodRow` stacks (Today / 7 Days / 30 Days); `ThisWeekCard` (bar chart only); removed `WeeklyGoalCard` ring (made redundant by 7 Days progress bar).
- **`Localizable.xcstrings`** — 6 new keys: `dashboard.section.today`, `dashboard.section.thisWeek`, `dashboard.overview.title`, `dashboard.overview.days7`, `dashboard.overview.days30`, `dashboard.overview.overLimit` (en/de/pl).
- **`DashboardViewModelTests.swift`** — 4 new tests: `thirtyDayGrams` boundary (day 29 included, day 31 excluded); `effectiveDailyLimitGrams` with WHO (uses actual daily) and UK (falls back to weekly/7).

### Key decisions

- Consumption overview placed **below** the today metrics grid. The header `RiskBadge` already surfaces risk immediately; today cards are the primary action area; the overview is supporting context.
- `WeeklyGoalCard` ring removed — the "7 Days" progress bar in the overview is a direct replacement.
- All gram values converted via `alcoholUnit.formattedValue` so the display respects the user's unit preference (grams / UK units / standard drinks).
- UK guideline (`dailyGrams == 0`) — `effectiveDailyLimitGrams` falls back to `weeklyLimitGrams / 7` to keep the Today progress bar meaningful.

### Results

Build clean, 56/56 tests green (4 new), 0 errors.

---

## 2026-05-18 — Lower deployment target to iOS 17 [plan-0002]

### What changed
- `IPHONEOS_DEPLOYMENT_TARGET` lowered from `26.5` to `17.0` across all four
  build configurations (app Debug/Release, tests Debug/Release).
- `ContentView.swift`: replaced iOS 18+ `Tab(title:systemImage:content:)` with
  the universally-supported `.tabItem { Label(...) }` pattern (iOS 16+).
- `CLAUDE.md`, `docs/product.md`, `docs/architecture.md`: updated minimum
  deployment references from iOS 26 to iOS 17.

### Key decision
Targeted iOS 17 (not iOS 18) to cover 2–3 major versions back. The only
iOS 18-specific API in the codebase was the new `Tab { }` initialiser; replacing
it with `.tabItem` is a no-cost mechanical change that also covers iOS 16.

### Results
Build clean, 36/36 tests green, 0 warnings.

---

## 2026-05-17 — Fix Swift 6 concurrency warnings

### What changed

- **`DrinkCategory` extracted to `Domain/DrinkCategory.swift`** — was co-located with `@Model class DrinkTemplate`, causing the SwiftData macro's `@MainActor` isolation to leak into `DrinkTypePreset` static properties via the `category: DrinkCategory` property chain.
- **`GuidelineChoice+Limits.swift` extracted** — `GuidelineLimits.swift` previously held both the struct and the `extension GuidelineChoice` block. The extension's connection to `@MainActor`-inferred `GuidelineChoice` was causing `GuidelineLimits.dailyGrams`/`weeklyGrams` to be inferred `@MainActor`. Now the struct lives alone in a file with no actor-isolated neighbours.
- **`nonisolated` added to `AlcoholUnit` extension members** (`formattedValue`, `unitLabel`, `displayName`) and `DrinkTypePreset.abvRange` — pure functions with no actor dependency, explicitly opted out of the `@MainActor` inference from the co-located `@Model` class.
- **`GuidelineChoice.limits(for:)` kept `nonisolated`** — now that the struct is separated, this annotation correctly documents that the function has no actor requirement.
- **`AlcoholCalculationTests` and `DrinkTypePresetTests` annotated `@MainActor`** — `AlcoholCalculationTests` constructs `ConsumptionEvent` (`@Model` = `@MainActor`); `DrinkTypePresetTests` accesses `DrinkTypePreset` static lets which are legitimately `@MainActor`-inferred. Adding `@MainActor` is honest and lets the `#expect` macro's autoclosures access isolated properties.

### Key decisions

- Chose per-file isolation over adding `nonisolated(unsafe)` to every static let. The file-split approach breaks the inference root and avoids the contradictory warning pair (compiler warns both "unnecessary" with `nonisolated(unsafe)` and "can't reference" without it on Sendable constants).
- Kept `DrinkCategory` as `Sendable` — still holds even after the move; `DrinkTypePreset.all`/`.custom` no longer warn after extraction.
- Build and test both clean: 0 warnings, 36/36 tests pass.

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

---

## 2026-05-22 15:35 — Insights screen test coverage (plan-0012 coverage close-out)

### What was built

Three new test files to bring Insights-layer coverage to ≥90%:

- **`InsightsDataGeneratorTests.swift`** (8 tests): nil guard for today/future/pre-2023, non-nil for start date, determinism, non-negative values, Saturday > Tuesday average (DoW multiplier), 2023 > 2025 average (trend multiplier). Coverage: 98.46%.
- **`InsightsPeriodTests.swift`** (18 tests): `localizedLabel` non-empty + distinct, `minOffset` constants, `dateRange` for all three periods + offset-1 cases (7-day span, 31-day May, 365-day year), `friendlyLabel` offset-0 vs offset-1 differ + format strings, `rangeLabel` dash separator / non-empty / year digit. Coverage: 89.47%.
- **`InsightsViewModelTests.swift`** additions (24 new methods): `drinkFreeDays`, `longestSoberStreak`, `heaviestDay`, `prevPeriodTotalGrams`, `trendFraction`, `periodSpendPerDay`, `navigateNext` increment branch, `limits(for: .custom)`, `seriesData` year case (12 monthly buckets), `friendlyLabel`/`rangeLabel` VM wrappers, `formattedValue` (no-profile path), `formattedSpend` non-empty. Coverage: 93.60%.
- Both new files added to `drinkpulse.xcodeproj/project.pbxproj` (PBXFileReference, PBXBuildFile, PBXGroup, PBXSourcesBuildPhase).

**Total tests**: 220 (up from 171 before this task's start). All pass.

### Key decisions

- `InsightsPeriodTests` requires `@MainActor` because `InsightsPeriod.localizedLabel` uses `String(localized:)` which is inferred `@MainActor` in Swift 6. Key path formation fails from non-isolated context; the `allCases.map(\.localizedLabel)` line was changed to a closure.
- Generator tests sample full calendar years (Sat vs Tue in 2024; Apr–Aug 2023 vs 2025) to get enough statistical signal despite dry-day probability randomness.
- Coverage methodology: xccov counts SwiftUI view bodies as executable lines even though they're excluded from the denominator per CLAUDE.md. Overall `drinkpulse.app` coverage is 19.35% (expected; views are untestable). VM, Domain, and utility layers all meet their per-layer targets.

### Open / next steps

- plan-0001 (Dashboard Redesign) should be closed — plan-0011 and plan-0012 both complete.
- Next features: plan-0013 (History calendar), plan-0014 (Edit entry), plan-0016 (Log-reminder notifications).
- `Localizable.xcstrings` still needs adding to Xcode project target.

## 2026-06-01 09:10 — plan-0020: Week start locale-aware

**What changed**: `DashboardViewModel` was hardcoding `firstWeekday = 2` (Monday)
via a `weekStartsOnMonday: Bool = true` property, causing `ThisWeekCard` bar chart
to always start on Monday regardless of the device's Language & Region setting.

**Fix**: removed `weekStartsOnMonday` and the private `cal` computed property;
replaced with `var calendar: Calendar = .current` (injectable for tests). All
internal `cal.` references renamed to `calendar.` (mechanical, ~15 call sites).

**Impact**: only `weekInterval` and its two consumers (`weekBarData`, `weeklyGrams`)
change behaviour. `weeklyPct`/`riskLevel` use `sevenDayGrams` (rolling 7-day) and
are unaffected. No persistence, no migration.

**Tests added**: two regression tests in `DashboardViewModelTests+Metrics.swift`
pinned to 2026-05-27 / event on 2026-05-24 (Sunday) — flips between calendars.

**Pre-existing failures noted** (unrelated): `InsightsViewModelTests`:
`monthSpend_sumsAllPricesInActivePeriod` and `bingeEpisodes_twoDaysAboveThreshold_countsBoth`
both fail on main before and after this change. To be fixed separately.

### Next up
- plan-0013 — History calendar with clickable days
- plan-0016 — Log-reminder local notifications

## 2026-06-01 09:40 — plan-0013: History calendar with clickable days

**What changed**: `HistoryView` now has a segment picker (List / Calendar). New files:
- `EventRow.swift` extracted from `HistoryView.swift`
- `HistoryViewModel.swift` — stateless VM: `monthCells`, `gramsByDay`, `groupedByDay`, `riskColor`
- `HistoryListQueryView` — windowed 90-day `@Query` with load-more sentinel
- `HistoryCalendarQueryView` + `HistoryCalendarView` + `HistoryCalendarDayCell` + `HistoryCalendarDayDetail`
- `HistoryView` refactored: earliest-event `@Query` (fetchLimit=1), `monthShown` state, prev/next nav, `canGoPrev`/`canGoNext`

**Key decisions**: nav arrows live in `HistoryView` (owns earliest-event bound); `DayCell.position` as id;
`ContentUnavailableView` only for list (calendar shows empty grid).

**xcstrings gotcha**: mixed `%@`/`%f` format specifiers rejected by xcstrings — accessibility labels
with grams values built in Swift, not via xcstrings format strings.

**Tests**: 14 functional + 4 performance. All 268 tests pass. Build zero warnings.

### Next up
- plan-0016 — Log-reminder local notifications

---

## 2026-06-01 11:10 — plan-0021: Edit-screen delete + type picker, list swipe fix

**What changed**:
- New `DrinkTypeGrid(selected:onSelect:)` (shared tile grid) + moved `DrinkTypeTile` into it,
  with an `isSelected` highlight. Add flow's `DrinkTypeGridView` re-pointed at it via
  `.navigationDestination(item:)` (same push, no behaviour change).
- New `EditDrinkTypeSelectionView` (edit-flow type picker, uses shared grid, applies + pops).
- `EditEventView`: inline category `Picker` → tappable `NavigationLink` row (icon + name);
  added `.topBarTrailing` red trash button → `.confirmationDialog` → `deleteEvent()`.
- `HistoryListQueryView`: `.onDelete` → per-row `.swipeActions` destructive button.
- Localization: `action.delete`, `editDrink.type`, `editDrink.changeType`,
  `editDrink.deleteConfirm.title`, `editDrink.deleteConfirm.message` (en/pl/de).

**Key decisions**:
- Delete = toolbar trash + confirmation (user-chosen); confirmation kept because it's
  irreversible health data.
- Dropped planned grouping memoization: freeze cause is the `.onDelete` + Button row
  interaction (fixed by `.swipeActions`), not grouping cost; memoizing would add a
  first-render empty flash. (rejected alternative)
- No new unit tests: no new testable pure logic (all view-layer); view-model coverage
  unchanged and ≥90%.

**Gotchas**:
- SourceKit reported false "cannot find type" errors module-wide mid-edit; build is clean.
- `xcodebuild test -derivedDataPath build/` fails CodeSign (iCloud `~/Documents` stamps
  fileprovider xattrs); use default DerivedData.

**Tests**: 268 pass, build zero warnings, all files <300 lines.

**Open**: swipe-height/freeze fix + edit flows need on-device confirmation (UI timing).

### Next up
- plan-0016 — Log-reminder local notifications
