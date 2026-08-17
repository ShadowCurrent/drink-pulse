import Foundation

@Observable @MainActor final class InsightsViewModel {
    var events: [ConsumptionEvent] = [] {
        didSet { rebuildGramsByDay() }
    }
    var profile: UserProfile? = nil {
        didSet { rebuildGramsByDay() }
    }
    var now: Date = .now
    var period: InsightsPeriod = .week

    var modeDensity: Double {
        (profile?.alcoholUnit ?? .standardDrinks).density(for: profile?.guidelineChoice ?? .who)
    }

    @ObservationIgnored private var gramsByDay: [Date: Double] = [:]

    private var cachedOldestEventDate: Date?

    private func rebuildGramsByDay() {
        let density = modeDensity
        var map: [Date: Double] = [:]
        map.reserveCapacity(events.count)
        var oldest = Date.distantFuture
        for e in events {
            map[cal.startOfDay(for: e.consumptionDate), default: 0] += e.alcoholGrams(density: density)
            if e.consumptionDate < oldest { oldest = e.consumptionDate }
        }
        gramsByDay = map
        cachedOldestEventDate = events.isEmpty ? nil : oldest
        cachedDaysRange = nil
    }

    private(set) var weekOffset: Int = 0
    private(set) var monthOffset: Int = 0
    private(set) var yearOffset: Int = 0

    // MARK: - Navigation

    var activeOffset: Int {
        switch period {
        case .week:    return weekOffset
        case .month:   return monthOffset
        case .year:    return yearOffset
        case .allTime: return 0
        }
    }

    var isAllTime: Bool { period == .allTime }

    var isCurrentPeriod: Bool { activeOffset == 0 }

    var oldestEventDate: Date? { cachedOldestEventDate }

    var minAllowedOffset: Int {
        guard let oldest = oldestEventDate else { return 0 }
        return period.offset(for: oldest, relativeTo: now, calendar: cal)
    }

    func navigatePrev() {
        guard !isAllTime else { return }
        let next = activeOffset - 1
        guard next >= minAllowedOffset else { return }
        setOffset(next)
    }

    func navigateNext() {
        guard !isAllTime, activeOffset < 0 else { return }
        setOffset(activeOffset + 1)
    }

    func jumpToNow() {
        guard !isAllTime else { return }
        setOffset(0)
    }

    private func setOffset(_ value: Int) {
        switch period {
        case .week:    weekOffset = value
        case .month:   monthOffset = value
        case .year:    yearOffset = value
        case .allTime: break
        }
    }

    // MARK: - Calendar

    var cal: Calendar { Calendar.current }

    // MARK: - Active date range

    var activeDateRange: ClosedRange<Date> {
        if isAllTime {
            let start = oldestEventDate.map { cal.startOfDay(for: $0) } ?? cal.startOfDay(for: now)
            return start...max(start, now)
        }
        return period.dateRange(offset: activeOffset, now: now, calendar: cal)
    }

    var friendlyLabel: String {
        if isAllTime { return String(localized: "insights.nav.allTime") }
        return period.friendlyLabel(offset: activeOffset, now: now, calendar: cal)
    }

    var rangeLabel: String {
        if isAllTime {
            let style = Date.FormatStyle.dateTime.month(.abbreviated).day().year()
            let r = activeDateRange
            return "\(r.lowerBound.formatted(style)) – \(r.upperBound.formatted(style))"
        }
        return period.rangeLabel(offset: activeOffset, now: now, calendar: cal)
    }

    // MARK: - Guideline helpers

    var sex: BiologicalSex { profile?.biologicalSex ?? .male }
    var guidelineChoice: GuidelineChoice { profile?.guidelineChoice ?? .who }

    func limits(for guideline: GuidelineChoice) -> GuidelineLimits {
        guideline.effectiveLimits(weeklyGoalGrams: profile?.weeklyGoalGrams ?? 100, for: sex)
    }

    var effectiveDailyLimitGrams: Double {
        limits(for: guidelineChoice).effectiveDailyGrams
    }

    // MARK: - Data source

    static var preview: InsightsViewModel {
        let vm = InsightsViewModel()
        vm.events = InsightsDataGenerator.previewEvents()
        vm.profile = UserProfile.preview
        return vm
    }

    func gramsForDay(_ date: Date) -> Double {
        gramsByDay[cal.startOfDay(for: date)] ?? 0
    }

    func gramsForNormalizedDay(_ day: Date) -> Double {
        gramsByDay[day] ?? 0
    }

    // MARK: - Period aggregates

    var effectiveDateRange: ClosedRange<Date> {
        let range = activeDateRange
        switch period {
        case .week, .month:
            return range
        case .year, .allTime:
            let end = min(range.upperBound, now)
            return range.lowerBound...max(range.lowerBound, end)
        }
    }

    @ObservationIgnored private var cachedDaysRange: ClosedRange<Date>?
    @ObservationIgnored private var cachedDays: [Date] = []

    var activeDays: [Date] {
        let range = effectiveDateRange
        if let key = cachedDaysRange, key == range { return cachedDays }
        let days = cal.days(in: range)
        cachedDaysRange = range
        cachedDays = days
        return days
    }

    var elapsedDays: [Date] {
        let today = cal.startOfDay(for: now)
        return activeDays.filter { $0 <= today }
    }

    var periodTotalGrams: Double {
        activeDays.reduce(0) { $0 + gramsForNormalizedDay($1) }
    }

    var prevPeriodTotalGrams: Double {
        guard !isAllTime else { return 0 }
        let prevRange = period.dateRange(offset: activeOffset - 1, now: now, calendar: cal)
        return cal.days(in: prevRange).reduce(0) { $0 + gramsForNormalizedDay($1) }
    }

    var trendFraction: Double {
        guard prevPeriodTotalGrams > 0 else { return 0 }
        return (periodTotalGrams - prevPeriodTotalGrams) / prevPeriodTotalGrams
    }

    // MARK: - Risk level

    func riskLevel(for grams: Double) -> RiskLevel {
        guard effectiveDailyLimitGrams > 0 else { return .safe }
        return RiskLevel.from(pct: grams / effectiveDailyLimitGrams)
    }

    // MARK: - Guideline comparisons

    private func effectiveDailyLimit(for guideline: GuidelineChoice) -> Double {
        limits(for: guideline).effectiveDailyGrams
    }

    var guidelineComparisons: [GuidelineComparison] {
        let consumed = periodTotalGrams
        let days = Double(activeDays.count)
        return [GuidelineChoice.who, .uk, .de].map { guideline in
            GuidelineComparison(
                guideline: guideline,
                name: guidelineShortName(guideline),
                consumedGrams: consumed,
                limitGrams: effectiveDailyLimit(for: guideline) * days
            )
        }
    }

}
