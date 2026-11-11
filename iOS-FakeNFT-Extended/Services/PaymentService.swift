//
//  PaymentService.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation

protocol PaymentService {
    func pay(currencyID: String) async throws -> PaymentResponse
}

@MainActor
final class PaymentServiceImpl: PaymentService {
    private let networkClient: NetworkClient

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    func pay(currencyID: String) async throws -> PaymentResponse {
        let request = PaymentRequest(currencyID: currencyID)
        let response: PaymentResponse = try await networkClient.send(
            request: request
        )
        return response
    }
}
