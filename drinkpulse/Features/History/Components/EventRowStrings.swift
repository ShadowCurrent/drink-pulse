import Foundation

/// Every string a History row renders, computed once.
///
/// `EventRow` previously derived the same six values twice per body pass: once for
/// the visible fields and again inside its accessibility label, which — being a plain
/// computed property — was evaluated eagerly on every body pass whether or not
/// VoiceOver was running. Deriving both from one pass halves the per-row formatting
/// work and makes it impossible for the spoken text and the visible text to disagree
/// after a formatting change. Being a value type, it is also unit-testable without a
/// view. Finding A4-1.
struct EventRowStrings: Equatable {
    let name: String
    let subtitle: String
    let amount: String
    let unitLabel: String
    let accessibilityLabel: String

    init(event: ConsumptionEvent, unitContext: RowUnitContext) {
        // Each underlying value is computed exactly once here, then reused by both
        // the visible strings and the spoken label below.
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
        // The row shows a note as a small glyph, which is hidden from VoiceOver
        // because a lone symbol reads as noise. Announcing its EXISTENCE here is
        // what makes the note discoverable without sight; the note's CONTENT is
        // deliberately never spoken (it is personal health data — see the phase
        // threat register, T-07-14). A cleared note is stored as "" rather than
        // nil, so both must read as "no note". Finding C14-5.
        if event.notes?.isEmpty == false {
            self.accessibilityLabel = "\(spoken), \(String(localized: "history.row.hasNote"))"
        } else {
            self.accessibilityLabel = spoken
        }
    }
}
