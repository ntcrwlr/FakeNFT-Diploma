//
//  CartServiceTests.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class CartServiceTests: XCTestCase {

    func testLoadOrderSuccess() async throws {
        let expectedOrder = Order(
            id: "order-1",
            nfts: ["nft-1", "nft-2"]
        )

        let networkClient = MockNetworkClient()
        networkClient.decodedResult = .success(expectedOrder)

        let service = CartServiceImpl(networkClient: networkClient)

        let order = try await service.loadOrder(id: "order-1")

        XCTAssertEqual(order.id, expectedOrder.id)
        XCTAssertEqual(order.nfts, expectedOrder.nfts)

        let request = try XCTUnwrap(networkClient.receivedRequest)
        XCTAssertEqual(
            request.endpoint?.absoluteString,
            "\(RequestConstants.baseURL)/api/v1/orders/order-1"
        )
    }

    func testLoadOrderFailure() async {
        let networkClient = MockNetworkClient()
        networkClient.decodedResult = .failure(NetworkClientError.parsingError)

        let service = CartServiceImpl(networkClient: networkClient)

        do {
            _ = try await service.loadOrder(id: "order-1")
            XCTFail("Expected an error")
        } catch let error as NetworkClientError {
            guard case .parsingError = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testUpdateOrderSuccess() async throws {
        let networkClient = MockNetworkClient()
        networkClient.dataResult = .success(Data())

        let service = CartServiceImpl(networkClient: networkClient)

        try await service.updateOrder(
            id: "order-1",
            nftIDs: ["nft-1", "nft-2"]
        )

        let request = try XCTUnwrap(networkClient.receivedRequest)

        XCTAssertEqual(
            request.endpoint?.absoluteString,
            "\(RequestConstants.baseURL)/api/v1/orders/order-1"
        )
        XCTAssertEqual(request.httpMethod, .put)
        XCTAssertEqual(
            request.contentType,
            "application/x-www-form-urlencoded"
        )
        XCTAssertEqual(
            String(data: try XCTUnwrap(request.httpBody), encoding: .utf8),
            "nfts=nft-1&nfts=nft-2"
        )
    }

    func testUpdateOrderFailure() async {
        let networkClient = MockNetworkClient()
        networkClient.dataResult = .failure(NetworkClientError.parsingError)

        let service = CartServiceImpl(networkClient: networkClient)

        do {
            try await service.updateOrder(
                id: "order-1",
                nftIDs: ["nft-1", "nft-2"]
            )
            XCTFail("Expected an error")
        } catch let error as NetworkClientError {
            guard case .parsingError = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
