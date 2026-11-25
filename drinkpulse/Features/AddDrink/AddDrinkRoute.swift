import Foundation

/// What Add Drink step 1 pushes: a preset with its defaults, or a Recent drink (D0047-4).
enum AddDrinkRoute: Hashable {
    case preset(DrinkCategory)
    case recent(RecentDrink)
}

/// The serving, strength and name a Recent drink pre-fills on step 2. Count, date, notes and
/// price are not carried: Recent repeats the drink, not the occasion.
struct DrinkPrefill: Equatable {
    let volumeMl: Double
    let abv: Double
    let customName: String?

    init(volumeMl: Double, abv: Double, customName: String?) {
        self.volumeMl = volumeMl
        self.abv = abv
        self.customName = customName
    }

    init(_ drink: RecentDrink) {
        self.init(volumeMl: drink.volumeMl, abv: drink.abv, customName: drink.customName)
    }
}
