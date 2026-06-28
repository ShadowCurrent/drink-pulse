import SwiftUI

struct EventRow: View {
    let event: ConsumptionEvent
    let profile: UserProfile?

    private var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .standardDrinks }
    private var guideline: GuidelineChoice { profile?.guidelineChoice ?? .who }
    private var unitSystem: UnitSystem { profile?.unitSystem ?? .metric }

    // Mass in the user's display unit (density per the chosen mode and guideline), counting quantity.
    private var massGrams: Double { event.alcoholGrams(density: alcoholUnit.density(for: guideline)) }

    var body: some View {
        HStack(spacing: 12) {
            Text(event.icon)
                .font(.title2)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(event.displayName(in: unitSystem))
                        .font(.body)
                    if event.notes?.isEmpty == false {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                Text(subtitleText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(alcoholUnit.formattedValue(massGrams, guideline: guideline))
                    .monospacedDigit()
                    .font(.body.weight(.medium))
                Text(alcoholUnit.unitLabel(for: guideline))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var subtitleText: String {
        let vol = unitSystem.formatVolume(event.volumeMl)
        let abv = String(format: "%.1f%%", event.abv * 100)
        let time = event.consumptionDate.formatted(.dateTime.hour().minute())
        return "\(vol) · \(abv) · \(time)"
    }

    private var accessibilityLabel: String {
        let amount = alcoholUnit.formattedValue(massGrams, guideline: guideline)
        return String(format: "%@, %@, %.1f percent ABV, %@ %@, logged at %@",
                      event.displayName(in: unitSystem),
                      unitSystem.formatVolume(event.volumeMl),
                      event.abv * 100,
                      amount,
                      alcoholUnit.unitLabel(for: guideline),
                      event.consumptionDate.formatted(.dateTime.hour().minute()))
    }
}

#Preview {
    List {
        EventRow(event: .previewBeer, profile: .preview)
        EventRow(event: .previewWine, profile: .preview)
        EventRow(event: .previewSpirits, profile: nil)
    }
}
