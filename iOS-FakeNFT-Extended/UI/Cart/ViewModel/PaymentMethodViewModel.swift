//
//  PaymentMethodViewModel.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import Foundation
import Observation
import OSLog

@Observable
@MainActor
final class PaymentMethodViewModel {
    private(set) var currencies: [Currency] = []
    private(set) var isLoading = false
    private(set) var mockCurrencies: [CurrencyMockData] = []

    private(set) var selectedCurrencyID: String?
    private(set) var isPaying = false
    private(set) var paymentError: String?
    private(set) var isPaymentSuccessful = false
    private(set) var isMockPayment = false

    private let currenciesService: CurrenciesService
    private let paymentService: PaymentService

    init(
        currenciesService: CurrenciesService,
        paymentService: PaymentService
    ) {
        self.currenciesService = currenciesService
        self.paymentService = paymentService
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
            Logger.shared.error("Ошибка загрузки валют: \(error.localizedDescription, privacy: .public)")
            mockCurrencies = CurrencyMockData.currencies
        }
    }

    func selectCurrency(id: String) {
        selectedCurrencyID = id
        paymentError = nil
    }

    func pay() async {
        guard let currencyID = selectedCurrencyID,
              !isPaying else {
            return
        }

        isPaying = true
        paymentError = nil
        isMockPayment = false

        defer {
            isPaying = false
        }

        do {
            let response = try await paymentService.pay(
                currencyID: currencyID
            )

            if response.success {
                isPaymentSuccessful = true
            } else {
                Logger.shared.warning("Сервер отклонил оплату. Используем мок.")
                isMockPayment = true
                isPaymentSuccessful = true
            }
        } catch {
            Logger.shared.error("Ошибка оплаты: \(error.localizedDescription, privacy: .public). Используем мок.")
            isMockPayment = true
            isPaymentSuccessful = true
        }
    }
}
