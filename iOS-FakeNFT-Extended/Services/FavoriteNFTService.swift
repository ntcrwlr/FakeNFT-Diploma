import Foundation

@MainActor
protocol FavoriteNFTService {
    func loadFavoriteNFTs() async throws -> [Nft]
    func removeFavoriteNFT(id: String) async throws
}

@MainActor
final class FavoriteNFTServiceImpl: FavoriteNFTService {
    private let profileService: ProfileService
    private let nftService: NftService
    private var removalTask: Task<Void, Error>?

    init(profileService: ProfileService, nftService: NftService) {
        self.profileService = profileService
        self.nftService = nftService
    }

    func loadFavoriteNFTs() async throws -> [Nft] {
        try Task.checkCancellation()
        let profile = try await profileService.loadProfile()
        var favorites: [Nft] = []

        for id in profile.likes {
            try Task.checkCancellation()
            let nft = try await nftService.loadNft(id: id)
            favorites.append(nft)
        }

        try Task.checkCancellation()
        return favorites
    }

    func removeFavoriteNFT(id: String) async throws {
        let previousTask = removalTask
        let task = Task { [profileService] in
            // Each update replaces all likes, so concurrent removals must be serialized.
            _ = await previousTask?.result
            let profile = try await profileService.loadProfile()
            _ = try await profileService.saveLikes(profile.likes.filter { $0 != id })
        }
        removalTask = task
        try await task.value
    }
}
