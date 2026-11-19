import SwiftUI
import SwiftData

/// The History List segment with a native search field and
/// All / Named / Unnamed scopes. While the filter is active it shows
/// `HistorySearchResultsQueryView`; otherwise the paginated list.
struct HistorySearchableList: View {
    @State private var searchText = ""
    @State private var scope: HistorySearchScope = .all
    @State private var isSearchPresented = false

    let windowStart: Date
    let hasMore: Bool
    let vm: HistoryViewModel
    let profile: UserProfile?
    let onLoadMore: () -> Void
    let onEditEvent: (ConsumptionEvent) -> Void

    private var filter: HistorySearchFilter {
        HistorySearchFilter(text: searchText, scope: scope)
    }

    var body: some View {
        Group {
            if filter.isActive {
                HistorySearchResultsQueryView(
                    filter: filter,
                    vm: vm,
                    profile: profile,
                    onEditEvent: onEditEvent
                )
            } else {
                HistoryListQueryView(
                    windowStart: windowStart,
                    hasMore: hasMore,
                    vm: vm,
                    profile: profile,
                    onLoadMore: onLoadMore,
                    onEditEvent: onEditEvent
                )
            }
        }
        .searchable(
            text: $searchText,
            isPresented: $isSearchPresented,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "history.search.prompt")
        )
        .searchScopes($scope, activation: .onSearchPresentation) {
            ForEach(HistorySearchScope.allCases) { scope in
                Text(scope.label).tag(scope)
            }
        }
        .onChange(of: isSearchPresented) { _, presented in
            if !presented { scope = .all }
        }
    }
}

#if DEBUG
/// In-memory sample data for the History search previews (Debug only).
enum HistorySearchPreviewData {
    @MainActor
    static func container() -> ModelContainer {
        let container = try! ModelContainer(
            for: ConsumptionEvent.self, DrinkTemplate.self, UserProfile.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let old = Calendar.current.date(byAdding: .day, value: -200, to: .now) ?? .now
        let seeds: [(String?, Date, Double)] = [
            ("Guinness", .now, 500), ("Tyskie", old, 500), (nil, .now, 330)
        ]
        for (name, date, volume) in seeds {
            container.mainContext.insert(ConsumptionEvent(
                consumptionDate: date, volumeMl: volume, abv: 0.05,
                category: .beer, icon: "🍺", customName: name
            ))
        }
        return container
    }
}

#Preview {
    NavigationStack {
        HistorySearchableList(
            windowStart: Calendar.current.date(byAdding: .day, value: -90, to: .now) ?? .now,
            hasMore: true, vm: HistoryViewModel(), profile: nil,
            onLoadMore: {}, onEditEvent: { _ in }
        )
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(HistorySearchPreviewData.container())
}
#endif
