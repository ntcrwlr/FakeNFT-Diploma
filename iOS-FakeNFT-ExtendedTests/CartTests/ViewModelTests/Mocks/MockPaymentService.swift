//
//  MockPaymentService.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 07.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

struct MockPaymentService: PaymentService {
    var result: Result<PaymentResponse, Error>

    func pay(currencyID: String) async throws -> PaymentResponse {
        try result.get()
    }
}
