import Foundation

@MainActor
protocol OwnedNFTService {
    func loadOwnedNFTs() async throws -> [Nft]
}

@MainActor
final class OwnedNFTServiceImpl: OwnedNFTService {
    private let profileService: ProfileService
    private let nftService: NftService

    init(profileService: ProfileService, nftService: NftService) {
        self.profileService = profileService
        self.nftService = nftService
    }

    func loadOwnedNFTs() async throws -> [Nft] {
        try Task.checkCancellation()
        let profile = try await profileService.loadProfile()
        var ownedNFTs: [Nft] = []

        for id in profile.nfts {
            try Task.checkCancellation()
            let nft = try await nftService.loadNft(id: id)
            ownedNFTs.append(nft)
        }

        try Task.checkCancellation()
        return ownedNFTs
    }
}
