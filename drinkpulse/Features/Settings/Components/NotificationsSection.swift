import SwiftUI
import SwiftData

/// Daily reminder and weekly summary in one section (plan 0043 D0043-1). Owns both
/// `permissionDenied` flags so the footer can show each hint, or its denied message in red
/// (D0043-2).
struct NotificationsSection: View {
    @State private var reminderDenied = false
    @State private var weeklyDenied = false

    var body: some View {
        Section {
            ReminderRows(permissionDenied: $reminderDenied)
            WeeklySummaryRows(permissionDenied: $weeklyDenied)
        } header: {
            Text(String(localized: "settings.section.notifications"))
        } footer: {
            VStack(alignment: .leading, spacing: 6) {
                footerLine(denied: reminderDenied,
                           hint: "settings.reminder.hint", deniedKey: "settings.reminder.denied")
                footerLine(denied: weeklyDenied,
                           hint: "settings.weeklySummary.hint", deniedKey: "settings.weeklySummary.denied")
            }
        }
    }

    private func footerLine(denied: Bool, hint: String.LocalizationValue,
                            deniedKey: String.LocalizationValue) -> some View {
        Text(String(localized: denied ? deniedKey : hint))
            .foregroundStyle(denied ? Color.red : Color.secondary)
    }
}

#Preview {
    Form { NotificationsSection() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}
