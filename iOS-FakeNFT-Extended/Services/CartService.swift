//
//  CartService.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 21.10.2026.
//

import Foundation

protocol CartService {
    func loadOrder(id: String) async throws -> Order
    func updateOrder(id: String, nftIDs: [String]) async throws
}

@MainActor
final class CartServiceImpl: CartService {
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
