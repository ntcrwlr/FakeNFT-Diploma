//
//  CurrenciesService.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation

protocol CurrenciesService {
    func loadCurrencies() async throws -> [Currency]
}

@MainActor
final class CurrenciesServiceImpl: CurrenciesService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func loadCurrencies() async throws -> [Currency] {
        let request = CurrenciesRequest()
        return try await networkClient.send(request: request)
    }
}
