//
//  CartService.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//

import Foundation

protocol CartService {
    func loadOrder(id: String) async throws -> Order
}

@MainActor
final class CartServiceImpl: CartService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadOrder(id: String) async throws -> Order {
        let request = OrderRequest(id: id)
        let order: Order = try await networkClient.send(request: request)
        return order
    }
}
