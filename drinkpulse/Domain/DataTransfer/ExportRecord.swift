import Foundation

struct ExportRecord: Codable {
    var timestamp: Date
    var volumeMl: Double
    var abv: Double
    var name: String
    var category: String
    var icon: String
    var customName: String?
    var notes: String?
    var price: Double?
}

extension ExportRecord {
    init(from event: ConsumptionEvent) {
        timestamp = event.timestamp
        volumeMl  = event.volumeMl
        abv       = event.abv
        name      = event.name
        category  = event.category.rawValue
        icon      = event.icon
        customName = event.customName
        notes     = event.notes
        price     = event.price
    }
}
