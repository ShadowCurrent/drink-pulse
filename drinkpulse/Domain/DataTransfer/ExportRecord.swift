import Foundation

nonisolated struct ExportRecord: Codable {
    var timestamp: Date
    var volumeMl: Double
    var abv: Double
    /// Number of single portions in this log. Absent in v1/v2 files written before
    /// plan-0025 → decodes to 1 (those files folded the count into `volumeMl`).
    var quantity: Int
    /// Unit-system provenance (plan-0031 / ADR-0007). Raw `UnitSystem` value, or
    /// nil. Absent in backups written before plan-0031 → decodes to nil (naming
    /// falls back to the current profile unit). Back-compatible, optional key.
    var enteredUnit: String?
    var name: String
    var category: String
    var icon: String
    var customName: String?
    var notes: String?
    var price: Double?
    /// ISO 4217 code the price was entered in (plan-0034). Absent in backups
    /// written before plan-0034 → decodes to nil (display falls back to the
    /// profile currency). Back-compatible, optional key.
    var priceCurrency: String?

    private enum CodingKeys: String, CodingKey {
        case timestamp, volumeMl, abv, quantity, enteredUnit, name, category, icon
        case customName, notes, price, priceCurrency
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp   = try c.decode(Date.self, forKey: .timestamp)
        volumeMl    = try c.decode(Double.self, forKey: .volumeMl)
        abv         = try c.decode(Double.self, forKey: .abv)
        quantity    = try c.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        enteredUnit = try c.decodeIfPresent(String.self, forKey: .enteredUnit)
        name        = try c.decode(String.self, forKey: .name)
        category    = try c.decode(String.self, forKey: .category)
        icon        = try c.decode(String.self, forKey: .icon)
        customName  = try c.decodeIfPresent(String.self, forKey: .customName)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes)
        price       = try c.decodeIfPresent(Double.self, forKey: .price)
        priceCurrency = try c.decodeIfPresent(String.self, forKey: .priceCurrency)
    }
}

extension ExportRecord {
    @MainActor
    init(from event: ConsumptionEvent) {
        timestamp   = event.timestamp
        volumeMl    = event.volumeMl
        abv         = event.abv
        quantity    = event.quantity
        enteredUnit = event.enteredUnit?.rawValue
        name        = event.name
        category   = event.category.rawValue
        icon       = event.icon
        customName = event.customName
        notes      = event.notes
        price      = event.price
        priceCurrency = event.priceCurrency
    }
}
