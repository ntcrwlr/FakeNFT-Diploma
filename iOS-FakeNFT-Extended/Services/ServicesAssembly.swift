import Foundation

@Observable
@MainActor
final class ServicesAssembly {

    private let networkClient: NetworkClient
    private let nftStorage: NftStorage

    init(
        networkClient: NetworkClient,
        nftStorage: NftStorage
    ) {
        self.networkClient = networkClient
        self.nftStorage = nftStorage
    }

    var nftService: NftService {
        NftServiceImpl(
            networkClient: networkClient,
            storage: nftStorage
        )
    }

    var collectionService: CollectionServiceProtocol {
        CollectionService(networkClient: networkClient)
    }

    var favoritesService: FavoritesServiceProtocol {
        FavoritesService(networkClient: networkClient)
    }

    var cartService: CartServiceProtocol {
        CartService(networkClient: networkClient)
    }

    var profileService: ProfileService {
        ProfileServiceImpl(networkClient: networkClient)
    }

    var favoriteNFTService: FavoriteNFTService {
        FavoriteNFTServiceImpl(profileService: profileService, nftService: nftService)
    }

    var ownedNFTService: OwnedNFTService {
        OwnedNFTServiceImpl(profileService: profileService, nftService: nftService)
    }
}
