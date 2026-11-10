import Foundation

// MARK: - Feature/cart

protocol CartServiceLocalProtocol {
    func loadOrder(id: String) async throws -> Order
    func updateOrder(id: String, nftIDs: [String]) async throws
}

@MainActor
final class CartServiceLocal: CartServiceLocalProtocol {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func loadOrder(id: String) async throws -> Order {
        let request = OrderRequest(id: id)
        return try await networkClient.send(request: request)
    }
    
    func updateOrder(id: String, nftIDs: [String]) async throws {
        let request = UpdateOrderRequest(id: id, nftIDs: nftIDs)
        let _: Data = try await networkClient.send(request: request)
    }
}

// MARK: - Develop

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
        let order: Order = try await networkClient.send(
            request: OrderRequest(id: "1")
        )
        return Set(order.nfts)
    }

    func updateOrder(_ nftIds: Set<String>) async throws -> Set<String> {
        let _: Data = try await networkClient.send(
            request: UpdateOrderRequest(id: "1", nftIDs: Array(nftIds))
        )
        return nftIds
    }
}
