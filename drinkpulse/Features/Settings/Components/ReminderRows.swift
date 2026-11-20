import OSLog
import SwiftUI

/// Daily reminder rows inside `NotificationsSection`: toggle, time when on, Open Settings when
/// denied. The hint / denied line is the section footer, so `permissionDenied` is owned there.
struct ReminderRows: View {
    @AppStorage(AppStorageKeys.reminderEnabled) private var enabled = false
    @AppStorage(AppStorageKeys.reminderHour) private var hour = ReminderService.defaultHour
    @AppStorage(AppStorageKeys.reminderMinute) private var minute = ReminderService.defaultMinute
    @Binding var permissionDenied: Bool

    private let service = ReminderService()
    private let logger = Logger(subsystem: "com.drinkpulse.app", category: "ReminderSection")

    var body: some View {
        Toggle(String(localized: "settings.reminder.toggle"), isOn: toggleBinding)

        if enabled {
            DatePicker(
                String(localized: "settings.reminder.time"),
                selection: timeBinding,
                displayedComponents: .hourAndMinute
            )
        }

        if permissionDenied {
            OpenSettingsRow(title: String(localized: "settings.reminder.openSettings"))
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
    @Previewable @State var denied = true
    Form { ReminderRows(permissionDenied: $denied) }
}
