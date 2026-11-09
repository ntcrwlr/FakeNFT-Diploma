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
    
    var cartService: CartService {
        CartServiceImpl(networkClient: networkClient)
    }
    
    var currenciesService: CurrenciesService {
        CurrenciesServiceImpl(networkClient: networkClient)
    }
    
    var paymentService: PaymentService {
        PaymentServiceImpl(networkClient: networkClient)
    }
    
    var analyticsService: AnalyticsService {
        AppMetricaAnalyticsService()
    }
}
