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
    private let analyticsService: AnalyticsService
    
    init(
        currenciesService: CurrenciesService,
        paymentService: PaymentService,
        analyticsService: AnalyticsService
    ) {
        self.currenciesService = currenciesService
        self.paymentService = paymentService
        self.analyticsService = analyticsService
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
            
            analyticsService.reportEvent(
                name: "currencies_load_failed",
                parameters: [:]
            )
        }
    }
    
    func selectCurrency(id: String) {
        selectedCurrencyID = id
        paymentError = nil
        
        analyticsService.reportEvent(
            name: "currency_selected",
            parameters: [
                "currency_id": id
            ]
        )
    }
    
   
    func pay() async {
        guard let currencyID = selectedCurrencyID,
              !isPaying else {
            return
        }

        isPaying = true
        paymentError = nil
        isPaymentSuccessful = false
        isMockPayment = false

        defer {
            isPaying = false
        }

        do {
            let response = try await paymentService.pay(
                currencyID: currencyID
            )

            guard response.success else {
                paymentError = "Сервер отклонил оплату"
                analyticsService.reportEvent(
                    name: "payment_failed",
                    parameters: [
                        "currency_id": currencyID,
                        "reason": "server_rejected"
                    ]
                )
                return
            }

            isPaymentSuccessful = true

            analyticsService.reportEvent(
                name: "payment_completed",
                parameters: [
                    "currency_id": currencyID,
                    "mock_payment": false
                ]
            )

        } catch {
            Logger.shared.error(
                "Ошибка оплаты: \(error.localizedDescription, privacy: .public)"
            )

            paymentError = error.localizedDescription

            analyticsService.reportEvent(
                name: "payment_failed",
                parameters: [
                    "currency_id": currencyID,
                    "reason": "request_error"
                ]
            )
        }
    }
}
