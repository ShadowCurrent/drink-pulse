import SwiftUI
import SwiftData

#Preview("With data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    let cal = Calendar.current
    let now = Date.now

    // Today
    ctx.insert(ConsumptionEvent(timestamp: now, volumeMl: 568, abv: 0.05,
                                category: .beer, icon: "🍺"))
    ctx.insert(ConsumptionEvent(timestamp: now.addingTimeInterval(-3600), volumeMl: 175, abv: 0.135,
                                category: .wine, icon: "🍷", price: 8.50))

    // Earlier this week
    let minus2 = cal.date(byAdding: .day, value: -2, to: now)!
    ctx.insert(ConsumptionEvent(timestamp: minus2, volumeMl: 330, abv: 0.05,
                                category: .beer, icon: "🍺", price: 4.00))
    let minus4 = cal.date(byAdding: .day, value: -4, to: now)!
    ctx.insert(ConsumptionEvent(timestamp: minus4, volumeMl: 250, abv: 0.12,
                                category: .wine, icon: "🍷"))

    ctx.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}

#Preview("Empty") {
    NavigationStack { DashboardView() }
        .modelContainer(
            for: [ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self],
            inMemory: true
        )
}

#Preview("Over limit") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
        configurations: config
    )
    let ctx = container.mainContext
    // WHO male weekly limit = 140 g. Insert 125 g today (over the 20 g daily).
    ctx.insert(ConsumptionEvent(timestamp: .now, volumeMl: 1562, abv: 0.10,
                                category: .spirits, icon: "🥃"))
    ctx.insert(UserProfile.preview)
    return NavigationStack { DashboardView() }
        .modelContainer(container)
}
