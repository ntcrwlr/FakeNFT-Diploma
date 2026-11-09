//
//  PaymentServiceTests.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class PaymentServiceTests: XCTestCase {

    func testPaySuccess() async throws {
        let expectedResponse = PaymentResponse(
            success: true,
            orderId: "order-1",
            id: "payment-1"
        )

        let networkClient = MockNetworkClient()
        networkClient.decodedResult = .success(expectedResponse)

        let service = PaymentServiceImpl(networkClient: networkClient)

        let response = try await service.pay(currencyID: "bitcoin")

        XCTAssertTrue(response.success)
        XCTAssertEqual(response.orderId, "order-1")
        XCTAssertEqual(response.id, "payment-1")
    }

    func testPayFailure() async {
        let networkClient = MockNetworkClient()
        networkClient.decodedResult = .failure(NetworkClientError.parsingError)

        let service = PaymentServiceImpl(networkClient: networkClient)

        do {
            _ = try await service.pay(currencyID: "bitcoin")
            XCTFail("Expected an error")
        } catch let error as NetworkClientError {
            guard case .parsingError = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testPayPassesCurrencyIDInRequest() async throws {
        let networkClient = MockNetworkClient()
        networkClient.decodedResult = .success(
            PaymentResponse(
                success: true,
                orderId: "order-1",
                id: "payment-1"
            )
        )

        let service = PaymentServiceImpl(networkClient: networkClient)

        _ = try await service.pay(currencyID: "bitcoin")

        let request = try XCTUnwrap(networkClient.receivedRequest)
        XCTAssertEqual(
            request.endpoint?.absoluteString,
            "\(RequestConstants.baseURL)/api/v1/orders/1/payment/bitcoin"
        )
    }
}
