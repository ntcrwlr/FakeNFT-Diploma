import Foundation
import Observation

@MainActor
@Observable
final class FavoriteNFTsViewModel {
    private(set) var items: [FavoriteNFT]
    private(set) var loadingError: Error?
    private(set) var removalError: Error?
    private(set) var failedRemovalID: String?
    private(set) var removingIDs: Set<String> = []
    private let service: FavoriteNFTService?
    private(set) var isLoading = false
    private(set) var hasLoaded = false

    var isEmpty: Bool {
        hasLoaded && items.isEmpty && !isLoading && loadingError == nil
    }

    init(service: FavoriteNFTService) {
        self.service = service
        items = []
    }

    init(items: [FavoriteNFT]) {
        self.items = items
        service = nil
        hasLoaded = true
    }

    func loadFavorites() async {
        guard let service, !isLoading else { return }
        isLoading = true
        loadingError = nil
        defer { isLoading = false }

        do {
            let response = try await service.loadFavoriteNFTs()
            try Task.checkCancellation()
            items = response.map {
                FavoriteNFT(
                    id: $0.id, name: $0.name, price: $0.price, rating: $0.rating,
                    imageName: nil, imageURL: $0.images.first
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

    func removeFavorite(id: String) async {
        guard let service, items.contains(where: { $0.id == id }),
              !removingIDs.contains(id) else { return }
        removingIDs.insert(id)
        defer { removingIDs.remove(id) }
        if failedRemovalID == id { dismissRemovalError() }
        do {
            try await service.removeFavoriteNFT(id: id)
            items.removeAll { $0.id == id }
        } catch {
            removalError = error
            failedRemovalID = id
        }
    }

    func dismissRemovalError() {
        removalError = nil
        failedRemovalID = nil
    }
}
