import Foundation
import Observation

enum OwnedNFTSortOption: CaseIterable {
    case price
    case rating
    case name
}

@MainActor
@Observable
final class OwnedNFTsViewModel {
    private var sourceItems: [OwnedNFT]
    private(set) var selectedSortOption: OwnedNFTSortOption?
    var isSortMenuPresented = false

    var items: [OwnedNFT] {
        guard let selectedSortOption else { return sourceItems }
        return sourceItems.sorted { first, second in
            switch selectedSortOption {
            case .price:
                return first.price < second.price
            case .rating:
                return first.rating > second.rating
            case .name:
                return first.name.localizedStandardCompare(second.name) == .orderedAscending
            }
        }
    }

    var isEmpty: Bool { sourceItems.isEmpty }

    init(items: [OwnedNFT]) {
        self.sourceItems = items
    }

    func updateItems(_ items: [OwnedNFT]) {
        sourceItems = items
    }

    func selectSortOption(_ option: OwnedNFTSortOption) {
        selectedSortOption = option
        closeSortMenu()
    }

    func closeSortMenu() {
        isSortMenuPresented = false
    }
}
