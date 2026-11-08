//
//  Mocks.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 07.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

struct MockCurrenciesService: CurrenciesService {
    var result: Result<[Currency], Error>

    func loadCurrencies() async throws -> [Currency] {
        try result.get()
    }
}
