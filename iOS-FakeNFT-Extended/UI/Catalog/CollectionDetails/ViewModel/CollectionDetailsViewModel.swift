import Foundation
import Observation

@MainActor
@Observable
final class CollectionDetailsViewModel {
    let collection: NftCollection

    private let nftService: NftService
    private let favoritesService: FavoritesServiceProtocol

    private(set) var state: CollectionDetailsState = .idle
    private(set) var likedNftIds: Set<String> = []
    private(set) var likeRequests: Set<String> = []

    init(
        collection: NftCollection,
        nftService: NftService,
        favoritesService: FavoritesServiceProtocol
    ) {
        self.collection = collection
        self.nftService = nftService
        self.favoritesService = favoritesService
    }

    func isLiked(_ id: String) -> Bool {
        likedNftIds.contains(id)
    }

    func isLikeInProgress(_ id: String) -> Bool {
        likeRequests.contains(id)
    }

    func toggleLike(id: String) async {
        guard !likeRequests.contains(id) else { return }
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
            return
        }
    }

    var authorURL: URL? {
        let raw = collection.author.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return nil }
        if let url = URL(string: raw), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(raw)")
    }

    func loadIfNeeded() async {
        guard case .idle = state else { return }
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
            let loadedNfts = try await nfts
            let loadedLikes = try await likes
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            likedNftIds = loadedLikes
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
}
