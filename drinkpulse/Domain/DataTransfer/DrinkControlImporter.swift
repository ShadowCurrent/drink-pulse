import Foundation
import SwiftData

struct DrinkControlImporter {

    // Returns the number of data rows (excluding header) without side effects.
    func previewCount(_ csvString: String) -> Int {
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return max(0, lines.count - 1)
    }

    @MainActor
    func importCSV(_ csvString: String, into context: ModelContext) -> ImportResult {
        let lines = csvString.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        guard lines.count > 1 else {
            return ImportResult(imported: 0, skipped: 0, failed: 0, errors: [])
        }

        let existing = (try? context.fetch(FetchDescriptor<ConsumptionEvent>())) ?? []
        let formatter = Self.makeDateFormatter()

        var imported = 0, skipped = 0, failed = 0
        var errors: [String] = []

        for (idx, line) in lines.dropFirst().enumerated() {
            do {
                let event = try parseLine(line, formatter: formatter)
                if DataImporter.isDuplicate(event.timestamp, volumeMl: event.volumeMl,
                                            abv: event.abv, in: existing) {
                    skipped += 1
                } else {
                    context.insert(event)
                    imported += 1
                }
            } catch {
                failed += 1
                errors.append("Row \(idx + 2): \(error.localizedDescription)")
            }
        }

        return ImportResult(imported: imported, skipped: skipped, failed: failed, errors: errors)
    }

    // MARK: - Parsing

    private func parseLine(_ line: String, formatter: DateFormatter) throws -> ConsumptionEvent {
        let fields = line.components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "\" ")) }

        guard fields.count >= 7 else { throw ParseError.insufficientFields }

        // Columns: AccountedForDate ; RegisteredDate ; Name ; Serving ;
        //          DrinkSizeInMl ; AlcoholVolumePercentage ; NumberOfDrinks ; ...
        guard let timestamp = formatter.date(from: fields[1])
                           ?? formatter.date(from: fields[0]) else {
            throw ParseError.invalidDate(fields[1])
        }
        let categoryName = fields[2].lowercased()
        guard let sizeInMl = Double(fields[4]) else { throw ParseError.invalidNumber("DrinkSizeInMl") }
        guard let abv      = Double(fields[5]) else { throw ParseError.invalidNumber("ABV") }
        guard let count    = Int(fields[6]), count >= 1 else { throw ParseError.invalidNumber("NumberOfDrinks") }

        let (category, baseName, icon) = Self.mapCategory(categoryName)
        let totalVolumeMl = sizeInMl * Double(count)

        return ConsumptionEvent(
            timestamp: timestamp,
            volumeMl:  totalVolumeMl,
            abv:       abv,
            name:      baseName,
            category:  category,
            icon:      icon
        )
    }

    // MARK: - Category mapping

    private static func mapCategory(_ name: String) -> (DrinkCategory, String, String) {
        switch name {
        case "beer":                                        return (.beer,      "Beer",      "🍺")
        case "wine":                                        return (.wine,      "Wine",      "🍷")
        case "champagne":                                   return (.champagne, "Champagne", "🥂")
        case "spirits":                                     return (.spirits,   "Spirits",   "🥃")
        case "vodka", "whisky", "whiskey", "rum",
             "gin", "tequila", "brandy", "liqueur":         return (.spirits,   "Spirits",   "🥃")
        case "cocktail":                                    return (.cocktail,  "Cocktail",  "🍹")
        case "cider":                                       return (.cider,     "Cider",     "🍺")
        default:                                            return (.custom,    "Other",     "🥤")
        }
    }

    // MARK: - Helpers

    private static func makeDateFormatter() -> DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }

    enum ParseError: LocalizedError {
        case insufficientFields
        case invalidDate(String)
        case invalidNumber(String)

        var errorDescription: String? {
            switch self {
            case .insufficientFields:    return "Not enough fields"
            case .invalidDate(let v):    return "Invalid date: \(v)"
            case .invalidNumber(let f):  return "Invalid number in field '\(f)'"
            }
        }
    }
}
