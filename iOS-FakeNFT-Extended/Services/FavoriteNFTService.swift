import Foundation

@MainActor
protocol FavoriteNFTService {
    func loadFavoriteNFTs() async throws -> [Nft]
}

@MainActor
final class FavoriteNFTServiceImpl: FavoriteNFTService {
    private let profileService: ProfileService
    private let nftService: NftService

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
}
