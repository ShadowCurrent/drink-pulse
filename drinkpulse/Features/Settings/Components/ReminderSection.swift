import OSLog
import SwiftUI

/// Settings → Reminders card (plan-0016). An opt-in daily local notification
/// that prompts the user to log their drinks. Off by default; toggling on
/// triggers the authorization request. The time row appears only when enabled.
///
/// Matches the current Settings design (a `SettingsSection` glass card of
/// `SettingsRow`s), introduced in plan-0027.
struct ReminderSection: View {
    @AppStorage(AppStorageKeys.reminderEnabled) private var enabled = false
    @AppStorage(AppStorageKeys.reminderHour) private var hour = ReminderService.defaultHour
    @AppStorage(AppStorageKeys.reminderMinute) private var minute = ReminderService.defaultMinute
    @State private var permissionDenied = false

    private let service = ReminderService()
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "ReminderSection")

    var body: some View {
        SettingsSection("settings.section.reminders") {
            SettingsRow(String(localized: "settings.reminder.toggle")) {
                Toggle(isOn: toggleBinding) {
                    Text(String(localized: "settings.reminder.toggle"))
                }
                .labelsHidden()
                .accessibilityLabel(String(localized: "settings.reminder.toggle"))
            }

            if enabled {
                Divider()
                SettingsRow(String(localized: "settings.reminder.time")) {
                    DatePicker(
                        String(localized: "settings.reminder.time"),
                        selection: timeBinding,
                        displayedComponents: .hourAndMinute
                    )
                    .labelsHidden()
                }
            }

            Divider()
            Text(String(localized: permissionDenied ? "settings.reminder.denied" : "settings.reminder.hint"))
                .font(.footnote)
                .foregroundStyle(permissionDenied ? Color.red : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 10)

            if permissionDenied {
                Divider()
                SettingsActionRow(
                    title: String(localized: "settings.reminder.openSettings"),
                    systemImage: "gearshape",
                    trailingSystemImage: "arrow.up.right.square"
                ) {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        }
    }

    // MARK: - Bindings

    private var toggleBinding: Binding<Bool> {
        Binding(
            get: { enabled },
            set: { newValue in
                if newValue {
                    Task { await enable() }
                } else {
                    enabled = false
                    permissionDenied = false
                    Task { await service.cancel() }
                }
            }
        )
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = hour
                components.minute = minute
                return Calendar.current.date(from: components) ?? .now
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                hour = components.hour ?? ReminderService.defaultHour
                minute = components.minute ?? ReminderService.defaultMinute
                Task { await reschedule() }
            }
        )
    }

    // MARK: - Actions

    private func enable() async {
        do {
            let granted = try await service.requestAuthorization()
            guard granted else {
                enabled = false
                permissionDenied = true
                return
            }
            permissionDenied = false
            enabled = true
            try await service.schedule(hour: hour, minute: minute)
        } catch {
            enabled = false
            permissionDenied = true
            logger.error("Reminder enable failed: \(error.localizedDescription)")
        }
    }

    private func reschedule() async {
        do {
            try await service.schedule(hour: hour, minute: minute)
        } catch {
            logger.error("Reminder reschedule failed: \(error.localizedDescription)")
        }
    }
}

#Preview {
    ScrollView {
        VStack(spacing: 20) {
            ReminderSection()
        }
        .padding()
    }
    .background(Color.dpAccent.opacity(0.04))
}
