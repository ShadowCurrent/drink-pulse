import Foundation
import Testing
@testable import drinkpulse

/// Unit coverage for `HealthStep`'s weekly-summary toggle-off path (tech-debt
/// item 2, v1.1 audit / D-02, D-03). Reuses `FakeNotificationCenter` (declared
/// in `ReminderServiceTests.swift`) rather than inventing a new mock — mirrors
/// `WeeklySummaryServiceTests.cancel_removesPendingWeeklySummaryRequest`'s
/// assertion shape exactly.
@MainActor
struct HealthStepTests {

    @Test func disableWeeklySummary_callsServiceCancel() async {
        let fake = FakeNotificationCenter()
        let service = WeeklySummaryService(center: fake, defaults: UserDefaults(suiteName: "test.healthStep.\(UUID().uuidString)")!)
        let step = HealthStep(onDone: {}, weeklySummaryService: service)

        await step.disableWeeklySummary()

        #expect(fake.removedBatches.last == [WeeklySummaryService.weeklySummaryIdentifier])
    }
}
