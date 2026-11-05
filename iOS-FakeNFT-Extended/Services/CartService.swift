import Foundation

protocol CartServiceProtocol {
    func loadOrder() async throws -> Set<String>
    func updateOrder(_ nftIds: Set<String>) async throws -> Set<String>
}

final class CartService: CartServiceProtocol {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadOrder() async throws -> Set<String> {
        let order: OrderResponse = try await networkClient.send(request: OrderRequest())
        return Set(order.nfts ?? [])
    }

    func updateOrder(_ nftIds: Set<String>) async throws -> Set<String> {
        let order: OrderResponse = try await networkClient.send(request: UpdateOrderRequest(nftIds: nftIds))
        return Set(order.nfts ?? [])
    }
}
