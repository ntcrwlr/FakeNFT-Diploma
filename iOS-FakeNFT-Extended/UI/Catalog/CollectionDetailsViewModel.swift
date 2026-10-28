import Foundation
import Observation

enum CollectionDetailsState {
    case loading
    case success([Nft])
    case error
}

@MainActor
@Observable
final class CollectionDetailsViewModel {
    let collection: NftCollection

    private let nftService: NftService
    private var isLoading = false

    private(set) var state: CollectionDetailsState = .loading

    init(collection: NftCollection, nftService: NftService) {
        self.collection = collection
        self.nftService = nftService
    }

    func loadIfNeeded() async {
        guard case .loading = state else { return }
        await load()
    }

    func load() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        state = .loading

        if collection.nfts.isEmpty {
            state = .success([])
            return
        }

        do {
            let nfts = try await loadNfts()
            guard !Task.isCancelled else { return }
            state = .success(nfts)
        } catch {
            guard !Task.isCancelled else { return }
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

struct PreviewNftService: NftService {
    func loadNft(id: String) async throws -> Nft {
        let samples: [String: (name: String, rating: Int, price: Double)] = [
            "1": ("April", 8, 1.78),
            "2": ("Aurora", 6, 1),
            "3": ("Biscuit", 4, 2.5),
            "4": ("Cotton", 10, 1.23),
            "5": ("Daisy", 2, 3),
            "6": ("Ellie", 0, 0.5)
        ]
        let sample = samples[id] ?? (name: "NFT \(id)", rating: 0, price: 1)
        return Nft(id: id, name: sample.name, images: [], rating: sample.rating, price: sample.price)
    }
}
