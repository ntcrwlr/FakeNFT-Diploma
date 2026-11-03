import Foundation
import Observation

@MainActor
@Observable
final class FavoriteNFTsViewModel {
    private(set) var items: [FavoriteNFT]
    private(set) var loadingError: Error?
    private(set) var removalError: Error?
    private let service: FavoriteNFTService?
    private var isLoading = false
    private var hasLoaded = false

    init(service: FavoriteNFTService) {
        self.service = service
        items = []
    }

    init(items: [FavoriteNFT]) {
        self.items = items
        service = nil
    }

    func loadFavorites() async {
        guard let service, !isLoading, !hasLoaded else { return }
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
        guard let service, items.contains(where: { $0.id == id }) else { return }
        removalError = nil
        do {
            try await service.removeFavoriteNFT(id: id)
            items.removeAll { $0.id == id }
        } catch {
            removalError = error
        }
    }
}
