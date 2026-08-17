import Foundation

struct EventRowStrings: Equatable {
    let name: String
    let subtitle: String
    let amount: String
    let unitLabel: String
    let accessibilityLabel: String

    init(event: ConsumptionEvent, unitContext: RowUnitContext) {
        let name = event.displayName(in: unitContext.unitSystem)
        let volumeText = unitContext.unitSystem.formatVolume(event.volumeMl)
        let abvPercent = event.abv * 100
        let timeText = event.consumptionDate.formatted(.dateTime.hour().minute())
        let massGrams = event.alcoholGrams(density: unitContext.density)
        let amount = unitContext.alcoholUnit.formattedValue(massGrams, guideline: unitContext.guideline)
        let unitLabel = unitContext.alcoholUnit.unitLabel(for: unitContext.guideline)

        self.name = name
        self.subtitle = "\(volumeText) · \(String(format: "%.1f%%", abvPercent)) · \(timeText)"
        self.amount = amount
        self.unitLabel = unitLabel

        let spoken = String(
            format: "%@, %@, %.1f percent ABV, %@ %@, logged at %@",
            name, volumeText, abvPercent, amount, unitLabel, timeText
        )
        if event.notes?.isEmpty == false {
            self.accessibilityLabel = "\(spoken), \(String(localized: "history.row.hasNote"))"
        } else {
            self.accessibilityLabel = spoken
        }
    }
}
