//
//  PaymentMethodViewModel.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation
import Observation

@Observable
@MainActor
final class PaymentMethodViewModel {
    private(set) var currencies: [Currency] = []
    private(set) var isLoading = false

    private let currenciesService: CurrenciesService
    private(set) var mockCurrencies: [CurrencyMockData] = []

    init(currenciesService: CurrenciesService) {
        self.currenciesService = currenciesService
    }

    func loadCurrencies() async {
        guard !isLoading else { return }

        isLoading = true
        defer {
            isLoading = false
        }

        do {
            currencies = try await currenciesService.loadCurrencies()
        } catch {
            print("Ошибка загрузки валют: \(error)")
            mockCurrencies = CurrencyMockData.currencies
        }
    }
}
