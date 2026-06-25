import Foundation
import SwiftData

@Model
final class ConsumptionEvent {
    var timestamp: Date
    /// Volume of a **single** portion in millilitres. The number of portions logged
    /// in one entry lives in `quantity` — never fold the count into this value.
    var volumeMl: Double
    /// Plain fraction, e.g. 0.05 for 5% ABV.
    var abv: Double
    /// Number of identical single portions in this one log (e.g. "Bottle ×10").
    /// Defaulted so the SwiftData migration is lightweight on existing stores.
    var quantity: Int = 1

    /// The unit system in effect when this event was logged (provenance, "C′" /
    /// ADR-0007). Drives which serving *name* is shown — stable across later
    /// unit-mode switches. `volumeMl` stays the canonical truth; this never
    /// affects any calculation. Optional + default nil → additive SwiftData
    /// migration (legacy events decode nil and fall back to the current profile
    /// unit for naming). It is permanent provenance: never edited after log time.
    var enteredUnit: UnitSystem?

    // Deprecated: snapshot of template name. No longer used for display; derived via
    // displayName from category + volumeMl. Will be removed in plan-0023 (CloudKit migration).
    var name: String
    var category: DrinkCategory
    var icon: String

    var template: DrinkTemplate?

    var customName: String?
    var notes: String?
    var price: Double?
    /// ISO 4217 code the `price` was entered in (plan-0034). Persisted *with*
    /// the price so a stored amount is never reinterpreted when the user later
    /// changes their profile currency. Optional + default nil → additive
    /// SwiftData migration. nil means "unknown"; the display falls back to the
    /// profile currency. Never affects any calculation.
    var priceCurrency: String?

    /// Pure-alcohol mass (g) for a given density, counting every portion:
    /// `volumeMl × quantity × abv × density`. The display layer passes the active
    /// mode and guideline's `density(for:)`; physical figures (calories / BAC) pass 0.789.
    func alcoholGrams(density: Double) -> Double {
        volumeMl * Double(quantity) * abv * density
    }

    /// Physical pure-alcohol mass (scientific 0.789 density). Used for calories and
    /// future BAC — never shifts with the user's chosen display unit.
    var pureAlcoholGrams: Double {
        alcoholGrams(density: AlcoholUnit.physicalDensityGramsPerMl)
    }

    init(
        timestamp: Date = .now,
        volumeMl: Double,
        abv: Double,
        quantity: Int = 1,
        enteredUnit: UnitSystem? = nil,
        name: String,
        category: DrinkCategory,
        icon: String,
        template: DrinkTemplate? = nil,
        customName: String? = nil,
        notes: String? = nil,
        price: Double? = nil,
        priceCurrency: String? = nil
    ) {
        self.timestamp = timestamp
        self.volumeMl = volumeMl
        self.abv = abv
        self.quantity = quantity
        self.enteredUnit = enteredUnit
        self.name = name
        self.category = category
        self.icon = icon
        self.template = template
        self.customName = customName
        self.notes = notes
        self.price = price
        self.priceCurrency = priceCurrency
    }
}

extension ConsumptionEvent {
    /// A new event copying every field of this one, with only `timestamp` reset
    /// (defaults to `.now`). Used by the History "Duplicate" action for a fast
    /// re-log. The returned instance is unmanaged — the caller inserts it into a
    /// `ModelContext`. The `template` reference is preserved (same drink).
    func duplicated(timestamp: Date = .now) -> ConsumptionEvent {
        ConsumptionEvent(
            timestamp: timestamp,
            volumeMl: volumeMl,
            abv: abv,
            quantity: quantity,
            enteredUnit: enteredUnit,
            name: name,
            category: category,
            icon: icon,
            template: template,
            customName: customName,
            notes: notes,
            price: price,
            priceCurrency: priceCurrency
        )
    }
}

extension ConsumptionEvent {
    /// User-facing name, resolved for `unitSystem`. Appends "×N" when more than
    /// one portion was logged. `unitSystem` is the *current profile* unit; the
    /// actual naming unit is the event's `enteredUnit` provenance when present
    /// (plan-0031 / ADR-0007), so the name stays stable across unit-mode switches.
    func displayName(in unitSystem: UnitSystem) -> String {
        let base = baseName(in: unitSystem)
        return quantity > 1 ? "\(base) ×\(quantity)" : base
    }

    /// Name-resolution chain (plan-0031):
    /// 1. an explicit `customName` always wins;
    /// 2. else resolve against the category's preset options at this `volumeMl`,
    ///    naming in `enteredUnit` when set, otherwise the current profile unit;
    /// 3. no matching preset option (orphaned/dropped serving) → `formatVolume`.
    private func baseName(in unitSystem: UnitSystem) -> String {
        if let custom = customName?.trimmingCharacters(in: .whitespacesAndNewlines), !custom.isEmpty {
            return custom
        }
        let resolvedUnit = enteredUnit ?? unitSystem
        let preset = DrinkTypePreset.preset(for: category)
        if let match = preset.volumes.first(where: { abs($0.volumeMl - volumeMl) < 0.5 }) {
            let name = match.name(in: resolvedUnit).trimmingCharacters(in: .whitespaces)
            if !name.isEmpty {
                return name
            }
        }
        return resolvedUnit.formatVolume(volumeMl)
    }
}

extension ConsumptionEvent {
    static var previewBeer: ConsumptionEvent {
        ConsumptionEvent(volumeMl: 568, abv: 0.05, name: "Beer", category: .beer, icon: "🍺")
    }
    static var previewWine: ConsumptionEvent {
        let twoHoursAgo = Calendar.current.date(byAdding: .hour, value: -2, to: .now) ?? .now
        return ConsumptionEvent(timestamp: twoHoursAgo, volumeMl: 175, abv: 0.135,
                                name: "Wine", category: .wine, icon: "🍷")
    }
    static var previewSpirits: ConsumptionEvent {
        let priorEvening = Calendar.current.date(byAdding: .hour, value: -20, to: .now) ?? .now
        return ConsumptionEvent(timestamp: priorEvening, volumeMl: 50, abv: 0.40,
                                name: "Whisky", category: .spirits, icon: "🥃")
    }
}
