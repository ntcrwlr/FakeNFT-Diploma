import Foundation
import Observation

@MainActor
@Observable
final class CollectionDetailsViewModel {
    let collection: NftCollection

    private let nftService: NftService
    private let favoritesService: FavoritesServiceProtocol
    private let cartService: CartServiceProtocol

    private(set) var state: CollectionDetailsState = .idle
    private(set) var likedNftIds: Set<String> = []
    private(set) var likeRequests: Set<String> = []
    private(set) var cartNftIds: Set<String> = []
    private(set) var cartRequests: Set<String> = []
    private(set) var actionErrorMessage: String?

    init(
        collection: NftCollection,
        nftService: NftService,
        favoritesService: FavoritesServiceProtocol,
        cartService: CartServiceProtocol
    ) {
        self.collection = collection
        self.nftService = nftService
        self.favoritesService = favoritesService
        self.cartService = cartService
    }

    func isLiked(_ id: String) -> Bool {
        likedNftIds.contains(id)
    }

    func isLikeInProgress(_ id: String) -> Bool {
        likeRequests.contains(id)
    }

    func toggleLike(id: String) async {
        guard likeRequests.isEmpty else { return }
        likeRequests.insert(id)
        defer { likeRequests.remove(id) }

        var likes = likedNftIds
        if likes.contains(id) {
            likes.remove(id)
        } else {
            likes.insert(id)
        }

        do {
            likedNftIds = try await favoritesService.updateLikes(likes)
        } catch {
            actionErrorMessage = Self.message(for: error)
        }
    }

    func clearActionError() {
        actionErrorMessage = nil
    }

    func isInCart(_ id: String) -> Bool {
        cartNftIds.contains(id)
    }

    func isCartInProgress(_ id: String) -> Bool {
        cartRequests.contains(id)
    }

    func toggleCart(id: String) async {
        guard cartRequests.isEmpty else { return }
        cartRequests.insert(id)
        defer { cartRequests.remove(id) }

        var nftIds = cartNftIds
        if nftIds.contains(id) {
            nftIds.remove(id)
        } else {
            nftIds.insert(id)
        }

        do {
            cartNftIds = try await cartService.updateOrder(nftIds)
        } catch {
            actionErrorMessage = Self.message(for: error)
        }
    }

    var authorURL: URL? {
        let raw = collection.author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }

        let address = raw.contains("://") ? raw : "https://\(raw)"

        guard let url = URL(string: address),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }

        return url
    }

    func loadIfNeeded() async {
        await load()
    }

    func load() async {
        if case .loading = state { return }

        state = .loading

        if collection.nfts.isEmpty {
            state = .success([])
            return
        }

        do {
            async let nfts = loadNfts()
            async let likes = favoritesService.loadLikes()
            async let order = cartService.loadOrder()
            let loadedNfts = try await nfts
            let loadedLikes = try await likes
            let loadedOrder = try await order
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            likedNftIds = loadedLikes
            cartNftIds = loadedOrder
            state = .success(loadedNfts)
        } catch {
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            state = .error
        }
    }

    private func loadNfts() async throws -> [Nft] {
        try await withThrowingTaskGroup(of: (Int, Nft).self) { group in
            for (index, id) in collection.nfts.enumerated() {
                group.addTask {
                    let nft = try await self.nftService.loadNft(id: id)
                    return (index, nft)
                }
            }

            var loaded: [(Int, Nft)] = []
            for try await nft in group {
                loaded.append(nft)
            }
            return loaded.sorted { $0.0 < $1.0 }.map(\.1)
        }
    }

    private static func message(for error: Error) -> String {
        if error is NetworkClientError {
            return NSLocalizedString("Error.network", comment: "")
        }
        return NSLocalizedString("Error.unknown", comment: "")
    }
}
