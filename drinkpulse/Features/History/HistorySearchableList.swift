import SwiftUI
import SwiftData

/// The History List segment with native search (plan 0045, D0045-7): `.searchable` drawer and
/// All / Named / Unnamed scopes shown on search presentation. While the filter is active it
/// shows `HistorySearchResultsQueryView`; otherwise the paginated list.
struct HistorySearchableList: View {
    @State private var searchText = ""
    @State private var scope: HistorySearchScope = .all

    let pageLimit: Int
    let vm: HistoryViewModel
    let profile: UserProfile?
    let onLoadMore: () -> Void

    var body: some View {
        HistorySearchContent(
            filter: HistorySearchFilter(text: searchText, scope: scope),
            scope: $scope,
            pageLimit: pageLimit,
            vm: vm,
            profile: profile,
            onLoadMore: onLoadMore
        )
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text(String(localized: "history.search.prompt"))
        )
        .searchScopes($scope, activation: .onSearchPresentation) {
            ForEach(HistorySearchScope.allCases) { Text($0.label).tag($0) }
        }
    }
}

/// Inside the searchable hierarchy, so it can read `isSearching` (SwiftUI "Managing search
/// interface activation") and reset the scope when search ends.
private struct HistorySearchContent: View {
    @Environment(\.isSearching) private var isSearching

    let filter: HistorySearchFilter
    @Binding var scope: HistorySearchScope
    let pageLimit: Int
    let vm: HistoryViewModel
    let profile: UserProfile?
    let onLoadMore: () -> Void

    var body: some View {
        Group {
            if filter.isActive {
                HistorySearchResultsQueryView(
                    filter: filter,
                    vm: vm,
                    profile: profile
                )
            } else {
                HistoryListQueryView(
                    pageLimit: pageLimit,
                    vm: vm,
                    profile: profile,
                    onLoadMore: onLoadMore
                )
            }
        }
        .onChange(of: isSearching) { _, searching in
            if !searching { scope = .all }
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
            pageLimit: HistoryViewModel.listPageSize, vm: HistoryViewModel(), profile: nil,
            onLoadMore: {}
        )
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }
    .modelContainer(HistorySearchPreviewData.container())
}
#endif
