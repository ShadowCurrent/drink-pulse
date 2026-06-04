import Foundation

enum DrinkCategory: String, Codable, CaseIterable, Sendable {
    case beer, wine, champagne, spirits, cocktail, cider, alcopop, fortifiedWine, hotDrink
    case brandy, cognac, vodka, whiskey, tequila, shot, liqueur
    case custom
}
