//
//  MockCartService.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import Foundation
@testable import iOS_FakeNFT_Extended

struct MockCartService: CartService {
    var loadOrderResult: Result<Order, Error>
    var updateOrderResult: Result<Void, Error>

    func loadOrder(id: String) async throws -> Order {
        try loadOrderResult.get()
    }

    func updateOrder(id: String, nftIDs: [String]) async throws {
        try updateOrderResult.get()
    }
}
