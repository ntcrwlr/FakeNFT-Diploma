//
//  CurrenciesServiceTests.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class CurrenciesServiceTests: XCTestCase {

    func testLoadCurrenciesSuccess() async throws {
        let expectedCurrencies = [
            Currency(
                id: "1",
                title: "Bitcoin",
                name: "BTC",
                imageURL: URL(string: "https://example.com/btc.png")!
            )
        ]

        let networkClient = MockNetworkClient()
        networkClient.decodedResult = .success(expectedCurrencies)

        let service = CurrenciesServiceImpl(networkClient: networkClient)

        let currencies = try await service.loadCurrencies()

        XCTAssertEqual(currencies.map(\.id), expectedCurrencies.map(\.id))
    }

    func testLoadCurrenciesFailure() async {
        let networkClient = MockNetworkClient()
        networkClient.decodedResult = .failure(NetworkClientError.parsingError)

        let service = CurrenciesServiceImpl(networkClient: networkClient)

        do {
            _ = try await service.loadCurrencies()
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
