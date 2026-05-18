# Plan: Dashboard Redesign

Source design: React/Tailwind sketch from Figma (provided 2026-05-18).
Status: **Ready to implement** — pending 4 decisions listed at the bottom.

---

## Zakres zmian

Nowy dashboard to kompletna wymiana `DashboardView`. Trzy ringi znikają.
Nowa struktura to 5 sekcji: header, metryki (2×2), weekly goal, streak/sober days, guideline alert.
Logika obliczeniowa przechodzi do `DashboardViewModel` (testowalność per CLAUDE.md).
Hydration reminder zignorowany (nie budujemy).

---

## Krok 1 — Color tokens (`DesignSystem/DPColors.swift`)

Semantyczne rozszerzenia na `Color`. Tła kart = systemowe adaptive colors (light/dark automatycznie).
Akcenty = stałe hex (te same w obu trybach).

```swift
extension Color {
    // Adaptive — działają w light i dark automatycznie
    static var dpCardBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var dpCardBorder:     Color { Color(.separator).opacity(0.5) }

    // Akcenty (stałe w obu trybach)
    static let dpTeal   = Color(hex: "#14B8A6")
    static let dpAmber  = Color(hex: "#F59E0B")
    static let dpRed    = Color(hex: "#EF4444")
    static let dpPurple = Color(hex: "#C084FC")
    static let dpGreen  = Color(hex: "#10B981")
}
```

Zewnętrzny `ScrollView` dostaje `Color(.systemGroupedBackground)`.
Kolory tła kart do korekty przez właściciela gdy projekt designu dojrzeje.

---

## Krok 2 — `DashboardViewModel` (`Features/Dashboard/DashboardViewModel.swift`)

`@Observable` class. Widok przekazuje eventy + profil, VM liczy.

### Computed properties

| Property | Nowa? | Logika |
|----------|-------|--------|
| `todayGrams: Double` | przeniesiona | filter `≥ startOfDay(now)` |
| `weeklyGrams: Double` | przeniesiona | filter `≥ 7 days ago` |
| `todayCaloriesKcal: Int` | nowa | `todayGrams × 7.1` (1 g etanolu = 7.1 kcal) |
| `todayDrinkCount: Int` | nowa | `.count` eventów today |
| `todaySpend: Double?` | nowa | suma `price` today; `nil` gdy żaden event nie ma ceny |
| `weekBarData: [WeekBarEntry]` | nowa | 7 dni bieżącego tygodnia Mon–Sun |
| `currentStreakDays: Int` | nowa | konsekutywne dni BEZ alkoholu wstecz od wczoraj |
| `soberDaysThisMonth: Int` | nowa | dni bez alkoholu w bieżącym miesiącu |
| `soberDaysThisMonthDates: [Date]` | nowa | dla podnagłówka "May 5, 9, 15" |
| `riskLevel: RiskLevel` | nowa | `< 0.5` → .safe · `< 1.0` → .caution · `≥ 1.0` → .exceeded |
| `weeklyPct: Double` | nowa | `weeklyGrams / weeklyLimit` |
| `greetingText: String` | nowa | "Good morning/afternoon/evening" (bez imienia — patrz Q1) |

### WeekBarEntry

```swift
struct WeekBarEntry: Identifiable {
    var id: Date { day }
    let day: Date
    let label: String   // "Mon", "Tue", …
    let grams: Double
    let isToday: Bool
    let isFuture: Bool
}
```

### Kolor słupka (obliczany w VM)

- `isToday` → `.dpTeal`
- `isFuture` → `Color(.quinarySystemFill)` (ghost)
- przeszły, `grams > dailyLimit` → `.dpAmber`
- przeszły, `grams ≤ dailyLimit` → `Color(.tertiarySystemFill)`

---

## Krok 3 — Subcomponents (private structs w `DashboardView.swift`)

| Komponent | Opis |
|-----------|------|
| `RiskBadge(level: RiskLevel)` | Pill: kolorowy kropek + tekst "SAFE" / "CAUTION" / "EXCEEDED" |
| `MetricCard(label:value:unit:icon:color:)` | Jedna karta z siatki 2×2 |
| `WeeklyGoalCard(vm:)` | Ring + Swift Charts `BarChart` obok siebie |
| `WeeklyGoalRing` | Wrapper na istniejący `IntakeRing` — inna wielkość, center tekst "203% / of limit" |
| `StreakCard(title:icon:value:unit:subtitle:color:)` | Karta dla streak i sober days |
| `GuidelineAlertCard(vm:onTap:)` | Czerwona karta z `ChevronRight` |

Istniejący `IntakeRing` — **zachowany bez zmian** (używany przez `WeeklyGoalRing`).

---

## Krok 4 — Layout `DashboardView`

```
ScrollView {
    VStack(spacing: 16) {
        HeaderSection           // date string + greetingText + RiskBadge
        MetricsGrid             // LazyVGrid(columns: 2) z MetricCard ×4
        WeeklyGoalCard          // ring left + bar chart right
        HStack { StreakCard; StreakCard }   // current streak | sober days this month
        GuidelineAlertCard      // widoczna tylko gdy weeklyPct > 0.5
    }
    .padding(.horizontal)
}
.background(Color(.systemGroupedBackground))
```

Toolbar `+` button bez zmian. `import Charts` dodany.

### Metryki (4 karty)

| Label | Value | Unit | Icon | Color |
|-------|-------|------|------|-------|
| Today's Alcohol | `todayGrams` formatted | g / units (wg ustawień) | drop.fill | `.dpTeal` |
| Calories | `todayCaloriesKcal` | kcal | flame.fill | `.dpAmber` |
| Drinks Today | `todayDrinkCount` | drinks | bolt.fill | `.dpPurple` |
| Today's Spend | `todaySpend` | waluta (Q4) | chart.line.uptrend | `.dpGreen` |

---

## Krok 5 — Testy (`drinkpulseTests/DashboardViewModelTests.swift`)

- `todayCaloriesKcal` — 20 g → 142 kcal
- `weekBarData` — 7 wpisów, `isToday` i `isFuture` poprawne
- `riskLevel` — progi < 0.5, < 1.0, ≥ 1.0
- `currentStreakDays` — 0 jeśli dziś pito; N jeśli N dni bez alkoholu
- `soberDaysThisMonth` — poprawne zliczanie dla miesiąca z różnymi danymi

---

## Pliki

| Plik | Akcja |
|------|-------|
| `DesignSystem/DPColors.swift` | Nowy |
| `Features/Dashboard/DashboardViewModel.swift` | Nowy |
| `Features/Dashboard/DashboardView.swift` | Pełny rewrite |
| `drinkpulseTests/DashboardViewModelTests.swift` | Nowy |
| `docs/DEVLOG.md` | Append |
| `docs/roadmap.md` | Dashboard expansion → 🔄 |

Brak zmian w SwiftData schema — kalorie i spend są wartościami derived.

---

## Otwarte pytania (wymagają decyzji przed implementacją)

### Q1 — Imię w nagłówku
`UserProfile` nie ma pola `name`. Opcje:
- **A** — bez imienia: "Good evening" *(domyślne jeśli brak decyzji)*
- **B** — dodać `var displayName: String?` do modelu (lightweight migration, nil = brak imienia)
- **C** — placeholder na razie, pole dodane później

### Q2 — Tap na guideline alert card
Co otwiera tapnięcie?
- **A** — zakładka Settings *(domyślne)*
- **B** — bezpośrednio sheet z wyborem guideline
- **C** — na razie brak akcji (`.disabled(true)`)

### Q3 — Spend card gdy brak cen
Jeśli żaden event today nie ma `price`:
- **A** — ukryj kartę (zastąp czymś innym lub pokaż 3 karty) *(domyślne)*
- **B** — pokaż "—" jako wartość
- **C** — pokaż "0.00"

### Q4 — Symbol waluty
`UserProfile.currency` to String "USD" / "EUR" / itd.
- **A** — użyj jako prefix tekstu: `"USD 13.50"` *(domyślne)*
- **B** — sformatuj przez `Locale` / `NumberFormatter` z symbolem `$` / `€`
- **C** — na razie hardcode `"€"` (wymaga korekty)

---

*Implementacja: wróć do tego pliku i zaimplementuj po podjęciu decyzji.*
