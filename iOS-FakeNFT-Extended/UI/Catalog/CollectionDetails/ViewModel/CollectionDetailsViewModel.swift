import Foundation
import Observation

@MainActor
@Observable
final class CollectionDetailsViewModel {
    let collection: NftCollection

    private let nftService: NftService

    private(set) var state: CollectionDetailsState = .idle

    init(collection: NftCollection, nftService: NftService) {
        self.collection = collection
        self.nftService = nftService
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
            let nfts = try await loadNfts()
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            state = .success(nfts)
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
