import SwiftUI
import SwiftData

extension EditEventView {
    static func volumeToPersist(selected: Double, original: Double) -> Double {
        selected != original ? selected : original
    }

    private var parsedPrice: Double? {
        let normalized = priceText.replacingOccurrences(of: ",", with: ".")
        return Double(normalized)
    }

    func save() {
        event.category  = category
        event.icon      = icon
        event.volumeMl  = Self.volumeToPersist(selected: volumeMl, original: originalVolumeMl)
        event.quantity  = count
        event.abv       = abvValue
        event.consumptionDate = date
        event.price     = parsedPrice
        event.priceCurrency = parsedPrice == nil ? nil : priceCurrency
        let trimmedCustomName = customNameText.trimmingCharacters(in: .whitespacesAndNewlines)
        event.customName = trimmedCustomName.isEmpty ? nil : trimmedCustomName
        let trimmedNotes = notesText.trimmingCharacters(in: .whitespacesAndNewlines)
        event.notes     = trimmedNotes.isEmpty ? nil : trimmedNotes
        event.touch()
        HealthWriteHooks.update(event, in: modelContext, using: healthService)
        dismiss()
    }

    /// Logs the stored drink again; unsaved edits on the form are discarded (D0047-9).
    func logAgain() {
        EventActions.logAgain(
            event, in: modelContext, healthService: healthService,
            reduceMotion: reduceMotion, drinkLogged: drinkLogged
        )
        dismiss()
    }

    func deleteEvent() {
        dismiss()
        EventActions.delete(event, in: modelContext, healthService: healthService, reduceMotion: reduceMotion)
    }
}
