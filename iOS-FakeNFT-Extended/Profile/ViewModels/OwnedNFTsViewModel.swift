import Foundation
import Observation

@MainActor
@Observable
final class OwnedNFTsViewModel {
    private let settingsService: UserSettingsServiceProtocol
    private var sourceItems: [OwnedNFT]
    private(set) var selectedSortOption: OwnedNFTSortOption
    var isSortMenuPresented = false

    var items: [OwnedNFT] {
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

    init(items: [OwnedNFT], settingsService: UserSettingsServiceProtocol = UserSettingsService()) {
        self.settingsService = settingsService
        self.sourceItems = items
        self.selectedSortOption = settingsService.ownedNFTSortOption
    }

    func updateItems(_ items: [OwnedNFT]) {
        sourceItems = items
    }

    func selectSortOption(_ option: OwnedNFTSortOption) {
        selectedSortOption = option
        settingsService.ownedNFTSortOption = option
        closeSortMenu()
    }

    func closeSortMenu() {
        isSortMenuPresented = false
    }
}
