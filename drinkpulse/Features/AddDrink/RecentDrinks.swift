import Foundation

/// A drink the user logged recently, offered at the top of the Add Drink list (D0047-4). It
/// repeats the drink (type, serving, strength, name), never the occasion (count, date, notes,
/// price).
struct RecentDrink: Hashable, Identifiable {
    let category: DrinkCategory
    let icon: String
    let volumeMl: Double
    let abv: Double
    let customName: String?

    var id: String {
        "\(category.rawValue)|\(volumeMl)|\(abv)|\(customName?.lowercased() ?? "")"
    }
}

enum RecentDrinks {
    /// The newest distinct drinks in `events`, which must be sorted newest first. Two events are
    /// the same drink when category, volume, ABV and trimmed custom name (ignoring case) match;
    /// the count is ignored.
    static func make(from events: [ConsumptionEvent], limit: Int = 3) -> [RecentDrink] {
        var seen = Set<String>()
        var result: [RecentDrink] = []
        for event in events {
            guard result.count < limit else { break }
            let drink = RecentDrink(
                category: event.category,
                icon: event.icon,
                volumeMl: event.volumeMl,
                abv: event.abv,
                customName: trimmedName(event.customName)
            )
            if seen.insert(drink.id).inserted {
                result.append(drink)
            }
        }
        return result
    }

    private static func trimmedName(_ name: String?) -> String? {
        guard let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }
}
