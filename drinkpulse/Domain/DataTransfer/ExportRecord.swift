import Foundation

nonisolated struct ExportRecord: Codable {
    var timestamp: Date
    var volumeMl: Double
    var abv: Double
    /// Number of single portions in this log. Absent in v1/v2 files written before
    /// plan-0025 → decodes to 1 (those files folded the count into `volumeMl`).
    var quantity: Int
    var name: String
    var category: String
    var icon: String
    var customName: String?
    var notes: String?
    var price: Double?

    private enum CodingKeys: String, CodingKey {
        case timestamp, volumeMl, abv, quantity, name, category, icon, customName, notes, price
    }

    init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        timestamp  = try c.decode(Date.self, forKey: .timestamp)
        volumeMl   = try c.decode(Double.self, forKey: .volumeMl)
        abv        = try c.decode(Double.self, forKey: .abv)
        quantity   = try c.decodeIfPresent(Int.self, forKey: .quantity) ?? 1
        name       = try c.decode(String.self, forKey: .name)
        category   = try c.decode(String.self, forKey: .category)
        icon       = try c.decode(String.self, forKey: .icon)
        customName = try c.decodeIfPresent(String.self, forKey: .customName)
        notes      = try c.decodeIfPresent(String.self, forKey: .notes)
        price      = try c.decodeIfPresent(Double.self, forKey: .price)
    }
}

extension ExportRecord {
    @MainActor
    init(from event: ConsumptionEvent) {
        timestamp  = event.timestamp
        volumeMl   = event.volumeMl
        abv        = event.abv
        quantity   = event.quantity
        name       = event.name
        category   = event.category.rawValue
        icon       = event.icon
        customName = event.customName
        notes      = event.notes
        price      = event.price
    }
}
