//
//  PaymentFlowView.swift
//  iOS-FakeNFT-Extended
//
//  Created by Leo Gabuev on 05.11.2026.
//

import SwiftUI

struct PaymentFlowView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: PaymentMethodViewModel

    private let onPaymentSuccess: (Bool) async -> Bool

    @State private var isClearingCart = false
    @State private var isCartCleared = false
    @State private var cartClearError = false

    init(
        currenciesService: CurrenciesService,
        paymentService: PaymentService,
        onPaymentSuccess: @escaping (Bool) async -> Bool
    ) {
        _viewModel = State(
            initialValue: PaymentMethodViewModel(
                currenciesService: currenciesService,
                paymentService: paymentService
            )
        )

        self.onPaymentSuccess = onPaymentSuccess
    }

    var body: some View {
        Group {
            if isCartCleared {
                PaymentSuccessView {
                    dismiss()
                }
            } else if viewModel.isPaymentSuccessful {
                ProgressView("Payment.clearingCart")
            } else {
                PaymentMethodView(viewModel: viewModel)
            }
        }
        .task(id: viewModel.isPaymentSuccessful) {
            guard viewModel.isPaymentSuccessful else { return }
            await clearCart()
        }
        .alert(
            "Payment.clearCart.error.title",
            isPresented: $cartClearError
        ) {
            Button("Error.repeat") {
                Task {
                    await clearCart()
                }
            }

            Button("Payment.success.back", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Payment.clearCart.error.message")
        }
    }

    private func clearCart() async {
        guard !isClearingCart else { return }

        isClearingCart = true

        let isCleared = await onPaymentSuccess(
            viewModel.isMockPayment
        )

        isClearingCart = false
        isCartCleared = isCleared
        cartClearError = !isCleared
    }
}
