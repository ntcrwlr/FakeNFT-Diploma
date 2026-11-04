import Foundation
import Observation

@MainActor
@Observable
final class OwnedNFTsViewModel {
    private let service: OwnedNFTService?
    private let settingsService: UserSettingsServiceProtocol
    private var sourceItems: [OwnedNFT]
    private(set) var isLoading = false
    private(set) var hasLoaded = false
    private(set) var loadingError: Error?
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

    var isEmpty: Bool {
        hasLoaded && sourceItems.isEmpty && !isLoading && loadingError == nil
    }

    init(service: OwnedNFTService, settingsService: UserSettingsServiceProtocol = UserSettingsService()) {
        self.service = service
        self.settingsService = settingsService
        self.sourceItems = []
        self.selectedSortOption = settingsService.ownedNFTSortOption
    }

    init(items: [OwnedNFT], settingsService: UserSettingsServiceProtocol = UserSettingsService()) {
        self.service = nil
        self.settingsService = settingsService
        self.sourceItems = items
        self.hasLoaded = true
        self.selectedSortOption = settingsService.ownedNFTSortOption
    }

    func loadOwnedNFTs() async {
        guard let service, !isLoading else { return }
        isLoading = true
        loadingError = nil
        defer { isLoading = false }

        do {
            try Task.checkCancellation()
            let response = try await service.loadOwnedNFTs()
            try Task.checkCancellation()
            sourceItems = response.map {
                OwnedNFT(
                    id: $0.id, name: $0.name, author: $0.author, price: $0.price,
                    rating: $0.rating, imageName: nil, isFavorite: false, imageURL: $0.images.first
                )
            }
            hasLoaded = true
        } catch is CancellationError {
            return
        } catch {
            guard !Task.isCancelled else { return }
            loadingError = error
        }
    }

    func updateItems(_ items: [OwnedNFT]) {
        sourceItems = items
        hasLoaded = true
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
