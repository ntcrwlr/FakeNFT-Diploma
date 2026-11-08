//
//  PaymentMethodViewModelTests.swift
//  iOS-FakeNFT-ExtendedTests
//
//  Created by Leo Gabuev on 08.11.2026.
//

import XCTest
@testable import iOS_FakeNFT_Extended

@MainActor
final class PaymentMethodViewModelTests: XCTestCase {

    // MARK: - Загрузка валют

    func testLoadCurrenciesSuccess() async {
        let expectedCurrencies = [
            Currency(
                id: "1",
                title: "Bitcoin",
                name: "BTC",
                image: URL(string: "https://example.com/bitcoin.png")!
            )
        ]

        let currenciesService = MockCurrenciesService(
            result: .success(expectedCurrencies)
        )

        let paymentService = MockPaymentService(
            result: .failure(NSError(domain: "Test", code: 1))
        )

        let viewModel = PaymentMethodViewModel(
            currenciesService: currenciesService,
            paymentService: paymentService
        )

        await viewModel.loadCurrencies()

        XCTAssertEqual(viewModel.currencies.count, 1)
        XCTAssertEqual(viewModel.currencies.first?.id, "1")
        XCTAssertEqual(viewModel.currencies.first?.name, "BTC")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.mockCurrencies.isEmpty)
    }

    func testLoadCurrenciesFailure() async {
        let currenciesService = MockCurrenciesService(
            result: .failure(NSError(domain: "Test", code: 1))
        )

        let paymentService = MockPaymentService(
            result: .failure(NSError(domain: "Test", code: 1))
        )

        let viewModel = PaymentMethodViewModel(
            currenciesService: currenciesService,
            paymentService: paymentService
        )

        await viewModel.loadCurrencies()

        XCTAssertTrue(viewModel.currencies.isEmpty)
        XCTAssertEqual(
            viewModel.mockCurrencies.count,
            CurrencyMockData.currencies.count
        )
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Оплата

    func testPaySuccess() async {
        let currenciesService = MockCurrenciesService(
            result: .success([])
        )

        let expectedResponse = PaymentResponse(
            success: true,
            orderId: "order-1",
            id: "payment-1"
        )

        let paymentService = MockPaymentService(
            result: .success(expectedResponse)
        )

        let viewModel = PaymentMethodViewModel(
            currenciesService: currenciesService,
            paymentService: paymentService
        )

        viewModel.selectCurrency(id: "1")

        await viewModel.pay()

        XCTAssertTrue(viewModel.isPaymentSuccessful)
        XCTAssertFalse(viewModel.isMockPayment)
        XCTAssertFalse(viewModel.isPaying)
        XCTAssertNil(viewModel.paymentError)
    }

    func testPayFailureUsesMockPayment() async {
        let currenciesService = MockCurrenciesService(
            result: .success([])
        )

        let paymentService = MockPaymentService(
            result: .failure(NSError(domain: "Test", code: 1))
        )

        let viewModel = PaymentMethodViewModel(
            currenciesService: currenciesService,
            paymentService: paymentService
        )

        viewModel.selectCurrency(id: "1")

        await viewModel.pay()

        XCTAssertTrue(viewModel.isPaymentSuccessful)
        XCTAssertTrue(viewModel.isMockPayment)
        XCTAssertFalse(viewModel.isPaying)
    }
}

