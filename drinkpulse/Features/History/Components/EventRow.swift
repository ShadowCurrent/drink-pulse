import SwiftUI

struct EventRow: View {
    let event: ConsumptionEvent
    let profile: UserProfile?

    private var alcoholUnit: AlcoholUnit { profile?.alcoholUnit ?? .units }
    private var guideline: GuidelineChoice { profile?.guidelineChoice ?? .who }

    // Mass in the user's display unit (density per the chosen unit), counting quantity.
    private var massGrams: Double { event.alcoholGrams(density: alcoholUnit.densityGramsPerMl) }

    var body: some View {
        HStack(spacing: 12) {
            Text(event.icon)
                .font(.title2)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(event.displayName)
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
                Text(alcoholUnit.unitLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var subtitleText: String {
        let vol = String(format: "%.0f ml", event.volumeMl)
        let abv = String(format: "%.1f%%", event.abv * 100)
        let time = event.timestamp.formatted(.dateTime.hour().minute())
        return "\(vol) · \(abv) · \(time)"
    }

    private var accessibilityLabel: String {
        let amount = alcoholUnit.formattedValue(massGrams, guideline: guideline)
        return String(format: "%@, %.0f millilitres, %.1f percent ABV, %@ %@, logged at %@",
                      event.displayName,
                      event.volumeMl,
                      event.abv * 100,
                      amount,
                      alcoholUnit.unitLabel,
                      event.timestamp.formatted(.dateTime.hour().minute()))
    }
}
